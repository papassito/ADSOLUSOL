import { useEffect, useMemo, useState } from "react";
import { api } from "../api";
import type { Campaign, CampaignMetrics, HealthResponse, Placement } from "../types";
import { number } from "../components/Common";

const NA = "N/A";

export function DashboardView(props: {
  campaigns: Campaign[] | null;
  health: HealthResponse | null;
  healthError: string | null;
  onSection: (title: string, subtitle: string) => void;
}) {
  const [metricsByCampaign, setMetricsByCampaign] = useState<Record<string, CampaignMetrics>>({});
  const [placements, setPlacements] = useState<Placement[] | null>(null);
  const [placementsError, setPlacementsError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void api.listPlacements()
      .then(items => {
        if (cancelled) return;
        setPlacements(items);
        setPlacementsError(null);
      })
      .catch(() => {
        if (!cancelled) setPlacementsError("No se pudo cargar el inventario de placements.");
      });
    return () => { cancelled = true; };
  }, []);

  useEffect(() => {
    let cancelled = false;

    if (!props.campaigns || props.campaigns.length === 0) {
      setMetricsByCampaign({});
      return () => {
        cancelled = true;
      };
    }

    setMetricsByCampaign({});
    void Promise.allSettled(props.campaigns.map(async campaign => ({
      id: campaign.id,
      metrics: await api.getCampaignMetrics(campaign.id)
    }))).then(results => {
      if (cancelled) return;
      const next: Record<string, CampaignMetrics> = {};
      for (const result of results) {
        if (result.status === "fulfilled") next[result.value.id] = result.value.metrics;
      }
      setMetricsByCampaign(next);
    });

    return () => {
      cancelled = true;
    };
  }, [props.campaigns]);

  const funnel = useMemo(() => {
    const campaigns = props.campaigns;
    if (!campaigns || campaigns.length === 0 || !campaigns.every(campaign => metricsByCampaign[campaign.id] !== undefined)) {
      return null;
    }
    const impressions = campaigns.reduce((total, campaign) => total + metricsByCampaign[campaign.id].impressions, 0);
    const clicks = campaigns.reduce((total, campaign) => total + metricsByCampaign[campaign.id].clicks, 0);
    return { impressions, clicks, ctr: impressions > 0 ? clicks / impressions * 100 : 0 };
  }, [props.campaigns, metricsByCampaign]);

  const healthStatus = props.health ? props.health.status.toUpperCase() : null;
  const healthy = healthStatus === "HEALTHY";
  const statusLabel = healthStatus ?? (props.healthError ? "API DESCONECTADA" : "VERIFICANDO");
  const statusTone = healthy
    ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
    : "bg-amber-500/10 text-amber-400 border-amber-500/20";
  const statusDot = healthy ? "bg-emerald-400" : "bg-amber-400";

  return (
    <div className="p-6 space-y-6 max-w-[1600px] w-full mx-auto">

      {/* HEADER CON TÍTULO Y ESTADO */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-extrabold tracking-tight">Centro de Control SSP & Monetización</h1>
          <p className="text-sm text-gray-400 mt-1">Supervisión operativa, ingresos de medios, subastas en vivo e infraestructura.</p>
        </div>
        <div className="flex items-center gap-3">
          <span className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold border ${statusTone}`}>
            <span className={`w-2 h-2 rounded-full animate-pulse ${statusDot}`}></span> {statusLabel}
          </span>
          <button type="button" disabled title="La API todavía no ofrece simulación ni subastas RTB." className="px-4 py-2 bg-gray-700 text-gray-400 rounded-lg text-xs font-bold transition flex items-center gap-2">
            <i className="fa-solid fa-bolt"></i> RTB no disponible
          </button>
        </div>
      </div>

      {/* RESUMEN FINANCIERO Y FLUJO ECONÓMICO REAL */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-xs font-extrabold uppercase tracking-wider text-gray-400 flex items-center gap-2">
            <i className="fa-solid fa-wallet text-blue-500"></i> Flujo Financiero del Sistema <span className="bg-blue-500/20 text-blue-400 text-[10px] px-2 py-0.5 rounded font-mono">OPERATIVO REAL</span>
          </h2>
          <span className="text-xs text-gray-500">Moneda: {NA}</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

          <div className="app-card p-5 rounded-xl relative overflow-hidden">
            <div className="text-xs text-gray-400 font-medium">Ingresos Brutos (Hoy)</div>
            <div className="text-2xl font-bold font-mono-num mt-2 currency-val text-emerald-400">{NA}</div>
            <div className="mt-2 text-xs flex items-center gap-1.5 text-emerald-400">
              <i className="fa-solid fa-arrow-trend-up"></i> SIN DATOS
            </div>
            <div className="absolute -right-3 -bottom-3 text-emerald-500/5 text-6xl font-black">
              <i className="fa-solid fa-sack-dollar"></i>
            </div>
          </div>

          <div className="app-card p-5 rounded-xl relative overflow-hidden">
            <div className="text-xs text-gray-400 font-medium">Ingresos Acumulados (Mes)</div>
            <div className="text-2xl font-bold font-mono-num mt-2 currency-val">{NA}</div>
            <div className="mt-2 text-xs text-gray-400">Meta mensual: {NA}</div>
            <div className="w-full bg-gray-800 h-1.5 rounded-full mt-2 overflow-hidden">
              <div className="bg-blue-500 h-full rounded-full" style={{ width: "0%" }}></div>
            </div>
          </div>

          <div className="app-card p-5 rounded-xl relative overflow-hidden">
            <div className="text-xs text-gray-400 font-medium">Comisiones AdSolusol</div>
            <div className="text-2xl font-bold font-mono-num mt-2 currency-val text-blue-400">{NA}</div>
            <div className="mt-2 text-xs text-gray-400">Tasa promedio RevShare: {NA}</div>
          </div>

          <div className="app-card p-5 rounded-xl relative overflow-hidden">
            <div className="text-xs text-gray-400 font-medium">Pagos Pendientes a Medios</div>
            <div className="text-2xl font-bold font-mono-num mt-2 currency-val text-amber-400">{NA}</div>
            <div className="mt-2 text-xs text-amber-400/80 flex items-center gap-1">
              <i className="fa-solid fa-clock"></i> SIN DATOS
            </div>
          </div>

        </div>
      </div>

      {/* MONITOR SYSTEM HEALTH & ALERTAS OPERATIVAS */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* System Health Center */}
        <div className="app-card p-5 rounded-xl">
          <div className="flex items-center justify-between mb-4 border-b border-inherit pb-3">
            <h3 className="font-heading font-bold text-sm flex items-center gap-2">
              <i className="fa-solid fa-server text-blue-500"></i> Health Center (Infraestructura)
            </h3>
            <span className={`text-[10px] border px-2 py-0.5 rounded font-bold ${statusTone}`}>{statusLabel}</span>
          </div>
          <div className="space-y-3 text-xs">
            {["OpenRTB Bidding Engine", "CDN & Content Delivery", "Video/Audio Streaming Hub", "Billing & Automated Payouts"].map(name => (
              <div key={name} className="flex items-center justify-between p-2 rounded-lg bg-black/20">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-gray-500"></span>
                  <span className="font-semibold">{name}</span>
                </div>
                <span className="font-mono text-gray-400">{NA}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Alertas Operativas */}
        <div className="app-card p-5 rounded-xl">
          <div className="flex items-center justify-between mb-4 border-b border-inherit pb-3">
            <h3 className="font-heading font-bold text-sm flex items-center gap-2">
              <i className="fa-solid fa-triangle-exclamation text-amber-500"></i> Alertas Operativas
            </h3>
            <span className="text-[10px] bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2 py-0.5 rounded font-bold">SIN DATOS</span>
          </div>
          <div className="space-y-3 text-xs">
            <div className="p-2.5 rounded-lg bg-amber-500/10 border border-amber-500/20 text-amber-200">
              <div className="font-bold flex items-center justify-between">
                <span>Sin feed de alertas</span>
                <span className="text-[10px] text-amber-400/70">{NA}</span>
              </div>
              <p className="text-[11px] text-amber-300/80 mt-1">La API no expone alertas operativas.</p>
            </div>
          </div>
        </div>

        {/* Módulo Anti-Fraude & Brand Safety */}
        <div className="app-card p-5 rounded-xl">
          <div className="flex items-center justify-between mb-4 border-b border-inherit pb-3">
            <h3 className="font-heading font-bold text-sm flex items-center gap-2">
              <i className="fa-solid fa-shield-virus text-emerald-500"></i> Anti-Fraude & Protection
            </h3>
            <span className="text-[10px] bg-gray-500/10 text-gray-400 px-2 py-0.5 rounded font-bold">{NA}</span>
          </div>
          <div className="space-y-3 text-xs">
            <div className="flex items-center justify-between">
              <span className="text-gray-400">Invalid Traffic (IVT):</span>
              <span className="font-mono font-bold">{NA}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-400">Bots Bloqueados Hoy:</span>
              <span className="font-mono font-bold">{NA}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-400">Score Brand Safety:</span>
              <span className="font-mono font-bold">{NA}</span>
            </div>
            <div className="p-2 rounded bg-black/20 text-[11px] text-gray-400 mt-2">
              <i className="fa-solid fa-circle-info mr-1"></i> SIN DATOS
            </div>
          </div>
        </div>

      </div>

      {/* RED DE PUBLISHERS & MEDIOS ALIADOS */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-xs font-extrabold uppercase tracking-wider text-gray-400 flex items-center gap-2">
            <i className="fa-solid fa-tower-cell text-blue-500"></i> Publishers Activos en el Ecosistema
          </h2>
          <button onClick={() => props.onSection("Agregar Nuevo Publisher", "Petición de Integración")} className="text-xs text-blue-400 hover:text-blue-300 font-semibold">+ Registrar Medio</button>
        </div>

        <div className="app-card p-4 rounded-xl text-xs text-gray-400">
          SIN DATOS: la API no expone publishers.
        </div>
      </div>

      {/* INVENTARIO DE ESPACIOS PUBLICITARIOS */}
      <div className="app-card rounded-xl p-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <div>
            <h3 className="font-heading font-bold text-base">Inventario de Espacios Publicitarios</h3>
            <p className="text-xs text-gray-400">Gestión de placements, Floor Price y Fill Rate operativo.</p>
          </div>
          <span className="text-xs text-gray-400 font-mono">Total slots: {placements?.length ?? NA}</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-inherit text-gray-400 font-semibold uppercase tracking-wider text-[10px]">
                <th className="py-3 px-3">ID</th>
                <th className="py-3 px-3">Código</th>
                <th className="py-3 px-3">Espacio Publicitario</th>
                <th className="py-3 px-3">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {placementsError ? (
                <tr><td colSpan={4} className="py-3 px-3 text-amber-400">{placementsError}</td></tr>
              ) : placements === null ? (
                <tr><td colSpan={4} className="py-3 px-3 text-gray-400">Cargando inventario...</td></tr>
              ) : placements.length === 0 ? (
                <tr><td colSpan={4} className="py-3 px-3 text-gray-400">Sin placements registrados.</td></tr>
              ) : placements.map(placement => (
                <tr key={placement.id}>
                  <td className="py-3 px-3 font-mono">{placement.id}</td>
                  <td className="py-3 px-3 font-mono">{placement.placementCode}</td>
                  <td className="py-3 px-3">{placement.name}</td>
                  <td className="py-3 px-3">{placement.isEnabled ? "Habilitado" : "Pausado"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* MAPA GEOGRÁFICO INTERACTIVO & EMBUDO PUBLICITARIO */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* MAPA GEOGRÁFICO VECTORIAL CON HOTSPOTS */}
        <div className="app-card p-5 rounded-xl flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-heading font-bold text-sm flex items-center gap-2">
                <i className="fa-solid fa-earth-americas text-blue-500"></i> Distribución Geográfica de Tráfico
              </h3>
              <span className="text-[10px] bg-gray-500/10 text-gray-400 px-2 py-0.5 rounded font-bold">SIN DATOS GEO</span>
            </div>

            <div className="relative w-full min-h-48 bg-black/40 rounded-lg border border-white/5 flex flex-col items-center justify-center p-6 text-center">
              <i className="fa-solid fa-earth-americas text-2xl text-gray-600" aria-hidden="true"></i>
              <strong className="mt-3 text-sm text-gray-300">Sin datos geográficos</strong>
              <p className="mt-1 max-w-sm text-xs text-gray-500">La API no ofrece métricas de tráfico por ubicación.</p>
            </div>
          </div>

          <div className="mt-3 p-2.5 rounded bg-black/30 border border-white/5 text-xs flex justify-between items-center">
            <span>Cobertura geográfica</span>
            <span className="font-mono text-gray-300">SIN DATOS</span>
          </div>
        </div>

        {/* EMBUDO PUBLICITARIO FULL FUNNEL */}
        <div className="app-card p-5 rounded-xl">
          <div className="flex items-center justify-between mb-4 border-b border-inherit pb-3">
            <h3 className="font-heading font-bold text-sm flex items-center gap-2">
              <i className="fa-solid fa-filter text-blue-500"></i> Embudo de Conversión Publicitaria
            </h3>
            <span className="text-[10px] text-gray-400">EFICIENCIA DE ENTREGA</span>
          </div>

          <div className="space-y-3 text-xs">
            <div>
              <div className="flex justify-between font-bold mb-1">
                <span>1. Impresiones Servidas</span>
                <span className="font-mono text-blue-400">{funnel ? `${number(funnel.impressions)}${funnel.impressions > 0 ? " (100%)" : ""}` : NA}</span>
              </div>
              <div className="w-full bg-gray-800 h-2 rounded-full"><div className="bg-blue-500 h-full rounded-full" style={{ width: funnel && funnel.impressions > 0 ? "100%" : "0%" }}></div></div>
            </div>

            <div>
              <div className="flex justify-between font-bold mb-1">
                <span>2. Visualizaciones (Viewable)</span>
                <span className="font-mono text-purple-400">{NA}</span>
              </div>
              <div className="w-full bg-gray-800 h-2 rounded-full"><div className="bg-purple-500 h-full rounded-full" style={{ width: "0%" }}></div></div>
            </div>

            <div>
              <div className="flex justify-between font-bold mb-1">
                <span>3. Clics Efectivos (CTR)</span>
                <span className="font-mono text-emerald-400">{funnel ? `${number(funnel.clicks)} (${funnel.ctr.toLocaleString("es-MX", { maximumFractionDigits: 2 })}%)` : NA}</span>
              </div>
              <div className="w-full bg-gray-800 h-2 rounded-full"><div className="bg-emerald-500 h-full rounded-full" style={{ width: funnel ? `${Math.min(100, funnel.ctr)}%` : "0%" }}></div></div>
            </div>

            <div>
              <div className="flex justify-between font-bold mb-1">
                <span>4. Conversiones / Sales (CPA)</span>
                <span className="font-mono text-amber-400">{NA}</span>
              </div>
              <div className="w-full bg-gray-800 h-2 rounded-full"><div className="bg-amber-500 h-full rounded-full" style={{ width: "0%" }}></div></div>
            </div>
          </div>
        </div>

      </div>

      {/* FORECAST Y PROYECCIÓN ALGORÍTMICA IA */}
      <div className="app-card p-5 rounded-xl bg-gradient-to-r from-blue-950/20 to-purple-950/20 border-blue-500/20">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-3">
          <div className="flex items-center gap-2">
            <span className="px-2 py-0.5 rounded text-[10px] font-black bg-blue-500 text-white font-mono">PROYECCIÓN IA</span>
            <h3 className="font-heading font-bold text-sm">Forecast Estimado (Próximos 30 Días)</h3>
          </div>
          <span className="text-xs text-gray-400">Algoritmo predictivo de demanda RTB</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-center py-2">
          <div className="p-3 bg-black/40 rounded-lg">
            <div className="text-xs text-gray-400">Ingresos Proyectados</div>
            <div className="text-xl font-bold font-mono text-emerald-400 mt-1">{NA}</div>
          </div>
          <div className="p-3 bg-black/40 rounded-lg">
            <div className="text-xs text-gray-400 font-medium">Comisiones Estimadas</div>
            <div className="text-xl font-bold font-mono text-blue-400 mt-1">{NA}</div>
          </div>
          <div className="p-3 bg-black/40 rounded-lg">
            <div className="text-xs text-gray-400 font-medium">Fill Rate Promedio Esperado</div>
            <div className="text-xl font-bold font-mono text-amber-400 mt-1">{NA}</div>
          </div>
        </div>
      </div>

    </div>
  );
}
