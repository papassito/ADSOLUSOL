import React, { useState, useEffect, useCallback } from 'react';
import { apiFetch } from './services/api';
import { mapToBackendCreateDto } from './services/campaignAdapter';
import { MODULE_META } from './constants';
import { ModuleKey, Campaign, Placement, Creative, SystemHealth } from './types';

import { Sidebar } from './components/Sidebar';
import { TopHeader } from './components/TopHeader';
import { PanelView } from './PanelView';
import { CampaignsGrid } from './components/CampaignsGrid';
import { PlacementsView } from './PlacementsView';
import { CreativesView } from './CreativesView';
import { SystemHealthView } from './components/SystemHealthView';
import { CommandPalette } from './components/CommandPalette';
import { ActionDrawer } from './components/ActionDrawer';
import { ConfirmDeleteModal } from './components/ConfirmDeleteModal';
import { ToastContainer } from './components/ToastContainer';
import { EmbedCodeGeneratorValidator } from './components/EmbedCodeGeneratorValidator';

let toastSeq = 0;

export default function App() {
  const [activeModule, setActiveModule] = useState<ModuleKey>('panel');
  const [loadingAction, setLoadingAction] = useState(false);
  const [toasts, setToasts] = useState<{ id: string; title: string; type: 'exito' | 'alerta' | 'info' }[]>([]);

  const [globalSearch, setGlobalSearch] = useState('');
  const [commandOpen, setCommandOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState<{
    collection: string;
    id: string;
    name: string;
  } | null>(null);

  // State variables to hold data from the real API
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [placements, setPlacements] = useState<Placement[]>([]);
  const [creatives, setCreatives] = useState<Creative[]>([]);
  const [sysHealth, setSysHealth] = useState<SystemHealth | null>(null);
  const [drawerType, setDrawerType] = useState<null | 'campana' | 'ubicacion' | 'creativo' | 'asignacion'>(null);
  const [campForm, setCampForm] = useState({ name: '', budget: 150, costPerClick: 2.5, costPerMille: 10 });
  const [plcForm, setPlcForm] = useState({
    code: 'solusol.portal.banner.nuevo',
    name: '',
    format: 'Banner 970x90 / Móvil 320x100',
    floorCpm: 14.0,
  });
  const [crtForm, setCrtForm] = useState({
    campaignId: '',
    name: '',
    description: '',
    contentUrl: 'https://',
    targetUrl: 'https://',
  });

  const pushToast = useCallback((title: string, type: 'exito' | 'alerta' | 'info' = 'exito') => {
    const id = `toast-${Date.now()}-${++toastSeq}`;
    setToasts((prev) => [...prev, { id, title, type }]);
    setTimeout(() => {
      setToasts((currentToasts) => currentToasts.filter((t) => t.id !== id));
    }, 5000);
  }, []);

  const fetchState = useCallback(async () => {
    setLoadingAction(true);
    try {
      const results = await Promise.allSettled([
        apiFetch('/api/Campaigns'),
        apiFetch('/api/Placements'),
        apiFetch('/api/Creatives'),
        apiFetch('/api/Health'),
      ]);

      const [campaignsRes, placementsRes, creativesRes, healthRes] = results;

      if (campaignsRes.status === 'fulfilled' && campaignsRes.value.ok) {
        const backendCampaigns = await campaignsRes.value.json();
        setCampaigns(backendCampaigns.map((c: any) => ({ 
          ...c,
          name: c.name || c.id,
          spent: Number(c.budgetSpent || c.spent || 0),
          status: String(c.status).toUpperCase() === 'ACTIVE' ? 'ACTIVA' : 'PAUSADA',
          backendStatus: String(c.status).toUpperCase(),
        })));
      } else {
        pushToast('Error al consultar campañas de la API', 'alerta');
      }

      if (placementsRes.status === 'fulfilled' && placementsRes.value.ok) {
        const backendPlacements = await placementsRes.value.json();
        setPlacements(backendPlacements.map((p: any) => ({
          ...p,
          name: p.name || p.placementCode,
          code: p.placementCode || p.code,
        })));
      } else {
        pushToast('Error al consultar ubicaciones de la API', 'alerta');
      }

      if (creativesRes.status === 'fulfilled' && creativesRes.value.ok) {
        const backendCreatives = await creativesRes.value.json();
        setCreatives(backendCreatives.map((cr: any) => ({
          ...cr,
          title: cr.name || cr.title || `Creativo #${cr.id}`,
        })));
      } else {
        pushToast('Error al consultar creativos de la API', 'alerta');
      }

      if (healthRes.status === 'fulfilled' && healthRes.value.ok) {
        setSysHealth(await healthRes.value.json());
      } else {
        setSysHealth(null);
      }
    } catch (err: any) {
      pushToast(`Fallo de conexión con la API: ${err?.message || 'Error de red'}`, 'alerta');
    } finally {
      setLoadingAction(false);
    }
  }, [pushToast]);

  useEffect(() => {
    fetchState();
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setCommandOpen((prev) => !prev);
      } else if (e.key === 'Escape') {
        setCommandOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [fetchState]);

  const handleToggleCampaignStatus = async (camp: Campaign) => {
    const currentBackendStatus = String(camp.backendStatus || camp.status).toUpperCase();
    const isCurrentlyActive = currentBackendStatus === 'ACTIVE' || currentBackendStatus === 'ACTIVA';
    const nextStatusBackend = isCurrentlyActive ? 'PAUSED' : 'ACTIVE';
    const cleanId = camp.id;

    try {
      const netRes = await apiFetch(`/api/Campaigns/${cleanId}/status`, {
        method: 'POST',
        body: JSON.stringify({ status: nextStatusBackend }),
      });

      if (netRes.ok) {
        pushToast(`Campaña ${camp.id} actualizada a estado ${nextStatusBackend}`, 'info');
        await fetchState();
      } else {
        const error = await netRes.json();
        pushToast(`Error ${netRes.status}: ${error.message || 'No se pudo actualizar'}`, 'alerta');
      }
    } catch (error) {
      pushToast('Error de red al actualizar campaña.', 'alerta');
    }
  };

  const handleCreateRecord = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingAction(true);
      if (drawerType === 'campana') {
        const netRes = await apiFetch('/api/Campaigns', {
          method: 'POST',
          body: JSON.stringify(mapToBackendCreateDto(campForm)),
        });
        if (netRes.ok) {
          pushToast('Campaña creada y persistida', 'exito');
          setDrawerType(null);
          await fetchState();
        } else {
          pushToast(`Error al crear campaña (HTTP ${netRes.status})`, 'alerta');
        }
      } else if (drawerType === 'ubicacion') {
        const netRes = await apiFetch('/api/Placements', {
          method: 'POST',
          body: JSON.stringify({
            placementCode: plcForm.code,
            isEnabled: true,
            name: plcForm.name,
            description: plcForm.name,
            floorCpm: Number(plcForm.floorCpm),
            format: plcForm.format,
          }),
        });
        if (netRes.ok) {
          pushToast('Ubicación registrada', 'exito');
          setDrawerType(null);
          await fetchState();
        } else {
          pushToast(`Error al crear ubicación (HTTP ${netRes.status})`, 'alerta');
        }
      } else if (drawerType === 'creativo') {
        const cleanCampId = crtForm.campaignId;
        const netRes = await apiFetch('/api/Creatives', {
          method: 'POST',
          body: JSON.stringify({
            campaignId: cleanCampId, // Backend expects the raw ID
            name: crtForm.name,
            isEnabled: true,
            contentUrl: crtForm.contentUrl,
            targetUrl: crtForm.targetUrl,
            description: crtForm.description,
          }),
        });
        if (netRes.ok) {
          pushToast('Anuncio guardado. Copia el código de verificación del sitio.', 'exito');
          setDrawerType(null);
          await fetchState();
        } else {
          pushToast(`Error al crear creativo (HTTP ${netRes.status})`, 'alerta');
        }
      } else if (drawerType === 'asignacion') {
        pushToast('La creación de asignaciones no está disponible.', 'info');
      }
    setLoadingAction(false);
  };

  const executeConfirmedDelete = async () => {
    if (!confirmDelete) return;
    setLoadingAction(true);
    const targetId = String(confirmDelete.id);
    const canonicalCollection =
      confirmDelete.collection === 'campaigns' ? 'Campaigns' :
      confirmDelete.collection === 'placements' ? 'Placements' :
      confirmDelete.collection === 'creatives' ? 'Creatives' :
      confirmDelete.collection === 'assignments' ? 'Assignments' : confirmDelete.collection;

    try {
      const netRes = await apiFetch(`/api/${canonicalCollection}/${encodeURIComponent(targetId)}`, {
        method: 'DELETE',
      });
      if (netRes.ok) { // Handles 204 No Content
        pushToast(`Registro "${confirmDelete.name}" eliminado.`, 'info');
        setConfirmDelete(null);
        await fetchState();
      } else {
        const errData = await netRes.json().catch(() => ({}));
        const msg = errData?.message || `HTTP ${netRes.status}`;
        pushToast(`No se pudo eliminar (${msg})`, 'alerta');
      }
    } catch (error) {
      pushToast('Error de red al eliminar.', 'alerta');
    } finally {
      setLoadingAction(false);
    }
  };

  const currentMeta = MODULE_META[activeModule];

  const totalDirections = creatives.reduce((sum, c) => sum + (c.directionsClicks || 0), 0);
  const campaignsOver90Count = campaigns.filter(
    (c: any) => c.budget > 0 && (c.spent || 0) / c.budget >= 0.9
  ).length;

  return (
    <div
      style={{ fontFamily: "'Plus Jakarta Sans', sans-serif" }}
      className="as-app min-h-screen text-slate-100 flex antialiased selection:bg-brand-500 selection:text-slate-950"
    >
      <Sidebar
        activeModule={activeModule}
        onSelectModule={setActiveModule}
        campaignsOver90Count={campaignsOver90Count}
        totalDirections={totalDirections}
      />

      <div className="flex-1 flex flex-col min-w-0">
        <TopHeader
          currentMeta={currentMeta}
          onToggleAutoLive={() => pushToast('Simulación de tráfico no disponible.', 'info')}
          pushPermission={'default'}
          onRequestPushPermission={() => pushToast('Notificaciones Push no implementadas.', 'info')}
          globalSearch={globalSearch}
          onSearchChange={setGlobalSearch}
          onOpenCommand={() => setCommandOpen(true)}
          onOpenSystem={() => setActiveModule('sistema')}
          sysHealth={sysHealth}
          ledgerBalance={null}
          loadingAction={loadingAction}
          onRefresh={fetchState}
        />

        <main className="p-3 sm:p-6 space-y-6 overflow-y-auto flex-1 min-w-0">
          {activeModule === 'panel' && (
            <PanelView
              campaigns={campaigns}
              systemHealth={sysHealth}
              campaignsAvailable={campaigns.length > 0}
              loading={loadingAction}
              onNavigate={setActiveModule}
            />
          )}
          {activeModule === 'campanas' && (
            <CampaignsGrid
              campaigns={campaigns}
              globalSearch={globalSearch}
              onNewCampaign={() => setDrawerType('campana')}
              onToggleStatus={handleToggleCampaignStatus}
              onDelete={(collection, id, name) => setConfirmDelete({ collection, id, name })}
            />
          )}
          {activeModule === 'ubicaciones' && (
            <div className="space-y-6">
              <PlacementsView
                placements={placements}
                onNewPlacement={() => setDrawerType('ubicacion')}
                onDeletePlacement={(id, name) => setConfirmDelete({ collection: 'placements', id, name })}
              />
              <EmbedCodeGeneratorValidator />
            </div>
          )}
          {activeModule === 'creativos' && (
            <CreativesView
              creatives={creatives}
              crtForm={crtForm}
              setCrtForm={setCrtForm}
              onApplyAiPreset={() => pushToast('Plantillas con IA no disponibles en este entorno.', 'info')}
              onOpenDrawer={() => setDrawerType('creativo')}
              onOpenDirectionsMaps={handleOpenDirectionsMaps}
              onServeClick={() => pushToast('Servicio de anuncios en vivo gestionado por el Ad Server.', 'info')}
              onDeleteCreative={(id, title) => setConfirmDelete({ collection: 'creatives', id, name: title })}
            />
          )}
          {activeModule === 'asignaciones' && (
            <div className="as-card-premium rounded-2xl p-6 text-center text-slate-400">Módulo no disponible. Endpoint de listado (`GET /api/Assignments`) no implementado.</div>
          )}
          {activeModule === 'entrega' && (
            <div className="as-card-premium rounded-2xl p-6 text-center text-slate-400">Módulo no disponible. Endpoint de simulación (`/api/Serve`) no implementado.</div>
          )}
          {activeModule === 'analitica' && (
            <div className="as-card-premium rounded-2xl p-6 text-center text-slate-400">Módulo no disponible. Endpoint de métricas globales no implementado.</div>
          )}
          {activeModule === 'audiencias' && (
            <div className="as-card-premium rounded-2xl p-6 text-center text-slate-400">Módulo no disponible. Endpoints de audiencias no implementados.</div>
          )}
          {activeModule === 'facturacion' && (
            <div className="as-card-premium rounded-2xl p-6 text-center text-slate-400">Módulo no disponible. Endpoint de Ledger no implementado.</div>
          )}
          {activeModule === 'alertas' && (
            <div className="as-card-premium rounded-2xl p-6 text-center text-slate-400">Módulo no disponible. Endpoint de alertas no implementado.</div>
          )}
          {activeModule === 'auditoria' && (
             <div className="as-card-premium rounded-2xl p-6 text-center text-slate-400">Módulo no disponible. Endpoint de logs de auditoría no implementado.</div>
          )}
          {activeModule === 'sistema' && <SystemHealthView sysHealth={sysHealth} />}
        </main>
      </div>

      <CommandPalette
        isOpen={commandOpen}
        onClose={() => setCommandOpen(false)}
        onSelectModule={setActiveModule}
      />
      <ActionDrawer
        drawerType={drawerType}
        onClose={() => setDrawerType(null)}
        onSubmit={handleCreateRecord}
        campForm={campForm} setCampForm={setCampForm}
        plcForm={plcForm} setPlcForm={setPlcForm}
        crtForm={crtForm} setCrtForm={setCrtForm}
      />
      <ConfirmDeleteModal
        confirmDelete={confirmDelete}
        onCancel={() => setConfirmDelete(null)}
        onConfirm={executeConfirmedDelete}
      />
      <ToastContainer
        toasts={toasts}
      />
    </div>
  );
}
