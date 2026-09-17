﻿using ADSOLUSOL.Domain.Entities;
using System.Data;

namespace ADSOLUSOL.Domain.Interfaces;

public interface IAdEventRepository
{
    Task AddAsync(AdEvent adEvent, IDbTransaction? transaction = null);
    Task<bool> ExistsAsync(string eventId);
    Task<int> CountByTypeAsync(string campaignId, string eventType);
}