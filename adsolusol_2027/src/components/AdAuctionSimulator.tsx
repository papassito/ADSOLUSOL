import React, { useState } from 'react';
import { Play, RotateCcw, CheckCircle2, XCircle, Zap, ShieldCheck, Eye, DollarSign } from 'lucide-react';
import { MOCK_BIDDERS } from '../data/adEngineData';

export const AdAuctionSimulator: React.FC = () => {
  const [auctionType, setAuctionType] = useState<'first_price' | 'second_price'>('first_price');
  const [priceFloor, setPriceFloor] = useState<number>(2.50);
  const [country, setCountry] = useState<string>('MEX');
  const [device, setDevice] = useState<'mobile' | 'desktop' | 'ctv'>('mobile');
  const [isFreqCapped, setIsFreqCapped] = useState<boolean>(false);
  const [isPacingThrottled, setIsPacingThrottled] = useState<boolean>(false);
  const [isRunning, setIsRunning] = useState<boolean>(false);
  const [currentStep, setCurrentStep] = useState<number>(0);
  const [simulationLog, setSimulationLog] = useState<string[]>([]);
  const [auctionResult, setAuctionResult] = useState<any>(null);
  const [viewabilityTriggered, setViewabilityTriggered] = useState<boolean>(false);

  const runSimulation = () => {
    setIsRunning(true);
    setCurrentStep(1);
    setViewabilityTriggered(false);
    setAuctionResult(null);
    setSimulationLog([`[0ms] HTTP Ad Request recibido: Pa s=${country}, Dispositivo=${device}`]);

    // Step 1: Ingestion & Privacy (5ms)
    setTimeout(() => {
      setCurrentStep(2);
      setSimulationLog(prev => [
        ...prev,
        `[4ms] Parsing de se ales de consentimiento (TCF v2.2 OK), PPID resuelto.`
      ]);
    }, 400);

    // Step 2: Targeting & Frequency (15ms)
    setTimeout(() => {
      setCurrentStep(3);
      if (isFreqCapped) {
        setSimulationLog(prev => [
          ...prev,
          `[12ms] ALERTA: L mite de frecuencia (Frequency Cap 3/24h) alcanzado para este usuario. Solicitud descartada.`
        ]);
        setIsRunning(false);
        setAuctionResult({
          error: 'Frecuencia superada',
          message: 'El usuario ya ha visto 3 impresiones hoy. El motor protege al usuario de fatiga publicitaria.'
        });
        return;
      }
      setSimulationLog(prev => [
        ...prev,
        `[15ms] Targeting evaluado: 4 DSPs candidatos elegibles. Verificando Pacing y Presupuestos.`
      ]);
    }, 900);

    // Step 3: RTB Auction & ML eCPM calculation (35ms)
    setTimeout(() => {
      if (isFreqCapped) return;
      setCurrentStep(4);
      // Evaluate bidders
      const bidders = Object.values(MOCK_BIDDERS).map(b => {
        // Calculate eCPM = Bid * pCTR * 1000
        const effectiveEcpm = Number((b.bid * b.pCTR * 1000).toFixed(2));
        const meetsFloor = b.bid >= priceFloor;
        const pacingFactor = isPacingThrottled ? (b.dsp === 'DV360' ? 0.3 : 1.0) : 1.0;
        const eligible = meetsFloor && (pacingFactor > 0.5 || Math.random() > 0.3);
        return {
          ...b,
          effectiveEcpm,
          meetsFloor,
          eligible,
          rejectionReason: !meetsFloor ? `Por debajo del piso de reserva ($${priceFloor.toFixed(2)})` : undefined
        };
      });
      const eligibleBidders = bidders.filter(b => b.eligible).sort((a, b) => b.bid - a.bid);
      if (eligibleBidders.length === 0) {
        setSimulationLog(prev => [
          ...prev,
          `[32ms] Ning n comprador super  el piso de reserva ($${priceFloor.toFixed(2)}). Subasta desierta (Unsold / Fill Rate 0%).`
        ]);
        setIsRunning(false);
        setAuctionResult({
          error: 'Subasta Desierta',
          message: 'Todas las ofertas estuvieron por debajo del Floor Price establecido por el editor.'
        });
        return;
      }
      const winner = eligibleBidders[0];
      const secondBid = eligibleBidders[1] ? eligibleBidders[1].bid : priceFloor;
      const clearingPrice = auctionType === 'first_price' ? winner.bid : Number((secondBid + 0.01).toFixed(2));
      setSimulationLog(prev => [
        ...prev,
        `[38ms] Subasta resuelta (${auctionType === 'first_price' ? '1er Precio' : '2do Precio Vickrey'}). Ganador: ${winner.advertiser} a $${clearingPrice.toFixed(2)} CPM.`
      ]);

      // Step 4: Creative Delivery & Rendering (48ms)
      setTimeout(() => {
        setCurrentStep(5);
        setSimulationLog(prev => [
          ...prev,
          `[46ms] Creative Payload entregado por CDN (<10ms). Renderizando SafeFrame.`
        ]);
        setAuctionResult({
          winner,
          clearingPrice,
          allBidders: bidders,
          secondBid
        });
        setIsRunning(false);
        // Simulate MRC Viewability test (1000ms delay)
        setTimeout(() => {
          setViewabilityTriggered(true);
          setSimulationLog(prev => [
            ...prev,
            `[+1000ms] Verificaci n MRC cumplida: 50% de p xeles visible por 1.0s. Disparado beacon 'viewable_impression'!`
          ]);
        }, 1200);
      }, 500);
    }, 1500);
  };

  const resetSimulation = () => {
    setIsRunning(false);
    setCurrentStep(0);
    setSimulationLog([]);
    setAuctionResult(null);
    setViewabilityTriggered(false);
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 sm:p-7">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-6 border-b border-slate-800">
        <div>
          <div className="flex items-center gap-2 text-xs text-amber-400 font-medium mb-1">
            <span>Simulador de Entorno Real</span>
            <span aria-hidden="true"> </span>
            <span>Ciclo de Vida de 50 Milisegundos</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-bold text-white tracking-tight">
            Simulador de Subasta RTB y Entrega de Anuncios
          </h2>
          <p className="text-xs sm:text-sm text-slate-400 mt-1">
            Experimenta en vivo c mo el motor recibe la solicitud, filtra candidatos, ejecuta la subasta de 1er vs 2do precio y verifica la visibilidad MRC.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={runSimulation}
            disabled={isRunning}
            className={`px-4 py-2.5 rounded-lg text-xs font-semibold flex items-center gap-2 transition-all cursor-pointer ${
              isRunning
                ? 'bg-slate-800 text-slate-500 cursor-not-allowed'
                : 'bg-amber-400 hover:bg-amber-300 text-slate-950 shadow-md active:scale-98'
            }`}
          >
            <Play className="w-3.5 h-3.5 fill-current" />
            {isRunning ? 'Subastando...' : 'Ejecutar Subasta (<50ms)'}
          </button>
          <button
            onClick={resetSimulation}
            disabled={isRunning}
            className="p-2.5 rounded-lg text-slate-400 hover:text-white bg-slate-800 hover:bg-slate-700 transition-colors cursor-pointer"
            title="Reiniciar simulador"
          >
            <RotateCcw className="w-4 h-4" />
          </button>
        </div>
      </div>
      {/* Control Configuration Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 py-5 border-b border-slate-800 text-xs">
        {/* Param 1: Auction Mode */}
        <div className="bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/80">
          <label className="text-slate-300 font-medium block mb-2">
            Tipo de Subasta
          </label>
          <div className="grid grid-cols-2 gap-1.5 p-1 bg-slate-900 rounded-lg">
            <button
              onClick={() => setAuctionType('first_price')}
              className={`py-1.5 px-2 rounded-md font-medium text-center transition-all cursor-pointer ${
                auctionType === 'first_price'
                  ? 'bg-amber-400 text-slate-950 font-semibold'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              1er Precio (Actual)
            </button>
            <button
              onClick={() => setAuctionType('second_price')}
              className={`py-1.5 px-2 rounded-md font-medium text-center transition-all cursor-pointer ${
                auctionType === 'second_price'
                  ? 'bg-amber-400 text-slate-950 font-semibold'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              2do Precio (Vickrey)
            </button>
          </div>
          <span className="text-[11px] text-slate-500 block mt-2">
            {auctionType === 'first_price'
              ? 'El ganador paga su oferta completa (est ndar OpenRTB actual).'
              : 'El ganador paga la 2  oferta + $0.01 centavo.'}
          </span>
        </div>
        {/* Param 2: Price Floor */}
        <div className="bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/80">
          <div className="flex justify-between items-center mb-2">
            <label className="text-slate-300 font-medium">Piso de Reserva (Floor)</label>
            <span className="font-mono font-semibold text-amber-400 tabular-nums">
              ${priceFloor.toFixed(2)} CPM
            </span>
          </div>
          <input
            type="range"
            min="1.0"
            max="6.0"
            step="0.25"
            value={priceFloor}
            onChange={(e) => setPriceFloor(parseFloat(e.target.value))}
            className="w-full accent-amber-400 cursor-pointer"
          />
          <span className="text-[11px] text-slate-500 block mt-2">
            Ofertas por debajo de este monto son descartadas autom ticamente.
          </span>
        </div>
        {/* Param 3: Context / Device */}
        <div className="bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/80">
          <label className="text-slate-300 font-medium block mb-2">
            Dispositivo & Regi
          </label>
          <div className="flex gap-2">
            <select
              value={country}
              onChange={(e) => setCountry(e.target.value)}
              className="bg-slate-900 border border-slate-700 text-white rounded-md px-2 py-1.5 text-xs flex-1 cursor-pointer focus:outline-none focus:border-amber-400"
            >
              <option value="MEX">M xico (MEX)</option>
              <option value="ESP">Espa a (ESP)</option>
              <option value="COL">Colombia (COL)</option>
              <option value="USA">EE. UU. (USA)</option>
            </select>
            <select
              value={device}
              onChange={(e) => setDevice(e.target.value as any)}
              className="bg-slate-900 border border-slate-700 text-white rounded-md px-2 py-1.5 text-xs flex-1 cursor-pointer focus:outline-none focus:border-amber-400"
            >
              <option value="mobile">M vil (iOS/Android)</option>
              <option value="desktop">Escritorio (Web)</option>
              <option value="ctv">Smart TV (CTV)</option>
            </select>
          </div>
          <span className="text-[11px] text-slate-500 block mt-2">
            Par metros inyectados en la cabecera OpenRTB.
          </span>
        </div>
        {/* Param 4: Guards (Frequency Cap & Pacing) */}
        <div className="bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/80">
          <label className="text-slate-300 font-medium block mb-2">
            Restricciones de Campa
          </label>
          <div className="space-y-1.5">
            <label className="flex items-center gap-2 cursor-pointer text-slate-300 hover:text-white">
              <input
                type="checkbox"
                checked={isFreqCapped}
                onChange={(e) => setIsFreqCapped(e.target.checked)}
                className="rounded accent-amber-400 cursor-pointer"
              />
              <span>Simular Cap de Frecuencia superado</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer text-slate-300 hover:text-white">
              <input
                type="checkbox"
                checked={isPacingThrottled}
                onChange={(e) => setIsPacingThrottled(e.target.checked)}
                className="rounded accent-amber-400 cursor-pointer"
              />
              <span>Simular Freno de Pacing (Presupuesto)</span>
            </label>
          </div>
          <span className="text-[11px] text-slate-500 block mt-1">
            Prueba c mo reacciona el motor ante l mites operativos.
          </span>
        </div>
      </div>
      {/* Real-time Progress Pipeline */}
      <div className="py-5 border-b border-slate-800">
        <div className="text-xs font-semibold text-slate-400 mb-3 flex items-center justify-between">
          <span>PIPELINE DE EJECUCI N DEL MOTOR (<span className="text-amber-400 font-mono">LATENCIA &lt; 50ms</span>)</span>
          {currentStep > 0 && (
            <span className="text-amber-400 font-mono text-[11px]">
              Fase {currentStep} de 5 activa
            </span>
          )}
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-2 text-xs">
          {[
            { step: 1, label: '01. Ingesta HTTP', time: '< 4ms', desc: 'Parsing & Privacy' },
            { step: 2, label: '02. Filtro & Cap', time: '< 12ms', desc: 'Targeting & Freq' },
            { step: 3, label: '03. ML & RTB', time: '< 30ms', desc: 'Bidding & pCTR' },
            { step: 4, label: '04. Subasta', time: '< 42ms', desc: 'Pricing Resolver' },
            { step: 5, label: '05. Entrega CDN', time: '< 50ms', desc: 'SafeFrame & VAST' },
          ].map((item) => {
            const isActive = currentStep === item.step;
            const isCompleted = currentStep > item.step;
            return (
              <div
                key={item.step}
                className={`p-3 rounded-xl border transition-all ${
                  isActive
                    ? 'border-amber-400 bg-amber-500/10 text-white shadow-sm'
                    : isCompleted
                    ? 'border-emerald-500/30 bg-emerald-950/20 text-slate-300'
                    : 'border-slate-800 bg-slate-950/40 text-slate-500'
                }`}
              >
                <div className="flex items-center justify-between font-mono text-[11px] mb-1">
                  <span className={isActive ? 'text-amber-400 font-semibold' : isCompleted ? 'text-emerald-400' : ''}>
                    {item.time}
                  </span>
                  {isCompleted && <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />}
                </div>
                <div className="font-semibold text-xs">{item.label}</div>
                <div className="text-[11px] text-slate-400 mt-0.5">{item.desc}</div>
              </div>
            );
          })}
        </div>
      </div>
      {/* Simulation Results & Visualization */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-5">
        {/* Left column: Live log (Terminal-style) */}
        <div className="lg:col-span-5 bg-slate-950 rounded-xl p-4 border border-slate-800/80 font-mono text-xs text-slate-300 flex flex-col h-72 overflow-y-auto">
          <div className="text-slate-500 text-[11px] pb-2 border-b border-slate-900 flex items-center justify-between shrink-0">
            <span>REGISTRO DE EVENTOS DEL MOTOR</span>
            <span>UTF-8</span>
          </div>
          <div className="space-y-1.5 pt-2 flex-1">
            {simulationLog.length === 0 ? (
              <p className="text-slate-600 italic">
                Presiona "Ejecutar Subasta" para ver el flujo de decisiones del motor en tiempo real...
              </p>
            ) : (
              simulationLog.map((log, idx) => (
                <div
                  key={idx}
                  className={`text-[11px] leading-relaxed ${
                    log.includes('ALERTA') || log.includes('descartada')
                      ? 'text-rose-400 font-semibold'
                      : log.includes('Ganador')
                      ? 'text-amber-400 font-semibold'
                      : log.includes('MRC')
                      ? 'text-emerald-400 font-semibold'
                      : 'text-slate-300'
                  }`}
                >
                  {log}
                </div>
              ))
            )}
          </div>
        </div>
        {/* Right column: Auction Outcome Card */}
        <div className="lg:col-span-7 bg-slate-950/60 rounded-xl p-4 sm:p-5 border border-slate-800/80 flex flex-col justify-between">
          {!auctionResult ? (
            <div className="h-full flex flex-col items-center justify-center text-center p-6 text-slate-500">
              <Zap className="w-10 h-10 text-slate-700 mb-3" />
              <p className="text-sm font-medium text-slate-400">Sin subasta activa</p>
              <p className="text-xs text-slate-600 mt-1 max-w-sm">
                Configura los par metros arriba y haz clic en "Ejecutar Subasta" para ver el c lculo de eCPM y el ganador.
              </p>
            </div>
          ) : auctionResult.error ? (
            <div className="h-full flex flex-col items-center justify-center text-center p-6">
              <XCircle className="w-10 h-10 text-rose-400 mb-3" />
              <h4 className="text-base font-bold text-white">{auctionResult.error}</h4>
              <p className="text-xs text-slate-400 mt-2 max-w-md">
                {auctionResult.message}
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {/* Winner Header */}
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 p-3.5 bg-amber-500/10 border border-amber-500/30 rounded-xl">
                <div>
                  <div className="text-[11px] text-amber-400 font-mono font-medium">ANUNCIO GANADOR DE LA SUBASTA</div>
                  <h3 className="text-base font-bold text-white mt-0.5">{auctionResult.winner.advertiser}</h3>
                  <div className="text-xs text-slate-400">
                    <span>{auctionResult.winner.name}</span>
                    <span className="mx-1.5" aria-hidden="true"> </span>
                    <span>Categor a: {auctionResult.winner.brandCategory}</span>
                  </div>
                </div>
                <div className="text-right sm:text-right">
                  <div className="text-[11px] text-slate-400">Precio de Liquidaci n</div>
                  <div className="text-xl font-bold font-mono text-amber-400 tabular-nums">
                    ${auctionResult.clearingPrice.toFixed(2)} <span className="text-xs font-normal text-slate-400">CPM</span>
                  </div>
                  <div className="text-[10px] text-slate-400">
                    {auctionType === 'first_price' ? '1er Precio (Oferta original)' : `2do Precio ($${auctionResult.secondBid.toFixed(2)} + $0.01)`}
                  </div>
                </div>
              </div>
              {/* Bidders Table Comparison */}
              <div>
                <div className="text-xs font-semibold text-slate-400 mb-2">
                  TABLA DE OFERTAS EVALUADAS POR EL MOTOR
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="text-slate-500 border-b border-slate-800">
                        <th className="pb-2 font-medium">Plataforma (DSP)</th>
                        <th className="pb-2 font-medium">Oferta CPM</th>
                        <th className="pb-2 font-medium">pCTR Estimado</th>
                        <th className="pb-2 font-medium">eCPM Efectivo</th>
                        <th className="pb-2 font-medium">Estado</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/60 font-mono">
                      {auctionResult.allBidders.map((b: any) => {
                        const isWon = b.name === auctionResult.winner.name;
                        return (
                          <tr key={b.name} className={isWon ? 'bg-amber-500/5 text-amber-300' : 'text-slate-400'}>
                            <td className="py-2 font-sans font-medium text-slate-200">{b.dsp}</td>
                            <td className="py-2 tabular-nums">${b.bid.toFixed(2)}</td>
                            <td className="py-2 tabular-nums">{(b.pCTR * 100).toFixed(2)}%</td>
                            <td className="py-2 font-semibold tabular-nums text-white">${b.effectiveEcpm.toFixed(2)}</td>
                            <td className="py-2 font-sans">
                              {isWon ? (
                                <span className="text-amber-400 font-semibold flex items-center gap-1">
                                  <CheckCircle2 className="w-3.5 h-3.5" /> Ganador
                                </span>
                              ) : b.rejectionReason ? (
                                <span className="text-rose-400 text-[11px]">{b.rejectionReason}</span>
                              ) : (
                                <span className="text-slate-500 text-[11px]">Superado</span>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
              {/* MRC Viewability Verification Box */}
              <div className="p-3 bg-slate-900 rounded-xl border border-slate-800 flex items-center justify-between text-xs">
                <div className="flex items-center gap-2.5">
                  <Eye className="w-4 h-4 text-slate-400" />
                  <div>
                    <span className="font-semibold text-white block">Auditor a de Visibilidad MRC</span>
                    <span className="text-[11px] text-slate-400">
                      Regla: 50% de p xeles visible por 1.0s continuo
                    </span>
                  </div>
                </div>
                {viewabilityTriggered ? (
                  <div className="flex items-center gap-1.5 text-emerald-400 font-semibold font-mono text-xs">
                    <ShieldCheck className="w-4 h-4" />
                    <span>VERIFICADO MRC (Cobro Habilitado)</span>
                  </div>
                ) : (
                  <div className="text-slate-500 text-xs flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-amber-400 animate-ping" />
                    <span>Comprobando visibilidad (1.0s)...</span>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
