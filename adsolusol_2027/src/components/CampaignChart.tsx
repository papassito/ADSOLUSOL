import React from 'react';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { CampaignHistory } from '../types/campaign';

interface CampaignChartProps {
  history: CampaignHistory[];
}

export const CampaignChart: React.FC<CampaignChartProps> = ({ history }) => {
  return (
    <div className="h-48 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={history}>
          <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
          <XAxis dataKey="date" stroke="#64748b" fontSize={10} />
          <YAxis stroke="#64748b" fontSize={10} />
          <Tooltip 
             contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', fontSize: '12px' }}
          />
          <Line name="Impresiones" type="monotone" dataKey="impressions" stroke="#10b981" strokeWidth={2} dot={false} />
          <Line name="Clics" type="monotone" dataKey="clicks" stroke="#f59e0b" strokeWidth={2} dot={false} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};
