import {
  useCallback,
  useEffect,
  useMemo,
  useState
} from "react";

import type {
  FormEvent,
  ReactNode
} from "react";

import {
  api,
  apiConfig,
  ApiError
} from "./api";

import type {
  Campaign,
  CampaignMetrics,
  Creative,
  HealthResponse
} from "./types";

type View =
  | "dashboard"
  | "campaigns"
  | "placements"
  | "creatives"
  | "assignments"
  | "serve"
  | "system";

const navigation: Array<{
  id: View;
  label: string;
  description: string;
}> = [
  {
    id: "dashboard",
    label: "Dashboard",
    description: "Estado general"
  },
  {
    id: "campaigns",
    label: "Campañas",
    description: "Presupuesto y estado"
  },
  {
    id: "placements",
    label: "Placements",
    description: "Inventario publicitario"
  },
  {
    id: "creatives",
    label: "Creativos",
    description: "Activos publicitarios"
  },
  {
    id: "assignments",
    label: "Asignaciones",
    description: "Campaña ↔ inventario"
  },
  {
    id: "serve",
    label: "Ad Serving",
    description: "Prueba de selección"
  },
  {
    id: "system",
    label: "Sistema",
    description: "API / SQLite / SIC"
  }
];

function errorMessage(
  error: unknown
): string {
  if (error instanceof ApiError) {
    return `${error.message} · HTTP ${error.status}`;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "Error desconocido.";
}

function money(
  value: number
): string {
  return new Intl.NumberFormat(
    "es-MX",
    {
      style: "currency",
      currency: "MXN",
      maximumFractionDigits: 4
    }
  ).format(value);
}

function number(
  value: number
): string {
  return new Intl.NumberFormat(
    "es-MX"
  ).format(value);
}

function date(
  value?: string | null
): string {
  if (!value) {
    return "—";
  }

  const parsed = new Date(value);

  if (
    Number.isNaN(parsed.getTime())
  ) {
    return "—";
  }

  return new Intl.DateTimeFormat(
    "es-MX",
    {
      dateStyle: "medium",
      timeStyle: "short"
    }
  ).format(parsed);
}

function toUtc(
  value: string
): string | null {
  if (!value) {
    return null;
  }

  const parsed = new Date(value);

  if (
    Number.isNaN(parsed.getTime())
  ) {
    return null;
  }

  return parsed.toISOString();
}

function Card(props: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <section
      className={`card ${
        props.className ?? ""
      }`}
    >
      {props.children}
    </section>
  );
}

function StatusBadge(props: {
  value: string;
}) {
  const normalized =
    props.value
      .trim()
      .toUpperCase();

  return (
    <span
      className={`status-badge status-${normalized}`}
    >
      {normalized}
    </span>
  );
}

function ErrorPanel(props: {
  message: string;
}) {
  return (
    <div className="error-panel">
      <strong>Error</strong>
      <span>{props.message}</span>
    </div>
  );
}

function EmptyState(props: {
  title: string;
  description: string;
}) {
  return (
    <div className="empty-state">
      <strong>{props.title}</strong>
      <span>
        {props.description}
      </span>
    </div>
  );
}

function StatCard(props: {
  label: string;
  value: ReactNode;
  detail: string;
}) {
  return (
    <Card className="stat-card">
      <span className="stat-label">
        {props.label}
      </span>

      <strong className="stat-value">
        {props.value}
      </strong>

      <span className="stat-detail">
        {props.detail}
      </span>
    </Card>
  );
}

export default function App() {
  const [
    view,
    setView
  ] =
    useState<View>("dashboard");

  const [
    campaigns,
    setCampaigns
  ] =
    useState<Campaign[] | null>(
      null
    );

  const [
    health,
    setHealth
  ] =
    useState<HealthResponse | null>(
      null
    );

  const [
    campaignsError,
    setCampaignsError
  ] =
    useState<string | null>(null);

  const [
    healthError,
    setHealthError
  ] =
    useState<string | null>(null);

  const [
    refreshing,
    setRefreshing
  ] =
    useState(false);

  const refresh =
    useCallback(async () => {
      setRefreshing(true);

      const [
        healthResult,
        campaignResult
      ] =
        await Promise.allSettled([
          api.getHealth(),
          api.listCampaigns()
        ]);

      if (
        healthResult.status ===
        "fulfilled"
      ) {
        setHealth(
          healthResult.value
        );
        setHealthError(null);
      } else {
        setHealth(null);
        setHealthError(
          errorMessage(
            healthResult.reason
          )
        );
      }

      if (
        campaignResult.status ===
        "fulfilled"
      ) {
        setCampaigns(
          campaignResult.value
        );
        setCampaignsError(null);
      } else {
        setCampaigns(null);
        setCampaignsError(
          errorMessage(
            campaignResult.reason
          )
        );
      }

      setRefreshing(false);
    }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const currentNavigation =
    navigation.find(
      item => item.id === view
    );

  const renderView = () => {
    switch (view) {
      case "dashboard":
        return (
          <DashboardView
            campaigns={campaigns}
            campaignError={
              campaignsError
            }
            health={health}
            healthError={
              healthError
            }
          />
        );

      case "campaigns":
        return (
          <CampaignsView
            campaigns={
              campaigns ?? []
            }
            loading={
              campaigns === null &&
              !campaignsError
            }
            error={
              campaignsError
            }
            onMutated={refresh}
          />
        );

      case "placements":
        return (
          <PlacementsView />
        );

      case "creatives":
        return (
          <CreativesView />
        );

      case "assignments":
        return (
          <AssignmentsView
            campaigns={
              campaigns ?? []
            }
          />
        );

      case "serve":
        return (
          <ServeView />
        );

      case "system":
        return (
          <SystemView
            health={health}
            error={healthError}
            onRefresh={refresh}
          />
        );
    }
  };

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">
            AD
          </div>

          <div>
            <strong>
              ADSOLUSOL
            </strong>

            <span>
              Advertising Engine
            </span>
          </div>
        </div>

        <nav className="navigation">
          {navigation.map(item => (
            <button
              key={item.id}
              type="button"
              className={
                item.id === view
                  ? "nav-item active"
                  : "nav-item"
              }
              onClick={() =>
                setView(item.id)
              }
            >
              <span>
                {item.label}
              </span>

              <small>
                {item.description}
              </small>
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <span>
            KLIK Soft PRO
          </span>
          <small>
            Software Direction
            <br />
            solusol.net
          </small>
        </div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div>
            <span className="eyebrow">
              ADSOLUSOL
            </span>

            <h1>
              {currentNavigation
                ?.label}
            </h1>
          </div>

          <div className="topbar-actions">
            <ConnectionIndicator
              health={health}
              error={
                healthError
              }
            />

            <button
              type="button"
              className="button button-secondary"
              disabled={refreshing}
              onClick={() =>
                void refresh()
              }
            >
              {refreshing
                ? "Actualizando..."
                : "Actualizar"}
            </button>
          </div>
        </header>

        <div className="content">
          {renderView()}
        </div>
      </main>
    </div>
  );
}

function ConnectionIndicator(
  props: {
    health: HealthResponse | null;
    error: string | null;
  }
) {
  if (props.error) {
    return (
      <span className="connection disconnected">
        API DISCONNECTED
      </span>
    );
  }

  if (!props.health) {
    return (
      <span className="connection checking">
        CHECKING
      </span>
    );
  }

  const status =
    props.health.status
      .toUpperCase();

  return (
    <span
      className={`connection ${
        status === "HEALTHY"
          ? "connected"
          : "degraded"
      }`}
    >
      {status}
    </span>
  );
}

function DashboardView(props: {
  campaigns:
    | Campaign[]
    | null;

  campaignError:
    | string
    | null;

  health:
    | HealthResponse
    | null;

  healthError:
    | string
    | null;
}) {
  const aggregate =
    useMemo(() => {
      if (!props.campaigns) {
        return null;
      }

      return {
        count:
          props.campaigns.length,

        active:
          props.campaigns.filter(
            campaign =>
              campaign.status
                .toUpperCase() ===
              "ACTIVE"
          ).length,

        budget:
          props.campaigns.reduce(
            (
              total,
              campaign
            ) =>
              total +
              campaign.budget,
            0
          ),

        spent:
          props.campaigns.reduce(
            (
              total,
              campaign
            ) =>
              total +
              campaign.budgetSpent,
            0
          )
      };
    }, [props.campaigns]);

  return (
    <div className="stack">
      {props.campaignError && (
        <ErrorPanel
          message={
            props.campaignError
          }
        />
      )}

      <div className="stats-grid">
        <StatCard
          label="Campañas"
          value={
            aggregate
              ? number(
                  aggregate.count
                )
              : "UNVERIFIED"
          }
          detail="Registros devueltos por API"
        />

        <StatCard
          label="Activas"
          value={
            aggregate
              ? number(
                  aggregate.active
                )
              : "UNVERIFIED"
          }
          detail="Estado ACTIVE"
        />

        <StatCard
          label="Presupuesto"
          value={
            aggregate
              ? money(
                  aggregate.budget
                )
              : "UNVERIFIED"
          }
          detail="Total configurado"
        />

        <StatCard
          label="Gastado"
          value={
            aggregate
              ? money(
                  aggregate.spent
                )
              : "UNVERIFIED"
          }
          detail="BudgetSpent real"
        />
      </div>

      <div className="dashboard-grid">
        <Card>
          <div className="card-header">
            <div>
              <span className="eyebrow">
                Runtime
              </span>

              <h2>
                Estado del sistema
              </h2>
            </div>
          </div>

          {props.healthError && (
            <ErrorPanel
              message={
                props.healthError
              }
            />
          )}

          {!props.health &&
            !props.healthError && (
              <p className="muted">
                Verificando...
              </p>
            )}

          {props.health && (
            <div className="health-grid">
              <div className="health-row">
                <span>
                  Estado general
                </span>

                <StatusBadge
                  value={
                    props.health
                      .status
                  }
                />
              </div>

              <div className="health-row">
                <span>
                  SQLite
                </span>

                <StatusBadge
                  value={
                    props.health
                      .checks
                      .database
                  }
                />
              </div>

              <div className="health-row">
                <span>
                  SIC
                </span>

                <StatusBadge
                  value={
                    props.health
                      .checks
                      .sicEngine
                  }
                />
              </div>

              <div className="health-row">
                <span>
                  Última lectura
                </span>

                <strong>
                  {date(
                    props.health
                      .timestamp
                  )}
                </strong>
              </div>
            </div>
          )}
        </Card>

        <Card>
          <div className="card-header">
            <div>
              <span className="eyebrow">
                Campañas
              </span>

              <h2>
                Actividad reciente
              </h2>
            </div>
          </div>

          {props.campaigns &&
          props.campaigns.length >
            0 ? (
            <div className="compact-list">
              {props.campaigns
                .slice(0, 6)
                .map(campaign => (
                  <div
                    key={
                      campaign.id
                    }
                    className="compact-item"
                  >
                    <div>
                      <strong>
                        {
                          campaign.name
                        }
                      </strong>

                      <small>
                        {
                          campaign.id
                        }
                      </small>
                    </div>

                    <StatusBadge
                      value={
                        campaign.status
                      }
                    />
                  </div>
                ))}
            </div>
          ) : (
            <EmptyState
              title="Sin campañas"
              description="No hay campañas disponibles o el backend aún no devolvió datos."
            />
          )}
        </Card>
      </div>
    </div>
  );
}

function CampaignsView(props: {
  campaigns: Campaign[];
  loading: boolean;
  error: string | null;
  onMutated: () => Promise<void>;
}) {
  const [
    form,
    setForm
  ] =
    useState({
      name: "",
      budget: "",
      cpm: "",
      cpc: "",
      startDate: "",
      endDate: ""
    });

  const [
    saving,
    setSaving
  ] =
    useState(false);

  const [
    mutationError,
    setMutationError
  ] =
    useState<string | null>(
      null
    );

  const [
    selectedMetrics,
    setSelectedMetrics
  ] =
    useState<{
      campaign: Campaign;
      metrics: CampaignMetrics;
    } | null>(null);

  const [
    metricsLoading,
    setMetricsLoading
  ] =
    useState<string | null>(
      null
    );

  async function submit(
    event: FormEvent
  ) {
    event.preventDefault();

    setSaving(true);
    setMutationError(null);

    try {
      await api.createCampaign({
        name: form.name.trim(),
        budget:
          Number(form.budget),
        costPerMille:
          Number(form.cpm),
        costPerClick:
          Number(form.cpc),
        startDateUtc:
          toUtc(form.startDate),
        endDateUtc:
          toUtc(form.endDate)
      });

      setForm({
        name: "",
        budget: "",
        cpm: "",
        cpc: "",
        startDate: "",
        endDate: ""
      });

      await props.onMutated();
    } catch (error) {
      setMutationError(
        errorMessage(error)
      );
    } finally {
      setSaving(false);
    }
  }

  async function changeStatus(
    campaign: Campaign,
    status: string
  ) {
    setMutationError(null);

    try {
      await api.updateCampaignStatus(
        campaign.id,
        status
      );

      await props.onMutated();
    } catch (error) {
      setMutationError(
        errorMessage(error)
      );
    }
  }

  async function loadMetrics(
    campaign: Campaign
  ) {
    setMetricsLoading(
      campaign.id
    );
    setMutationError(null);

    try {
      const metrics =
        await api.getCampaignMetrics(
          campaign.id
        );

      setSelectedMetrics({
        campaign,
        metrics
      });
    } catch (error) {
      setMutationError(
        errorMessage(error)
      );
    } finally {
      setMetricsLoading(null);
    }
  }

  return (
    <div className="stack">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Campaign management
            </span>

            <h2>
              Nueva campaña
            </h2>
          </div>
        </div>

        {mutationError && (
          <ErrorPanel
            message={
              mutationError
            }
          />
        )}

        <form
          className="form-grid"
          onSubmit={submit}
        >
          <label className="field field-wide">
            <span>Nombre</span>

            <input
              required
              value={form.name}
              onChange={event =>
                setForm({
                  ...form,
                  name:
                    event.target
                      .value
                })
              }
              placeholder="Campaña"
            />
          </label>

          <label className="field">
            <span>
              Presupuesto
            </span>

            <input
              required
              min="0.01"
              step="0.01"
              type="number"
              value={
                form.budget
              }
              onChange={event =>
                setForm({
                  ...form,
                  budget:
                    event.target
                      .value
                })
              }
            />
          </label>

          <label className="field">
            <span>CPM</span>

            <input
              required
              min="0"
              step="0.0001"
              type="number"
              value={form.cpm}
              onChange={event =>
                setForm({
                  ...form,
                  cpm:
                    event.target
                      .value
                })
              }
            />
          </label>

          <label className="field">
            <span>CPC</span>

            <input
              required
              min="0"
              step="0.0001"
              type="number"
              value={form.cpc}
              onChange={event =>
                setForm({
                  ...form,
                  cpc:
                    event.target
                      .value
                })
              }
            />
          </label>

          <label className="field">
            <span>
              Inicio
            </span>

            <input
              type="datetime-local"
              value={
                form.startDate
              }
              onChange={event =>
                setForm({
                  ...form,
                  startDate:
                    event.target
                      .value
                })
              }
            />
          </label>

          <label className="field">
            <span>
              Fin
            </span>

            <input
              type="datetime-local"
              value={
                form.endDate
              }
              onChange={event =>
                setForm({
                  ...form,
                  endDate:
                    event.target
                      .value
                })
              }
            />
          </label>

          <div className="form-actions field-wide">
            <button
              className="button button-primary"
              type="submit"
              disabled={saving}
            >
              {saving
                ? "Guardando..."
                : "Crear campaña"}
            </button>
          </div>
        </form>
      </Card>

      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Persistencia
            </span>

            <h2>
              Campañas
            </h2>
          </div>

          <span className="record-count">
            {
              props.campaigns
                .length
            }{" "}
            registros
          </span>
        </div>

        {props.error && (
          <ErrorPanel
            message={
              props.error
            }
          />
        )}

        {props.loading && (
          <p className="muted">
            Cargando...
          </p>
        )}

        {!props.loading &&
        props.campaigns.length ===
          0 ? (
          <EmptyState
            title="Sin campañas"
            description="La API no devolvió campañas."
          />
        ) : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>Campaña</th>
                  <th>Estado</th>
                  <th>
                    Presupuesto
                  </th>
                  <th>Gastado</th>
                  <th>CPM</th>
                  <th>CPC</th>
                  <th>Acciones</th>
                </tr>
              </thead>

              <tbody>
                {props.campaigns.map(
                  campaign => (
                    <tr
                      key={
                        campaign.id
                      }
                    >
                      <td>
                        <strong>
                          {
                            campaign.name
                          }
                        </strong>

                        <small className="table-id">
                          {
                            campaign.id
                          }
                        </small>
                      </td>

                      <td>
                        <StatusBadge
                          value={
                            campaign.status
                          }
                        />
                      </td>

                      <td>
                        {money(
                          campaign.budget
                        )}
                      </td>

                      <td>
                        {money(
                          campaign.budgetSpent
                        )}
                      </td>

                      <td>
                        {money(
                          campaign.costPerMille
                        )}
                      </td>

                      <td>
                        {money(
                          campaign.costPerClick
                        )}
                      </td>

                      <td>
                        <div className="row-actions">
                          <select
                            value={
                              campaign.status
                            }
                            onChange={event =>
                              void changeStatus(
                                campaign,
                                event
                                  .target
                                  .value
                              )
                            }
                          >
                            <option value="SCHEDULED">
                              SCHEDULED
                            </option>

                            <option value="ACTIVE">
                              ACTIVE
                            </option>

                            <option value="PAUSED">
                              PAUSED
                            </option>

                            <option value="COMPLETED">
                              COMPLETED
                            </option>
                          </select>

                          <button
                            type="button"
                            className="button button-small"
                            disabled={
                              metricsLoading ===
                              campaign.id
                            }
                            onClick={() =>
                              void loadMetrics(
                                campaign
                              )
                            }
                          >
                            Métricas
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                )}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {selectedMetrics && (
        <Card>
          <div className="card-header">
            <div>
              <span className="eyebrow">
                Métricas
              </span>

              <h2>
                {
                  selectedMetrics
                    .campaign.name
                }
              </h2>
            </div>

            <button
              type="button"
              className="button button-secondary button-small"
              onClick={() =>
                setSelectedMetrics(
                  null
                )
              }
            >
              Cerrar
            </button>
          </div>

          <div className="stats-grid">
            <StatCard
              label="Impresiones"
              value={number(
                selectedMetrics
                  .metrics
                  .impressions
              )}
              detail="Eventos aceptados"
            />

            <StatCard
              label="Clicks"
              value={number(
                selectedMetrics
                  .metrics.clicks
              )}
              detail="Eventos aceptados"
            />

            <StatCard
              label="CTR"
              value={`${selectedMetrics.metrics.ctr}%`}
              detail="Servidor autoritativo"
            />

            <StatCard
              label="BudgetSpent"
              value={money(
                selectedMetrics
                  .metrics
                  .budgetSpent
              )}
              detail="Gasto persistido"
            />
          </div>
        </Card>
      )}
    </div>
  );
}

function PlacementsView() {
  const [
    form,
    setForm
  ] =
    useState({
      placementCode: "",
      name: "",
      isEnabled: true
    });

  const [
    createdId,
    setCreatedId
  ] =
    useState<number | null>(
      null
    );

  const [
    error,
    setError
  ] =
    useState<string | null>(
      null
    );

  const [
    saving,
    setSaving
  ] =
    useState(false);

  async function submit(
    event: FormEvent
  ) {
    event.preventDefault();

    setSaving(true);
    setError(null);
    setCreatedId(null);

    try {
      const result =
        await api.createPlacement({
          placementCode:
            form.placementCode.trim(),
          name:
            form.name.trim(),
          isEnabled:
            form.isEnabled
        });

      setCreatedId(result.id);

      setForm({
        placementCode: "",
        name: "",
        isEnabled: true
      });
    } catch (error) {
      setError(
        errorMessage(error)
      );
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="two-column">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Inventory
            </span>

            <h2>
              Crear placement
            </h2>
          </div>
        </div>

        {error && (
          <ErrorPanel
            message={error}
          />
        )}

        {createdId !== null && (
          <div className="success-panel">
            Placement creado.
            ID real:{" "}
            <strong>
              {createdId}
            </strong>
          </div>
        )}

        <form
          className="form-grid"
          onSubmit={submit}
        >
          <label className="field field-wide">
            <span>
              Placement code
            </span>

            <input
              required
              value={
                form.placementCode
              }
              onChange={event =>
                setForm({
                  ...form,
                  placementCode:
                    event.target
                      .value
                })
              }
              placeholder="HEADER_LEADERBOARD"
            />
          </label>

          <label className="field field-wide">
            <span>Nombre</span>

            <input
              required
              value={form.name}
              onChange={event =>
                setForm({
                  ...form,
                  name:
                    event.target
                      .value
                })
              }
            />
          </label>

          <label className="checkbox-field field-wide">
            <input
              type="checkbox"
              checked={
                form.isEnabled
              }
              onChange={event =>
                setForm({
                  ...form,
                  isEnabled:
                    event.target
                      .checked
                })
              }
            />

            <span>
              Placement habilitado
            </span>
          </label>

          <div className="form-actions field-wide">
            <button
              type="submit"
              className="button button-primary"
              disabled={saving}
            >
              {saving
                ? "Guardando..."
                : "Crear placement"}
            </button>
          </div>
        </form>
      </Card>

      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Zero Synthetic
            </span>

            <h2>
              Listado
            </h2>
          </div>
        </div>

        <EmptyState
          title="GET no disponible"
          description="El backend actual no expone todavía un endpoint de listado de placements. La UI no inventará registros ni mantendrá un catálogo sintético."
        />
      </Card>
    </div>
  );
}

function CreativesView() {
  const [
    form,
    setForm
  ] =
    useState({
      name: "",
      contentUrl: "",
      targetUrl: "",
      isEnabled: true
    });

  const [
    created,
    setCreated
  ] =
    useState<Creative | null>(
      null
    );

  const [
    error,
    setError
  ] =
    useState<string | null>(
      null
    );

  const [
    saving,
    setSaving
  ] =
    useState(false);

  async function submit(
    event: FormEvent
  ) {
    event.preventDefault();

    setSaving(true);
    setError(null);
    setCreated(null);

    try {
      const result =
        await api.createCreative({
          name:
            form.name.trim(),
          contentUrl:
            form.contentUrl.trim(),
          targetUrl:
            form.targetUrl.trim(),
          isEnabled:
            form.isEnabled
        });

      setCreated(result);

      setForm({
        name: "",
        contentUrl: "",
        targetUrl: "",
        isEnabled: true
      });
    } catch (error) {
      setError(
        errorMessage(error)
      );
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="two-column">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Creative delivery
            </span>

            <h2>
              Crear creativo
            </h2>
          </div>
        </div>

        {error && (
          <ErrorPanel
            message={error}
          />
        )}

        {created && (
          <div className="success-panel">
            Creative creado.
            ID real:{" "}
            <strong>
              {created.id}
            </strong>
          </div>
        )}

        <form
          className="form-grid"
          onSubmit={submit}
        >
          <label className="field field-wide">
            <span>Nombre</span>

            <input
              required
              value={form.name}
              onChange={event =>
                setForm({
                  ...form,
                  name:
                    event.target
                      .value
                })
              }
            />
          </label>

          <label className="field field-wide">
            <span>
              Content URL
            </span>

            <input
              required
              type="url"
              value={
                form.contentUrl
              }
              onChange={event =>
                setForm({
                  ...form,
                  contentUrl:
                    event.target
                      .value
                })
              }
            />
          </label>

          <label className="field field-wide">
            <span>
              Target URL
            </span>

            <input
              required
              type="url"
              value={
                form.targetUrl
              }
              onChange={event =>
                setForm({
                  ...form,
                  targetUrl:
                    event.target
                      .value
                })
              }
            />
          </label>

          <label className="checkbox-field field-wide">
            <input
              type="checkbox"
              checked={
                form.isEnabled
              }
              onChange={event =>
                setForm({
                  ...form,
                  isEnabled:
                    event.target
                      .checked
                })
              }
            />

            <span>
              Creative habilitado
            </span>
          </label>

          <div className="form-actions field-wide">
            <button
              type="submit"
              className="button button-primary"
              disabled={saving}
            >
              {saving
                ? "Guardando..."
                : "Crear creativo"}
            </button>
          </div>
        </form>
      </Card>

      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Zero Synthetic
            </span>

            <h2>
              Catálogo
            </h2>
          </div>
        </div>

        <EmptyState
          title="GET no disponible"
          description="El backend actual no expone todavía un endpoint para listar creativos. La UI muestra únicamente respuestas reales de creación."
        />
      </Card>
    </div>
  );
}

function AssignmentsView(props: {
  campaigns: Campaign[];
}) {
  const [
    type,
    setType
  ] =
    useState<
      "placement" | "creative"
    >("placement");

  const [
    campaignId,
    setCampaignId
  ] =
    useState("");

  const [
    entityId,
    setEntityId
  ] =
    useState("");

  const [
    error,
    setError
  ] =
    useState<string | null>(
      null
    );

  const [
    success,
    setSuccess
  ] =
    useState<string | null>(
      null
    );

  const [
    saving,
    setSaving
  ] =
    useState(false);

  async function submit(
    event: FormEvent
  ) {
    event.preventDefault();

    setSaving(true);
    setError(null);
    setSuccess(null);

    try {
      const payload = {
        campaignId,
        entityId:
          Number(entityId)
      };

      if (
        type === "placement"
      ) {
        await api.assignPlacement(
          payload
        );
      } else {
        await api.assignCreative(
          payload
        );
      }

      setSuccess(
        type === "placement"
          ? "Placement asociado correctamente."
          : "Creative asociado correctamente."
      );

      setEntityId("");
    } catch (error) {
      setError(
        errorMessage(error)
      );
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <div className="card-header">
        <div>
          <span className="eyebrow">
            Relationships
          </span>

          <h2>
            Asignar recurso
          </h2>
        </div>
      </div>

      {error && (
        <ErrorPanel
          message={error}
        />
      )}

      {success && (
        <div className="success-panel">
          {success}
        </div>
      )}

      <form
        className="form-grid"
        onSubmit={submit}
      >
        <label className="field">
          <span>
            Tipo
          </span>

          <select
            value={type}
            onChange={event =>
              setType(
                event.target
                  .value as
                  | "placement"
                  | "creative"
              )
            }
          >
            <option value="placement">
              Placement
            </option>

            <option value="creative">
              Creative
            </option>
          </select>
        </label>

        <label className="field">
          <span>
            Campaña
          </span>

          <select
            required
            value={
              campaignId
            }
            onChange={event =>
              setCampaignId(
                event.target
                  .value
              )
            }
          >
            <option value="">
              Seleccionar
            </option>

            {props.campaigns.map(
              campaign => (
                <option
                  key={
                    campaign.id
                  }
                  value={
                    campaign.id
                  }
                >
                  {campaign.name}
                </option>
              )
            )}
          </select>
        </label>

        <label className="field">
          <span>
            Entity ID
          </span>

          <input
            required
            min="1"
            step="1"
            type="number"
            value={entityId}
            onChange={event =>
              setEntityId(
                event.target
                  .value
              )
            }
          />
        </label>

        <div className="form-actions field-wide">
          <button
            type="submit"
            className="button button-primary"
            disabled={
              saving ||
              !campaignId
            }
          >
            {saving
              ? "Asignando..."
              : "Asignar"}
          </button>
        </div>
      </form>
    </Card>
  );
}

function ServeView() {
  const [
    placementCode,
    setPlacementCode
  ] =
    useState("");

  const [
    creative,
    setCreative
  ] =
    useState<Creative | null>(
      null
    );

  const [
    noAd,
    setNoAd
  ] =
    useState(false);

  const [
    error,
    setError
  ] =
    useState<string | null>(
      null
    );

  const [
    loading,
    setLoading
  ] =
    useState(false);

  async function submit(
    event: FormEvent
  ) {
    event.preventDefault();

    setLoading(true);
    setError(null);
    setCreative(null);
    setNoAd(false);

    try {
      const result =
        await api.serve(
          placementCode.trim()
        );

      if (!result) {
        setNoAd(true);
      } else {
        setCreative(result);
      }
    } catch (error) {
      setError(
        errorMessage(error)
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="two-column">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Serving engine
            </span>

            <h2>
              Solicitar anuncio
            </h2>
          </div>
        </div>

        {error && (
          <ErrorPanel
            message={error}
          />
        )}

        <form
          className="form-grid"
          onSubmit={submit}
        >
          <label className="field field-wide">
            <span>
              Placement code
            </span>

            <input
              required
              value={
                placementCode
              }
              onChange={event =>
                setPlacementCode(
                  event.target
                    .value
                )
              }
            />
          </label>

          <div className="form-actions field-wide">
            <button
              type="submit"
              className="button button-primary"
              disabled={loading}
            >
              {loading
                ? "Consultando..."
                : "Solicitar anuncio"}
            </button>
          </div>
        </form>
      </Card>

      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Decision
            </span>

            <h2>
              Resultado
            </h2>
          </div>
        </div>

        {noAd && (
          <EmptyState
            title="NO_AD_AVAILABLE"
            description="El backend no encontró un anuncio elegible. La UI no genera fallback ficticio."
          />
        )}

        {!noAd &&
          !creative && (
            <EmptyState
              title="Sin decisión"
              description="Ejecuta una consulta de serving."
            />
          )}

        {creative && (
          <div className="creative-result">
            <div>
              <span className="eyebrow">
                Creative ID
              </span>

              <strong>
                {creative.id}
              </strong>
            </div>

            <h3>
              {creative.name}
            </h3>

            <dl>
              <div>
                <dt>
                  Content URL
                </dt>
                <dd>
                  {creative.contentUrl}
                </dd>
              </div>

              <div>
                <dt>
                  Target URL
                </dt>
                <dd>
                  {creative.targetUrl}
                </dd>
              </div>

              <div>
                <dt>
                  Enabled
                </dt>
                <dd>
                  {String(
                    creative.isEnabled
                  )}
                </dd>
              </div>
            </dl>
          </div>
        )}
      </Card>
    </div>
  );
}

function SystemView(props: {
  health:
    | HealthResponse
    | null;

  error:
    | string
    | null;

  onRefresh:
    () => Promise<void>;
}) {
  return (
    <div className="two-column">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Configuration
            </span>

            <h2>
              API
            </h2>
          </div>
        </div>

        <div className="definition-list">
          <div>
            <span>
              Base URL
            </span>

            <strong>
              {
                apiConfig.baseUrl
              }
            </strong>
          </div>

          <div>
            <span>
              Authentication
            </span>

            <strong>
              BACKEND AUTHORITY
            </strong>
          </div>

          <div>
            <span>
              Private keys
            </span>

            <strong>
              NEVER IN UI
            </strong>
          </div>

          <div>
            <span>
              Synthetic data
            </span>

            <strong>
              DISABLED
            </strong>
          </div>
        </div>
      </Card>

      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">
              Health
            </span>

            <h2>
              Dependencias
            </h2>
          </div>

          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() =>
              void props.onRefresh()
            }
          >
            Actualizar
          </button>
        </div>

        {props.error && (
          <ErrorPanel
            message={
              props.error
            }
          />
        )}

        {props.health && (
          <div className="health-grid">
            <div className="health-row">
              <span>
                API status
              </span>

              <StatusBadge
                value={
                  props.health
                    .status
                }
              />
            </div>

            <div className="health-row">
              <span>
                SQLite
              </span>

              <StatusBadge
                value={
                  props.health
                    .checks.database
                }
              />
            </div>

            <div className="health-row">
              <span>SIC</span>

              <StatusBadge
                value={
                  props.health
                    .checks
                    .sicEngine
                }
              />
            </div>
          </div>
        )}

        {!props.health &&
          !props.error && (
            <p className="muted">
              Verificando...
            </p>
          )}
      </Card>
    </div>
  );
}