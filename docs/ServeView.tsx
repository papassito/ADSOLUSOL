import { useState } from "react";
import type { FormEvent } from "react";
import { api } from "../api";
import type { Creative } from "../types";
import { Card, EmptyState, ErrorPanel, errorMessage } from "../components/Common";

export function ServeView() {
  const [placementCode, setPlacementCode] = useState("");
  const [creative, setCreative] = useState<Creative | null>(null);
  const [noAd, setNoAd] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);
    setCreative(null);
    setNoAd(false);

    try {
      const result = await api.serve(placementCode.trim());
      if (!result) {
        setNoAd(true);
      } else {
        setCreative(result);
      }
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="two-column">
      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">Serving engine</span>
            <h2>Solicitar anuncio</h2>
          </div>
        </div>

        {error && <ErrorPanel message={error} />}

        <form className="form-grid" onSubmit={submit}>
          <label className="field field-wide">
            <span>Placement code</span>
            <input
              required
              value={placementCode}
              onChange={event => setPlacementCode(event.target.value)}
            />
          </label>

          <div className="form-actions field-wide">
            <button type="submit" className="button button-primary" disabled={loading}>
              {loading ? "Consultando..." : "Solicitar anuncio"}
            </button>
          </div>
        </form>
      </Card>

      <Card>
        <div className="card-header">
          <div>
            <span className="eyebrow">Decision</span>
            <h2>Resultado</h2>
          </div>
        </div>

        {noAd && (
          <EmptyState
            title="NO_AD_AVAILABLE"
            description="El backend no encontró un anuncio elegible. La UI no genera fallback ficticio."
          />
        )}

        {!noAd && !creative && (
          <EmptyState
            title="Sin decisión"
            description="Ejecuta una consulta de serving."
          />
        )}

        {creative && (
          <div className="creative-result">
            <div>
              <span className="eyebrow">Creative ID</span>
              <strong>{creative.id}</strong>
            </div>
            <h3>{creative.name}</h3>
            <dl>
              <div><dt>Content URL</dt><dd>{creative.contentUrl}</dd></div>
              <div><dt>Target URL</dt><dd>{creative.targetUrl}</dd></div>
              <div><dt>Enabled</dt><dd>{String(creative.isEnabled)}</dd></div>
            </dl>
          </div>
        )}
      </Card>
    </div>
  );
}