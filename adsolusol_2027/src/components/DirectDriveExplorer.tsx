import React, { useState } from 'react';
import { DIRECT_DRIVE_FUNCTIONS } from '../data/directDriveData';
import { Cpu, Zap, Activity, ShieldCheck, CheckCircle2 } from 'lucide-react';

export const DirectDriveExplorer: React.FC = () => {
  const [rpm, setRpm] = useState<number>(33);
  const [poles, setPoles] = useState<number>(16);

  // Electrical Frequency f = (Poles * RPM) / 120
  const electricalFreq = ((poles * rpm) / 120).toFixed(1);

  return (
    <div className="space-y-8">
      {/* Overview Card */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 sm:p-8">
        <div className="max-w-3xl">
          <div className="flex items-center gap-2 text-xs text-amber-400 font-medium mb-1">
            <span>Electromec nica & Rob tica</span>
            <span aria-hidden="true"> </span>
            <span>Accionamiento Directo (Direct Drive)</span>
          </div>
          <h2 className="text-xl sm:text-2xl lg:text-3xl font-bold text-white tracking-tight">
            Motor de Accionamiento Directo (AD / Direct Drive)
          </h2>
          <p className="mt-2 text-xs sm:text-sm text-slate-300 leading-relaxed">
            En f sica y mecatr nica, un <strong>Motor AD</strong> hace referencia a un motor de <em>Accionamiento Directo (Direct Drive)</em>. A diferencia de los motores convencionales que dependen de engranajes reductores o correas para ganar fuerza, el motor AD acopla la carga  til directamente sobre el rotor magn tico multipolo, erradicando holguras mec nicas y p rdidas por fricci 
          </p>
        </div>
      </div>

      {/* Interactive Physics Model */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 sm:p-7">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-5 border-b border-slate-800">
          <div>
            <div className="flex items-center gap-2 text-xs text-amber-400 font-mono font-medium mb-1">
              <span>C LCULO VECTORIAL PMSM / BLDC</span>
              <span aria-hidden="true"> </span>
              <span>PAR MOTOR & FRECUENCIA</span>
            </div>
            <h3 className="text-lg sm:text-xl font-bold text-white">
              Simulador Electromagn tico de Accionamiento Directo
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Ajusta las RPM y el n mero de polos magn ticos para ver la frecuencia el ctrica y el par nominal resultante.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-5">
          <div className="space-y-4 text-xs">
            <div className="p-4 bg-slate-950 rounded-xl border border-slate-800">
              <div className="flex justify-between items-center mb-2">
                <span className="text-slate-300 font-medium">Velocidad de Giro (RPM)</span>
                <span className="font-mono text-amber-400 font-bold text-sm">{rpm} RPM</span>
              </div>
              <input
                type="range"
                min="5"
                max="300"
                value={rpm}
                onChange={(e) => setRpm(parseInt(e.target.value))}
                className="w-full accent-amber-400 cursor-pointer"
              />
              <div className="flex justify-between text-[11px] text-slate-500 mt-1">
                <span>5 RPM (Tornamesa / SimRacing)</span>
                <span>300 RPM (Lavadora / Aerogenerador)</span>
              </div>
            </div>
            <div className="p-4 bg-slate-950 rounded-xl border border-slate-800">
              <div className="flex justify-between items-center mb-2">
                <span className="text-slate-300 font-medium">N mero de Polos Magn ticos (P)</span>
                <span className="font-mono text-amber-400 font-bold text-sm">{poles} Polos</span>
              </div>
              <input
                type="range"
                min="4"
                max="48"
                step="2"
                value={poles}
                onChange={(e) => setPoles(parseInt(e.target.value))}
                className="w-full accent-amber-400 cursor-pointer"
              />
              <span className="text-[11px] text-slate-500 block mt-1">
                A mayor n mero de polos magn ticos en el estator, mayor densidad de par a baja velocidad sin reductores.
              </span>
            </div>
          </div>

          <div className="bg-slate-950 rounded-xl p-5 border border-slate-800 flex flex-col justify-between">
            <div>
              <span className="text-xs font-mono text-slate-400 block mb-1">C LCULO EN TIEMPO REAL:</span>
              <div className="font-mono text-xs text-slate-400 mb-3">f_el ctrica = (Polos   RPM) / 120</div>
              
              <div className="grid grid-cols-2 gap-3 text-xs">
                <div className="p-3 bg-slate-900 rounded-lg border border-slate-800">
                  <span className="text-[11px] text-slate-400 block">Frecuencia Inversor FOC</span>
                  <span className="font-mono text-xl font-bold text-amber-400">{electricalFreq} Hz</span>
                </div>
                <div className="p-3 bg-slate-900 rounded-lg border border-slate-800">
                  <span className="text-[11px] text-slate-400 block">Holgura Mec nica</span>
                  <span className="font-mono text-xl font-bold text-emerald-400">0.00 mm</span>
                  <span className="text-[10px] text-slate-500 block">Cero Backlash</span>
                </div>
              </div>
            </div>
            <div className="mt-4 p-3 bg-slate-900/60 rounded-lg border border-slate-800 text-[11px] text-slate-300">
              <strong className="text-amber-400">Ventaja T cnica Fundamental:</strong> Al no tener engranajes que rocen ni correas que se estiren, la respuesta es instant nea (latencia en par inferior a 1 milisegundo) y la eficiencia energ tica supera el 95%.
            </div>
          </div>
        </div>
      </div>

      {/* 3 Core Functions */}
      <div className="space-y-4">
        <h3 className="text-lg sm:text-xl font-bold text-white tracking-tight">
          Funciones y Principios de un Motor de Accionamiento Directo
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {DIRECT_DRIVE_FUNCTIONS.map((fn) => (
            <div
              key={fn.id}
              className="bg-slate-900 border border-slate-800 rounded-xl p-5 flex flex-col justify-between"
            >
              <div>
                <span className="font-mono text-lg font-bold text-amber-400 block mb-1">
                  {fn.number}.
                </span>
                <h4 className="text-base font-bold text-white mb-2">{fn.title}</h4>
                <p className="text-xs text-slate-300 leading-relaxed mb-4">
                  {fn.summary}
                </p>
                <div className="space-y-2 text-xs mb-4">
                  <span className="text-[11px] font-semibold text-slate-400 block">
                    Aplicaciones T picas:
                  </span>
                  <ul className="space-y-1 text-slate-300">
                    {fn.applications.map((app, i) => (
                      <li key={i} className="flex items-start gap-1.5">
                        <span className="text-amber-400"> </span>
                        <span>{app}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
              <div className="bg-slate-950/70 p-3 rounded-lg border border-slate-800/80 text-xs">
                <span className="text-[11px] font-semibold text-emerald-400 block mb-1">
                  Ventajas Clave:
                </span>
                <div className="text-slate-300 text-[11px] space-y-0.5">
                  {fn.advantages.map((adv, j) => (
                    <div key={j}>  {adv}</div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
