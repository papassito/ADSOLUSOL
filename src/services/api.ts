// API local de demostraci?n. La integraci?n con api.solusol.net est? pendiente.
export function apiFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  return fetch(input, init);
}
