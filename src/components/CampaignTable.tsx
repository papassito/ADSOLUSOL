import React from 'react';
import { useCampaigns } from '../context/CampaignContext';
import { Play, Pause, CheckCircle2 } from 'lucide-react';
import { CampaignChart } from './CampaignChart';

const ALLOWED_STRATEGIES = [
  'Pacing Ponderado + CPC',
  'Límite Condicional Atómico',
  'Prioridad Alta Intención',
  'CPC Estricto',
];

export const CampaignTable: React.FC = () => {
  const { campaigns, updateStatus, updateStrategy, finalizeCampaign } = useCampaigns();

  const normalizeStatus = (status?: string) => String(status || '').toUpperCase();

  const isActive = (status?: string) => {
    const s = normalizeStatus(status);
    return s === 'ACTIVA' || s === 'ACTIVE';
  };

  const isPaused = (status?: string) => {
    const s = normalizeStatus(status);
    return s === 'PAUSADA' || s === 'PAUSED';
  };

  const isFinalized = (status?: string) => {
    const s = normalizeStatus(status);
    return s === 'FINALIZADA' || s === 'COMPLETED' || s === 'FINALIZED';
  };

  const isLimited = (status?: string) => normalizeStatus(status) === 'LIMITADA';

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
      <h3 className="text-lg font-bold text-white mb-4">Administración de Campañas</h3>
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="text-slate-400 border-b border-slate-800">
            <th className="pb-3 font-medium">Nombre</th>
            <th className="pb-3 font-medium">Estado</th>
            <th className="pb-3 font-medium">Estrategia</th>
            <th className="pb-3 font-medium text-right">Presupuesto / Gasto</th>
            <th className="pb-3 font-medium text-right">Telemetría</th>
            <th className="pb-3 font-medium text-right">Acciones</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800">
          {campaigns.map((c: any) => {
            const active = isActive(c.status);
            const paused = isPaused(c.status);
            const limited = isLimited(c.status);
            const finalized = isFinalized(c.status);
            const currentStrategy = c.strategy || c.pacingStrategy || ALLOWED_STRATEGIES[0];

            return (
              <tr key={c.id} className="text-slate-200">
                <td className="py-4 font-semibold text-white">{c.name}</td>
                <td className="py-4">
                  <span
                    className={`px-2 py-1 rounded text-[10px] font-mono uppercase ${
                      active
                        ? 'bg-emerald-900 text-emerald-300'
                        : paused
                        ? 'bg-amber-900 text-amber-300'
                        : limited
                        ? 'bg-rose-900 text-rose-300'
                        : 'bg-slate-800 text-slate-400'
                    }`}
                  >
                    {c.status}
                  </span>
                </td>
                <td className="py-4 text-xs space-y-1">
                  <select
                    value={currentStrategy}
                    onChange={(e) => updateStrategy(c.id, e.target.value as any, c.bidStrategy)}
                    disabled={finalized}
                    className="bg-slate-950 border border-slate-700 rounded px-2 py-1 text-slate-200 disabled:opacity-50"
                  >
                    {ALLOWED_STRATEGIES.map((strat) => (
                      <option key={strat} value={strat}>
                        {strat}
                      </option>
                    ))}
                  </select>
                </td>
                <td className="py-4 text-right font-mono">
                  <div className="text-white">${Number(c.budget || 0).toFixed(2)}</div>
                  {c.spent !== undefined && (
                    <div className="text-[11px] text-slate-400">
                      Gastado: ${Number(c.spent || 0).toFixed(2)}
                    </div>
                  )}
                </td>
                <td className="py-4 text-right">
                  {Array.isArray(c.history) && c.history.length > 0 ? (
                    <CampaignChart history={c.history} />
                  ) : (
                    <div className="text-xs font-mono text-slate-400">
                      {c.impressions ?? 0} imp · {c.clicks ?? 0} clics
                    </div>
                  )}
                </td>
                <td className="py-4 text-right">
                  {!finalized && (
                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        title={active ? 'Pausar campaña' : 'Activar campaña'}
                        onClick={() => {
                          const usesSpanish = c.status === 'ACTIVA' || c.status === 'PAUSADA' || c.status === 'LIMITADA';
                          const nextStatus = usesSpanish
                            ? active
                              ? 'PAUSADA'
                              : 'ACTIVA'
                            : active
                            ? 'paused'
                            : 'active';
                          updateStatus(c.id, nextStatus as any);
                        }}
                        className="p-1 hover:text-amber-400 transition-colors"
                      >
                        {active ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
                      </button>
                      {finalizeCampaign && (
                        <button
                          type="button"
                          title="Finalizar campaña"
                          onClick={() => finalizeCampaign(c.id)}
                          className="p-1 hover:text-emerald-400 transition-colors"
                        >
                          <CheckCircle2 className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};