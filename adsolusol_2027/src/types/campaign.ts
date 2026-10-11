export type CampaignStatus = 'active' | 'paused' | 'finalized';
export type PacingStrategy = 'linear' | 'aggressive' | 'conservative';
export type BidStrategy = 'maximize_conversion' | 'maximize_clicks' | 'manual';

export interface CampaignHistory {
  date: string;
  spent: number;
  impressions: number;
  clicks: number;
}

export interface Campaign {
  id: string;
  name: string;
  status: CampaignStatus;
  pacingStrategy: PacingStrategy;
  bidStrategy: BidStrategy;
  budget: number; // Total Daily Budget
  bid: number; // Add bid for real auction
  spent: number;
  impressions: number;
  ctr: number; // Percent CTR
  history: CampaignHistory[];
}
