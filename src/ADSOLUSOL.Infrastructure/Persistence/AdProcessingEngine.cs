using System;
using Microsoft.Data.Sqlite;
using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Infrastructure.Services
{
    public class AdProcessingEngine
    {
        private readonly string _connectionString;

        public AdProcessingEngine(string dbPath)
        {
            _connectionString = $"Data Source={dbPath}";
        }

        public string ProcessAdEvent(AdEvent adEvent)
        {
            using var connection = new SqliteConnection(_connectionString);
            connection.Open();
            using var transaction = connection.BeginTransaction();

            try
            {
                // 1. Control de Idempotencia por ID de Evento único
                string checkEventSql = "SELECT COUNT(1) FROM ad_events WHERE event_id = @EventId";
                using (var checkCmd = new SqliteCommand(checkEventSql, connection, transaction))
                {
                    checkCmd.Parameters.AddWithValue("@EventId", adEvent.EventId);
                    var checkResult = checkCmd.ExecuteScalar();
                    long exists = checkResult != null ? Convert.ToInt64(checkResult) : 0;
                    if (exists > 0)
                    {
                        return "DUPLICATE";
                    }
                }

                // 2. Obtener métricas de Campaña
                string getCampaignSql = @"
                    SELECT pricing_model, rate, budget_total, budget_spent, total_impressions, total_clicks, status 
                    FROM campaigns WHERE id = @CampaignId";
                
                string pricingModel = "CPC";
                decimal rate = 0;
                decimal budgetTotal = 0;
                decimal budgetSpent = 0;
                long totalImpressions = 0;
                long totalClicks = 0;
                string status = "INACTIVE";

                using (var getCmd = new SqliteCommand(getCampaignSql, connection, transaction))
                {
                    getCmd.Parameters.AddWithValue("@CampaignId", adEvent.CampaignId);
                    using var reader = getCmd.ExecuteReader();
                    if (!reader.Read())
                    {
                        return "CAMPAIGN_NOT_FOUND";
                    }

                    pricingModel = reader.GetString(0);
                    rate = Convert.ToDecimal(reader.GetDouble(1));
                    budgetTotal = Convert.ToDecimal(reader.GetDouble(2));
                    budgetSpent = Convert.ToDecimal(reader.GetDouble(3));
                    totalImpressions = reader.GetInt64(4);
                    totalClicks = reader.GetInt64(5);
                    status = reader.GetString(6);
                }

                if (status != "ACTIVE")
                {
                    return "CAMPAIGN_INACTIVE";
                }

                // 3. Procesar Costo (CPM/CPC) y actualizar contadores
                decimal cost = 0;
                if (adEvent.EventType.Equals("CLICK", StringComparison.OrdinalIgnoreCase))
                {
                    totalClicks++;
                    if (pricingModel.Equals("CPC", StringComparison.OrdinalIgnoreCase))
                    {
                        cost = rate;
                    }
                }
                else if (adEvent.EventType.Equals("IMPRESSION", StringComparison.OrdinalIgnoreCase))
                {
                    totalImpressions++;
                    if (pricingModel.Equals("CPM", StringComparison.OrdinalIgnoreCase))
                    {
                        cost = rate / 1000.0m;
                    }
                }

                adEvent.Cost = cost;
                decimal newBudgetSpent = budgetSpent + cost;
                double ctr = totalImpressions == 0 ? 0.0 : (double)totalClicks / totalImpressions;

                // Cerrar campaña automáticamente al agotar el presupuesto
                string newStatus = newBudgetSpent >= budgetTotal ? "COMPLETED" : "ACTIVE";

                // 4. Registrar Evento e Historial de Ledger
                string insertEventSql = @"
                    INSERT INTO ad_events (event_id, campaign_id, placement_id, event_type, timestamp_utc, ip_address, user_agent, cost)
                    VALUES (@EventId, @CampaignId, @PlacementId, @EventType, @Timestamp, @IP, @UA, @Cost)";
                
                using (var insertEventCmd = new SqliteCommand(insertEventSql, connection, transaction))
                {
                    insertEventCmd.Parameters.AddWithValue("@EventId", adEvent.EventId);
                    insertEventCmd.Parameters.AddWithValue("@CampaignId", adEvent.CampaignId);
                    insertEventCmd.Parameters.AddWithValue("@PlacementId", adEvent.PlacementId);
                    insertEventCmd.Parameters.AddWithValue("@EventType", adEvent.EventType);
                    insertEventCmd.Parameters.AddWithValue("@Timestamp", adEvent.TimestampUtc.ToString("yyyy-MM-ddTHH:mm:ssZ"));
                    insertEventCmd.Parameters.AddWithValue("@IP", adEvent.IPAddress);
                    insertEventCmd.Parameters.AddWithValue("@UA", adEvent.UserAgent);
                    insertEventCmd.Parameters.AddWithValue("@Cost", (double)cost);
                    insertEventCmd.ExecuteNonQuery();
                }

                // 5. Actualizar campaña con nuevas métricas
                string updateCampaignSql = @"
                    UPDATE campaigns 
                    SET budget_spent = @BudgetSpent,
                        total_impressions = @Impressions,
                        total_clicks = @Clicks,
                        ctr = @Ctr,
                        status = @Status
                    WHERE id = @CampaignId";

                using (var updateCmd = new SqliteCommand(updateCampaignSql, connection, transaction))
                {
                    updateCmd.Parameters.AddWithValue("@BudgetSpent", (double)newBudgetSpent);
                    updateCmd.Parameters.AddWithValue("@Impressions", totalImpressions);
                    updateCmd.Parameters.AddWithValue("@Clicks", totalClicks);
                    updateCmd.Parameters.AddWithValue("@Ctr", ctr);
                    updateCmd.Parameters.AddWithValue("@Status", newStatus);
                    updateCmd.Parameters.AddWithValue("@CampaignId", adEvent.CampaignId);
                    updateCmd.ExecuteNonQuery();
                }

                transaction.Commit();
                return newStatus == "COMPLETED" ? "BUDGET_EXHAUSTED" : "SUCCESS";
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }
    }
}