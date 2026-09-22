﻿using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Infrastructure.Authentication;

/// <summary>
/// Mock implementation for resolving a NodeId to its authorized TenantId and public key.
/// In a real production system, this would be backed by a secure database or configuration provider.
/// </summary>
public class NodeRegistry : INodeRegistry
{
    // Test Node: "NODE_ADS_01" is authorized for "tenant-A".
    private readonly Dictionary<string, (string TenantId, string PublicKeyHex)> _nodes = new()
    {
        { "NODE_ADS_01", ("tenant-A", "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a") }
    };

    public (string? TenantId, string? PublicKeyHex) GetNodeInfo(string nodeId) =>
        _nodes.TryGetValue(nodeId, out var info) ? info : (null, null);
}