import React from 'react';

interface BillingViewProps {
  auditLogs: any[];
  paymentMethod?: string;
  ledgerBalance: number | null;
}

export const BillingView: React.FC<BillingViewProps> = ({
  auditLogs,
  paymentMethod = 'NO DISPONIBLE',
  ledgerBalance,
}) => {
  return (
    <section className="as-card-premium rounded-2xl p-6 space-y-4">
      <div>
        <h3 className="text-base font-bold text-white">
          Libro Mayor Autoritativo (Server Authoritative Ledger)
        </h3>
        <p className="text-xs text-slate-400">
          {`Método Principal: ${paymentMethod} • Saldo Disponible: $${ledgerBalance?.toFixed(2) ?? 'NO DISPONIBLE'} MXN`}
        </p>
      </div>
      <table className="w-full text-left border-collapse text-xs font-mono">
        <thead>
          <tr className="border-b border-slate-800 text-slate-400">
            <th className="py-3">Evento ID</th>
            <th className="py-3">Hora</th>
            <th className="py-3">Operación</th>
            <th className="py-3">Concepto / Ruta GPS</th>
            <th className="py-3">Cargo Atómico</th>
            <th className="py-3">Estado / Firma</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800/60">
          {auditLogs.map((log: any) => (
            <tr key={log.id}>
              <td className="py-3 text-amber-400 font-bold">{log.id}</td>
              <td className="py-3">{log.timestamp}</td>
              <td className="py-3">
                <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 text-slate-300">
                  {log.eventType}
                </span>
              </td>
              <td className="py-3 text-white">{log.campaign}</td>
              <td className="py-3 text-emerald-400 font-bold">{`$${Number(log.amount || 0).toFixed(2)} MXN`}</td>
              <td className="py-3 text-slate-400">{`${log.status} (${log.signature || 'OK'})`}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
};