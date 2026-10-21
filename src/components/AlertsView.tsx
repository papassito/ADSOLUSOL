import React from 'react';
import { BellRing } from 'lucide-react';
import { Campaign } from '../types';

interface AlertsViewProps {
  campaigns: Campaign[];
  alerts: any[];
  onRequestPushPermission: () => void;
}

export const AlertsView: React.FC<AlertsViewProps> = ({
  campaigns,
  alerts,
  onRequestPushPermission,
}) => {
  return (
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
          onClick={onRequestPushPermission}
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
                  {`La campaña alcanzó el ${pct}% de su presupuesto diario ($${c.spent.toFixed(2)} / $${c.budget.toFixed(2)} MXN).`}
                </p>
              </div>
              <span className="text-xs font-mono font-bold text-rose-400">{`${pct}%`}</span>
            </div>
          );
        })}

      <div className="space-y-2 pt-2">
        <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Bitácora de Eventos y Notaría</h4>
        {alerts.length === 0 ? (
          <p className="text-xs text-slate-500 py-3">No hay alertas activas en el sistema.</p>
        ) : (
          alerts.map((al: any) => (
            <div key={al.id} className="p-3.5 rounded-xl bg-[#070B12] border border-slate-800 text-xs flex items-center justify-between">
              <div>
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded mr-2 ${al.severity === 'ADVERTENCIA' ? 'bg-amber-500/20 text-amber-400' : 'bg-cyan-500/20 text-cyan-400'}`}>
                  {al.severity || 'INFO'}
                </span>
                <span className="font-semibold text-white">{al.module}</span>
                <p className="text-xs text-slate-300 mt-1">{al.message}</p>
              </div>
              <span className="font-mono text-slate-500 text-[11px] shrink-0">{al.timestamp}</span>
            </div>
          ))
        )}
      </div>
    </section>
  );
};