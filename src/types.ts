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
  strategy: string;
  budget: number;
  spent: number;
  impressions: number;
  clicks: number;
  maxCpc: number;
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
  title: string;
  description: string;
  locationAddress: string;
  clicks: number;
  directionsClicks?: number;
  destinationUrl: string;
  whatsappContact: string;
}

export * from './types/adEngine';