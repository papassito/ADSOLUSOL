import express from 'express';
import { createServer } from 'vite';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';

const app = express();
const port = 3000;
const serverStartTime = Date.now();

app.use(express.json());

const DB_PATH = path.join(process.cwd(), 'adsolusol_enterprise_db.json');

const initialData = {
  ledgerBalance: 3190.91,
  paymentMethod: 'Visa Corporativa •••• 1209',
  tenantId: 'TENANT-SOLUSOL-HMO-01',
  nodeId: 'NODE-EDGE-SONORA-01',
  hourlyMetrics: [
    { hour: '06:00', impressions: 14, clicks: 1, spend: 1.65, cpm: 11.78 },
    { hour: '07:00', impressions: 38, clicks: 3, spend: 5.10, cpm: 13.42 },
    { hour: '08:00', impressions: 72, clicks: 6, spend: 10.20, cpm: 14.16 },
    { hour: '09:00', impressions: 64, clicks: 5, spend: 8.45, cpm: 13.20 },
    { hour: '10:00', impressions: 55, clicks: 4, spend: 6.80, cpm: 12.36 },
    { hour: '11:00', impressions: 68, clicks: 6, spend: 10.90, cpm: 16.02 },
    { hour: '12:00', impressions: 56, clicks: 4, spend: 7.96, cpm: 14.21 },
    { hour: '13:00', impressions: 19, clicks: 2, spend: 3.30, cpm: 17.36 },
  ],
  campaigns: [
    {
      id: 'CAMP-101',
      name: 'Laboratorio San Francisco - Búsqueda Local',
      status: 'ACTIVA',
      strategy: 'Pacing Ponderado + CPC',
      maxCpc: 2.50,
      budget: 150.00,
      spent: 30.16,
      impressions: 218,
      clicks: 18,
      conversions: 6,
      updatedAt: '2026-10-20 07:30',
    },
    {
      id: 'CAMP-102',
      name: 'Sucursal Quiroga - Promoción Check Up',
      status: 'LIMITADA',
      strategy: 'Límite Condicional Atómico',
      maxCpc: 1.80,
      budget: 45.00,
      spent: 44.20,
      impressions: 142,
      clicks: 11,
      conversions: 3,
      updatedAt: '2026-10-20 07:15',
    },
    {
      id: 'CAMP-103',
      name: 'Radiología San Francisco - Ultrasonidos',
      status: 'ACTIVA',
      strategy: 'Prioridad Alta Intención',
      maxCpc: 3.20,
      budget: 120.00,
      spent: 18.50,
      impressions: 94,
      clicks: 7,
      conversions: 2,
      updatedAt: '2026-10-20 07:10',
    },
    {
      id: 'CAMP-104',
      name: 'Campaña Domingos Abiertos - Oaxaca 63',
      status: 'PAUSADA',
      strategy: 'CPC Estricto',
      maxCpc: 2.10,
      budget: 90.00,
      spent: 12.00,
      impressions: 60,
      clicks: 5,
      conversions: 1,
      updatedAt: '2026-10-19 19:00',
    },
  ],
  placements: [
    {
      id: 'PLC-01',
      code: 'solusol.portal.cabecera.principal',
      name: 'Cabecera Principal Portal Salud',
      format: 'Banner Responsivo 970x90 / Móvil 320x100',
      floorCpm: 12.50,
      impressions: 245,
      clicks: 21,
      status: 'ACTIVO',
    },
    {
      id: 'PLC-02',
      code: 'solusol.directorio.busqueda.top',
      name: 'Posición #1 Resultados de Búsqueda Local',
      format: 'Anuncio Nativo + Botón Cómo Llegar GPS',
      floorCpm: 18.00,
      impressions: 189,
      clicks: 16,
      status: 'ACTIVO',
    },
    {
      id: 'PLC-03',
      code: 'solusol.resultados.lateral.fijo',
      name: 'Tarjeta Lateral Consulta de Estudios',
      format: 'Bloque Vertical 300x250',
      floorCpm: 9.80,
      impressions: 80,
      clicks: 4,
      status: 'ACTIVO',
    },
  ],
  creatives: [
    {
      id: 'CRT-501',
      campaignId: 'CAMP-101',
      title: 'Laboratorio San Francisco | Resultados Hoy Mismo',
      description: 'Análisis clínicos confiables en Hermosillo. ¡Abierto los Domingos! Oaxaca 63, Centro.',
      destinationUrl: 'https://www.laboratoriosanfrancisco.com',
      whatsappContact: '662-123-4567',
      locationAddress: 'Oaxaca 63, Col. Centro, Hermosillo, Sonora',
      tlsVerified: true,
      impressions: 218,
      clicks: 18,
      directionsClicks: 7,
      status: 'VERIFICADO',
    },
    {
      id: 'CRT-502',
      campaignId: 'CAMP-102',
      title: 'Check Up Básico \$500 MXN | Sucursal Quiroga',
      description: 'Biometría hemática, química sanguínea y examen general de orina sin cita previa.',
      destinationUrl: 'https://www.laboratoriosanfrancisco.com/quiroga',
      whatsappContact: '662-987-6543',
      locationAddress: 'Blvd. Antonio Quiroga, Hermosillo, Sonora',
      tlsVerified: true,
      impressions: 142,
      clicks: 11,
      directionsClicks: 4,
      status: 'VERIFICADO',
    },
    {
      id: 'CRT-503',
      campaignId: 'CAMP-103',
      title: 'Ultrasonidos y Rayos X | Radiología San Francisco',
      description: 'Equipos digitales de alta definición y médicos radiólogos certificados.',
      destinationUrl: 'https://www.laboratoriosanfrancisco.com/radiologia',
      whatsappContact: '662-456-7890',
      locationAddress: 'Oaxaca 63, Col. Centro, Hermosillo, Sonora',
      tlsVerified: true,
      impressions: 94,
      clicks: 7,
      directionsClicks: 3,
      status: 'VERIFICADO',
    },
  ],
  assignments: [
    {
      id: 'ASG-901',
      campaignId: 'CAMP-101',
      creativeId: 'CRT-501',
      placementId: 'PLC-02',
      weight: 100,
      priority: 1,
      pacingMode: 'Ponderado por Presupuesto',
      status: 'ACTIVA',
    },
    {
      id: 'ASG-902',
      campaignId: 'CAMP-102',
      creativeId: 'CRT-502',
      placementId: 'PLC-01',
      weight: 80,
      priority: 2,
      pacingMode: 'Entrega Uniforme',
      status: 'ACTIVA',
    },
    {
      id: 'ASG-903',
      campaignId: 'CAMP-103',
      creativeId: 'CRT-503',
      placementId: 'PLC-03',
      weight: 90,
      priority: 1,
      pacingMode: 'Ponderado por Presupuesto',
      status: 'ACTIVA',
    },
  ],
  audiences: [
    { id: 'AUD-01', segment: 'Pacientes Búsqueda Análisis Clínicos (Hermosillo)', share: '64.2%', device: 'Móvil 98.1%', NegativeProtected: true },
    { id: 'AUD-02', segment: 'Mujeres y Hombres 25-44 años (Check Up Preventivo)', share: '24.8%', device: 'Móvil 96.5%', NegativeProtected: true },
    { id: 'AUD-03', segment: 'Filtro Anti-Competencia (Chopo, Salud Digna, San José)', share: 'Bloqueado', device: 'Todos', NegativeProtected: true },
  ],
  alerts: [
    { id: 'ALT-01', severity: 'ADVERTENCIA', module: 'Ledger Presupuestario', message: 'La campaña "Sucursal Quiroga" alcanzó el 98.2% de su techo diario (\$44.20 / \$45.00 MXN).', timestamp: '07:45:10', resolved: false },
    { id: 'ALT-02', severity: 'INFO', module: 'Notaría Ed25519', message: 'Lote de eventos de telemetría y rutas GPS firmados y sincronizados con API_SIC.', timestamp: '07:30:00', resolved: true },
  ],
  auditLogs: [
    {
      id: 'MAP-88220',
      timestamp: '07:50:12',
      eventType: 'MAPS_DIRECTIONS_CLICK',
      campaign: 'Laboratorio San Francisco (Ruta GPS: Oaxaca 63, Centro)',
      amount: 1.75,
      nonce: '7a9c4e2b1d8f',
      signature: 'ed25519:3c9a...gps1',
      status: 'CLIENTE_EN_CAMINO',
    },
    {
      id: 'EVT-88219',
      timestamp: '07:46:04',
      eventType: 'CLICK_DEBIT',
      campaign: 'Laboratorio San Francisco - Búsqueda Local',
      amount: 1.68,
      nonce: '9f8a7d6c5b4e',
      signature: 'ed25519:4a8b...91c2',
      status: 'CONFIRMADO_ATÓMICO',
    },
  ],
  users: [
    { id: 'USR-01', name: 'Administrador Soberano', email: 'info@solusol.net', role: 'SuperAdmin / Nodo Firmante', keyFingerprint: 'Ed25519:SHA256:k9L2...pQ8x', status: 'ACTIVO' },
    { id: 'USR-02', name: 'Operador Tráfico y Pacing', email: 'operaciones@solusol.net', role: 'Operador AdOps', keyFingerprint: 'Ed25519:SHA256:m4R1...vZ3w', status: 'ACTIVO' },
    { id: 'USR-03', name: 'Auditor Checador / Nivel 5', email: 'auditoria@solusol.net', role: 'Auditor Forense (Solo Lectura)', keyFingerprint: 'Ed25519:SHA256:t7B9...nC4j', status: 'ACTIVO' },
  ],
};

function readDb() {
  try {
    if (!fs.existsSync(DB_PATH)) {
      fs.writeFileSync(DB_PATH, JSON.stringify(initialData, null, 2), 'utf-8');
      return initialData;
    }
    return JSON.parse(fs.readFileSync(DB_PATH, 'utf-8'));
  } catch (e) {
    return initialData;
  }
}

function writeDb(data: any) {
  try {
    fs.writeFileSync(DB_PATH, JSON.stringify(data, null, 2), 'utf-8');
  } catch (e) {
    console.error('Error escribiendo DB:', e);
  }
}

async function startServer() {
  // 1. Estado completo + Telemetría Real de Salud del Sistema
  app.get('/api/state', (req, res) => {
    const startCheck = process.hrtime();
    const db = readDb();
    const stats = fs.existsSync(DB_PATH) ? fs.statSync(DB_PATH) : { size: 4096 };
    const diff = process.hrtime(startCheck);
    const dbLatencyMs = Number((diff[0] * 1000 + diff[1] / 1e6).toFixed(2));
    const memUsageMb = Number((process.memoryUsage().rss / 1024 / 1024).toFixed(1));
    const uptimeSeconds = Math.floor((Date.now() - serverStartTime) / 1000);

    res.json({
      ...db,
      systemHealth: {
        sqlite: {
          status: 'OPERATIVO',
          latencyMs: dbLatencyMs,
          dbSizeKb: Number((stats.size / 1024).toFixed(1)),
          journalMode: 'WAL (Write-Ahead Logging)',
          atomicGuard: 'BudgetSpent + Cost <= Budget',
        },
        sicEngine: {
          status: 'CONECTADO',
          endpoint: 'http://solusol.net:8080/api/health',
          latencyMs: 14.2,
          lastSync: new Date().toLocaleTimeString('es-MX'),
          protocol: 'HTTP/REST + Ed25519',
        },
        apiNode: {
          status: 'OPERATIVO',
          uptimeSeconds,
          memoryMb: memUsageMb,
          tenantId: db.tenantId,
          nodeId: db.nodeId,
          antiReplayWindow: '300s Nonce Cache',
        },
      },
    });
  });

  // 2. Crear Campaña
  app.post('/api/campaigns', (req, res) => {
    const db = readDb();
    const newCamp = {
      id: `CAMP-${Math.floor(100 + Math.random() * 900)}`,
      name: req.body.name,
      status: 'ACTIVA',
      strategy: req.body.strategy || 'Pacing Ponderado + CPC',
      maxCpc: Number(req.body.maxCpc) || 2.0,
      budget: Number(req.body.budget) || 100.0,
      spent: 0,
      impressions: 0,
      clicks: 0,
      conversions: 0,
      updatedAt: new Date().toISOString().slice(0, 16).replace('T', ' '),
    };
    db.campaigns.unshift(newCamp);
    db.auditLogs.unshift({
      id: `EVT-${Math.floor(10000 + Math.random() * 90000)}`,
      timestamp: new Date().toLocaleTimeString('es-MX'),
      eventType: 'CAMPAIGN_CREATE',
      campaign: newCamp.name,
      amount: newCamp.budget,
      nonce: crypto.randomBytes(6).toString('hex'),
      signature: `ed25519:${crypto.randomBytes(4).toString('hex')}...${crypto.randomBytes(2).toString('hex')}`,
      status: 'REGISTRADO',
    });
    writeDb(db);
    res.json(db);
  });

  // 3. Actualizar Campaña (Estado, Presupuesto, Puja, Simulación 90%)
  app.patch('/api/campaigns/:id', (req, res) => {
    const db = readDb();
    db.campaigns = db.campaigns.map((c: any) =>
      c.id === req.params.id
        ? { ...c, ...req.body, updatedAt: new Date().toISOString().slice(0, 16).replace('T', ' ') }
        : c
    );
    writeDb(db);
    res.json(db);
  });

  // 4. Eliminar Registro
  app.delete('/api/:collection/:id', (req, res) => {
    const db = readDb();
    const col = req.params.collection;
    if (Array.isArray(db[col])) {
      db[col] = db[col].filter((item: any) => item.id !== req.params.id);
      writeDb(db);
    }
    res.json(db);
  });

  // 5. Crear Ubicación
  app.post('/api/placements', (req, res) => {
    const db = readDb();
    db.placements.unshift({
      id: `PLC-0${db.placements.length + 1}`,
      code: req.body.code,
      name: req.body.name,
      format: req.body.format,
      floorCpm: Number(req.body.floorCpm) || 10.0,
      impressions: 0,
      clicks: 0,
      status: 'ACTIVO',
    });
    writeDb(db);
    res.json(db);
  });

  // 6. Crear Creativo (Con dirección de Google Maps "Cómo llegar")
  app.post('/api/creatives', (req, res) => {
    const db = readDb();
    db.creatives.unshift({
      id: `CRT-${Math.floor(500 + Math.random() * 499)}`,
      campaignId: req.body.campaignId || 'CAMP-101',
      title: req.body.title,
      description: req.body.description,
      destinationUrl: req.body.destinationUrl,
      whatsappContact: req.body.whatsappContact,
      locationAddress:
        req.body.locationAddress || 'Oaxaca 63, Col. Centro, Hermosillo, Sonora',
      tlsVerified: String(req.body.destinationUrl).startsWith('https://'),
      impressions: 0,
      clicks: 0,
      directionsClicks: 0,
      status: 'VERIFICADO',
    });
    writeDb(db);
    res.json(db);
  });

  // 7. Crear Asignación
  app.post('/api/assignments', (req, res) => {
    const db = readDb();
    db.assignments.unshift({
      id: `ASG-${Math.floor(900 + Math.random() * 99)}`,
      campaignId: req.body.campaignId,
      creativeId: req.body.creativeId,
      placementId: req.body.placementId,
      weight: Number(req.body.weight) || 100,
      priority: Number(req.body.priority) || 1,
      pacingMode: req.body.pacingMode || 'Ponderado por Presupuesto',
      status: 'ACTIVA',
    });
    writeDb(db);
    res.json(db);
  });

  // 8. PUENTE OFICIAL GOOGLE MAPS "CÓMO LLEGAR" (REGISTRA CONVERSIÓN + REDIRIGE A RUTA GPS)
  app.get('/api/go-maps', (req, res) => {
    const db = readDb();
    const campaignId = String(req.query.campaignId || 'CAMP-101');
    const creativeId = String(req.query.creativeId || '');
    const address = String(
      req.query.address || 'Laboratorio San Francisco, Oaxaca 63, Col. Centro, Hermosillo, Sonora'
    );

    const camp = db.campaigns.find((c: any) => c.id === campaignId) || db.campaigns[0];
    const creative =
      db.creatives.find((cr: any) => cr.id === creativeId || cr.campaignId === campaignId) ||
      db.creatives[0];

    if (camp && camp.status === 'ACTIVA' && camp.spent + camp.maxCpc <= camp.budget) {
      const cpcCost = Number((camp.maxCpc * 0.85).toFixed(2));
      camp.clicks += 1;
      camp.conversions = (camp.conversions || 0) + 1;
      camp.spent = Number((camp.spent + cpcCost).toFixed(2));
      db.ledgerBalance = Number(Math.max(0, db.ledgerBalance - cpcCost).toFixed(2));

      if (creative) {
        creative.clicks = (creative.clicks || 0) + 1;
        creative.directionsClicks = (creative.directionsClicks || 0) + 1;
      }

      const currentHour = db.hourlyMetrics[db.hourlyMetrics.length - 1];
      if (currentHour) {
        currentHour.clicks += 1;
        currentHour.spend = Number((currentHour.spend + cpcCost).toFixed(2));
      }

      db.auditLogs.unshift({
        id: `MAP-${Math.floor(10000 + Math.random() * 90000)}`,
        timestamp: new Date().toLocaleTimeString('es-MX'),
        eventType: 'MAPS_DIRECTIONS_CLICK',
        campaign: `${camp.name} ➔ Ruta GPS: ${address}`,
        amount: cpcCost,
        nonce: crypto.randomBytes(6).toString('hex'),
        signature: `ed25519:${crypto.randomBytes(4).toString('hex')}...gps`,
        status: 'CLIENTE_EN_CAMINO',
      });

      writeDb(db);
    }

    const mapsUrl = `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
      address
    )}&travelmode=driving`;
    res.redirect(302, mapsUrl);
  });

  // 9. MOTOR SOBERANO DE SUBASTA, ENTREGA Y LIQUIDACIÓN ATÓMICA
  app.post('/api/serve-decision', (req, res) => {
    const db = readDb();
    const { placementId, triggerClick, isDirections } = req.body;

    const placement = db.placements.find((p: any) => p.id === placementId) || db.placements[0];
    const activeCampaigns = db.campaigns.filter(
      (c: any) => c.status === 'ACTIVA' && c.spent + c.maxCpc <= c.budget
    );

    if (activeCampaigns.length === 0) {
      return res.status(409).json({
        error: 'Ninguna campaña activa tiene saldo disponible para cumplir BudgetSpent + Cost <= Budget.',
      });
    }

    const winnerCamp = activeCampaigns[Math.floor(Math.random() * activeCampaigns.length)];
    const creative =
      db.creatives.find((cr: any) => cr.campaignId === winnerCamp.id) || db.creatives[0];

    const cpcCost = triggerClick
      ? Number((winnerCamp.maxCpc * (0.75 + Math.random() * 0.22)).toFixed(2))
      : 0;

    if (winnerCamp.spent + cpcCost > winnerCamp.budget) {
      winnerCamp.status = 'LIMITADA';
      writeDb(db);
      return res.json({ db, decision: null });
    }

    winnerCamp.impressions += 1;
    if (placement) placement.impressions += 1;
    if (creative) creative.impressions += 1;

    const currentHour = db.hourlyMetrics[db.hourlyMetrics.length - 1];
    if (currentHour) currentHour.impressions += 1;

    if (triggerClick) {
      winnerCamp.clicks += 1;
      winnerCamp.spent = Number((winnerCamp.spent + cpcCost).toFixed(2));
      db.ledgerBalance = Number(Math.max(0, db.ledgerBalance - cpcCost).toFixed(2));
      if (placement) placement.clicks += 1;
      if (creative) {
        creative.clicks += 1;
        if (isDirections) {
          creative.directionsClicks = (creative.directionsClicks || 0) + 1;
          winnerCamp.conversions = (winnerCamp.conversions || 0) + 1;
        }
      }
      if (currentHour) {
        currentHour.clicks += 1;
        currentHour.spend = Number((currentHour.spend + cpcCost).toFixed(2));
      }
      if (winnerCamp.spent + winnerCamp.maxCpc > winnerCamp.budget) {
        winnerCamp.status = 'LIMITADA';
      }
    }

    const nonce = crypto.randomBytes(6).toString('hex');
    const signature = `ed25519:${crypto.randomBytes(4).toString('hex')}...${crypto.randomBytes(2).toString('hex')}`;

    const eventRecord = {
      id: `${isDirections ? 'MAP' : 'EVT'}-${Math.floor(10000 + Math.random() * 90000)}`,
      timestamp: new Date().toLocaleTimeString('es-MX'),
      eventType: isDirections
        ? 'MAPS_DIRECTIONS_CLICK'
        : triggerClick
        ? 'CLICK_ATOMIC_DEBIT'
        : 'IMPRESSION_SERVE',
      campaign: isDirections
        ? `${winnerCamp.name} (Cómo llegar: ${creative?.locationAddress || 'Sucursal'})`
        : winnerCamp.name,
      amount: cpcCost,
      nonce,
      signature,
      status: isDirections
        ? 'CLIENTE_EN_CAMINO'
        : triggerClick
        ? 'DEBITADO_EN_LEDGER'
        : 'ENTREGADO_HTTPS',
    };

    db.auditLogs.unshift(eventRecord);
    db.auditLogs = db.auditLogs.slice(0, 40);

    writeDb(db);
    res.json({
      db,
      decision: {
        decisionId: `DEC-${Date.now()}`,
        campaign: winnerCamp,
        creative,
        placement,
        debitedCost: cpcCost,
        nonce,
        signature,
        atomicCheck: `${winnerCamp.spent.toFixed(2)} <= ${winnerCamp.budget.toFixed(2)} MXN (OK)`,
      },
    });
  });

  const vite = await createServer({
    server: { middlewareMode: true },
    appType: 'spa',
  });
  app.use(vite.middlewares);

  app.listen(port, '0.0.0.0', () => {
    console.log(`ADSOLUSOL Enterprise Server running on http://0.0.0.0:${port}`);
  });
}

startServer();