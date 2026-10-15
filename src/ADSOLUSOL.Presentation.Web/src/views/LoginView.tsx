import { useState } from "react";
import type { FormEvent } from "react";
import { api, ApiError } from "../api";
import { errorMessage } from "../components/Common";

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
    <div className="p-6 max-w-md w-full mx-auto">
      <div className="app-card rounded-xl p-6">
        <span className="text-[10px] font-bold uppercase tracking-wider text-blue-500">Acceso protegido</span>
        <h2 className="font-heading font-extrabold text-lg mt-1">Ingresar a ADSOLUSOL</h2>
        <p className="text-xs text-gray-400 mt-1">Las campañas y presupuestos solo se muestran después de autenticar el tenant.</p>
        {error && (
          <div className="mt-3 p-2.5 rounded-lg bg-red-500/10 border border-red-500/20 text-red-300 text-xs" role="alert" aria-live="assertive">
            <strong>Error </strong>
            <span>{error}</span>
          </div>
        )}
        <form className="mt-4 space-y-3 text-xs" onSubmit={submit}>
          <label className="block">
            <span className="text-gray-400">Correo electrónico o Tenant ID</span>
            <input className="mt-1 w-full px-3 py-2 rounded-lg bg-black/30 border border-white/10" required autoComplete="username" value={tenantId} onChange={event => setTenantId(event.target.value)} />
          </label>
          <label className="block">
            <span className="text-gray-400">Contraseña</span>
            <input className="mt-1 w-full px-3 py-2 rounded-lg bg-black/30 border border-white/10" required type="password" autoComplete="current-password" value={password} onChange={event => setPassword(event.target.value)} />
          </label>
          <button className="px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-xs font-bold transition" disabled={submitting} type="submit">
            {submitting ? "Verificando..." : "Ingresar"}
          </button>
        </form>
      </div>
    </div>
  );
}

