import React from 'react';

interface ConfirmDeleteModalProps {
  confirmDelete: { collection: string; id: string; name: string } | null;
  onCancel: () => void;
  onConfirm: () => void;
}

export const ConfirmDeleteModal: React.FC<ConfirmDeleteModalProps> = ({
  confirmDelete,
  onCancel,
  onConfirm,
}) => {
  if (!confirmDelete) return null;

  return (
    <div className="fixed inset-0 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4 z-50">
      <div className="bg-[#0E1422] border border-rose-500/40 rounded-2xl p-6 w-full max-w-sm space-y-4">
        <h4 className="text-base font-bold text-white">Confirmar Eliminación</h4>
        <p className="text-xs text-slate-300">
          {`¿Estás seguro de que deseas eliminar "${confirmDelete.name}" (${confirmDelete.id})? Esta acción quedará registrada.`}
        </p>
        <div className="flex justify-end gap-2">
          <button
            onClick={onCancel}
            className="px-4 py-2 rounded-xl bg-slate-800 text-xs font-bold text-slate-300 cursor-pointer hover:bg-slate-700"
          >
            Cancelar
          </button>
          <button
            onClick={onConfirm}
            className="px-4 py-2 rounded-xl bg-rose-600 text-white text-xs font-bold cursor-pointer hover:bg-rose-500"
          >
            Sí, Eliminar
          </button>
        </div>
      </div>
    </div>
  );
};