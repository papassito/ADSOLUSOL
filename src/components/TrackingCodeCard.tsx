import { useEffect, useState } from 'react';
import { apiFetch } from '../services/api';

type Tracking = { code: string; redirectUrl: string; targetUrl: string };

export function TrackingCodeCard({ creativeId }: { creativeId: string | number }) {
  const [tracking, setTracking] = useState<Tracking | null>(null);
  const [copied, setCopied] = useState(false);
  useEffect(() => {
    let active = true;
    apiFetch(`/api/Creatives/${encodeURIComponent(String(creativeId))}/tracking`)
      .then(async r => r.ok ? r.json() : null)
      .then(value => { if (active && value) setTracking(value); })
      .catch(() => undefined);
    return () => { active = false; };
  }, [creativeId]);
  if (!tracking) return null;
  const copy = async () => { await navigator.clipboard.writeText(tracking.redirectUrl); setCopied(true); };
  return <div className="rounded-xl border border-cyan-500/30 bg-cyan-500/5 p-3 space-y-2">
    <p className="text-xs font-bold text-cyan-300">Código real de rastreo</p>
    <p className="font-mono text-[11px] text-white break-all">{tracking.code}</p>
    <p className="text-[11px] text-slate-300 break-all">URL etiquetada: {tracking.redirectUrl}</p>
    <button type="button" onClick={copy} className="rounded border border-cyan-400/40 px-2 py-1 text-xs text-cyan-200">{copied ? 'Copiada' : 'Copiar URL de rastreo'}</button>
    <p className="text-[10px] text-slate-400">Los clics pasan por /r/{tracking.code} y se registran antes de redirigir al destino.</p>
  </div>;
}
