import React from 'react';
import { X, Sparkles, Navigation } from 'lucide-react';
import { BRANCH_LOCATIONS } from '../constants';

interface ActionDrawerProps {
  drawerType: 'campana' | 'ubicacion' | 'creativo' | 'asignacion' | null;
  onClose: () => void;
  onSubmit: (e: React.FormEvent) => void;
  campForm: any;
  setCampForm: React.Dispatch<React.SetStateAction<any>>;
  plcForm: any;
  setPlcForm: React.Dispatch<React.SetStateAction<any>>;
  crtForm: any;
  setCrtForm: React.Dispatch<React.SetStateAction<any>>;
  asgForm: any;
  setAsgForm: React.Dispatch<React.SetStateAction<any>>;
  onApplyAiPreset: () => void;
}

export const ActionDrawer: React.FC<ActionDrawerProps> = ({
  drawerType,
  onClose,
  onSubmit,
  campForm,
  setCampForm,
  plcForm,
  setPlcForm,
  crtForm,
  setCrtForm,
  asgForm,
  setAsgForm,
  onApplyAiPreset,
}) => {
  if (!drawerType) return null;

  return (
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex justify-end z-50">
      <form
        onSubmit={onSubmit}
        className="bg-[#0E1525] border-l border-amber-500/30 w-full max-w-md h-full p-6 flex flex-col justify-between shadow-2xl"
      >
        <div className="space-y-4">
          <div className="flex items-center justify-between border-b border-slate-800 pb-4">
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-amber-400">
                Registro Transaccional
              </span>
              <h3 className="text-base font-bold text-white">
                {drawerType === 'campana' && 'Crear Nueva Campaña'}
                {drawerType === 'ubicacion' && 'Registrar Nueva Ubicación'}
                {drawerType === 'creativo' && 'Registrar Nuevo Creativo HTTPS + GPS'}
                {drawerType === 'asignacion' && 'Vincular Recurso en Matriz'}
              </h3>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="p-1.5 rounded-lg bg-slate-800/80 text-slate-400 hover:text-white cursor-pointer"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          {drawerType === 'campana' && (
            <div className="space-y-3">
              <div>
                <label className="text-xs text-slate-400">Nombre de la campaña</label>
                <input
                  type="text"
                  required
                  placeholder="Ej. Ultrasonidos Hermosillo"
                  value={campForm.name}
                  onChange={(e) => setCampForm({ ...campForm, name: e.target.value })}
                  className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                />
              </div>
              <div>
                <label className="text-xs text-slate-400">Presupuesto Diario (MXN)</label>
                <input
                  type="number"
                  value={campForm.budget}
                  onChange={(e) => setCampForm({ ...campForm, budget: Number(e.target.value) })}
                  className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                />
              </div>
              <div>
                <label className="text-xs text-slate-400">CPC Máximo (MXN)</label>
                <input
                  type="number"
                  step="0.1"
                  value={campForm.maxCpc}
                  onChange={(e) => setCampForm({ ...campForm, maxCpc: Number(e.target.value) })}
                  className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                />
              </div>
            </div>
          )}

          {drawerType === 'ubicacion' && (
            <div className="space-y-3">
              <div>
                <label className="text-xs text-slate-400">Código Canónico</label>
                <input
                  type="text"
                  required
                  value={plcForm.code}
                  onChange={(e) => setPlcForm({ ...plcForm, code: e.target.value })}
                  className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                />
              </div>
              <div>
                <label className="text-xs text-slate-400">Nombre Descriptivo</label>
                <input
                  type="text"
                  required
                  value={plcForm.name}
                  onChange={(e) => setPlcForm({ ...plcForm, name: e.target.value })}
                  className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                />
              </div>
            </div>
          )}

          {drawerType === 'creativo' && (
            <div className="space-y-3">
              <button
                type="button"
                onClick={onApplyAiPreset}
                className="w-full py-2 rounded-xl bg-indigo-500/20 border border-indigo-400/40 text-indigo-300 text-xs font-bold flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <Sparkles className="h-3.5 w-3.5 text-amber-400" /> Autocompletar con IA Clínica
              </button>
              <div>
                <label className="text-xs text-slate-400">Título del Anuncio</label>
                <input
                  type="text"
                  required
                  value={crtForm.title}
                  onChange={(e) => setCrtForm({ ...crtForm, title: e.target.value })}
                  className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white"
                />
              </div>
              <div>
                <label className="text-xs text-slate-400">Descripción Persuasiva</label>
                <textarea
                  rows={2}
                  required
                  value={crtForm.description}
                  onChange={(e) => setCrtForm({ ...crtForm, description: e.target.value })}
                  className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-slate-400">URL Destino (HTTPS)</label>
                  <input
                    type="url"
                    required
                    value={crtForm.destinationUrl}
                    onChange={(e) => setCrtForm({ ...crtForm, destinationUrl: e.target.value })}
                    className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                  />
                </div>
                <div>
                  <label className="text-xs text-slate-400">WhatsApp de Contacto</label>
                  <input
                    type="text"
                    required
                    value={crtForm.whatsappContact}
                    onChange={(e) => setCrtForm({ ...crtForm, whatsappContact: e.target.value })}
                    className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                  />
                </div>
              </div>
              <div>
                <label className="text-xs text-amber-400 font-semibold flex items-center gap-1">
                  <Navigation className="h-3.5 w-3.5" /> Dirección GPS para Botón "Cómo llegar"
                </label>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-1">
                  <input
                    type="text"
                    value={crtForm.locationAddress}
                    onChange={(e) => setCrtForm({ ...crtForm, locationAddress: e.target.value })}
                    className="sm:col-span-2 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
                  />
                  <select
                    value={crtForm.locationAddress}
                    onChange={(e) => setCrtForm({ ...crtForm, locationAddress: e.target.value })}
                    className="bg-[#070B12] border border-amber-500/40 rounded-xl px-2.5 py-2 text-xs text-amber-400 font-bold"
                  >
                    {BRANCH_LOCATIONS.map((b, idx) => (
                      <option key={idx} value={b.address}>{b.label}</option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          )}

          {drawerType === 'asignacion' && (
            <div className="space-y-3">
              <div>
                <label className="text-xs text-slate-400">ID de Campaña</label>
                <input
                  type="text"
                  required
                  value={asgForm.campaignId}
                  onChange={(e) => setAsgForm({ ...asgForm, campaignId: e.target.value })}
                  className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white font-mono"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-slate-400">ID de Creativo</label>
                  <input
                    type="text"
                    required
                    value={asgForm.creativeId}
                    onChange={(e) => setAsgForm({ ...asgForm, creativeId: e.target.value })}
                    className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white font-mono"
                  />
                </div>
                <div>
                  <label className="text-xs text-slate-400">ID de Ubicación</label>
                  <input
                    type="text"
                    required
                    value={asgForm.placementId}
                    onChange={(e) => setAsgForm({ ...asgForm, placementId: e.target.value })}
                    className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white font-mono"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-slate-400">Peso de Subasta (1-100)</label>
                  <input
                    type="number"
                    min="1"
                    max="100"
                    value={asgForm.weight}
                    onChange={(e) => setAsgForm({ ...asgForm, weight: Number(e.target.value) })}
                    className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white font-mono"
                  />
                </div>
                <div>
                  <label className="text-xs text-slate-400">Prioridad</label>
                  <input
                    type="number"
                    min="1"
                    max="10"
                    value={asgForm.priority}
                    onChange={(e) => setAsgForm({ ...asgForm, priority: Number(e.target.value) })}
                    className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white font-mono"
                  />
                </div>
              </div>
              <p className="text-[11px] text-slate-400 leading-relaxed pt-1">
                La asignación vinculará la entidad en el motor bajo el algoritmo de Pacing Ponderado por Presupuesto.
              </p>
            </div>
          )}
        </div>

        <div className="flex justify-end gap-2 pt-4 border-t border-slate-800">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2.5 rounded-xl bg-slate-800 text-xs font-bold text-slate-300 cursor-pointer hover:bg-slate-700"
          >
            Cancelar
          </button>
          <button
            type="submit"
            className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold cursor-pointer"
          >
            Guardar en Servidor
          </button>
        </div>
      </form>
    </div>
  );
};