import React from 'react';

interface AuditingViewProps {
  users: any[];
}

export const AuditingView: React.FC<AuditingViewProps> = ({ users }) => {
  return (
    <section className="as-card-premium rounded-2xl p-6 space-y-6">
      <div>
        <h3 className="text-base font-bold text-white mb-3">
          Operadores y Nodos Firmantes Autorizados (RBAC)
        </h3>
        <table className="w-full text-left border-collapse text-xs">
          <thead>
            <tr className="border-b border-slate-800 text-slate-400">
              <th className="py-2.5">Usuario</th>
              <th className="py-2.5">Correo</th>
              <th className="py-2.5">Rol en Ecosistema</th>
              <th className="py-2.5">Huella Pública Ed25519</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {users.map((u: any) => (
              <tr key={u.id}>
                <td className="py-3 font-bold text-white">{u.name}</td>
                <td className="py-3 text-slate-300">{u.email}</td>
                <td className="py-3 text-amber-400 font-semibold">{u.role}</td>
                <td className="py-3 font-mono text-slate-400">{u.keyFingerprint}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
};