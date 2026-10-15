import { useCallback, useEffect, useState } from "react";
import { api, ApiError } from "./api";
import type { Campaign, HealthResponse } from "./types";
import {
  ConnectionIndicator,
  errorMessage
} from "./components/Common";
import { LoginView } from "./views/LoginView";
import { DashboardView } from "./views/DashboardView";
import { CampaignsView } from "./views/CampaignsView";
import { PlacementsView } from "./views/PlacementsView";
import { CreativesView } from "./views/CreativesView";
import { AssignmentsView } from "./views/AssignmentsView";
import { ServeView } from "./views/ServeView";
import { SystemView } from "./views/SystemView";
import { SettingsView } from "./views/SettingsView";

type View =
  | "dashboard"
  | "campaigns"
  | "placements"
  | "creatives"
  | "assignments"
  | "serve"
  | "system"
  | "settings";

const dashboardPreview =
  import.meta.env.DEV &&
  new URLSearchParams(window.location.search).get("preview") === "dashboard";

const navigation: Array<{
  id: View;
  label: string;
  description: string;
}> = [
  { id: "dashboard", label: "Dashboard", description: "Estado general" },
  { id: "campaigns", label: "Campañas", description: "Presupuesto y estado" },
  { id: "placements", label: "Placements", description: "Inventario publicitario" },
  { id: "creatives", label: "Creativos", description: "Activos publicitarios" },
  { id: "assignments", label: "Asignaciones", description: "Campaña ↔ inventario" },
  { id: "serve", label: "Ad Serving", description: "Prueba de selección" },
  { id: "system", label: "Sistema", description: "API / SQLite / SIC" },
  { id: "settings", label: "Configuración", description: "Parámetros del tenant" }
];

export default function App() {
  const [session, setSession] = useState<string | null | undefined>(undefined);
  const [view, setView] = useState<View>("dashboard");
  const [campaigns, setCampaigns] = useState<Campaign[] | null>(null);
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [campaignsError, setCampaignsError] = useState<string | null>(null);
  const [healthError, setHealthError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    if (dashboardPreview) {
      return;
    }

    void api
      .getSession()
      .then(result => setSession(result.tenantId))
      .catch(() => setSession(null));
  }, []);

  const refresh = useCallback(async () => {
    if (dashboardPreview) {
      return;
    }

    setRefreshing(true);

    const [healthResult, campaignResult] = await Promise.allSettled([
      api.getHealth(),
      session ? api.listCampaigns() : Promise.resolve(null)
    ]);

    if (healthResult.status === "fulfilled") {
      setHealth(healthResult.value);
      setHealthError(null);
    } else {
      setHealth(null);
      setHealthError(errorMessage(healthResult.reason));
    }

    if (campaignResult.status === "fulfilled" && campaignResult.value) {
      setCampaigns(campaignResult.value);
      setCampaignsError(null);
    } else if (!session) {
      setCampaigns(null);
      setCampaignsError(null);
    } else {
      setCampaigns(null);
      setCampaignsError(
        campaignResult.status === "rejected"
          ? errorMessage(campaignResult.reason)
          : "No se pudieron cargar campañas."
      );
      if (
        campaignResult.status === "rejected" &&
        campaignResult.reason instanceof ApiError &&
        campaignResult.reason.status === 401
      ) {
        setSession(null);
      }
    }

    setRefreshing(false);
  }, [session]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const currentNavigation = navigation.find(item => item.id === view);

  const renderView = () => {
    switch (view) {
      case "dashboard":
        return (
          <DashboardView
            campaigns={campaigns}
            campaignError={campaignsError}
            health={health}
            healthError={healthError}
          />
        );
      case "campaigns":
        return (
          <CampaignsView
            campaigns={campaigns ?? []}
            loading={campaigns === null && !campaignsError}
            error={campaignsError}
            onMutated={refresh}
          />
        );
      case "placements":
        return <PlacementsView />;
      case "creatives":
        return <CreativesView />;
      case "assignments":
        return <AssignmentsView campaigns={campaigns ?? []} />;
      case "serve":
        return <ServeView />;
      case "system":
        return <SystemView health={health} error={healthError} onRefresh={refresh} />;
      case "settings":
        return <SettingsView />;
    }
  };

  return (
    <div className={dashboardPreview ? "app-shell dashboard-preview" : "app-shell"}>
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">AD</div>
          <div>
            <strong>ADSOLUSOL</strong>
            <span>Advertising Engine</span>
          </div>
        </div>

        <nav className="navigation">
          {navigation.map(item => (
            <button
              key={item.id}
              type="button"
              disabled={!session}
              className={item.id === view ? "nav-item active" : "nav-item"}
              onClick={() => setView(item.id)}
            >
              <span>{item.label}</span>
              <small>{item.description}</small>
            </button>
          ))}
        </nav>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div>
            <span className="eyebrow">ADSOLUSOL</span>
            <h1>{currentNavigation?.label}</h1>
          </div>

          <div className="topbar-actions">
            {session && (
              <>
                <span className="muted">Tenant {session}</span>
                <button
                  type="button"
                  className="button button-secondary"
                  onClick={() => {
                    void api.logout().then(() => setSession(null));
                  }}
                >
                  Salir
                </button>
              </>
            )}
            {dashboardPreview ? (
              <span className="preview-label">VISTA LOCAL · API SIN CONSULTAR</span>
            ) : (
              <ConnectionIndicator health={health} error={healthError} />
            )}

            <button
              type="button"
              className="button button-secondary"
              disabled={refreshing || dashboardPreview}
              onClick={() => void refresh()}
            >
              {refreshing ? "Actualizando..." : "Actualizar"}
            </button>
          </div>
        </header>

        <div className="content">
          {dashboardPreview ? (
            <DashboardView
              campaigns={null}
              campaignError={null}
              health={null}
              healthError={null}
              preview
            />
          ) : session === undefined ? (
            <p className="muted">Verificando acceso...</p>
          ) : session === null ? (
            <LoginView onLogin={setSession} />
          ) : renderView()}
        </div>
      </main>
    </div>
  );
}
