import React, { useState } from 'react';
import { AdFunctionItem } from '../types/adEngine';
import { ChevronDown, ChevronUp, Code2, AlertTriangle, Cpu, Gauge } from 'lucide-react';

interface AdFunctionCardProps {
  item: AdFunctionItem;
  defaultExpanded?: boolean;
}

export const AdFunctionCard: React.FC<AdFunctionCardProps> = ({ item, defaultExpanded = false }) => {
  const [isExpanded, setIsExpanded] = useState<boolean>(defaultExpanded);
  const [showCode, setShowCode] = useState<boolean>(false);

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 sm:p-6 transition-all hover:border-slate-700/80">
      {/* Header section */}
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-3">
        <div className="flex items-baseline gap-3">
          <span className="font-mono text-xl sm:text-2xl font-bold text-amber-400">
            {item.number}.
          </span>
          <div>
            <h3 className="text-base sm:text-lg font-bold text-white tracking-tight">
              {item.name}
            </h3>
            {/* Zero-pill metadata as specified in frontend-design */}
            <div className="flex items-center gap-2 text-xs text-slate-400 mt-1">
              <span>{item.categoryLabel}</span>
              <span aria-hidden="true"> </span>
              <span>Prioridad {item.importance}</span>
              <span aria-hidden="true"> </span>
              <span className="font-mono text-amber-400/90">{item.latencyImpact}</span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2 self-end sm:self-auto shrink-0">
          {item.codeExample && (
            <button
              onClick={() => setShowCode(!showCode)}
              className={`p-2 rounded-lg text-xs font-medium flex items-center gap-1.5 transition-colors cursor-pointer ${
                showCode ? 'bg-amber-400/20 text-amber-300' : 'bg-slate-800 text-slate-400 hover:text-white'
              }`}
              title="Ver c digo/protocolo t cnico"
            >
              <Code2 className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">C digo</span>
            </button>
          )}
          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className="p-2 rounded-lg text-xs font-medium bg-slate-800 text-slate-300 hover:text-white transition-colors cursor-pointer flex items-center gap-1"
          >
            <span className="text-xs">{isExpanded ? 'Menos' : 'Detalles'}</span>
            {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Short Summary */}
      <p className="text-xs sm:text-sm text-slate-300 leading-relaxed mb-4">
        {item.shortDescription}
      </p>

      {/* Core capabilities list */}
      <div className="space-y-1.5 text-xs text-slate-300 mb-4 bg-slate-950/40 p-3.5 rounded-lg border border-slate-800/60">
        <span className="text-[11px] font-semibold text-slate-400 block mb-1">
          Capacidades Operativas Clave:
        </span>
        <ul className="space-y-1">
          {item.keyCapabilities.slice(0, isExpanded ? undefined : 3).map((cap, idx) => (
            <li key={idx} className="flex items-start gap-2">
              <span className="text-amber-400 mt-0.5"> </span>
              <span>{cap}</span>
            </li>
          ))}
        </ul>
        {!isExpanded && item.keyCapabilities.length > 3 && (
          <button
            onClick={() => setIsExpanded(true)}
            className="text-[11px] text-amber-400 hover:underline pt-1 cursor-pointer block"
          >
            + Ver {item.keyCapabilities.length - 3} capacidades m s...
          </button>
        )}
      </div>

      {/* Code Snippet Box (Toggleable) */}
      {showCode && item.codeExample && (
        <div className="mb-4 bg-slate-950 rounded-lg p-3.5 border border-slate-800 text-xs font-mono overflow-x-auto">
          <div className="flex items-center justify-between text-slate-500 text-[11px] pb-2 border-b border-slate-900 mb-2">
            <span>{item.codeExample.title}</span>
            <span className="uppercase">{item.codeExample.language}</span>
          </div>
          <pre className="text-amber-300/90 leading-relaxed text-[11px]">
            {item.codeExample.code}
          </pre>
        </div>
      )}

      {/* Expanded deep technical specifications */}
      {isExpanded && (
        <div className="pt-4 border-t border-slate-800/80 space-y-4">
          <p className="text-xs text-slate-300 leading-relaxed">
            {item.detailedDescription}
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 text-xs">
            <div className="p-3 bg-slate-950/70 rounded-lg border border-slate-800/60">
              <div className="flex items-center gap-1.5 text-slate-400 mb-1 text-[11px]">
                <Cpu className="w-3.5 h-3.5 text-amber-400" />
                <span>Protocolo / Est ndar</span>
              </div>
              <span className="font-mono text-white text-xs font-medium">
                {item.technicalSpecs.protocolOrStandard}
              </span>
            </div>
            <div className="p-3 bg-slate-950/70 rounded-lg border border-slate-800/60">
              <div className="flex items-center gap-1.5 text-slate-400 mb-1 text-[11px]">
                <Gauge className="w-3.5 h-3.5 text-emerald-400" />
                <span>M tricas de Control</span>
              </div>
              <span className="text-slate-300 text-[11px]">
                {item.technicalSpecs.metrics.join('   ')}
              </span>
            </div>
            <div className="p-3 bg-slate-950/70 rounded-lg border border-slate-800/60 sm:col-span-2 lg:col-span-1">
              <div className="flex items-center gap-1.5 text-rose-400 mb-1 text-[11px]">
                <AlertTriangle className="w-3.5 h-3.5" />
                <span>Riesgo en caso de fallo</span>
              </div>
              <span className="text-slate-300 text-[11px]">
                {item.technicalSpecs.riskIfFailed}
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
