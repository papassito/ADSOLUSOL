import React from 'react';
import { Activity, AlertTriangle, ArrowRight, Bell, CircleHelp, Megaphone, ShieldCheck, TrendingUp, Wallet } from 'lucide-react';
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import { Campaign, ModuleKey } from './types';

interface PanelViewProps {
  campaigns: Campaign[];
  forecast7DaysData: any[];
  total7DayPredictedSpend: number;
  total7DayShieldOptimized: number;
  ledgerBalance: number | null;
  systemHealth: any;
  campaignsAvailable: boolean;
  loading: boolean;
  onNavigate: (module: ModuleKey) => void;
}

export const PanelView: React.FC<PanelViewProps> = ({
  campaigns,
  forecast7DaysData,
  total7DayPredictedSpend,
  total7DayShieldOptimized,
  ledgerBalance,
  systemHealth,
  campaignsAvailable,
  loading,
  onNavigate,
}) => {
  if (import.meta.env.VITE_DEMO_MODE !== 'true') {
    const counts = campaigns.reduce((result, campaign) => {
      const backendStatus = String(campaign.backendStatus || '').toUpperCase();
      if (campaign.status === 'LIMITADA') result.limited += 1;
      else if (backendStatus === 'ACTIVE' || backendStatus === 'ACTIVA' || campaign.status === 'ACTIVA') result.active += 1;
      else if (backendStatus === 'PAUSED' || backendStatus === 'PAUSADA' || campaign.status === 'PAUSADA') result.paused += 1;
      else if (backendStatus === 'COMPLETED' || backendStatus === 'FINALIZADA') result.completed += 1;
      else if (backendStatus === 'SCHEDULED' || backendStatus === 'PROGRAMADA') result.scheduled += 1;
      else result.other += 1;
      return result;
    }, { active: 0, paused: 0, limited: 0, completed: 0, scheduled: 0, other: 0 });
    const totalBudget = campaigns.reduce((sum, campaign) => sum + Math.max(campaign.budget, 0), 0);
    const totalSpent = campaigns.reduce((sum, campaign) => sum + Math.max(campaign.spent, 0), 0);
    const availableBudget = Math.max(totalBudget - totalSpent, 0);
    const formatMoney = (value: number) => new Intl.NumberFormat('es-MX', {
      style: 'currency', currency: 'MXN', maximumFractionDigits: 2,
    }).format(value);
    const awaitingCampaigns = loading && campaigns.length === 0;
    const displayCount = (value: number) => awaitingCampaigns ? 'Consultando…' : campaignsAvailable ? String(value) : 'N/D';
    const displayMoney = (value: number) => awaitingCampaigns ? 'Consultando…' : campaignsAvailable ? formatMoney(value) : 'No disponible';
    const statusTone = (value?: string) => {
      const status = String(value || '').toUpperCase();
      if (['UP', 'HEALTHY', 'OPERATIVO', 'CONECTADO'].includes(status)) return 'text-emerald-400';
      if (!status || ['NO DISPONIBLE', 'N/A'].includes(status)) return 'text-amber-300';
      return 'text-rose-400';
    };
    const apiStatus = systemHealth?.apiNode?.status || 'NO DISPONIBLE';
    const sqliteStatus = systemHealth?.sqlite?.status || 'NO DISPONIBLE';
    const sicStatus = systemHealth?.sicEngine?.status || 'NO DISPONIBLE';

    const cards: {
      title: string;
      icon: React.ReactNode;
      module: ModuleKey;
      content: React.ReactNode;
    }[] = [
      {
        title: 'Estado del sistema', icon: <Activity className="h-4 w-4" />, module: 'sistema',
        content: <div className="mt-4 space-y-2 text-xs">
          {[['API', apiStatus], ['SQLite', sqliteStatus], ['SIC', sicStatus]].map(([label, value]) => (
            <div key={label} className="flex items-center justify-between gap-2">
              <span className="text-slate-400">{label}</span>
              <span className={`font-mono font-bold ${statusTone(value)}`}>{value}</span>
            </div>
          ))}
        </div>,
      },
      {
        title: 'Campañas', icon: <Megaphone className="h-4 w-4" />, module: 'campanas',
        content: <>
          <div className="mt-4 text-3xl font-bold text-white">{displayCount(campaigns.length)}</div>
          <div className="mt-3 grid grid-cols-2 gap-x-3 gap-y-2 text-xs">
            <span className="text-slate-400">Activas <b className="text-emerald-400">{displayCount(counts.active)}</b></span>
            <span className="text-slate-400">Pausadas <b className="text-slate-200">{displayCount(counts.paused)}</b></span>
            <span className="text-slate-400">Limitadas <b className="text-amber-300">{displayCount(counts.limited)}</b></span>
            <span className="text-slate-400">Finalizadas <b className="text-slate-200">{displayCount(counts.completed)}</b></span>
            {counts.scheduled > 0 && <span className="text-slate-400">Programadas <b className="text-cyan-300">{displayCount(counts.scheduled)}</b></span>}
            {counts.other > 0 && <span className="text-slate-400">Otros <b className="text-slate-200">{displayCount(counts.other)}</b></span>}
          </div>
        </>,
      },
      {
        title: 'Presupuesto', icon: <Wallet className="h-4 w-4" />, module: 'facturacion',
        content: <div className="mt-4 space-y-3">
          <div><span className="block text-xs text-slate-400">Disponible en campañas</span><strong className="text-xl font-bold text-emerald-400">{displayMoney(availableBudget)}</strong></div>
          <div><span className="block text-xs text-slate-400">Consumido</span><strong className="text-sm font-mono text-slate-200">{displayMoney(totalSpent)}</strong></div>
          <div className="border-t border-slate-700/70 pt-2 text-xs text-amber-300">Saldo ledger: No disponible</div>
        </div>,
      },
      {
        title: 'Supervisión', icon: <ShieldCheck className="h-4 w-4" />, module: 'alertas',
        content: <div className="mt-4 space-y-3 text-xs">
          <div className="flex items-center gap-2 text-amber-300"><Bell className="h-3.5 w-3.5" /> Alertas: No disponible</div>
          <div className="flex items-center gap-2 text-amber-300"><CircleHelp className="h-3.5 w-3.5" /> Auditorías: No disponible</div>
        </div>,
      },
    ];

    return <section className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-2">
        <div>
          <p className="text-[10px] font-bold uppercase tracking-widest text-cyan-300">Resumen operativo</p>
          <h3 className="mt-1 text-lg font-bold text-white">Estado en tiempo real</h3>
        </div>
        <span className="text-xs text-slate-400">Las cifras se basan en las respuestas actuales de la API.</span>
      </div>
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 2xl:grid-cols-4">
        {cards.map((card) => <button
          key={card.title}
          type="button"
          onClick={() => onNavigate(card.module)}
          className="as-card-premium rounded-xl border border-slate-800 p-4 text-left transition-colors hover:border-cyan-500/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-400"
        >
          <span className="flex items-center justify-between gap-3">
            <span className="flex items-center gap-2 text-sm font-bold text-slate-100">{card.icon}{card.title}</span>
            <ArrowRight className="h-4 w-4 shrink-0 text-slate-500" />
          </span>
          {card.content}
        </button>)}
      </div>
    </section>;
  }

  return (
    <div className="space-y-6">
      <div className="bg-amber-900/50 border border-amber-500/40 text-amber-200 p-3 rounded-xl text-xs flex items-center gap-3">
        <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0" />
        <div>
          <span className="font-bold">MODO DEMOSTRACIÓN:</span> Los datos de proyección de gasto y ahorro Shield™ son simulaciones basadas en los datos iniciales y no representan una analítica real.
        </div>
      </div>
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

          <div className="flex flex-wrap gap-3">
            <div className="bg-[#070B12] border border-slate-800 px-3.5 py-2 rounded-xl">
              <span className="block text-[10px] text-slate-400 uppercase font-bold">Gasto Proyectado (7 Días)</span>
              <span className="font-mono text-sm font-extrabold text-amber-400">
                ${total7DayPredictedSpend.toFixed(2)} MXN
              </span>
            </div>
            <div className="bg-[#070B12] border border-slate-800 px-3.5 py-2 rounded-xl">
              <span className="block text-[10px] text-slate-400 uppercase font-bold">Con Optimización Shield™</span>
              <span className="font-mono text-sm font-extrabold text-emerald-400">
                ${total7DayShieldOptimized.toFixed(2)} MXN
              </span>
            </div>
            <div className="bg-[#070B12] border border-slate-800 px-3.5 py-2 rounded-xl">
              <span className="block text-[10px] text-slate-400 uppercase font-bold">Cobertura de Saldo Ledger</span>
              <span className="font-mono text-sm font-extrabold text-cyan-400">
                {ledgerBalance == null ? 'NO DISPONIBLE' : ledgerBalance > total7DayPredictedSpend ? '100% Cubierto' : 'Requiere Recarga'}
              </span>
            </div>
          </div>
        </div>

        <div className="h-72 w-full pt-2">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={forecast7DaysData} margin={{ top: 10, right: 20, left: 0, bottom: 5 }}>
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
                formatter={(value: any, name: any) => [`$${value} MXN`, String(name ?? '')]}
              />
              <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '8px' }} />
              <Area type="monotone" dataKey="techoPresupuesto" name="Techo Presupuestario Diario" stroke="#64748B" strokeDasharray="5 5" fill="none" strokeWidth={2} />
              <Area type="monotone" dataKey="gastoProyectado" name="Gasto Proyectado" stroke="#F59E0B" fillOpacity={1} fill="url(#predSpendGrad)" strokeWidth={2.8} />
              <Area type="monotone" dataKey="gastoOptimizadoShield" name="Optimizado Shield™" stroke="#10B981" fillOpacity={1} fill="url(#shieldOptGrad)" strokeWidth={2.5} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </section>
    </div>
  );
};