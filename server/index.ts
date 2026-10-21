// Forzar sondeo (polling) en todos los observadores de archivos (Chokidar/Vite) para evitar UVException en unidades de red en Windows
process.env.CHOKIDAR_USEPOLLING = 'true';
process.env.CHOKIDAR_INTERVAL = '150';

import express from 'express';
import { createServer } from 'vite';
import * as controllers from './controllers';
import { demoRoutes } from './demoRoutes';
import react from '@vitejs/plugin-react';
import path from 'path';

const app = express();
const port = 3000;

app.use(express.json());

async function startServer() {
  app.use(demoRoutes);
  // Rutas segregadas por controlador de negocio
  app.get('/api/state', controllers.getState);
  app.post('/api/campaigns', controllers.createCampaign);
  app.patch('/api/campaigns/:id', controllers.patchCampaign);
  app.delete('/api/:collection/:id', controllers.deleteRecord);
  app.post('/api/serve-decision', controllers.handleServeDecision);

  const vite = await createServer({
    configFile: false, // No cargar vite.config.ts para aislar el modo demo
    server: {
      middlewareMode: true,
    },
    plugins: [react()],
    resolve: {
      alias: {
        '@': path.resolve(process.cwd(), '.'),
      },
    },
    define: {
      // Inyectar variable para que el frontend sepa que está en modo demo
      'import.meta.env.VITE_DEMO_MODE': JSON.stringify('true'),
    },
    appType: 'spa',
  });
  app.use(vite.middlewares);

  app.listen(port, '127.0.0.1', () => {
    console.log(`ADSOLUSOL Enterprise Server running on http://127.0.0.1:${port}`);
  });
}

startServer();
