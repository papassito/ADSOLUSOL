import { CampaignProvider } from './context/CampaignContext';
import { ThemeProvider } from './context/ThemeContext';
import { ThemeToggle } from './components/ThemeToggle';
import { DashboardPanel } from './components/DashboardPanel';
import { CampaignTable } from './components/CampaignTable';
import { UrlAnalyzer } from './components/UrlAnalyzer';

export default function App() {
  return (
    <ThemeProvider>
      <CampaignProvider>
        <div className="min-h-screen bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 p-8">
          <header className="mb-8 flex justify-between items-center bg-white dark:bg-slate-900 p-6 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <div>
              <h1 className="text-3xl font-bold text-slate-900 dark:text-white">AdManager Pro</h1>
              <p className="text-slate-600 dark:text-slate-400">Bento Grid Campaign Management Dashboard</p>
            </div>
            <ThemeToggle />
          </header>
          <DashboardPanel />
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <div className="lg:col-span-2">
                  <CampaignTable />
              </div>
              <div>
                  <UrlAnalyzer />
              </div>
          </div>
        </div>
      </CampaignProvider>
    </ThemeProvider>
  );
}
