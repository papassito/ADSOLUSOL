export type CampaignStatus =
  | "SCHEDULED"
  | "ACTIVE"
  | "PAUSED"
  | "COMPLETED"
  | string;

export interface Campaign {
  id: string;
  tenantId: string;
  name: string;
  status: CampaignStatus;

  budget: number;
  budgetSpent: number;
  remainingBudget?: number;

  costPerMille: number;
  costPerClick: number;

  startDateUtc: string;
  endDateUtc: string;
  createdAtUtc: string;
}

export interface CampaignMetrics {
  campaignId?: string;
  impressions: number;
  clicks: number;
  ctr: number;
  budget: number;
  budgetSpent: number;
}

export interface CreateCampaignRequest {
  name: string;
  budget: number;
  costPerMille: number;
  costPerClick: number;
  startDateUtc: string | null;
  endDateUtc: string | null;
}

export interface Placement {
  id: number;
  placementCode: string;
  name: string;
  isEnabled: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreatePlacementRequest {
  placementCode: string;
  name: string;
  isEnabled: boolean;
}

export interface Creative {
  id: number;
  name: string;
  contentUrl: string;
  targetUrl: string;
  isEnabled: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateCreativeRequest {
  name: string;
  contentUrl: string;
  targetUrl: string;
  isEnabled: boolean;
}

export interface AssignmentRequest {
  campaignId: string;
  entityId: number;
}

export interface HealthResponse {
  status: string;
  timestamp: string;
  checks: {
    database: string;
    sicEngine: string;
  };
}