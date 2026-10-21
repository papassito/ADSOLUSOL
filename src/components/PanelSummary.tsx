import type { Campaign } from '../types';

type Props = { campaigns: Campaign[]; loading: boolean };

export function PanelSummary({ campaigns, loading }: Props) {
  const totals = campaigns.reduce((sum, campaign) => ({
    budget: sum.budget + campaign.budget,
    spent: sum.spent + campaign.spent,
    clicks: sum.clicks + campaign.clicks,
    impressions: sum.impressions + campaign.impressions,
    active: sum.active + Number(campaign.status === 'ACTIVA'),
  }), { budget: 0, spent: 0, clicks: 0, impressions: 0, active: 0 });
  const money = (value: number) => new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(value);
  const cards = [
    { label: 'Gasto de campañas', value: money(totals.spent), detail: `de ${money(totals.budget)} presupuestados` },
    { label: 'Campañas activas', value: String(totals.active), detail: `${campaigns.length} campañas registradas` },
    { label: 'Clics', value: totals.clicks.toLocaleString('es-MX'), detail: `${totals.impressions.toLocaleString('es-MX')} impresiones` },
    { label: 'CTR', value: `${totals.impressions ? (totals.clicks / totals.impressions * 100).toFixed(2) : '0.00'}%`, detail: 'Clics / impresiones' },
  ];
  return <section aria-label="Resumen de campañas" className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
    {cards.map(card => <div key={card.label} className="as-card-premium rounded-2xl p-5">
      <p className="text-sm font-medium text-slate-300">{card.label}</p>
      <p className="mt-2 text-2xl font-bold text-white">{loading ? '—' : card.value}</p>
      <p className="mt-1 text-sm text-slate-400">{loading ? 'Cargando datos…' : card.detail}</p>
    </div>)}
  </section>;
}
