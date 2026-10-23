import { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { apiFetch } from './services/api';
import { mapFromBackendCampaign } from './services/campaignAdapter';
import { Campaign, ToastMsg } from './types';

export function useAdsolusolState() {
  const [loadingAction, setLoadingAction] = useState(true);
  const [isAutoLive, setIsAutoLive] = useState(false);
  const [toasts, setToasts] = useState<ToastMsg[]>([]);
  const [pushAlertBanner, setPushAlertBanner] = useState<string | null>(null);
  const [pushPermission, setPushPermission] = useState<NotificationPermission>(
    typeof Notification !== 'undefined' ? Notification.permission : 'default'
  );
  const notified90CampaignsRef = useRef<Set<string>>(new Set());

  const [dbState, setDbState] = useState<any>(null);
  const [lastDecision, setLastDecision] = useState<any>(null);

  const [competitorTerms, setCompetitorTerms] = useState<any[]>([]);

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
          loadedPlacements = (await plcRes.value.json()).map((p: any) => ({ ...p, code: p.placementCode ?? p.code }));
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
            campaignsAvailable: true,
            ...(loadedPlacements && { placements: loadedPlacements }),
            ...(loadedCreatives && { creatives: loadedCreatives }),
            systemHealth: {
              sqlite: {
                status: loadedHealth?.checks?.database === 'UP' ? 'OPERATIVO' : (loadedHealth?.checks?.database || 'DOWN'),
                latencyMs: measuredLatency,
                journalMode: loadedHealth?.checks?.journalMode || 'NO DISPONIBLE',
                atomicGuard: 'BudgetSpent + Cost <= Budget',
              },
              sicEngine: {
                status: loadedHealth?.checks?.sicEngine === 'UP' ? 'CONECTADO' : 'DOWN (Zero-Synthetic)',
                endpoint: 'http://solusol.net:8080/health',
                latencyMs: loadedHealth?.checks?.sicEngine === 'UP' ? measuredLatency : null,
                protocol: 'HTTP/REST (Outbox Bridge)',
              },
              apiNode: {
                status: loadedHealth?.status || 'NO DISPONIBLE',
                antiReplayWindow: '300s Nonce Cache',
                tenantId: localStorage.getItem('adsolusol_tenant_id') || 'SIN_TENANT_CONFIGURADO',
              },
            },
          }));
        } else {
          // Si la conexión con .NET falla, se muestra un estado de desconexión.
          pushToast('Backend .NET no disponible. No se pueden obtener datos en vivo.', 'alerta');
          setDbState((prev: any) => ({
            ...(prev || {}),
            campaigns: prev?.campaigns || [],
            campaignsAvailable: false,
            systemHealth: {
              sqlite: { status: 'DISCONNECTED', latencyMs: null, journalMode: 'N/A', atomicGuard: 'N/A' },
              sicEngine: { status: 'DISCONNECTED', endpoint: 'https://api.solusol.net/api', latencyMs: null, protocol: 'HTTP/REST' },
              apiNode: { status: 'API DISCONNECTED', antiReplayWindow: '300s Nonce Cache', tenantId: 'SIN_TENANT' },
            },
          }));
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
        setLastDecision(null);
        const placement = placements.find((p: any) => String(p.id) === String(placementId)) || placements[0];
        if (!placement?.code) throw new Error('Selecciona una ubicación real con código.');
        const serveRes = await apiFetch(`/api/Serve?placementCode=${encodeURIComponent(placement.code)}`);
        if (serveRes.status === 204 || serveRes.status === 404) {
          pushToast('No hay anuncios elegibles para esta ubicación', 'alerta');
          return;
        }
        if (!serveRes.ok) throw new Error(`Entrega rechazada (HTTP ${serveRes.status})`);
        const creative = await serveRes.json();
        if (!creative.campaignId || creative.id == null) throw new Error('Respuesta sin campaña o creativo. Actualiza la API.');
        const eventId = crypto.randomUUID();
        const eventRes = await apiFetch(`/api/Campaigns/${encodeURIComponent(String(creative.campaignId))}/${triggerClick ? 'click' : 'impression'}`, {
          method: 'POST',
          body: JSON.stringify({
            eventId,
            placementCode: placement.code,
            creativeId: String(creative.id),
          }),
        });
        const event = await eventRes.json().catch(() => ({}));
        if (!eventRes.ok || event.status !== 'ACCEPTED' || event.eventId !== eventId || typeof event.cost !== 'number') {
          throw new Error(`Evento no confirmado (HTTP ${eventRes.status})`);
        }
        setLastDecision({
          decisionId: eventId,
          campaign: { id: creative.campaignId, name: creative.campaignName },
          creative: { ...creative, title: creative.name, description: creative.targetUrl },
          placement, debitedCost: event.cost, nonce: eventId,
          signature: serveRes.headers.get('X-Solusol-Signature') || 'NO DISPONIBLE',
          atomicCheck: 'Evento aceptado y coste confirmado por el backend',
        });
        pushToast('Evento persistido en backend real', 'exito');
        await fetchState();
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