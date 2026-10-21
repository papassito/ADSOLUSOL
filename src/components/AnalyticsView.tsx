import React from 'react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
} from 'recharts';

interface AnalyticsViewProps {
  trends24hData: any[];
  hourlyMetrics: any[];
  onInjectLiveClick: () => void;
  onExportCsv: () => void;
}

export const AnalyticsView: React.FC<AnalyticsViewProps> = ({
  trends24hData,
  hourlyMetrics,
  onInjectLiveClick,
  onExportCsv,
}) => {
  return (
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
              onClick={onInjectLiveClick}
              className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-bold text-emerald-400 cursor-pointer"
            >
              + Inyectar Clic en Vivo
            </button>
            <button
              onClick={onExportCsv}
              className="px-3 py-1.5 rounded-xl bg-amber-500 text-slate-950 text-xs font-bold cursor-pointer"
            >
              Descargar Reporte CSV
            </button>
          </div>
        </div>

        <div className="h-80 w-full pt-2">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={trends24hData} margin={{ top: 10, right: 20, left: 0, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
              <XAxis dataKey="hour" stroke="#94A3B8" fontSize={11} tickMargin={8} />
              <YAxis yAxisId="left" stroke="#10B981" fontSize={11} unit="%" domain={[0, 'auto']} />
              <YAxis yAxisId="right" orientation="right" stroke="#F59E0B" fontSize={11} unit=" $" domain={[0, 'auto']} />
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
              <Line yAxisId="left" type="monotone" dataKey="ctr" name="CTR de Efectividad (%)" stroke="#10B981" strokeWidth={2.8} dot={{ r: 3, fill: '#10B981' }} />
              <Line yAxisId="right" type="monotone" dataKey="cpc" name="CPC Promedio ($ MXN)" stroke="#F59E0B" strokeWidth={2.8} dot={{ r: 3, fill: '#F59E0B' }} />
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
                <td className="py-3">{`${h.impressions > 0 ? ((h.clicks / h.impressions) * 100).toFixed(2) : '0.00'}%`}</td>
                <td className="py-3">{`$${Number(h.cpm || 0).toFixed(2)} MXN`}</td>
                <td className="py-3 text-emerald-400 font-bold">{`$${Number(h.spend || 0).toFixed(2)} MXN`}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
};