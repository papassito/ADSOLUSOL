namespace ADSOLUSOL.Domain.Interfaces;

public interface ICoreSignatureVerifier
{
    bool Verify(string signature, string nodeId, long timestamp, string nonce, byte[] requestBody, string httpMethod, string requestPath, string queryString);
}
