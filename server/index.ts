// Forzar sondeo (polling) en todos los observadores de archivos (Chokidar/Vite) para evitar UVException en unidades de red en Windows
process.env.CHOKIDAR_USEPOLLING = 'true';
process.env.CHOKIDAR_INTERVAL = '150';

import express from 'express';
import { createServer } from 'vite';
import * as controllers from './controllers';
import { demoRoutes } from './demoRoutes';

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
    server: {
      middlewareMode: true,
      proxy: {}, // Desactivar proxy para que el servidor de demo maneje las rutas /api
      watch: {
        usePolling: true,
        interval: 150,
        // Excluir directorios que causan problemas con el observador de archivos en Windows,
        // especialmente en unidades de red o con muchos archivos (como el proyecto .NET).
        ignored: [
          '**/.git/**',
          '**/node_modules/**',
          '**/bin/**',
          '**/obj/**',
          '**/.vs/**',
          '**/docs/**',
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

  app.listen(port, '127.0.0.1', () => {
    console.log(`ADSOLUSOL Enterprise Server running on http://127.0.0.1:${port}`);
  });
}

startServer();
