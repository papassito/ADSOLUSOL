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

export function DashboardView(props: {
  campaigns: Campaign[] | null;
  campaignError: string | null;
  health: HealthResponse | null;
  healthError: string | null;
}) {
  const [metricsByCampaign, setMetricsByCampaign] = useState<Record<string, CampaignMetrics>>({});
  const [metricsLoading, setMetricsLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function loadMetrics() {
      if (!props.campaigns) {
        setMetricsByCampaign({});
        return;
      }

      if (props.campaigns.length === 0) {
        setMetricsByCampaign({});
        return;
      }

      setMetricsLoading(true);
      const results = await Promise.allSettled(
        props.campaigns.map(async campaign => ({
          id: campaign.id,
          metrics: await api.getCampaignMetrics(campaign.id)
        }))
      );

      if (!cancelled) {
        const next: Record<string, CampaignMetrics> = {};
        for (const result of results) {
          if (result.status === "fulfilled") {
            next[result.value.id] = result.value.metrics;
          }
        }
        setMetricsByCampaign(next);
        setMetricsLoading(false);
      }
    }

    void loadMetrics();
    return () => {
      cancelled = true;
    };
  }, [props.campaigns]);

  const aggregate = useMemo(() => {
    if (!props.campaigns) {
      return null;
    }

    const campaigns = props.campaigns;
    const allMetricsAvailable =
      campaigns.length === 0 ||
      campaigns.every(campaign => metricsByCampaign[campaign.id] !== undefined);

    const impressions = allMetricsAvailable
      ? campaigns.reduce((total, campaign) => total + (metricsByCampaign[campaign.id]?.impressions ?? 0), 0)
      : null;
    const clicks = allMetricsAvailable
      ? campaigns.reduce((total, campaign) => total + (metricsByCampaign[campaign.id]?.clicks ?? 0), 0)
      : null;

    return {
      count: campaigns.length,
      active: campaigns.filter(campaign => campaign.status.toUpperCase() === "ACTIVE").length,
      budget: campaigns.reduce((total, campaign) => total + campaign.budget, 0),
      spent: campaigns.reduce((total, campaign) => total + campaign.budgetSpent, 0),
      impressions,
      clicks,
      ctr: impressions !== null && clicks !== null
        ? (impressions > 0 ? (clicks / impressions) * 100 : 0)
        : null
    };
  }, [props.campaigns, metricsByCampaign]);

  const metricsComplete = Boolean(aggregate && aggregate.impressions !== null && aggregate.clicks !== null);

  return (
    <div className="stack dashboard-stack">
      <div className="dashboard-intro">
        <div>
          <span className="eyebrow">Centro de rendimiento</span>
          <h2>Resumen de publicidad</h2>
          <p>Indicadores calculados a partir de la API de ADSOLUSOL. Sin estimaciones ni métricas sintéticas.</p>
        </div>
        <span className="data-source-badge">FUENTE: API</span>
      </div>

      {props.campaignError && <ErrorPanel message={props.campaignError} />}

      <div className="stats-grid dashboard-stats">
        <StatCard
          label="Campañas"
          value={aggregate ? number(aggregate.count) : unavailable}
          detail="Registros devueltos por API"
        />
        <StatCard
          label="Campañas activas"
          value={aggregate ? number(aggregate.active) : unavailable}
          detail="Estado ACTIVE"
        />
        <StatCard
          label="Impresiones"
          value={metricsComplete ? number(aggregate!.impressions!) : unavailable}
          detail={metricsLoading ? "Consultando métricas…" : "Eventos reportados por API"}
        />
        <StatCard
          label="Clics"
          value={metricsComplete ? number(aggregate!.clicks!) : unavailable}
          detail={metricsLoading ? "Consultando métricas…" : "Eventos reportados por API"}
        />
        <StatCard
          label="CTR"
          value={metricsComplete ? `${aggregate!.ctr!.toLocaleString("es-MX", { maximumFractionDigits: 2 })}%` : unavailable}
          detail="Clics ÷ impresiones"
        />
        <StatCard
          label="Gasto registrado"
          value={aggregate ? money(aggregate.spent) : unavailable}
          detail="Suma de BudgetSpent"
        />
      </div>

      <div className="dashboard-layout">
        <div className="dashboard-primary stack">
          <Card>
            <div className="card-header">
              <div>
                <span className="eyebrow">Rendimiento</span>
                <h2>Actividad de campañas</h2>
              </div>
              <span className="muted">Datos actuales</span>
            </div>

            {props.campaigns && props.campaigns.length > 0 ? (
              <div className="campaign-performance-list">
                {props.campaigns.slice(0, 8).map(campaign => {
                  const metrics = metricsByCampaign[campaign.id];
                  return (
                    <div key={campaign.id} className="campaign-performance-row">
                      <div className="campaign-performance-name">
                        <strong>{campaign.name}</strong>
                        <small>{campaign.id}</small>
                      </div>
                      <div className="campaign-performance-metric">
                        <span>Presupuesto</span>
                        <strong>{money(campaign.budget)}</strong>
                      </div>
                      <div className="campaign-performance-metric">
                        <span>Impresiones</span>
                        <strong>{metrics ? number(metrics.impressions) : unavailable}</strong>
                      </div>
                      <div className="campaign-performance-metric">
                        <span>Clics</span>
                        <strong>{metrics ? number(metrics.clicks) : unavailable}</strong>
                      </div>
                      <StatusBadge value={campaign.status} />
                    </div>
                  );
                })}
              </div>
            ) : (
              <EmptyState
                title="Sin campañas disponibles"
                description="La API no devolvió campañas para esta cuenta, o todavía no hay registros."
              />
            )}
          </Card>

          <Card>
            <div className="card-header">
              <div>
                <span className="eyebrow">Tendencia</span>
                <h2>Rendimiento en el tiempo</h2>
              </div>
            </div>
            <EmptyState
              title="Histórico no disponible"
              description="La API actual no expone una serie temporal para graficar. No se dibujará una curva ficticia."
            />
          </Card>
        </div>

        <aside className="dashboard-rail stack">
          <Card>
            <div className="card-header">
              <div>
                <span className="eyebrow">Runtime</span>
                <h2>Estado del sistema</h2>
              </div>
            </div>

            {props.healthError && <ErrorPanel message={props.healthError} />}
            {!props.health && !props.healthError && <p className="muted">Verificando conexión…</p>}

            {props.health && (
              <div className="health-grid">
                <div className="health-row">
                  <span>Estado general</span>
                  <StatusBadge value={props.health.status} />
                </div>
                <div className="health-row">
                  <span>Base de datos</span>
                  <StatusBadge value={props.health.checks.database} />
                </div>
                <div className="health-row">
                  <span>SIC</span>
                  <StatusBadge value={props.health.checks.sicEngine} />
                </div>
                <div className="health-row">
                  <span>Última lectura</span>
                  <strong>{date(props.health.timestamp)}</strong>
                </div>
              </div>
            )}
          </Card>

          <Card>
            <div className="card-header">
              <div>
                <span className="eyebrow">Optimización</span>
                <h2>Oportunidades</h2>
              </div>
            </div>
            <EmptyState
              title="Sin recomendaciones verificadas"
              description="No hay datos de conversiones, CPA o ROAS disponibles en la API actual para justificar recomendaciones."
            />
          </Card>

          <Card>
            <div className="card-header">
              <div>
                <span className="eyebrow">Cobertura</span>
                <h2>Datos del panel</h2>
              </div>
            </div>
            <div className="health-grid">
              <div className="health-row">
                <span>Campañas</span>
                <StatusBadge value={props.campaigns ? "AVAILABLE" : "UNVERIFIED"} />
              </div>
              <div className="health-row">
                <span>Métricas</span>
                <StatusBadge value={metricsComplete ? "AVAILABLE" : metricsLoading ? "CHECKING" : "UNAVAILABLE"} />
              </div>
              <div className="health-row">
                <span>Histórico</span>
                <StatusBadge value="UNAVAILABLE" />
              </div>
              <div className="health-row">
                <span>Conversiones / ROAS</span>
                <StatusBadge value="UNAVAILABLE" />
              </div>
            </div>
          </Card>
        </aside>
      </div>
    </div>
  );
}
