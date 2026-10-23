import React, { useState } from 'react';
import { AD_ENGINE_FUNCTIONS } from '../data/adEngineData';
import { AdFunctionCard } from './AdFunctionCard';
import { ArchitectureFlow } from './ArchitectureFlow';
import { EcpmCalculator } from './EcpmCalculator';
import { Search, SlidersHorizontal, Activity, Layers, Cpu, ShieldCheck } from 'lucide-react';

export const AdEngineOverview: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'functions' | 'architecture' | 'calculator'>('functions');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  const filteredFunctions = AD_ENGINE_FUNCTIONS.filter((fn) => {
    const matchesSearch =
      fn.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      fn.shortDescription.toLowerCase().includes(searchQuery.toLowerCase()) ||
      fn.keyCapabilities.some((c) => c.toLowerCase().includes(searchQuery.toLowerCase())) ||
      fn.technicalSpecs.protocolOrStandard.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCat = selectedCategory === 'all' || fn.category === selectedCategory;
    return matchesSearch && matchesCat;
  });

  return (
    <div className="space-y-8">
      {/* Intro Header & Quick Stats */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 sm:p-8">
        <div className="max-w-4xl">
          <div className="flex items-center gap-2 text-xs text-amber-400 font-medium mb-1">
            <span>Servidor de Publicidad & Ad Tech</span>
            <span aria-hidden="true"> </span>
            <span>Est ndares IAB Tech Lab & OpenRTB</span>
          </div>
          <h2 className="text-xl sm:text-2xl lg:text-3xl font-bold text-white tracking-tight">
            Motor de Publicidad Digital (Ad Serving & RTB Bidding Engine)
          </h2>
          <p className="mt-2 text-xs sm:text-sm text-slate-300 leading-relaxed">
            Un <strong>Motor Ad (Ad Engine)</strong> es el cerebro inform tico distribuido de alta disponibilidad que orquesta la entrega, subasta, segmentaci n, optimizaci n y medici n de miles de millones de anuncios en la web, aplicaciones m viles, videojuegos y televisi n conectada (CTV), operando bajo un estricto SLA de <strong>menos de 50 milisegundos</strong> por impresi 
          </p>
        </div>

        {/* Quick Specs strip (no static pills, clean metadata) */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-6 pt-6 border-t border-slate-800 text-xs">
          <div>
            <span className="text-slate-400 text-[11px] block">Presupuesto de Latencia</span>
            <span className="font-mono text-base font-bold text-amber-400">&lt; 50 ms</span>
            <span className="text-[10px] text-slate-500 block">HTTP a Renderizado</span>
          </div>
          <div>
            <span className="text-slate-400 text-[11px] block">Protocolo Principal</span>
            <span className="font-mono text-base font-bold text-white">OpenRTB 2.5/3.0</span>
            <span className="text-[10px] text-slate-500 block">IAB Tech Lab Standard</span>
          </div>
          <div>
            <span className="text-slate-400 text-[11px] block">Norma de Medici n</span>
            <span className="font-mono text-base font-bold text-emerald-400">MRC & OM SDK</span>
            <span className="text-[10px] text-slate-500 block">50% px / 1.0s continuo</span>
          </div>
          <div>
            <span className="text-slate-400 text-[11px] block">Macro-Funciones</span>
            <span className="font-mono text-base font-bold text-white">10 Fundamentales</span>
            <span className="text-[10px] text-slate-500 block">De Ingesta a Atribuci n</span>
          </div>
        </div>
      </div>

      {/* Internal Interactive Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-800 pb-2 overflow-x-auto">
        <button
          onClick={() => setActiveTab('functions')}
          className={`px-4 py-2 text-xs font-semibold rounded-lg transition-colors cursor-pointer whitespace-nowrap flex items-center gap-2 ${
            activeTab === 'functions'
              ? 'bg-amber-400 text-slate-950 shadow-sm'
              : 'text-slate-400 hover:text-white hover:bg-slate-900'
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>Las 10 Funciones Detalladas</span>
        </button>
        <button
          onClick={() => setActiveTab('architecture')}
          className={`px-4 py-2 text-xs font-semibold rounded-lg transition-colors cursor-pointer whitespace-nowrap flex items-center gap-2 ${
            activeTab === 'architecture'
              ? 'bg-amber-400 text-slate-950 shadow-sm'
              : 'text-slate-400 hover:text-white hover:bg-slate-900'
          }`}
        >
          <Activity className="w-4 h-4" />
          <span>Ciclo de Vida &lt;50ms</span>
        </button>
        <button
          onClick={() => setActiveTab('calculator')}
          className={`px-4 py-2 text-xs font-semibold rounded-lg transition-colors cursor-pointer whitespace-nowrap flex items-center gap-2 ${
            activeTab === 'calculator'
              ? 'bg-amber-400 text-slate-950 shadow-sm'
              : 'text-slate-400 hover:text-white hover:bg-slate-900'
          }`}
        >
          <Cpu className="w-4 h-4" />
          <span>Calculadora eCPM</span>
        </button>
      </div>

      {/* Tab 1: Detailed Functions List with Search & Category Filters */}
      {activeTab === 'functions' && (
        <div className="space-y-6">
          {/* Search bar & filter pills */}
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-slate-900/60 p-4 rounded-xl border border-slate-800">
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Buscar funciones, algoritmos, est ndares (ej. subasta, pacing, MRC, fraude, VAST, cookies)..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-lg pl-9 pr-4 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
              />
            </div>
            <div className="flex items-center gap-1.5 overflow-x-auto text-xs shrink-0">
              <span className="text-[11px] text-slate-400 mr-1 hidden sm:inline">Filtrar:</span>
              <button
                onClick={() => setSelectedCategory('all')}
                className={`px-2.5 py-1 rounded-md text-xs font-medium cursor-pointer transition-colors ${
                  selectedCategory === 'all'
                    ? 'bg-amber-400/20 text-amber-300 border border-amber-400/40'
                    : 'text-slate-400 hover:text-white bg-slate-950/60'
                }`}
              >
                Todas (10)
              </button>
              <button
                onClick={() => setSelectedCategory('subasta')}
                className={`px-2.5 py-1 rounded-md text-xs font-medium cursor-pointer transition-colors ${
                  selectedCategory === 'subasta'
                    ? 'bg-amber-400/20 text-amber-300 border border-amber-400/40'
                    : 'text-slate-400 hover:text-white bg-slate-950/60'
                }`}
              >
                Subasta
              </button>
              <button
                onClick={() => setSelectedCategory('targeting')}
                className={`px-2.5 py-1 rounded-md text-xs font-medium cursor-pointer transition-colors ${
                  selectedCategory === 'targeting'
                    ? 'bg-amber-400/20 text-amber-300 border border-amber-400/40'
                    : 'text-slate-400 hover:text-white bg-slate-950/60'
                }`}
              >
                Targeting
              </button>
              <button
                onClick={() => setSelectedCategory('pacing')}
                className={`px-2.5 py-1 rounded-md text-xs font-medium cursor-pointer transition-colors ${
                  selectedCategory === 'pacing'
                    ? 'bg-amber-400/20 text-amber-300 border border-amber-400/40'
                    : 'text-slate-400 hover:text-white bg-slate-950/60'
                }`}
              >
                Pacing
              </button>
              <button
                onClick={() => setSelectedCategory('ml')}
                className={`px-2.5 py-1 rounded-md text-xs font-medium cursor-pointer transition-colors ${
                  selectedCategory === 'ml'
                    ? 'bg-amber-400/20 text-amber-300 border border-amber-400/40'
                    : 'text-slate-400 hover:text-white bg-slate-950/60'
                }`}
              >
                IA & eCPM
              </button>
              <button
                onClick={() => setSelectedCategory('seguridad')}
                className={`px-2.5 py-1 rounded-md text-xs font-medium cursor-pointer transition-colors ${
                  selectedCategory === 'seguridad'
                    ? 'bg-amber-400/20 text-amber-300 border border-amber-400/40'
                    : 'text-slate-400 hover:text-white bg-slate-950/60'
                }`}
              >
                Antifraude
              </button>
            </div>
          </div>

          {/* Cards List */}
          <div className="space-y-4">
            {filteredFunctions.length === 0 ? (
              <div className="text-center py-12 bg-slate-900/40 border border-slate-800 rounded-xl p-8">
                <p className="text-sm text-slate-400">
                  No se encontraron funciones que coincidan con los filtros aplicados.
                </p>
                <button
                  onClick={() => {
                    setSearchQuery('');
                    setSelectedCategory('all');
                  }}
                  className="mt-3 text-xs text-amber-400 hover:underline cursor-pointer"
                >
                  Restablecer filtros
                </button>
              </div>
            ) : (
              filteredFunctions.map((item, index) => (
                <AdFunctionCard
                  key={item.id}
                  item={item}
                  defaultExpanded={index === 0}
                />
              ))
            )}
          </div>
        </div>
      )}

      {/* Tab 3: 50ms Lifecycle Architecture */}
      {activeTab === 'architecture' && <ArchitectureFlow />}

      {/* Tab 4: Mathematical eCPM Calculator */}
      {activeTab === 'calculator' && <EcpmCalculator />}
    </div>
  );
};
