import { Request, Response } from 'express';
import fs from 'fs';
import crypto from 'crypto';
import { DB_PATH, readDb, writeDb } from './storage';

export const serverStartTime = Date.now();

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
  const allowedFields = ['name', 'status', 'strategy', 'maxCpc', 'budget'];
  const campaignIndex = db.campaigns.findIndex((c: any) => c.id === req.params.id);

  if (campaignIndex === -1) {
    return res.status(404).json({ error: `Campaña con ID ${req.params.id} no encontrada.` });
  }

  const campaignToUpdate = { ...db.campaigns[campaignIndex] };
  const updatePayload: { [key: string]: any } = {};

  // Primero, validar que no se intenten modificar campos protegidos
  for (const key in req.body) {
    if (!allowedFields.includes(key)) {
      return res.status(400).json({ error: `El campo '${key}' es protegido y no puede ser modificado.` });
    }
  }

  for (const key of allowedFields) {
    if (req.body[key] === undefined) continue;

    const value = req.body[key];

    if (key === 'budget' || key === 'maxCpc') {
      const numValue = Number(value);
      // 1. Validar que es un numero finito
      if (value === null || !Number.isFinite(numValue)) {
        return res.status(400).json({ error: `El campo '${key}' debe ser un número finito.` });
      }
      // 2. Validar que es estrictamente positivo
      if (numValue <= 0) {
        return res.status(400).json({ error: `El campo '${key}' debe ser un número estrictamente positivo.` });
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