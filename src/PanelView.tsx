import React from 'react';
import { TrendingUp } from 'lucide-react';
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

interface PanelViewProps {
  forecast7DaysData: any[];
  total7DayPredictedSpend: number;
  total7DayShieldOptimized: number;
  ledgerBalance: number;
}

export const PanelView: React.FC<PanelViewProps> = ({
  forecast7DaysData,
  total7DayPredictedSpend,
  total7DayShieldOptimized,
  ledgerBalance,
}) => {
  return (
    <div className="space-y-6">
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
                {ledgerBalance > total7DayPredictedSpend ? '100% Cubierto' : 'Requiere Recarga'}
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