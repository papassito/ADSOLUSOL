export function apiFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const headers = new Headers(init?.headers || {});

  if (!headers.has('Content-Type') && !(init?.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  // Headers requeridos por el backend cuando opera autenticación de nodo
  const tenantId = localStorage.getItem('adsolusol_tenant_id') || 'TENANT-SOLUSOL-HMO-01';
  if (!headers.has('X-Solusol-Tenant-Id')) {
    headers.set('X-Solusol-Tenant-Id', tenantId);
  }

  return fetch(input, {
    ...init,
    headers,
  });
}
