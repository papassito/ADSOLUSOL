import React from 'react';
import { ChevronRight, Radio, BellRing, Search, RefreshCw } from 'lucide-react';

interface TopHeaderProps {
  currentMeta: { title: string; category: string; subtitle: string };
  isAutoLive: boolean;
  onToggleAutoLive: () => void;
  pushPermission: NotificationPermission;
  onRequestPushPermission: () => void;
  globalSearch: string;
  onSearchChange: (value: string) => void;
  onOpenCommand: () => void;
  onOpenSystem: () => void;
  sysHealth: any;
  ledgerBalance: number;
  loadingAction: boolean;
  onRefresh: () => void;
}

export const TopHeader: React.FC<TopHeaderProps> = ({
  currentMeta,
  isAutoLive,
  onToggleAutoLive,
  pushPermission,
  onRequestPushPermission,
  globalSearch,
  onSearchChange,
  onOpenCommand,
  onOpenSystem,
  sysHealth,
  ledgerBalance,
  loadingAction,
  onRefresh,
}) => {
  return (
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
            onClick={onToggleAutoLive}
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
            onClick={onRequestPushPermission}
            className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold border transition-all cursor-pointer ${
              pushPermission === 'granted'
                ? 'bg-amber-500/15 text-amber-400 border-amber-500/40'
                : 'bg-slate-800/60 text-slate-300 border-slate-700 hover:border-amber-500/50'
            }`}
          >
            <BellRing className="h-3.5 w-3.5" />
            {pushPermission === 'granted' ? 'Push 90%: Activo' : 'Activar Push 90%'}
          </button>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2.5">
        <div className="relative">
          <Search className="h-4 w-4 text-slate-400 absolute left-3 top-2.5" />
          <input
            type="text"
            value={globalSearch}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Filtrar campañas, IDs..."
            className="bg-[#070B12] border border-slate-800 rounded-xl pl-9 pr-16 py-1.5 text-xs text-slate-200 focus:outline-none focus:border-amber-500 w-56"
          />
          <button
            onClick={onOpenCommand}
            className="absolute right-2 top-1.5 px-1.5 py-0.5 rounded bg-slate-800 text-[10px] font-mono text-slate-300 hover:text-white cursor-pointer"
          >
            Ctrl+K
          </button>
        </div>

        <button
          onClick={onOpenSystem}
          className="flex items-center gap-2 bg-[#070B12] border border-slate-800 px-3 py-1.5 rounded-xl text-xs cursor-pointer hover:border-slate-700"
        >
          <span
            className={`h-2 w-2 rounded-full ${
              sysHealth?.sqlite?.status?.includes('OPERATIVO') || sysHealth?.sqlite?.status === 'UP'
                ? 'bg-emerald-400'
                : 'bg-rose-400'
            } animate-pulse`}
          />
          <span className="font-semibold text-slate-300">SQLite:</span>
          <span className="font-mono text-emerald-400 font-bold">
            {`${sysHealth?.sqlite?.latencyMs ?? 0.28}ms`}
          </span>
          <span className="text-slate-600">|</span>
          <span className="font-semibold text-slate-300">SIC:</span>
          <span className="font-mono text-cyan-400 font-bold">
            {sysHealth?.sicEngine?.status === 'CONECTADO' || sysHealth?.sicEngine?.status === 'UP'
              ? `${sysHealth?.sicEngine?.latencyMs ?? 12.4}ms`
              : 'DOWN'}
          </span>
        </button>

        <div className="bg-emerald-500/10 border border-emerald-500/30 px-3 py-1.5 rounded-xl text-xs font-mono font-bold text-emerald-400">
          {`Saldo: $${ledgerBalance.toLocaleString('es-MX', {
            minimumFractionDigits: 2,
          })} MXN`}
        </div>

        <button
          onClick={onRefresh}
          title="Sincronizar estado con servidor"
          className="p-2 rounded-xl bg-[#070B12] border border-slate-800 text-slate-300 hover:text-white cursor-pointer"
        >
          <RefreshCw className={`h-4 w-4 ${loadingAction ? 'animate-spin text-amber-400' : ''}`} />
        </button>
      </div>
    </header>
  );
};