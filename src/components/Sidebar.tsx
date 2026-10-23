import React from 'react';
import { ModuleKey } from '../types';
import { MODULE_META } from '../constants';

interface SidebarProps {
  activeModule: ModuleKey;
  onSelectModule: (key: ModuleKey) => void;
  campaignsOver90Count: number;
  totalDirections: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeModule,
  onSelectModule,
  campaignsOver90Count,
  totalDirections,
}) => {
  const categories = [
    'Operación Central',
    'Inventario y Creativos',
    'Motor AdServer',
    'Inteligencia y Finanzas',
    'Gobernanza y Sistema',
  ];

  return (
    <aside className="w-16 md:w-68 bg-[#0B101B]/95 border-r border-slate-800/80 flex flex-col justify-between shrink-0 backdrop-blur-xl">
      <div>
        <div className="p-3 md:p-5 border-b border-slate-800/80 flex items-center justify-center md:justify-start gap-3">
          <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-amber-400 to-amber-600 text-slate-950 flex items-center justify-center font-black shadow-lg shadow-amber-500/25">
            ADS
          </div>
          <div className="hidden md:block">
            <h1
              style={{ fontFamily: "'Space Grotesk', sans-serif" }}
              className="text-base font-bold tracking-tight text-white"
            >
              ADSOLUSOL 2027
            </h1>
            <p className="text-[11px] text-amber-400 font-semibold">
              Command Suite Soberana
            </p>
          </div>
        </div>

        <nav className="p-2 md:p-3 space-y-5 overflow-y-auto max-h-[calc(100vh-100px)] md:max-h-[calc(100vh-160px)]">
          {categories.map((cat) => (
            <div key={cat}>
              <p className="hidden md:block px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                {cat}
              </p>
              <div className="space-y-1">
                {(Object.keys(MODULE_META) as ModuleKey[])
                  .filter((k) => MODULE_META[k].category === cat)
                  .map((key) => {
                    const item = MODULE_META[key];
                    const Icon = item.icon;
                    const active = activeModule === key;
                    return (
                      <button
                        key={key}
                        onClick={() => onSelectModule(key)}
                        aria-label={item.title}
                        title={item.title}
                        className={`w-full flex items-center justify-center md:justify-between px-2 md:px-3 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                          active
                            ? 'bg-gradient-to-r from-amber-500 to-amber-400 text-slate-950 font-bold shadow-md shadow-amber-500/20'
                            : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 hover:translate-x-0.5'
                        }`}
                      >
                        <span className="flex items-center justify-center md:justify-start gap-2.5">
                          <Icon className="h-4 w-4 shrink-0" />
                          <span className="hidden md:inline">{item.title}</span>
                        </span>
                        {key === 'alertas' && campaignsOver90Count > 0 && (
                          <span className="px-1.5 py-0.5 text-[10px] rounded-full bg-rose-500 text-white font-bold animate-pulse">
                            {campaignsOver90Count}
                          </span>
                        )}
                      </button>
                    );
                  })}
              </div>
            </div>
          ))}
        </nav>
      </div>

      <div className="hidden md:block p-4 border-t border-slate-800/80 bg-[#080C14] text-[11px]">
        <div className="flex items-center justify-between text-slate-400">
          <span>Rutas GPS Hoy:</span>
          <span className="font-mono text-cyan-400 font-bold">{`${totalDirections} pacientes`}</span>
        </div>
        <div className="flex items-center justify-between text-slate-400 mt-1">
          <span>Centinela 90%:</span>
          <span className="font-mono text-emerald-400 font-bold">Push Activo</span>
        </div>
      </div>
    </aside>
  );
};