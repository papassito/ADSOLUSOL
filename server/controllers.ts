import { Request, Response } from 'express';
import fs from 'fs';
import crypto from 'crypto';
import { DB_PATH, readDb, writeDb } from './storage';

export const serverStartTime = Date.now();

export async function validateEmbed(req: Request, res: Response) {
  const rawUrl = typeof req.body?.url === 'string' ? req.body.url.trim() : '';
  const zoneId = typeof req.body?.zoneId === 'string' ? req.body.zoneId.trim() : '';
  let url: URL;
  try { url = new URL(rawUrl); } catch { return res.status(400).json({ verified: false, code: 'INVALID_URL', message: 'URL inválida.' }); }
  if (url.protocol !== 'https:') return res.status(400).json({ verified: false, code: 'HTTPS_REQUIRED', message: 'La URL debe usar HTTPS.' });
  if (!zoneId || !/^[A-Za-z0-9_-]{3,80}$/.test(zoneId)) return res.status(400).json({ verified: false, code: 'INVALID_ZONE', message: 'Zona inválida.' });
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(8000), headers: { 'User-Agent': 'ADSOLUSOL-Validator/2027' } });
    const html = (await response.text()).slice(0, 2_000_000);
    const tagDetected = html.includes(`data-zone-id="${zoneId}"`) || html.includes(`data-adsolusol-zone="${zoneId}"`);
    // La firma solo se marca válida cuando exista verificación criptográfica real en el backend.
    return res.json({ verified: response.ok && tagDetected, reachable: response.ok, statusCode: response.status, tagDetected, signatureVerified: false, message: response.ok && tagDetected ? 'Sitio accesible y zona detectada.' : 'No se detectó una zona ADSOLUSOL verificable.' });
  } catch (error) {
    return res.status(502).json({ verified: false, code: 'TARGET_UNREACHABLE', message: 'No se pudo contactar el sitio destino.' });
  }
}

export function getState(req: Request, res: Response) {
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
}

export function createCampaign(req: Request, res: Response) {
  const db = readDb();
  const newCamp = {
    id: req.body.id || `CAMP-${crypto.randomBytes(4).toString('hex')}`,
    name: req.body.name,
    status: 'ACTIVA',
    strategy: req.body.strategy || 'Pacing Ponderado + CPC',
    maxCpc: Number(req.body.maxCpc) || 2.0,
    budget: Number(req.body.budget) || 100.0,
    spent: Number(req.body.spent) || 0,
    impressions: Number(req.body.impressions) || 0,
    clicks: Number(req.body.clicks) || 0,
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
    signature: `ed25519-simulated:${crypto.randomBytes(4).toString('hex')}...${crypto.randomBytes(2).toString('hex')}`, // ADVERTENCIA: Firma simulada solo para demostración.
    status: 'REGISTRADO',
  });
  writeDb(db);
  res.json(db);
}

export function patchCampaign(req: Request, res: Response) {
  const db = readDb();
  if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body) || Object.keys(req.body).length === 0) {
    return res.status(400).json({ code: 'INVALID_BODY', error: 'Se requiere un objeto JSON no vacio.' });
  }
  const allowedFields = ['name', 'status', 'strategy', 'maxCpc', 'budget'];
  const campaignIndex = db.campaigns.findIndex((c: any) => c.id === req.params.id);

  if (campaignIndex === -1) {
    return res.status(404).json({ error: `Campaña con ID ${req.params.id} no encontrada.` });
  }

  const campaignToUpdate = { ...db.campaigns[campaignIndex] };
  const updatePayload: { [key: string]: any } = {};

  // Primero, validar que no se intenten modificar campos protegidos
  for (const key of Object.keys(req.body)) {
    if (!allowedFields.includes(key)) {
      return res.status(400).json({ code: 'PROTECTED_FIELD', error: `El campo '${key}' es protegido y no puede ser modificado.` });
    }
  }

  for (const key of allowedFields) {
    if (req.body[key] === undefined) continue;

    const value = req.body[key];

    if (key === 'budget' || key === 'maxCpc') {
      const numValue = value;
      if (typeof numValue !== 'number' || !Number.isFinite(numValue) || numValue <= 0) {
        return res.status(400).json({ code: 'INVALID_NUMBER', error: `El campo '${key}' debe ser un número estrictamente positivo.` });
      }
      // 3. Validar regla de negocio
      if (key === 'budget' && numValue < campaignToUpdate.spent) {
        return res.status(400).json({ error: `El presupuesto (${numValue}) no puede ser menor que el gasto actual (${campaignToUpdate.spent}).` });
      }
      updatePayload[key] = numValue;
    } else if (key === 'name') {
      if (typeof value !== 'string' || value.trim().length < 3 || value.trim().length > 100) {
        return res.status(400).json({ error: `El campo 'name' debe ser una cadena entre 3 y 100 caracteres.` });
      }
      updatePayload[key] = value.trim();
    } else if (key === 'status') {
      const allowedStatus = ['ACTIVA', 'PAUSADA'];
      if (!allowedStatus.includes(value)) {
        return res.status(400).json({ error: `El 'status' debe ser uno de: ${allowedStatus.join(', ')}.` });
      }
      updatePayload[key] = value;
    } else if (key === 'strategy') {
      const allowedStrategies = ['Pacing Ponderado + CPC', 'Límite Condicional Atómico', 'Prioridad Alta Intención', 'CPC Estricto'];
      if (typeof value !== 'string' || !allowedStrategies.includes(value)) {
        return res.status(400).json({ error: `La 'strategy' debe ser una de: ${allowedStrategies.join(', ')}.` });
      }
      updatePayload[key] = value;
    }
  }

  // Aplicar la actualización
  db.campaigns[campaignIndex] = { ...campaignToUpdate, ...updatePayload, updatedAt: new Date().toISOString().slice(0, 16).replace('T', ' ') };

  writeDb(db);
  res.json(db.campaigns[campaignIndex]);
}

export function createPlacement(req: Request, res: Response) {
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
}

export function createCreative(req: Request, res: Response) {
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
}

export function createAssignment(req: Request, res: Response) {
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
}

export function deleteRecord(req: Request, res: Response) {
  const db = readDb();
  const col = req.params.collection;
  if (Array.isArray(db[col])) {
    db[col] = db[col].filter((item: any) => item.id !== req.params.id);
    writeDb(db);
  }
  res.json(db);
}

export function handleServeDecision(req: Request, res: Response) {
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
  }

  const nonce = crypto.randomBytes(6).toString('hex');
  const signature = `ed25519-simulated:${crypto.randomBytes(4).toString('hex')}...dev`; // ADVERTENCIA: Firma simulada solo para demostración.

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
}
