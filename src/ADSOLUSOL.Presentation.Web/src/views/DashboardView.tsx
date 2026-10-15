import { useEffect, useMemo, useState } from "react";
import { api } from "../api";
import type { Campaign, CampaignMetrics, HealthResponse } from "../types";
import {
  Card,
  EmptyState,
  ErrorPanel,
  StatCard,
  StatusBadge,
  date,
  money,
  number
} from "../components/Common";

const unavailable = "NO DISPONIBLE";

const unavailableDimensions = [
  { label: "Palabras clave", detail: "Sin datos en la API" },
  { label: "Conversiones", detail: "Sin datos en la API" },
  { label: "Dispositivos", detail: "Sin desglose en la API" },
  { label: "Anuncios", detail: "Sin resultados por anuncio" },
  { label: "Ubicaciones", detail: "Sin desglose geográfico" },
  { label: "Alertas", detail: "Sin feed de alertas" }
];

export function DashboardView(props: {
  campaigns: Campaign[] | null;
  campaignError: string | null;
  health: HealthResponse | null;
  healthError: string | null;
  preview?: boolean;
}) {
  const [metricsByCampaign, setMetricsByCampaign] = useState<Record<string, CampaignMetrics>>({});
  const [metricsLoading, setMetricsLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;

    if (props.preview || !props.campaigns || props.campaigns.length === 0) {
      setMetricsByCampaign({});
      setMetricsLoading(false);
      return () => {
        cancelled = true;
      };
    }

    setMetricsByCampaign({});
    setMetricsLoading(true);
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
      setMetricsLoading(false);
    });

    return () => {
      cancelled = true;
    };
  }, [props.campaigns, props.preview]);

  const aggregate = useMemo(() => {
    if (!props.campaigns) return null;
    const campaigns = props.campaigns;
    const metricsAvailable = campaigns.length > 0 &&
      campaigns.every(campaign => metricsByCampaign[campaign.id] !== undefined);
    const impressions = metricsAvailable
      ? campaigns.reduce((total, campaign) => total + metricsByCampaign[campaign.id].impressions, 0)
      : null;
    const clicks = metricsAvailable
      ? campaigns.reduce((total, campaign) => total + metricsByCampaign[campaign.id].clicks, 0)
      : null;

    return {
      count: campaigns.length,
      active: campaigns.filter(campaign => campaign.status.toUpperCase() === "ACTIVE").length,
      spent: campaigns.reduce((total, campaign) => total + campaign.budgetSpent, 0),
      impressions,
      clicks,
      ctr: impressions !== null && clicks !== null
        ? impressions > 0 ? clicks / impressions * 100 : 0
        : null
    };
  }, [props.campaigns, metricsByCampaign]);

  const metricsComplete = Boolean(aggregate && aggregate.impressions !== null);
  const metricDetail = props.preview
    ? "Vista previa, sin datos de cuenta"
    : metricsLoading
    ? "Consultando API..."
    : metricsComplete
      ? "Eventos registrados por la API"
      : unavailable;

  return (
    <div className="dashboard-page">
      <header className="dashboard-heading">
        <div>
          <span className="eyebrow">ADSOLUSOL / RENDIMIENTO</span>
          <h2>Control de pauta</h2>
          <p>Una lectura clara de campañas, entrega y gasto.</p>
        </div>
        {props.preview ? (
          <span className="preview-label">VISTA LOCAL · SIN DATOS</span>
        ) : (
          <span className="data-source-label">FUENTE · API</span>
        )}
      </header>

      {props.campaignError && <ErrorPanel message={props.campaignError} />}

      <section className="stats-grid dashboard-stats" aria-label="Indicadores principales">
        <StatCard label="Campañas" value={aggregate ? number(aggregate.count) : unavailable} detail={props.preview ? "Vista previa sin datos" : aggregate ? `${number(aggregate.active)} activas` : "Esperando respuesta de API"} />
        <StatCard label="Impresiones" value={metricsComplete ? number(aggregate!.impressions!) : unavailable} detail={metricDetail} />
        <StatCard label="Clics" value={metricsComplete ? number(aggregate!.clicks!) : unavailable} detail={metricDetail} />
        <StatCard label="CTR" value={metricsComplete ? `${aggregate!.ctr!.toLocaleString("es-MX", { maximumFractionDigits: 2 })}%` : unavailable} detail="Clics / impresiones" />
        <StatCard label="CPC promedio" value={unavailable} detail="La API no reporta CPC observado" />
        <StatCard label="Gasto registrado" value={aggregate ? money(aggregate.spent) : unavailable} detail={aggregate ? "Suma de gasto de campañas" : "Esperando respuesta de API"} />
      </section>

      <section className="dashboard-grid" aria-label="Desempeño y cobertura">
        <Card className="dashboard-panel dashboard-campaigns">
          <div className="card-header dashboard-panel-heading">
            <div><span className="eyebrow">ENTREGA</span><h2>Campañas</h2></div>
            <span className="panel-count">{aggregate ? number(aggregate.count) : "—"} TOTAL</span>
          </div>
          {props.campaigns && props.campaigns.length > 0 ? (
            <div className="campaign-table">
              <div className="campaign-table-head"><span>Campaña</span><span>Estado</span><span>Impresiones</span><span>Clics</span><span>Gasto</span></div>
              {props.campaigns.slice(0, 8).map(campaign => {
                const metrics = metricsByCampaign[campaign.id];
                return (
                  <div className="campaign-table-row" key={campaign.id}>
                    <div className="campaign-table-name"><strong>{campaign.name}</strong><small>{campaign.id}</small></div>
                    <StatusBadge value={campaign.status} />
                    <span className="table-number">{metrics ? number(metrics.impressions) : unavailable}</span>
                    <span className="table-number">{metrics ? number(metrics.clicks) : unavailable}</span>
                    <span className="table-number">{money(campaign.budgetSpent)}</span>
                  </div>
                );
              })}
            </div>
          ) : (
            <EmptyState
              title={props.preview ? "Sin datos de cuenta" : props.campaigns ? "Sin campañas" : unavailable}
              description={props.preview ? "Inicia sesión para consultar los datos de la cuenta." : props.campaigns ? "La API devolvió una lista vacía de campañas." : "No se recibieron campañas de la API."}
            />
          )}
        </Card>

        <Card className="dashboard-panel dashboard-system">
          <div className="card-header dashboard-panel-heading"><div><span className="eyebrow">SERVICIO</span><h2>Estado del sistema</h2></div></div>
          {props.preview ? (
            <EmptyState title="API sin consultar" description="La vista previa no envía solicitudes al backend." />
          ) : props.healthError ? <ErrorPanel message={props.healthError} /> : props.health ? (
            <div className="health-grid dashboard-health">
              <div className="health-row"><span>General</span><StatusBadge value={props.health.status} /></div>
              <div className="health-row"><span>Base de datos</span><StatusBadge value={props.health.checks.database} /></div>
              <div className="health-row"><span>SIC</span><StatusBadge value={props.health.checks.sicEngine} /></div>
              <div className="health-row"><span>Última lectura</span><strong>{date(props.health.timestamp)}</strong></div>
            </div>
          ) : <p className="muted">Verificando servicio...</p>}
        </Card>

        <Card className="dashboard-panel dashboard-history">
          <div className="card-header dashboard-panel-heading"><div><span className="eyebrow">TENDENCIA</span><h2>Rendimiento en el tiempo</h2></div><span className="panel-period">SERIE TEMPORAL</span></div>
          <EmptyState title={unavailable} description="La API no ofrece una serie histórica para construir una gráfica verificable." />
        </Card>

        {unavailableDimensions.map(dimension => (
          <Card className="dashboard-panel dashboard-module" key={dimension.label}>
            <div className="card-header dashboard-panel-heading">
              <div><span className="eyebrow">COBERTURA DE DATOS</span><h2>{dimension.label}</h2></div>
            </div>
            <EmptyState title={unavailable} description={dimension.detail} />
          </Card>
        ))}
      </section>
    </div>
  );
}
