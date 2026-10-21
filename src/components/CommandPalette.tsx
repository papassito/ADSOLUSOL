import React from 'react';
import { Command } from 'lucide-react';
import { ModuleKey } from '../types';
import { MODULE_META } from '../constants';

interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
  query: string;
  onQueryChange: (val: string) => void;
  onSelectModule: (key: ModuleKey) => void;
  onOpenGps: () => void;
}

export const CommandPalette: React.FC<CommandPaletteProps> = ({
  isOpen,
  onClose,
  query,
  onQueryChange,
  onSelectModule,
  onOpenGps,
}) => {
  if (!isOpen) return null;

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 bg-black/75 backdrop-blur-sm flex items-start justify-center pt-24 p-4 z-50"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="bg-[#0E1525] border border-amber-500/40 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl"
      >
        <div className="p-3.5 border-b border-slate-800 flex items-center gap-2.5">
          <Command className="h-4 w-4 text-amber-400" />
          <input
            type="text"
            autoFocus
            value={query}
            onChange={(e) => onQueryChange(e.target.value)}
            placeholder="Escribe un comando o módulo (ej. analitica, creativos, sistema)..."
            className="w-full bg-transparent text-xs text-white focus:outline-none"
          />
          <span className="text-[10px] font-mono text-slate-500">ESC</span>
        </div>
        <div className="p-2 max-h-72 overflow-y-auto space-y-1 text-xs">
          <button
            onClick={() => {
              onOpenGps();
              onClose();
            }}
            className="w-full text-left px-3 py-2 rounded-xl hover:bg-slate-800 flex items-center justify-between cursor-pointer"
          >
            <span className="font-bold text-cyan-400">
              📍 Probar Botón "Cómo llegar" (Google Maps + Débito GPS)
            </span>
            <span className="font-mono text-[10px] text-slate-400">Ruta GPS</span>
          </button>
          {(Object.keys(MODULE_META) as ModuleKey[])
            .filter((k) => MODULE_META[k].title.toLowerCase().includes(query.toLowerCase()))
            .map((k) => (
              <button
                key={k}
                onClick={() => {
                  onSelectModule(k);
                  onClose();
                }}
                className="w-full text-left px-3 py-2 rounded-xl hover:bg-slate-800 flex items-center justify-between cursor-pointer"
              >
                <span>Ir a {MODULE_META[k].title}</span>
                <span className="text-[10px] text-slate-500">{MODULE_META[k].category}</span>
              </button>
            ))}
        </div>
      </div>
    </div>
  );
};