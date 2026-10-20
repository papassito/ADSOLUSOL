import React, { useState } from 'react';
import { useCampaigns } from '../context/CampaignContext';
import { DollarSign, Target, BarChart2, AlertCircle } from 'lucide-react';
import { Tooltip } from './Tooltip';
import { CampaignForm } from './CampaignForm';

export const DashboardPanel: React.FC = () => {
  const { campaigns, notifications, dismissNotification } = useCampaigns();

  const totalBudget = campaigns.reduce((acc, c) => acc + c.budget, 0);
  const activeCampaigns = campaigns.filter((c) => c.status === 'active').length;
  const avgCtr = campaigns.length > 0 ? (campaigns.reduce((acc, c) => acc + c.ctr, 0) / campaigns.length).toFixed(2) : '0';

  const stats = [
    { label: 'Presupuesto Total Diario', value: `$${totalBudget}`, icon: DollarSign, color: 'text-amber-400', desc: 'Suma de presupuestos diarios de todas las campa as.' },
    { label: 'Campa as Activas', value: activeCampaigns, icon: Target, color: 'text-emerald-400', desc: 'N mero de campa as actualmente entregando anuncios.' },
    { label: 'CTR Promedio', value: `${avgCtr}%`, icon: BarChart2, color: 'text-blue-400', desc: 'Click-Through Rate promedio de todas las campa as.' },
  ];

  const [showForm, setShowForm] = useState(false);

  return (
    <>
      {showForm && <CampaignForm onClose={() => setShowForm(false)} />}
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold text-white">Resumen</h2>
        <button onClick={() => setShowForm(true)} className="bg-amber-400 text-slate-950 px-4 py-2 rounded-lg font-semibold text-sm cursor-pointer hover:bg-amber-300">
          Nueva Campa a
        </button>
      </div>
      {notifications.length > 0 && (
        <div className="mb-6 space-y-2">
          {notifications.map((note, index) => (
            <div key={index} className="bg-amber-500/10 border border-amber-500/30 text-amber-200 p-4 rounded-xl flex items-center justify-between text-sm animate-fade-in">
              <div className="flex items-center gap-3">
                <AlertCircle className="w-5 h-5 text-amber-400" />
                {note}
              </div>
              <button onClick={() => dismissNotification(index)} className="text-amber-400 hover:text-amber-300 font-bold">X</button>
            </div>
          ))}
        </div>
      )}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        {stats.map((stat, idx) => (
          <Tooltip key={idx} content={stat.desc}>
            <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-5 rounded-2xl flex items-center gap-4 hover:border-slate-300 dark:hover:border-slate-700 transition-colors shadow-sm">
              <div className={`p-3 bg-slate-100 dark:bg-slate-950 rounded-xl ${stat.color}`}>
                <stat.icon className="w-6 h-6" />
              </div>
              <div>
                <span className="text-xs text-slate-500 dark:text-slate-400">{stat.label}</span>
                <span className="text-2xl font-bold font-mono text-slate-900 dark:text-white block tabular-nums">{stat.value}</span>
              </div>
            </div>
          </Tooltip>
        ))}
      </div>
    </>
  );
};
