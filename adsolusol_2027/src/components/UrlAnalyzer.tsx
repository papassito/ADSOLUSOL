import React, { useState } from 'react';
import { Search, Loader2, AlertCircle, CheckCircle } from 'lucide-react';
import { validateCampaignUrl } from '../utils/urlValidator';

export const UrlAnalyzer: React.FC = () => {
  const [url, setUrl] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState('');

  const analyze = async () => {
    const validation = validateCampaignUrl(url);
    if (!validation.valid) {
      setError(validation.reason);
      setResult(null);
      return;
    }
     
    setLoading(true);
    setError('');
    try {
      const response = await fetch('/api/analyze-url', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url }),
      });
      const data = await response.json();
      setResult(data);
    } catch (err) {
      setError('Error al analizar la URL. Verifica que sea accesible.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
      <h3 className="text-lg font-bold text-white mb-4">Analizador de Landing Page (SEO & Compliance)</h3>
      <div className="flex gap-2 mb-4">
        <input
          type="text"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          placeholder="https://tu-landing-page.com"
          className="flex-1 bg-slate-950 border border-slate-700 rounded-lg px-3 py-2 text-sm text-white"
        />
        <button
          onClick={analyze}
          disabled={loading}
          className="bg-amber-400 text-slate-950 px-4 py-2 rounded-lg font-semibold text-sm cursor-pointer"
        >
          {loading ? <Loader2 className="animate-spin w-4 h-4" /> : 'Analizar'}
        </button>
      </div>
      {error && <p className="text-rose-400 text-xs">{error}</p>}
      {result && (
        <div className="mt-4 p-4 bg-slate-950 rounded-lg border border-slate-800">
          <div className="flex items-center gap-2 mb-2">
            {result.compliant ? <CheckCircle className="text-emerald-400 w-5 h-5" /> : <AlertCircle className="text-amber-400 w-5 h-5" />}
            <span className="font-bold text-white">{result.compliant ? 'P gina Saludable' : 'Problemas Encontrados'}</span>
          </div>
          <p className="text-xs text-slate-300 mb-2">T tulo: {result.metadata.title}</p>
          <ul className="text-xs text-slate-400 list-disc list-inside">
            {result.issues.map((issue: string, i: number) => <li key={i}>{issue}</li>)}
          </ul>
        </div>
      )}
    </div>
  );
};
