import type { ReactNode } from "react";
import { ApiError } from "../api";
import type { HealthResponse } from "../types";

export function errorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    return `${error.message} · HTTP ${error.status}`;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "Error desconocido.";
}

export function money(value: number): string {
  return new Intl.NumberFormat("es-MX", {
    style: "currency",
    currency: "MXN",
    maximumFractionDigits: 4
  }).format(value);
}

export function number(value: number): string {
  return new Intl.NumberFormat("es-MX").format(value);
}

export function date(value?: string | null): string {
  if (!value) {
    return "—";
  }

  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) {
    return "—";
  }

  return new Intl.DateTimeFormat("es-MX", {
    dateStyle: "medium",
    timeStyle: "short"
  }).format(parsed);
}

export function toUtc(value: string): string | null {
  if (!value) {
    return null;
  }

  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) {
    return null;
  }

  return parsed.toISOString();
}

export function Card(props: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <section className={`card ${props.className ?? ""}`}>
      {props.children}
    </section>
  );
}

export function StatusBadge(props: { value: string }) {
  const normalized = props.value.trim().toUpperCase();

  return (
    <span className={`status-badge status-${normalized}`}>
      {normalized}
    </span>
  );
}

export function ErrorPanel(props: { message: string }) {
  return (
    <div className="error-panel" role="alert" aria-live="assertive">
      <strong>Error</strong>
      <span>{props.message}</span>
    </div>
  );
}

export function EmptyState(props: {
  title: string;
  description: string;
}) {
  return (
    <div className="empty-state">
      <strong>{props.title}</strong>
      <span>{props.description}</span>
    </div>
  );
}

export function StatCard(props: {
  label: string;
  value: ReactNode;
  detail: string;
}) {
  return (
    <Card className="stat-card">
      <span className="stat-label">
        {props.label}
      </span>

      <strong className="stat-value">
        {props.value}
      </strong>

      <span className="stat-detail">
        {props.detail}
      </span>
    </Card>
  );
}

export function ConnectionIndicator(props: {
  health: HealthResponse | null;
  error: string | null;
}) {
  if (props.error) {
    return (
      <span className="connection disconnected" aria-label="API desconectada">
        API DISCONNECTED
      </span>
    );
  }

  if (!props.health) {
    return (
      <span className="connection checking" aria-label="Verificando API">
        CHECKING
      </span>
    );
  }

  const status = props.health.status.toUpperCase();

  return (
    <span className={`connection ${status === "HEALTHY" ? "connected" : "degraded"}`}>
      {status}
    </span>
  );
}