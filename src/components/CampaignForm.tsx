import React, { useState } from 'react';
import { useCampaigns } from '../context/CampaignContext';
import { X } from 'lucide-react';

interface CampaignFormProps {
  onClose: () => void;
}

export const CampaignForm: React.FC<CampaignFormProps> = ({ onClose }) => {
  const { addCampaign } = useCampaigns();
  const [name, setName] = useState('');
  const [budget, setBudget] = useState(100);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    addCampaign({
      name,
      status: 'paused',
      pacingStrategy: 'linear',
      bidStrategy: 'manual',
      budget: budget,
      bid: 0
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-white">Nueva Campa a</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-white cursor-pointer"><X /></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm text-slate-400 mb-1">Nombre</label>
            <input type="text" value={name} onChange={e => setName(e.target.value)} required className="w-full bg-slate-950 border border-slate-700 rounded-lg p-2 text-white" />
          </div>
          <div>
            <label className="block text-sm text-slate-400 mb-1">Presupuesto Diario ($)</label>
            <input type="number" value={budget} onChange={e => setBudget(Number(e.target.value))} required className="w-full bg-slate-950 border border-slate-700 rounded-lg p-2 text-white" />
          </div>
          <button type="submit" className="w-full bg-amber-400 text-slate-950 font-bold py-2 rounded-lg cursor-pointer">Crear</button>
        </form>
      </div>
    </div>
  );
};
