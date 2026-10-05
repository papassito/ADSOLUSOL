import { apiConfig } from "../api";
import type { HealthResponse } from "../types";
import { Card, ErrorPanel, StatusBadge } from "../components/Common";

export function SystemView(props: {
  health: HealthResponse | null;
  error: string | null;
  onRefresh: () => Promise<void>;
}) {
  return (
    <div className="two-column">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">Configuration</span>
            <h2>API</h2>
          </div>
        </div>

        <div className="definition-list">
          <div><span>Base URL</span><strong>{apiConfig.baseUrl}</strong></div>
          <div><span>Authentication</span><strong>BACKEND AUTHORITY</strong></div>
          <div><span>Private keys</span><strong>NEVER IN UI</strong></div>
          <div><span>Synthetic data</span><strong>DISABLED</strong></div>
        </div>
      </Card>

      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">Health</span>
            <h2>Dependencias</h2>
          </div>

          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => void props.onRefresh()}
          >
            Actualizar
          </button>
        </div>

        {props.error && <ErrorPanel message={props.error} />}

        {props.health && (
          <div className="health-grid">
            <div className="health-row"><span>API status</span><StatusBadge value={props.health.status} /></div>
            <div className="health-row"><span>SQLite</span><StatusBadge value={props.health.checks.database} /></div>
            <div className="health-row"><span>SIC</span><StatusBadge value={props.health.checks.sicEngine} /></div>
          </div>
        )}

        {!props.health && !props.error && (
          <p className="muted">Verificando...</p>
        )}
      </Card>
    </div>
  );
}