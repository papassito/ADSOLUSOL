import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Campaign, PacingStrategy, BidStrategy } from '../types/campaign';

interface CampaignContextType {
  campaigns: Campaign[];
  addCampaign: (campaign: Omit<Campaign, 'id' | 'spent' | 'impressions' | 'ctr' | 'history'>) => void;
  updateStatus: (id: string, status: Campaign['status']) => void;
  updateStrategy: (id: string, pacingStrategy: PacingStrategy, bidStrategy: BidStrategy) => void;
  finalizeCampaign: (id: string) => void;
  notifications: string[];
  dismissNotification: (index: number) => void;
}

const CampaignContext = createContext<CampaignContextType | undefined>(undefined);

const STORAGE_KEY = 'ad_engine_campaigns';

export const CampaignProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [notifications, setNotifications] = useState<string[]>([]);

  useEffect(() => {
    fetch('/api/campaigns')
      .then(res => res.json())
      .then(data => setCampaigns(data));
  }, []);

  const addCampaign = async (newCampaign: Omit<Campaign, 'id' | 'spent' | 'impressions' | 'ctr' | 'history'>) => {
    const id = Math.random().toString(36).substr(2, 9);
    await fetch('/api/campaigns', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, ...newCampaign }),
    });
    setCampaigns(prev => [...prev, { ...newCampaign, id, spent: 0, impressions: 0, ctr: 0, history: [] }]);
  };

  const updateStatus = (id: string, status: Campaign['status']) => {
    setCampaigns((prev) =>
      prev.map((c) => (c.id === id ? { ...c, status } : c))
    );
  };

  const updateStrategy = (id: string, pacingStrategy: PacingStrategy, bidStrategy: BidStrategy) => {
    setCampaigns((prev) =>
      prev.map((c) => (c.id === id ? { ...c, pacingStrategy, bidStrategy } : c))
    );
  };

  const finalizeCampaign = (id: string) => {
    setCampaigns((prev) =>
      prev.map((c) => (c.id === id ? { ...c, status: 'finalized' } : c))
    );
  };

  const dismissNotification = (index: number) => {
    setNotifications(prev => prev.filter((_, i) => i !== index));
  };

  return (
    <CampaignContext.Provider value={{ campaigns, addCampaign, updateStatus, updateStrategy, finalizeCampaign, notifications, dismissNotification }}>
      {children}
    </CampaignContext.Provider>
  );
};

export const useCampaigns = () => {
  const context = useContext(CampaignContext);
  if (!context) throw new Error('useCampaigns must be used within a CampaignProvider');
  return context;
};
