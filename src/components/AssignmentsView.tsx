import React from 'react';
import { Plus } from 'lucide-react';

interface AssignmentsViewProps {
  assignments: any[];
  onNewAssignment: () => void;
}

export const AssignmentsView: React.FC<AssignmentsViewProps> = ({
  assignments,
  onNewAssignment,
}) => {
  return (
    <section className="as-card-premium rounded-2xl p-6 space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-base font-bold text-white">Matriz Operativa de Asignaciones</h3>
          <p className="text-xs text-slate-400">
            Vínculos activos entre Campañas, Creativos y Ubicaciones con peso de subasta
          </p>
        </div>
        <button
          onClick={onNewAssignment}
          className="px-4 py-2 rounded-xl bg-amber-500 text-slate-950 text-xs font-bold flex items-center gap-1.5 cursor-pointer"
        >
          <Plus className="h-4 w-4" /> Nueva Asignación
        </button>
      </div>

      <table className="w-full text-left border-collapse text-xs">
        <thead>
          <tr className="border-b border-slate-800 text-slate-400 uppercase">
            <th className="py-3">ID Asignación</th>
            <th className="py-3">Campaña</th>
            <th className="py-3">Creativo</th>
            <th className="py-3">Ubicación</th>
            <th className="py-3">Peso / Prioridad</th>
            <th className="py-3">Modo de Pacing</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800/60">
          {assignments.map((a: any) => (
            <tr key={a.id}>
              <td className="py-3.5 font-mono text-amber-400 font-bold">{a.id}</td>
              <td className="py-3.5 font-mono text-white">{a.campaignId}</td>
              <td className="py-3.5 font-mono text-cyan-400">{a.creativeId}</td>
              <td className="py-3.5 font-mono text-emerald-400">{a.placementId}</td>
              <td className="py-3.5 font-mono">{`Peso: ${a.weight} (P${a.priority})`}</td>
              <td className="py-3.5 text-slate-300">{a.pacingMode}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
};