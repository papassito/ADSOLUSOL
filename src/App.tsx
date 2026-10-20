import Dashboard from './screens/Dashboard';

export default function App() {
  return (
    <>
      <div role="status" style={{ background: '#713f12', color: '#fff', padding: '12px 20px', fontSize: 14, textAlign: 'center' }}>
        MODO DEMOSTRACI?N: datos, subastas, firmas y estado de servicios simulados. Las acciones modifican ?nicamente el archivo local de demostraci?n. No conectado a api.solusol.net.
      </div>
      <Dashboard />
    </>
  );
}
