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
    title: 'Transmisión Directa Sin Reductora (Gearless Transmission)',
    principle: 'El rotor del motor está fijado directamente al eje de la carga útil sin cajas de cambios ni poleas intermedias.',
    summary: 'Elimina las pérdidas mecánicas por fricción, el desgaste de engranajes y la holgura angular (Backlash).',
    applications: ['Tornamesas de vinilo profesionales (Technics SL-1200)', 'Bases de volantes de simulación de carreras (SimRacing F1)', 'Ejes de rotación en máquinas CNC de 5 ejes'],
    advantages: ['Respuesta mecánica instantánea (latencia cero en par)', 'Eliminación del juego mecánico (Zero Backlash)', 'Operación ultrasilenciosa']
  },
  {
    id: 'high-torque-low-rpm',
    number: '02',
    title: 'Generación de Alto Par a Bajas Revoluciones (High Torque Density)',
    principle: 'Diseño electromagnético con un gran número de pares de polos magnéticos (Multipole PM-BLDC / PMSM).',
    summary: 'Genera una fuerza de giro masiva desde 0 RPM sin requerir acelerar a altas velocidades.',
    applications: ['Lavadoras modernas Direct Drive (LG Inverter DD)', 'Generadores eólicos marinos sin multiplicador', 'Turbinas hidroeléctricas'],
    advantages: ['Máxima eficiencia energética (pérdidas reducidas en un 30-40%)', 'Eliminación del fallo por correas rotas o poleas desalineadas', 'Control de velocidad hiperpreciso (±0.001 RPM)']
  },
  {
    id: 'closed-loop-foc',
    number: '03',
    title: 'Control Vectorial Orientado al Campo (Field-Oriented Control - FOC)',
    principle: 'Inversores de conmutación electrónica y codificadores ópticos de alta resolución (20-bit encoders).',
    summary: 'Controla el vector de corriente magnética en el estator para posicionamiento micrométrico en tiempo real.',
    applications: ['Brazos robóticos industriales de precisión y cobots', 'Gimbals estabilizadores de cámaras de cine', 'Telescopios astronómicos profesionales'],
    advantages: ['Posicionamiento angular submilimétrico', 'Rizado de par (Torque Ripple) prácticamente nulo', 'Frenado regenerativo dinámico integrado']
  }
];
