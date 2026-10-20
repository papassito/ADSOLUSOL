import React, { useState } from 'react';
import { Clock, Cpu, Shield, Activity, DollarSign, Layers } from 'lucide-react';

interface StageDetail {
  id: string;
  ms: string;
  title: string;
  engineFunction: string;
  summary: string;
  substeps: string[];
  protocol: string;
}

const STAGES: StageDetail[] = [
  {
    id: 't0',
    ms: '0 - 5 ms',
    title: 'Ingesta y Parseo de Se ales',
    engineFunction: 'Recepci n y Enriquecimiento (01)',
    summary: 'El navegador o SDK env a la solicitud HTTP. El motor descifra las cabeceras, geolocaliza la IP y valida el consentimiento legal.',
    substeps: [
      'Terminaci n TLS en Edge PoP m s cercano',
      'Extracci n del Slot ID (ej. 300x250, Video VAST)',
      'Decodificaci n del Consent String TCF v2.2 (GDPR / CCPA)',
      'Resoluci n de Geohash por IP y detecci sica de bots'
    ],
    protocol: 'OpenRTB 2.5 / 3.0, gRPC, HTTP/2'
  },
  {
    id: 't1',
    ms: '5 - 15 ms',
    title: 'Elegibilidad, Filtros y Pacing',
    engineFunction: 'Targeting (02), Pacing (04), Frecuencia (05)',
    summary: 'Consulta memorias ultrarr pidas en memoria (Redis/Aerospike) para verificar l mites de frecuencia y balanceo presupuestario.',
    substeps: [
      'Filtrado de campa as elegibles usando Roaring Bitmaps',
      'Comprobaci n del Frequency Cap del usuario (m x. 3 al d a)',
      'Evaluaci n del PID Controller de Pacing presupuestario',
      'Descarte de campa as sin presupuesto activo'
    ],
    protocol: 'Redis Cluster In-Memory, Aerospike SSD, Bitsets'
  },
  {
    id: 't2',
    ms: '15 - 35 ms',
    title: 'Subasta RTB y Prebid Simult neo',
    engineFunction: 'Subastas en Tiempo Real (03) y ML eCPM (06)',
    summary: 'Emite llamados de subasta concurrentes a DSPs (DV360, The Trade Desk) con un timeout estricto de 20ms.',
    substeps: [
      'Env o paralelo de Bid Requests a 10+ DSPs y Ad Networks',
      'Recepci n de ofertas competitivas concurrentes',
      'Inferencia de IA para predecir pCTR y pCVR (< 5ms)',
      'C lculo de eCPM efectivo = Oferta   pCTR   1000'
    ],
    protocol: 'OpenRTB JSON BidRequest / BidResponse, ONNX Runtime'
  },
  {
    id: 't3',
    ms: '35 - 45 ms',
    title: 'Resoluci n de Subasta y Precios',
    engineFunction: 'Auction Resolver & Yield Optimization (03, 10)',
    summary: 'Compara ofertas directas contra program tica, aplica el piso de reserva y determina el ganador y precio de cobro.',
    substeps: [
      'Filtrado de ofertas inferiores al Dynamic Price Floor',
      'Resoluci n de 1er Precio (oferta  ntegra) o 2do Precio (Vickrey)',
      'Arbitraje entre campa as directas garantizadas y mercado abierto',
      'Generaci n del Win Notice (notificaci n de victoria al DSP)'
    ],
    protocol: 'First-Price Auction Engine, Win Notification Beacons'
  },
  {
    id: 't4',
    ms: '45 - 50 ms',
    title: 'Ensamblaje y Entrega del Creativo',
    engineFunction: 'Creative Delivery (07) y Sandbox SafeFrame',
    summary: 'Empaqueta el c digo HTML5 / VAST con los p xeles de auditor a y lo despacha al dispositivo antes de que el usuario lo note.',
    substeps: [
      'Inyecci n de p xeles criptogr ficos de tracking',
      'Aislamiento del anuncio en SafeFrame 2.0 (evita robo de datos)',
      'Despacho de activos multimedia desde la CDN perimetral',
      'Inicio de cuenta atr s de visibilidad (Est ndar MRC)'
    ],
    protocol: 'IAB SafeFrame 2.0, VAST 4.2, Anycast CDN'
  }
];

export const ArchitectureFlow: React.FC = () => {
  const [selectedStage, setSelectedStage] = useState<StageDetail>(STAGES[2]);
  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 sm:p-7">
      <div className="pb-5 border-b border-slate-800">
        <div className="flex items-center gap-2 text-xs text-amber-400 font-medium mb-1">
          <span>Ingenier a de Baja Latencia</span>
          <span aria-hidden="true"> </span>
          <span>SLA Estricto de 50 Milisegundos</span>
        </div>
        <h2 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
          Arquitectura del Ciclo de Vida de una Impresi
        </h2>
        <p className="text-xs sm:text-sm text-slate-400 mt-1 max-w-3xl">
          Un motor ad procesa millones de impresiones concurrentes. Cada solicitud pasa por 5 etapas cr ticas en menos de una vig sima de segundo (50ms). Haz clic en cada etapa para inspeccionar su anatom cnica.
        </p>
      </div>

      {/* Interactive Timeline Bar */}
      <div className="py-6">
        <div className="grid grid-cols-1 sm:grid-cols-5 gap-3">
          {STAGES.map((stage) => {
            const isSelected = selectedStage.id === stage.id;
            return (
              <button
                key={stage.id}
                onClick={() => setSelectedStage(stage)}
                className={`p-3.5 rounded-xl text-left border transition-all cursor-pointer ${
                  isSelected
                    ? 'border-amber-400 bg-amber-500/10 shadow-md ring-1 ring-amber-400/30'
                    : 'border-slate-800 bg-slate-950/60 hover:bg-slate-800/60 text-slate-400'
                }`}
              >
                <div className="flex items-center justify-between font-mono text-xs mb-1">
                  <span className={isSelected ? 'text-amber-400 font-bold' : 'text-slate-400'}>
                    {stage.ms}
                  </span>
                  <Clock className={`w-3.5 h-3.5 ${isSelected ? 'text-amber-400' : 'text-slate-600'}`} />
                </div>
                <div className="font-semibold text-xs text-white leading-tight">
                  {stage.title}
                </div>
                <div className="text-[11px] text-slate-400 mt-1 truncate">
                  {stage.engineFunction}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Detail Showcase of Selected Stage */}
      <div className="p-5 sm:p-6 bg-slate-950/80 rounded-xl border border-slate-800/80 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        <div className="lg:col-span-7">
          <div className="flex items-center gap-2 text-xs font-mono text-amber-400 mb-1">
            <span>VENTANA TEMPORAL: {selectedStage.ms}</span>
            <span aria-hidden="true"> </span>
            <span>{selectedStage.engineFunction}</span>
          </div>
          <h3 className="text-lg font-bold text-white mb-2">{selectedStage.title}</h3>
          <p className="text-xs sm:text-sm text-slate-300 leading-relaxed mb-4">
            {selectedStage.summary}
          </p>
          <div className="space-y-2">
            <span className="text-xs font-semibold text-slate-400 block">
              Operaciones At micas Realizadas por el Motor:
            </span>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
              {selectedStage.substeps.map((sub, i) => (
                <div key={i} className="flex items-start gap-2 p-2 bg-slate-900 rounded-lg text-slate-300">
                  <span className="font-mono text-amber-400 font-bold shrink-0">{i + 1}.</span>
                  <span>{sub}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
        <div className="lg:col-span-5 bg-slate-900/90 p-4 rounded-xl border border-slate-800 space-y-3 text-xs">
          <div>
            <span className="text-[11px] text-slate-400 block">Protocolos y Est ndares</span>
            <span className="font-mono text-white text-xs font-medium">{selectedStage.protocol}</span>
          </div>
          <div>
            <span className="text-[11px] text-slate-400 block">Restricci n de Latencia SLA</span>
            <span className="text-amber-400 font-mono font-semibold">Tolerancia m xima {selectedStage.ms.split(' - ')[1]}</span>
          </div>
          <div className="p-2.5 bg-slate-950 rounded-lg border border-slate-800/60 text-slate-400 text-[11px] leading-relaxed">
            <strong className="text-slate-300"> Por qu  es cr tico?</strong> Si esta etapa excede su presupuesto de tiempo, el navegador del usuario descarta la respuesta por timeout y la impresi n se pierde sin ingresos para el sitio.
          </div>
        </div>
      </div>
    </div>
  );
};
