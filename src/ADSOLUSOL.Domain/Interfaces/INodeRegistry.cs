namespace ADSOLUSOL.Domain.Interfaces;

public interface INodeRegistry
{
    (string? TenantId, string? PublicKeyHex) GetNodeInfo(string nodeId);
}