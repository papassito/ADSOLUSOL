import { useState } from "react";
import type { FormEvent } from "react";
import { api } from "../api";
import type { Campaign } from "../types";
import { Card, ErrorPanel, errorMessage } from "../components/Common";

export function AssignmentsView(props: { campaigns: Campaign[] }) {
  const [type, setType] = useState<"placement" | "creative">("placement");
  const [campaignId, setCampaignId] = useState("");
  const [entityId, setEntityId] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(null);
    setSuccess(null);

    try {
      const payload = {
        campaignId,
        entityId: Number(entityId)
      };

      if (type === "placement") {
        await api.assignPlacement(payload);
      } else {
        await api.assignCreative(payload);
      }

      setSuccess(
        type === "placement"
          ? "Placement asociado correctamente."
          : "Creative asociado correctamente."
      );
      setEntityId("");
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <div className="card-header">
        <div>
          <span className="eyebrow">Relationships</span>
          <h2>Asignar recurso</h2>
        </div>
      </div>

      {error && <ErrorPanel message={error} />}
      {success && <div className="success-panel">{success}</div>}

      <form className="form-grid" onSubmit={submit}>
        <label className="field">
          <span>Tipo</span>
          <select value={type} onChange={event => setType(event.target.value as "placement" | "creative")}>
            <option value="placement">Placement</option>
            <option value="creative">Creative</option>
          </select>
        </label>

        <label className="field">
          <span>Campaña</span>
          <select required value={campaignId} onChange={event => setCampaignId(event.target.value)}>
            <option value="">Seleccionar</option>
            {props.campaigns.map(campaign => (
              <option key={campaign.id} value={campaign.id}>
                {campaign.name}
              </option>
            ))}
          </select>
        </label>

        <label className="field">
          <span>Entity ID</span>
          <input
            required
            min="1"
            step="1"
            type="number"
            value={entityId}
            onChange={event => setEntityId(event.target.value)}
          />
        </label>

        <div className="form-actions field-wide">
          <button type="submit" className="button button-primary" disabled={saving || !campaignId}>
            {saving ? "Asignando..." : "Asignar"}
          </button>
        </div>
      </form>
    </Card>
  );
}

