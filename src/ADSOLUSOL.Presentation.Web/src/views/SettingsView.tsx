import { useCallback, useEffect, useState } from "react";
import type { FormEvent } from "react";
import { api } from "../api";
import { Card, ErrorPanel, errorMessage } from "../components/Common";

export function SettingsView() {
  const [settings, setSettings] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.getSettings();
      setSettings(result.settings ?? {});
    } catch (cause) {
      setError(errorMessage(cause));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  function setValue(key: string, value: string) {
    setSettings(current => ({ ...current, [key]: value }));
  }

  async function save(event: FormEvent) {
    event.preventDefault();
    setSaving(true);
    setMessage(null);
    setError(null);
    try {
      await api.updateSettings(settings);
      setMessage("Configuración guardada correctamente.");
    } catch (cause) {
      setError(errorMessage(cause));
    } finally {
      setSaving(false);
    }
  }

  const fields = [
    ["tenant.name", "Nombre comercial", "Nombre mostrado en reportes"],
    ["tenant.timezone", "Zona horaria", "Ej. America/Hermosillo"],
    ["campaign.defaultBudget", "Presupuesto predeterminado", "Monto inicial sugerido"],
    ["campaign.defaultDurationDays", "Duración predeterminada (días)", "Duración sugerida de campañas"],
    ["reporting.email", "Correo de informes", "Destino de los informes periódicos"]
  ];

  return (
    <div className="two-column">
      <Card>
        <div className="card-header"><div><span className="eyebrow">Tenant</span><h2>Configurador</h2></div><button type="button" className="button button-secondary button-small" onClick={() => void load()}>Recargar</button></div>
        {loading ? <p className="muted">Cargando configuración...</p> : (
          <form className="form-grid" onSubmit={save}>
            {fields.map(([key, label, hint]) => (
              <label className="field field-wide" key={key}>
                <span>{label}</span>
                <input value={settings[key] ?? ""} placeholder={hint} onChange={event => setValue(key, event.target.value)} />
                <small className="muted">{hint}</small>
              </label>
            ))}
            {error && <ErrorPanel message={error} />}
            {message && <p className="success-message">{message}</p>}
            <button className="button button-primary" disabled={saving} type="submit">{saving ? "Guardando..." : "Guardar configuración"}</button>
          </form>
        )}
      </Card>
    </div>
  );
}

