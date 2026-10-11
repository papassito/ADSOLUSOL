import express from 'express';
import { createServer as createViteServer } from 'vite';
import fs from 'fs/promises';
import { z } from 'zod';
import rateLimit from 'express-rate-limit';

const DB_FILE = './ad_engine_data.json';
const API_KEY = process.env.ADSOLUSOL_API_KEY || 'default-secret-key-change-me';

// Validation Schemas
const TelemetrySchema = z.object({
  campaign_id: z.string(),
  event_type: z.enum(['impression', 'click']),
  user_ip: z.string(),
  user_agent: z.string(),
});

// Atomic JSON Database Handler
let campaignsCache: any[] = [];
let telemetryCache: any[] = [];

const loadDb = async () => {
  try {
    const data = await fs.readFile(DB_FILE, 'utf-8');
    const db = JSON.parse(data);
    campaignsCache = db.campaigns || [];
    telemetryCache = db.telemetry || [];
  } catch (e) {
    campaignsCache = [];
    telemetryCache = [];
  }
};

const saveDb = async () => {
  const data = { campaigns: campaignsCache, telemetry: telemetryCache };
  const tempFile = `${DB_FILE}.tmp`;
  await fs.writeFile(tempFile, JSON.stringify(data, null, 2));
  await fs.rename(tempFile, DB_FILE);
};

async function startServer() {
  await loadDb();
  const app = express();
  const vite = await createViteServer({
    server: { middlewareMode: true },
    appType: 'spa',
  });
  app.use(vite.middlewares);
  app.use(express.json());

  // Security Middlewares
  const apiLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute
    max: 1000 // Limit each IP to 1000 requests per window
  });

  const authMiddleware = (req: express.Request, res: express.Response, next: express.NextFunction) => {
    if (req.headers['x-api-key'] !== API_KEY) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
  };

  // CORS Configuration
  app.use((req, res, next) => {
    const allowedOrigins = ['https://adsolusol.solusol.net', 'https://api.solusol.net'];
    const origin = req.headers.origin as string;
    if (allowedOrigins.includes(origin)) {
      res.setHeader('Access-Control-Allow-Origin', origin);
    }
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-API-KEY');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
  });

  // Production API Endpoints (Public - secured)
  app.use('/api/public', apiLimiter, authMiddleware);

  app.get('/api/public/ad-request', async (req, res) => {
    // Auction logic: eCPM = (bid * (ctr / 100) * 1000)
    const activeCampaigns = campaignsCache.filter((c: any) => c.status === 'active');
    if (activeCampaigns.length === 0) return res.status(204).send();

    const winner = activeCampaigns.reduce((prev: any, current: any) => {
      const prevEcpm = (prev.bid * (prev.ctr / 100) * 1000);
      const currEcpm = (current.bid * (current.ctr / 100) * 1000);
      return (currEcpm > prevEcpm) ? current : prev;
    });

    res.json({ ad: winner });
  });

  app.post('/api/public/telemetry', async (req, res) => {
    const validation = TelemetrySchema.safeParse(req.body);
    if (!validation.success) return res.status(400).json(validation.error);

    telemetryCache.push({ ...validation.data, timestamp: new Date().toISOString() });
    await saveDb();
    res.json({ success: true });
  });

  // Dashboard Management API
  app.get('/api/campaigns', async (req, res) => {
    res.json(campaignsCache);
  });

  app.post('/api/campaigns', async (req, res) => {
    const newCampaign = { ...req.body, status: 'paused', spent: 0, impressions: 0 };
    campaignsCache.push(newCampaign);
    await saveDb();
    res.json({ success: true });
  });

  app.listen(3000, () => {
    console.log('adsolusol production engine running on http://localhost:3000');
  });
}
startServer();
