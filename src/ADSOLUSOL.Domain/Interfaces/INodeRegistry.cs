﻿using System.Collections.Concurrent;

namespace ADSOLUSOL.Domain.Interfaces;

public interface INodeRegistry
{
    (string? TenantId, string? PublicKeyHex) GetNodeInfo(string nodeId);
    bool TryResolveTenant(string nodeId, out string tenantId);
    bool TryGetPublicKey(string nodeId, out string publicKey);
    void RegisterNode(string nodeId, string tenantId, string publicKey);
}

public class NodeRegistry : INodeRegistry
{
    private readonly ConcurrentDictionary<string, (string TenantId, string PublicKeyHex)> _nodes = new();

    public NodeRegistry()
    {
        // Nodo de pruebas/desarrollo local preautorizado
        _nodes["NODE_ADS_01"] = ("tenant-A", "4a5a3b8d9c2e1f0a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a");
    }

    public (string? TenantId, string? PublicKeyHex) GetNodeInfo(string nodeId)
    {
        if (!string.IsNullOrWhiteSpace(nodeId) && _nodes.TryGetValue(nodeId, out var info))
        {
            return info;
        }
        return (null, null);
    }

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
            publicKey = info.PublicKeyHex;
            return true;
        }
        return false;
    }

    public void RegisterNode(string nodeId, string tenantId, string publicKey) => _nodes[nodeId] = (tenantId, publicKey);
}