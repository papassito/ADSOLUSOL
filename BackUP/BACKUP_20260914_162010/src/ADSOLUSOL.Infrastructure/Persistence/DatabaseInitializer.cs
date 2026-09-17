using System;
using System.IO;
using Microsoft.Data.Sqlite;

namespace ADSOLUSOL.Infrastructure.Persistence
{
    public class DatabaseInitializer
    {
        private readonly string _connectionString;

        public DatabaseInitializer(string dbPath)
        {
            _connectionString = $"Data Source={dbPath}";
            var directory = Path.GetDirectoryName(dbPath);
            if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }
        }

        public void Initialize()
        {
            using var connection = new SqliteConnection(_connectionString);
            connection.Open();

            string createTablesSql = @"
                PRAGMA foreign_keys = ON;

                CREATE TABLE IF NOT EXISTS placements (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    type TEXT NOT NULL,
                    width INTEGER NOT NULL,
                    height INTEGER NOT NULL
                );

                CREATE TABLE IF NOT EXISTS campaigns (
                    id TEXT PRIMARY KEY,
                    advertiser_id TEXT NOT NULL,
                    placement_id TEXT NOT NULL,
                    start_date_utc TEXT NOT NULL,
                    end_date_utc TEXT NOT NULL,
                    target_url TEXT NOT NULL,
                    banner_url TEXT NOT NULL,
                    pricing_model TEXT NOT NULL,
                    rate REAL NOT NULL,
                    budget_total REAL NOT NULL,
                    budget_spent REAL NOT NULL,
                    total_impressions INTEGER NOT NULL,
                    total_clicks INTEGER NOT NULL,
                    ctr REAL NOT NULL,
                    status TEXT NOT NULL,
                    FOREIGN KEY(placement_id) REFERENCES placements(id)
                );

                CREATE TABLE IF NOT EXISTS creatives (
                    id TEXT PRIMARY KEY,
                    campaign_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    banner_url TEXT NOT NULL,
                    target_url TEXT NOT NULL,
                    FOREIGN KEY(campaign_id) REFERENCES campaigns(id)
                );

                CREATE TABLE IF NOT EXISTS ad_events (
                    event_id TEXT PRIMARY KEY,
                    campaign_id TEXT NOT NULL,
                    placement_id TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    timestamp_utc TEXT NOT NULL,
                    ip_address TEXT,
                    user_agent TEXT,
                    cost REAL NOT NULL,
                    FOREIGN KEY(campaign_id) REFERENCES campaigns(id),
                    FOREIGN KEY(placement_id) REFERENCES placements(id)
                );
            ";

            using var command = new SqliteCommand(createTablesSql, connection);
            command.ExecuteNonQuery();
        }
    }
}