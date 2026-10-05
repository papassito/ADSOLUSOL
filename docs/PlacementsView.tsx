import { useState } from "react";
import type { FormEvent } from "react";
import { api } from "../api";
import { Card, EmptyState, ErrorPanel, errorMessage } from "../components/Common";

export function PlacementsView() {
  const [form, setForm] = useState({
    placementCode: "",
    name: "",
    isEnabled: true
  });

  const [createdId, setCreatedId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(null);
    setCreatedId(null);

    try {
      const result = await api.createPlacement({
        placementCode: form.placementCode.trim(),
        name: form.name.trim(),
        isEnabled: form.isEnabled
      });

      setCreatedId(result.id);
      setForm({
        placementCode: "",
        name: "",
        isEnabled: true
      });
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="two-column">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">Inventory</span>
            <h2>Crear placement</h2>
          </div>
        </div>

        {error && <ErrorPanel message={error} />}

        {createdId !== null && (
          <div className="success-panel">
            Placement creado. ID real: <strong>{createdId}</strong>
          </div>
        )}

        <form className="form-grid" onSubmit={submit}>
          <label className="field field-wide">
            <span>Placement code</span>
            <input
              required
              value={form.placementCode}
              onChange={event => setForm({ ...form, placementCode: event.target.value })}
              placeholder="HEADER_LEADERBOARD"
            />
          </label>

          <label className="field field-wide">
            <span>Nombre</span>
            <input
              required
              value={form.name}
              onChange={event => setForm({ ...form, name: event.target.value })}
            />
          </label>

          <label className="checkbox-field field-wide">
            <input
              type="checkbox"
              checked={form.isEnabled}
              onChange={event => setForm({ ...form, isEnabled: event.target.checked })}
            />
            <span>Placement habilitado</span>
          </label>

          <div className="form-actions field-wide">
            <button type="submit" className="button button-primary" disabled={saving}>
              {saving ? "Guardando..." : "Crear placement"}
            </button>
          </div>
        </form>
      </Card>

      <Card>
        <div className="card-header"><div><span className="eyebrow">Zero Synthetic</span><h2>Listado</h2></div></div>
        <EmptyState title="GET no disponible" description="El backend actual no expone todavía un endpoint de listado de placements. La UI no inventará registros ni mantendrá un catálogo sintético." />
      </Card>
    </div>
  );
}