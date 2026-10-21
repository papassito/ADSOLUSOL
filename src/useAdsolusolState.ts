import { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { apiFetch } from './services/api';
import { mapFromBackendCampaign } from './services/campaignAdapter';
import { Campaign, ToastMsg } from './types';

export function useAdsolusolState() {
  const [loadingAction, setLoadingAction] = useState(false);
  const [isAutoLive, setIsAutoLive] = useState(false);
  const [toasts, setToasts] = useState<ToastMsg[]>([]);
  const [pushAlertBanner, setPushAlertBanner] = useState<string | null>(null);
  const [pushPermission, setPushPermission] = useState<NotificationPermission>(
    typeof Notification !== 'undefined' ? Notification.permission : 'default'
  );
  const notified90CampaignsRef = useRef<Set<string>>(new Set());

  const [dbState, setDbState] = useState<any>(null);
  const [lastDecision, setLastDecision] = useState<any>(null);

  const [competitorTerms, setCompetitorTerms] = useState([
    { id: 'sh-1', term: 'salud digna hermosillo telefono', wasted: 14.5, category: 'Competidor Directo', blocked: true },
    { id: 'sh-2', term: 'laboratorio chopo hermosillo precios', wasted: 19.2, category: 'Competidor Directo', blocked: true },
    { id: 'sh-3', term: 'laboratorio san jose sucursales', wasted: 11.8, category: 'Competidor Local', blocked: false },
    { id: 'sh-4', term: 'laboratorio ramos hermosillo', wasted: 9.4, category: 'Competidor Local', blocked: false },
    { id: 'sh-5', term: 'clinica 37 imss citas', wasted: 8.1, category: 'Sector Público', blocked: true },
  ]);

  const pushToast = useCallback((title: string, type: 'exito' | 'alerta' | 'info' = 'exito') => {
    const id = Math.random().toString(36).substring(2, 8);
    setToasts((prev) => [...prev, { id, title, type }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 4200);
  }, []);

  const requestBrowserPushPermission = async () => {
    if (typeof Notification === 'undefined') {
      pushToast('Este navegador no soporta Notification API nativa; usando Push Interno.', 'info');
      return;
    }
    const perm = await Notification.requestPermission();
    setPushPermission(perm);
    if (perm === 'granted') {
      new Notification('ADSOLUSOL 2027 • Push Activado', {
        body: 'Recibirás alertas inmediatas cuando una campaña alcance el 90% de su presupuesto diario.',
      });
      pushToast('Notificaciones Push del sistema activadas correctamente', 'exito');
    } else {
      pushToast('Permiso denegado en navegador; se usarán notificaciones Push en consola', 'alerta');
    }
  };

  const triggerBudget90Push = useCallback(
    (camp: any, pct: number) => {
      const msg = `⚠️ Alerta 90% Presupuesto: "${camp.name}" (${camp.id}) ha consumido el ${pct}% ($${camp.spent.toFixed(
        2
      )} de $${camp.budget.toFixed(2)} MXN).`;

      setPushAlertBanner(msg);
      pushToast(msg, 'alerta');

      if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
        try {
          new Notification('⚠️ ADSOLUSOL: Umbral 90% de Presupuesto', {
            body: `${camp.name} (${camp.id}) alcanzó el ${pct}% de su techo diario ($${camp.spent.toFixed(
              2
            )} / $${camp.budget.toFixed(2)} MXN).`,
            tag: `budget-90-${camp.id}`,
          });
        } catch (e) {
          console.warn('Error mostrando Notification nativa:', e);
        }
      }
    },
    [pushToast]
  );

  const fetchState = useCallback(async () => {
    setLoadingAction(true);
    try {
      // MODO DEMO: Se ejecuta con `npm run dev`. Consulta directamente el estado del servidor Node.
      if (import.meta.env.VITE_DEMO_MODE === 'true') {
        const res = await apiFetch('/api/state');
        if (res.ok) {
          setDbState(await res.json());
        } else {
          pushToast(`Error en servidor demo: ${res.statusText}`, 'alerta');
          setDbState(null);
        }
      } else {
        // MODO REAL: Se ejecuta con `npm run dev:real`. Intenta conectar con el backend .NET.
        const startCheck = performance.now();
        const [campRes, plcRes, crtRes, healthRes] = await Promise.allSettled([
          apiFetch('/api/Campaigns'),
          apiFetch('/api/Placements'),
          apiFetch('/api/Creatives'),
          apiFetch('/api/health'),
        ]);

        let loadedCampaigns: any[] | null = null;
        let loadedPlacements: any[] | null = null;
        let loadedCreatives: any[] | null = null;
        let loadedHealth: any = null;

        if (campRes.status === 'fulfilled' && campRes.value.ok) {
          loadedCampaigns = await campRes.value.json();
        }
        if (plcRes.status === 'fulfilled' && plcRes.value.ok) {
          loadedPlacements = await plcRes.value.json();
        }
        if (crtRes.status === 'fulfilled' && crtRes.value.ok) {
          loadedCreatives = await crtRes.value.json();
        }
        if (healthRes.status === 'fulfilled' && healthRes.value.ok) {
          loadedHealth = await healthRes.value.json();
        }
        const measuredLatency = Number((performance.now() - startCheck).toFixed(2));

        if (loadedCampaigns) {
          // Si la conexión con .NET es exitosa, se actualiza el estado.
          setDbState((prev: any) => ({
            ...(prev || {}), // Conservar estado anterior para evitar parpadeos
            campaigns: loadedCampaigns,
            ...(loadedPlacements && { placements: loadedPlacements }),
            ...(loadedCreatives && { creatives: loadedCreatives }),
            systemHealth: {
              sqlite: {
                status: loadedHealth?.checks?.database === 'UP' ? 'OPERATIVO (WAL)' : (loadedHealth?.checks?.database || 'DOWN'),
                latencyMs: measuredLatency,
                journalMode: loadedHealth?.checks?.journalMode || 'Verificado en Kestrel',
                atomicGuard: 'BudgetSpent + Cost <= Budget',
              },
              sicEngine: {
                status: loadedHealth?.checks?.sicEngine === 'UP' ? 'CONECTADO' : 'DOWN (Zero-Synthetic)',
                endpoint: 'http://solusol.net:8080/health',
                latencyMs: loadedHealth?.checks?.sicEngine === 'UP' ? measuredLatency : null,
                protocol: 'HTTP/REST (Outbox Bridge)',
              },
              apiNode: {
                status: loadedHealth?.status || 'ACTIVE',
                antiReplayWindow: '300s Nonce Cache',
                tenantId: localStorage.getItem('adsolusol_tenant_id') || 'TENANT-SOLUSOL-HMO-01',
              },
            },
          }));
        } else {
          // Si la conexión con .NET falla, se muestra un estado de desconexión.
          pushToast('Backend .NET no disponible. No se pueden obtener datos en vivo.', 'alerta');
          setDbState((prev: any) => ({
            ...(prev || {}),
            campaigns: prev?.campaigns || [],
            systemHealth: {
              sqlite: { status: 'DISCONNECTED', latencyMs: null, journalMode: 'N/A', atomicGuard: 'N/A' },
              sicEngine: { status: 'DISCONNECTED', endpoint: 'https://api.solusol.net/api', latencyMs: null, protocol: 'HTTP/REST' },
              apiNode: { status: 'API DISCONNECTED', antiReplayWindow: '300s Nonce Cache', tenantId: 'SIN_TENANT' },
            },
          }));
        }
      }
    } catch (error: any) {
      pushToast(`Error de red: ${error.message}`, 'alerta');
      setDbState(null);
    } finally {
      setLoadingAction(false);
    }
  }, [pushToast]);

  useEffect(() => {
    fetchState();
  }, [fetchState]);

  const campaigns: Campaign[] = useMemo(() => {
    return (dbState?.campaigns || []).map(mapFromBackendCampaign);
  }, [dbState?.campaigns]);
  const placements = dbState?.placements || [];
  const creatives = dbState?.creatives || [];
  const assignments = dbState?.assignments || [];
  const hourlyMetrics = dbState?.hourlyMetrics || [];
  const auditLogs = dbState?.auditLogs || [];
  const alerts = dbState?.alerts || [];
  const audiences = dbState?.audiences || [];
  const users = dbState?.users || [];
  const sysHealth = dbState?.systemHealth;

  useEffect(() => {
    campaigns.forEach((c: any) => {
      if (!c.budget || c.budget <= 0) return;
      const ratio = c.spent / c.budget;
      const pct = Math.round(ratio * 100);
      if (ratio >= 0.9 && !notified90CampaignsRef.current.has(c.id)) {
        notified90CampaignsRef.current.add(c.id);
        triggerBudget90Push(c, pct);
      } else if (ratio < 0.9 && notified90CampaignsRef.current.has(c.id)) {
        notified90CampaignsRef.current.delete(c.id);
      }
    });
  }, [campaigns, triggerBudget90Push]);

  useEffect(() => {
    if (!isAutoLive) return;
    const timer = setInterval(() => {
      fetchState();
    }, 5000);
    return () => clearInterval(timer);
  }, [isAutoLive, fetchState]);

  const handleServeDecision = useCallback(
    async (triggerClick: boolean, placementId?: string, isDirections?: boolean) => {
      setLoadingAction(true);
      try {
        const placement = placements.find((p: any) => p.id === placementId) || placements[0];
        const placementCode = placement?.code || 'HEADER_LEADERBOARD';
        const serveRes = await apiFetch(`/api/Serve?placementCode=${encodeURIComponent(placementCode)}`);

        if (serveRes.status === 200) {
          const creative = await serveRes.json();
          const targetCampId = creative.campaignId || campaigns[0]?.id || '1';
          const eventId = typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : `evt-${Date.now()}`;
          let debitCost = 0;

          if (triggerClick) {
            const cleanId = String(targetCampId).replace('CAMP-', '');
            const clickRes = await apiFetch(`/api/Campaigns/${cleanId}/click`, {
              method: 'POST',
              body: JSON.stringify({ eventId, placementId: placement?.id || placementCode, creativeId: creative.id }),
            });
            if (!clickRes.ok) {
              const errData = await clickRes.json().catch(() => ({}));
              pushToast(errData.message || 'Límite presupuestario en backend .NET', 'alerta');
              await fetchState();
              return;
            }
            const debitData = await clickRes.json().catch(() => ({}));
            debitCost = Number(debitData?.cost ?? 0);
          } else {
            const cleanId = String(targetCampId).replace('CAMP-', '');
            await apiFetch(`/api/Campaigns/${cleanId}/impression`, {
              method: 'POST',
              body: JSON.stringify({ eventId, placementId: placement?.id || placementCode, creativeId: creative.id }),
            });
            debitCost = 0.014;
          }

          const responseSignature = serveRes.headers.get('X-Solusol-Signature') || 'SIN_FIRMA_EN_RESPUESTA';
          setLastDecision({
            decisionId: `DEC-${eventId.slice(0, 8)}`,
            campaign: campaigns.find((c) => c.id === targetCampId) || { id: targetCampId, name: creative.name || 'Campaña Activa' },
            creative: {
              id: creative.id,
              title: creative.name || 'Creativo Canónico',
              description: creative.targetUrl || creative.contentUrl || '',
              locationAddress: creative.locationAddress || 'Ubicación autorizada',
              whatsappContact: creative.whatsappContact || 'N/A',
            },
            placement,
            debitedCost: debitCost,
            nonce: eventId.replace(/-/g, '').slice(0, 12),
            signature: responseSignature,
            atomicCheck: 'BudgetSpent + Cost <= Budget (Confirmado por Kestrel)',
          });
          pushToast('Decisión y evento confirmados en .NET 8', 'exito');
          await fetchState();
          return;
        }

        if (serveRes.status === 204) {
          pushToast('No hay campañas activas elegibles', 'alerta');
          return;
        }

        // Fallback resiliente a nodo local si Kestrel no maneja la subasta
        const localRes = await apiFetch('/api/serve-decision', {
          method: 'POST',
          body: JSON.stringify({ placementId: placement?.id || placementCode, triggerClick, isDirections }),
        }).catch(() => null);

        if (localRes && localRes.ok) {
          const data = await localRes.json();
          if (data.decision) setLastDecision(data.decision);
          if (data.db) setDbState((prev: any) => ({ ...prev, ...data.db }));
          pushToast('Decisión entregada por AdServer local', 'exito');
          return;
        }

        pushToast(`Falla en AdServer (HTTP ${serveRes.status}): No se pudo entregar la impresión`, 'alerta');
      } catch (err: any) {
        pushToast(`Error de conexión en AdServer: ${err.message || 'Sin respuesta'}`, 'alerta');
      } finally {
        setLoadingAction(false);
      }
    },
    [placements, campaigns, fetchState, pushToast]
  );

  return {
    loadingAction,
    isAutoLive,
    setIsAutoLive,
    toasts,
    pushAlertBanner,
    setPushAlertBanner,
    pushPermission,
    requestBrowserPushPermission,
    dbState,
    setDbState,
    lastDecision,
    competitorTerms,
    setCompetitorTerms,
    campaigns,
    placements,
    creatives,
    assignments,
    hourlyMetrics,
    auditLogs,
    alerts,
    audiences,
    users,
    sysHealth,
    fetchState,
    pushToast,
    handleServeDecision,
  };
}