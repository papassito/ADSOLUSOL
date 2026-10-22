import React, { useState, useEffect, useCallback } from 'react';
import { useAdsolusolState } from './useAdsolusolState';
import { useAnalyticsCalculations } from './useAnalyticsCalculations';
import { apiFetch } from './services/api';
import { mapToBackendCreateDto } from './services/campaignAdapter';
import { MODULE_META, AI_PRESETS } from './constants';
import { ModuleKey, Campaign } from './types';

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
  const [globalSearch, setGlobalSearch] = useState('');
  const [commandOpen, setCommandOpen] = useState(false);
  const [commandQuery, setCommandQuery] = useState('');
  const [confirmDelete, setConfirmDelete] = useState<{
    collection: string;
    id: string;
    name: string;
  } | null>(null);

  const [drawerType, setDrawerType] = useState<
    null | 'campana' | 'ubicacion' | 'creativo' | 'asignacion'
  >(null);

  const [campForm, setCampForm] = useState({ name: '', budget: 150, maxCpc: 2.5 });
  const [plcForm, setPlcForm] = useState({
    code: 'solusol.portal.banner.nuevo',
    name: '',
    format: 'Banner 970x90 / Móvil 320x100',
    floorCpm: 14.0,
  });
  const [crtForm, setCrtForm] = useState({
    campaignId: 'CAMP-101',
    title: 'Laboratorio San Francisco | Resultados Hoy Mismo',
    description:
      'Análisis clínicos confiables en Hermosillo. ¡Abierto los Domingos! Visítanos sin cita previa.',
    destinationUrl: 'https://www.laboratoriosanfrancisco.com',
    whatsappContact: '662-123-4567',
    locationAddress: 'Laboratorio San Francisco, Oaxaca 63, Col. Centro, Hermosillo, Sonora',
    sitelinks: ['Check Up Básico \$500', 'Resultados WhatsApp'],
  });
  const [asgForm, setAsgForm] = useState({
    campaignId: 'CAMP-101', creativeId: 'CRT-501', placementId: 'PLC-01', weight: 100, priority: 1,
  });

  const {
    loadingAction, isAutoLive, setIsAutoLive, toasts, pushAlertBanner, setPushAlertBanner,
    pushPermission, requestBrowserPushPermission, dbState, lastDecision,
    competitorTerms, campaigns, placements, creatives, assignments, hourlyMetrics,
    auditLogs, alerts, audiences, users, sysHealth, fetchState, pushToast, handleServeDecision,
    setCompetitorTerms,
  } = useAdsolusolState();
  const { kpis, forecast7DaysData, trends24hData, total7DayPredictedSpend, total7DayShieldOptimized }
    = useAnalyticsCalculations(campaigns, hourlyMetrics, competitorTerms, creatives);

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

  const handleOpenDirectionsMaps = async (address: string) => {
    if (!address) { pushToast('Dirección no disponible', 'alerta'); return; }
    const mapsNavUrl = `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
      address
    )}&travelmode=driving`;
    window.open(mapsNavUrl, '_blank', 'noopener,noreferrer');
  };

  const simulateReach90Threshold = () => pushToast('Simulación desactivada en LIVE', 'alerta');

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

  const applyAiCreativePreset = () => {
    const randomPreset = AI_PRESETS[Math.floor(Math.random() * AI_PRESETS.length)];
    setCrtForm((prev) => ({ ...prev, ...randomPreset }));
    pushToast('Anuncio optimizado con IA Clínica + Ruta GPS de Sucursal', 'exito');
  };

  const handleCreateRecord = async (e: React.FormEvent) => {
    e.preventDefault();
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
          pushToast('Anuncio guardado. Copia el código de verificación del sitio en la sección de creativos.', 'exito');
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
      pushToast('La operación no fue confirmada por el backend.', 'alerta');
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

  const currentMeta = MODULE_META[activeModule];
  const campaignsOver90Count = campaigns.filter(
    (c: any) => c.budget > 0 && c.spent / c.budget >= 0.9
  ).length;

  return (
    <div
      style={{ fontFamily: "'Plus Jakarta Sans', sans-serif", background: 'var(--as-background)' }}
      className="as-app min-h-screen text-slate-100 flex antialiased selection:bg-brand-500 selection:text-slate-950"
    >
      <Sidebar
        activeModule={activeModule}
        onSelectModule={setActiveModule}
        campaignsOver90Count={campaignsOver90Count}
        totalDirections={kpis.totalDirections}
      />

      <div className="flex-1 flex flex-col min-w-0">
        <TopHeader
          currentMeta={currentMeta}
          isAutoLive={isAutoLive}
          onToggleAutoLive={() => {
            setIsAutoLive(!isAutoLive);
            pushToast(!isAutoLive ? 'Actualización automática activada' : 'Actualización automática pausada', 'info');
          }}
          pushPermission={pushPermission}
          onRequestPushPermission={requestBrowserPushPermission}
          globalSearch={globalSearch}
          onSearchChange={setGlobalSearch}
          onOpenCommand={() => setCommandOpen(true)}
          onOpenSystem={() => setActiveModule('sistema')}
          sysHealth={sysHealth}
          ledgerBalance={dbState?.ledgerBalance}
          loadingAction={loadingAction}
          onRefresh={fetchState}
        />

        <main className="p-6 space-y-6 overflow-y-auto flex-1">
          {activeModule === 'panel' && (
            <PanelView
              forecast7DaysData={forecast7DaysData}
              total7DayPredictedSpend={total7DayPredictedSpend}
              total7DayShieldOptimized={total7DayShieldOptimized}
              ledgerBalance={dbState?.ledgerBalance}
            />
          )}
          {activeModule === 'campanas' && (
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
              onApplyAiPreset={applyAiCreativePreset}
              onOpenDrawer={() => setDrawerType('creativo')}
              onOpenDirectionsMaps={handleOpenDirectionsMaps}
              onServeClick={() => handleServeDecision(true)}
              onDeleteCreative={(id, title) => setConfirmDelete({ collection: 'creatives', id, name: title })}
            />
          )}
          {activeModule === 'asignaciones' && (
            <AssignmentsView assignments={assignments} onNewAssignment={() => setDrawerType('asignacion')} />
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
              onInjectLiveClick={() => handleServeDecision(true)}
              onExportCsv={() => { /* Implementar exportación */ }}
            />
          )}
          {activeModule === 'audiencias' && (
            <AudiencesView
              competitorTerms={competitorTerms}
              onToggleBlockTerm={(id) => {
                setCompetitorTerms(terms => terms.map(t => t.id === id ? {...t, blocked: !t.blocked} : t));
                pushToast('La configuración de Shield™ es solo una simulación en el frontend.', 'info');
              }}
              shieldSavings={kpis.shieldSavings}
              audiences={audiences}
            />
          )}
          {activeModule === 'facturacion' && (
            <BillingView auditLogs={auditLogs} paymentMethod={dbState?.paymentMethod} ledgerBalance={dbState?.ledgerBalance} />
          )}
          {activeModule === 'alertas' && (
            <AlertsView campaigns={campaigns} alerts={alerts} onRequestPushPermission={requestBrowserPushPermission} />
          )}
          {activeModule === 'auditoria' && <AuditingView users={users} />}
          {activeModule === 'sistema' && <SystemHealthView sysHealth={sysHealth} />}
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
        campForm={campForm} setCampForm={setCampForm}
        plcForm={plcForm} setPlcForm={setPlcForm}
        crtForm={crtForm} setCrtForm={setCrtForm}
        asgForm={asgForm} setAsgForm={setAsgForm}
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
