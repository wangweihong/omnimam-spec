-- modelgateway S2 design schema, compatibility baseline v1.1.0.
-- This is a design contract, not a migration.
-- ProviderCapability, ApplicationEngineType and load diagnostics are startup-only
-- registries and intentionally have no database tables.

-- s1_refs: US-AIAPP-041; BR-AIAPP-140.
CREATE TABLE aiapp_engine_instances (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  application_engine_type_id TEXT NOT NULL,
  base_url TEXT NOT NULL,
  auth_type TEXT NOT NULL CHECK (auth_type IN ('none', 'api_key', 'bearer_token', 'ak_sk')),
  -- auth_type/auth_config_json form a strict union validated by the API/domain layer
  -- against the selected ApplicationEngineType in the Runtime Registry.
  auth_config_json TEXT NOT NULL DEFAULT '{}',
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  health_status TEXT NOT NULL DEFAULT 'unknown' CHECK (health_status IN ('unknown', 'online', 'offline', 'degraded')),
  last_health_check_at TIMESTAMPTZ,
  unhealthy_reason TEXT DEFAULT '',
  region TEXT DEFAULT '',
  max_concurrency INTEGER NOT NULL DEFAULT 1 CHECK (max_concurrency > 0),
  request_timeout_seconds INTEGER NOT NULL DEFAULT 60 CHECK (request_timeout_seconds > 0),
  task_timeout_seconds INTEGER NOT NULL DEFAULT 1800 CHECK (task_timeout_seconds > 0)
);

CREATE UNIQUE INDEX idx_aiapp_engine_instances_name ON aiapp_engine_instances(name);
CREATE INDEX idx_aiapp_engine_instances_type_health ON aiapp_engine_instances(application_engine_type_id, enabled, health_status);

-- s1_refs: US-AIAPP-041, US-AIAPP-049; BR-AIAPP-169, BR-AIAPP-170, BR-AIAPP-187.
-- This is a one-to-one current-fact extension, not an independently managed resource;
-- it intentionally has no id/name/resource_version, checksum, history, or state column.
CREATE TABLE aiapp_comfyui_engine_object_info (
  engine_instance_id TEXT PRIMARY KEY REFERENCES aiapp_engine_instances(id) ON DELETE CASCADE,
  object_info_json TEXT NOT NULL,
  comfyui_version TEXT NOT NULL DEFAULT '',
  refreshed_at TIMESTAMPTZ NOT NULL
);

-- s1_refs: US-AIAPP-040, US-AIAPP-041; BR-AIAPP-135, BR-AIAPP-137, BR-AIAPP-141.
-- provider_capability_id has no foreign key because the target is an in-memory registry.
CREATE TABLE aiapp_engine_capability_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  engine_instance_id TEXT NOT NULL REFERENCES aiapp_engine_instances(id) ON DELETE CASCADE,
  engine_instance_snapshot_json TEXT NOT NULL,
  provider_capability_id TEXT NOT NULL,
  provider_capability_revision TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  restrictions_json TEXT NOT NULL DEFAULT '{}'
);

CREATE UNIQUE INDEX idx_aiapp_binding_engine_capability ON aiapp_engine_capability_bindings(engine_instance_id, provider_capability_id);
CREATE INDEX idx_aiapp_binding_capability ON aiapp_engine_capability_bindings(provider_capability_id, enabled);

-- system_managed is derived from the current ProviderCapability binding_policy and is not persisted.
