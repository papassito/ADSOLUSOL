export type EngineCategory = 'adtech' | 'activedirectory' | 'directdrive';

export interface AdFunctionItem {
  id: string;
  number: string;
  name: string;
  shortDescription: string;
  category: 'ingesta' | 'targeting' | 'subasta' | 'pacing' | 'frecuencia' | 'ml' | 'entrega' | 'tracking' | 'seguridad' | 'atribucion';
  categoryLabel: string;
  importance: 'Crítica' | 'Alta' | 'Estratégica';
  latencyImpact: string; // e.g. "< 5 ms"
  detailedDescription: string;
  keyCapabilities: string[];
  technicalSpecs: {
    protocolOrStandard: string;
    metrics: string[];
    algorithms: string[];
    riskIfFailed: string;
  };
  codeExample?: {
    language: string;
    title: string;
    code: string;
  };
}

export interface AdBidder {
  name: string;
  dsp: string;
  bid: number; // USD CPM
  pCTR: number; // predicted CTR (0 - 1)
  pCVR: number; // predicted CVR (0 - 1)
  brandCategory: string;
  creativeUrl: string;
  advertiser: string;
}
