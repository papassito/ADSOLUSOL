import React, { useState, useEffect, useCallback } from 'react';
import { apiFetch } from './services/api';
import { mapToBackendCreateDto } from './services/campaignAdapter';
import { MODULE_META, AI_PRESETS } from './constants';
import { ModuleKey, Campaign, Placement, Creative, Assignment, SystemHealth, AuditLog, Alert, Audience, User } from './types';

import { Sidebar } from './components/Sidebar';
import { TopHeader } from './components/TopHeader';
import { PanelView } from './PanelView';
import { CampaignsGrid } from './components/CampaignsGrid';
import { PlacementsView } from './PlacementsView';
import { CreativesView } from './CreativesView';
import { AssignmentsView } from './components/AssignmentsView';
import { ServeView } from './components/ServeView';
import { AnalyticsView } from './components/AnalyticsView';
import { AudiencesView } from './components/AudiencesView';
import { BillingView } from './components/BillingView';
import { AlertsView } from './components/AlertsView';
import { AuditingView } from './components/AuditingView';
import { SystemHealthView } from './components/SystemHealthView';
import { CommandPalette } from './components/CommandPalette';
import { ActionDrawer } from './components/ActionDrawer';
import { ConfirmDeleteModal } from './components/ConfirmDeleteModal';
import { ToastContainer } from './components/ToastContainer';
import { EmbedCodeGeneratorValidator } from './components/EmbedCodeGeneratorValidator';

export default function App() {
  const [activeModule, setActiveModule] = useState<ModuleKey>('panel');
  const [loadingAction, setLoadingAction] = useState(false);
  const [isAutoLive, setIsAutoLive] = useState(false); // Kept for UI, but simulation logic removed.
  const [toasts, setToasts] = useState<{ id: string; title: string; type: 'exito' | 'alerta' | 'info' }[]>([]);

  const [globalSearch, setGlobalSearch] = useState('');
  const [commandOpen, setCommandOpen] = useState(false);
  const [commandQuery, setCommandQuery] = useState('');
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
    const id = `toast-${Date.now()}`;
    setToasts((prev) => [...prev, { id, title, type }]);
    setTimeout(() => {
      setToasts((currentToasts) => currentToasts.filter((t) => t.id !== id));
    }, 5000);
  }, []);

  const fetchState = useCallback(async () => {
    setLoadingAction(true);
    const results = await Promise.allSettled([
      apiFetch('/api/Campaigns'),
      apiFetch('/api/Placements'),
      apiFetch('/api/Creatives'),
      apiFetch('/api/Health'),
    ]);
    setLoadingAction(false);

    const [campaignsRes, placementsRes, creativesRes, healthRes] = results;

    if (campaignsRes.status === 'fulfilled' && campaignsRes.value.ok) {
      const backendCampaigns = await campaignsRes.value.json();
      setCampaigns(backendCampaigns.map((c: any) => ({
        ...c, 
        name: c.name,
        spent: c.budgetSpent,
        status: String(c.status).toUpperCase() === 'ACTIVE' ? 'ACTIVA' : 'PAUSADA', // Simplified mapping
        backendStatus: String(c.status).toUpperCase(),
      })));
    } else {
      pushToast('Error al cargar campañas', 'alerta');
    }

    if (placementsRes.status === 'fulfilled' && placementsRes.value.ok) {
      const backendPlacements = await placementsRes.value.json();
      setPlacements(backendPlacements.map((p: any) => ({...p, name: p.name, code: p.placementCode})));
    } else {
        pushToast('Error al cargar ubicaciones', 'alerta');
    }

    if (creativesRes.status === 'fulfilled' && creativesRes.value.ok) {
      const backendCreatives = await creativesRes.value.json();
      setCreatives(backendCreatives.map((cr: any) => ({...cr, title: cr.name})));
    } else {
        pushToast('Error al cargar creativos', 'alerta');
    }

    if (healthRes.status === 'fulfilled' && healthRes.value.ok) setSysHealth(await healthRes.value.json());
    else pushToast('Error al cargar salud del sistema', 'alerta');

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
    const nextStatusBackend = currentBackendStatus === 'ACTIVE' ? 'PAUSED' : 'ACTIVE';
    const cleanId = camp.id; // Send the full ID as received

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
    setLoadingAction(true);
    e.preventDefault();
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
          pushToast('Anuncio guardado. Verifique el sitio en la sección de creativos.', 'exito');
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
    // The backend API expects the raw ID (GUID or long), not the prefixed string.
    // This stripping is necessary for the current API design to work, as the route
    // constraints are [HttpDelete("{id}")] and [HttpDelete("{id:long}")].
    // Sending the prefixed ID would result in a 404 Not Found.
    const cleanId = String(confirmDelete.id).replace(/^(CAMP-|PLC-|CRT-|ASG-)/, '');
    const canonicalCollection =
      confirmDelete.collection === 'campaigns' ? 'Campaigns' :
      confirmDelete.collection === 'placements' ? 'Placements' :
      confirmDelete.collection === 'creatives' ? 'Creatives' :
      confirmDelete.collection === 'assignments' ? 'Assignments' : confirmDelete.collection;

    try {
      const netRes = await apiFetch(`/api/${canonicalCollection}/${cleanId}`, {
        method: 'DELETE',
      });
      if (netRes.ok) { // Handles 204 No Content
        pushToast(`Registro "${confirmDelete.name}" eliminado.`, 'info');
        setConfirmDelete(null);
        await fetchState();
      } else {
        pushToast(`No se pudo eliminar (HTTP ${netRes.status})`, 'alerta');
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
          isAutoLive={false}
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
              onOpenDrawer={() => setDrawerType('creativo')}
              onDeleteCreative={(id, name) => setConfirmDelete({ collection: 'creatives', id, name })}
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
        loading={loadingAction}
      />
      <ToastContainer
        toasts={toasts}
    </div>
  );
}
