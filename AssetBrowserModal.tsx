import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Search,
  Music,
  Disc,
  FileText,
  ShieldCheck,
  ShieldAlert,
  Shield,
  Play,
  Pause,
  Download,
  Filter,
  Sliders,
  CheckCircle2,
  AlertTriangle,
  X,
  Sparkles,
  RefreshCw,
  Zap,
} from 'lucide-react';

// ============================================================================
// CONTRATOS & TIPADO (Sincronizado con Especificación JSON Asset & Rights API)
// ============================================================================

export type QueryType = 'METADATA' | 'MELODIC' | 'STEM';
export type AssetType = 'score' | 'stem' | 'midi' | 'pdf';
export type RightsStatus = 'PUBLIC_DOMAIN' | 'COMMERCIAL_LICENSE' | 'COPYRIGHT_PROTECTED';

export interface CatalogFilter {
  text?: string;
  assetTypes?: AssetType[];
  genre?: string;
  key?: string;
  timeSignature?: string;
  melodicPattern?: string;
  tolerance?: number;
  instrument?: 'vocal' | 'bass' | 'drums' | 'other';
}

export interface CatalogSearchRequest {
  queryType: QueryType;
  filter: CatalogFilter;
  pagination: {
    page: number;
    pageSize: number;
  };
  include?: ('waveform_preview' | 'copyright_analysis')[];
}

export interface AssetRightsInfo {
  status: RightsStatus;
  statusBadge: string;
  details: string;
  dn_s_percentage: number; // Distancia Levenshtein Ponderada & Similitud S%
}

export interface CatalogItem {
  assetId: string;
  type: AssetType;
  title: string;
  composer: string;
  metadata: {
    genre?: string;
    epoch?: string;
    key?: string;
    timeSignature?: string;
    durationMs?: number;
  };
  previewUrl?: string;
  waveform?: number[];
  download: {
    url: string;
    sha256: string;
  };
  rights: AssetRightsInfo;
}

export interface CatalogSearchResponse {
  results: CatalogItem[];
  pagination: {
    currentPage: number;
    totalPages: number;
    totalResults: number;
  };
}

interface AssetBrowserModalProps {
  isOpen: boolean;
  onClose: () => void;
  onImportAsset: (asset: CatalogItem) => Promise<void>;
}

// ============================================================================
// COMPONENTE PRINCIPAL: ASSET & RIGHTS EXPLORER MODAL
// ============================================================================

export const AssetBrowserModal: React.FC<AssetBrowserModalProps> = ({
  isOpen,
  onClose,
  onImportAsset,
}) => {
  // --- ESTADOS DE CONTROL Y FILTROS ---
  const [queryType, setQueryType] = useState<QueryType>('METADATA');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedAssetTypes, setSelectedAssetTypes] = useState<AssetType[]>(['score', 'stem', 'midi']);
  const [genreFilter, setGenreFilter] = useState<string>('all');
  const [keyFilter, setKeyFilter] = useState<string>('all');
  const [melodicSequence, setMelodicSequence] = useState<string>('C4-G4-A4-F4');
  const [melodicTolerance, setMelodicTolerance] = useState<number>(0.85);
  const [selectedInstrument, setSelectedInstrument] = useState<'vocal' | 'bass' | 'drums' | 'other'>('vocal');

  // --- ESTADOS DE RESULTADOS Y AUDICIÓN ---
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [results, setResults] = useState<CatalogItem[]>([]);
  const [pagination, setPagination] = useState({ currentPage: 1, totalPages: 1, totalResults: 0 });
  const [currentlyPlayingId, setCurrentlyPlayingId] = useState<string | null>(null);
  const [importingAssetId, setImportingAssetId] = useState<string | null>(null);

  // --- MOCK API CALL (Sustituir por invocación a CatalogBridge.ts / Go FFI) ---
  const executeSearch = useCallback(async () => {
    setIsLoading(true);

    const requestBody: CatalogSearchRequest = {
      queryType,
      filter: {
        text: searchTerm,
        assetTypes: selectedAssetTypes,
        genre: genreFilter !== 'all' ? genreFilter : undefined,
        key: keyFilter !== 'all' ? keyFilter : undefined,
        melodicPattern: queryType === 'MELODIC' ? melodicSequence : undefined,
        tolerance: queryType === 'MELODIC' ? melodicTolerance : undefined,
        instrument: queryType === 'STEM' ? selectedInstrument : undefined,
      },
      pagination: {
        page: pagination.currentPage,
        pageSize: 12,
      },
      include: ['waveform_preview', 'copyright_analysis'],
    };

    console.log('[AssetBrowserModal] Dispatching Catalog Query Payload:', requestBody);

    // Simulación de respuesta de red / motor FFI
    setTimeout(() => {
      const mockItems: CatalogItem[] = [
        {
          assetId: 'klk-asset-001',
          type: 'score',
          title: 'Sinfonía No. 5 en Do menor, Op. 67',
          composer: 'Ludwig van Beethoven',
          metadata: { genre: 'Clásico', epoch: 'Romántico', key: 'Cm', timeSignature: '2/4', durationMs: 1800000 },
          waveform: [0.1, 0.4, 0.8, 0.9, 0.3, 0.6, 0.2, 0.7, 0.9, 0.5, 0.2, 0.1],
          download: { url: 'https://cdn.klik.pro/scores/beethoven_5.orquesta', sha256: 'da61472bd550b455132072f02b5e76509b74c1b54642bbe2ce8c3a2ad4abf379' },
          rights: {
            status: 'PUBLIC_DOMAIN',
            statusBadge: '🟢',
            details: 'Obra en Dominio Público (ISO 16 / ISO 21771). Libre para arreglo y redistribución.',
            dn_s_percentage: 0.0,
          },
        },
        {
          assetId: 'klk-asset-002',
          type: 'stem',
          title: 'Acoustic Piano Stem (Concert Grand C3)',
          composer: 'KLIK Studio Session',
          metadata: { genre: 'Jazz', epoch: 'Contemporáneo', key: 'C#m', timeSignature: '4/4', durationMs: 210000 },
          waveform: [0.2, 0.5, 0.3, 0.7, 0.4, 0.8, 0.6, 0.3, 0.5, 0.2, 0.4, 0.1],
          download: { url: 'https://cdn.klik.pro/stems/piano_stem.enc', sha256: '8f93b5a19283e746192837461928374619283746192837461928374619283746' },
          rights: {
            status: 'COMMERCIAL_LICENSE',
            statusBadge: '🟡',
            details: 'Licencia Creative Commons Atribución (CC-BY 4.0). Requiere crédito en la obra.',
            dn_s_percentage: 12.4,
          },
        },
        {
          assetId: 'klk-asset-003',
          type: 'midi',
          title: 'Fuga en Sol Menor BWV 578 ("Little Fugue")',
          composer: 'Johann Sebastian Bach',
          metadata: { genre: 'Barroco', epoch: 'Barroco', key: 'Gm', timeSignature: '4/4', durationMs: 235000 },
          waveform: [0.3, 0.6, 0.4, 0.5, 0.8, 0.9, 0.7, 0.6, 0.4, 0.3, 0.2, 0.1],
          download: { url: 'https://cdn.klik.pro/midi/bwv578.mid', sha256: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef' },
          rights: {
            status: 'PUBLIC_DOMAIN',
            statusBadge: '🟢',
            details: 'Patrimonio Abierto. Transcripción verificada a 960 PPQN.',
            dn_s_percentage: 0.0,
          },
        },
        {
          assetId: 'klk-asset-004',
          type: 'score',
          title: 'Contemporary Cinematic Motif #4',
          composer: 'Protected Rights Index #881',
          metadata: { genre: 'Cinematic', epoch: 'Moderno', key: 'Am', timeSignature: '6/8', durationMs: 140000 },
          waveform: [0.8, 0.9, 0.7, 0.8, 0.9, 0.9, 0.8, 0.7, 0.6, 0.8, 0.9, 0.7],
          download: { url: 'https://cdn.klik.pro/scores/cinematic_4.orquesta', sha256: '99887766554433221100aabbccddeeff99887766554433221100aabbccddeeff' },
          rights: {
            status: 'COPYRIGHT_PROTECTED',
            statusBadge: '🔴',
            details: '⚠️ KLIK Rights Guard: Alta Similitud Melódica ($S(A,B) = 84.5\\%$). Requiere autorización de edición.',
            dn_s_percentage: 84.5,
          },
        },
      ];

      setResults(mockItems);
      setPagination({ currentPage: 1, totalPages: 1, totalResults: mockItems.length });
      setIsLoading(false);
    }, 400);
  }, [queryType, searchTerm, selectedAssetTypes, genreFilter, keyFilter, melodicSequence, melodicTolerance, selectedInstrument, pagination.currentPage]);

  useEffect(() => {
    if (isOpen) {
      executeSearch();
    }
  }, [isOpen, executeSearch]);

  const handleImport = async (item: CatalogItem) => {
    setImportingAssetId(item.assetId);
    try {
      await onImportAsset(item);
    } finally {
      setImportingAssetId(null);
    }
  };

  const toggleAssetType = (type: AssetType) => {
    setSelectedAssetTypes((prev) =>
      prev.includes(type) ? prev.filter((t) => t !== type) : [...prev, type]
    );
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4 animate-in fade-in duration-200">
      <div className="flex h-[90vh] w-full max-w-7xl flex-col overflow-hidden rounded-xl border border-slate-800 bg-[#0a0b0e] text-slate-100 shadow-2xl shadow-emerald-950/20">
        
        {/* ==================================================================== */}
        {/* HEADER & TOPBAR                                                       */}
        {/* ==================================================================== */}
        <div className="flex items-center justify-between border-b border-slate-800 bg-[#12141d] px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-400">
              <Sparkles className="h-5 w-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold tracking-wide text-white flex items-center gap-2">
                ASSET & RIGHTS EXPLORER
                <span className="rounded border border-emerald-500/30 bg-emerald-500/10 px-2 py-0.5 text-[10px] font-mono text-emerald-400">
                  KLIK GUARD ACTIVE
                </span>
              </h2>
              <p className="text-xs text-slate-400">
                Buscador pericial de partituras, pistas y verificación de derechos de autor en tiempo real
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="rounded-lg border border-slate-700 bg-slate-800/50 p-2 text-slate-400 hover:bg-slate-800 hover:text-white transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* ==================================================================== */}
        {/* CUERPO PRINCIPAL: SIDEBAR DE FILTROS + REJILLA DE RESULTADOS         */}
        {/* ==================================================================== */}
        <div className="flex flex-1 overflow-hidden">
          
          {/* --- SIDEBAR IZQUIERDO: SELECCIÓN DE MODO Y FILTROS --- */}
          <div className="w-80 border-r border-slate-800 bg-[#0e1017] p-5 flex flex-col gap-6 overflow-y-auto">
            
            {/* TIPO DE BÚSQUEDA */}
            <div>
              <label className="text-xs font-semibold uppercase text-slate-400 font-mono tracking-wider">
                Modo de Búsqueda
              </label>
              <div className="mt-2 grid grid-cols-3 gap-1 rounded-lg bg-slate-900 p-1 border border-slate-800">
                <button
                  onClick={() => setQueryType('METADATA')}
                  className={`flex flex-col items-center gap-1 rounded-md py-2 text-xs font-medium transition-all ${
                    queryType === 'METADATA'
                      ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <Search className="h-4 w-4" />
                  Texto
                </button>
                <button
                  onClick={() => setQueryType('MELODIC')}
                  className={`flex flex-col items-center gap-1 rounded-md py-2 text-xs font-medium transition-all ${
                    queryType === 'MELODIC'
                      ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <Music className="h-4 w-4" />
                  Melódica
                </button>
                <button
                  onClick={() => setQueryType('STEM')}
                  className={`flex flex-col items-center gap-1 rounded-md py-2 text-xs font-medium transition-all ${
                    queryType === 'STEM'
                      ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <Disc className="h-4 w-4" />
                  Stems
                </button>
              </div>
            </div>

            {/* FILTROS ESPECÍFICOS SEGÚN QUERY TYPE */}
            {queryType === 'METADATA' && (
              <div className="flex flex-col gap-4">
                <div>
                  <label className="text-xs text-slate-400">Formatos Aceptados</label>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {(['score', 'stem', 'midi', 'pdf'] as AssetType[]).map((t) => (
                      <button
                        key={t}
                        onClick={() => toggleAssetType(t)}
                        className={`rounded border px-2.5 py-1 text-xs font-mono transition-colors ${
                          selectedAssetTypes.includes(t)
                            ? 'border-emerald-500/50 bg-emerald-500/10 text-emerald-400'
                            : 'border-slate-800 bg-slate-900 text-slate-500 hover:text-slate-300'
                        }`}
                      >
                        .{t}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="text-xs text-slate-400">Género Musical</label>
                  <select
                    value={genreFilter}
                    onChange={(e) => setGenreFilter(e.target.value)}
                    className="mt-1 w-full rounded-md border border-slate-800 bg-slate-900 px-3 py-2 text-xs text-slate-200 focus:border-emerald-500 focus:outline-none"
                  >
                    <option value="all">Todos los Géneros</option>
                    <option value="Clásico">Clásico</option>
                    <option value="Barroco">Barroco</option>
                    <option value="Jazz">Jazz</option>
                    <option value="Cinematic">Cinematic</option>
                  </select>
                </div>
              </div>
            )}

            {queryType === 'MELODIC' && (
              <div className="flex flex-col gap-4">
                <div>
                  <label className="text-xs text-slate-400">Secuencia de Notas (Invarianza Tonal)</label>
                  <input
                    type="text"
                    value={melodicSequence}
                    onChange={(e) => setMelodicSequence(e.target.value)}
                    placeholder="Ej: C4-G4-A4-F4"
                    className="mt-1 w-full rounded-md border border-slate-800 bg-slate-900 px-3 py-2 text-xs font-mono text-emerald-400 focus:border-emerald-500 focus:outline-none"
                  />
                  <p className="mt-1 text-[10px] text-slate-500">
                    Búsqueda por patrón de intervalos ($M_i = \text{MIDI}_{i+1} - \text{MIDI}_i$)
                  </p>
                </div>

                <div>
                  <label className="text-xs text-slate-400">
                    Tolerancia de Similitud ($S\%$): {(melodicTolerance * 100).toFixed(0)}%
                  </label>
                  <input
                    type="range"
                    min="0.5"
                    max="1.0"
                    step="0.05"
                    value={melodicTolerance}
                    onChange={(e) => setMelodicTolerance(parseFloat(e.target.value))}
                    className="mt-2 w-full accent-emerald-500"
                  />
                </div>
              </div>
            )}

            {queryType === 'STEM' && (
              <div className="flex flex-col gap-4">
                <div>
                  <label className="text-xs text-slate-400">Instrumento de Pista</label>
                  <select
                    value={selectedInstrument}
                    onChange={(e) => setSelectedInstrument(e.target.value as any)}
                    className="mt-1 w-full rounded-md border border-slate-800 bg-slate-900 px-3 py-2 text-xs text-slate-200 focus:border-emerald-500 focus:outline-none"
                  >
                    <option value="vocal">Voces / Lead</option>
                    <option value="bass">Bajo / Sub</option>
                    <option value="drums">Batería / Percusión</option>
                    <option value="other">Orquesta / Sintetizadores</option>
                  </select>
                </div>
              </div>
            )}

            {/* BOTÓN EJECUTAR BÚSQUEDA */}
            <button
              onClick={executeSearch}
              disabled={isLoading}
              className="mt-auto flex items-center justify-center gap-2 rounded-lg bg-emerald-600 py-2.5 text-xs font-semibold text-white shadow-lg shadow-emerald-900/30 hover:bg-emerald-500 active:bg-emerald-700 disabled:opacity-50 transition-all"
            >
              {isLoading ? (
                <RefreshCw className="h-4 w-4 animate-spin" />
              ) : (
                <Search className="h-4 w-4" />
              )}
              Buscar en Catálogo
            </button>
          </div>

          {/* --- PANEL DERECHO: BUSCADOR SUPERIOR Y RESULTADOS --- */}
          <div className="flex flex-1 flex-col bg-[#0a0b0e]">
            
            {/* BUSCADOR TEXTUAL DE ENTRADA RÁPIDA */}
            <div className="border-b border-slate-800 bg-[#0e1017]/50 p-4">
              <div className="relative">
                <Search className="absolute left-3.5 top-3 h-4 w-4 text-slate-500" />
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && executeSearch()}
                  placeholder="Buscar por título, compositor, obra o etiqueta..."
                  className="w-full rounded-lg border border-slate-800 bg-slate-900/80 pl-10 pr-4 py-2 text-xs text-slate-100 placeholder-slate-500 focus:border-emerald-500/50 focus:outline-none focus:ring-1 focus:ring-emerald-500/50"
                />
              </div>
            </div>

            {/* MUESTRA DE RESULTADOS EN REJILLA */}
            <div className="flex-1 overflow-y-auto p-6">
              {isLoading ? (
                <div className="flex h-64 flex-col items-center justify-center gap-3 text-slate-500">
                  <RefreshCw className="h-8 w-8 animate-spin text-emerald-500" />
                  <p className="text-xs font-mono">Consultando catálogo y calculando vector de derechos...</p>
                </div>
              ) : results.length === 0 ? (
                <div className="flex h-64 flex-col items-center justify-center text-slate-500">
                  <Music className="h-12 w-12 stroke-1 text-slate-600" />
                  <p className="mt-2 text-xs">No se encontraron activos para los criterios especificados.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  {results.map((item) => (
                    <div
                      key={item.assetId}
                      className="group relative flex flex-col justify-between rounded-xl border border-slate-800/80 bg-[#11131c] p-4 hover:border-slate-700 transition-all shadow-md hover:shadow-xl"
                    >
                      {/* HEADER TARJETA: TITULO + RIGHTS BADGE */}
                      <div>
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex items-center gap-2">
                            {item.type === 'score' && <FileText className="h-4 w-4 text-emerald-400" />}
                            {item.type === 'stem' && <Disc className="h-4 w-4 text-indigo-400" />}
                            {item.type === 'midi' && <Music className="h-4 w-4 text-amber-400" />}
                            <h3 className="text-xs font-bold text-white group-hover:text-emerald-400 transition-colors">
                              {item.title}
                            </h3>
                          </div>

                          {/* RIGHTS BADGE */}
                          <div
                            className={`flex items-center gap-1 rounded border px-2 py-0.5 text-[10px] font-mono font-semibold ${
                              item.rights.status === 'PUBLIC_DOMAIN'
                                ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400'
                                : item.rights.status === 'COMMERCIAL_LICENSE'
                                ? 'border-amber-500/30 bg-amber-500/10 text-amber-400'
                                : 'border-rose-500/30 bg-rose-500/10 text-rose-400'
                            }`}
                            title={item.rights.details}
                          >
                            <span>{item.rights.statusBadge}</span>
                            <span>{item.rights.status}</span>
                          </div>
                        </div>

                        <p className="mt-1 text-[11px] text-slate-400">{item.composer}</p>

                        {/* METADATOS MUSICALES */}
                        <div className="mt-3 flex flex-wrap gap-2 text-[10px] font-mono text-slate-400">
                          <span className="rounded bg-slate-800/60 px-1.5 py-0.5">
                            Tone: {item.metadata.key}
                          </span>
                          <span className="rounded bg-slate-800/60 px-1.5 py-0.5">
                            Meter: {item.metadata.timeSignature}
                          </span>
                          <span className="rounded bg-slate-800/60 px-1.5 py-0.5">
                            {item.metadata.genre}
                          </span>
                        </div>
                      </div>

                      {/* DETALLE DE DERECHOS & BOTON DE IMPORTACIÓN */}
                      <div className="mt-4 border-t border-slate-800/60 pt-3 flex items-center justify-between">
                        <div className="text-[10px] text-slate-500 max-w-[240px] truncate" title={item.rights.details}>
                          {item.rights.details}
                        </div>

                        <button
                          onClick={() => handleImport(item)}
                          disabled={importingAssetId === item.assetId || item.rights.status === 'COPYRIGHT_PROTECTED'}
                          className={`flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold transition-all ${
                            item.rights.status === 'COPYRIGHT_PROTECTED'
                              ? 'border border-slate-800 bg-slate-900 text-slate-600 cursor-not-allowed'
                              : 'bg-emerald-600 text-white hover:bg-emerald-500 active:bg-emerald-700 shadow-md shadow-emerald-950/40'
                          }`}
                        >
                          {importingAssetId === item.assetId ? (
                            <RefreshCw className="h-3.5 w-3.5 animate-spin" />
                          ) : (
                            <Download className="h-3.5 w-3.5" />
                          )}
                          Importar
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* FOOTER: PAGINACIÓN Y ESTADO DE SEGURIDAD */}
            <div className="flex items-center justify-between border-t border-slate-800 bg-[#0e1017] px-6 py-3 text-xs text-slate-400 font-mono">
              <div>
                Resultados totales: <span className="text-emerald-400">{pagination.totalResults}</span>
              </div>
              <div className="flex items-center gap-2">
                <span>Página {pagination.currentPage} de {pagination.totalPages}</span>
              </div>
            </div>

          </div>
        </div>

      </div>
    </div>
  );
};