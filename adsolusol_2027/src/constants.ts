import {
  LayoutDashboard,
  Megaphone,
  MapPin,
  ImageIcon,
  Link2,
  Cpu,
  BarChart3,
  Users,
  Wallet,
  Bell,
  ShieldCheck,
  Server,
} from 'lucide-react';
import { ModuleKey } from './types';

export const MODULE_META: Record<
  ModuleKey,
  { title: string; category: string; subtitle: string; icon: any }
> = {
  panel: {
    title: 'Panel Principal',
    category: 'Operación Central',
    subtitle: 'Resumen ejecutivo, proyección predictiva a 7 días y liquidación atómica',
    icon: LayoutDashboard,
  },
  campanas: {
    title: 'Gestión de Campañas',
    category: 'Operación Central',
    subtitle: 'Control de ciclo de vida, techos presupuestarios y pacing ponderado',
    icon: Megaphone,
  },
  ubicaciones: {
    title: 'Inventario de Ubicaciones',
    category: 'Inventario y Creativos',
    subtitle: 'Espacios publicitarios normalizados y pisos de subasta CPM',
    icon: MapPin,
  },
  creativos: {
    title: 'Estudio de Creativos + GPS',
    category: 'Inventario y Creativos',
    subtitle: 'Diseño con IA, conexión a Google Maps ("Cómo llegar") y vista previa SERP móvil',
    icon: ImageIcon,
  },
  asignaciones: {
    title: 'Matriz de Asignaciones',
    category: 'Inventario y Creativos',
    subtitle: 'Vinculación ponderada entre campañas, creativos y ubicaciones activas',
    icon: Link2,
  },
  entrega: {
    title: 'Motor de Entrega y Subasta',
    category: 'Motor AdServer',
    subtitle: 'Inspección en tiempo real del algoritmo de decisión y firma criptográfica Ed25519',
    icon: Cpu,
  },
  analitica: {
    title: 'Analítica y Reportes',
    category: 'Inteligencia y Finanzas',
    subtitle: 'Tendencias de 24 horas de CTR y CPC con Recharts y desglose por franja horaria',
    icon: BarChart3,
  },
  audiencias: {
    title: 'Audiencias y Escudo Shield™',
    category: 'Inteligencia y Finanzas',
    subtitle: 'Segmentación First-Party y bloqueo en 1 clic de búsquedas de competencia',
    icon: Users,
  },
  facturacion: {
    title: 'Facturación y Libro Mayor (Ledger)',
    category: 'Inteligencia y Finanzas',
    subtitle: 'Contabilidad autoritativa en servidor y auditoría de débitos por clic y rutas GPS',
    icon: Wallet,
  },
  alertas: {
    title: 'Centro de Alertas',
    category: 'Gobernanza y Sistema',
    subtitle: 'Notificaciones Push al 90% del presupuesto, anomalías de tráfico y avisos',
    icon: Bell,
  },
  auditoria: {
    title: 'Auditoría Forense y Usuarios',
    category: 'Gobernanza y Sistema',
    subtitle: 'Bitácora inmutable de eventos firmados (Anti-Replay) y control de roles RBAC',
    icon: ShieldCheck,
  },
  sistema: {
    title: 'Salud del Sistema y Nodos',
    category: 'Gobernanza y Sistema',
    subtitle: 'Diagnóstico técnico con latencia real de SQLite WAL, API_SIC y Nodo Borde',
    icon: Server,
  },
};

export const AI_PRESETS = [
  {
    title: 'Laboratorio San Francisco | Resultados Hoy Mismo',
    description:
      'Análisis clínicos de alta precisión en Hermosillo. ¡Abierto los Domingos! Cotiza por WhatsApp sin fila.',
    locationAddress: 'Oaxaca 63, Col. Centro, Hermosillo, Sonora',
    sitelinks: ['Check Up Básico \$500', 'Resultados en Línea'],
  },
  // ... otros presets
];

export const BRANCH_LOCATIONS = [
  {
    label: 'Sucursal Centro (Oaxaca 63)',
    address: 'Laboratorio San Francisco, Oaxaca 63, Col. Centro, Hermosillo, Sonora',
  },
  {
    label: 'Sucursal Quiroga (Norte/Poniente)',
    address: 'Blvd. Antonio Quiroga, Hermosillo, Sonora',
  },
  {
    label: 'Unidad de Radiología San Francisco',
    address: 'Radiología San Francisco, Oaxaca 63, Centro, Hermosillo, Sonora',
  },
];