import React, { useState } from 'react';
import { Copy, Check, Link, Zap, Wifi, WifiOff, AlertTriangle } from 'lucide-react';
import { apiFetch } from '../services/api';

const STATUS_CONFIG = {
  IDLE: { icon: Link, color: 'text-slate-500', label: 'Esperando validación' },
  VALIDATING: { icon: Zap, color: 'text-amber-400 animate-pulse', label: 'Comprobando etiqueta...' },
  PENDING: { icon: Zap, color: 'text-cyan-400', label: 'Etiqueta pendiente de comprobar' },
  VERIFIED: { icon: Wifi, color: 'text-emerald-400', label: 'Dominio verificado' },
  FAILED: { icon: WifiOff, color: 'text-rose-500', label: 'Etiqueta no detectada' },
  ERROR: { icon: AlertTriangle, color: 'text-rose-500', label: 'Error de Red' },
};

type ValidationStatus = keyof typeof STATUS_CONFIG;
type Proof = {
  domain: string;
  siteUrl: string;
  status: 'PENDING' | 'VERIFIED' | 'FAILED';
  snippet: string;
  verifiedAtUtc: string | null;
  lastCheckedAtUtc: string | null;
  message: string | null;
};

async function readApiResponse<T>(response: Response): Promise<T> {
  const body = await response.text();
  let data: ({ message?: string } & T) | {};
  try {
    data = body ? JSON.parse(body) : {};
  } catch {
    throw new Error(`El servidor devolvió una respuesta no válida (HTTP ${response.status}).`);
  }
  if (!response.ok) {
    throw new Error(('message' in data && data.message) || `La solicitud falló (HTTP ${response.status}).`);
  }
  return data as T;
}

export const EmbedCodeGeneratorValidator: React.FC = () => {
  const [targetUrl, setTargetUrl] = useState('https://www.laboratoriosanfrancisco.com');
  const [validationStatus, setValidationStatus] = useState<ValidationStatus>('IDLE');
  const [validationMessage, setValidationMessage] = useState('');
  const [isCopied, setIsCopied] = useState(false);
  const [proof, setProof] = useState<Proof | null>(null);

  const handleCopy = async () => {
    if (!proof) return;
    try {
      await navigator.clipboard.writeText(proof.snippet);
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    } catch {
      setValidationStatus('ERROR');
      setValidationMessage('No se pudo copiar. Selecciona y copia la etiqueta manualmente.');
    }
  };

  const handleValidate = async (verify: boolean) => {
    setValidationStatus('VALIDATING');
    setValidationMessage('');
    try {
      const res = await apiFetch(`/api/SiteVerifications${verify ? '/verify' : ''}`, {
        method: 'POST',
        body: JSON.stringify({ targetUrl }),
      });
      const data = await readApiResponse<Proof>(res);
      setProof(data);
      setValidationStatus(data.status);
      setValidationMessage(data.message || '');
    } catch (error) {
      setValidationStatus('ERROR');
      setValidationMessage(error instanceof Error ? error.message : 'Error de red.');
    }
  };

  const CurrentStatusIcon = STATUS_CONFIG[validationStatus].icon;

  return (
    <section className="as-card-premium rounded-2xl p-6 space-y-4">
      <div>
        <h3 className="text-base font-bold text-white">Generador de Tag First-Party y Validador de Conexión</h3>
        <p className="text-xs text-slate-400">
          Genera una etiqueta meta de verificación y comprueba que esté publicada en el dominio.
        </p>
      </div>

      <div>
        <label htmlFor="embed-validation-url" className="text-xs font-semibold text-slate-400">URL del sitio promocionado</label>
        <input
          id="embed-validation-url"
          type="url"
          value={targetUrl}
          onChange={(e) => { setTargetUrl(e.target.value); setProof(null); setValidationStatus('IDLE'); setValidationMessage(''); }}
          placeholder="https://www.cliente.com"
          className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
        />
      </div>

      <div className="bg-[#070B12] p-4 rounded-xl border border-slate-800 space-y-3">
        <div className="flex justify-between items-center">
          <p className="text-xs font-bold text-slate-300">Etiqueta que se coloca dentro de &lt;head&gt;</p>
          <button
            type="button"
            onClick={handleCopy}
            disabled={!proof}
            className="px-3 py-1.5 rounded-lg bg-slate-700 hover:bg-slate-600 text-xs font-bold text-white flex items-center gap-1.5"
          >
            {isCopied ? <Check className="h-4 w-4 text-emerald-400" /> : <Copy className="h-4 w-4" />}
            {isCopied ? 'Copiado' : 'Copiar'}
          </button>
        </div>
        <pre className="bg-black/40 p-3 rounded-lg text-cyan-400 text-[11px] font-mono overflow-x-auto">
          <code>{proof?.snippet || 'Genera la etiqueta para este dominio.'}</code>
        </pre>
        {proof && <p className="text-[11px] text-slate-400">Dominio exacto: {proof.domain}</p>}
      </div>

      <div className="flex items-center gap-4 pt-3 border-t border-slate-800">
        <button
          type="button"
          onClick={() => handleValidate(false)}
          disabled={validationStatus === 'VALIDATING' || !targetUrl.trim()}
          className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold flex items-center gap-2 disabled:opacity-50"
        >
          <Zap className="h-4 w-4" />
          {proof ? 'Obtener etiqueta' : 'Generar etiqueta'}
        </button>
        {proof && (
          <button
            type="button"
            onClick={() => handleValidate(true)}
            disabled={validationStatus === 'VALIDATING'}
            className="px-4 py-2.5 rounded-xl border border-slate-600 text-slate-200 text-xs font-bold disabled:opacity-50"
          >
            {validationStatus === 'VALIDATING' ? 'Comprobando…' : 'Verificar etiqueta'}
          </button>
        )}
        <div className="flex items-center gap-2">
          <CurrentStatusIcon className={`h-5 w-5 ${STATUS_CONFIG[validationStatus].color}`} />
          <div>
            <p className={`text-xs font-bold ${STATUS_CONFIG[validationStatus].color}`}>
              {STATUS_CONFIG[validationStatus].label}
            </p>
            {validationMessage && (
              <p className="text-[11px] text-slate-400">{validationMessage}</p>
            )}
          </div>
        </div>
      </div>
      <p className="text-[11px] text-slate-500">
        Coloca exactamente esta etiqueta en el &lt;head&gt; del sitio y pulsa “Verificar etiqueta”. La verificación es inmediata; no requiere script ni handshake.
      </p>
    </section>
  );
};