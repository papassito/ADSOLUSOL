namespace ADSOLUSOL.Domain.Interfaces
{
    public interface INodeRegistry
    {
        bool TryResolveTenant(string nodeId, out string tenantId);
        bool TryGetPublicKey(string nodeId, out string publicKey);
        void RegisterNode(string nodeId, string tenantId, string publicKey);
    }
}