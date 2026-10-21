import { Router } from 'express';
import crypto from 'crypto';
import { readDb, writeDb } from './storage';

export const demoRoutes = Router();
const router = demoRoutes;

  // 5. Crear Ubicación
  router.post('/api/placements', (req, res) => {
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
  router.post('/api/creatives', (req, res) => {
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
  router.post('/api/assignments', (req, res) => {
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
  router.get('/api/go-maps', (req, res) => {
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

