import { useMemo } from "react";
import type { Campaign, HealthResponse } from "../types";
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

export function DashboardView(props: {
  campaigns: Campaign[] | null;
  campaignError: string | null;
  health: HealthResponse | null;
  healthError: string | null;
}) {
  const aggregate = useMemo(() => {
    if (!props.campaigns) {
      return null;
    }

    return {
      count: props.campaigns.length,
      active: props.campaigns.filter(
        campaign => campaign.status.toUpperCase() === "ACTIVE"
      ).length,
      budget: props.campaigns.reduce(
        (total, campaign) => total + campaign.budget,
        0
      ),
      spent: props.campaigns.reduce(
        (total, campaign) => total + campaign.budgetSpent,
        0
      )
    };
  }, [props.campaigns]);

  return (
    <div className="stack">
      {props.campaignError && (
        <ErrorPanel message={props.campaignError} />
      )}

      <div className="stats-grid">
        <StatCard
          label="CampaÃƒÂ±as"
          value={aggregate ? number(aggregate.count) : "UNVERIFIED"}
          detail="Registros devueltos por API"
        />

        <StatCard
          label="Activas"
          value={aggregate ? number(aggregate.active) : "UNVERIFIED"}
          detail="Estado ACTIVE"
        />

        <StatCard
          label="Presupuesto"
          value={aggregate ? money(aggregate.budget) : "UNVERIFIED"}
          detail="Total configurado"
        />

        <StatCard
          label="Gastado"
          value={aggregate ? money(aggregate.spent) : "UNVERIFIED"}
          detail="BudgetSpent real"
        />
      </div>

      <div className="dashboard-grid">
        <Card>
          <div className="card-header">
            <div>
              <span className="eyebrow">Runtime</span>
              <h2>Estado del sistema</h2>
            </div>
          </div>

          {props.healthError && (
            <ErrorPanel message={props.healthError} />
          )}

          {!props.health && !props.healthError && (
            <p className="muted">Verificando...</p>
          )}

          {props.health && (
            <div className="health-grid">
              <div className="health-row">
                <span>Estado general</span>
                <StatusBadge value={props.health.status} />
              </div>

              <div className="health-row">
                <span>SQLite</span>
                <StatusBadge value={props.health.checks.database} />
              </div>

              <div className="health-row">
                <span>SIC</span>
                <StatusBadge value={props.health.checks.sicEngine} />
              </div>

              <div className="health-row">
                <span>ÃƒÅ¡ltima lectura</span>
                <strong>{date(props.health.timestamp)}</strong>
              </div>
            </div>
          )}
        </Card>

        <Card>
          <div className="card-header">
            <div>
              <span className="eyebrow">CampaÃƒÂ±as</span>
              <h2>Actividad reciente</h2>
            </div>
          </div>

          {props.campaigns && props.campaigns.length > 0 ? (
            <div className="compact-list">
              {props.campaigns.slice(0, 6).map(campaign => (
                <div key={campaign.id} className="compact-item">
                  <div>
                    <strong>{campaign.name}</strong>
                    <small>{campaign.id}</small>
                  </div>

                  <StatusBadge value={campaign.status} />
                </div>
              ))}
            </div>
          ) : (
            <EmptyState
              title="Sin campaÃƒÂ±as"
              description="No hay campaÃƒÂ±as disponibles o el backend aÃƒÂºn no devolviÃƒÂ³ datos."
            />
          )}
        </Card>
      </div>
    </div>
  );
}

