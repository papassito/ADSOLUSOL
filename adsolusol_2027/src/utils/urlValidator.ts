export const validateCampaignUrl = (url: string) => {
  if (!url.startsWith('https://')) return { valid: false, reason: 'Solo se permiten URLs HTTPS.' };
  if (url.includes('fraude.com') || url.includes('malware.net')) return { valid: false, reason: 'Dominio en lista negra de seguridad.' };
  try {
    new URL(url);
    return { valid: true, reason: '' };
  } catch {
    return { valid: false, reason: 'URL con formato inv lido.' };
  }
};
