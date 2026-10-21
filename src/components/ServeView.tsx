import React from 'react';
import { Navigation } from 'lucide-react';

interface ServeViewProps {
  lastDecision: any;
  onServeImpression: () => void;
  onServeClick: () => void;
  onOpenDirectionsMaps: (address: string) => void;
}

export const ServeView: React.FC<ServeViewProps> = ({
  lastDecision,
  onServeImpression,
  onServeClick,
  onOpenDirectionsMaps,
}) => {
  return (
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
            onClick={onServeImpression}
            className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-bold text-white cursor-pointer"
          >
            Solicitar Impresión (Serve)
          </button>
          <button
            onClick={onServeClick}
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
            <p>{`Campaña Ganadora: ${lastDecision.campaign?.id} (${lastDecision.campaign?.name})`}</p>
            <p>{`Creativo Entregado: ${lastDecision.creative?.id}`}</p>
            <p className="text-emerald-400">{`Invariante Presupuestaria: ${lastDecision.atomicCheck}`}</p>
            <p className="text-cyan-400">{`Nonce Anti-Replay: ${lastDecision.nonce}`}</p>
            <p className="text-slate-400">{`Firma: ${lastDecision.signature}`}</p>
          </div>

          <div className="p-5 rounded-xl bg-white text-slate-900 space-y-2">
            <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded bg-slate-200 text-slate-800">
              Creativo Renderizado en Ubicación
            </span>
            <h4 className="text-base font-bold text-blue-700">{lastDecision.creative?.title}</h4>
            <p className="text-xs text-slate-700">{lastDecision.creative?.description}</p>
            <div className="pt-2 flex flex-wrap gap-2">
              <button
                onClick={() => onOpenDirectionsMaps(lastDecision.creative?.locationAddress)}
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
  );
};