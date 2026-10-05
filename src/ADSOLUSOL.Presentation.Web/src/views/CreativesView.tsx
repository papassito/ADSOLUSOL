import { useState } from "react";
import type { FormEvent } from "react";
import { api } from "../api";
import type { Creative } from "../types";
import { Card, EmptyState, ErrorPanel, errorMessage } from "../components/Common";

export function CreativesView() {
  const [form, setForm] = useState({
    name: "",
    contentUrl: "",
    targetUrl: "",
    isEnabled: true
  });

  const [created, setCreated] = useState<Creative | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setError(null);
    setCreated(null);

    try {
      const result = await api.createCreative({
        name: form.name.trim(),
        contentUrl: form.contentUrl.trim(),
        targetUrl: form.targetUrl.trim(),
        isEnabled: form.isEnabled
      });

      setCreated(result);
      setForm({
        name: "",
        contentUrl: "",
        targetUrl: "",
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
            <span className="eyebrow">Creative delivery</span>
            <h2>Crear creativo</h2>
          </div>
        </div>

        {error && <ErrorPanel message={error} />}

        {created && (
          <div className="success-panel">
            Creative creado. ID real: <strong>{created.id}</strong>
          </div>
        )}

        <form className="form-grid" onSubmit={submit}>
          <label className="field field-wide">
            <span>Nombre</span>
            <input
              required
              value={form.name}
              onChange={event => setForm({ ...form, name: event.target.value })}
            />
          </label>

          <label className="field field-wide">
            <span>Content URL</span>
            <input
              required
              type="url"
              value={form.contentUrl}
              onChange={event => setForm({ ...form, contentUrl: event.target.value })}
            />
          </label>

          <label className="field field-wide">
            <span>Target URL</span>
            <input
              required
              type="url"
              value={form.targetUrl}
              onChange={event => setForm({ ...form, targetUrl: event.target.value })}
            />
          </label>

          <label className="checkbox-field field-wide">
            <input type="checkbox" checked={form.isEnabled} onChange={event => setForm({ ...form, isEnabled: event.target.checked })} />
            <span>Creative habilitado</span>
          </label>

          <div className="form-actions field-wide">
            <button type="submit" className="button button-primary" disabled={saving}>
              {saving ? "Guardando..." : "Crear creativo"}
            </button>
          </div>
        </form>
      </Card>

      <Card>
        <div className="card-header"><div><span className="eyebrow">Zero Synthetic</span><h2>CatÃƒÂ¡logo</h2></div></div>
        <EmptyState title="GET no disponible" description="El backend actual no expone todavÃƒÂ­a un endpoint para listar creativos. La UI muestra ÃƒÂºnicamente respuestas reales de creaciÃƒÂ³n." />
      </Card>
    </div>
  );
}

