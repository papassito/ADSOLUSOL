export function apiFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const headers = new Headers(init?.headers || {});

  if (!headers.has('Content-Type') && !(init?.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  // Headers requeridos por el backend cuando opera autenticación de nodo
  const tenantId = localStorage.getItem('adsolusol_tenant_id');
  if (tenantId && !headers.has('X-Solusol-Tenant-Id')) {
    headers.set('X-Solusol-Tenant-Id', tenantId);
  }

  const apiBase = import.meta.env.VITE_API_BASE_URL || '';
  const requestUrl = typeof input === 'string' && input.startsWith('/') ? `${apiBase}${input}` : input;

  return fetch(requestUrl, {
    ...init,
    credentials: init?.credentials ?? 'include',
    headers,
  });
}
