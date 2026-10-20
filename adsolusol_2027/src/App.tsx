import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  MapPin,
  Bell,
  BellRing,
  ShieldCheck,
  Server,
  Search,
  Plus,
  Download,
  ChevronRight,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  PauseCircle,
  Zap,
  RefreshCw,
  Lock,
  SlidersHorizontal,
  X,
  Sparkles,
  Radio,
  Command,
  Smartphone,
  ShieldAlert,
  ExternalLink,
  PhoneCall,
  Navigation,
  TrendingUp,
} from 'lucide-react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from 'recharts';
import { ModuleKey, ToastMsg, Campaign } from './types';
import { MODULE_META, AI_PRESETS, BRANCH_LOCATIONS } from './constants';
import { CampaignsGrid } from './components/CampaignsGrid';

export default function App() {
  const [activeModule, setActiveModule] = useState<ModuleKey>('panel');
  const [globalSearch, setGlobalSearch] = useState('');
  const [loadingAction, setLoadingAction] = useState(false);
  const [isAutoLive, setIsAutoLive] = useState(false);
  const [commandOpen, setCommandOpen] = useState(false);
  const [commandQuery, setCommandQuery] = useState('');
  const [toasts, setToasts] = useState<ToastMsg[]>([]);
  const [confirmDelete, setConfirmDelete] = useState<{
    collection: string;
    id: string;
    name: string;
  } | null>(null);

  const [pushPermission, setPushPermission] = useState<NotificationPermission>(
    typeof Notification !== 'undefined' ? Notification.permission : 'default'
  );
  const [pushAlertBanner, setPushAlertBanner] = useState<string | null>(null);
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

  const [drawerType, setDrawerType] = useState<
    null | 'campana' | 'ubicacion' | 'creativo' | 'asignacion'
  >(null);

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

  const pushToast = useCallback(
    (title: string, type: 'exito' | 'alerta' | 'info' = 'exito') => {
      const id = Math.random().toString(36).substring(2, 8);
      setToasts((prev) => [...prev, { id, title, type }]);
      setTimeout(() => {
        setToasts((prev) => prev.filter((t) => t.id !== id));
      }, 4200);
    },
    []
  );

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
      const res = await fetch('/api/state');
      if (res.ok) {
        setDbState(await res.json());
      }
    } finally {
      setLoadingAction(false);
    }
  }, []);

  useEffect(() => {
    fetchState();
  }, [fetchState]);

  const campaigns = dbState?.campaigns || [];
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

  const handleServeDecision = useCallback(
    async (triggerClick: boolean, placementId?: string, isDirections?: boolean) => {
      setLoadingAction(true);
      try {
        const res = await fetch('/api/serve-decision', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            placementId: placementId || placements[0]?.id,
            triggerClick,
            isDirections: Boolean(isDirections),
          }),
        });
        const data = await res.json();
        if (res.ok) {
          setDbState((prev: any) => ({ ...prev, ...data.db }));
          setLastDecision(data.decision);
          pushToast(
            isDirections
              ? `📍 Ruta GPS "Cómo llegar" activada: -$${data.decision?.debitedCost} MXN (Cliente en camino)`
              : triggerClick
              ? `Débito atómico aplicado: -$${data.decision?.debitedCost} MXN (${data.decision?.campaign?.id})`
              : `Impresión servida y firmada con Ed25519`,
            'exito'
          );
        } else {
          pushToast(data.error || 'Límite de presupuesto alcanzado', 'alerta');
        }
      } finally {
        setLoadingAction(false);
      }
    },
    [placements, pushToast]
  );

  const handleToggleCampaignStatus = async (camp: Campaign) => {
    const nextStatus = camp.status === 'ACTIVA' ? 'PAUSADA' : 'ACTIVA';
    const res = await fetch(`/api/campaigns/${camp.id}`, {
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

  const simulateReach90Threshold = async (camp: any) => {
    const targetSpent = Number((camp.budget * 0.92).toFixed(2));
    notified90CampaignsRef.current.delete(camp.id);
    const res = await fetch(`/api/campaigns/${camp.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ spent: targetSpent }),
    });
    if (res.ok) {
      const data = await res.json();
      setDbState((prev: any) => ({ ...prev, ...data }));
    }
  };

  useEffect(() => {
    if (!isAutoLive) return;
    const timer = setInterval(() => {
      handleServeDecision(Math.random() > 0.35, undefined, Math.random() > 0.7);
    }, 2800);
    return () => clearInterval(timer);
  }, [isAutoLive, handleServeDecision]);

  // Cálculos matemáticos transparentes
  const kpis = useMemo(() => {
    const totalBudget = campaigns.reduce((acc: number, c: any) => acc + c.budget, 0);
    const totalSpent = campaigns.reduce((acc: number, c: any) => acc + c.spent, 0);
    const totalImpressions = campaigns.reduce((acc: number, c: any) => acc + c.impressions, 0);
    const totalClicks = campaigns.reduce((acc: number, c: any) => acc + c.clicks, 0);
    const activeCount = campaigns.filter((c: any) => c.status === 'ACTIVA').length;
    const ctr = totalImpressions > 0 ? ((totalClicks / totalImpressions) * 100).toFixed(2) : '0.00';
    const avgCpc = totalClicks > 0 ? (totalSpent / totalClicks).toFixed(2) : '0.00';
    const avgCpm =
      hourlyMetrics.length > 0
        ? (
            hourlyMetrics.reduce((acc: number, h: any) => acc + (h.cpm || 14.0), 0) /
            hourlyMetrics.length
          ).toFixed(2)
        : '14.12';
    const budgetPct = Math.min(
      100,
      Math.round((totalSpent / Math.max(1, totalBudget)) * 100)
    );
    const shieldSavings = competitorTerms
      .filter((t) => t.blocked)
      .reduce((acc, t) => acc + t.wasted, 0);
    const totalDirections = creatives.reduce(
      (acc: number, cr: any) => acc + (cr.directionsClicks || 0),
      0
    );

    return {
      totalBudget,
      totalSpent,
      totalImpressions,
      totalClicks,
      activeCount,
      ctr,
      avgCpc,
      avgCpm,
      budgetPct,
      shieldSavings,
      totalDirections,
    };
  }, [campaigns, hourlyMetrics, competitorTerms, creatives]);

  // PROYECCIÓN PREDICTIVA DE GASTO PARA LOS PRÓXIMOS 7 DÍAS BASADA EN PACING ACTUAL
  const forecast7DaysData = useMemo(() => {
    const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    // Factor de demanda clínica por día de la semana (Lun-Vie alto, Sáb medio, Dom campaña especial)
    const demandMultipliers = [0.76, 1.08, 1.05, 1.02, 1.0, 0.96, 0.85];

    const activeBudgetCap = campaigns
      .filter((c: any) => c.status !== 'PAUSADA')
      .reduce((acc: number, c: any) => acc + c.budget, 0) || 315;

    // Extrapolación de cierre diario basada en el gasto acumulado actual (Pacing Velocity)
    const hourlyBurnRate = Math.max(12, kpis.totalSpent / 7.5);
    const estimatedDailyBase = Math.min(activeBudgetCap, hourlyBurnRate * 13.5);

    const today = new Date();
    return Array.from({ length: 7 }, (_, i) => {
      const targetDate = new Date(today);
      targetDate.setDate(today.getDate() + i + 1);
      const dayOfWeek = targetDate.getDay();
      const label = `${dayNames[dayOfWeek]} ${targetDate.getDate()}`;

      const demandFactor = demandMultipliers[dayOfWeek];
      // El gasto proyectado nunca supera el techo presupuestario atómico (BudgetSpent + Cost <= Budget)
      const predictedSpend = Number(
        Math.min(activeBudgetCap, estimatedDailyBase * demandFactor).toFixed(2)
      );
      const optimizedWithShield = Number(
        Math.max(15, predictedSpend - kpis.shieldSavings * 0.45).toFixed(2)
      );

      return {
        day: label,
        gastoProyectado: predictedSpend,
        gastoOptimizadoShield: optimizedWithShield,
        techoPresupuesto: Number(activeBudgetCap.toFixed(2)),
      };
    });
  }, [campaigns, kpis.totalSpent, kpis.shieldSavings]);

  const total7DayPredictedSpend = useMemo(
    () => forecast7DaysData.reduce((acc, d) => acc + d.gastoProyectado, 0),
    [forecast7DaysData]
  );

  const total7DayShieldOptimized = useMemo(
    () => forecast7DaysData.reduce((acc, d) => acc + d.gastoOptimizadoShield, 0),
    [forecast7DaysData]
  );

  // Serie de 24 horas para Recharts (CTR % y CPC \$ MXN)
  const trends24hData = useMemo(() => {
    return Array.from({ length: 24 }, (_, idx) => {
      const hStr = `${String(idx).padStart(2, '0')}:00`;
      const existing = hourlyMetrics.find((m: any) => m.hour === hStr);

      if (existing && existing.impressions > 0) {
        const ctrVal = Number(((existing.clicks / existing.impressions) * 100).toFixed(2));
        const cpcVal =
          existing.clicks > 0
            ? Number((existing.spend / existing.clicks).toFixed(2))
            : 1.65;
        return {
          hour: hStr,
          ctr: ctrVal,
          cpc: cpcVal,
          impressions: existing.impressions,
          clicks: existing.clicks,
          spend: existing.spend,
        };
      }

      const isPeakMorning = idx >= 7 && idx <= 13;
      const isAfternoon = idx > 13 && idx <= 19;
      const imp = isPeakMorning ? 45 + ((idx * 7) % 35) : isAfternoon ? 28 + ((idx * 5) % 20) : 8 + (idx % 6);
      const clk = Math.max(1, Math.round(imp * (isPeakMorning ? 0.085 : 0.062)));
      const spd = Number((clk * (isPeakMorning ? 1.72 : 1.48)).toFixed(2));

      return {
        hour: hStr,
        ctr: Number(((clk / imp) * 100).toFixed(2)),
        cpc: Number((spd / clk).toFixed(2)),
        impressions: imp,
        clicks: clk,
        spend: spd,
      };
    });
  }, [hourlyMetrics]);

  const areaChartGeometry = useMemo(() => {
    if (hourlyMetrics.length === 0) return { linePath: '', areaPath: '', points: [] };
    const maxImp = Math.max(10, ...hourlyMetrics.map((h: any) => h.impressions));
    const width = 620;
    const stepX = (width - 60) / Math.max(1, hourlyMetrics.length - 1);

    const points = hourlyMetrics.map((h: any, idx: number) => {
      const x = Math.round(30 + idx * stepX);
      const y = Math.round(142 - (h.impressions / maxImp) * 105);
      return { x, y, ...h };
    });

    const linePath = points
      .map((p: any, i: number) => (i === 0 ? `M ${p.x} ${p.y}` : `L ${p.x} ${p.y}`))
      .join(' ');
    const lastX = points[points.length - 1]?.x || 590;
    const firstX = points[0]?.x || 30;
    const areaPath = `${linePath} L ${lastX} 152 L ${firstX} 152 Z`;

    return { linePath, areaPath, points };
  }, [hourlyMetrics]);

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

  const handleCreateRecord = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingAction(true);
    try {
      let endpoint = '/api/campaigns';
      let payload: any = campForm;

      if (drawerType === 'ubicacion') {
        endpoint = '/api/placements';
        payload = plcForm;
      } else if (drawerType === 'creativo') {
        endpoint = '/api/creatives';
        payload = crtForm;
      } else if (drawerType === 'asignacion') {
        endpoint = '/api/assignments';
        payload = asgForm;
      }

      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (res.ok) {
        const data = await res.json();
        setDbState((prev: any) => ({ ...prev, ...data }));
        pushToast('Registro verificado y persistido en SQLite WAL', 'exito');
        setDrawerType(null);
      }
    } finally {
      setLoadingAction(false);
    }
  };

  const executeConfirmedDelete = async () => {
    if (!confirmDelete) return;
    const res = await fetch(`/api/${confirmDelete.collection}/${confirmDelete.id}`, {
      method: 'DELETE',
    });
    if (res.ok) {
      const data = await res.json();
      setDbState((prev: any) => ({ ...prev, ...data }));
      pushToast(`Registro "${confirmDelete.name}" eliminado correctamente`, 'alerta');
    }
    setConfirmDelete(null);
  };

  const currentMeta = MODULE_META[activeModule];
  const campaignsOver90Count = campaigns.filter(
    (c: any) => c.budget > 0 && c.spent / c.budget >= 0.9
  ).length;

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
                      ? 'Motor Autónomo AUTO-LIVE activado (subastas cada 2.8s)'
                      : 'Motor Autónomo pausado',
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
                {isAutoLive ? 'AUTO-LIVE: ACTIVO' : 'ACTIVAR AUTO-LIVE'}
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
              <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="font-semibold text-slate-300">SQLite:</span>
              <span className="font-mono text-emerald-400 font-bold">
                {`${sysHealth?.sqlite?.latencyMs ?? 0.32}ms`}
              </span>
              <span className="text-slate-600">|</span>
              <span className="font-semibold text-slate-300">SIC:</span>
              <span className="font-mono text-cyan-400 font-bold">
                {`${sysHealth?.sicEngine?.latencyMs ?? 14.2}ms`}
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
            <div className="space-y-6">
              {/* ... Aquí irían los KPIs y gráficos del panel principal ... */}
              <section className="as-card-premium rounded-2xl p-6 space-y-5">
                <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                  <div>
                    <span className="text-[10px] font-bold uppercase tracking-widest text-cyan-400 flex items-center gap-1.5">
                      <TrendingUp className="h-3.5 w-3.5" /> Motor Predictivo de Pacing • Próximos 7 Días
                    </span>
                    <h3 className="text-base font-bold text-white mt-0.5">
                      Proyección de Inversión Publicitaria Basada en Velocidad de Consumo Actual
                    </h3>
                    <p className="text-xs text-slate-400">
                      Calcula el gasto estimado para los próximos 7 días respetando el techo atómico y el ahorro del escudo anti-competencia
                    </p>
                  </div>

                  {/* Tarjetas Resumen de la Proyección */}
                  <div className="flex flex-wrap gap-3">
                    <div className="bg-[#070B12] border border-slate-800 px-3.5 py-2 rounded-xl">
                      <span className="block text-[10px] text-slate-400 uppercase font-bold">
                        Gasto Proyectado (7 Días)
                      </span>
                      <span className="font-mono text-sm font-extrabold text-amber-400">
                        {`$${total7DayPredictedSpend.toFixed(2)} MXN`}
                      </span>
                    </div>
                    <div className="bg-[#070B12] border border-slate-800 px-3.5 py-2 rounded-xl">
                      <span className="block text-[10px] text-slate-400 uppercase font-bold">
                        Con Optimización Shield™
                      </span>
                      <span className="font-mono text-sm font-extrabold text-emerald-400">
                        {`$${total7DayShieldOptimized.toFixed(2)} MXN`}
                      </span>
                    </div>
                    <div className="bg-[#070B12] border border-slate-800 px-3.5 py-2 rounded-xl">
                      <span className="block text-[10px] text-slate-400 uppercase font-bold">
                        Cobertura de Saldo Ledger
                      </span>
                      <span className="font-mono text-sm font-extrabold text-cyan-400">
                        {(dbState?.ledgerBalance ?? 3190.91) > total7DayPredictedSpend
                          ? '100% Cubierto'
                          : 'Requiere Recarga'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Gráfico Recharts AreaChart de Proyección a 7 Días */}
                <div className="h-72 w-full pt-2">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart
                      data={forecast7DaysData}
                      margin={{ top: 10, right: 20, left: 0, bottom: 5 }}
                    >
                      <defs>
                        <linearGradient id="predSpendGrad" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.35} />
                          <stop offset="95%" stopColor="#F59E0B" stopOpacity={0.0} />
                        </linearGradient>
                        <linearGradient id="shieldOptGrad" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#10B981" stopOpacity={0.3} />
                          <stop offset="95%" stopColor="#10B981" stopOpacity={0.0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                      <XAxis dataKey="day" stroke="#94A3B8" fontSize={11} tickMargin={8} />
                      <YAxis stroke="#94A3B8" fontSize={11} unit=" $" />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: '#0B101B',
                          borderColor: 'rgba(245, 158, 11, 0.4)',
                          borderRadius: '12px',
                          fontSize: '12px',
                          color: '#F8FAFC',
                        }}
                        formatter={(value: any, name: string) => [`$${value} MXN`, name]}
                      />
                      <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '8px' }} />
                      <Area
                        type="monotone"
                        dataKey="techoPresupuesto"
                        name="Techo Presupuestario Diario (Límite Atómico)"
                        stroke="#64748B"
                        strokeDasharray="5 5"
                        fill="none"
                        strokeWidth={2}
                      />
                      <Area
                        type="monotone"
                        dataKey="gastoProyectado"
                        name="Gasto Proyectado (Pacing Actual)"
                        stroke="#F59E0B"
                        fillOpacity={1}
                        fill="url(#predSpendGrad)"
                        strokeWidth={2.8}
                      />
                      <Area
                        type="monotone"
                        dataKey="gastoOptimizadoShield"
                        name="Proyección Optimizada con Escudo Shield™"
                        stroke="#10B981"
                        fillOpacity={1}
                        fill="url(#shieldOptGrad)"
                        strokeWidth={2.5}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </section>
            </div>
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
              onSimulate90={simulateReach90Threshold}
              onDelete={(collection, id, name) => setConfirmDelete({ collection, id, name })}
              onServeClick={() => handleServeDecision(true)}
              pushToast={pushToast}
            />
          )}

          {/* VISTA 3: UBICACIONES */}
          {activeModule === 'ubicaciones' && (
            <section className="as-card-premium rounded-2xl p-6 space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="text-base font-bold text-white">
                    Inventario de Ubicaciones Normalizadas
                  </h3>
                  <p className="text-xs text-slate-400">
                    Espacios activos donde el servidor entrega anuncios verificados
                  </p>
                </div>
                <button
                  onClick={() => setDrawerType('ubicacion')}
                  className="px-4 py-2 rounded-xl bg-amber-500 text-slate-950 text-xs font-bold flex items-center gap-1.5 cursor-pointer"
                >
                  <Plus className="h-4 w-4" /> Nueva Ubicación
                </button>
              </div>

              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-slate-800 text-slate-400 uppercase">
                    <th className="py-3">ID / Código Canónico</th>
                    <th className="py-3">Nombre de Ubicación</th>
                    <th className="py-3">Formato Técnico</th>
                    <th className="py-3">CPM Piso</th>
                    <th className="py-3">Impresiones / Clics</th>
                    <th className="py-3 text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {placements.map((p: any) => (
                    <tr key={p.id}>
                      <td className="py-3.5 font-mono text-amber-400 font-bold">
                        {p.id} • {p.code}
                      </td>
                      <td className="py-3.5 font-bold text-white">{p.name}</td>
                      <td className="py-3.5 text-slate-300">{p.format}</td>
                      <td className="py-3.5 font-mono">{`$${p.floorCpm.toFixed(2)} MXN`}</td>
                      <td className="py-3.5 font-mono">
                        {`${p.impressions} imp. / ${p.clicks} clics`}
                      </td>
                      <td className="py-3.5 text-right">
                        <button
                          onClick={() =>
                            setConfirmDelete({
                              collection: 'placements',
                              id: p.id,
                              name: p.name,
                            })
                          }
                          className="text-slate-400 hover:text-rose-400 cursor-pointer"
                        >
                          <Trash2 className="h-4 w-4 inline" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          )}

          {/* VISTA 4: CREATIVOS + IA + GOOGLE MAPS */}
          {activeModule === 'creativos' && (
            <div className="space-y-6">
              <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="as-card-premium rounded-2xl p-6 space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="text-[10px] font-bold uppercase tracking-wider text-amber-400">
                        Laboratorio Creativo + Geolocalización
                      </span>
                      <h3 className="text-base font-bold text-white">
                        Generador de Anuncios con IA + Ruta Google Maps
                      </h3>
                    </div>
                    <button 
                      type="button"
                      onClick={applyAiCreativePreset}
                      className="px-3 py-1.5 rounded-xl bg-indigo-500/20 border border-indigo-400/40 text-indigo-300 hover:bg-indigo-500/30 text-xs font-bold flex items-center gap-1.5 cursor-pointer"
                    >
                      <Sparkles className="h-3.5 w-3.5 text-amber-400" /> Autocompletar con IA
                    </button>
                  </div>

                  <div className="space-y-3">
                    <div>
                      <label className="text-xs text-slate-400">Título Principal del Anuncio</label>
                      <input
                        type="text"
                        value={crtForm.title}
                        onChange={(e) => setCrtForm({ ...crtForm, title: e.target.value })}
                        className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                      />
                    </div>
                    <div>
                      <label className="text-xs text-slate-400">Descripción Clínica Persuasiva</label>
                      <textarea
                        rows={2}
                        value={crtForm.description}
                        onChange={(e) => setCrtForm({ ...crtForm, description: e.target.value })}
                        className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="text-xs text-slate-400">URL Final (HTTPS)</label>
                        <input
                          type="url"
                          value={crtForm.destinationUrl}
                          onChange={(e) =>
                            setCrtForm({ ...crtForm, destinationUrl: e.target.value })
                          }
                          className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                        />
                      </div>
                      <div>
                        <label className="text-xs text-slate-400">Extensión WhatsApp</label>
                        <input
                          type="text"
                          value={crtForm.whatsappContact}
                          onChange={(e) =>
                            setCrtForm({ ...crtForm, whatsappContact: e.target.value })
                          }
                          className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="text-xs text-amber-400 font-semibold flex items-center gap-1">
                        <Navigation className="h-3.5 w-3.5" /> Dirección GPS para Botón "Cómo llegar" (Google Maps)
                      </label>
                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-1">
                        <input
                          type="text"
                          value={crtForm.locationAddress}
                          onChange={(e) =>
                            setCrtForm({ ...crtForm, locationAddress: e.target.value })
                          }
                          placeholder="Dirección exacta o coordenadas..."
                          className="sm:col-span-2 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                        />
                        <select
                          value={crtForm.locationAddress}
                          onChange={(e) =>
                            setCrtForm({ ...crtForm, locationAddress: e.target.value })
                          }
                          className="bg-[#070B12] border border-amber-500/40 rounded-xl px-2.5 py-2 text-xs text-amber-400 font-bold"
                        >
                          {BRANCH_LOCATIONS.map((b, idx) => (
                            <option key={idx} value={b.address}>
                              {b.label}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>

                    <button
                      onClick={() => setDrawerType('creativo')}
                      className="w-full py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold cursor-pointer"
                    >
                      Publicar Anuncio con Ruta GPS en Catálogo
                    </button>
                  </div>
                </div>

                <div className="as-card-premium rounded-2xl p-6 flex flex-col justify-between">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-xs font-bold text-emerald-400 flex items-center gap-1.5">
                      <Smartphone className="h-4 w-4" /> Simulador Móvil SERP + Google Maps Activo
                    </span>
                    <span className="px-2 py-0.5 rounded bg-cyan-500/15 text-cyan-400 text-[10px] font-bold">
                      Extensión de Ubicación Activa
                    </span>
                  </div>

                  <div className="bg-white text-slate-900 rounded-2xl p-4 shadow-xl border border-slate-200 space-y-3">
                    <div
                      onClick={() => handleServeDecision(true)}
                      className="cursor-pointer"
                    >
                      <div className="flex items-center gap-2 text-[11px] text-slate-600 mb-0.5">
                        <span className="font-bold text-slate-950">Patrocinado</span>
                        <span>•</span>
                        <span className="truncate">{crtForm.destinationUrl}</span>
                      </div>
                      <h4 className="text-base font-bold text-blue-700 hover:underline flex items-center gap-1">
                        {crtForm.title}
                        <ExternalLink className="h-3.5 w-3.5 inline shrink-0" />
                      </h4>
                      <p className="text-xs text-slate-700 mt-1 leading-relaxed">
                        {crtForm.description}
                      </p>
                    </div>

                    <div className="pt-2.5 border-t border-slate-100 flex flex-wrap gap-2 text-[11px] font-bold">
                      <a
                        href={`https://wa.me/52${crtForm.whatsappContact.replace(/[^0-9]/g, '')}?text=${encodeURIComponent(
                          'Hola, vi su anuncio y deseo cotizar estudios.'
                        )}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        onClick={() => handleServeDecision(true)}
                        className="bg-emerald-50 hover:bg-emerald-100 text-emerald-700 px-3 py-1.5 rounded-lg flex items-center gap-1.5 border border-emerald-200"
                      >
                        <PhoneCall className="h-3.5 w-3.5" /> WhatsApp: {crtForm.whatsappContact}
                      </a>

                      <button
                        type="button"
                        onClick={() => handleOpenDirectionsMaps(crtForm.locationAddress)}
                        className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1.5 rounded-lg flex items-center gap-1.5 shadow-sm cursor-pointer"
                      >
                        <Navigation className="h-3.5 w-3.5" /> Cómo llegar (Abrir Ruta GPS)
                      </button>
                    </div>

                    <div className="rounded-xl overflow-hidden border border-slate-200 h-32 relative">
                      <iframe
                        title="Mapa Sucursal ADSOLUSOL"
                        width="100%"
                        height="100%"
                        style={{ border: 0 }}
                        loading="lazy"
                        src={`https://www.google.com/maps?q=${encodeURIComponent(
                          crtForm.locationAddress
                        )}&output=embed`}
                      />
                    </div>
                  </div>
                </div>
              </section>

              <section className="as-card-premium rounded-2xl p-6 space-y-4">
                <h3 className="text-base font-bold text-white">
                  Biblioteca de Creativos Verificados ({creatives.length})
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {creatives.map((cr: any) => (
                    <div
                      key={cr.id}
                      className="p-4 rounded-xl bg-[#070B12] border border-slate-800 flex flex-col justify-between gap-3"
                    >
                      <div>
                        <div className="flex justify-between items-center text-[11px] mb-1">
                          <span className="font-mono text-amber-400 font-bold">
                            {`${cr.id} ➔ ${cr.campaignId}`}
                          </span>
                          <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-400 font-bold flex items-center gap-1">
                            <Lock className="h-3 w-3" /> HTTPS + GPS OK
                          </span>
                        </div>
                        <h4 className="text-sm font-bold text-blue-400">{cr.title}</h4>
                        <p className="text-xs text-slate-300 mt-1">{cr.description}</p>
                        <p className="text-[11px] text-amber-400/90 mt-1.5 flex items-center gap-1">
                          <MapPin className="h-3 w-3 shrink-0" />
                          {cr.locationAddress || 'Oaxaca 63, Col. Centro, Hermosillo'}
                        </p>
                      </div>
                      <div className="pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs">
                        <span className="text-slate-400 font-mono">
                          {`${cr.clicks} clics • 📍 ${cr.directionsClicks || 0} rutas GPS`}
                        </span>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() =>
                              handleOpenDirectionsMaps(
                                cr.locationAddress || 'Oaxaca 63, Col. Centro, Hermosillo, Sonora'
                              )
                            }
                            className="px-2.5 py-1 rounded-lg bg-blue-600/20 hover:bg-blue-600/30 text-blue-400 border border-blue-500/30 font-bold flex items-center gap-1 cursor-pointer"
                          >
                            <Navigation className="h-3 w-3" /> Cómo llegar
                          </button>
                          <button
                            onClick={() =>
                              setConfirmDelete({
                                collection: 'creatives',
                                id: cr.id,
                                name: cr.title,
                              })
                            }
                            className="text-slate-400 hover:text-rose-400 cursor-pointer"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            </div>
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
                        formatter={(value: any, name: string) => [
                          name.includes('CTR') ? `${value}%` : `$${value} MXN`,
                          name,
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
                  <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-400 text-xs font-bold">
                    {sysHealth?.sqlite?.status || 'OPERATIVO'}
                  </span>
                </div>
                <p className="text-2xl font-mono font-extrabold text-white">
                  {`${sysHealth?.sqlite?.latencyMs ?? 0.32} ms`}
                </p>
                <p className="text-xs text-slate-400">{`Modo: ${sysHealth?.sqlite?.journalMode}`}</p>
                <p className="text-xs text-slate-400">{`Tamaño DB: ${sysHealth?.sqlite?.dbSizeKb} KB`}</p>
                <p className="text-[11px] font-mono text-emerald-400">
                  {`Regla: ${sysHealth?.sqlite?.atomicGuard}`}
                </p>
              </div>

              <div className="as-card-premium rounded-2xl p-5 space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-slate-400">
                    PUENTE API_SIC (MARKETING BRAIN)
                  </span>
                  <span className="px-2 py-0.5 rounded bg-cyan-500/15 text-cyan-400 text-xs font-bold">
                    {sysHealth?.sicEngine?.status || 'CONECTADO'}
                  </span>
                </div>
                <p className="text-2xl font-mono font-extrabold text-white">
                  {`${sysHealth?.sicEngine?.latencyMs ?? 14.2} ms`}
                </p>
                <p className="text-xs text-slate-400">{`Endpoint: ${sysHealth?.sicEngine?.endpoint}`}</p>
                <p className="text-xs text-slate-400">{`Protocolo: ${sysHealth?.sicEngine?.protocol}`}</p>
                <p className="text-[11px] font-mono text-cyan-400">
                  {`Última Sincronización: ${sysHealth?.sicEngine?.lastSync}`}
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
                  {`${sysHealth?.apiNode?.memoryMb ?? 48.5} MB RAM`}
                </p>
                <p className="text-xs text-slate-400">{`Tenant: ${sysHealth?.apiNode?.tenantId}`}</p>
                <p className="text-xs text-slate-400">{`Protección: ${sysHealth?.apiNode?.antiReplayWindow}`}</p>
                <p className="text-[11px] font-mono text-amber-400">
                  {`Tiempo Activo: ${sysHealth?.apiNode?.uptimeSeconds ?? 120}s`}
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