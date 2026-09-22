﻿using System;
using System.Collections.Concurrent;

namespace ADSOLUSOL.Domain.Interfaces
{
    public interface INodeRegistry
    {
        bool TryResolveTenant(string nodeId, out string tenantId);
        bool TryGetPublicKey(string nodeId, out string publicKey);
        void RegisterNode(string nodeId, string tenantId, string publicKey);
    }

    public class NodeRegistry : INodeRegistry
    {
        private readonly ConcurrentDictionary<string, (string TenantId, string PublicKey)> _nodes = new();

        public bool TryResolveTenant(string nodeId, out string tenantId)
        {
            tenantId = string.Empty;
            if (!string.IsNullOrWhiteSpace(nodeId) && _nodes.TryGetValue(nodeId, out var info))
            {
                tenantId = info.TenantId;
                return true;
            }
            return false;
        }

        public bool TryGetPublicKey(string nodeId, out string publicKey)
        {
            publicKey = string.Empty;
            if (!string.IsNullOrWhiteSpace(nodeId) && _nodes.TryGetValue(nodeId, out var info))
            {
                publicKey = info.PublicKey;
                return true;
            }
            return false;
        }

        public void RegisterNode(string nodeId, string tenantId, string publicKey)
        {
            _nodes[nodeId] = (tenantId, publicKey);
        }
    }
}