import { SiteVerificationCard } from './components/SiteVerificationCard';
import React from 'react';
import { Sparkles, Navigation, Smartphone, ExternalLink, PhoneCall, Lock, MapPin, Trash2 } from 'lucide-react';
import { Creative } from './types';
import { BRANCH_LOCATIONS } from './constants';

interface CreativesViewProps {
  creatives: Creative[];
  crtForm: any;
  setCrtForm: React.Dispatch<React.SetStateAction<any>>;
  onApplyAiPreset: () => void;
  onOpenDrawer: () => void;
  onOpenDirectionsMaps: (address: string) => void;
  onServeClick: () => void;
  onDeleteCreative: (id: string, title: string) => void;
}

export const CreativesView: React.FC<CreativesViewProps> = ({
  creatives,
  crtForm,
  setCrtForm,
  onApplyAiPreset,
  onOpenDrawer,
  onOpenDirectionsMaps,
  onServeClick,
  onDeleteCreative,
}) => {
  return (
    <div className="space-y-6">
      <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="as-card-premium rounded-2xl p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-amber-400">Laboratorio Creativo + Geolocalización</span>
              <h3 className="text-base font-bold text-white">Generador de Anuncios con IA + Ruta Google Maps</h3>
            </div>
            <button type="button" onClick={onApplyAiPreset} className="px-3 py-1.5 rounded-xl bg-indigo-500/20 border border-indigo-400/40 text-indigo-300 hover:bg-indigo-500/30 text-xs font-bold flex items-center gap-1.5 cursor-pointer">
              <Sparkles className="h-3.5 w-3.5 text-amber-400" /> Autocompletar con IA
            </button>
          </div>

          <div className="space-y-3">
            <div>
              <label className="text-xs text-slate-400">Título Principal</label>
              <input type="text" value={crtForm.title} onChange={(e) => setCrtForm({ ...crtForm, title: e.target.value })} className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white" />
            </div>
            <div>
              <label className="text-xs text-slate-400">Descripción Persuasiva</label>
              <textarea rows={2} value={crtForm.description} onChange={(e) => setCrtForm({ ...crtForm, description: e.target.value })} className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs text-slate-400">URL Final (HTTPS)</label>
                <input type="url" value={crtForm.destinationUrl} onChange={(e) => setCrtForm({ ...crtForm, destinationUrl: e.target.value })} className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white" />
              </div>
              <div>
                <label className="text-xs text-slate-400">Extensión WhatsApp</label>
                <input type="text" value={crtForm.whatsappContact} onChange={(e) => setCrtForm({ ...crtForm, whatsappContact: e.target.value })} className="w-full mt-1 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white" />
              </div>
            </div>
            <div>
              <label className="text-xs text-amber-400 font-semibold flex items-center gap-1">
                <Navigation className="h-3.5 w-3.5" /> Dirección GPS para Botón "Cómo llegar"
              </label>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 mt-1">
                <input type="text" value={crtForm.locationAddress} onChange={(e) => setCrtForm({ ...crtForm, locationAddress: e.target.value })} className="sm:col-span-2 bg-[#070B12] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white" />
                <select value={crtForm.locationAddress} onChange={(e) => setCrtForm({ ...crtForm, locationAddress: e.target.value })} className="bg-[#070B12] border border-amber-500/40 rounded-xl px-2.5 py-2 text-xs text-amber-400 font-bold">
                  {BRANCH_LOCATIONS.map((b, idx) => (
                    <option key={idx} value={b.address}>{b.label}</option>
                  ))}
                </select>
              </div>
            </div>
            <button onClick={onOpenDrawer} className="w-full py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold cursor-pointer">
              Publicar Anuncio con Ruta GPS en Catálogo
            </button>
          </div>
        </div>

        <div className="as-card-premium rounded-2xl p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-bold text-emerald-400 flex items-center gap-1.5">
              <Smartphone className="h-4 w-4" /> Simulador Móvil SERP + Google Maps Activo
            </span>
            <span className="px-2 py-0.5 rounded bg-cyan-500/15 text-cyan-400 text-[10px] font-bold">Extensión de Ubicación Activa</span>
          </div>

          <div className="bg-white text-slate-900 rounded-2xl p-4 shadow-xl border border-slate-200 space-y-3">
            <div onClick={onServeClick} className="cursor-pointer">
              <div className="flex items-center gap-2 text-[11px] text-slate-600 mb-0.5">
                <span className="font-bold text-slate-950">Patrocinado</span>
                <span>•</span>
                <span className="truncate">{crtForm.destinationUrl}</span>
              </div>
              <h4 className="text-base font-bold text-blue-700 hover:underline flex items-center gap-1">
                {crtForm.title} <ExternalLink className="h-3.5 w-3.5 inline shrink-0" />
              </h4>
              <p className="text-xs text-slate-700 mt-1 leading-relaxed">{crtForm.description}</p>
            </div>

            <div className="pt-2.5 border-t border-slate-100 flex flex-wrap gap-2 text-[11px] font-bold">
              <a href={`https://wa.me/52${crtForm.whatsappContact.replace(/[^0-9]/g, '')}`} target="_blank" rel="noopener noreferrer" onClick={onServeClick} className="bg-emerald-50 text-emerald-700 px-3 py-1.5 rounded-lg flex items-center gap-1.5 border border-emerald-200">
                <PhoneCall className="h-3.5 w-3.5" /> WhatsApp: {crtForm.whatsappContact}
              </a>
              <button type="button" onClick={() => onOpenDirectionsMaps(crtForm.locationAddress)} className="bg-blue-600 text-white px-3 py-1.5 rounded-lg flex items-center gap-1.5 shadow-sm cursor-pointer">
                <Navigation className="h-3.5 w-3.5" /> Cómo llegar (Abrir Ruta GPS)
              </button>
            </div>

            <div className="rounded-xl overflow-hidden border border-slate-200 h-32 relative">
              <iframe title="Mapa Sucursal" width="100%" height="100%" style={{ border: 0 }} loading="lazy" src={`https://www.google.com/maps?q=${encodeURIComponent(crtForm.locationAddress)}&output=embed`} />
            </div>
          </div>
        </div>
      </section>

      <SiteVerificationCard targetUrl={crtForm.destinationUrl} refreshKey={String(creatives.length)} />
      <section className="as-card-premium rounded-2xl p-6 space-y-4">
        <h3 className="text-base font-bold text-white">Biblioteca de Creativos ({creatives.length})</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {creatives.map((cr: any) => (
            <div key={cr.id} className="p-4 rounded-xl bg-[#070B12] border border-slate-800 flex flex-col justify-between gap-3">
              <div>
                <div className="flex justify-between items-center text-[11px] mb-1">
                  <span className="font-mono text-amber-400 font-bold">{cr.id} ➔ {cr.campaignId}</span>
                  <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-400 font-bold flex items-center gap-1"><Lock className="h-3 w-3" /> Creativo registrado</span>
                </div>
                <h4 className="text-sm font-bold text-blue-400">{cr.title}</h4>
                <p className="text-xs text-slate-300 mt-1">{cr.description}</p>
                <p className="text-[11px] text-amber-400/90 mt-1.5 flex items-center gap-1">
                  <MapPin className="h-3 w-3 shrink-0" /> {cr.locationAddress || 'Ubicación autorizada'}
                </p>
              </div>
              <SiteVerificationCard targetUrl={cr.targetUrl || cr.destinationUrl || ''} />
              <div className="pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs">
                <span className="text-slate-400 font-mono">{cr.clicks} clics • 📍 {cr.directionsClicks || 0} rutas GPS</span>
                <div className="flex items-center gap-2">
                  <button onClick={() => onOpenDirectionsMaps(cr.locationAddress)} className="px-2.5 py-1 rounded-lg bg-blue-600/20 text-blue-400 border border-blue-500/30 font-bold flex items-center gap-1 cursor-pointer">
                    <Navigation className="h-3 w-3" /> Cómo llegar
                  </button>
                  <button onClick={() => onDeleteCreative(cr.id, cr.title)} className="text-slate-400 hover:text-rose-400 cursor-pointer"><Trash2 className="h-4 w-4" /></button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};