import { useCallback, useEffect, useState } from "react";
import { api, ApiError } from "./api";
import type { Campaign, HealthResponse } from "./types";
import { date, errorMessage } from "./components/Common";
import { LoginView } from "./views/LoginView";
import { DashboardView } from "./views/DashboardView";
import { CampaignsView } from "./views/CampaignsView";
import { PlacementsView } from "./views/PlacementsView";
import { CreativesView } from "./views/CreativesView";
import { AssignmentsView } from "./views/AssignmentsView";
import { ServeView } from "./views/ServeView";
import { SystemView } from "./views/SystemView";
import { SettingsView } from "./views/SettingsView";

type ThemeMode = "dark" | "light" | "system";
type OperatingMode = "SSP" | "Network" | "Exchange";
type View = "dashboard" | "campaigns" | "placements" | "creatives" | "assignments" | "serve" | "system" | "settings";

const navItemClass = "flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-400 hover:bg-white/5 hover:text-white transition";

function applyTheme(mode: ThemeMode) {
  const htmlEl = document.documentElement;
  htmlEl.classList.remove("light", "dark");

  if (mode === "system") {
    const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    htmlEl.classList.add(systemPrefersDark ? "dark" : "light");
  } else {
    htmlEl.classList.add(mode);
  }

  localStorage.setItem("adsolusol_theme", mode);
}

function themeButtonClass(active: boolean) {
  return active
    ? "px-2.5 py-1 rounded-md flex items-center gap-1.5 bg-blue-600 text-white font-bold transition"
    : "px-2.5 py-1 rounded-md flex items-center gap-1.5 text-gray-400 hover:text-white transition";
}

function modeButtonClass(active: boolean) {
  return active
    ? "px-3 py-1 rounded-md bg-blue-600 text-white font-bold shadow-sm transition"
    : "px-3 py-1 rounded-md font-medium text-gray-400 hover:text-white transition";
}

export default function App() {
  const [session, setSession] = useState<string | null | undefined>(undefined);
  const [view, setView] = useState<View>("dashboard");
  const [campaigns, setCampaigns] = useState<Campaign[] | null>(null);
  const [campaignsError, setCampaignsError] = useState<string | null>(null);
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [healthError, setHealthError] = useState<string | null>(null);
  const [theme, setTheme] = useState<ThemeMode>(() => {
    const saved = localStorage.getItem("adsolusol_theme");
    return saved === "light" || saved === "system" ? saved : "dark";
  });
  const [mode, setMode] = useState<OperatingMode>("SSP");
  const [modal, setModal] = useState<{ title: string; subtitle: string } | null>(null);

  useEffect(() => {
    applyTheme(theme);
  }, [theme]);

  useEffect(() => {
    void api
      .getSession()
      .then(result => setSession(result.tenantId))
      .catch(() => setSession(null));
  }, []);

  const refresh = useCallback(async () => {
    const [healthResult, campaignResult] = await Promise.allSettled([
      api.getHealth(),
      session ? api.listCampaigns() : Promise.resolve(null)
    ]);

    if (healthResult.status === "fulfilled") {
      setHealth(healthResult.value);
      setHealthError(null);
    } else {
      setHealth(null);
      setHealthError(errorMessage(healthResult.reason));
    }

    if (campaignResult.status === "fulfilled" && campaignResult.value) {
      setCampaigns(campaignResult.value);
      setCampaignsError(null);
    } else {
      setCampaigns(null);
      setCampaignsError(session && campaignResult.status === "rejected"
        ? errorMessage(campaignResult.reason)
        : null);
      if (
        session &&
        campaignResult.status === "rejected" &&
        campaignResult.reason instanceof ApiError &&
        campaignResult.reason.status === 401
      ) {
        setSession(null);
      }
    }
  }, [session]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  function openSection(title: string, subtitle: string) {
    if (session) setModal({ title, subtitle });
  }

  function renderView() {
    switch (view) {
      case "dashboard":
        return <DashboardView campaigns={campaigns} health={health} healthError={healthError} onSection={openSection} />;
      case "campaigns":
        return <CampaignsView campaigns={campaigns ?? []} loading={campaigns === null && !campaignsError} error={campaignsError} onMutated={refresh} />;
      case "placements":
        return <PlacementsView />;
      case "creatives":
        return <CreativesView />;
      case "assignments":
        return <AssignmentsView campaigns={campaigns ?? []} />;
      case "serve":
        return <ServeView />;
      case "system":
        return <SystemView health={health} error={healthError} onRefresh={refresh} />;
      case "settings":
        return <SettingsView />;
    }
  }

  function switchMode(next: OperatingMode) {
    setMode(next);
    alert(`Modo cambiado a: ${next}.`);
  }

  function section(title: string, subtitle: string, icon: string, label: string, target?: View) {
    const active = target === view;
    return (
      <a href="#" onClick={event => { event.preventDefault(); target ? setView(target) : openSection(title, subtitle); }} className={`${navItemClass} ${active ? "bg-blue-600/10 text-blue-500 font-semibold" : ""}`}>
        <i className={`fa-solid ${icon} w-5`}></i> {label}
      </a>
    );
  }

  return (
    <>
      {/* SIDEBAR LATERAL SIEMPRE VISIBLE */}
      <aside className="w-64 h-full app-surface border-r flex flex-col shrink-0 z-30">
        <div className="p-5 flex items-center gap-3 border-b border-inherit">
          <div className="w-9 h-9 rounded-lg bg-blue-600 flex items-center justify-center text-white font-black text-xl shadow-lg shadow-blue-500/30">
            A
          </div>
          <div>
            <span className="font-heading font-extrabold text-lg tracking-tight block">AdSolusol</span>
            <span className="text-[10px] uppercase font-bold text-blue-500 tracking-wider">SSP / OPERATING SYSTEM</span>
          </div>
        </div>

        <nav className="flex flex-col p-4 space-y-1 text-sm font-medium flex-1 overflow-y-auto">
          <div className="px-3 py-2 text-[10px] font-bold text-gray-500 uppercase tracking-wider">Operaciones SSP</div>
          <a href="#" onClick={event => { event.preventDefault(); setView("dashboard"); }} className={`flex items-center gap-3 px-3 py-2.5 rounded-lg ${view === "dashboard" ? "bg-blue-600/10 text-blue-500 font-semibold" : "text-gray-400 hover:bg-white/5 hover:text-white"}`}>
            <i className="fa-solid fa-chart-pie w-5"></i> Dashboard General
          </a>
          {section("Inventario de Espacios Publicitarios", "Inventarios Activos", "fa-layer-group", "Inventario & Slots", "placements")}
          {section("Red de Publishers & Medios", "Medios Afiliados", "fa-tower-cell", "Publishers & Medios")}
          {section("Gestión de Anunciantes & DSPs", "Directorio de Compradores", "fa-briefcase", "Anunciantes & Agencias")}
          {section("Campañas Publicitarias", "Programación & Entregas", "fa-bullhorn", "Campañas Activas", "campaigns")}
          {section("Creativos de Campaña", "Imágenes y destinos de anuncios", "fa-image", "Creativos", "creatives")}
          {section("Subastas OpenRTB & Bidding Engine", "Subastas en Vivo", "fa-gavel", "Subastas RTB", "serve")}
          {section("Asignaciones de Campaña e Inventario", "Recursos vinculados", "fa-link", "Asignaciones", "assignments")}

          <div className="px-3 py-2 text-[10px] font-bold text-gray-500 uppercase tracking-wider mt-4">Finanzas & Negocio</div>
          {section("Facturación & CFDI/Tax ID", "Finanzas General", "fa-file-invoice-dollar", "Facturación & Pagos")}
          {section("Gestión de Contratos & RevShare", "Legal & Acuerdos", "fa-file-contract", "Contratos & RevShare")}
          {section("Verificación KYC & Compliance", "Auditoría Fiscal", "fa-id-card", "Verificación KYC")}

          <div className="px-3 py-2 text-[10px] font-bold text-gray-500 uppercase tracking-wider mt-4">Infraestructura</div>
          {section("Registro de Auditoría & Seguridad", "Logs del Sistema", "fa-shield-halved", "Security & Audit Log")}
          {section("Auditoría y estado de infraestructura", "Estado de API y dependencias", "fa-shield-halved", "Health & Sistema", "system")}
          {section("Configuración Global de la SSP", "Settings", "fa-sliders", "Ajustes de Sistema", "settings")}
        </nav>

        <div className="p-4 border-t border-inherit">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold text-xs">
              SYS
            </div>
            <div className="text-xs">
              <div className="font-bold">Tenant</div>
              <div className="text-gray-500 text-[11px]">{session ?? "N/A"}</div>
              {session && (
                <button
                  type="button"
                  className="text-[11px] text-blue-400 hover:text-blue-300 font-semibold"
                  onClick={() => { void api.logout().then(() => setSession(null)); }}
                >
                  Salir
                </button>
              )}
            </div>
          </div>
        </div>
      </aside>

      {/* CONTENIDO PRINCIPAL */}
      <main className="flex-1 h-full flex flex-col min-w-0 overflow-y-auto">

        {/* TOP NAVBAR */}
        <header className="app-surface border-b px-6 py-3.5 flex flex-wrap items-center justify-between gap-4 sticky top-0 z-20">

          {/* Workspace & Selector de Modo */}
          <div className="flex items-center gap-4 flex-wrap">
            <div className="flex items-center gap-2 bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs px-3 py-1.5 rounded-full font-semibold">
              <i className="fa-solid fa-building flex"></i>
              <span>AdSolusol</span>
              <span className="text-gray-500">|</span>
              <span className="text-gray-300">Workspace: {session ?? "N/A"}</span>
            </div>

            {/* Modo Operativo (SSP / Network / Exchange) */}
            <div className="flex items-center bg-black/40 border border-white/10 rounded-lg p-1 text-xs">
              <button onClick={() => switchMode("SSP")} className={modeButtonClass(mode === "SSP")}>
                Modo SSP
              </button>
              <button onClick={() => switchMode("Network")} className={modeButtonClass(mode === "Network")}>
                Ad Network
              </button>
              <button onClick={() => switchMode("Exchange")} className={modeButtonClass(mode === "Exchange")}>
                Exchange RTB
              </button>
            </div>
          </div>

          {/* Control de Tema (OLED / Claro / Sistema) */}
          <div className="flex items-center gap-3">
            <span className="text-xs text-gray-400">Tema Interface:</span>
            <div className="flex items-center bg-black/40 border border-white/10 rounded-lg p-1 text-xs">
              <button onClick={() => setTheme("dark")} className={themeButtonClass(theme === "dark")}>
                <i className="fa-solid fa-moon text-indigo-400"></i> OLED Black
              </button>
              <button onClick={() => setTheme("light")} className={themeButtonClass(theme === "light")}>
                <i className="fa-solid fa-sun text-amber-400"></i> Claro
              </button>
              <button onClick={() => setTheme("system")} className={themeButtonClass(theme === "system")}>
                <i className="fa-solid fa-desktop text-blue-400"></i> Sistema
              </button>
            </div>
          </div>
        </header>

        {session === undefined ? (
          <p className="p-6 text-xs text-gray-400">Verificando acceso...</p>
        ) : session === null ? (
          <LoginView onLogin={setSession} />
        ) : (
          renderView()
        )}
      </main>

      {/* MODAL GENERAL */}
      {modal && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="app-card max-w-lg w-full rounded-xl p-6 shadow-2xl relative">
            <button onClick={() => setModal(null)} className="absolute top-4 right-4 text-gray-400 hover:text-white">
              <i className="fa-solid fa-xmark text-xl"></i>
            </button>
            <h3 className="font-heading font-extrabold text-lg">{modal.title}</h3>
            <p className="text-xs text-gray-400 mt-1">{modal.subtitle}</p>

            <div className="mt-4 text-xs space-y-3 py-3 border-y border-inherit">
              <div className="p-3 bg-black/30 rounded border border-white/5 space-y-2">
                <p><strong>Estado Operativo:</strong> SIN DATOS</p>
                <p><strong>Última lectura de la API:</strong> {health ? date(health.timestamp) : "N/A"}</p>
              </div>
            </div>

            <div className="mt-5 flex justify-end gap-3">
              <button onClick={() => setModal(null)} className="px-4 py-2 bg-gray-800 hover:bg-gray-700 text-white rounded-lg text-xs font-bold">Cerrar</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
