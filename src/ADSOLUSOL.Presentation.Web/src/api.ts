import type {
  AssignmentRequest,
  Campaign,
  CampaignMetrics,
  CreateCampaignRequest,
  CreateCreativeRequest,
  CreatePlacementRequest,
  Creative,
  HealthResponse,
  Placement
} from "./types";

const configuredBase =
  import.meta.env.VITE_API_BASE_URL?.trim() ?? "";

const API_BASE = configuredBase.replace(/\/$/, "");

export type SignatureProvider = (context: {
  method: string;
  path: string;
  body: string;
}) => Promise<Record<string, string>> | Record<string, string>;

let customSignatureProvider: SignatureProvider | null = null;

export function setSignatureProvider(provider: SignatureProvider | null): void {
  customSignatureProvider = provider;
}

function url(path: string): string {
  return `${API_BASE}${path}`;
}

export class ApiError extends Error {
  readonly status: number;
  readonly payload: unknown;

  constructor(
    message: string,
    status: number,
    payload?: unknown
  ) {
    super(message);

    this.name = "ApiError";
    this.status = status;
    this.payload = payload;
  }
}

async function request<T>(
  path: string,
  init: RequestInit = {}
): Promise<T> {
  const headers = new Headers(init.headers);

  headers.set("Accept", "application/json");

  if (init.body && !(init.body instanceof FormData) && !headers.has("Content-Type")) {
    headers.set(
      "Content-Type",
      "application/json; charset=utf-8"
    );
  }

  if (customSignatureProvider) {
    const method = init.method ?? "GET";
    const bodyStr = typeof init.body === "string" ? init.body : "";
    const sigHeaders = await customSignatureProvider({
      method,
      path,
      body: bodyStr
    });
    for (const [k, v] of Object.entries(sigHeaders)) {
      headers.set(k, v);
    }
  }

  const response = await fetch(url(path), {
    ...init,
    headers,
    credentials: "include"
  });

  if (response.status === 204) {
    return null as T;
  }

  const contentType =
    response.headers.get("content-type") ?? "";

  let payload: unknown = null;

  if (contentType.includes("application/json")) {
    payload = await response.json();
  } else {
    const text = await response.text();
    payload = text || null;
  }

  if (!response.ok) {
    let message = `HTTP ${response.status}`;

    if (
      payload &&
      typeof payload === "object" &&
      "message" in payload
    ) {
      message = String(
        (payload as { message?: unknown }).message
      );
    } else if (typeof payload === "string") {
      message = payload;
    }

    throw new ApiError(
      message,
      response.status,
      payload
    );
  }

  return payload as T;
}

/*
 * IMPORTANTE:
 *
 * Estas rutas representan el backend REAL existente
 * actualmente en ADSOLUSOL.
 *
 * NO cambiar a las rutas canónicas
 * /api/marketing/adsolusol/...
 * hasta que el backend las implemente realmente.
 *
 * Cuando eso ocurra solamente se modifica este bloque.
 */
const routes = {
  authSession: "/api/auth/session",

  health: "/api/health",

  campaigns: "/api/Campaigns",

  placements: "/api/Placements",

  creatives: "/api/Creatives",

  assignmentsPlacement:
    "/api/assignments/placement",

  assignmentsCreative:
    "/api/assignments/creative",

  serve: "/api/Serve",

  settings: "/api/Settings"
};

export const apiConfig = {
  baseUrl:
    API_BASE || "same-origin",

  routes
};

export const api = {
  login(tenantId: string, password: string): Promise<{ status: string; tenantId: string }> {
    return request<{ status: string; tenantId: string }>(routes.authSession, {
      method: "POST",
      body: JSON.stringify({ tenantId, password })
    });
  },

  getSession(): Promise<{ status: string; tenantId: string }> {
    return request<{ status: string; tenantId: string }>(routes.authSession);
  },

  logout(): Promise<void> {
    return request<void>(routes.authSession, { method: "DELETE" });
  },

  getSettings(): Promise<{ tenantId: string; settings: Record<string, string>; lastUpdatedAtUtc: string }> {
    return request(routes.settings);
  },

  updateSettings(settings: Record<string, string>): Promise<{ tenantId: string; settings: Record<string, string>; lastUpdatedAtUtc: string }> {
    return request(routes.settings, {
      method: "PUT",
      body: JSON.stringify({ settings })
    });
  },

  getHealth(): Promise<HealthResponse> {
    return request<HealthResponse>(
      routes.health
    );
  },

  listCampaigns(): Promise<Campaign[]> {
    return request<Campaign[]>(
      routes.campaigns
    );
  },

  getCampaign(
    campaignId: string
  ): Promise<Campaign> {
    return request<Campaign>(
      `${routes.campaigns}/${encodeURIComponent(
        campaignId
      )}`
    );
  },

  createCampaign(
    data: CreateCampaignRequest
  ): Promise<Campaign> {
    return request<Campaign>(
      routes.campaigns,
      {
        method: "POST",
        body: JSON.stringify(data)
      }
    );
  },

  updateCampaignStatus(
    campaignId: string,
    status: string
  ): Promise<Campaign> {
    return request<Campaign>(
      `${routes.campaigns}/${encodeURIComponent(
        campaignId
      )}/status`,
      {
        method: "POST",
        body: JSON.stringify({
          status
        })
      }
    );
  },

  getCampaignMetrics(
    campaignId: string
  ): Promise<CampaignMetrics> {
    return request<CampaignMetrics>(
      `${routes.campaigns}/${encodeURIComponent(
        campaignId
      )}/metrics`
    );
  },

  createPlacement(
    data: CreatePlacementRequest
  ): Promise<{ id: number }> {
    return request<{ id: number }>(
      routes.placements,
      {
        method: "POST",
        body: JSON.stringify(data)
      }
    );
  },

  listPlacements(): Promise<Placement[]> {
    return request<Placement[]>(routes.placements);
  },

  createCreative(
    data: CreateCreativeRequest
  ): Promise<Creative> {
    return request<Creative>(
      routes.creatives,
      {
        method: "POST",
        body: JSON.stringify(data)
      }
    );
  },

  uploadCreativeAsset(file: File): Promise<{ contentUrl: string; contentType: string }> {
    const body = new FormData();
    body.append("file", file);
    return request<{ contentUrl: string; contentType: string }>("/api/Creatives/assets", {
      method: "POST",
      body
    });
  },

  assignPlacement(
    data: AssignmentRequest
  ): Promise<void> {
    return request<void>(
      routes.assignmentsPlacement,
      {
        method: "POST",
        body: JSON.stringify(data)
      }
    );
  },

  assignCreative(
    data: AssignmentRequest
  ): Promise<void> {
    return request<void>(
      routes.assignmentsCreative,
      {
        method: "POST",
        body: JSON.stringify(data)
      }
    );
  },

  async serve(
    placementCode: string
  ): Promise<Creative | null> {
    try {
      return await request<Creative | null>(
        `${
          routes.serve
        }?placementCode=${encodeURIComponent(
          placementCode
        )}`
      );
    } catch (error) {
      if (
        error instanceof ApiError &&
        error.status === 404
      ) {
        return null;
      }

      throw error;
    }
  }
};
