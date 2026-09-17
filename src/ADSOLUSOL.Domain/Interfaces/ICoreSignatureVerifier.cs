namespace ADSOLUSOL.Domain.Interfaces;

// Abstracción para el verificador de firmas, desacoplando el dominio de la criptografía
public interface ICoreSignatureVerifier
{
    bool Verify(string signature, string nodeId, long timestamp, string nonce, byte[] requestBody);
}