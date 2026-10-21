import React from 'react';
import { CheckCircle2 } from 'lucide-react';
import { ToastMsg } from '../types';

interface ToastContainerProps {
  toasts: ToastMsg[];
}

export const ToastContainer: React.FC<ToastContainerProps> = ({ toasts }) => {
  return (
    <div className="fixed bottom-5 right-5 space-y-2 z-50">
      {toasts.map((t) => (
        <div
          key={t.id}
          className={`px-4 py-3 rounded-xl border shadow-lg text-xs font-bold flex items-center gap-2 ${
            t.type === 'exito'
              ? 'bg-[#0E1422] border-emerald-500/50 text-emerald-400'
              : t.type === 'alerta'
              ? 'bg-[#0E1422] border-rose-500/50 text-rose-400'
              : 'bg-[#0E1422] border-amber-500/50 text-amber-400'
          }`}
        >
          <CheckCircle2 className="h-4 w-4 shrink-0" />
          <span>{t.title}</span>
        </div>
      ))}
    </div>
  );
};