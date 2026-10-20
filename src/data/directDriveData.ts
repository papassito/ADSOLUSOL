export interface DirectDriveFunction {
  id: string;
  number: string;
  title: string;
  principle: string;
  summary: string;
  applications: string[];
  advantages: string[];
}

export const DIRECT_DRIVE_FUNCTIONS: DirectDriveFunction[] = [
  {
    id: 'gearless-coupling',
    number: '01',
    title: 'Transmisi n Directa Sin Reductora (Gearless Transmission)',
    principle: 'El rotor del motor est  fijado directamente al eje de la carga  til sin cajas de cambios ni poleas intermedias.',
    summary: 'Elimina las p rdidas mec nicas por fricci n, el desgaste de engranajes y la holgura angular (Backlash).',
    applications: ['Tornamesas de vinilo profesionales (Technics SL-1200)', 'Bases de volantes de simulaci n de carreras (SimRacing F1)', 'Ejes de rotaci n en m quinas CNC de 5 ejes'],
    advantages: ['Respuesta mec nica instant nea (latencia cero en par)', 'Eliminaci n del juego mec nico (Zero Backlash)', 'Operaci n ultrasilenciosa']
  },
  {
    id: 'high-torque-low-rpm',
    number: '02',
    title: 'Generaci n de Alto Par a Bajas Revoluciones (High Torque Density)',
    principle: 'Dise o electromagn tico con un gran n mero de pares de polos magn ticos (Multipole PM-BLDC / PMSM).',
    summary: 'Genera una fuerza de giro masiva desde 0 RPM sin requerir acelerar a altas velocidades.',
    applications: ['Lavadoras modernas Direct Drive (LG Inverter DD)', 'Generadores e licos marinos sin multiplicador', 'Turbinas hidroel ctricas'],
    advantages: ['M xima eficiencia energ tica (p rdidas reducidas en un 30-40%)', 'Eliminaci n del fallo por correas rotas o poleas desalineadas', 'Control de velocidad hiperpreciso ( 0.001 RPM)']
  },
  {
    id: 'closed-loop-foc',
    number: '03',
    title: 'Control Vectorial Orientado al Campo (Field-Oriented Control - FOC)',
    principle: 'Inversores de conmutaci n electr nica y codificadores  pticos de alta resoluci n (20-bit encoders).',
    summary: 'Controla el vector de corriente magn tica en el estator para posicionamiento microm trico en tiempo real.',
    applications: ['Brazos rob ticos industriales de precisi n y cobots', 'Gimbals estabilizadores de c maras de cine', 'Telescopios astron micos profesionales'],
    advantages: ['Posicionamiento angular sub-milim trico', 'Rizado de par (Torque Ripple) pr cticamente nulo', 'Frenado regenerativo din mico integrado']
  }
];
