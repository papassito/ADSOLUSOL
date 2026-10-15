import { useState } from "react";
import type { FormEvent } from "react";
import { api, ApiError } from "../api";
import { Card, ErrorPanel, errorMessage } from "../components/Common";

export function LoginView(props: { onLogin: (tenantId: string) => void }) {
  const [tenantId, setTenantId] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const result = await api.login(tenantId.trim(), password);
      setPassword("");
      props.onLogin(result.tenantId);
    } catch (cause) {
      setError(
        cause instanceof ApiError && cause.status === 401
          ? "Tenant o contraseña incorrectos."
          : errorMessage(cause)
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-layout">
      <Card className="login-card">
        <span className="eyebrow">Acceso protegido</span>
        <h2>Ingresar a ADSOLUSOL</h2>
        <p className="muted">Las campañas y presupuestos solo se muestran después de autenticar el tenant.</p>
        {error && <ErrorPanel message={error} />}
        <form className="form-grid" onSubmit={submit}>
          <label className="field field-wide">
            <span>Correo electrónico o Tenant ID</span>
            <input required autoComplete="username" value={tenantId} onChange={event => setTenantId(event.target.value)} />
          </label>
          <label className="field field-wide">
            <span>Contraseña</span>
            <input required type="password" autoComplete="current-password" value={password} onChange={event => setPassword(event.target.value)} />
          </label>
          <button className="button button-primary" disabled={submitting} type="submit">
            {submitting ? "Verificando..." : "Ingresar"}
          </button>
        </form>
      </Card>
    </div>
  );
}

