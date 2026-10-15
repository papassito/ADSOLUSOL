import { useState } from "react";
import type { FormEvent } from "react";
import { api } from "../api";
import type { Campaign, CampaignMetrics } from "../types";
import {
  Card,
  EmptyState,
  ErrorPanel,
  StatCard,
  StatusBadge,
  errorMessage,
  money,
  number,
  toUtc
} from "../components/Common";

export function CampaignsView(props: {
  campaigns: Campaign[];
  loading: boolean;
  error: string | null;
  onMutated: () => Promise<void>;
}) {
  const [form, setForm] = useState({
    name: "",
    budget: "",
    cpm: "",
    cpc: "",
    startDate: "",
    endDate: ""
  });

  const [saving, setSaving] = useState(false);
  const [mutationError, setMutationError] = useState<string | null>(null);
  const [selectedMetrics, setSelectedMetrics] = useState<{
    campaign: Campaign;
    metrics: CampaignMetrics;
  } | null>(null);
  const [metricsLoading, setMetricsLoading] = useState<string | null>(null);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setMutationError(null);

    try {
      await api.createCampaign({
        name: form.name.trim(),
        budget: Number(form.budget),
        costPerMille: Number(form.cpm),
        costPerClick: Number(form.cpc),
        startDateUtc: toUtc(form.startDate),
        endDateUtc: toUtc(form.endDate)
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
      setMutationError(errorMessage(error));
    } finally {
      setSaving(false);
    }
  }

  async function changeStatus(campaign: Campaign, status: string) {
    setMutationError(null);

    try {
      await api.updateCampaignStatus(campaign.id, status);
      await props.onMutated();
    } catch (error) {
      setMutationError(errorMessage(error));
    }
  }

  async function loadMetrics(campaign: Campaign) {
    setMetricsLoading(campaign.id);
    setMutationError(null);

    try {
      const metrics = await api.getCampaignMetrics(campaign.id);
      setSelectedMetrics({
        campaign,
        metrics
      });
    } catch (error) {
      setMutationError(errorMessage(error));
    } finally {
      setMetricsLoading(null);
    }
  }

  return (
    <div className="stack">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">Campaign management</span>
            <h2>Nueva campaña</h2>
          </div>
        </div>

        {mutationError && (
          <ErrorPanel message={mutationError} />
        )}

        <form className="form-grid" onSubmit={submit}>
          <label className="field field-wide">
            <span>Nombre</span>
            <input
              required
              value={form.name}
              onChange={event => setForm({ ...form, name: event.target.value })}
              placeholder="Campaña"
            />
          </label>

          <label className="field">
            <span>Presupuesto</span>
            <input
              required
              min="0.01"
              step="0.01"
              type="number"
              value={form.budget}
              onChange={event => setForm({ ...form, budget: event.target.value })}
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
              onChange={event => setForm({ ...form, cpm: event.target.value })}
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
              onChange={event => setForm({ ...form, cpc: event.target.value })}
            />
          </label>

          <label className="field">
            <span>Inicio</span>
            <input
              type="datetime-local"
              value={form.startDate}
              onChange={event => setForm({ ...form, startDate: event.target.value })}
            />
          </label>

          <label className="field">
            <span>Fin</span>
            <input
              type="datetime-local"
              value={form.endDate}
              onChange={event => setForm({ ...form, endDate: event.target.value })}
            />
          </label>

          <div className="form-actions field-wide">
            <button className="button button-primary" type="submit" disabled={saving}>
              {saving ? "Guardando..." : "Crear campaña"}
            </button>
          </div>
        </form>
      </Card>

      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">Persistencia</span>
            <h2>Campañas</h2>
          </div>

          <span className="record-count">
            {props.campaigns.length} registros
          </span>
        </div>

        {props.error && (
          <ErrorPanel message={props.error} />
        )}

        {props.loading && (
          <p className="muted">Cargando...</p>
        )}

        {!props.loading && props.campaigns.length === 0 ? (
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
                  <th>Presupuesto</th>
                  <th>Gastado</th>
                  <th>CPM</th>
                  <th>CPC</th>
                  <th>Acciones</th>
                </tr>
              </thead>

              <tbody>
                {props.campaigns.map(campaign => (
                  <tr key={campaign.id}>
                    <td>
                      <strong>{campaign.name}</strong>
                      <small className="table-id">{campaign.id}</small>
                    </td>

                    <td>
                      <StatusBadge value={campaign.status} />
                    </td>

                    <td>{money(campaign.budget)}</td>
                    <td>{money(campaign.budgetSpent)}</td>
                    <td>{money(campaign.costPerMille)}</td>
                    <td>{money(campaign.costPerClick)}</td>

                    <td>
                      <div className="row-actions">
                        <select
                          value={campaign.status}
                          onChange={event => void changeStatus(campaign, event.target.value)}
                        >
                          <option value="SCHEDULED">SCHEDULED</option>
                          <option value="ACTIVE">ACTIVE</option>
                          <option value="PAUSED">PAUSED</option>
                          <option value="COMPLETED">COMPLETED</option>
                        </select>

                        <button
                          type="button"
                          className="button button-small"
                          disabled={metricsLoading === campaign.id}
                          onClick={() => void loadMetrics(campaign)}
                        >
                          Métricas
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {selectedMetrics && (
        <Card>
          <div className="card-header">
            <div>
              <span className="eyebrow">Métricas</span>
              <h2>{selectedMetrics.campaign.name}</h2>
            </div>

            <button type="button" className="button button-secondary button-small" onClick={() => setSelectedMetrics(null)}>
              Cerrar
            </button>
          </div>

          <div className="stats-grid">
            <StatCard label="Impresiones" value={number(selectedMetrics.metrics.impressions)} detail="Eventos aceptados" />
            <StatCard label="Clicks" value={number(selectedMetrics.metrics.clicks)} detail="Eventos aceptados" />
            <StatCard label="CTR" value={`${selectedMetrics.metrics.ctr}%`} detail="Servidor autoritativo" />
            <StatCard label="BudgetSpent" value={money(selectedMetrics.metrics.budgetSpent)} detail="Gasto persistido" />
          </div>
        </Card>
      )}
    </div>
  );
}

