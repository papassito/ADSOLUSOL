import { useMemo, useState } from 'react';
import { Check, Copy, Code2, AlertTriangle } from 'lucide-react';

/** Genera el snippet, pero solo muestra una validación confirmada por el backend. */
export function EmbedCodeGeneratorValidator() {
  const [targetUrl, setTargetUrl] = useState('https://laboratoriosanfrancisco.mx');
  const [zoneId, setZoneId] = useState('ZONE-HMO-101');
  const [copied, setCopied] = useState(false);
  const [status, setStatus] = useState<string | null>(null);

  const host = useMemo(() => {
    try { return new URL(targetUrl).hostname; } catch { return ''; }
  }, [targetUrl]);

  const snippet = useMemo(() => `<!-- ADSOLUSOL 2027 -->\n<script src="https://api.solusol.net/sdk/adsolusol.js" async\n  data-zone-id="${zoneId}"\n  data-origin-host="${host}"></script>`, [zoneId, host]);

  async function copySnippet() {
    await navigator.clipboard.writeText(snippet);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  }

  async function validate() {
    setStatus('Validando con el servidor…');
    try {
      const response = await fetch('/api/embed/validate', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: targetUrl, zoneId }),
      });
      const data = await response.json().catch(() => ({}));
      setStatus(response.ok && data.verified ? 'Conexión verificada por el servidor.' : (data.message ?? 'No verificado.'));
    } catch { setStatus('No se pudo contactar al validador.'); }
  }

  return <section className="as-card-premium rounded-2xl p-5 space-y-3">
    <div className="flex items-center gap-2"><Code2 className="h-5 w-5 text-brand-400" /><h3 className="font-bold text-white">Código embebido y verificación</h3></div>
    <p className="text-xs text-slate-400">El resultado solo se marca como verificado cuando responde el endpoint del servidor.</p>
    <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
      <input value={targetUrl} onChange={e => setTargetUrl(e.target.value)} className="rounded-lg bg-slate-950 border border-slate-700 px-3 py-2 text-xs text-white" aria-label="URL destino" />
      <input value={zoneId} onChange={e => setZoneId(e.target.value)} className="rounded-lg bg-slate-950 border border-slate-700 px-3 py-2 text-xs text-white" aria-label="Zona" />
      <div className="flex gap-2"><button onClick={copySnippet} className="px-3 py-2 rounded-lg bg-brand-500 text-slate-950 text-xs font-bold">{copied ? <Check className="inline h-4 w-4" /> : <Copy className="inline h-4 w-4" />} Copiar</button><button onClick={validate} className="px-3 py-2 rounded-lg bg-slate-800 text-white text-xs font-bold">Validar</button></div>
    </div>
    <pre className="overflow-auto rounded-lg bg-slate-950 p-3 text-[11px] text-emerald-300">{snippet}</pre>
    {status && <p className="text-xs text-slate-300"><AlertTriangle className="inline h-4 w-4 mr-1 text-amber-400" />{status}</p>}
  </section>;
}
