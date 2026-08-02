-- Design-time schema only; this repository does not contain migrations.
-- PlatformOverview is a read-only projection of runtime metadata and AuditLog summaries; it has no dedicated table.

-- s1_refs: BR-PLATFORM-001, BR-PLATFORM-002, BR-PLATFORM-003, US-PLATFORM-001, US-PLATFORM-002
CREATE TABLE platform_system_auth_configs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'default',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  registration_mode TEXT NOT NULL CHECK (registration_mode IN ('OPEN', 'ADMIN_APPROVAL')),
  password_policy_json TEXT NOT NULL DEFAULT '{}',
  login_failure_policy_json TEXT NOT NULL DEFAULT '{}',
  online_presence_window_seconds INTEGER NOT NULL DEFAULT 300 CHECK (online_presence_window_seconds > 0),
  access_token_lifetime_seconds INTEGER NOT NULL CHECK (access_token_lifetime_seconds > 0),
  refresh_token_lifetime_seconds INTEGER NOT NULL CHECK (refresh_token_lifetime_seconds > access_token_lifetime_seconds),
  updated_by_principal_type TEXT NOT NULL CHECK (updated_by_principal_type IN ('USER', 'SERVICE_ACCOUNT')),
  updated_by_principal_id TEXT NOT NULL,

  CONSTRAINT chk_platform_auth_config_version CHECK (resource_version >= 0)
);

-- detail_json is redacted, bounded and never contains credentials or raw request payloads.
-- s1_refs: BR-PLATFORM-004, BR-PLATFORM-005, BR-PLATFORM-006, BR-PLATFORM-007, US-PLATFORM-003, US-PLATFORM-004
CREATE TABLE platform_audit_logs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  source_domain TEXT NOT NULL,
  source_module TEXT NOT NULL,
  principal_type TEXT NOT NULL CHECK (principal_type IN ('USER', 'SERVICE_ACCOUNT', 'ANONYMOUS')),
  principal_id TEXT,
  actor_user_id TEXT,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  owner_user_id TEXT,
  result TEXT NOT NULL CHECK (result IN ('SUCCESS', 'FAILED', 'DENIED')),
  reason_code TEXT,
  request_id TEXT,
  trace_id TEXT,
  ip_address TEXT,
  user_agent TEXT,
  detail_json TEXT NOT NULL DEFAULT '{}',
  idempotency_key TEXT NOT NULL,

  CONSTRAINT uq_platform_audit_idempotency UNIQUE (idempotency_key),
  CONSTRAINT chk_platform_audit_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_platform_audit_created
  ON platform_audit_logs (created_at DESC, id);
CREATE INDEX idx_platform_audit_source
  ON platform_audit_logs (source_domain, source_module, created_at DESC);
CREATE INDEX idx_platform_audit_principal
  ON platform_audit_logs (principal_type, principal_id, created_at DESC);
CREATE INDEX idx_platform_audit_target
  ON platform_audit_logs (target_type, target_id, created_at DESC);

-- s1_refs: BR-PLATFORM-001, BR-PLATFORM-004, US-PLATFORM-002, US-PLATFORM-004
CREATE TABLE platform_outbox_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  resource_version INTEGER NOT NULL DEFAULT 0,
  event_name TEXT NOT NULL,
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  aggregate_version INTEGER NOT NULL,
  payload_json TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  published_at TIMESTAMPTZ,
  CONSTRAINT uq_platform_outbox_idempotency UNIQUE (idempotency_key),
  CONSTRAINT chk_platform_outbox_version CHECK (resource_version >= 0)
);
