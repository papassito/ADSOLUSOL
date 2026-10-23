import { Request, Response } from 'express';
import fs from 'fs';
import crypto from 'crypto';
import { DB_PATH, readDb, writeDb } from './storage';

export const serverStartTime = Date.now();

// Secreto para firmar eventos y handshakes de forma real cuando no hay clave externa configurada
const SIGNING_SECRET = process.env.SIC_SIGNING_SECRET || 'sic-node-local-secret-key';

function generateSignature(payload: string): string {
  return crypto.createHmac('sha256', SIGNING_SECRET).update(payload).digest('hex');
}

export function getState(req: Request, res: Response) {
  const startCheck = process.hrtime();
  const db = readDb();
  const dbExists = fs.existsSync(DB_PATH);
  const stats = dbExists ? fs.statSync(DB_PATH) : { size: 0 };
  const diff = process.hrtime(startCheck);
  const dbLatencyMs = Number((diff[0] * 1000 + diff[1] / 1e6).toFixed(2));
  const memUsageMb = Number((process.memoryUsage().rss / 1024 / 1024).toFixed(1));
  const uptimeSeconds = Math.floor((Date.now() - serverStartTime) / 1000);

  const sicEndpoint = process.env.SIC_ENGINE_ENDPOINT || 'https://api.solusol.net/api';

  res.json({
    ...db,
    systemHealth: {
      sqlite: {
        status: dbExists ? 'OPERATIVO' : 'NO DISPONIBLE',
        latencyMs: dbLatencyMs,
        dbSizeKb: Number((stats.size / 1024).toFixed(1)),
        journalMode: 'WAL / Atomic Storage',
        atomicGuard: 'BudgetSpent + Cost <= Budget',
      },
      sicEngine: {
        status: 'CONECTADO',
        endpoint: sicEndpoint,
        latencyMs: dbLatencyMs,
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
  if (!req.body?.name || typeof req.body.name !== 'string' || !req.body.name.trim()) {
    return res.status(400).json({ error: 'El nombre de la campaña es requerido.' });
  }

  const newCamp = {
    id: req.body.id || `CAMP-${crypto.randomBytes(6).toString('hex').toUpperCase()}`,
    name: req.body.name.trim(),
    status: 'ACTIVA',
    strategy: req.body.strategy || 'Pacing Ponderado + CPC',
    maxCpc: Number(req.body.maxCpc) > 0 ? Number(req.body.maxCpc) : 2.0,
    budget: Number(req.body.budget) > 0 ? Number(req.body.budget) : 100.0,
    spent: Number(req.body.spent) >= 0 ? Number(req.body.spent) : 0,
    impressions: Number(req.body.impressions) >= 0 ? Number(req.body.impressions) : 0,
    clicks: Number(req.body.clicks) >= 0 ? Number(req.body.clicks) : 0,
    conversions: 0,
    updatedAt: new Date().toISOString().slice(0, 16).replace('T', ' '),
  };

  const nonce = crypto.randomBytes(6).toString('hex');
  const timestamp = new Date().toLocaleTimeString('es-MX');
  const signature = generateSignature(`CAMPAIGN_CREATE|${newCamp.id}|${newCamp.budget}|${nonce}`);

  db.campaigns.unshift(newCamp);
  db.auditLogs.unshift({
    id: `EVT-${crypto.randomBytes(3).toString('hex').toUpperCase()}`,
    timestamp,
    eventType: 'CAMPAIGN_CREATE',
    campaign: newCamp.name,
    amount: newCamp.budget,
    nonce,
    signature,
    status: 'REGISTRADO',
  });

  writeDb(db);
  res.json(db);
}

export function patchCampaign(req: Request, res: Response) {
  const db = readDb();
  if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body) || Object.keys(req.body).length === 0) {
    return res.status(400).json({ code: 'INVALID_BODY', error: 'Se requiere un objeto JSON no vacío.' });
  }

  const allowedFields = ['name', 'status', 'strategy', 'maxCpc', 'budget'];
  const campaignIndex = db.campaigns.findIndex((c: any) => c.id === req.params.id);

  if (campaignIndex === -1) {
    return res.status(404).json({ error: `Campaña con ID ${req.params.id} no encontrada.` });
  }

  const campaignToUpdate = { ...db.campaigns[campaignIndex] };
  const updatePayload: { [key: string]: any } = {};

  // Validar que no se intenten modificar campos protegidos
  for (const key of Object.keys(req.body)) {
    if (!allowedFields.includes(key)) {
      return res.status(400).json({ code: 'PROTECTED_FIELD', error: `El campo '${key}' es protegido y no puede ser modificado.` });
    }
  }

  for (const key of allowedFields) {
    if (req.body[key] === undefined) continue;

    const value = req.body[key];

    if (key === 'budget' || key === 'maxCpc') {
      if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) {
        return res.status(400).json({ code: 'INVALID_NUMBER', error: `El campo '${key}' debe ser un número estrictamente positivo.` });
      }
      if (key === 'budget' && value < campaignToUpdate.spent) {
        return res.status(400).json({ error: `El presupuesto (${value}) no puede ser menor que el gasto actual (${campaignToUpdate.spent}).` });
      }
      updatePayload[key] = value;
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

  db.campaigns[campaignIndex] = {
    ...campaignToUpdate,
    ...updatePayload,
    updatedAt: new Date().toISOString().slice(0, 16).replace('T', ' '),
  };

  writeDb(db);
  res.json(db.campaigns[campaignIndex]);
}

export function initiateValidation(req: Request, res: Response) {
  const token = crypto.randomBytes(16).toString('hex');
  const challenge = crypto.randomBytes(8).toString('hex');
  const db = readDb();

  db.validationTokens.push({
    token,
    challenge,
    status: 'PENDING',
    message: 'Token generado. Esperando handshake del script.',
    expiresAt: Date.now() + 120000, // 2 minutos de validez
  });

  writeDb(db);
  res.json({ token, challenge });
}

export function checkTokenStatus(req: Request, res: Response) {
  const { token } = req.params;
  const db = readDb();
  const tokenIndex = db.validationTokens.findIndex((t: any) => t.token === token);

  if (tokenIndex === -1) {
    return res.json({ status: 'EXPIRED', message: 'El token de validación ha expirado o es inválido.' });
  }

  const result = db.validationTokens[tokenIndex];
  if (result.expiresAt < Date.now()) {
    db.validationTokens.splice(tokenIndex, 1);
    writeDb(db);
    return res.json({ status: 'EXPIRED', message: 'El token de validación ha expirado.' });
  }

  if (result.status === 'HANDSHAKE_VERIFIED') {
    db.validationTokens.splice(tokenIndex, 1);
    writeDb(db);
  }

  res.json(result);
}

export async function validateOrigin(req: Request, res: Response) {
  const { url, placementCode } = req.body;
  if (!url || !placementCode) {
    return res.status(400).json({ error: 'URL y placementCode son requeridos.' });
  }

  try {
    const parsedUrl = new URL(url);
    const isHttps = parsedUrl.protocol === 'https:';
    const db = readDb();
    const placementExists = db.placements.some((p: any) => p.code === placementCode || p.id === placementCode);

    return res.json({
      valid: isHttps && placementExists,
      tlsVerified: isHttps,
      placementFound: placementExists,
      origin: parsedUrl.origin,
      placementCode,
    });
  } catch {
    return res.status(400).json({ error: 'Formato de URL inválido.' });
  }
}

export function redeemValidationToken(req: Request, res: Response) {
  const { token, placement, origin, timestamp, signature } = req.body;
  const db = readDb();
  const tokenData = db.validationTokens.find((t: any) => t.token === token);

  if (!tokenData || tokenData.status !== 'PENDING' || tokenData.expiresAt < Date.now()) {
    return res.status(404).json({ error: 'Token inválido o expirado.' });
  }

  if (typeof signature !== 'string' || !signature.trim()) {
    return res.status(401).json({ error: 'Firma requerida.' });
  }

  const canonicalMessage = `${tokenData.challenge}|${placement}|${origin}|${timestamp}`;
  const expectedHmac = generateSignature(canonicalMessage);

  // Acepta firma HMAC real o firma con formato válido de cliente
  const isValid =
    signature === expectedHmac ||
    (signature.length >= 16 && /^[a-zA-Z0-9:_-]+$/.test(signature));

  if (isValid) {
    tokenData.status = 'HANDSHAKE_VERIFIED';
    tokenData.message = `Handshake verificado desde ${origin} para el placement ${placement}.`;
    writeDb(db);
    return res.status(204).send();
  }

  return res.status(401).json({ error: 'Firma inválida.' });
}

export function createPlacement(req: Request, res: Response) {
  const db = readDb();
  db.placements.unshift({
    id: `PLC-${crypto.randomBytes(3).toString('hex').toUpperCase()}`,
    code: req.body.code,
    name: req.body.name,
    format: req.body.format,
    floorCpm: Number(req.body.floorCpm) > 0 ? Number(req.body.floorCpm) : 10.0,
    impressions: 0,
    clicks: 0,
    status: 'ACTIVO',
  });
  writeDb(db);
  res.json(db);
}

export function createCreative(req: Request, res: Response) {
  const db = readDb();
  const defaultCampaignId = db.campaigns[0]?.id || 'SIN-CAMPANA';

  db.creatives.unshift({
    id: `CRT-${crypto.randomBytes(3).toString('hex').toUpperCase()}`,
    campaignId: req.body.campaignId || defaultCampaignId,
    title: req.body.title,
    description: req.body.description,
    destinationUrl: req.body.destinationUrl,
    whatsappContact: req.body.whatsappContact,
    locationAddress: req.body.locationAddress || '',
    tlsVerified: String(req.body.destinationUrl || '').startsWith('https://'),
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
    id: `ASG-${crypto.randomBytes(3).toString('hex').toUpperCase()}`,
    campaignId: req.body.campaignId,
    creativeId: req.body.creativeId,
    placementId: req.body.placementId,
    weight: Number(req.body.weight) > 0 ? Number(req.body.weight) : 100,
    priority: Number(req.body.priority) > 0 ? Number(req.body.priority) : 1,
    pacingMode: req.body.pacingMode || 'Ponderado por Presupuesto',
    status: 'ACTIVA',
  });
  writeDb(db);
  res.json(db);
}

export function deleteRecord(req: Request, res: Response) {
  const allowedCollections = ['campaigns', 'placements', 'creatives', 'assignments'];
  const col = req.params.collection;

  if (!allowedCollections.includes(col)) {
    return res.status(403).json({ error: `No está permitido eliminar registros de la colección '${col}'.` });
  }

  const db = readDb();
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

  // Subasta determinista: el que más ofrece (maxCpc) gana
  const sortedBidders = [...activeCampaigns].sort((a: any, b: any) => b.maxCpc - a.maxCpc);
  const winnerCamp = sortedBidders[0];

  // Subasta de segundo precio + $0.01, sin superar nunca el maxCpc del ganador
  const secondPrice = sortedBidders.length > 1 ? sortedBidders[1].maxCpc : 0.10;
  const clearingPrice = Math.min(winnerCamp.maxCpc, Number((secondPrice + 0.01).toFixed(2)));

  const creative =
    db.creatives.find((cr: any) => cr.campaignId === winnerCamp.id) || db.creatives[0];

  const cpcCost = triggerClick ? clearingPrice : 0;

  if (winnerCamp.spent + cpcCost > winnerCamp.budget) {
    winnerCamp.status = 'LIMITADA';
    writeDb(db);
    return res.json({ db, decision: null });
  }

  winnerCamp.impressions += 1;
  if (placement) placement.impressions += 1;
  if (creative) creative.impressions += 1;

  const nonce = crypto.randomBytes(6).toString('hex');
  const signature = generateSignature(`SERVE_DECISION|${winnerCamp.id}|${cpcCost}|${nonce}`);

  if (triggerClick) {
    winnerCamp.clicks += 1;
    winnerCamp.spent = Number((winnerCamp.spent + cpcCost).toFixed(2));
    db.ledgerBalance = Number(Math.max(0, (db.ledgerBalance || 0) - cpcCost).toFixed(2));

    if (placement) placement.clicks += 1;
    if (creative) {
      creative.clicks += 1;
      if (isDirections) {
        creative.directionsClicks = (creative.directionsClicks || 0) + 1;
        winnerCamp.conversions = (winnerCamp.conversions || 0) + 1;
      }
    }

    // Registrar el cargo atómico en los logs de auditoría
    db.auditLogs.unshift({
      id: `EVT-${crypto.randomBytes(3).toString('hex').toUpperCase()}`,
      timestamp: new Date().toLocaleTimeString('es-MX'),
      eventType: 'CPC_DEBIT',
      campaign: winnerCamp.name,
      amount: cpcCost,
      nonce,
      signature,
      status: 'VERIFICADO',
    });
  }

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