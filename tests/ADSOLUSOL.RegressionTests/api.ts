import type {
  AssignmentRequest,
  Campaign,
  CampaignMetrics,
  CreateCampaignRequest,
  CreateCreativeRequest,
  CreatePlacementRequest,
  Creative,
  HealthResponse
} from "./types";

const configuredBase =
  import.meta.env.VITE_API_BASE_URL?.trim() ?? "";

const API_BASE = configuredBase.replace(/\/$/, "");

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

  if (init.body && !headers.has("Content-Type")) {
    headers.set(
      "Content-Type",
      "application/json; charset=utf-8"
    );
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
  health: "/api/health",

  campaigns: "/api/Campaigns",

  placements: "/api/Placements",

  creatives: "/api/Creatives",

  assignmentsPlacement:
    "/api/assignments/placement",

  assignmentsCreative:
    "/api/assignments/creative",

  serve: "/api/Serve"
};

export const apiConfig = {
  baseUrl:
    API_BASE || "same-origin / Vite proxy",

  routes
};

export const api = {
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