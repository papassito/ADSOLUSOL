import { useMemo } from 'react';
import { Campaign } from './types';

export function useAnalyticsCalculations(
  campaigns: Campaign[],
  hourlyMetrics: any[],
  competitorTerms: any[],
  creatives: any[]
) {
  const kpis = useMemo(() => {
    const totalBudget = campaigns.reduce((acc, c) => acc + c.budget, 0);
    const totalSpent = campaigns.reduce((acc, c) => acc + c.spent, 0);
    const totalImpressions = campaigns.reduce((acc, c) => acc + c.impressions, 0);
    const totalClicks = campaigns.reduce((acc, c) => acc + c.clicks, 0);
    const activeCount = campaigns.filter((c) => c.status === 'ACTIVA').length;
    const ctr = totalImpressions > 0 ? ((totalClicks / totalImpressions) * 100).toFixed(2) : '0.00';
    const avgCpc = totalClicks > 0 ? (totalSpent / totalClicks).toFixed(2) : '0.00';
    const avgCpm =
      hourlyMetrics.length > 0
        ? (hourlyMetrics.reduce((acc, h) => acc + (h.cpm ?? 0), 0) / hourlyMetrics.length).toFixed(2)
        : 'NO DISPONIBLE';
    const budgetPct = Math.min(100, Math.round((totalSpent / Math.max(1, totalBudget)) * 100));
    const shieldSavings = competitorTerms.filter((t) => t.blocked).reduce((acc, t) => acc + t.wasted, 0);
    const totalDirections = creatives.reduce((acc, cr) => acc + (cr.directionsClicks || 0), 0);

    return {
      totalBudget,
      totalSpent,
      totalImpressions,
      totalClicks,
      activeCount,
      ctr,
      avgCpc,
      avgCpm,
      budgetPct,
      shieldSavings,
      totalDirections,
    };
  }, [campaigns, hourlyMetrics, competitorTerms, creatives]);

  const forecast7DaysData = useMemo(() => {
    const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    const activeCampaigns = campaigns.filter((c) => c.status !== 'PAUSADA');
    const activeBudgetCap = activeCampaigns.reduce((acc, c) => acc + c.budget, 0);
    const totalActiveSpent = activeCampaigns.reduce((acc, c) => acc + c.spent, 0);
    const remainingBudget = Math.max(0, activeBudgetCap - totalActiveSpent);

    // Zero-Synthetic: Ritmo de consumo derivado del histórico observado real (hourlyMetrics)
    const totalHourlySpend = hourlyMetrics.reduce((acc, h) => acc + Number(h.spend || 0), 0);
    const observedHours = hourlyMetrics.filter((h) => Number(h.impressions || 0) > 0 || Number(h.spend || 0) > 0).length;
    const hourlyBurnRate = observedHours > 0 ? totalHourlySpend / observedHours : 0;
    const dailyBurnRate = Number((hourlyBurnRate * 24).toFixed(2));

    const today = new Date();
    let cumulativeForecastSpend = 0;

    return Array.from({ length: 7 }, (_, i) => {
      const targetDate = new Date(today);
      targetDate.setDate(today.getDate() + i + 1);
      const dayOfWeek = targetDate.getDay();
      const label = `${dayNames[dayOfWeek]} ${targetDate.getDate()}`;

      // El gasto proyectado no puede exceder el presupuesto restante del ciclo
      const availableForDay = Math.max(0, remainingBudget - cumulativeForecastSpend);
      const predictedSpend = Number(Math.min(dailyBurnRate, availableForDay).toFixed(2));
      cumulativeForecastSpend += predictedSpend;

      const dailyShieldSaving = dailyBurnRate > 0 && kpis.shieldSavings > 0
        ? Number(Math.min(predictedSpend, kpis.shieldSavings / 7).toFixed(2))
        : 0;
      const optimizedWithShield = Number(Math.max(0, predictedSpend - dailyShieldSaving).toFixed(2));

      return {
        day: label,
        gastoProyectado: predictedSpend,
        gastoOptimizadoShield: optimizedWithShield,
        techoPresupuesto: Number(activeBudgetCap.toFixed(2)),
      };
    });
  }, [campaigns, hourlyMetrics, kpis.shieldSavings]);

  const trends24hData = useMemo(() => {
    if (hourlyMetrics.length === 0) return [];
    return Array.from({ length: 24 }, (_, idx) => {
      const hStr = `${String(idx).padStart(2, '0')}:00`;
      const existing = hourlyMetrics.find((m) => m.hour === hStr);

      if (existing && existing.impressions > 0) {
        const ctrVal = Number(((existing.clicks / existing.impressions) * 100).toFixed(2));
        const cpcVal = existing.clicks > 0 ? Number((existing.spend / existing.clicks).toFixed(2)) : 0;
        return {
          hour: hStr,
          ctr: ctrVal,
          cpc: cpcVal,
          impressions: existing.impressions ?? 0,
          clicks: existing.clicks ?? 0,
          spend: existing.spend ?? 0,
        };
      }
      return { hour: hStr, ctr: 0, cpc: 0, impressions: 0, clicks: 0, spend: 0 };
    });
  }, [hourlyMetrics]);

  const total7DayPredictedSpend = useMemo(() => forecast7DaysData.reduce((acc, d) => acc + d.gastoProyectado, 0), [forecast7DaysData]);
  const total7DayShieldOptimized = useMemo(() => forecast7DaysData.reduce((acc, d) => acc + d.gastoOptimizadoShield, 0), [forecast7DaysData]);

  return { kpis, forecast7DaysData, trends24hData, total7DayPredictedSpend, total7DayShieldOptimized };
}