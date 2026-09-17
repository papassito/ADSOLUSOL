using System;
using System.IO;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Infrastructure.Services;

namespace ADSOLUSOL.Presentation.Api.Controllers
{
    [ApiController]
    [Route("api/marketing/adsolusol/campaigns")]
    public class CampaignsController : ControllerBase
    {
        private readonly AdProcessingEngine _processingEngine;
        private readonly string _connectionString;

        public CampaignsController()
        {
            string dbPath = Path.Combine(AppContext.BaseDirectory, "App_Data", "campaigns.db");
            _processingEngine = new AdProcessingEngine(dbPath);
            _connectionString = $"Data Source={dbPath}";
        }

        [HttpPost("{id}/toggle")]
        public IActionResult ToggleCampaign(string id)
        {
            using var connection = new SqliteConnection(_connectionString);
            connection.Open();

            string selectSql = "SELECT status FROM campaigns WHERE id = @Id";
            string currentStatus = string.Empty;

            using (var selectCmd = new SqliteCommand(selectSql, connection))
            {
                selectCmd.Parameters.AddWithValue("@Id", id);
                var result = selectCmd.ExecuteScalar();
                if (result == null)
                {
                    return NotFound(new { message = "Campaign not found" });
                }
                currentStatus = result?.ToString() ?? string.Empty;
            }

            string newStatus = currentStatus == "ACTIVE" ? "INACTIVE" : "ACTIVE";
            string updateSql = "UPDATE campaigns SET status = @NewStatus WHERE id = @Id";

            using (var updateCmd = new SqliteCommand(updateSql, connection))
            {
                updateCmd.Parameters.AddWithValue("@NewStatus", newStatus);
                updateCmd.Parameters.AddWithValue("@Id", id);
                updateCmd.ExecuteNonQuery();
            }

            return Ok(new { campaignId = id, status = newStatus });
        }

        [HttpPost("{id}/click")]
        public IActionResult RegisterClick(string id, [FromQuery] string event_id, [FromQuery] string placement_id)
        {
            if (string.IsNullOrEmpty(event_id) || string.IsNullOrEmpty(placement_id))
            {
                return BadRequest(new { error = "Missing event_id or placement_id parameters" });
            }

            var adEvent = new AdEvent
            {
                EventId = event_id,
                CampaignId = id,
                PlacementId = placement_id,
                EventType = "CLICK",
                TimestampUtc = DateTime.UtcNow,
                IPAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1",
                UserAgent = Request.Headers["User-Agent"].ToString()
            };

            try
            {
                string result = _processingEngine.ProcessAdEvent(adEvent);

                if (result == "DUPLICATE")
                {
                    return Ok(new { status = "DUPLICATE", message = "Event already processed. Idempotency enforced." });
                }
                if (result == "CAMPAIGN_NOT_FOUND") return NotFound(new { error = "Campaign not found" });
                if (result == "CAMPAIGN_INACTIVE") return BadRequest(new { error = "Campaign is inactive" });

                return Accepted(new { status = result });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        [HttpPost("{id}/impression")]
        public IActionResult RegisterImpression(string id, [FromQuery] string event_id, [FromQuery] string placement_id)
        {
            if (string.IsNullOrEmpty(event_id) || string.IsNullOrEmpty(placement_id))
            {
                return BadRequest(new { error = "Missing event_id or placement_id parameters" });
            }

            var adEvent = new AdEvent
            {
                EventId = event_id,
                CampaignId = id,
                PlacementId = placement_id,
                EventType = "IMPRESSION",
                TimestampUtc = DateTime.UtcNow,
                IPAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1",
                UserAgent = Request.Headers["User-Agent"].ToString()
            };

            try
            {
                string result = _processingEngine.ProcessAdEvent(adEvent);

                if (result == "DUPLICATE")
                {
                    return Ok(new { status = "DUPLICATE", message = "Event already processed. Idempotency enforced." });
                }
                if (result == "CAMPAIGN_NOT_FOUND") return NotFound(new { error = "Campaign not found" });
                if (result == "CAMPAIGN_INACTIVE") return BadRequest(new { error = "Campaign is inactive" });

                return Accepted(new { status = result });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}