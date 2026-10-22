import React, { useState } from 'react';
import { Copy, Check, Link, Zap, Wifi, WifiOff, AlertTriangle } from 'lucide-react';
import { apiFetch } from '../services/api';

const STATUS_CONFIG = {
  IDLE: { icon: Link, color: 'text-slate-500', label: 'Esperando validación' },
  VALIDATING: { icon: Zap, color: 'text-amber-400 animate-pulse', label: 'Validando conexión...' },
  PENDING: { icon: Zap, color: 'text-cyan-400 animate-pulse', label: 'Esperando Handshake del script...' },
  HANDSHAKE_VERIFIED: { icon: Wifi, color: 'text-emerald-400', label: 'Handshake Verificado. Conexión Activa.' },
  EXPIRED: { icon: WifiOff, color: 'text-rose-500', label: 'Token de validación expirado.' },
  ERROR: { icon: AlertTriangle, color: 'text-rose-500', label: 'Error de Red' },
};

type ValidationStatus = keyof typeof STATUS_CONFIG;

export const EmbedCodeGeneratorValidator: React.FC = () => {
  const [targetUrl, setTargetUrl] = useState('https://www.laboratoriosanfrancisco.com');
  const [placementCode, setPlacementCode] = useState('solusol.directorio.busqueda.top');
  const [validationStatus, setValidationStatus] = useState<ValidationStatus>('IDLE');
  const [validationMessage, setValidationMessage] = useState('');
  const [isCopied, setIsCopied] = useState(false);
  const [validationToken, setValidationToken] = useState('');
  const [validationChallenge, setValidationChallenge] = useState('');

  const embedCode = `<script async src="https://adsolusol.solusol.net/adsolusol.js" data-placement-code="${placementCode}" data-token="${validationToken}" data-challenge="${validationChallenge}"></script>`;

  const handleCopy = () => {
    navigator.clipboard.writeText(embedCode);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  const pollTokenStatus = (token: string, attempts: number) => {
    if (attempts <= 0) {
      setValidationStatus('EXPIRED');
      setValidationMessage('El script no respondió a tiempo. Verifica la consola del navegador del cliente.');
      return;
    }

    setTimeout(async () => {
      try {
        const res = await apiFetch(`/api/check-token-status/${token}`);
        const data = await res.json();
        if (data.status === 'HANDSHAKE_VERIFIED') {
          setValidationStatus('HANDSHAKE_VERIFIED');
          setValidationMessage(data.message);
        } else if (data.status === 'EXPIRED') {
          setValidationStatus('EXPIRED');
          setValidationMessage(data.message);
        } else {
          pollTokenStatus(token, attempts - 1);
        }
      } catch (error: any) {
        setValidationStatus('ERROR');
        setValidationMessage(`Error de red al sondear: ${error.message}`);
      }
    }, 3000);
  };

  const handleValidate = async () => {
    setValidationStatus('VALIDATING');
    setValidationMessage('');
    try {
      const res = await apiFetch('/api/initiate-validation', { method: 'POST' });
      const data = await res.json();
      setValidationToken(data.token);
      setValidationChallenge(data.challenge);
      setValidationStatus('PENDING');
      setValidationMessage(`Token generado. Pide al cliente que inserte el tag y recargue su página.`);
      pollTokenStatus(data.token, 20); // Poll for 1 minute (20 attempts * 3s)
    } catch (error: any) {
      setValidationStatus('ERROR');
      setValidationMessage(`Error de red: ${error.message}`);
    }
  };

  const CurrentStatusIcon = STATUS_CONFIG[validationStatus].icon;

  return (
    <section className="as-card-premium rounded-2xl p-6 space-y-4">
      <div>
        <h3 className="text-base font-bold text-white">Generador de Tag First-Party y Validador de Conexión</h3>
        <p className="text-xs text-slate-400">
          Genera el código para insertar en el sitio del cliente y verifica la ejecución del script mediante un handshake.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-end">
        <div>
          <label className="text-xs font-semibold text-slate-400">URL del Cliente a Validar</label>
          <input
            type="url"
            value={targetUrl}
            onChange={(e) => setTargetUrl(e.target.value)}
            placeholder="https://www.cliente.com"
            className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white"
          />
        </div>
        <div>
          <label className="text-xs font-semibold text-slate-400">Código de Ubicación (Placement)</label>
          <input
            type="text"
            value={placementCode}
            onChange={(e) => setPlacementCode(e.target.value)}
            placeholder="codigo.del.placement"
            className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white font-mono"
          />
        </div>
      </div>

      <div className="bg-[#070B12] p-4 rounded-xl border border-slate-800 space-y-3">
        <div className="flex justify-between items-center">
          <p className="text-xs font-bold text-slate-300">Código de Inserción (pegar en el &lt;head&gt; del HTML)</p>
          <button
            onClick={handleCopy}
            className="px-3 py-1.5 rounded-lg bg-slate-700 hover:bg-slate-600 text-xs font-bold text-white flex items-center gap-1.5"
          >
            {isCopied ? <Check className="h-4 w-4 text-emerald-400" /> : <Copy className="h-4 w-4" />}
            {isCopied ? 'Copiado' : 'Copiar'}
          </button>
        </div>
        <pre className="bg-black/40 p-3 rounded-lg text-cyan-400 text-[11px] font-mono overflow-x-auto">
          <code>{embedCode}</code>
        </pre>
      </div>

      <div className="flex items-center gap-4 pt-3 border-t border-slate-800">
        <button
          onClick={handleValidate}
          disabled={validationStatus === 'VALIDATING' || validationStatus === 'PENDING'}
          className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold flex items-center gap-2 disabled:opacity-50"
        >
          <Zap className="h-4 w-4" />
          Validar Conexión
        </button>
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
    </section>
  );
};