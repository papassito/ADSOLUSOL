// Forzar sondeo (polling) en todos los observadores de archivos (Chokidar/Vite) para evitar UVException en unidades de red en Windows
process.env.CHOKIDAR_USEPOLLING = 'true';
process.env.CHOKIDAR_INTERVAL = '150';

import express from 'express';
import { createServer } from 'vite';
import * as controllers from './controllers';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import path from 'path';

const app = express();
const port = 3000;

app.use(express.json());

async function startServer() {
  // Rutas segregadas por controlador de negocio
  app.get('/api/state', controllers.getState);
  app.post('/api/campaigns', controllers.createCampaign);
  app.patch('/api/campaigns/:id', controllers.patchCampaign);
  app.delete('/api/:collection/:id', controllers.deleteRecord);
  app.post('/api/serve-decision', controllers.handleServeDecision);
  // Handshake de validación de Tag
  app.post('/api/initiate-validation', controllers.initiateValidation);
  app.get('/api/check-token-status/:token', controllers.checkTokenStatus);
  app.post('/api/redeem-validation-token', controllers.redeemValidationToken);

  app.post('/api/placements', controllers.createPlacement);
  app.post('/api/creatives', controllers.createCreative);
  app.post('/api/assignments', controllers.createAssignment);

  const vite = await createServer({
    configFile: false, // No cargar vite.config.ts para aislar el modo demo
    server: {
      middlewareMode: true,
    },
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: {
        '@': path.resolve(process.cwd(), '.'),
      },
    },
    define: {
      'import.meta.env.VITE_DEMO_MODE': JSON.stringify(
        process.env.VITE_DEMO_MODE === 'true' && process.env.NODE_ENV !== 'production'
          ? 'true'
          : 'false'
      ),
    },
    appType: 'spa',
  });
  app.use(vite.middlewares);

  app.listen(port, '127.0.0.1', () => {
    console.log(`ADSOLUSOL Enterprise Server running on http://127.0.0.1:${port}`);
  });
}

startServer();
