import React, { useEffect, useState } from 'react';
import { Activity, ArrowRight, Bell, CircleHelp, Megaphone, ShieldCheck, Wallet } from 'lucide-react';
import { Campaign, ModuleKey } from './types';

interface ReleaseInfo {
  state: 'checking' | 'published' | 'unverified';
  commit?: string;
  builtAtUtc?: string;
  detail?: string;
}

interface PanelViewProps {
  campaigns: Campaign[];
  systemHealth: any;
  campaignsAvailable: boolean;
  loading: boolean;
  onNavigate: (module: ModuleKey) => void;
}

export const PanelView: React.FC<PanelViewProps> = ({
  campaigns,
  systemHealth,
  campaignsAvailable,
  loading,
  onNavigate,
}) => {
  const [releaseInfo, setReleaseInfo] = useState<ReleaseInfo>({ state: 'checking' });

  useEffect(() => {
    const controller = new AbortController();
    fetch('/release.json', {
      cache: 'no-store',
      credentials: 'same-origin',
      signal: controller.signal,
    })
      .then(async (response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        if (!response.headers.get('content-type')?.includes('application/json')) {
          throw new Error('respuesta no JSON');
        }
        const release = await response.json();
        if (typeof release.commit !== 'string' || !release.commit.trim()) {
          throw new Error('metadatos incompletos');
        }
        setReleaseInfo({
          state: 'published',
          commit: release.commit,
          builtAtUtc: typeof release.builtAtUtc === 'string' ? release.builtAtUtc : undefined,
        });
      })
      .catch((error: unknown) => {
        if (!controller.signal.aborted) {
          setReleaseInfo({
            state: 'unverified',
            detail: error instanceof Error ? error.message : 'sin respuesta',
          });
        }
      });

    return () => controller.abort();
  }, []);

  const counts = campaigns.reduce(
    (result, campaign) => {
      const backendStatus = String(campaign.backendStatus || '').toUpperCase();
      if (campaign.status === 'LIMITADA') result.limited += 1;
      else if (backendStatus === 'ACTIVE' || backendStatus === 'ACTIVA' || campaign.status === 'ACTIVA') result.active += 1;
      else if (backendStatus === 'PAUSED' || backendStatus === 'PAUSADA' || campaign.status === 'PAUSADA') result.paused += 1;
      else if (backendStatus === 'COMPLETED' || backendStatus === 'FINALIZADA') result.completed += 1;
      else if (backendStatus === 'SCHEDULED' || backendStatus === 'PROGRAMADA') result.scheduled += 1;
      else result.other += 1;
      return result;
    },
    { active: 0, paused: 0, limited: 0, completed: 0, scheduled: 0, other: 0 }
  );

  const totalBudget = campaigns.reduce((sum, campaign) => sum + Math.max(campaign.budget, 0), 0);
  const totalSpent = campaigns.reduce((sum, campaign) => sum + Math.max(campaign.spent, 0), 0);
  const availableBudget = Math.max(totalBudget - totalSpent, 0);

  const formatMoney = (value: number) =>
    new Intl.NumberFormat('es-MX', {
      style: 'currency',
      currency: 'MXN',
      maximumFractionDigits: 2,
    }).format(value);

  const awaitingCampaigns = loading && campaigns.length === 0;
  const displayCount = (value: number) => (awaitingCampaigns ? 'Consultando…' : campaignsAvailable ? String(value) : 'N/D');
  const displayMoney = (value: number) => (awaitingCampaigns ? 'Consultando…' : campaignsAvailable ? formatMoney(value) : 'No disponible');

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
      title: 'Estado del sistema',
      icon: <Activity className="h-4 w-4" />,
      module: 'sistema',
      content: (
        <div className="mt-4 space-y-2 text-xs">
          {[
            ['API', apiStatus],
            ['SQLite', sqliteStatus],
            ['SIC', sicStatus],
          ].map(([label, value]) => (
            <div key={label} className="flex items-center justify-between gap-2">
              <span className="text-slate-400">{label}</span>
              <span className={`font-mono font-bold ${statusTone(value)}`}>{value}</span>
            </div>
          ))}
        </div>
      ),
    },
    {
      title: 'Campañas',
      icon: <Megaphone className="h-4 w-4" />,
      module: 'campanas',
      content: (
        <>
          <div className="mt-4 text-3xl font-bold text-white">{displayCount(campaigns.length)}</div>
          <div className="mt-3 grid grid-cols-2 gap-x-3 gap-y-2 text-xs">
            <span className="text-slate-400">
              Activas <b className="text-emerald-400">{displayCount(counts.active)}</b>
            </span>
            <span className="text-slate-400">
              Pausadas <b className="text-slate-200">{displayCount(counts.paused)}</b>
            </span>
            <span className="text-slate-400">
              Limitadas <b className="text-amber-300">{displayCount(counts.limited)}</b>
            </span>
            <span className="text-slate-400">
              Finalizadas <b className="text-slate-200">{displayCount(counts.completed)}</b>
            </span>
            {counts.scheduled > 0 && (
              <span className="text-slate-400">
                Programadas <b className="text-cyan-300">{displayCount(counts.scheduled)}</b>
              </span>
            )}
            {counts.other > 0 && (
              <span className="text-slate-400">
                Otros <b className="text-slate-200">{displayCount(counts.other)}</b>
              </span>
            )}
          </div>
        </>
      ),
    },
    {
      title: 'Presupuesto',
      icon: <Wallet className="h-4 w-4" />,
      module: 'facturacion',
      content: (
        <div className="mt-4 space-y-3">
          <div>
            <span className="block text-xs text-slate-400">Disponible en campañas</span>
            <strong className="text-xl font-bold text-emerald-400">{displayMoney(availableBudget)}</strong>
          </div>
          <div>
            <span className="block text-xs text-slate-400">Consumido</span>
            <strong className="text-sm font-mono text-slate-200">{displayMoney(totalSpent)}</strong>
          </div>
          <div className="border-t border-slate-700/70 pt-2 text-xs text-amber-300">Saldo ledger: No disponible</div>
        </div>
      ),
    },
    {
      title: 'Supervisión',
      icon: <ShieldCheck className="h-4 w-4" />,
      module: 'alertas',
      content: (
        <div className="mt-4 space-y-3 text-xs">
          <div className="flex items-center gap-2 text-amber-300">
            <Bell className="h-3.5 w-3.5" /> Alertas: No disponible
          </div>
          <div className="flex items-center gap-2 text-amber-300">
            <CircleHelp className="h-3.5 w-3.5" /> Auditorías: No disponible
          </div>
          <div className="border-t border-slate-700/70 pt-2">
            <div className={`font-semibold ${releaseInfo.state === 'published' ? 'text-emerald-400' : 'text-amber-300'}`}>
              Despliegue: {releaseInfo.state === 'checking' ? 'Verificando' : releaseInfo.state === 'published' ? 'Publicado' : 'No verificado'}
            </div>
            {releaseInfo.state === 'published' ? (
              <div className="mt-1 text-slate-400">
                Commit {releaseInfo.commit}
                {releaseInfo.builtAtUtc ? ` · ${releaseInfo.builtAtUtc} UTC` : ''}
              </div>
            ) : releaseInfo.state === 'unverified' ? (
              <div className="mt-1 text-slate-400">
                release.json no disponible ({releaseInfo.detail}). Revisar registro de Plesk.
              </div>
            ) : null}
          </div>
        </div>
      ),
    },
  ];

  return (
    <section className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-2">
        <div>
          <p className="text-[10px] font-bold uppercase tracking-widest text-cyan-300">Resumen operativo</p>
          <h3 className="mt-1 text-lg font-bold text-white">Estado en tiempo real</h3>
        </div>
        <span className="text-xs text-slate-400">Las cifras se basan en las respuestas actuales de la API.</span>
      </div>
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 2xl:grid-cols-4">
        {cards.map((card) => (
          <button
            key={card.title}
            type="button"
            onClick={() => onNavigate(card.module)}
            className="as-card-premium rounded-xl border border-slate-800 p-4 text-left transition-colors hover:border-cyan-500/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-400"
          >
            <span className="flex items-center justify-between gap-3">
              <span className="flex items-center gap-2 text-sm font-bold text-slate-100">
                {card.icon}
                {card.title}
              </span>
              <ArrowRight className="h-4 w-4 shrink-0 text-slate-500" />
            </span>
            {card.content}
          </button>
        ))}
      </div>
    </section>
  );
};