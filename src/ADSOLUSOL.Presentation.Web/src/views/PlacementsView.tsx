import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { api } from "../api";
import type { Placement } from "../types";
import { Card, EmptyState, ErrorPanel, errorMessage } from "../components/Common";

export function PlacementsView() {
  const [form, setForm] = useState({
    placementCode: "",
    name: "",
    isEnabled: true
  });

  const [createdId, setCreatedId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [listError, setListError] = useState<string | null>(null);
  const [placements, setPlacements] = useState<Placement[] | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void api.listPlacements()
      .then(items => { if (!cancelled) setPlacements(items); })
      .catch(err => { if (!cancelled) setListError(errorMessage(err)); });
    return () => { cancelled = true; };
  }, []);

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
      setPlacements(await api.listPlacements());
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
        <div className="card-header">
          <div><span className="eyebrow">Inventario real</span><h2>Placements</h2></div>
          <span className="record-count">{placements?.length ?? "—"} registros</span>
        </div>
        {listError && <ErrorPanel message={listError} />}
        {placements === null && !listError && <p className="muted">Cargando inventario...</p>}
        {placements?.length === 0 && <EmptyState title="Sin placements" description="Crea un placement para habilitar inventario publicitario." />}
        {!!placements?.length && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead><tr className="border-b border-inherit text-gray-400 font-semibold uppercase text-[10px]">
                <th className="py-3 px-3">ID</th><th className="py-3 px-3">Código</th><th className="py-3 px-3">Espacio</th><th className="py-3 px-3">Estado</th>
              </tr></thead>
              <tbody className="divide-y divide-white/5">
                {placements.map(placement => (
                  <tr key={placement.id}>
                    <td className="py-3 px-3 font-mono">{placement.id}</td>
                    <td className="py-3 px-3 font-mono">{placement.placementCode}</td>
                    <td className="py-3 px-3">{placement.name}</td>
                    <td className="py-3 px-3">{placement.isEnabled ? "Habilitado" : "Pausado"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}

