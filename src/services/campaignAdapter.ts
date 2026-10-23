import type { Campaign } from '../types';

export interface BackendCampaign {
  id: number | string;
  name: string;
  budget: number;
  budgetSpent?: number;
  costPerMille?: number;
  costPerClick?: number;
  startDateUtc?: string | null;
  endDateUtc?: string | null;
  status: string;
  impressions?: number;
  clicks?: number;
}

export function mapFromBackendCampaign(item: BackendCampaign): Campaign {
  const rawStatus = String(item.status || 'ACTIVE').toUpperCase();
  const spent = Number(item.budgetSpent ?? (item as any).spent ?? 0);
  const budget = Number(item.budget ?? 0);

  let normalizedStatus: 'ACTIVA' | 'PAUSADA' | 'LIMITADA' = 'PAUSADA';
  if (rawStatus === 'ACTIVE' || rawStatus === 'ACTIVA') {
    normalizedStatus = budget > 0 && spent >= budget ? 'LIMITADA' : 'ACTIVA';
  } else if (rawStatus === 'LIMITADA') {
    normalizedStatus = 'LIMITADA';
  }

  const maxCpc = Number(item.costPerClick ?? (item as any).maxCpc ?? 2.0);

  return {
    id: typeof item.id === 'number' ? `CAMP-${item.id}` : String(item.id),
    name: item.name || 'Sin nombre',
    status: normalizedStatus,
    backendStatus: rawStatus,
    strategy: 'Pacing Ponderado + CPC',
    budget,
    spent,
    impressions: Number(item.impressions ?? 0),
    clicks: Number(item.clicks ?? 0),
    maxCpc,
  };
}

export function mapToBackendCreateDto(form: {
  name: string;
  budget: number;
  maxCpc: number;
  cpmFloor?: number;
}) {
  return {
    name: form.name.trim(),
    budget: Number(form.budget),
    costPerClick: Number(form.maxCpc),
    costPerMille: Number(form.cpmFloor ?? 14.0),
  };
}