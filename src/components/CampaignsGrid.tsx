import React, { useState, useMemo } from 'react';
import {
  Plus,
  Download,
  SlidersHorizontal,
  ArrowUpDown,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  PauseCircle,
} from 'lucide-react';
import { Campaign } from '../types';

interface CampaignsGridProps {
  campaigns: Campaign[];
  globalSearch: string;
  onNewCampaign: () => void;
  onToggleStatus: (campaign: Campaign) => void;
  onSimulate90: (campaign: Campaign) => void;
  onDelete: (collection: string, id: string, name: string) => void;
  onServeClick: () => void;
  pushToast: (title: string, type?: 'exito' | 'alerta' | 'info') => void;
}

export const CampaignsGrid: React.FC<CampaignsGridProps> = ({
  campaigns,
  globalSearch,
  onNewCampaign,
  onToggleStatus,
  onSimulate90,
  onDelete,
  onServeClick,
  pushToast,
}) => {
  const [statusFilter, setStatusFilter] = useState<string>('TODOS');
  const [sortField, setSortField] = useState<'spent' | 'clicks' | 'impressions' | 'budget'>('spent');
  const [sortAsc, setSortAsc] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);

  const filteredCampaigns = useMemo(() => {
    return campaigns
      .filter((c) => {
        const matchesSearch =
          c.name.toLowerCase().includes(globalSearch.toLowerCase()) ||
          c.id.toLowerCase().includes(globalSearch.toLowerCase());
        const matchesStatus = statusFilter === 'TODOS' || c.status === statusFilter;
        return matchesSearch && matchesStatus;
      })
      .sort((a, b) => {
        const diff = a[sortField] - b[sortField];
        return sortAsc ? diff : -diff;
      });
  }, [campaigns, globalSearch, statusFilter, sortField, sortAsc]);

  const pageSize = 5;
  const paginatedCampaigns = filteredCampaigns.slice(
    (currentPage - 1) * pageSize,
    currentPage * pageSize
  );

  const exportCsvReport = () => {
    const headers = 'ID,Campaña,Estado,Estrategia,Presupuesto,Gastado,Impresiones,Clics,CTR\n';
    const rows = campaigns
      .map((c: Campaign) => {
        const ctr = c.impressions > 0 ? ((c.clicks / c.impressions) * 100).toFixed(2) : '0.00';
        return `${c.id},"${c.name}",${c.status},"${c.strategy}",${c.budget},${c.spent},${c.impressions},${c.clicks},${ctr}%`;
      })
      .join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `ADSOLUSOL_Auditoria_Operativa.csv`;
    a.click();
    URL.revokeObjectURL(url);
    pushToast('Reporte CSV exportado con métricas verificadas', 'exito');
  };

  return (
    <section className="as-card-premium rounded-2xl p-6 space-y-4">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div>
          <h3 className="text-base font-bold text-white">Grid Operativo de Campañas Publicitarias</h3>
          <p className="text-xs text-slate-400">
            Monitoreo automático con notificación Push al cruzar el 90% del presupuesto diario
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center gap-1 bg-[#070B12] p-1 rounded-xl border border-slate-800">
            <SlidersHorizontal className="h-3.5 w-3.5 text-slate-400 ml-2 mr-1" />
            {['TODOS', 'ACTIVA', 'LIMITADA', 'PAUSADA'].map((st) => (
              <button
                key={st}
                onClick={() => {
                  setStatusFilter(st);
                  setCurrentPage(1);
                }}
                className={`text-[11px] px-2.5 py-1 rounded-lg font-bold cursor-pointer transition-all ${
                  statusFilter === st ? 'bg-amber-500 text-slate-950' : 'text-slate-400 hover:text-white'
                }`}
              >
                {st}
              </button>
            ))}
          </div>

          <button
            onClick={exportCsvReport}
            className="px-3 py-2 rounded-xl bg-[#070B12] border border-slate-800 text-xs font-bold text-slate-200 hover:border-slate-700 flex items-center gap-1.5 cursor-pointer"
          >
            <Download className="h-3.5 w-3.5" /> Exportar CSV
          </button>

          <button
            onClick={onNewCampaign}
            className="px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold flex items-center gap-1.5 shadow-md shadow-amber-500/20 cursor-pointer"
          >
            <Plus className="h-4 w-4" /> Nueva Campaña
          </button>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-slate-800 text-[11px] uppercase tracking-wider text-slate-400">
              <th className="py-3 px-2">ID / Campaña</th>
              <th className="py-3 px-2">Estado</th>
              <th className="py-3 px-2">Algoritmo / Puja</th>
              <th
                onClick={() => {
                  setSortField('spent');
                  setSortAsc(!sortAsc);
                }}
                className="py-3 px-2 cursor-pointer hover:text-white"
              >
                <span className="inline-flex items-center gap-1">
                  Gastado / Presupuesto <ArrowUpDown className="h-3 w-3" />
                </span>
              </th>
              <th className="py-3 px-2 cursor-pointer hover:text-white">Impresiones</th>
              <th className="py-3 px-2 cursor-pointer hover:text-white">Clics / CTR</th>
              <th className="py-3 px-2 text-right">Acciones Operativas</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60 text-xs">
            {paginatedCampaigns.map((c: Campaign) => {
              const ctr = c.impressions > 0 ? ((c.clicks / c.impressions) * 100).toFixed(2) : '0.00';
              return (
                <tr key={c.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="py-3.5 px-2">
                    <span className="font-mono text-[11px] text-amber-400 font-bold">{c.id}</span>
                    <p className="font-bold text-slate-100 text-sm">{c.name}</p>
                  </td>
                  <td className="py-3.5 px-2">
                    <button
                      onClick={() => onToggleStatus(c)}
                      className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full font-bold cursor-pointer ${
                        c.status === 'ACTIVA'
                          ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                          : c.status === 'LIMITADA'
                          ? 'bg-amber-500/15 text-amber-400 border border-amber-500/30'
                          : 'bg-slate-700/40 text-slate-400'
                      }`}
                    >
                      {c.status === 'ACTIVA' && <CheckCircle2 className="h-3 w-3" />}
                      {c.status === 'LIMITADA' && <AlertTriangle className="h-3 w-3" />}
                      {c.status === 'PAUSADA' && <PauseCircle className="h-3 w-3" />}
                      {c.status}
                    </button>
                  </td>
                  <td className="py-3.5 px-2">
                    <p className="font-semibold text-slate-200">{c.strategy}</p>
                    <p className="text-slate-400 font-mono">{`CPC Máx: $${c.maxCpc.toFixed(2)} MXN`}</p>
                  </td>
                  <td className="py-3.5 px-2 font-mono">
                    <span className="font-bold text-white">{`$${c.spent.toFixed(2)}`}</span>
                    <span className="text-slate-400">{` / $${c.budget.toFixed(2)} MXN`}</span>
                  </td>
                  <td className="py-3.5 px-2 font-mono font-bold text-slate-200">{c.impressions}</td>
                  <td className="py-3.5 px-2">
                    <span className="font-mono font-bold text-white">{`${c.clicks} clics`}</span>
                    <span className="ml-2 px-2 py-0.5 rounded bg-cyan-500/15 text-cyan-400 font-mono font-bold">{`${ctr}%`}</span>
                  </td>
                  <td className="py-3.5 px-2 text-right space-x-1.5">
                    <button onClick={onServeClick} className="px-2.5 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white font-bold cursor-pointer">+ Clic</button>
                    <button onClick={() => onSimulate90(c)} title="Simular llegar al 92% del presupuesto" className="px-2.5 py-1.5 rounded-lg bg-amber-500/20 hover:bg-amber-500/30 text-amber-400 border border-amber-500/30 font-bold cursor-pointer">🔔 Probar 90%</button>
                    <button onClick={() => onDelete('campaigns', c.id, c.name)} className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 cursor-pointer"><Trash2 className="h-4 w-4 inline" /></button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between pt-3 border-t border-slate-800 text-xs text-slate-400">
        <span>{`Mostrando ${paginatedCampaigns.length} de ${filteredCampaigns.length} campañas`}</span>
        <div className="flex gap-2">
          <button disabled={currentPage === 1} onClick={() => setCurrentPage((p) => Math.max(1, p - 1))} className="px-3 py-1 rounded-lg bg-[#070B12] border border-slate-800 disabled:opacity-40 cursor-pointer">Anterior</button>
          <button disabled={currentPage * pageSize >= filteredCampaigns.length} onClick={() => setCurrentPage((p) => p + 1)} className="px-3 py-1 rounded-lg bg-[#070B12] border border-slate-800 disabled:opacity-40 cursor-pointer">Siguiente</button>
        </div>
      </div>
    </section>
  );
};