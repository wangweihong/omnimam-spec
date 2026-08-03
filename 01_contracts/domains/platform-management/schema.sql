-- Design-time schema only; this repository does not contain migrations.
-- PlatformOverview is a read-only projection of runtime metadata and AuditLog summaries; it has no dedicated table.

-- s1_refs: BR-PLATFORM-001, BR-PLATFORM-002, BR-PLATFORM-003, US-PLATFORM-001, US-PLATFORM-002
CREATE TABLE platform_system_auth_configs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'default',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  registration_mode TEXT NOT NULL CHECK (registration_mode IN ('OPEN', 'ADMIN_APPROVAL')),
  password_policy_json TEXT NOT NULL DEFAULT '{}',
  login_failure_policy_json TEXT NOT NULL DEFAULT '{}',
  online_presence_window_seconds INTEGER NOT NULL DEFAULT 300 CHECK (online_presence_window_seconds BETWEEN 30 AND 3600),
  access_token_lifetime_seconds INTEGER NOT NULL CHECK (access_token_lifetime_seconds BETWEEN 300 AND 86400),
  refresh_token_lifetime_seconds INTEGER NOT NULL CHECK (refresh_token_lifetime_seconds BETWEEN 3600 AND 31536000 AND refresh_token_lifetime_seconds > access_token_lifetime_seconds),
  updated_by_principal_type TEXT NOT NULL CHECK (updated_by_principal_type IN ('USER', 'SERVICE_ACCOUNT')),
  updated_by_principal_id TEXT NOT NULL,

  CONSTRAINT chk_platform_auth_config_singleton CHECK (id = 'default'),
  CONSTRAINT chk_platform_auth_password_policy_json CHECK (jsonb_typeof(password_policy_json::jsonb) = 'object'),
  CONSTRAINT chk_platform_auth_login_failure_policy_json CHECK (jsonb_typeof(login_failure_policy_json::jsonb) = 'object'),
  CONSTRAINT chk_platform_auth_config_version CHECK (resource_version >= 0)
);

-- detail_json is redacted, bounded and never contains credentials or raw request payloads.
-- content_fingerprint is lowercase hexadecimal SHA-256 of the canonical accepted audit content.
-- extend_shadow remains empty for AuditLog; variable audit content belongs only in bounded detail_json.
-- s1_refs: BR-PLATFORM-004, BR-PLATFORM-005, BR-PLATFORM-006, BR-PLATFORM-007, US-PLATFORM-003, US-PLATFORM-004
CREATE TABLE platform_audit_logs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
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
  occurred_at TIMESTAMPTZ NOT NULL,
  idempotency_key TEXT NOT NULL,
  content_fingerprint TEXT NOT NULL,

  CONSTRAINT uq_platform_audit_idempotency UNIQUE (source_domain, source_module, idempotency_key),
  CONSTRAINT chk_platform_audit_detail_json CHECK (octet_length(detail_json) <= 16384 AND jsonb_typeof(detail_json::jsonb) = 'object'),
  CONSTRAINT chk_platform_audit_fingerprint CHECK (content_fingerprint ~ '^[0-9a-f]{64}$'),
  CONSTRAINT chk_platform_audit_occurred_at CHECK (occurred_at <= created_at + INTERVAL '5 minutes'),
  CONSTRAINT chk_platform_audit_immutable_metadata CHECK (updated_at = created_at AND resource_version = 0),
  CONSTRAINT chk_platform_audit_extend_shadow_empty CHECK (extend_shadow = '')
);

CREATE INDEX idx_platform_audit_created
  ON platform_audit_logs (created_at DESC, id);
CREATE INDEX idx_platform_audit_occurred
  ON platform_audit_logs (occurred_at DESC, id);
CREATE INDEX idx_platform_audit_source
  ON platform_audit_logs (source_domain, source_module, occurred_at DESC);
CREATE INDEX idx_platform_audit_principal
  ON platform_audit_logs (principal_type, principal_id, occurred_at DESC);
CREATE INDEX idx_platform_audit_target
  ON platform_audit_logs (target_type, target_id, occurred_at DESC);
CREATE INDEX idx_platform_audit_action
  ON platform_audit_logs (action, occurred_at DESC);
CREATE INDEX idx_platform_audit_result
  ON platform_audit_logs (result, occurred_at DESC);
CREATE INDEX idx_platform_audit_request
  ON platform_audit_logs (request_id, occurred_at DESC);

-- s1_refs: BR-PLATFORM-001, BR-PLATFORM-004, US-PLATFORM-002, US-PLATFORM-004
CREATE TABLE platform_outbox_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  event_name TEXT NOT NULL,
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  aggregate_version INTEGER NOT NULL,
  payload_json TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  published_at TIMESTAMPTZ,
  CONSTRAINT uq_platform_outbox_idempotency UNIQUE (idempotency_key),
  CONSTRAINT chk_platform_outbox_payload_json CHECK (jsonb_typeof(payload_json::jsonb) = 'object'),
  CONSTRAINT chk_platform_outbox_version CHECK (resource_version >= 0)
);
