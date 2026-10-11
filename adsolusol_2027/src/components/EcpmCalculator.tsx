import React, { useState } from 'react';
import { Calculator, HelpCircle } from 'lucide-react';

export const EcpmCalculator: React.FC = () => {
  const [cpcBid, setCpcBid] = useState<number>(0.80);
  const [pctrPercent, setPctrPercent] = useState<number>(0.45); // 0.45%
  const [totalSpend, setTotalSpend] = useState<number>(1200);
  const [impressions, setImpressions] = useState<number>(450000);
  const [adRequests, setAdRequests] = useState<number>(500000);

  // Predictive eCPM = CPC * (pCTR / 100) * 1000
  const predictiveEcpm = (cpcBid * (pctrPercent / 100) * 1000).toFixed(2);
  
  // Effective eCPM = (Spend / Impressions) * 1000
  const effectiveEcpm = impressions > 0 ? ((totalSpend / impressions) * 1000).toFixed(2) : '0.00';
  
  // Fill Rate = (Impressions / AdRequests) * 100
  const fillRate = adRequests > 0 ? ((impressions / adRequests) * 100).toFixed(1) : '0.0';

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 sm:p-7">
      <div className="pb-5 border-b border-slate-800">
        <div className="flex items-center gap-2 text-xs text-amber-400 font-medium mb-1">
          <span>Modelos Matem ticos de Monetizaci n</span>
          <span aria-hidden="true"> </span>
          <span>F rmulas del Motor Ad</span>
        </div>
        <h3 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
          Calculadora de M tricas y Algoritmo eCPM
        </h3>
        <p className="text-xs sm:text-sm text-slate-400 mt-1 max-w-3xl">
          El motor ad convierte todas las ofertas (CPC, CPA, CPV) a una unidad com n de comparaci n llamada <strong>eCPM (Coste Efectivo por Mil Impresiones)</strong> para decidir qu  anuncio gana cada subasta.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-5">
        {/* Calculator 1: Predictive eCPM from CPC & CTR */}
        <div className="bg-slate-950 p-5 rounded-xl border border-slate-800 space-y-4">
          <div className="flex items-center justify-between">
            <span className="font-semibold text-sm text-white">1. eCPM Predictivo (Subasta RTB)</span>
            <span className="font-mono text-[11px] text-amber-400">eCPM = Oferta   pCTR   1000</span>
          </div>
          <div className="space-y-3 text-xs">
            <div>
              <div className="flex justify-between text-slate-300 mb-1">
                <span>Puja del Anunciante por Clic (CPC)</span>
                <span className="font-mono font-semibold text-white">${cpcBid.toFixed(2)} USD</span>
              </div>
              <input
                type="range"
                min="0.10"
                max="5.00"
                step="0.05"
                value={cpcBid}
                onChange={(e) => setCpcBid(parseFloat(e.target.value))}
                className="w-full accent-amber-400 cursor-pointer"
              />
            </div>
            <div>
              <div className="flex justify-between text-slate-300 mb-1">
                <span>Predicci n de Tasa de Clic (pCTR de IA)</span>
                <span className="font-mono font-semibold text-white">{pctrPercent.toFixed(2)}%</span>
              </div>
              <input
                type="range"
                min="0.05"
                max="2.50"
                step="0.05"
                value={pctrPercent}
                onChange={(e) => setPctrPercent(parseFloat(e.target.value))}
                className="w-full accent-amber-400 cursor-pointer"
              />
            </div>
          </div>
          <div className="p-3 bg-slate-900 rounded-lg border border-slate-800 flex items-center justify-between">
            <span className="text-xs text-slate-400">eCPM Competitivo Equivalente:</span>
            <span className="font-mono text-xl font-bold text-amber-400 tabular-nums">
              ${predictiveEcpm} <span className="text-xs font-normal text-slate-400">CPM</span>
            </span>
          </div>
        </div>

        {/* Calculator 2: Fill Rate & Yield */}
        <div className="bg-slate-950 p-5 rounded-xl border border-slate-800 space-y-4">
          <div className="flex items-center justify-between">
            <span className="font-semibold text-sm text-white">2. Rendimiento de Entrega (Fill Rate)</span>
            <span className="font-mono text-[11px] text-emerald-400">Fill = (Servidas / Requests)   100</span>
          </div>
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div>
              <label className="text-slate-400 block mb-1">Solicitudes Totales</label>
              <input
                type="number"
                value={adRequests}
                onChange={(e) => setAdRequests(parseInt(e.target.value) || 0)}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg px-2.5 py-1.5 text-white font-mono focus:outline-none focus:border-amber-400"
              />
            </div>
            <div>
              <label className="text-slate-400 block mb-1">Impresiones Servidas</label>
              <input
                type="number"
                value={impressions}
                onChange={(e) => setImpressions(parseInt(e.target.value) || 0)}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg px-2.5 py-1.5 text-white font-mono focus:outline-none focus:border-amber-400"
              />
            </div>
          </div>
          <div>
            <label className="text-slate-400 block mb-1 text-xs">Ingreso Bruto Total ($)</label>
            <input
              type="number"
              value={totalSpend}
              onChange={(e) => setTotalSpend(parseFloat(e.target.value) || 0)}
              className="w-full bg-slate-900 border border-slate-700 rounded-lg px-2.5 py-1.5 text-white font-mono text-xs focus:outline-none focus:border-amber-400"
            />
          </div>
          <div className="grid grid-cols-2 gap-2 text-xs">
            <div className="p-2.5 bg-slate-900 rounded-lg border border-slate-800">
              <span className="text-[11px] text-slate-400 block">Tasa de Llenado (Fill)</span>
              <span className="font-mono text-lg font-bold text-emerald-400 tabular-nums">{fillRate}%</span>
            </div>
            <div className="p-2.5 bg-slate-900 rounded-lg border border-slate-800">
              <span className="text-[11px] text-slate-400 block">eCPM Hist rico Real</span>
              <span className="font-mono text-lg font-bold text-amber-400 tabular-nums">${effectiveEcpm}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
