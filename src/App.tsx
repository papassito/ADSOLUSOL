import React, { useState, useEffect, useCallback } from 'react';
import { BellRing, X } from 'lucide-react';
import { ModuleKey, Campaign } from './types';
import { MODULE_META, AI_PRESETS } from './constants';
import { useAdsolusolState } from './useAdsolusolState';
import { useAnalyticsCalculations } from './useAnalyticsCalculations';
import { apiFetch } from './services/api';
import { mapToBackendCreateDto } from './services/campaignAdapter';

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
import { ActionDrawer } from './components/ActionDrawer';
import { CommandPalette } from './components/CommandPalette';
import { ConfirmDeleteModal } from './components/ConfirmDeleteModal';
import { ToastContainer } from './components/ToastContainer';

export default function App() {
  const [activeModule, setActiveModule] = useState<ModuleKey>('panel');
  const [globalSearch, setGlobalSearch] = useState('');
  const [commandOpen, setCommandOpen] = useState(false);
  const [commandQuery, setCommandQuery] = useState('');
  const [confirmDelete, setConfirmDelete] = useState<{
    collection: string;
    id: string;
    name: string;
  } | null>(null);

  const [drawerType, setDrawerType] = useState<null | 'campana' | 'ubicacion' | 'creativo' | 'asignacion'>(null);

  const [campForm, setCampForm] = useState({
    name: '',
    strategy: 'Pacing Ponderado + CPC',
    budget: 150,
    maxCpc: 2.5,
  });
  const [plcForm, setPlcForm] = useState({
    code: 'solusol.portal.banner.nuevo',
    name: '',
    format: 'Banner 970x90 / Móvil 320x100',
    floorCpm: 14.0,
  });
  const [crtForm, setCrtForm] = useState({
    campaignId: 'CAMP-101',
    title: 'Laboratorio San Francisco | Resultados Hoy Mismo',
    description: 'Análisis clínicos confiables en Hermosillo. ¡Abierto los Domingos!',
    destinationUrl: 'https://www.laboratoriosanfrancisco.com',
    whatsappContact: '662-123-4567',
    locationAddress: 'Laboratorio San Francisco, Oaxaca 63, Col. Centro, Hermosillo, Sonora',
  });
  const [asgForm, setAsgForm] = useState({
    campaignId: 'CAMP-101',
    creativeId: 'CRT-501',
    placementId: 'PLC-01',
    weight: 100,
    priority: 1,
  });

  const {
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
  } = useAdsolusolState();

  const {
    kpis,
    forecast7DaysData,
    trends24hData,
    total7DayPredictedSpend,
    total7DayShieldOptimized,
  } = useAnalyticsCalculations(campaigns, hourlyMetrics, competitorTerms, creatives);

  useEffect(() => {
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
  }, []);

  const handleToggleCampaignStatus = async (camp: Campaign) => {
    const nextStatus = camp.status === 'ACTIVA' ? 'PAUSADA' : 'ACTIVA';
    const nextStatusBackend = camp.status === 'ACTIVA' ? 'PAUSED' : 'ACTIVE';
    const cleanId = String(camp.id).replace('CAMP-', '');

    const netRes = await apiFetch(`/api/Campaigns/${cleanId}/status`, {
      method: 'POST',
      body: JSON.stringify({ status: nextStatusBackend }),
    });

    if (netRes.ok) {
      pushToast(`Campaña ${camp.id} actualizada a estado ${nextStatus} (.NET 8)`, 'info');
      await fetchState();
      return;
    }

    pushToast(`No se pudo actualizar la campaña (HTTP ${netRes.status})`, 'alerta');
  };

  const handleOpenDirectionsMaps = async (address: string) => {
    if (!address) { pushToast('Dirección no disponible', 'alerta'); return; }
    const mapsNavUrl = `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
      address
    )}&travelmode=driving`;
    window.open(mapsNavUrl, '_blank', 'noopener,noreferrer');
  };

  const applyAiCreativePreset = () => {
    if (import.meta.env.VITE_DEMO_MODE !== 'true') { pushToast('Generación IA no disponible: proveedor sin conectar', 'alerta'); return; }
    const randomPreset = AI_PRESETS[Math.floor(Math.random() * AI_PRESETS.length)];
    setCrtForm((prev) => ({
      ...prev,
      title: randomPreset.title,
      description: randomPreset.description,
      locationAddress: randomPreset.locationAddress,
    }));
    pushToast('Anuncio optimizado con IA Clínica + Ruta GPS de Sucursal', 'exito');
  };

  const exportCsvReport = useCallback(() => {
    const headers = 'ID,Campaña,Estado,Estrategia,Presupuesto,Gastado,Impresiones,Clics,CTR\n';
    const rows = campaigns
      .map((c: any) => {
        const ctr = c.impressions > 0 ? ((c.clicks / c.impressions) * 100).toFixed(2) : '0.00';
        return `${c.id},"${c.name}",${c.status},"${c.strategy}",${c.budget},${c.spent},${c.impressions},${c.clicks},${ctr}%`;
      })
      .join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'ADSOLUSOL_Auditoria_Operativa.csv';
    a.click();
    URL.revokeObjectURL(url);
    pushToast('Reporte CSV exportado con métricas verificadas', 'exito');
  }, [campaigns, pushToast]);

  const handleCreateRecord = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (drawerType === 'campana') {
        const netRes = await apiFetch('/api/Campaigns', {
          method: 'POST',
          body: JSON.stringify(mapToBackendCreateDto(campForm)),
        });
        if (netRes.ok) {
          pushToast('Campaña creada y persistida (.NET 8)', 'exito');
          setDrawerType(null);
          await fetchState();
          return;
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
          pushToast('Ubicación registrada (.NET 8)', 'exito');
          setDrawerType(null);
          await fetchState();
          return;
        }
      } else if (drawerType === 'creativo') {
        const cleanCampId = Number(String(crtForm.campaignId).replace('CAMP-', '')) || 1;
        const netRes = await apiFetch('/api/Creatives', {
          method: 'POST',
          body: JSON.stringify({
            campaignId: cleanCampId,
            name: crtForm.title,
            isEnabled: true,
            contentUrl: crtForm.destinationUrl,
            targetUrl: crtForm.destinationUrl,
            description: crtForm.description,
            locationAddress: crtForm.locationAddress,
            whatsappContact: crtForm.whatsappContact,
          }),
        });
        if (netRes.ok) {
          pushToast('Creativo registrado (.NET 8)', 'exito');
          setDrawerType(null);
          await fetchState();
          return;
        }
      } else if (drawerType === 'asignacion') {
        const cleanCampId = String(asgForm.campaignId).replace('CAMP-', '');
        const cleanCrtId = Number(String(asgForm.creativeId).replace('CRT-', '')) || 1;
        const cleanPlcId = Number(String(asgForm.placementId).replace('PLC-', '')) || 1;

        const [plcAssignRes, crtAssignRes] = await Promise.all([
          apiFetch('/api/assignments/placement', {
            method: 'POST',
            body: JSON.stringify({ campaignId: cleanCampId, entityId: cleanPlcId }),
          }),
          apiFetch('/api/assignments/creative', {
            method: 'POST',
            body: JSON.stringify({ campaignId: cleanCampId, entityId: cleanCrtId }),
          }),
        ]);

        if (plcAssignRes.ok && crtAssignRes.ok) {
          pushToast('Asignación vinculada (.NET 8)', 'exito');
          setDrawerType(null);
          await fetchState();
          return;
        }
      }

      throw new Error('El backend no confirmó la operación.');
    } catch (error) {
      console.error('Error al persistir registro', error);
      pushToast(error instanceof Error ? error.message : 'Error al persistir registro', 'alerta');
    }
  };

  const executeConfirmedDelete = async () => {
    if (!confirmDelete) return;
    const cleanId = String(confirmDelete.id).replace(/^(CAMP-|PLC-|CRT-|ASG-)/, '');
    const canonicalCollection =
      confirmDelete.collection === 'campaigns' ? 'Campaigns' :
      confirmDelete.collection === 'placements' ? 'Placements' :
      confirmDelete.collection === 'creatives' ? 'Creatives' :
      confirmDelete.collection === 'assignments' ? 'Assignments' : confirmDelete.collection;

    const netRes = await apiFetch(`/api/${canonicalCollection}/${cleanId}`, {
      method: 'DELETE',
    });
    if (netRes.ok) {
      pushToast(`Registro "${confirmDelete.name}" eliminado (.NET 8)`, 'alerta');
      setConfirmDelete(null);
      await fetchState();
      return;
    }
    pushToast(`No se pudo eliminar (HTTP ${netRes.status})`, 'alerta');
  };

  const handleToggleBlockTerm = (id: string) => {
    if (import.meta.env.VITE_DEMO_MODE !== 'true') { pushToast('Bloqueo no disponible: proveedor sin conectar', 'alerta'); return; }
    setCompetitorTerms((prev) =>
      prev.map((t) => (t.id === id ? { ...t, blocked: !t.blocked } : t))
    );
    pushToast('Estado de término en escudo actualizado', 'info');
  };

  const currentMeta = MODULE_META[activeModule];
  const campaignsOver90Count = campaigns.filter((c: any) => c.budget > 0 && c.spent / c.budget >= 0.9).length;


  return (
    <div
      style={{
        fontFamily: "'Plus Jakarta Sans', sans-serif",
        background: 'radial-gradient(circle at 18% 0%, #132038 0%, #070B12 58%)',
      }}
      className="min-h-screen text-slate-100 flex antialiased selection:bg-amber-500 selection:text-slate-950"
    >
      <Sidebar
        activeModule={activeModule}
        onSelectModule={setActiveModule}
        campaignsOver90Count={campaignsOver90Count}
        totalDirections={kpis.totalDirections}
      />

      <div className="flex-1 flex flex-col min-w-0">
        {pushAlertBanner && (
          <div className="bg-gradient-to-r from-rose-600/90 via-amber-600/90 to-rose-600/90 text-white px-6 py-2.5 flex items-center justify-between text-xs font-bold shadow-lg z-30">
            <div className="flex items-center gap-2">
              <BellRing className="h-4 w-4 animate-bounce shrink-0" />
              <span>{pushAlertBanner}</span>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setActiveModule('campanas')}
                className="px-2.5 py-1 rounded bg-black/30 hover:bg-black/50 text-[11px] cursor-pointer"
              >
                Ajustar Presupuesto
              </button>
              <button
                onClick={() => setPushAlertBanner(null)}
                className="p-1 hover:bg-black/20 rounded cursor-pointer"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        )}

        <TopHeader
          currentMeta={currentMeta}
          isAutoLive={isAutoLive}
          onToggleAutoLive={() => setIsAutoLive(!isAutoLive)}
          pushPermission={pushPermission}
          onRequestPushPermission={requestBrowserPushPermission}
          globalSearch={globalSearch}
          onSearchChange={setGlobalSearch}
          onOpenCommand={() => setCommandOpen(true)}
          onOpenSystem={() => setActiveModule('sistema')}
          sysHealth={sysHealth}
          ledgerBalance={dbState?.ledgerBalance ?? null}
          loadingAction={loadingAction}
          onRefresh={fetchState}
        />

        <main className="p-6 space-y-6 overflow-y-auto flex-1">
          {activeModule === 'panel' && (
            <PanelView
              forecast7DaysData={forecast7DaysData}
              total7DayPredictedSpend={total7DayPredictedSpend}
              total7DayShieldOptimized={total7DayShieldOptimized}
              ledgerBalance={dbState?.ledgerBalance ?? null}
            />
          )}

          {(activeModule === 'panel' || activeModule === 'campanas') && (
            <CampaignsGrid
              campaigns={campaigns}
              globalSearch={globalSearch}
              onNewCampaign={() => setDrawerType('campana')}
              onToggleStatus={handleToggleCampaignStatus}
              onDelete={(collection, id, name) => setConfirmDelete({ collection, id, name })}
              onServeClick={() => handleServeDecision(true)}
              pushToast={pushToast}
            />
          )}

          {activeModule === 'ubicaciones' && (
            <PlacementsView
              placements={placements}
              onNewPlacement={() => setDrawerType('ubicacion')}
              onDeletePlacement={(id, name) => setConfirmDelete({ collection: 'placements', id, name })}
            />
          )}

          {activeModule === 'creativos' && (
            <CreativesView
              creatives={creatives}
              crtForm={crtForm}
              setCrtForm={setCrtForm}
              onApplyAiPreset={applyAiCreativePreset}
              onOpenDrawer={() => setDrawerType('creativo')}
              onOpenDirectionsMaps={handleOpenDirectionsMaps}
              onServeClick={() => handleServeDecision(true)}
              onDeleteCreative={(id, title) => setConfirmDelete({ collection: 'creatives', id, name: title })}
            />
          )}

          {activeModule === 'asignaciones' && (
            <AssignmentsView
              assignments={assignments}
              onNewAssignment={() => setDrawerType('asignacion')}
            />
          )}

          {activeModule === 'entrega' && (
            <ServeView
              lastDecision={lastDecision}
              onServeImpression={() => handleServeDecision(false)}
              onServeClick={() => handleServeDecision(true)}
              onOpenDirectionsMaps={handleOpenDirectionsMaps}
            />
          )}

          {activeModule === 'analitica' && (
            <AnalyticsView
              trends24hData={trends24hData}
              hourlyMetrics={hourlyMetrics}
              onInjectLiveClick={() => handleServeDecision(true, undefined, false)}
              onExportCsv={exportCsvReport}
            />
          )}

          {activeModule === 'audiencias' && (
            <AudiencesView
              competitorTerms={competitorTerms}
              onToggleBlockTerm={handleToggleBlockTerm}
              shieldSavings={kpis.shieldSavings}
              audiences={audiences}
            />
          )}

          {activeModule === 'facturacion' && (
            <BillingView
              auditLogs={auditLogs}
              paymentMethod={dbState?.paymentMethod}
              ledgerBalance={dbState?.ledgerBalance ?? null}
            />
          )}

          {activeModule === 'alertas' && (
            <AlertsView
              campaigns={campaigns}
              alerts={alerts}
              onRequestPushPermission={requestBrowserPushPermission}
            />
          )}

          {activeModule === 'auditoria' && (
            <AuditingView users={users} />
          )}

          {activeModule === 'sistema' && (
            <SystemHealthView sysHealth={sysHealth} />
          )}
        </main>
      </div>

      <CommandPalette
        isOpen={commandOpen}
        onClose={() => setCommandOpen(false)}
        query={commandQuery}
        onQueryChange={setCommandQuery}
        onSelectModule={setActiveModule}
        onOpenGps={() => handleOpenDirectionsMaps(crtForm.locationAddress)}
      />

      <ActionDrawer
        drawerType={drawerType}
        onClose={() => setDrawerType(null)}
        onSubmit={handleCreateRecord}
        campForm={campForm}
        setCampForm={setCampForm}
        plcForm={plcForm}
        setPlcForm={setPlcForm}
        crtForm={crtForm}
        setCrtForm={setCrtForm}
        asgForm={asgForm}
        setAsgForm={setAsgForm}
        onApplyAiPreset={applyAiCreativePreset}
      />

      <ConfirmDeleteModal
        confirmDelete={confirmDelete}
        onCancel={() => setConfirmDelete(null)}
        onConfirm={executeConfirmedDelete}
      />

      <ToastContainer toasts={toasts} />
    </div>
  );
}
