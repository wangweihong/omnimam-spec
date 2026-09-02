-- Model Gateway S2 design schema. This is not a migration.
-- Product source: 00_product/domains/modelgateway/product-spec.md
-- Destructive reset: legacy aiapp_engine_* and user_model_* provider/health tables are not retained.

-- s1_refs: US-MGW-001, BR-MGW-001, BR-MGW-002, BR-MGW-007
CREATE TABLE model_gateway_provider_accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  scope TEXT NOT NULL CHECK (scope IN ('USER', 'PLATFORM')),
  owner_user_id TEXT,
  provider_type TEXT NOT NULL,
  endpoint TEXT,
  auth_type TEXT NOT NULL,
  credential_ref TEXT,
  extra_config JSONB NOT NULL DEFAULT '{}'::jsonb,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  config_version INTEGER NOT NULL DEFAULT 1 CHECK (config_version >= 1),
  health_status TEXT NOT NULL DEFAULT 'UNKNOWN' CHECK (health_status IN ('UNKNOWN', 'HEALTHY', 'DEGRADED', 'UNHEALTHY')),
  health_reason TEXT,
  last_health_check_at TIMESTAMPTZ,
  routing_priority INTEGER NOT NULL DEFAULT 100 CHECK (routing_priority >= 0),
  max_concurrency INTEGER NOT NULL DEFAULT 4 CHECK (max_concurrency >= 1),
  timeouts JSONB NOT NULL DEFAULT '{}'::jsonb,
  CHECK (
    (scope = 'USER' AND owner_user_id IS NOT NULL)
    OR (scope = 'PLATFORM' AND owner_user_id IS NULL)
  )
);

CREATE INDEX idx_mg_provider_accounts_owner ON model_gateway_provider_accounts(owner_user_id, provider_type);
CREATE INDEX idx_mg_provider_accounts_platform_route ON model_gateway_provider_accounts(scope, enabled, routing_priority, id);

-- s1_refs: US-MGW-002, BR-MGW-005, BR-MGW-007
CREATE TABLE model_gateway_provider_resources (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  provider_account_id TEXT NOT NULL REFERENCES model_gateway_provider_accounts(id) ON DELETE CASCADE,
  resource_kind TEXT NOT NULL CHECK (resource_kind IN ('MODEL', 'WORKFLOW', 'APPLICATION', 'DEPLOYMENT')),
  remote_resource_id TEXT NOT NULL,
  capability_definition_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  disabled_capability_definition_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  discovery_status TEXT NOT NULL DEFAULT 'MANUAL' CHECK (discovery_status IN ('MANUAL', 'DISCOVERED', 'MISSING', 'INVALID')),
  health_status TEXT NOT NULL DEFAULT 'UNKNOWN' CHECK (health_status IN ('UNKNOWN', 'HEALTHY', 'DEGRADED', 'UNHEALTHY')),
  health_reason TEXT,
  resource_revision TEXT NOT NULL,
  non_sensitive_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (provider_account_id, resource_kind, remote_resource_id)
);

CREATE INDEX idx_mg_provider_resources_account ON model_gateway_provider_resources(provider_account_id, resource_kind, enabled);
CREATE INDEX idx_mg_provider_resources_discovery ON model_gateway_provider_resources(discovery_status, health_status);

-- s1_refs: US-MGW-003, US-MGW-007, BR-MGW-004, BR-MGW-006
CREATE TABLE model_gateway_account_capability_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  provider_account_id TEXT NOT NULL REFERENCES model_gateway_provider_accounts(id) ON DELETE CASCADE,
  provider_capability_id TEXT NOT NULL,
  provider_capability_revision TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  restrictions JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (provider_account_id, provider_capability_id)
);

-- s1_refs: US-MGW-004, BR-MGW-007
CREATE TABLE model_gateway_health_checks (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  target_type TEXT NOT NULL CHECK (target_type IN ('ACCOUNT', 'RESOURCE')),
  provider_account_id TEXT NOT NULL REFERENCES model_gateway_provider_accounts(id) ON DELETE CASCADE,
  provider_resource_id TEXT REFERENCES model_gateway_provider_resources(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('HEALTHY', 'DEGRADED', 'UNHEALTHY')),
  reason TEXT,
  checked_account_config_version INTEGER NOT NULL,
  checked_resource_revision TEXT,
  checked_at TIMESTAMPTZ NOT NULL,
  duration_ms INTEGER NOT NULL CHECK (duration_ms >= 0),
  CHECK (
    (target_type = 'ACCOUNT' AND provider_resource_id IS NULL AND checked_resource_revision IS NULL)
    OR (target_type = 'RESOURCE' AND provider_resource_id IS NOT NULL)
  )
);

CREATE INDEX idx_mg_health_target ON model_gateway_health_checks(target_type, provider_account_id, provider_resource_id, checked_at DESC);

-- s1_refs: US-MGW-005, BR-MGW-008
CREATE TABLE model_gateway_comfyui_object_info (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  provider_account_id TEXT NOT NULL UNIQUE REFERENCES model_gateway_provider_accounts(id) ON DELETE CASCADE,
  object_info JSONB NOT NULL,
  comfyui_version TEXT,
  refreshed_at TIMESTAMPTZ NOT NULL,
  checked_account_config_version INTEGER NOT NULL
);

-- Singleton configuration resource. Generic resource fields are retained for audit/versioning.
-- s1_refs: US-MGW-006, BR-MGW-016, BR-MGW-017
CREATE TABLE model_gateway_network_policy (
  id TEXT PRIMARY KEY CHECK (id = 'default'),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  mode TEXT NOT NULL DEFAULT 'ALLOW_ALL' CHECK (mode IN ('ALLOW_ALL', 'PUBLIC_ONLY', 'ALLOWLIST')),
  allowed_hosts JSONB NOT NULL DEFAULT '[]'::jsonb,
  allowed_cidrs JSONB NOT NULL DEFAULT '[]'::jsonb,
  allowed_schemes JSONB NOT NULL DEFAULT '["http", "https"]'::jsonb,
  allowed_ports JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_by TEXT NOT NULL
);

-- Reliable outbox infrastructure, not a user-facing resource; generic resource metadata is intentionally inapplicable.
-- s1_refs: BR-MGW-002, BR-MGW-007, BR-MGW-017
CREATE TABLE model_gateway_outbox (
  event_id TEXT PRIMARY KEY,
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  aggregate_version INTEGER NOT NULL,
  event_name TEXT NOT NULL,
  payload JSONB NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL,
  published_at TIMESTAMPTZ,
  publish_attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  UNIQUE (aggregate_type, aggregate_id, aggregate_version, event_name)
);

CREATE INDEX idx_mg_outbox_pending ON model_gateway_outbox(published_at, occurred_at);
