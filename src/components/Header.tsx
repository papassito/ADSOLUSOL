import React from 'react';
import { BookOpen, Download } from 'lucide-react';
import { EngineCategory } from '../types/adEngine';

interface HeaderProps {
  currentCategory: EngineCategory;
  onSelectCategory: (category: EngineCategory) => void;
  onOpenGlossary: () => void;
  onOpenSummary: () => void;
  activeSection: string;
}

export const Header: React.FC<HeaderProps> = ({
  currentCategory,
  onSelectCategory,
  onOpenGlossary,
  onOpenSummary,
  activeSection
}) => {
  return (
    <header className="sticky top-0 z-40 bg-slate-950/90 backdrop-blur-md border-b border-slate-800">
      {/* 3-zone Top Bar Contract as specified in frontend-design guidelines */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-8">
        
        {/* Zone 1: Brand wordmark (single line, no attached subtitle chips) */}
        <div className="flex items-center gap-3 shrink-0">
          <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-amber-500 to-amber-700 flex items-center justify-center font-bold text-slate-950 text-base shadow-sm">
            AD
          </div>
          <span className="text-lg font-bold tracking-tight text-white whitespace-nowrap">
            Motor AD Architecture
          </span>
        </div>

        {/* Zone 2: Navigation Links (concise, single-line text links) */}
        <nav className="hidden md:flex items-center gap-6 text-sm font-medium text-slate-300">
          <button
            onClick={() => onSelectCategory('adtech')}
            className={`whitespace-nowrap transition-colors py-1 cursor-pointer ${
              currentCategory === 'adtech'
                ? 'text-amber-400 font-semibold border-b-2 border-amber-400'
                : 'hover:text-white'
            }`}
          >
            Motor de Publicidad (Ad Tech)
          </button>
          <button
            onClick={() => onSelectCategory('activedirectory')}
            className={`whitespace-nowrap transition-colors py-1 cursor-pointer ${
              currentCategory === 'activedirectory'
                ? 'text-amber-400 font-semibold border-b-2 border-amber-400'
                : 'hover:text-white'
            }`}
          >
            Active Directory (AD IT)
          </button>
          <button
            onClick={() => onSelectCategory('directdrive')}
            className={`whitespace-nowrap transition-colors py-1 cursor-pointer ${
              currentCategory === 'directdrive'
                ? 'text-amber-400 font-semibold border-b-2 border-amber-400'
                : 'hover:text-white'
            }`}
          >
            Accionamiento Directo (Mec nica)
          </button>
          <button
            onClick={onOpenGlossary}
            className="whitespace-nowrap text-slate-400 hover:text-white transition-colors cursor-pointer flex items-center gap-1.5"
          >
            <BookOpen className="w-3.5 h-3.5" />
            Glosario
          </button>
        </nav>

        {/* Zone 3: Primary Action */}
        <div className="flex items-center gap-3 shrink-0">
          <button
            onClick={onOpenSummary}
            className="px-4 py-2 text-xs font-semibold text-slate-950 bg-amber-400 hover:bg-amber-300 active:scale-98 transition-all rounded-lg whitespace-nowrap flex items-center gap-1.5 shadow-sm cursor-pointer"
          >
            <Download className="w-3.5 h-3.5" />
            Resumen Ejecutivo
          </button>
        </div>
      </div>
    </header>
  );
};
