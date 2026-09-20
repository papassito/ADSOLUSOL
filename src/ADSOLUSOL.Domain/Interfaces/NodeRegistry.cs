using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Infrastructure.Authentication;

/// <summary>
/// Mock implementation for resolving a NodeId to its authorized TenantId and public key.
/// In a real production system, this would be backed by a secure database or configuration provider.
/// </summary>
public class NodeRegistry : INodeRegistry
{
    // Test Node: "NODE_ADS_01" is authorized for "tenant-A".
    // Public Key for private key: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
    private readonly Dictionary<string, (string TenantId, string PublicKeyHex)> _nodes = new()
    {
        { "NODE_ADS_01", ("tenant-A", "c1c2c3c4c5c6c1c2c3c4c5c6c1c2c3c4c5c6c1c2c3c4c5c6c1c2c3c4c5c6c1c2") }
    };

    public (string? TenantId, string? PublicKeyHex) GetNodeInfo(string nodeId) =>
        _nodes.TryGetValue(nodeId, out var info) ? info : (null, null);
}