import React from 'react';
import { Plus, Trash2 } from 'lucide-react';
import { Placement } from './types';

interface PlacementsViewProps {
  placements: Placement[];
  onNewPlacement: () => void;
  onDeletePlacement: (id: string, name: string) => void;
}

export const PlacementsView: React.FC<PlacementsViewProps> = ({
  placements,
  onNewPlacement,
  onDeletePlacement,
}) => {
  return (
    <section className="as-card-premium rounded-2xl p-6 space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-base font-bold text-white">Inventario de Ubicaciones Normalizadas</h3>
          <p className="text-xs text-slate-400">Espacios activos donde el servidor entrega anuncios verificados</p>
        </div>
        <button
          onClick={onNewPlacement}
          className="px-4 py-2 rounded-xl bg-amber-500 text-slate-950 text-xs font-bold flex items-center gap-1.5 cursor-pointer"
        >
          <Plus className="h-4 w-4" /> Nueva Ubicación
        </button>
      </div>

      <table className="w-full text-left border-collapse text-xs">
        <thead>
          <tr className="border-b border-slate-800 text-slate-400 uppercase">
            <th className="py-3">ID / Código Canónico</th>
            <th className="py-3">Nombre de Ubicación</th>
            <th className="py-3">Formato Técnico</th>
            <th className="py-3">CPM Piso</th>
            <th className="py-3">Impresiones / Clics</th>
            <th className="py-3 text-right">Acciones</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800/60">
          {placements.map((p: any) => (
            <tr key={p.id}>
              <td className="py-3.5 font-mono text-amber-400 font-bold">{p.id} • {p.code}</td>
              <td className="py-3.5 font-bold text-white">{p.name}</td>
              <td className="py-3.5 text-slate-300">{p.format}</td>
              <td className="py-3.5 font-mono">${Number(p.floorCpm || 0).toFixed(2)} MXN</td>
              <td className="py-3.5 font-mono">{p.impressions || 0} imp. / {p.clicks || 0} clics</td>
              <td className="py-3.5 text-right">
                <button onClick={() => onDeletePlacement(p.id, p.name)} className="text-slate-400 hover:text-rose-400 cursor-pointer"><Trash2 className="h-4 w-4 inline" /></button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
};