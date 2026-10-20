import React, { useState } from 'react';
import { X, Search, BookOpen } from 'lucide-react';

interface GlossaryTerm {
  term: string;
  category: 'Ad Tech' | 'Active Directory' | 'Mec nica';
  acronym?: string;
  definition: string;
}

const GLOSSARY_TERMS: GlossaryTerm[] = [
  {
    term: 'OpenRTB',
    category: 'Ad Tech',
    definition: 'Protocolo de comunicaci n est ndar internacional del IAB Tech Lab que define el formato JSON con el que se env an y reciben solicitudes de puja y anuncios entre SSPs y DSPs.'
  },
  {
    term: 'DSP (Demand-Side Platform)',
    category: 'Ad Tech',
    definition: 'Plataforma de software utilizada por agencias y anunciantes para comprar inventario publicitario automatizado en m ltiples ad exchanges mediante subastas en tiempo real.'
  },
  {
    term: 'SSP (Supply-Side Platform)',
    category: 'Ad Tech',
    definition: 'Plataforma utilizada por editores de p ginas web, diarios y aplicaciones m viles para poner a disposici n su inventario publicitario y maximizar sus ingresos.'
  },
  {
    term: 'eCPM (Effective Cost Per Mille)',
    category: 'Ad Tech',
    definition: 'M trica que calcula el coste o ingreso por cada mil impresiones publicitarias servidas: eCPM = (Ingresos / Impresiones)   1000.'
  },
  {
    term: 'Header Bidding',
    category: 'Ad Tech',
    definition: 'T cnica program tica avanzada donde el navegador del usuario recopila pujas de m ltiples compradores en paralelo antes de consultar al servidor de publicidad principal.'
  },
  {
    term: 'Frequency Capping',
    category: 'Ad Tech',
    definition: 'Funci n del motor ad que restringe cu ntas veces se le puede mostrar un anuncio o campa a a un mismo usuario  nico en un per odo de tiempo determinado.'
  },
  {
    term: 'Pacing Presupuestario',
    category: 'Ad Tech',
    definition: 'Algoritmo de control PID o muestreo probabil stico que regula la velocidad a la que se gasta el presupuesto publicitario para que dure todo el d a o mes.'
  },
  {
    term: 'Est ndar MRC (Media Rating Council)',
    category: 'Ad Tech',
    definition: 'Norma de la industria que dictamina que un anuncio gr fico se considera visto si al menos el 50% de sus p xeles permanece visible en el viewport durante al menos 1.0 segundo continuo (2.0 segundos para video).'
  },
  {
    term: 'VAST (Video Ad Serving Template)',
    category: 'Ad Tech',
    definition: 'Protocolo XML est ndar de la IAB para estructurar y transferir anuncios en reproductores de video digital, indicando URLs del archivo MP4/HLS, duraci n y balizas de telemetr  '
  },
  {
    term: 'SafeFrame',
    category: 'Ad Tech',
    definition: 'Contenedor iframe administrado por API que permite mostrar anuncios interactivos mientras a sla el c digo del anuncio para proteger los datos y la privacidad del sitio anfitri  '
  },
  {
    term: 'IVT (Invalid Traffic)',
    category: 'Ad Tech',
    definition: 'Tr fico publicitario no humano o fraudulento, categorizado en GIVT (bots conocidos, rastreadores) y SIVT (malware complejo, granjas de clics, dominios suplantados).'
  },
  {
    term: 'DCO (Dynamic Creative Optimization)',
    category: 'Ad Tech',
    definition: 'Tecnolog a de IA que ensambla elementos publicitarios (t tulo, imagen de producto, color, llamada a la acci n) al vuelo en funci n de los datos del usuario.'
  },
  {
    term: 'Kerberos v5',
    category: 'Active Directory',
    definition: 'Protocolo de autenticaci n en red basado en criptograf a de clave sim trica y boletos (Tickets TGT y ST) para permitir inicio de sesi nico (SSO) en Windows Server sin transmitir contrase as.'
  },
  {
    term: 'LDAP (Lightweight Directory Access Protocol)',
    category: 'Active Directory',
    definition: 'Protocolo cliente-servidor est ndar para acceder y mantener servicios de informaci n de directorios distribuidos jer rquicos sobre IP.'
  },
  {
    term: 'NTDS.dit',
    category: 'Active Directory',
    definition: 'Archivo de base de datos relacional transaccional (motor ESE JET Blue) que almacena f sicamente todos los objetos de Active Directory en cada Controlador de Dominio.'
  },
  {
    term: 'GPO (Group Policy Object)',
    category: 'Active Directory',
    definition: 'Colecci n de configuraciones de administraci n centralizada de directivas aplicadas a equipos y usuarios en un entorno Windows de Active Directory.'
  },
  {
    term: 'Accionamiento Directo (Direct Drive)',
    category: 'Mec nica',
    definition: 'Mecanismo electromec nico donde el rotor del motor se conecta directamente a la carga sin engranajes reductores ni correas, eliminando la holgura angular (Backlash) y el desgaste por rozamiento.'
  }
];

interface GlossaryModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const GlossaryModal: React.FC<GlossaryModalProps> = ({ isOpen, onClose }) => {
  const [searchTerm, setSearchTerm] = useState<string>('');
  if (!isOpen) return null;

  const filtered = GLOSSARY_TERMS.filter(
    (item) =>
      item.term.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.definition.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.category.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-3xl max-h-[85vh] flex flex-col shadow-2xl overflow-hidden">
        {/* Modal Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <BookOpen className="w-5 h-5 text-amber-400" />
            <h3 className="text-lg font-bold text-white">Glosario T cnico de Motores AD</h3>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        {/* Search input */}
        <div className="p-4 border-b border-slate-800 bg-slate-950/40">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Buscar t rmino (ej. OpenRTB, eCPM, Kerberos, SafeFrame, IVT)..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-4 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-400"
            />
          </div>
        </div>
        {/* Terms list */}
        <div className="p-5 overflow-y-auto space-y-3 divide-y divide-slate-800/60 flex-1">
          {filtered.length === 0 ? (
            <p className="text-center py-8 text-xs text-slate-500">
              No se encontraron t rminos que coincidan con la b squeda.
            </p>
          ) : (
            filtered.map((item, idx) => (
              <div key={idx} className={idx > 0 ? 'pt-3' : ''}>
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-bold text-sm text-white">{item.term}</span>
                  <span className="text-[11px] text-amber-400 font-mono">[{item.category}]</span>
                </div>
                <p className="text-xs text-slate-300 leading-relaxed">
                  {item.definition}
                </p>
              </div>
            ))
          )}
        </div>
        {/* Modal Footer */}
        <div className="p-4 border-t border-slate-800 bg-slate-950/60 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg text-xs font-semibold cursor-pointer transition-colors"
          >
            Cerrar
          </button>
        </div>
      </div>
    </div>
  );
};
