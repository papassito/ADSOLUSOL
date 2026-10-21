import React from 'react';
import { ShieldAlert } from 'lucide-react';

interface AudiencesViewProps {
  competitorTerms: Array<{ id: string; term: string; wasted: number; category: string; blocked: boolean }>;
  onToggleBlockTerm: (id: string) => void;
  shieldSavings: number;
  audiences: any[];
}

export const AudiencesView: React.FC<AudiencesViewProps> = ({
  competitorTerms,
  onToggleBlockTerm,
  shieldSavings,
  audiences,
}) => {
  return (
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
            {`Ahorro Protegido: $${shieldSavings.toFixed(2)} MXN`}
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {competitorTerms.map((item) => (
            <div key={item.id} className="p-4 rounded-xl bg-[#070B12] border border-slate-800 flex items-center justify-between gap-3">
              <div>
                <p className={`text-xs font-bold ${item.blocked ? 'line-through text-rose-400' : 'text-white'}`}>
                  {`"${item.term}"`}
                </p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  {`${item.category} • Fuga estimada: $${item.wasted.toFixed(2)} MXN`}
                </p>
              </div>
              <button
                onClick={() => onToggleBlockTerm(item.id)}
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
            <div key={aud.id} className="p-4 rounded-xl bg-[#070B12] border border-slate-800 space-y-2">
              <span className="text-[10px] font-mono text-amber-400 font-bold">{aud.id}</span>
              <p className="text-sm font-bold text-white">{aud.segment}</p>
              <p className="text-xs text-slate-400">{`Participación: ${aud.share} • ${aud.device}`}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};