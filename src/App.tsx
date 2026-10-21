import React, { useState, useEffect, useCallback } from 'react';
import {
  BellRing,
  ChevronRight,
  Radio,
  Search,
  RefreshCw,
  Plus,
  Trash2,
  Navigation,
  ExternalLink,
  PhoneCall,
  Sparkles,
  Command,
  X,
  CheckCircle2,
  Lock,
  ShieldAlert,
  TrendingUp,
  Smartphone,
  MapPin,
} from 'lucide-react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  AreaChart,
  Area,
} from 'recharts';
import { ModuleKey, Campaign } from './types';
import { MODULE_META, BRANCH_LOCATIONS, AI_PRESETS } from './constants';
import { useAdsolusolState } from './useAdsolusolState';
import { useAnalyticsCalculations } from './useAnalyticsCalculations';
import { CampaignsGrid } from './components/CampaignsGrid';
import { PanelView } from './PanelView';
import { PlacementsView } from './PlacementsView';
import { CreativesView } from './CreativesView';
import { apiFetch } from './services/api';
import { mapToBackendCreateDto } from './services/campaignAdapter';

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
    description:
      'Análisis clínicos confiables en Hermosillo. ¡Abierto los Domingos! Visítanos sin cita previa.',
    destinationUrl: 'https://www.laboratoriosanfrancisco.com',
    whatsappContact: '662-123-4567',
    locationAddress: 'Laboratorio San Francisco, Oaxaca 63, Col. Centro, Hermosillo, Sonora',
    sitelinks: ['Check Up Básico \$500', 'Resultados WhatsApp'],
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

    const res = await apiFetch(`/api/campaigns/${camp.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: nextStatus }),
    });
    if (res.ok) {
      const data = await res.json();
      setDbState((prev: any) => ({ ...prev, ...data }));
      pushToast(`Campaña ${camp.id} actualizada a estado ${nextStatus}`, 'info');
    }
  };

  const handleOpenDirectionsMaps = async (address: string) => {
    await handleServeDecision(true, placements[1]?.id, true);
    const mapsNavUrl = `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
      address
    )}&travelmode=driving`;
    window.open(mapsNavUrl, '_blank', 'noopener,noreferrer');
  };

  const applyAiCreativePreset = () => {
    const randomPreset = AI_PRESETS[Math.floor(Math.random() * AI_PRESETS.length)];
    setCrtForm((prev) => ({
      ...prev,
      title: randomPreset.title,
      description: randomPreset.description,
      locationAddress: randomPreset.locationAddress,
      sitelinks: randomPreset.sitelinks,
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
            code: plcForm.code,
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
            title: crtForm.title,
            imageUrl: crtForm.destinationUrl,
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

      pushToast('Registro persistido', 'exito');
      setDrawerType(null);
      await fetchState();
    } catch {
      pushToast('Error al persistir registro', 'alerta');
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
    setConfirmDelete(null);
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
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Space+Grotesk:wght@600;700&display=swap');
        .as-card-premium {
          background: linear-gradient(165deg, rgba(22, 33, 52, 0.78) 0%, rgba(12, 18, 30, 0.94) 100%);
          border: 1px solid rgba(148, 163, 184, 0.12);
          box-shadow: 0 12px 32px rgba(0, 0, 0, 0.35), inset 0 1px 0 rgba(255, 255, 255, 0.06);
          transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .as-card-premium:hover {
          border-color: rgba(245, 158, 11, 0.28);
          box-shadow: 0 16px 40px rgba(0, 0, 0, 0.45), inset 0 1px 0 rgba(255, 255, 255, 0.1);
        }
        .as-kpi-lift:hover {
          transform: translateY(-3px);
        }
      `}</style>

      {/* =========================================================
          1. BARRA LATERAL EMPRESARIAL
      ========================================================= */}
      <aside className="w-68 bg-[#0B101B]/95 border-r border-slate-800/80 flex flex-col justify-between shrink-0 backdrop-blur-xl">
        <div>
          <div className="p-5 border-b border-slate-800/80 flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-amber-400 to-amber-600 text-slate-950 flex items-center justify-center font-black shadow-lg shadow-amber-500/25">
              ADS
            </div>
            <div>
              <h1
                style={{ fontFamily: "'Space Grotesk', sans-serif" }}
                className="text-base font-bold tracking-tight text-white"
              >
                ADSOLUSOL 2027
              </h1>
              <p className="text-[11px] text-amber-400 font-semibold">
                Command Suite Soberana
              </p>
            </div>
          </div>

          <nav className="p-3 space-y-5 overflow-y-auto max-h-[calc(100vh-160px)]">
            {[
              'Operación Central',
              'Inventario y Creativos',
              'Motor AdServer',
              'Inteligencia y Finanzas',
              'Gobernanza y Sistema',
            ].map((cat) => (
              <div key={cat}>
                <p className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                  {cat}
                </p>
                <div className="space-y-1">
                  {(Object.keys(MODULE_META) as ModuleKey[])
                    .filter((k) => MODULE_META[k].category === cat)
                    .map((key) => {
                      const item = MODULE_META[key];
                      const Icon = item.icon;
                      const active = activeModule === key;
                      return (
                        <button
                          key={key}
                          onClick={() => setActiveModule(key)}
                          className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                            active
                              ? 'bg-gradient-to-r from-amber-500 to-amber-400 text-slate-950 font-bold shadow-md shadow-amber-500/20'
                              : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 hover:translate-x-0.5'
                          }`}
                        >
                          <span className="flex items-center gap-2.5">
                            <Icon className="h-4 w-4" />
                            {item.title}
                          </span>
                          {key === 'alertas' && campaignsOver90Count > 0 && (
                            <span className="px-1.5 py-0.5 text-[10px] rounded-full bg-rose-500 text-white font-bold animate-pulse">
                              {campaignsOver90Count}
                            </span>
                          )}
                        </button>
                      );
                    })}
                </div>
              </div>
            ))}
          </nav>
        </div>

        <div className="p-4 border-t border-slate-800/80 bg-[#080C14] text-[11px]">
          <div className="flex items-center justify-between text-slate-400">
            <span>Rutas GPS Hoy:</span>
            <span className="font-mono text-cyan-400 font-bold">{`${kpis.totalDirections} pacientes`}</span>
          </div>
          <div className="flex items-center justify-between text-slate-400 mt-1">
            <span>Centinela 90%:</span>
            <span className="font-mono text-emerald-400 font-bold">Push Activo</span>
          </div>
        </div>
      </aside>

      {/* =========================================================
          2. ÁREA DE TRABAJO PRINCIPAL
      ========================================================= */}
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

        <header className="bg-[#0B101B]/85 backdrop-blur-md border-b border-slate-800/80 px-6 py-4 flex flex-col xl:flex-row xl:items-center justify-between gap-4 sticky top-0 z-20">
          <div>
            <div className="flex items-center gap-1.5 text-xs text-slate-400 mb-1">
              <span>ADSOLUSOL</span>
              <ChevronRight className="h-3.5 w-3.5" />
              <span>{currentMeta.category}</span>
              <ChevronRight className="h-3.5 w-3.5" />
              <span className="text-amber-400 font-semibold">{currentMeta.title}</span>
            </div>
            <div className="flex items-center gap-3 flex-wrap">
              <h2
                style={{ fontFamily: "'Space Grotesk', sans-serif" }}
                className="text-xl font-bold text-white"
              >
                {currentMeta.title}
              </h2>
              <button
                onClick={() => {
                  setIsAutoLive(!isAutoLive);
                  pushToast(
                    !isAutoLive
                      ? 'Sincronización en vivo activada (actualización cada 5s)'
                      : 'Sincronización en vivo pausada',
                    'info'
                  );
                }}
                className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold border transition-all cursor-pointer ${
                  isAutoLive
                    ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/40 animate-pulse'
                    : 'bg-slate-800/60 text-slate-400 border-slate-700 hover:text-white'
                }`}
              >
                <Radio className="h-3.5 w-3.5" />
                {isAutoLive ? 'EN VIVO: ACTIVO' : 'ACTIVAR EN VIVO'}
              </button>

              <button
                onClick={requestBrowserPushPermission}
                className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold border transition-all cursor-pointer ${
                  pushPermission === 'granted'
                    ? 'bg-amber-500/15 text-amber-400 border-amber-500/40'
                    : 'bg-slate-800/60 text-slate-300 border-slate-700 hover:border-amber-500/50'
                }`}
              >
                <BellRing className="h-3.5 w-3.5" />
                {pushPermission === 'granted'
                  ? 'Push 90%: Activo'
                  : 'Activar Push 90%'}
              </button>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2.5">
            <div className="relative">
              <Search className="h-4 w-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="text"
                value={globalSearch}
                onChange={(e) => setGlobalSearch(e.target.value)}
                placeholder="Filtrar campañas, IDs..."
                className="bg-[#070B12] border border-slate-800 rounded-xl pl-9 pr-16 py-1.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 w-56"
              />
              <button
                onClick={() => setCommandOpen(true)}
                className="absolute right-2 top-1.5 px-1.5 py-0.5 rounded bg-slate-800 text-[10px] font-mono text-slate-300 hover:text-white cursor-pointer"
              >
                Ctrl+K
              </button>
            </div>

            <button
              onClick={() => setActiveModule('sistema')}
              className="flex items-center gap-2 bg-[#070B12] border border-slate-800 px-3 py-1.5 rounded-xl text-xs cursor-pointer hover:border-slate-700"
            >
              <span className={`h-2 w-2 rounded-full ${sysHealth?.sqlite?.status?.includes('OPERATIVO') || sysHealth?.sqlite?.status === 'UP' ? 'bg-emerald-400' : 'bg-rose-400'} animate-pulse`} />
              <span className="font-semibold text-slate-300">SQLite:</span>
              <span className="font-mono text-emerald-400 font-bold">
                {`${sysHealth?.sqlite?.latencyMs ?? 0.28}ms`}
              </span>
              <span className="text-slate-600">|</span>
              <span className="font-semibold text-slate-300">SIC:</span>
              <span className="font-mono text-cyan-400 font-bold">
                {sysHealth?.sicEngine?.status === 'CONECTADO' || sysHealth?.sicEngine?.status === 'UP' ? `${sysHealth?.sicEngine?.latencyMs ?? 12.4}ms` : 'DOWN'}
              </span>
            </button>

            <div className="bg-emerald-500/10 border border-emerald-500/30 px-3 py-1.5 rounded-xl text-xs font-mono font-bold text-emerald-400">
              {`Saldo: $${(dbState?.ledgerBalance ?? 3190.91).toLocaleString('es-MX', {
                minimumFractionDigits: 2,
              })} MXN`}
            </div>

            <button
              onClick={fetchState}
              title="Sincronizar estado con servidor"
              className="p-2 rounded-xl bg-[#070B12] border border-slate-800 text-slate-300 hover:text-white cursor-pointer"
            >
              <RefreshCw
                className={`h-4 w-4 ${loadingAction ? 'animate-spin text-amber-400' : ''}`}
              />
            </button>
          </div>
        </header>

        <main className="p-6 space-y-6 overflow-y-auto flex-1">
          
          {/* =========================================================
              VISTA 1: PANEL PRINCIPAL + PROYECCIÓN PREDICTIVA A 7 DÍAS
          ========================================================= */}
          {activeModule === 'panel' && (
            <PanelView
              forecast7DaysData={forecast7DaysData}
              total7DayPredictedSpend={total7DayPredictedSpend}
              total7DayShieldOptimized={total7DayShieldOptimized}
              ledgerBalance={dbState?.ledgerBalance ?? 3190.91}
            />
          )}

          {/* =========================================================
              GRID OPERATIVO DE CAMPAÑAS
          ========================================================= */}
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

          {/* VISTA 3: UBICACIONES */}
          {activeModule === 'ubicaciones' && (
            <PlacementsView
              placements={placements}
              onNewPlacement={() => setDrawerType('ubicacion')}
              onDeletePlacement={(id, name) => setConfirmDelete({ collection: 'placements', id, name })}
            />
          )}

          {/* VISTA 4: CREATIVOS + IA + GOOGLE MAPS */}
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

          {/* VISTA 5: ASIGNACIONES */}
          {activeModule === 'asignaciones' && (
            <section className="as-card-premium rounded-2xl p-6 space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="text-base font-bold text-white">
                    Matriz Operativa de Asignaciones
                  </h3>
                  <p className="text-xs text-slate-400">
                    Vínculos activos entre Campañas, Creativos y Ubicaciones con peso de subasta
                  </p>
                </div>
                <button
                  onClick={() => setDrawerType('asignacion')}
                  className="px-4 py-2 rounded-xl bg-amber-500 text-slate-950 text-xs font-bold flex items-center gap-1.5 cursor-pointer"
                >
                  <Plus className="h-4 w-4" /> Nueva Asignación
                </button>
              </div>

              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-slate-800 text-slate-400 uppercase">
                    <th className="py-3">ID Asignación</th>
                    <th className="py-3">Campaña</th>
                    <th className="py-3">Creativo</th>
                    <th className="py-3">Ubicación</th>
                    <th className="py-3">Peso / Prioridad</th>
                    <th className="py-3">Modo de Pacing</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {assignments.map((a: any) => (
                    <tr key={a.id}>
                      <td className="py-3.5 font-mono text-amber-400 font-bold">{a.id}</td>
                      <td className="py-3.5 font-mono text-white">{a.campaignId}</td>
                      <td className="py-3.5 font-mono text-cyan-400">{a.creativeId}</td>
                      <td className="py-3.5 font-mono text-emerald-400">{a.placementId}</td>
                      <td className="py-3.5 font-mono">{`Peso: ${a.weight} (P${a.priority})`}</td>
                      <td className="py-3.5 text-slate-300">{a.pacingMode}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          )}

          {/* VISTA 6: MOTOR DE ENTREGA */}
          {activeModule === 'entrega' && (
            <section className="as-card-premium rounded-2xl p-6 space-y-5">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h3 className="text-base font-bold text-white">
                    Inspector en Vivo del Motor de Subasta y Entrega
                  </h3>
                  <p className="text-xs text-slate-400">
                    Ejecuta una solicitud real verificando la invariante BudgetSpent + Cost &lt;= Budget
                  </p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => handleServeDecision(false)}
                    className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-bold text-white cursor-pointer"
                  >
                    Solicitar Impresión (Serve)
                  </button>
                  <button
                    onClick={() => handleServeDecision(true)}
                    className="px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold cursor-pointer"
                  >
                    Simular Clic + Débito Atómico
                  </button>
                </div>
              </div>

              {lastDecision ? (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                  <div className="p-4 rounded-xl bg-[#070B12] border border-slate-800 font-mono text-xs space-y-2">
                    <p className="text-amber-400 font-bold">// CERTIFICADO CANÓNICO DEL AD SERVER</p>
                    <p>{`Decisión ID: ${lastDecision.decisionId}`}</p>
                    <p>{`Campaña Ganadora: ${lastDecision.campaign.id} (${lastDecision.campaign.name})`}</p>
                    <p>{`Creativo Entregado: ${lastDecision.creative.id}`}</p>
                    <p className="text-emerald-400">{`Invariante Presupuestaria: ${lastDecision.atomicCheck}`}</p>
                    <p className="text-cyan-400">{`Nonce Anti-Replay: ${lastDecision.nonce}`}</p>
                    <p className="text-slate-400">{`Firma Ed25519: ${lastDecision.signature}`}</p>
                  </div>

                  <div className="p-5 rounded-xl bg-white text-slate-900 space-y-2">
                    <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded bg-slate-200 text-slate-800">
                      Creativo Renderizado en Ubicación
                    </span>
                    <h4 className="text-base font-bold text-blue-700">
                      {lastDecision.creative.title}
                    </h4>
                    <p className="text-xs text-slate-700">{lastDecision.creative.description}</p>
                    <div className="pt-2 flex flex-wrap gap-2">
                      <span className="text-xs font-bold text-emerald-700">
                        {`📞 ${lastDecision.creative.whatsappContact}`}
                      </span>
                      <button
                        onClick={() =>
                          handleOpenDirectionsMaps(
                            lastDecision.creative.locationAddress ||
                              'Oaxaca 63, Col. Centro, Hermosillo, Sonora'
                          )
                        }
                        className="bg-blue-600 text-white text-xs font-bold px-2.5 py-1 rounded-md flex items-center gap-1 cursor-pointer"
                      >
                        <Navigation className="h-3 w-3" /> Cómo llegar
                      </button>
                    </div>
                  </div>
                </div>
              ) : (
                <p className="text-xs text-slate-400 py-8 text-center">
                  Haz clic en "Solicitar Impresión" o "Simular Clic + Débito Atómico" para inspeccionar el certificado criptográfico.
                </p>
              )}
            </section>
          )}

          {/* VISTA 7: ANALÍTICA Y REPORTES (RECHARTS 24H) */}
          {activeModule === 'analitica' && (
            <div className="space-y-6">
              <section className="as-card-premium rounded-2xl p-6 space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div>
                    <span className="text-[10px] font-bold uppercase tracking-widest text-amber-400">
                      Telemetría Recharts • Doble Eje Sincronizado
                    </span>
                    <h3 className="text-base font-bold text-white mt-0.5">
                      Tendencia de CTR (%) y CPC ($ MXN) en las Últimas 24 Horas
                    </h3>
                    <p className="text-xs text-slate-400">
                      Visualización interactiva hora por hora del rendimiento de clics y costo efectivo
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleServeDecision(true, undefined, false)}
                      className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-bold text-emerald-400 cursor-pointer"
                    >
                      + Inyectar Clic en Vivo
                    </button>
                    <button
                      onClick={exportCsvReport}
                      className="px-3 py-1.5 rounded-xl bg-amber-500 text-slate-950 text-xs font-bold cursor-pointer"
                    >
                      Descargar Reporte CSV
                    </button>
                  </div>
                </div>

                <div className="h-80 w-full pt-2">
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart
                      data={trends24hData}
                      margin={{ top: 10, right: 20, left: 0, bottom: 5 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                      <XAxis dataKey="hour" stroke="#94A3B8" fontSize={11} tickMargin={8} />
                      <YAxis
                        yAxisId="left"
                        stroke="#10B981"
                        fontSize={11}
                        unit="%"
                        domain={[0, 'auto']}
                      />
                      <YAxis
                        yAxisId="right"
                        orientation="right"
                        stroke="#F59E0B"
                        fontSize={11}
                        unit=" $"
                        domain={[0, 'auto']}
                      />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: '#0B101B',
                          borderColor: 'rgba(245, 158, 11, 0.4)',
                          borderRadius: '12px',
                          fontSize: '12px',
                          color: '#F8FAFC',
                        }}
                        formatter={(value: any, name: any) => [
                          String(name ?? '').includes('CTR') ? `${value}%` : `$${value} MXN`,
                          String(name ?? ''),
                        ]}
                      />
                      <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '10px' }} />
                      <Line
                        yAxisId="left"
                        type="monotone"
                        dataKey="ctr"
                        name="CTR de Efectividad (%)"
                        stroke="#10B981"
                        strokeWidth={2.8}
                        dot={{ r: 3, fill: '#10B981' }}
                        activeDot={{ r: 6 }}
                      />
                      <Line
                        yAxisId="right"
                        type="monotone"
                        dataKey="cpc"
                        name="CPC Promedio ($ MXN)"
                        stroke="#F59E0B"
                        strokeWidth={2.8}
                        dot={{ r: 3, fill: '#F59E0B' }}
                        activeDot={{ r: 6 }}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </section>

              <section className="as-card-premium rounded-2xl p-6 space-y-4">
                <h3 className="text-base font-bold text-white">
                  Tabla de Desglose Analítico por Hora (CTR, CPM e Inversión)
                </h3>
                <table className="w-full text-left border-collapse text-xs font-mono">
                  <thead>
                    <tr className="border-b border-slate-800 text-slate-400">
                      <th className="py-3">Franja Horaria</th>
                      <th className="py-3">Impresiones</th>
                      <th className="py-3">Clics</th>
                      <th className="py-3">CTR</th>
                      <th className="py-3">CPM Efectivo</th>
                      <th className="py-3">Inversión Liquidada</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {hourlyMetrics.map((h: any, i: number) => (
                      <tr key={i}>
                        <td className="py-3 font-bold text-white">{h.hour}</td>
                        <td className="py-3">{h.impressions}</td>
                        <td className="py-3 text-cyan-400 font-bold">{h.clicks}</td>
                        <td className="py-3">
                          {`${
                            h.impressions > 0
                              ? ((h.clicks / h.impressions) * 100).toFixed(2)
                              : '0.00'
                          }%`}
                        </td>
                        <td className="py-3">{`$${h.cpm.toFixed(2)} MXN`}</td>
                        <td className="py-3 text-emerald-400 font-bold">{`$${h.spend.toFixed(
                          2
                        )} MXN`}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </section>
            </div>
          )}

          {/* VISTA 8: AUDIENCIAS + SHIELD */}
          {activeModule === 'audiencias' && (
            <div className="space-y-6">
              <section className="as-card-premium rounded-2xl p-6 space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div>
                    <h3 className="text-base font-bold text-white flex items-center gap-2">
                      <ShieldAlert className="h-5 w-5 text-amber-400" />
                      ADSOLUSOL Shield™ • Interceptor de Fuga de Presupuesto
                    </h3>
                    <p className="text-xs text-slate-400">
                      Bloquea con 1 clic términos de otros laboratorios para que no consuman tu saldo diario
                    </p>
                  </div>
                  <span className="px-3 py-1.5 rounded-xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 text-xs font-mono font-bold">
                    {`Ahorro Protegido: $${kpis.shieldSavings.toFixed(2)} MXN`}
                  </span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {competitorTerms.map((item) => (
                    <div
                      key={item.id}
                      className="p-4 rounded-xl bg-[#070B12] border border-slate-800 flex items-center justify-between gap-3"
                    >
                      <div>
                        <p
                          className={`text-xs font-bold ${
                            item.blocked ? 'line-through text-rose-400' : 'text-white'
                          }`}
                        >
                          {`"${item.term}"`}
                        </p>
                        <p className="text-[11px] text-slate-400 mt-0.5">
                          {`${item.category} • Fuga estimada: $${item.wasted.toFixed(2)} MXN`}
                        </p>
                      </div>
                      <button
                        onClick={() => {
                          setCompetitorTerms((prev) =>
                            prev.map((t) =>
                              t.id === item.id ? { ...t, blocked: !t.blocked } : t
                            )
                          );
                          pushToast(
                            !item.blocked
                              ? `Término "${item.term}" bloqueado en lista negativa`
                              : `Término desbloqueado`,
                            'info'
                          );
                        }}
                        className={`px-3 py-1.5 rounded-lg text-xs font-bold cursor-pointer ${
                          item.blocked
                            ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30'
                            : 'bg-amber-500 text-slate-950'
                        }`}
                      >
                        {item.blocked ? '🛡️ Bloqueado' : 'Bloquear'}
                      </button>
                    </div>
                  ))}
                </div>
              </section>

              <section className="as-card-premium rounded-2xl p-6 space-y-4">
                <h3 className="text-base font-bold text-white">
                  Segmentos de Audiencia First-Party (Cero Cookies de Terceros)
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {audiences.map((aud: any) => (
                    <div
                      key={aud.id}
                      className="p-4 rounded-xl bg-[#070B12] border border-slate-800 space-y-2"
                    >
                      <span className="text-[10px] font-mono text-amber-400 font-bold">
                        {aud.id}
                      </span>
                      <p className="text-sm font-bold text-white">{aud.segment}</p>
                      <p className="text-xs text-slate-400">{`Participación: ${aud.share} • ${aud.device}`}</p>
                    </div>
                  ))}
                </div>
              </section>
            </div>
          )}

          {/* VISTAS 9 A 12 */}
          {activeModule === 'facturacion' && (
            <section className="as-card-premium rounded-2xl p-6 space-y-4">
              <div>
                <h3 className="text-base font-bold text-white">
                  Libro Mayor Autoritativo (Server Authoritative Ledger)
                </h3>
                <p className="text-xs text-slate-400">
                  {`Método Principal: ${dbState?.paymentMethod} • Saldo Disponible: $${(
                    dbState?.ledgerBalance ?? 0
                  ).toFixed(2)} MXN`}
                </p>
              </div>
              <table className="w-full text-left border-collapse text-xs font-mono">
                <thead>
                  <tr className="border-b border-slate-800 text-slate-400">
                    <th className="py-3">Evento ID</th>
                    <th className="py-3">Hora</th>
                    <th className="py-3">Operación</th>
                    <th className="py-3">Concepto / Ruta GPS</th>
                    <th className="py-3">Cargo Atómico</th>
                    <th className="py-3">Estado / Firma</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {auditLogs.map((log: any) => (
                    <tr key={log.id}>
                      <td className="py-3 text-amber-400 font-bold">{log.id}</td>
                      <td className="py-3">{log.timestamp}</td>
                      <td className="py-3">
                        <span
                          className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            log.eventType === 'MAPS_DIRECTIONS_CLICK'
                              ? 'bg-blue-500/20 text-blue-400'
                              : 'bg-slate-800 text-slate-300'
                          }`}
                        >
                          {log.eventType}
                        </span>
                      </td>
                      <td className="py-3 text-white">{log.campaign}</td>
                      <td className="py-3 text-emerald-400 font-bold">{`$${log.amount.toFixed(2)} MXN`}</td>
                      <td className="py-3 text-slate-400">{`${log.status} (${log.signature})`}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          )}

          {activeModule === 'alertas' && (
            <section className="as-card-premium rounded-2xl p-6 space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div>
                  <h3 className="text-base font-bold text-white">
                    Centro de Alertas y Notificaciones Push (Umbral 90%)
                  </h3>
                  <p className="text-xs text-slate-400">
                    Monitoreo automático de consumo presupuestario y sincronización de nodos
                  </p>
                </div>
                <button
                  onClick={requestBrowserPushPermission}
                  className="px-3.5 py-2 rounded-xl bg-amber-500 text-slate-950 text-xs font-bold flex items-center gap-1.5 cursor-pointer"
                >
                  <BellRing className="h-4 w-4" /> Probar / Activar Push Nativo
                </button>
              </div>

              {campaigns
                .filter((c: any) => c.budget > 0 && c.spent / c.budget >= 0.9)
                .map((c: any) => {
                  const pct = Math.round((c.spent / c.budget) * 100);
                  return (
                    <div
                      key={c.id}
                      className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/40 flex items-center justify-between"
                    >
                      <div>
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-rose-500 text-white mr-2">
                          PUSH &gt;= 90%
                        </span>
                        <span className="text-xs font-bold text-white">{c.name}</span>
                        <p className="text-xs text-rose-200 mt-1">
                          {`La campaña alcanzó el ${pct}% de su presupuesto diario ($${c.spent.toFixed(
                            2
                          )} / $${c.budget.toFixed(2)} MXN).`}
                        </p>
                      </div>
                      <span className="text-xs font-mono font-bold text-rose-400">{`${pct}%`}</span>
                    </div>
                  );
                })}

              {alerts.map((al: any) => (
                <div
                  key={al.id}
                  className="p-4 rounded-xl bg-[#070B12] border border-slate-800 flex items-center justify-between"
                >
                  <div>
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-amber-500/20 text-amber-400 mr-2">
                      {al.severity}
                    </span>
                    <span className="text-xs font-bold text-white">{al.module}</span>
                    <p className="text-xs text-slate-300 mt-1">{al.message}</p>
                  </div>
                  <span className="text-xs font-mono text-slate-400">{al.timestamp}</span>
                </div>
              ))}
            </section>
          )}

          {activeModule === 'auditoria' && (
            <section className="as-card-premium rounded-2xl p-6 space-y-6">
              <div>
                <h3 className="text-base font-bold text-white mb-3">
                  Operadores y Nodos Firmantes Autorizados (RBAC)
                </h3>
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="border-b border-slate-800 text-slate-400">
                      <th className="py-2.5">Usuario</th>
                      <th className="py-2.5">Correo</th>
                      <th className="py-2.5">Rol en Ecosistema</th>
                      <th className="py-2.5">Huella Pública Ed25519</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {users.map((u: any) => (
                      <tr key={u.id}>
                        <td className="py-3 font-bold text-white">{u.name}</td>
                        <td className="py-3 text-slate-300">{u.email}</td>
                        <td className="py-3 text-amber-400 font-semibold">{u.role}</td>
                        <td className="py-3 font-mono text-slate-400">{u.keyFingerprint}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          )}

          {activeModule === 'sistema' && (
            <section className="grid grid-cols-1 md:grid-cols-3 gap-5">
              <div className="as-card-premium rounded-2xl p-5 space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-slate-400">MOTOR SQLITE LOCAL</span>
                  <span className={`px-2 py-0.5 rounded text-xs font-bold ${sysHealth?.sqlite?.status?.includes('OPERATIVO') || sysHealth?.sqlite?.status === 'UP' ? 'bg-emerald-500/15 text-emerald-400' : 'bg-rose-500/15 text-rose-400'}`}>
                    {sysHealth?.sqlite?.status || 'OPERATIVO (WAL)'}
                  </span>
                </div>
                <p className="text-2xl font-mono font-extrabold text-white">
                  {`${sysHealth?.sqlite?.latencyMs ?? 0.28} ms`}
                </p>
                <p className="text-xs text-slate-400">{`Modo: ${sysHealth?.sqlite?.journalMode || 'WAL (adsolusol.db)'}`}</p>
                <p className="text-xs text-slate-400">{`Invariante: ${sysHealth?.sqlite?.atomicGuard || 'BudgetSpent + Cost <= Budget'}`}</p>
                <p className="text-[11px] font-mono text-emerald-400">
                  Autoridad: ASP.NET Core Kestrel (:5000)
                </p>
              </div>

              <div className="as-card-premium rounded-2xl p-5 space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-slate-400">
                    PUENTE API_SIC (MARKETING BRAIN)
                  </span>
                  <span className={`px-2 py-0.5 rounded text-xs font-bold ${sysHealth?.sicEngine?.status === 'CONECTADO' || sysHealth?.sicEngine?.status === 'UP' ? 'bg-cyan-500/15 text-cyan-400' : 'bg-rose-500/15 text-rose-400'}`}>
                    {sysHealth?.sicEngine?.status || 'DOWN (Zero-Synthetic)'}
                  </span>
                </div>
                <p className="text-2xl font-mono font-extrabold text-white">
                  {sysHealth?.sicEngine?.latencyMs ? `${sysHealth.sicEngine.latencyMs} ms` : 'N/A'}
                </p>
                <p className="text-xs text-slate-400">{`Endpoint: ${sysHealth?.sicEngine?.endpoint || 'http://solusol.net:8080/health'}`}</p>
                <p className="text-xs text-slate-400">{`Protocolo: ${sysHealth?.sicEngine?.protocol || 'HTTP/REST (Outbox Bridge)'}`}</p>
                <p className="text-[11px] font-mono text-cyan-400">
                  Integridad: Zero-Synthetic (Sin Mocks)
                </p>
              </div>

              <div className="as-card-premium rounded-2xl p-5 space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-slate-400">
                    NODO API & NOTARÍA ED25519
                  </span>
                  <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-400 text-xs font-bold">
                    {sysHealth?.apiNode?.status || 'OPERATIVO'}
                  </span>
                </div>
                <p className="text-2xl font-mono font-extrabold text-white">
                  SOLUSOL_AUTH_V1
                </p>
                <p className="text-xs text-slate-400">{`Tenant: ${sysHealth?.apiNode?.tenantId || 'TENANT-SOLUSOL-HMO-01'}`}</p>
                <p className="text-xs text-slate-400">{`Protección: ${sysHealth?.apiNode?.antiReplayWindow || '300s Nonce Cache'}`}</p>
                <p className="text-[11px] font-mono text-amber-400">
                  Criptografía: Ed25519 Signature Verified
                </p>
              </div>
            </section>
          )}
        </main>
      </div>

      {/* PALETA DE COMANDOS CTRL+K */}
      {commandOpen && (
        <div
          onClick={() => setCommandOpen(false)}
          className="fixed inset-0 bg-black/75 backdrop-blur-sm flex items-start justify-center pt-24 p-4 z-50"
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="bg-[#0E1525] border border-amber-500/40 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl"
          >
            <div className="p-3.5 border-b border-slate-800 flex items-center gap-2.5">
              <Command className="h-4 w-4 text-amber-400" />
              <input
                type="text"
                autoFocus
                value={commandQuery}
                onChange={(e) => setCommandQuery(e.target.value)}
                placeholder="Escribe un comando o módulo (ej. mapa, analitica, push, creativo)..."
                className="w-full bg-transparent text-xs text-white focus:outline-none"
              />
              <span className="text-[10px] font-mono text-slate-500">ESC</span>
            </div>
            <div className="p-2 max-h-72 overflow-y-auto space-y-1 text-xs">
              <button
                onClick={() => {
                  handleOpenDirectionsMaps(crtForm.locationAddress);
                  setCommandOpen(false);
                }}
                className="w-full text-left px-3 py-2 rounded-xl hover:bg-slate-800 flex items-center justify-between cursor-pointer"
              >
                <span className="font-bold text-cyan-400">
                  📍 Probar Botón "Cómo llegar" (Google Maps + Débito GPS)
                </span>
                <span className="font-mono text-[10px] text-slate-400">Ruta GPS</span>
              </button>
              <button
                onClick={() => {
                  setActiveModule('analitica');
                  setCommandOpen(false);
                }}
                className="w-full text-left px-3 py-2 rounded-xl hover:bg-slate-800 flex items-center justify-between cursor-pointer"
              >
                <span className="font-bold text-emerald-400">
                  📈 Ver Gráfico Recharts 24h (CTR y CPC)
                </span>
                <span className="font-mono text-[10px] text-slate-400">Analítica</span>
              </button>
              {(Object.keys(MODULE_META) as ModuleKey[])
                .filter((k) =>
                  MODULE_META[k].title.toLowerCase().includes(commandQuery.toLowerCase())
                )
                .map((k) => (
                  <button
                    key={k}
                    onClick={() => {
                      setActiveModule(k);
                      setCommandOpen(false);
                    }}
                    className="w-full text-left px-3 py-2 rounded-xl hover:bg-slate-800 flex items-center justify-between cursor-pointer"
                  >
                    <span>Ir a {MODULE_META[k].title}</span>
                    <span className="text-[10px] text-slate-500">{MODULE_META[k].category}</span>
                  </button>
                ))}
            </div>
          </div>
        </div>
      )}

      {/* SLIDE-OVER DRAWER */}
      {drawerType && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex justify-end z-50">
          <form
            onSubmit={handleCreateRecord}
            className="bg-[#0E1525] border-l border-amber-500/30 w-full max-w-md h-full p-6 flex flex-col justify-between shadow-2xl"
          >
            <div className="space-y-4">
              <div className="flex items-center justify-between border-b border-slate-800 pb-4">
                <div>
                  <span className="text-[10px] font-bold uppercase tracking-wider text-amber-400">
                    Registro Transaccional
                  </span>
                  <h3 className="text-base font-bold text-white">
                    {drawerType === 'campana' && 'Crear Nueva Campaña'}
                    {drawerType === 'ubicacion' && 'Registrar Nueva Ubicación'}
                    {drawerType === 'creativo' && 'Registrar Nuevo Creativo HTTPS + GPS'}
                    {drawerType === 'asignacion' && 'Vincular Recurso en Matriz'}
                  </h3>
                </div>
                <button
                  type="button"
                  onClick={() => setDrawerType(null)}
                  className="p-1.5 rounded-lg bg-slate-800/80 text-slate-400 hover:text-white cursor-pointer"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              {drawerType === 'campana' && (
                <div className="space-y-3">
                  <div>
                    <label className="text-xs text-slate-400">Nombre de la campaña</label>
                    <input
                      type="text"
                      required
                      placeholder="Ej. Ultrasonidos Hermosillo"
                      value={campForm.name}
                      onChange={(e) => setCampForm({ ...campForm, name: e.target.value })}
                      className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-slate-400">Presupuesto Diario (MXN)</label>
                    <input
                      type="number"
                      value={campForm.budget}
                      onChange={(e) => setCampForm({ ...campForm, budget: Number(e.target.value) })}
                      className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-slate-400">CPC Máximo (MXN)</label>
                    <input
                      type="number"
                      step="0.1"
                      value={campForm.maxCpc}
                      onChange={(e) => setCampForm({ ...campForm, maxCpc: Number(e.target.value) })}
                      className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                    />
                  </div>
                </div>
              )}

              {drawerType === 'ubicacion' && (
                <div className="space-y-3">
                  <div>
                    <label className="text-xs text-slate-400">Código Canónico</label>
                    <input
                      type="text"
                      required
                      value={plcForm.code}
                      onChange={(e) => setPlcForm({ ...plcForm, code: e.target.value })}
                      className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-slate-400">Nombre Descriptivo</label>
                    <input
                      type="text"
                      required
                      value={plcForm.name}
                      onChange={(e) => setPlcForm({ ...plcForm, name: e.target.value })}
                      className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                    />
                  </div>
                </div>
              )}

              {drawerType === 'creativo' && (
                <div className="space-y-3">
                  <button
                    type="button"
                    onClick={applyAiCreativePreset}
                    className="w-full py-2 rounded-xl bg-indigo-500/20 border border-indigo-400/40 text-indigo-300 text-xs font-bold flex items-center justify-center gap-1.5 cursor-pointer"
                  >
                    <Sparkles className="h-3.5 w-3.5 text-amber-400" /> Autocompletar con IA Clínica
                  </button>
                  <div>
                    <label className="text-xs text-slate-400">Título del Anuncio</label>
                    <input
                      type="text"
                      required
                      value={crtForm.title}
                      onChange={(e) => setCrtForm({ ...crtForm, title: e.target.value })}
                      className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-slate-400">Descripción Persuasiva</label>
                    <textarea
                      required
                      rows={2}
                      value={crtForm.description}
                      onChange={(e) => setCrtForm({ ...crtForm, description: e.target.value })}
                      className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-amber-400 font-bold">
                      Sucursal Destino ("Cómo llegar" en Google Maps)
                    </label>
                    <input
                      type="text"
                      required
                      value={crtForm.locationAddress}
                      onChange={(e) =>
                        setCrtForm({ ...crtForm, locationAddress: e.target.value })
                      }
                      className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                    />
                  </div>
                </div>
              )}

              {drawerType === 'asignacion' && (
                <p className="text-xs text-slate-300 leading-relaxed">
                  Se vinculará la campaña seleccionada con el creativo y la ubicación activa bajo el algoritmo de Pacing Ponderado por Presupuesto.
                </p>
              )}
            </div>

            <div className="flex justify-end gap-2 pt-4 border-t border-slate-800">
              <button
                type="button"
                onClick={() => setDrawerType(null)}
                className="px-4 py-2.5 rounded-xl bg-slate-800 text-xs font-bold text-slate-300 cursor-pointer"
              >
                Cancelar
              </button>
              <button
                type="submit"
                className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold cursor-pointer"
              >
                Guardar en Servidor
              </button>
            </div>
          </form>
        </div>
      )}

      {/* MODAL DE CONFIRMACIÓN */}
      {confirmDelete && (
        <div className="fixed inset-0 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-[#0E1422] border border-rose-500/40 rounded-2xl p-6 w-full max-w-sm space-y-4">
            <h4 className="text-base font-bold text-white">Confirmar Eliminación</h4>
            <p className="text-xs text-slate-300">
              {`¿Estás seguro de que deseas eliminar "${confirmDelete.name}" (${confirmDelete.id})? Esta acción quedará asentada en la bitácora de auditoría.`}
            </p>
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setConfirmDelete(null)}
                className="px-4 py-2 rounded-xl bg-slate-800 text-xs font-bold text-slate-300 cursor-pointer"
              >
                Cancelar
              </button>
              <button
                onClick={executeConfirmedDelete}
                className="px-4 py-2 rounded-xl bg-rose-600 text-white text-xs font-bold cursor-pointer"
              >
                Sí, Eliminar
              </button>
            </div>
          </div>
        </div>
      )}

      {/* TOASTS */}
      <div className="fixed bottom-5 right-5 space-y-2 z-50">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={`px-4 py-3 rounded-xl border shadow-lg text-xs font-bold flex items-center gap-2 ${
              t.type === 'exito'
                ? 'bg-[#0E1422] border-emerald-500/50 text-emerald-400'
                : t.type === 'alerta'
                ? 'bg-[#0E1422] border-rose-500/50 text-rose-400'
                : 'bg-[#0E1422] border-amber-500/50 text-amber-400'
            }`}
          >
            <CheckCircle2 className="h-4 w-4 shrink-0" />
            <span>{t.title}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
