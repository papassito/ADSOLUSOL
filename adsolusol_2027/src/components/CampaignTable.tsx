import React, { useState } from 'react';
import { useCampaigns } from '../context/CampaignContext';
import { Play, Pause, CheckCircle2, TrendingUp, AlertCircle } from 'lucide-react';
import { Tooltip } from './Tooltip';
import { CampaignChart } from './CampaignChart';

export const CampaignTable: React.FC = () => {
  const { campaigns, updateStatus, updateStrategy, finalizeCampaign } = useCampaigns();

  const trackAction = async (campaignId: string, event: 'impression' | 'click') => {
    await fetch('/api/telemetry', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        campaign_id: campaignId,
        event_type: event,
        user_ip: '127.0.0.1', // Mocked IP for live demo
        user_agent: navigator.userAgent
      }),
    });
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
      <h3 className="text-lg font-bold text-white mb-4">Administraci n de Campa as</h3>
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="text-slate-400 border-b border-slate-800">
            <th className="pb-3 font-medium">Nombre</th>
            <th className="pb-3 font-medium">Estado</th>
            <th className="pb-3 font-medium">Estrategias</th>
            <th className="pb-3 font-medium text-right">Presupuesto</th>
            <th className="pb-3 font-medium text-right">Telemetr a</th>
            <th className="pb-3 font-medium text-right">Acciones</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800">
          {campaigns.map((c) => (
            <tr key={c.id} className="text-slate-200">
              <td className="py-4 font-semibold text-white">{c.name}</td>
              <td className="py-4">
                <span className={`px-2 py-1 rounded text-[10px] font-mono uppercase ${
                  c.status === 'active' ? 'bg-emerald-900 text-emerald-300' :
                  c.status === 'paused' ? 'bg-amber-900 text-amber-300' : 'bg-slate-800 text-slate-400'
                }`}>
                  {c.status}
                </span>
              </td>
              <td className="py-4 text-xs space-y-1">
                <select 
                   value={c.pacingStrategy} 
                   onChange={(e) => updateStrategy(c.id, e.target.value as any, c.bidStrategy)}
                  className="bg-slate-950 border border-slate-700 rounded px-1 py-0.5"
                >
                  <option value="linear">Linear Pacing</option>
                  <option value="aggressive">Aggressive</option>
                  <option value="conservative">Conservative</option>
                </select>
              </td>
              <td className="py-4 text-right font-mono">${c.budget.toFixed(2)}</td>
              <td className="py-4 text-right">
                <CampaignChart history={c.history} />
              </td>
              <td className="py-4 text-right">
                {c.status !== 'finalized' && (
                  <div className="flex justify-end gap-2">
                    <button onClick={() => {
                        trackAction(c.id, 'click');
                        updateStatus(c.id, c.status === 'active' ? 'paused' : 'active');
                      }} className="p-1 hover:text-amber-400">
                      {c.status === 'active' ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
                    </button>
                    <button onClick={() => {
                        trackAction(c.id, 'click');
                        finalizeCampaign(c.id);
                      }} className="p-1 hover:text-emerald-400">
                      <CheckCircle2 className="w-4 h-4" />
                    </button>
                  </div>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
