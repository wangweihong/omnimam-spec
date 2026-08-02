-- Identity S2 design schema. This file is a design contract, not a migration.
-- Cross-domain resource IDs and principal owner IDs intentionally have no
-- foreign keys to business-domain tables.

-- password_hash stores the complete Argon2id PHC string; plaintext passwords,
-- reversible ciphertext, and raw password input are never persisted.
-- s1_refs: US-IAM-001, US-IAM-002; BR-IAM-001, BR-IAM-002, BR-IAM-003, BR-IAM-017, BR-IAM-021
CREATE TABLE identity_users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  username TEXT NOT NULL,
  normalized_username TEXT NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  alias TEXT NOT NULL DEFAULT '',
  email TEXT,
  normalized_email TEXT,
  phone TEXT,
  password_hash TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'PENDING', 'DISABLED', 'LOCKED', 'DELETED')),
  first_login_required BOOLEAN NOT NULL DEFAULT FALSE,
  failed_login_count INTEGER NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
  locked_until TIMESTAMPTZ,
  security_version INTEGER NOT NULL DEFAULT 0 CHECK (security_version >= 0),
  authorization_version INTEGER NOT NULL DEFAULT 0 CHECK (authorization_version >= 0),
  password_changed_at TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  created_by TEXT,
  deleted_at TIMESTAMPTZ,

  CONSTRAINT uq_identity_users_username UNIQUE (normalized_username),
  CONSTRAINT uq_identity_users_email UNIQUE (normalized_email),
  CONSTRAINT chk_identity_users_version CHECK (resource_version >= 0),
  CONSTRAINT chk_identity_users_deleted CHECK (
    (status = 'DELETED' AND deleted_at IS NOT NULL) OR status <> 'DELETED'
  )
);

CREATE INDEX idx_identity_users_status
  ON identity_users (status, updated_at DESC);
CREATE INDEX idx_identity_users_display_name
  ON identity_users (display_name);

-- s1_refs: US-IAM-005; BR-IAM-008, BR-IAM-009
CREATE TABLE identity_roles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  code TEXT NOT NULL,
  builtin BOOLEAN NOT NULL DEFAULT FALSE,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'DISABLED')),

  CONSTRAINT uq_identity_roles_code UNIQUE (code),
  CONSTRAINT chk_identity_roles_version CHECK (resource_version >= 0)
);

-- s1_refs: US-IAM-005, US-IAM-006; BR-IAM-009
CREATE TABLE identity_permission_definitions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  code TEXT NOT NULL,
  domain TEXT NOT NULL,
  resource TEXT NOT NULL,
  action TEXT NOT NULL,
  risk_level TEXT NOT NULL CHECK (risk_level IN ('NORMAL', 'SENSITIVE', 'DANGEROUS')),
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'DEPRECATED')),

  CONSTRAINT uq_identity_permissions_code UNIQUE (code),
  CONSTRAINT chk_identity_permissions_version CHECK (resource_version >= 0)
);

-- Association table; general resource metadata does not apply.
-- s1_refs: US-IAM-005; BR-IAM-009
CREATE TABLE identity_role_permission_grants (
  role_id TEXT NOT NULL REFERENCES identity_roles(id),
  permission_code TEXT NOT NULL REFERENCES identity_permission_definitions(code),
  created_by TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (role_id, permission_code)
);

-- Association table; general resource metadata does not apply.
-- s1_refs: US-IAM-002, US-IAM-005; BR-IAM-008, BR-IAM-009
CREATE TABLE identity_user_role_grants (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES identity_users(id),
  role_id TEXT NOT NULL REFERENCES identity_roles(id),
  effective_from TIMESTAMPTZ,
  effective_to TIMESTAMPTZ,
  created_by TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  CONSTRAINT chk_identity_user_role_grant_period CHECK (
    effective_to IS NULL OR effective_from IS NULL OR effective_to > effective_from
  )
);

CREATE INDEX idx_identity_user_role_grants_user
  ON identity_user_role_grants (user_id, effective_to);
CREATE INDEX idx_identity_user_role_grants_role
  ON identity_user_role_grants (role_id, effective_to);

-- s1_refs: US-IAM-005; BR-IAM-008
CREATE TABLE identity_groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  code TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'DISABLED')),

  CONSTRAINT uq_identity_groups_code UNIQUE (code),
  CONSTRAINT chk_identity_groups_version CHECK (resource_version >= 0)
);

-- Association table; general resource metadata does not apply.
-- s1_refs: US-IAM-005; BR-IAM-008
CREATE TABLE identity_group_members (
  group_id TEXT NOT NULL REFERENCES identity_groups(id),
  user_id TEXT NOT NULL REFERENCES identity_users(id),
  created_by TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (group_id, user_id)
);

CREATE INDEX idx_identity_group_members_user
  ON identity_group_members (user_id, group_id);

-- Association table; general resource metadata does not apply.
-- s1_refs: US-IAM-005; BR-IAM-008, BR-IAM-009
CREATE TABLE identity_group_role_grants (
  group_id TEXT NOT NULL REFERENCES identity_groups(id),
  role_id TEXT NOT NULL REFERENCES identity_roles(id),
  created_by TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (group_id, role_id)
);

-- This table stores only grants for resource domains that explicitly opt in.
-- resource_id/resource_type are polymorphic and intentionally have no FK.
-- s1_refs: US-IAM-006, US-IAM-007; BR-IAM-011, BR-IAM-012, BR-IAM-013
CREATE TABLE identity_resource_access_grants (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  subject_type TEXT NOT NULL CHECK (subject_type IN ('USER', 'GROUP')),
  subject_id TEXT NOT NULL,
  access_level TEXT NOT NULL CHECK (access_level IN ('VIEW', 'USE', 'EDIT', 'MANAGE')),
  granted_by_principal_type TEXT NOT NULL CHECK (granted_by_principal_type IN ('USER', 'SERVICE_ACCOUNT')),
  granted_by_principal_id TEXT NOT NULL,
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,

  CONSTRAINT uq_identity_resource_grant UNIQUE (resource_type, resource_id, subject_type, subject_id),
  CONSTRAINT chk_identity_resource_grant_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_identity_resource_grants_resource
  ON identity_resource_access_grants (resource_type, resource_id, revoked_at, expires_at);
CREATE INDEX idx_identity_resource_grants_subject
  ON identity_resource_access_grants (subject_type, subject_id, revoked_at);

-- last_active_at is updated by successful login, refresh, and presence heartbeat.
-- s1_refs: US-IAM-004, US-IAM-013, US-IAM-014; BR-IAM-005, BR-IAM-006, BR-IAM-007, BR-IAM-022
CREATE TABLE identity_auth_sessions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  user_id TEXT NOT NULL REFERENCES identity_users(id),
  client_id TEXT NOT NULL,
  device_info TEXT NOT NULL DEFAULT '',
  ip_address TEXT,
  user_agent TEXT,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
  last_active_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  revoke_reason TEXT,

  CONSTRAINT chk_identity_auth_sessions_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_identity_auth_sessions_user
  ON identity_auth_sessions (user_id, status, last_active_at DESC);

-- s1_refs: US-IAM-001, US-IAM-004; BR-IAM-005, BR-IAM-007
CREATE TABLE identity_token_credentials (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  principal_type TEXT NOT NULL CHECK (principal_type IN ('USER', 'SERVICE_ACCOUNT')),
  principal_id TEXT NOT NULL,
  auth_session_id TEXT REFERENCES identity_auth_sessions(id),
  access_token_jti TEXT NOT NULL,
  security_version INTEGER NOT NULL DEFAULT 0,
  credential_version INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
  issued_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,

  CONSTRAINT uq_identity_token_credentials_jti UNIQUE (access_token_jti),
  CONSTRAINT chk_identity_token_credentials_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_identity_token_credentials_principal
  ON identity_token_credentials (principal_type, principal_id, status);

-- Refresh token plaintext is never stored.
-- s1_refs: US-IAM-004; BR-IAM-006, BR-IAM-007
CREATE TABLE identity_refresh_tokens (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  session_id TEXT NOT NULL REFERENCES identity_auth_sessions(id),
  token_hash TEXT NOT NULL,
  parent_id TEXT REFERENCES identity_refresh_tokens(id),
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'USED', 'REVOKED', 'EXPIRED')),
  issued_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,

  CONSTRAINT uq_identity_refresh_tokens_hash UNIQUE (token_hash),
  CONSTRAINT chk_identity_refresh_tokens_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_identity_refresh_tokens_session
  ON identity_refresh_tokens (session_id, status, expires_at);

-- owner_id is a controlled reference to a system component or integration,
-- not a cross-domain foreign key.
-- s1_refs: US-IAM-008; BR-IAM-010, BR-IAM-014, BR-IAM-015
CREATE TABLE identity_service_accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  code TEXT NOT NULL,
  owner_type TEXT NOT NULL CHECK (owner_type IN ('SYSTEM', 'WORKER', 'AGENT', 'APPLICATION', 'EXTERNAL')),
  owner_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'DISABLED')),
  security_version INTEGER NOT NULL DEFAULT 0,
  authorization_version INTEGER NOT NULL DEFAULT 0,
  created_by TEXT,
  disabled_at TIMESTAMPTZ,

  CONSTRAINT uq_identity_service_accounts_code UNIQUE (code),
  CONSTRAINT chk_identity_service_accounts_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_identity_service_accounts_owner
  ON identity_service_accounts (owner_type, owner_id, status);

-- Service credential plaintext is never stored.
-- s1_refs: US-IAM-008; BR-IAM-014, BR-IAM-015
CREATE TABLE identity_service_account_credentials (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  service_account_id TEXT NOT NULL REFERENCES identity_service_accounts(id),
  credential_hash TEXT NOT NULL,
  prefix TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'REVOKED', 'EXPIRED')),
  issued_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ,

  CONSTRAINT uq_identity_service_credentials_hash UNIQUE (credential_hash),
  CONSTRAINT chk_identity_service_credentials_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_identity_service_credentials_account
  ON identity_service_account_credentials (service_account_id, status);

-- Reliable events are written transactionally with their source fact.
-- s1_refs: BR-IAM-015, BR-IAM-019; US-IAM-009, US-IAM-011
CREATE TABLE identity_outbox_events (
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
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED')),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  last_error_code TEXT,

  CONSTRAINT uq_identity_outbox_idempotency UNIQUE (idempotency_key),
  CONSTRAINT chk_identity_outbox_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_identity_outbox_pending
  ON identity_outbox_events (status, next_attempt_at, created_at);
