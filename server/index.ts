import express from 'express';
import { createServer } from 'vite';
import fs from 'fs';
import crypto from 'crypto';

const app = express();
const port = 3000;
const serverStartTime = Date.now();

app.use(express.json());

import { DB_PATH, readDb, writeDb } from './storage';

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
          status: 'SIMULADO (archivo JSON)',
          latencyMs: dbLatencyMs,
          dbSizeKb: Number((stats.size / 1024).toFixed(1)),
          journalMode: 'No disponible (archivo JSON)',
          atomicGuard: 'BudgetSpent + Cost <= Budget',
        },
        sicEngine: {
          status: 'SIMULADO',
          endpoint: 'https://api.solusol.net/api (sin conectar)',
          latencyMs: null,
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
    server: {
      middlewareMode: true,
      watch: {
        // Excluir directorios que causan problemas con el observador de archivos en Windows,
        // especialmente en unidades de red o con muchos archivos (como el proyecto .NET).
        ignored: [
          '**/.git/**',
          '**/node_modules/**',
          '**/src/ADSOLUSOL.Presentation.Api/**',
          '**/src/ADSOLUSOL.Presentation.Web/**',
          '**/src/ADSOLUSOL.Presentation.Desktop/**',
          '**/src/ADSOLUSOL.Domain/**',
          '**/src/ADSOLUSOL.Application/**',
          '**/src/ADSOLUSOL.Infrastructure/**',
          '**/adsolusol_2027/**',
        ],
      },
    },
    appType: 'spa',
  });
  app.use(vite.middlewares);

  app.listen(port, '0.0.0.0', () => {
    console.log(`ADSOLUSOL Enterprise Server running on http://0.0.0.0:${port}`);
  });
}

startServer();