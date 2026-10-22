import React, { useEffect, useRef, useState } from 'react';
import { apiFetch } from '../services/api';

type Proof = {
  domain: string; siteUrl: string; status: 'PENDING' | 'VERIFIED' | 'FAILED';
  snippet: string; verifiedAtUtc: string | null; lastCheckedAtUtc: string | null;
  message: string | null;
};

export function SiteVerificationCard({ targetUrl, refreshKey = '' }: { targetUrl: string; refreshKey?: string }) {
  const [proof, setProof] = useState<Proof | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [copied, setCopied] = useState(false);
  const generation = useRef(0);
  let siteUrl = '';
  try {
    const url = new URL(targetUrl);
    if (url.protocol === 'https:' && !url.username && !url.password && (!url.port || url.port === '443'))
      siteUrl = url.origin + '/';
  } catch { /* Show URL guidance below. */ }

  useEffect(() => {
    const current = ++generation.current;
    const abort = new AbortController();
    setProof(null); setError(''); setCopied(false); setBusy(false);
    if (!siteUrl) return () => abort.abort();
    apiFetch('/api/SiteVerifications?targetUrl=' + encodeURIComponent(siteUrl), { signal: abort.signal })
      .then(async response => {
        if (current !== generation.current) return;
        if (response.status === 404) return;
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'No se pudo consultar la verificación.');
        if (current === generation.current) setProof(data);
      })
      .catch(err => {
        if (!abort.signal.aborted && current === generation.current) setError(err.message);
      });
    return () => { abort.abort(); generation.current++; };
  }, [siteUrl, refreshKey]);

  async function submit(verify: boolean) {
    const current = generation.current;
    setBusy(true); setError(''); setCopied(false);
    try {
      const response = await apiFetch('/api/SiteVerifications' + (verify ? '/verify' : ''), {
        method: 'POST', body: JSON.stringify({ targetUrl: siteUrl }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.message || 'No se pudo completar la verificación.');
      if (current === generation.current) setProof(data);
    } catch (err) {
      if (current === generation.current) setError(err instanceof Error ? err.message : 'Error de red.');
    } finally { if (current === generation.current) setBusy(false); }
  }

  async function copy() {
    try { await navigator.clipboard.writeText(proof!.snippet); setCopied(true); }
    catch { setError('No se pudo copiar. Selecciona y copia el código manualmente.'); }
  }

  return (
    <section aria-label="Verificación del sitio" className="as-card-premium rounded-2xl p-4 space-y-3">
      <h3 className="font-bold">Verificar sitio promocionado</h3>
      {!siteUrl ? <p>Introduce una URL HTTPS para obtener el código del sitio.</p> : (
        <>
          <p className="text-sm break-all">{proof?.domain || siteUrl}</p>
          <p className="text-sm">Coloca la etiqueta dentro de &lt;head&gt; en el index.html, index.php o plantilla principal del dominio exacto. Después pulsa Verificar sitio.</p>
          <p role="status">{proof?.status === 'VERIFIED' ? 'VERIFICADO' : proof?.status === 'FAILED' ? 'NO VERIFICADO' : 'PENDIENTE DE VERIFICACIÓN'}</p>
          {proof && (
            <>
              <textarea aria-label="Código de verificación" readOnly rows={3} value={proof.snippet}
                className="w-full rounded p-3 font-mono text-xs bg-slate-900 text-slate-100" />
              <button type="button" onClick={copy} className="rounded border px-3 py-2">{copied ? 'Copiado' : 'Copiar código'}</button>
              <button type="button" disabled={busy} onClick={() => submit(true)} className="rounded border px-3 py-2 ml-2">
                {busy ? 'Comprobando…' : 'Verificar sitio'}
              </button>
              {proof.verifiedAtUtc && <p>Verificado: {new Date(proof.verifiedAtUtc).toLocaleString()}</p>}
              {proof.lastCheckedAtUtc && <p>Última comprobación: {new Date(proof.lastCheckedAtUtc).toLocaleString()}</p>}
              {proof.message && <p>{proof.message}</p>}
            </>
          )}
          {!proof && <button type="button" disabled={busy} onClick={() => submit(false)} className="rounded border px-3 py-2">
            {busy ? 'Generando…' : 'Generar código del sitio'}
          </button>}
          <p className="text-xs">La verificación acredita control de esta página en la fecha indicada. La medición y la entrega publicitaria se comprueban por separado.</p>
        </>
      )}
      {error && <p role="alert">{error}</p>}
    </section>
  );
}
