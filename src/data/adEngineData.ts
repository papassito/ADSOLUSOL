import { AdFunctionItem } from '../types/adEngine';

export const AD_ENGINE_FUNCTIONS: AdFunctionItem[] = [
    {
    id: 'ad-request-ingestion',
    number: '01',
    name: 'Recepci n, Ingesta y Parsing de Solicitudes (Ad Request Handling)',
    shortDescription: 'Captura la llamada publicitaria del navegador, app o Smart TV en menos de 5ms, extrayendo par metros del usuario y contexto.',
    category: 'ingesta',
    categoryLabel: 'Ingesta & Gateway',
    importance: 'Cr tica',
    latencyImpact: '< 4 ms',
    detailedDescription: 'Es la puerta de entrada de todo el ecosistema Ad Tech. Cuando un usuario carga un sitio web o aplicaci n, el SDK del reproductor o tag de JavaScript env a un HTTP/gRPC Ad Request. El motor debe recibir decenas de miles a millones de solicitudes concurrentes por segundo (QPS), autenticar al editor (Publisher ID), verificar la firma SSL, extraer identificadores (PPID, Device ID, cookies consentidas) y decodificar el consent string de privacidad (IAB TCF v2.2, US Privacy / CCPA).',
    keyCapabilities: [
      'Extracci n de metadatos del slot (tama o: 300x250, 728x90, 1920x1080 VAST, intersticial, sticky).',
      'Normalizaci n de User Agent y detecci n de bot inmediato a nivel de cabecera.',
      'Decodificaci n de cadenas de consentimiento de privacidad (GDPR TCF v2.2, COPPA, GPC, Global Privacy Platform).',
      'Geolocalizaci n por IP y resoluci n de operador de telecomunicaciones (ASNs).',
      'Enriquecimiento de se ales contextuales (URL can nica, taxonom a IAB Tech Lab Tier 1-3).'
    ],
    technicalSpecs: {
      protocolOrStandard: 'OpenRTB 2.5/3.0, IAB TCF v2.2, HTTP/2, gRPC',
      metrics: ['QPS (Queries Per Second)', 'Request Latency (p99)', 'Header Error Rate'],
      algorithms: ['Token Bucket Rate Limiting', 'Fast IP Geolocation Lookup (MaxMind/IP2Location)', 'Protobuf deserialization'],
      riskIfFailed: 'P rdida inmediata de monetizaci n e impresiones descartadas por timeout del navegador.'
    },
    codeExample: {
      language: 'json',
      title: 'Objeto OpenRTB 2.5 Ad Request simplificado',
      code: `{
  "id": "req-8974a9f2",
  "imp": [{
    "id": "1",
    "banner": { "w": 300, "h": 250, "pos": 1 },
    "bidfloor": 1.50,
    "bidfloorcur": "USD"
  }],
  "site": {
    "id": "site_882",
    "domain": "noticiasfinancieras.com",
    "cat": ["IAB13", "IAB13-1"]
  },
  "device": { "ip": "189.210.xx.xx", "ua": "Mozilla/5.0 (iPhone; CPU OS 17...)", "geo": { "country": "MEX", "region": "CMX" } },
  "user": { "id": "ppid_user_hash_4492", "consent": "CP12345ABCD..." }
    }`
    }
  },
  {
    id: 'targeting-eligibility',
    number: '02',
    name: 'Segmentaci n y Elegibilidad Multidimensional (Targeting Engine)',
    shortDescription: 'Eval a en milisegundos qu  campa as publicitarias coinciden con las caracter sticas geogr ficas, t cnicas y de audiencia del usuario.',
    category: 'targeting',
    categoryLabel: 'Targeting & Audiencias',
    importance: 'Cr tica',
    latencyImpact: '< 8 ms',
    detailedDescription: 'Un servidor de publicidad puede tener activas cientos de miles de l neas de pedido (Line Items) de anunciantes. El motor de elegibilidad filtra en milisegundos este cat logo masivo para identificar cu les campa as coinciden exactamente con la solicitud entrante. Realiza una b squeda booleana altamente optimizada indexada en memoria (In-Memory Bitsets / inverted indexes).',
    keyCapabilities: [
      'Segmentaci n Geogr fica: Pa s, estado/provincia, ciudad, c digo postal y geocercas por coordenadas GPS.',
      'Segmentaci n Tecnogr fica: Sistema operativo (iOS vs Android), versi n del navegador, fabricante de hardware y tipo de conexi n (WiFi vs 5G).',
      'Segmentaci n de Audiencias First-Party y Segmentos DMP/CDP (compradores frecuentes, carritos abandonados, lookalikes).',
      'Programaci n Temporal (Dayparting): Activaci n solo en horarios comerciales o fines de semana espec ficos seg n la zona horaria del usuario.',
      'Brand Safety & Exclusiones de Contenido: Bloqueo de URLs con contenido violento, pol tico o desastres naturales.'
    ],
    technicalSpecs: {
      protocolOrStandard: 'IAB Audience Taxonomy, IAB Content Taxonomy v3.0, Roaring Bitmaps',
      metrics: ['Eligible Campaigns Ratio', 'Evaluation Latency', 'Cache Hit Ratio'],
      algorithms: ['Inverted Index Matching', 'Roaring Bitmaps Boolean Operations (AND/OR/NOT)', 'Geohash spatial filtering'],
      riskIfFailed: 'Anuncios irrelevantes entregados, multas por infracci n de segmentaci n legal (ej. alcohol/apuestas en menores).'
    },
    codeExample: {
      language: 'typescript',
      title: 'Regla de elegibilidad de targeting en el motor',
      code: `interface TargetingRule {
  geoCountries: string[]; // ['MEX', 'COL', 'ESP']
  deviceTypes: ('mobile' | 'desktop' | 'ctv')[];
  minAgeConsent: boolean;
  daypartingSchedule: { dayOfWeek: number; hours: number[] }[];
  contextualExcludedCats: string[]; // ['IAB25-3', 'IAB25-7']
}

function isEligible(campaign: Campaign, req: AdRequest): boolean {
  if (!campaign.target.geoCountries.includes(req.device.geo.country)) return false;
  if (!campaign.target.deviceTypes.includes(req.device.type)) return false;
  return matchesDayparting(campaign.target.schedule, req.timestamp);
    }`
    }
  },
  {
    id: 'auction-rtb-bidding',
    number: '03',
    name: 'Subasta en Tiempo Real y Fijaci n de Precios (RTB & Auction Engine)',
    shortDescription: 'Coordina la subasta competitiva entre m ltiples anunciantes (DSP, Header Bidding, Ad Networks) calculando el ganador y precio final.',
    category: 'subasta',
    categoryLabel: 'Subasta & Precios',
    importance: 'Cr tica',
    latencyImpact: '< 25 ms',
    detailedDescription: 'Es el n cleo econ mico del motor publicitario. Env a solicitudes de puja a m ltiples plataformas de demanda (DSPs como The Trade Desk, DV360, Amazon DSP) y recolecta sus ofertas concurrentes. Aplica la l gica de subasta (Primer Precio vs Segundo Precio), respeta los pisos de reserva (Price Floors) y orquesta la competencia entre inventario garantizado (direct deals) y program tica abierta.',
    keyCapabilities: [
      'Subastas First-Price (Primer Precio): El ganador paga exactamente lo que ofert ; est ndar global actual para evitar opacidad.',
      'Subastas Second-Price (Vickrey): El ganador paga la segunda mejor oferta m s $0.01 centavo.',
      'Dynamic Price Floors: C lculo algor tmico del precio de reserva m nimo para forzar a los compradores a pujar el valor real del inventario.',
      'Header Bidding & Prebid Mediation: Evaluaci n simult nea de ofertas del lado del cliente y servidor antes de la llamada al Ad Server primario.',
      'Manejo de Deal IDs (Programmatic Guaranteed, Preferred Deals y Private Marketplaces - PMP).'
    ],
    technicalSpecs: {
      protocolOrStandard: 'OpenRTB 2.5 / 3.0, Prebid.js, Prebid Server, Google Ad Manager Open Bidding',
      metrics: ['Win Rate (%)', 'Effective CPM (eCPM)', 'Bid Density', 'Timeout Drop Rate'],
      algorithms: ['First-Price Auction Resolver', 'Vickrey-Clarke-Groves Auction', 'Reinforcement Learning for Floor Prices'],
      riskIfFailed: 'Subastas mal resueltas generan p rdidas de millones de d lares o cobros err neos a los anunciantes.'
    },
    codeExample: {
      language: 'typescript',
      title: 'L gica del motor de subasta (First vs Second Price)',
      code: `function resolveAuction(bids: Bid[], floorPrice: number, mode: 'first_price' | 'second_price') {
  const validBids = bids.filter(b => b.amount >= floorPrice).sort((a, b) => b.amount - a.amount);
  if (validBids.length === 0) return null;
  const winner = validBids[0];
  const clearingPrice = mode === 'first_price' 
     ? winner.amount 
     : (validBids[1] ? Math.max(validBids[1].amount + 0.01, floorPrice) : floorPrice);
  return { winner, clearingPrice };
    }`
    }
  },
  {
    id: 'pacing-budget-control',
    number: '04',
    name: 'Regulaci n de Presupuesto y Ritmo de Gasto (Pacing & Budget Engine)',
    shortDescription: 'Garantiza que el presupuesto se distribuya equilibradamente durante el d a o mes, evitando que se agote en las primeras horas.',
    category: 'pacing',
    categoryLabel: 'Pacing & Presupuesto',
    importance: 'Cr tica',
    latencyImpact: '< 3 ms',
    detailedDescription: 'Si una campa a tiene $10,000 de presupuesto diario y el motor ad no tuviera control de pacing, todo el dinero se gastar a en las primeras 2 horas de la ma ana cuando el tr fico despierta, dejando la campa a inactiva el resto del d a. El motor de pacing utiliza controladores de retroalimentaci n PID y muestreo probabil stico para dosificar las impresiones de manera suave y precisa.',
    keyCapabilities: [
      'Even Pacing (Ritmo Uniforme): Dosifica la probabilidad de puja minuto a minuto calculando la velocidad de gasto esperada vs real.',
      'Accelerated Pacing (Gasto R pido): Puja activamente en todas las oportunidades elegibles; ideal para ventas flash o eventos deportivos en directo.',
      'Lifetime Pacing: Distribuye presupuestos mensuales o de varios meses considerando patrones estacionales (ej. fines de semana con mayor tr fico).',
      'Protecci n Anti Over-Delivery: Bloquea inmediatamente las ofertas cuando el presupuesto diario o total alcanza el 100%, con tolerancia < 0.5%.'
    ],
    technicalSpecs: {
      protocolOrStandard: 'Proportional-Integral-Derivative (PID) Control, Redis Distributed Counters',
      metrics: ['Spend Velocity ($/min)', 'Under-delivery %', 'Over-delivery %', 'Burn Rate'],
      algorithms: ['PID Closed-Loop Controller', 'Probabilistic Throttling (Coin Toss)', 'Dual-Threshold Budget Reservoirs'],
      riskIfFailed: 'Sobregasto no reembolsable asumido por la plataforma, o campa as que no entregan lo prometido al cliente.'
    },
    codeExample: {
      language: 'typescript',
      title: 'Algoritmo de Probabilistic Pacing',
      code: `function calculateBidProbability(spentToday: number, dailyBudget: number, currentMinute: number): number {
  const targetSpend = (dailyBudget / 1440) * currentMinute;
  const delta = targetSpend - spentToday;
  // Si estamos gastando de m s, bajamos la probabilidad de participar en la subasta
  if (delta < 0) {
    return Math.max(0.05, 1.0 - (Math.abs(delta) / targetSpend));
  // Si estamos atrasados, aumentamos la agresividad
  return Math.min(1.0, 1.0 + (delta / targetSpend));
    }`
    }
  },
  {
    id: 'frequency-capping',
    number: '05',
    name: 'Control de Frecuencia y Recencia (Frequency Capping & Fatigue Engine)',
    shortDescription: 'Limita cu ntas veces un usuario espec fico ve el mismo anuncio o campa a por hora, d a o semana, protegiendo la experiencia.',
    category: 'frecuencia',
    categoryLabel: 'Frecuencia & Fatiga',
    importance: 'Alta',
    latencyImpact: '< 5 ms',
    detailedDescription: 'Ver el mismo anuncio 20 veces al d a arruina la percepci n de la marca y satura al usuario ("Ad Fatigue"). El motor de frequency capping consulta memorias cach  distribuidas en memoria ultrarr pidas (Redis / Aerospike) para verificar el contador hist rico de impresiones asociadas a la identidad an nima del usuario antes de autorizar la entrega.',
    keyCapabilities: [
      'Cap por Campa a, L nea de Pedido o Anunciante (ej. m ximo 3 impresiones por usuario cada 24 horas).',
      'Cap por Unidad de Tiempo: Frecuencia por hora, por d a, por semana o por vida  til de la campa a.',
      'Rotaci n Creativa: Si el usuario ya vio la variante creativa A dos veces sin hacer clic, el motor conmuta autom ticamente a la variante B.',
      'Control de Recencia: Establece un intervalo de descanso obligatorio entre impactos (ej. m nimo 15 minutos entre anuncios del mismo anunciante).'
    ],
    technicalSpecs: {
      protocolOrStandard: 'Aerospike / Redis Cluster TTL, HyperLogLog, Cookie Sync / Identity Graphs',
      metrics: ['Unique Reach', 'Average Frequency', 'Fatigue CTR Drop Rate', 'Lookup Latency'],
      algorithms: ['Sliding Window Counter', 'Redis Sliding Log Algorithm', 'Approximate Counting (HyperLogLog)'],
      riskIfFailed: 'Molestia extrema del usuario, desperdicio masivo del presupuesto del anunciante y bloqueo de anuncios.'
    },
    codeExample: {
      language: 'typescript',
      title: 'Verificaci n de frecuencia distribuida',
      code: `async function checkFrequencyCap(userId: string, campaignId: string, limit: number, windowHours: number): Promise<boolean> {
  const cacheKey = \`freq:\${campaignId}:\${userId}\`;
  const currentCount = await redis.incr(cacheKey);
  if (currentCount === 1) {
    await redis.expire(cacheKey, windowHours * 3600);
  return currentCount <= limit;
    }`
    }
  },
  {
    id: 'ml-optimization-ecpm',
    number: '06',
    name: 'Optimizaci n Algor tmica y Machine Learning (eCPM Maximizer & pCTR)',
    shortDescription: 'Predice con IA la probabilidad de clic (pCTR) y conversi n (pCVR) para calcular el valor  ptimo de cada impresi n.',
    category: 'ml',
    categoryLabel: 'IA & Optimizaci',
    importance: 'Estrat gica',
    latencyImpact: '< 10 ms',
    detailedDescription: 'Los anunciantes no compran impresiones a ciegas; compran resultados (clics, ventas, registros). El motor de optimizaci n corre modelos de Machine Learning en tiempo real que eval an cientos de variables (historial del publisher, hora, posici n en pantalla, categor a del anuncio) para predecir la tasa de clic esperada (pCTR) y la tasa de conversi n esperada (pCVR). Con esto calcula el eCPM objetivo: eCPM = Oferta   pCTR   1000.',
    keyCapabilities: [
      'Predicci n de CTR y CVR en tiempo real (< 10ms de inferencia mediante modelos comprimidos con ONNX / TensorRT).',
      'Dynamic Creative Optimization (DCO): Selecci n algor tmica de la imagen, llamada a la acci n y producto m s atractivo para cada perfil.',
      'Multi-Armed Bandit (Exploraci n vs Explotaci n): Dedica un 10% del tr fico a probar nuevas creatividades o publishers y un 90% a maximizar ganancias.',
      'Bid Shading: En subastas de primer precio, predice el valor m nimo necesario para ganar la subasta sin pagar de m s innecesariamente.'
    ],
    technicalSpecs: {
      protocolOrStandard: 'ONNX Runtime, Factorization Machines, Deep & Cross Network (DCN), Multi-Armed Bandit (Thompson Sampling)',
      metrics: ['Log-Loss / AUC-ROC de pCTR', 'eCPM Lift (%)', 'Exploration Regret', 'Inference Latency'],
      algorithms: ['Logistic Regression with FTRL', 'Deep Learning CTR Predictors', 'Thompson Sampling / Upper Confidence Bound (UCB)'],
      riskIfFailed: 'P rdida de competitividad, anuncios con cero interacci n y descalificaci n en subastas de calidad de Google/Meta.'
    },
    codeExample: {
      language: 'python',
      title: 'C lculo de eCPM predictivo y Bid Shading',
      code: `def calculate_ecpm_bid(base_cpc_bid: float, features_vector) -> float:
    # Inferencia ultrarr pida del modelo pCTR (< 5ms)
    p_ctr = model_predict_pctr(features_vector) 
    ecpm = base_cpc_bid * p_ctr * 1000.0 
        
    # Aplicar Bid Shading para no sobrepagar en subastas de 1er precio
    shaded_bid = apply_bid_shading(ecpm, historical_clearing_distribution)
    return shaded_bid`
    }
  },
  {
    id: 'creative-serving-delivery',
    number: '07',
    name: 'Servido y Renderizado Creativo (Creative Delivery & CDN Engine)',
    shortDescription: 'Entrega los activos visuales (HTML5, im genes WebP, video VAST 4.2 / HLS) mediante CDN perimetrales con latencia ultra baja.',
    category: 'entrega',
    categoryLabel: 'Entrega & Formatos',
    importance: 'Alta',
    latencyImpact: '< 15 ms',
    detailedDescription: 'Una vez que se resuelve la subasta, el motor debe ensamblar y entregar el payload del anuncio al navegador o aplicaci n. Esto incluye inyectar etiquetas seguras en iframes aislados (Friendly iFrames / SafeFrames), validar que el c digo creativo no contenga malware o cryptominers, y transmitir flujos de video adaptativos compatibles con la especificaci n IAB VAST.',
    keyCapabilities: [
      'Soporte Multiformato: Display responsivo, Rich Media interactivo con soporte de sensores m viles, Audio digital (DAA) y Video VAST 4.2.',
      'Transcodificaci n Autom tica: Convierte videos pesados en m ltiples bitrates y resoluciones (HLS/DASH) para reproducci n instant nea sin buffering.',
      'SafeFrame 2.0 Isolation: A sla el anuncio en un contenedor seguro para que no pueda acceder a datos privados de la p gina contenedora.',
      'Entrega Global por CDN: Servido desde puntos de presencia (PoPs) a menos de 20ms del usuario final.'
    ],
    technicalSpecs: {
      protocolOrStandard: 'IAB VAST 4.2, SIMID, SafeFrame 2.0, MRAID 3.0, WebP, AVIF, HLS',
      metrics: ['Render Time (Time to First Frame)', 'Payload Weight (KB)', 'Creative Error Rate (VAST 900)'],
      algorithms: ['On-the-fly Image Optimization', 'Adaptive Bitrate Streaming', 'SafeFrame Sandbox PostMessage Bridge'],
      riskIfFailed: 'Anuncio en blanco (White Screen of Death), retraso en la carga de la p gina del medio y penalizaci n de SEO (Core Web Vitals).'
    },
    codeExample: {
      language: 'xml',
      title: 'Estructura de respuesta VAST 4.2 para video',
      code: `<VAST version="4.2">
  <Ad id="20001">
    <InLine>
      <AdSystem version="2.0">AdEngine</AdSystem>
      <AdTitle>Spot Comercial 30s</AdTitle>
      <Impression id="imp_track"><![CDATA[https://engine.ad/track/imp?bid=8974]]></Impression>
      <Creatives>
        <Creative id="cr_1">
          <Linear>
            <Duration>00:00:15</Duration>
            <MediaFiles>
              <MediaFile delivery="progressive" type="video/mp4" width="1920" height="1080">
                <![CDATA[https://cdn.engine.ad/creatives/spot_1080p.mp4]]>
              </MediaFile>
            </MediaFiles>
          </Linear>
        </Creative>
      </Creatives>
    </InLine>
  </Ad>
</VAST>`
    }
  },
  {
    id: 'tracking-telemetry-viewability',
    number: '08',
    name: 'Telemetr a, Visibilidad y Tracking de Eventos (Telemetry & Viewability)',
    shortDescription: 'Registra de manera verificable cada impresi n, visibilidad real seg n est ndar MRC, clics y cuartiles de reproducci n de video.',
    category: 'tracking',
    categoryLabel: 'Telemetr a & MRC',
    importance: 'Cr tica',
    latencyImpact: '< 5 ms',
    detailedDescription: 'En la publicidad digital, una impresi n solo se cobra si es v lida y medible. El motor de telemetr a procesa los disparos de p xeles (beacons HTTP GET/POST as ncronos con navigator.sendBeacon) cuando el anuncio aparece en pantalla. Aplica la norma de la Media Rating Council (MRC): al menos el 50% de los p xeles debe estar visible en el viewport durante al menos 1 segundo continuo para display y 2 segundos para video.',
    keyCapabilities: [
      'Medici n de Visibilidad MRC y OM SDK (Open Measurement SDK) en navegadores, aplicaciones nativas y TV conectada.',
      'Tracking de Cuartiles de Video: Eventos FirstQuartile (25%), Midpoint (50%), ThirdQuartile (75%), Complete (100%), Mute, Pause y Replay.',
      'Tracking de Clics Seguro con Redirecci n Criptogr fica para evitar adulteraci n de URLs de destino.',
      'Medici n de Tiempo de Exposici n (Time-in-View) y tasa de atenci n del usuario.'
    ],
    technicalSpecs: {
      protocolOrStandard: 'IAB Open Measurement Interface Definition (OMID), Media Rating Council (MRC) Standards, W3C IntersectionObserver API',
      metrics: ['Viewability Rate (%)', 'CTR (Click-Through Rate)', 'Video Completion Rate (VCR)', 'Time-in-View (segundos)'],
      algorithms: ['Geometric IntersectionObserver Polling', 'Zero-Drop Event Ingestion Pipelines (Kafka / Kinesis)', 'Pixel Signature Verification'],
      riskIfFailed: 'Los anunciantes no pagan las impresiones no verificables; discrepancias de cobro y p rdida de certificaciones de auditor'
    },
    codeExample: {
      language: 'javascript',
      title: 'Verificaci n de visibilidad MRC con IntersectionObserver',
      code: `const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    // Regla MRC: 50% de p xeles visible durante 1000ms continuos
    if (entry.intersectionRatio >= 0.50) {
      if (!window.viewTimer) {
        window.viewTimer = setTimeout(() => {
          navigator.sendBeacon('https://engine.ad/track/viewable_impression', payload);
        }, 1000);
      }
    } else {
      clearTimeout(window.viewTimer);
      window.viewTimer = null;
    }
  });
}, { threshold: [0.5] });`
    }
  },
  {
    id: 'antifraud-brand-safety',
    number: '09',
    name: 'Antifraude, Seguridad de Marca e IVT (Fraud Detection & Brand Safety)',
    shortDescription: 'Filtra tr fico falso de bots (GIVT/SIVT), granjas de clics, ad stacking y protege a las marcas de salir en sitios da inos.',
    category: 'seguridad',
    categoryLabel: 'Seguridad & Fraude',
    importance: 'Cr tica',
    latencyImpact: '< 8 ms',
    detailedDescription: 'El fraude publicitario cuesta decenas de miles de millones de d lares al a o. El motor de seguridad inspecciona cada interacci n para detectar Tr fico Inv lido General (GIVT: bots de b squeda conocidos) y Tr fico Inv lido Sofisticado (SIVT: malware residencial, granjas de clics, suplantaci n de dominio o ad stacking, donde apilan 10 anuncios invisibles uno encima del otro). Adem s, bloquea inventario que incumple las pol ticas del anunciante.',
    keyCapabilities: [
      'Filtrado GIVT y SIVT certificado por el MRC y TAG (Trustworthy Accountability Group).',
      'Detecci n de Ad Stacking y Pixel Stuffing (anuncios de 1x1 p xeles que generan impresiones falsas).',
      'Validaci n de Cadena de Suministro: Inspecci n de ads.txt, app-ads.txt y sellers.json para evitar dominios suplantados.',
      'Brand Safety & Contextual Suitability: An lisis sem ntico mediante NLP para evitar que un anuncio de aerol nea aparezca junto a una noticia de un accidente a reo.'
    ],
    technicalSpecs: {
      protocolOrStandard: 'TAG Certified Against Fraud, IAB ads.txt / app-ads.txt / sellers.json, MRC IVT Guidelines',
      metrics: ['IVT Rate (%)', 'Spoofed Domain Rate', 'Brand Safety Violation Rate', 'False Positive Rate'],
      algorithms: ['Behavioral Biometrics (mouse velocity, tap entropy)', 'Domain Spoofing Cryptographic Check', 'BERT/Transformer Semantic Text Analysis'],
      riskIfFailed: 'Demandas legales de marcas por aparecer en contenido ilegal o terrorista; reembolsos forzados por tr fico falso de bots.'
    },
    codeExample: {
      language: 'typescript',
      title: 'Validaci n de ads.txt y Sellers.json en el motor',
      code: `async function verifySupplyChain(publisherDomain: string, sellerId: string, publisherAccount: string): Promise<boolean> {
  const adsTxtRecords = await fetchAdsTxt(publisherDomain);
  const match = adsTxtRecords.find(r => r.exchangeDomain === 'adengine.net' && r.accountId === publisherAccount);
  if (!match) return false; // Tr fico no autorizado por el due o del dominio
  return match.relationshipType === 'DIRECT' || match.relationshipType === 'RESELLER';
    }`
    }
  },
  {
    id: 'attribution-yield-management',
    number: '10',
    name: 'Atribuci n, Conciliaci n y Yield Management (Attribution & Analytics)',
    shortDescription: 'Asigna el valor a las ventas generadas (Post-Click / Post-View) y concilia las discrepancias de facturaci n entre plataformas.',
    category: 'atribucion',
    categoryLabel: 'Atribuci n & Yield',
    importance: 'Estrat gica',
    latencyImpact: 'As ncrono (Batch)',
    detailedDescription: 'Cierra el ciclo comercial de la publicidad. Mide qu  anuncios condujeron a compras reales, descargas de apps o registros, calculando el Retorno de la Inversi n Publicitaria (ROAS). Para los editores (Publishers), el m dulo de Yield Management maximiza los ingresos decidiendo si conviene m s vender la impresi n a una campa a directa de $10 CPM o al mercado program tico abierto.',
    keyCapabilities: [
      'Modelos de Atribuci n Multitoque (MTA): Primer Clic,  ltimo Clic, Lineal, Decrecimiento Temporal y Modelos Algor tmicos Basados en Datos (Data-Driven).',
      'Atribuci n Post-Click (ej. ventana de 30 d as) y Post-View / View-Through (ej. ventana de 24 horas).',
      'Conciliaci n de Discrepancias Financieras: Algoritmos de reconciliaci n que ajustan diferencias de conteo entre el DSP y el Ad Server (t picamente < 2-3%).',
      'Waterfall & Unified Pricing: Comparaci n en tiempo real entre precios de reserva, acuerdos privados y pujas del mercado abierto para maximizar el RPM del editor.'
    ],
    technicalSpecs: {
      protocolOrStandard: 'W3C Attribution Reporting API, SKAdNetwork / Privacy Sandbox, Click IDs (gclid, fbclid, dclid)',
      metrics: ['ROAS (Return on Ad Spend)', 'eCPM / RPM', 'Discrepancy %', 'Conversion Rate (CVR)', 'Fill Rate (%)'],
      algorithms: ['Shapley Value Attribution', 'Markov Chain Attribution Models', 'Dynamic Yield Optimization Linear Programming'],
      riskIfFailed: 'Informes financieros err neos, incapacidad para demostrar el ROI a los clientes y p rdida masiva de ingresos.'
    },
    codeExample: {
      language: 'typescript',
      title: 'Modelo de Atribuci n Basado en Cadenas de Markov',
      code: `interface Touchpoint {
  channel: string; // 'Display', 'Video', 'Search', 'Social'
  timestamp: number;
}

function calculateMarkovRemovalEffect(journeys: Touchpoint[][], targetChannel: string): number {
  // Simula la tasa de conversi n global sin el canal objetivo para determinar su aporte incremental real
  const baseConversionRate = computeGlobalConversionRate(journeys);
  const withoutChannelRate = computeConversionRateExcluding(journeys, targetChannel);
  return (baseConversionRate - withoutChannelRate) / baseConversionRate;
    }`
    }
  }
];

export const MOCK_BIDDERS: { [key: string]: { name: string; dsp: string; bid: number; pCTR: number; pCVR: number; brandCategory: string; creativeUrl: string; advertiser: string } } = {
  dv360: {
    name: 'Google DV360 (Display & Video 360)',
    dsp: 'DV360',
    bid: 4.80,
    pCTR: 0.0035, // 0.35% CTR
    pCVR: 0.045,
    brandCategory: 'Finanzas y Banca',
    creativeUrl: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=400&q=80',
    advertiser: 'Banco Global Neo'
  },
  tradedesk: {
    name: 'The Trade Desk (TTD Open Marketplace)',
    dsp: 'The Trade Desk',
    bid: 5.40,
    pCTR: 0.0042, // 0.42% CTR
    pCVR: 0.060,
    brandCategory: 'Automotriz',
    creativeUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400&q=80',
    advertiser: 'Apex Motors EV'
  },
  amazon: {
    name: 'Amazon DSP (E-Commerce Intent)',
    dsp: 'Amazon DSP',
    bid: 3.90,
    pCTR: 0.0055, // 0.55% CTR
    pCVR: 0.082,
    brandCategory: 'Electr nica de Consumo',
    creativeUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80',
    advertiser: 'SoundWave Auriculares'
  },
  criteo: {
    name: 'Criteo Retail Media & Retargeting',
    dsp: 'Criteo',
    bid: 4.10,
    pCTR: 0.0048,
    pCVR: 0.075,
    brandCategory: 'Moda y Retail',
    creativeUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
    advertiser: 'Moda Urbana Store'
  }
};
