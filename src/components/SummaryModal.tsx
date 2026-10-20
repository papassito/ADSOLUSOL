import React, { useState } from 'react';
import { X, Copy, Check, FileText } from 'lucide-react';
import { AD_ENGINE_FUNCTIONS } from '../data/adEngineData';
import { ACTIVE_DIRECTORY_FUNCTIONS } from '../data/activeDirectoryData';
import { DIRECT_DRIVE_FUNCTIONS } from '../data/directDriveData';

interface SummaryModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const SummaryModal: React.FC<SummaryModalProps> = ({ isOpen, onClose }) => {
  const [copied, setCopied] = useState<boolean>(false);
  if (!isOpen) return null;

  const generateMarkdownSummary = () => {
    let md = `# RESUMEN COMPLETO: FUNCIONES DE UN MOTOR AD\n\n`;
    md += `El t rmino "Motor AD" abarca principalmente 3  mbitos tecnol gicos:\n\n`;
    md += `## 1. MOTOR DE PUBLICIDAD DIGITAL (AD TECH SERVER & BIDDING ENGINE)\n`;
    md += `Es el software central que subasta, selecciona y entrega anuncios en < 50ms.\n\n`;
    AD_ENGINE_FUNCTIONS.forEach((fn) => {
      md += `### ${fn.number}. ${fn.name}\n`;
      md += `- Categor a: ${fn.categoryLabel} | Latencia: ${fn.latencyImpact}\n`;
      md += `- Descripci n: ${fn.shortDescription}\n`;
      md += `- Capacidades: ${fn.keyCapabilities.join('; ')}\n`;
      md += `- Est ndares/Protocolos: ${fn.technicalSpecs.protocolOrStandard}\n\n`;
    });
    md += `## 2. MOTOR DE ACTIVE DIRECTORY (MICROSOFT AD IT)\n`;
    md += `Servicio transaccional de autenticaci n e identidades corporativas en Windows Server.\n\n`;
    ACTIVE_DIRECTORY_FUNCTIONS.forEach((fn) => {
      md += `### ${fn.number}. ${fn.title}\n`;
      md += `- Componente: ${fn.component} | Protocolo: ${fn.protocolOrCore}\n`;
      md += `- Funci n: ${fn.summary}\n\n`;
    });
    md += `## 3. MOTOR DE ACCIONAMIENTO DIRECTO (DIRECT DRIVE ELECTROMEC NICO)\n`;
    md += `Motor de transmisi n directa sin engranajes reductores ni holguras (Zero Backlash).\n\n`;
    DIRECT_DRIVE_FUNCTIONS.forEach((fn) => {
      md += `### ${fn.number}. ${fn.title}\n`;
      md += `- Principio: ${fn.principle}\n`;
      md += `- Resumen: ${fn.summary}\n\n`;
    });
    return md;
  };

  const copyToClipboard = () => {
    navigator.clipboard.writeText(generateMarkdownSummary());
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-4xl max-h-[90vh] flex flex-col shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <FileText className="w-5 h-5 text-amber-400" />
            <div>
              <h3 className="text-lg font-bold text-white">Resumen Ejecutivo de Funciones del Motor AD</h3>
              <p className="text-xs text-slate-400">Documento t cnico estructurado para consulta o exportaci n</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        {/* Content */}
        <div className="p-6 overflow-y-auto space-y-6 flex-1 text-xs font-mono bg-slate-950/70 text-slate-300">
          <div className="p-4 bg-slate-900 rounded-xl border border-slate-800 text-xs">
            <h4 className="text-amber-400 font-bold text-sm mb-2 font-sans">
              1. Las 10 Funciones del Motor de Publicidad Digital (Ad Engine):
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-slate-300">
              {AD_ENGINE_FUNCTIONS.map((f) => (
                <div key={f.id} className="p-2.5 bg-slate-950 rounded-lg border border-slate-800/60">
                  <span className="text-amber-400 font-bold block">{f.number}. {f.name}</span>
                  <span className="text-[11px] text-slate-400 font-sans block mt-1">{f.shortDescription}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="p-4 bg-slate-900 rounded-xl border border-slate-800 text-xs">
            <h4 className="text-amber-400 font-bold text-sm mb-2 font-sans">
              2. Las 6 Funciones del Motor Active Directory (Microsoft AD):
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-slate-300">
              {ACTIVE_DIRECTORY_FUNCTIONS.map((f) => (
                <div key={f.id} className="p-2.5 bg-slate-950 rounded-lg border border-slate-800/60">
                  <span className="text-amber-400 font-bold block">{f.number}. {f.title}</span>
                  <span className="text-[11px] text-slate-400 font-sans block mt-1">{f.summary}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="p-4 bg-slate-900 rounded-xl border border-slate-800 text-xs">
            <h4 className="text-amber-400 font-bold text-sm mb-2 font-sans">
              3. Las 3 Funciones del Motor de Accionamiento Directo (Direct Drive):
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-slate-300">
              {DIRECT_DRIVE_FUNCTIONS.map((f) => (
                <div key={f.id} className="p-2.5 bg-slate-950 rounded-lg border border-slate-800/60">
                  <span className="text-amber-400 font-bold block">{f.number}. {f.title}</span>
                  <span className="text-[11px] text-slate-400 font-sans block mt-1">{f.summary}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
        {/* Footer */}
        <div className="p-4 border-t border-slate-800 bg-slate-950 flex items-center justify-between">
          <span className="text-xs text-slate-500">
            Formato Markdown listo para copiar al portapapeles.
          </span>
          <div className="flex gap-2">
            <button
              onClick={copyToClipboard}
              className="px-4 py-2 bg-amber-400 hover:bg-amber-300 active:scale-98 text-slate-950 font-semibold rounded-lg text-xs flex items-center gap-1.5 cursor-pointer shadow-sm transition-all"
            >
              {copied ? (
                <>
                  <Check className="w-4 h-4 text-emerald-900" />
                  <span> Copiado con  xito!</span>
                </>
              ) : (
                <>
                  <Copy className="w-4 h-4" />
                  <span>Copiar Todo el Resumen</span>
                </>
              )}
            </button>
            <button
              onClick={onClose}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg text-xs font-semibold cursor-pointer transition-colors"
            >
              Cerrar
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
