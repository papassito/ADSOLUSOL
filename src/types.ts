export type ModuleKey =
  | 'panel'
  | 'campanas'
  | 'ubicaciones'
  | 'creativos'
  | 'asignaciones'
  | 'entrega'
  | 'analitica'
  | 'audiencias'
  | 'facturacion'
  | 'alertas'
  | 'auditoria'
  | 'sistema';

export interface ToastMsg {
  id: string;
  title: string;
  type: 'exito' | 'alerta' | 'info';
}

export interface Campaign {
  id: string;
  name: string;
  status: 'ACTIVA' | 'PAUSADA' | 'LIMITADA';
  backendStatus?: string;
  budget: number;
  spent: number;
  budgetSpent?: number;
  impressions: number;
  clicks: number;
  costPerClick: number;
  costPerMille: number;
  startDateUtc?: string;
  endDateUtc?: string;
}

export interface Placement {
  id: string;
  code: string;
  name: string;
  format: string;
  floorCpm: number;
  impressions: number;
  clicks: number;
}

export interface Creative {
  id: string;
  campaignId: string;
  name: string;
  title: string;
  description: string;
  locationAddress: string;
  clicks: number;
  directionsClicks?: number;
  destinationUrl: string;
  contentUrl: string;
  whatsappContact: string;
}

export interface Assignment {
  id: number;
  campaignId: string;
  creativeId: number;
  placementId: number;
}

export interface SystemHealth {
  status: string;
  timestamp: string;
  checks: {
    database: string;
    sicEngine: string;
  };
}

export interface AuditLog {
  id: string;
  timestamp: string;
  eventType: string;
  details: string;
}

export interface Alert {
  id: string;
  severity: 'INFO' | 'WARNING' | 'CRITICAL';
  message: string;
  timestamp: string;
}

export interface Audience {
  id: string;
  name: string;
  description: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: string;
}

export * from './types/adEngine';