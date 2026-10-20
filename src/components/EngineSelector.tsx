import React from 'react';
import { EngineCategory } from '../types/adEngine';
import { Layers, Server, Cpu, Sparkles } from 'lucide-react';

interface EngineSelectorProps {
  currentCategory: EngineCategory;
  onSelectCategory: (category: EngineCategory) => void;
}

export const EngineSelector: React.FC<EngineSelectorProps> = ({
  currentCategory,
  onSelectCategory
}) => {
  return (
    <div className="border-b border-slate-800 bg-slate-900/40">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="text-center md:text-left md:flex md:items-end md:justify-between gap-6 mb-6">
          <div>
            <div className="flex items-center gap-2 text-xs text-amber-400 font-medium mb-1">
              <span>Arquitectura & Ingenier a de Sistemas</span>
              <span aria-hidden="true"> </span>
              <span>Gu cnica Exhaustiva</span>
            </div>
            <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-white">
                es y cu les son las funciones de un Motor AD?
            </h1>
            <p className="mt-2 text-sm sm:text-base text-slate-400 max-w-3xl">
              El t rmino <strong className="text-slate-200">"Motor AD"</strong> se utiliza en 3 disciplinas tecnol gicas esenciales. Explora en detalle cada una con diagramas, algoritmos y simuladores interactivos.
            </p>
          </div>
        </div>

        {/* 3 Main Categories Segmented Switcher */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 p-1.5 bg-slate-950/80 rounded-xl border border-slate-800">
          <button
            onClick={() => onSelectCategory('adtech')}
            className={`flex items-start gap-3 p-3.5 rounded-lg text-left transition-all cursor-pointer ${
              currentCategory === 'adtech'
                ? 'bg-slate-800 text-white shadow-md border border-slate-700/60'
                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-900/60'
            }`}
          >
            <div className={`p-2 rounded-lg shrink-0 ${currentCategory === 'adtech' ? 'bg-amber-500/20 text-amber-400' : 'bg-slate-800/60 text-slate-400'}`}>
              <Layers className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="font-semibold text-sm text-white">1. Motor de Publicidad (Ad Tech)</span>
                {currentCategory === 'adtech' && (
                  <span className="text-[10px] text-amber-400 font-mono">(Principal)</span>
                )}
              </div>
              <p className="text-xs text-slate-400 mt-0.5 line-clamp-2">
                Ad Server, subastas RTB &lt;50ms, targeting, pacing, control de frecuencia, eCPM y fraude.
              </p>
            </div>
          </button>
          <button
            onClick={() => onSelectCategory('activedirectory')}
            className={`flex items-start gap-3 p-3.5 rounded-lg text-left transition-all cursor-pointer ${
              currentCategory === 'activedirectory'
                ? 'bg-slate-800 text-white shadow-md border border-slate-700/60'
                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-900/60'
            }`}
          >
            <div className={`p-2 rounded-lg shrink-0 ${currentCategory === 'activedirectory' ? 'bg-amber-500/20 text-amber-400' : 'bg-slate-800/60 text-slate-400'}`}>
              <Server className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <span className="font-semibold text-sm text-white block">2. Active Directory (AD IT)</span>
              <p className="text-xs text-slate-400 mt-0.5 line-clamp-2">
                Directorio Activo de Microsoft, autenticaci n Kerberos, LDAP, NTDS.dit, GPO y replicaci
              </p>
            </div>
          </button>
          <button
            onClick={() => onSelectCategory('directdrive')}
            className={`flex items-start gap-3 p-3.5 rounded-lg text-left transition-all cursor-pointer ${
              currentCategory === 'directdrive'
                ? 'bg-slate-800 text-white shadow-md border border-slate-700/60'
                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-900/60'
            }`}
          >
            <div className={`p-2 rounded-lg shrink-0 ${currentCategory === 'directdrive' ? 'bg-amber-500/20 text-amber-400' : 'bg-slate-800/60 text-slate-400'}`}>
              <Cpu className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <span className="font-semibold text-sm text-white block">3. Accionamiento Directo (AD)</span>
              <p className="text-xs text-slate-400 mt-0.5 line-clamp-2">
                Motor electromec nico Direct Drive: alto par sin engranajes, cero holgura (Zero Backlash).
              </p>
            </div>
          </button>
        </div>
      </div>
    </div>
  );
};
