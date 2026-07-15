-- application-platform S2 design schema, v0.8.0-draft.
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
  engine_instance_id TEXT NOT NULL REFERENCES aiapp_engine_instances(id),
  provider_capability_id TEXT NOT NULL,
  provider_capability_revision TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  restrictions_json TEXT NOT NULL DEFAULT '{}'
);

CREATE UNIQUE INDEX idx_aiapp_binding_engine_capability ON aiapp_engine_capability_bindings(engine_instance_id, provider_capability_id);
CREATE INDEX idx_aiapp_binding_capability ON aiapp_engine_capability_bindings(provider_capability_id, enabled);

-- s1_refs: US-AIAPP-042; BR-AIAPP-142, BR-AIAPP-144, BR-AIAPP-145, BR-AIAPP-147.
CREATE TABLE aiapp_application_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  capability_source_type TEXT NOT NULL CHECK (capability_source_type IN ('comfyui_workflow', 'provider_capability')),
  capability_definition_id TEXT NOT NULL,
  current_version_id TEXT
);

CREATE UNIQUE INDEX idx_aiapp_templates_owner_name ON aiapp_application_templates(owner_user_id, name);
CREATE INDEX idx_aiapp_templates_capability ON aiapp_application_templates(capability_definition_id, capability_source_type);

-- s1_refs: US-AIAPP-042; BR-AIAPP-142, BR-AIAPP-144, BR-AIAPP-145, BR-AIAPP-147.
CREATE TABLE aiapp_application_template_versions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  application_template_id TEXT NOT NULL REFERENCES aiapp_application_templates(id),
  version INTEGER NOT NULL CHECK (version > 0),
  status TEXT NOT NULL CHECK (status IN ('draft', 'published', 'retired')),
  capability_source_type TEXT NOT NULL CHECK (capability_source_type IN ('comfyui_workflow', 'provider_capability')),
  source_revision TEXT NOT NULL,
  provider_capability_id TEXT,
  provider_capability_revision TEXT,
  provider_operation_id TEXT,
  workflow_contract_revision TEXT,
  template_contract_json TEXT NOT NULL,
  comfyui_api_workflow_json TEXT,
  comfyui_object_info_json TEXT,
  published_at TIMESTAMPTZ,
  CHECK (
    (status = 'published' AND published_at IS NOT NULL) OR
    (status <> 'published')
  ),
  CHECK (
    (capability_source_type = 'provider_capability' AND provider_capability_id IS NOT NULL AND provider_capability_revision IS NOT NULL AND provider_operation_id IS NOT NULL AND workflow_contract_revision IS NULL AND comfyui_api_workflow_json IS NULL AND comfyui_object_info_json IS NULL) OR
    (capability_source_type = 'comfyui_workflow' AND provider_capability_id IS NULL AND provider_capability_revision IS NULL AND provider_operation_id IS NULL AND workflow_contract_revision IS NOT NULL AND comfyui_api_workflow_json IS NOT NULL AND comfyui_object_info_json IS NOT NULL)
  )
);

CREATE UNIQUE INDEX idx_aiapp_template_versions_number ON aiapp_application_template_versions(application_template_id, version);

-- Deferred self-reference after both template tables are defined.
ALTER TABLE aiapp_application_templates
  ADD CONSTRAINT fk_aiapp_template_current_version
  FOREIGN KEY (current_version_id) REFERENCES aiapp_application_template_versions(id);

-- s1_refs: US-AIAPP-042, US-AIAPP-043; BR-AIAPP-142, BR-AIAPP-148.
CREATE TABLE aiapp_applications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  capability_definition_id TEXT NOT NULL,
  visibility TEXT NOT NULL DEFAULT 'private' CHECK (visibility IN ('private', 'global')),
  run_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  canvas_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  copy_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  preset_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  current_version_id TEXT
);

CREATE UNIQUE INDEX idx_aiapp_applications_owner_name ON aiapp_applications(owner_user_id, name);
CREATE INDEX idx_aiapp_applications_owner_visibility ON aiapp_applications(owner_user_id, visibility);
CREATE INDEX idx_aiapp_applications_capability_run ON aiapp_applications(capability_definition_id, run_enabled);

-- s1_refs: US-AIAPP-042, US-AIAPP-043; BR-AIAPP-137, BR-AIAPP-142, BR-AIAPP-147.
CREATE TABLE aiapp_application_versions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  application_id TEXT NOT NULL REFERENCES aiapp_applications(id),
  semantic_version TEXT NOT NULL CHECK (semantic_version ~ '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'),
  status TEXT NOT NULL CHECK (status IN ('draft', 'published', 'retired')),
  application_template_version_id TEXT NOT NULL REFERENCES aiapp_application_template_versions(id),
  input_schema_json TEXT NOT NULL,
  output_schema_json TEXT NOT NULL,
  parameter_policies_json TEXT NOT NULL,
  published_at TIMESTAMPTZ,
  CHECK (
    (status = 'published' AND published_at IS NOT NULL) OR
    (status <> 'published')
  )
);

CREATE UNIQUE INDEX idx_aiapp_application_versions_semver ON aiapp_application_versions(application_id, semantic_version);

ALTER TABLE aiapp_applications
  ADD CONSTRAINT fk_aiapp_application_current_version
  FOREIGN KEY (current_version_id) REFERENCES aiapp_application_versions(id);

-- s1_refs: US-AIAPP-043; BR-AIAPP-135, BR-AIAPP-137, BR-AIAPP-138, BR-AIAPP-143, BR-AIAPP-145, BR-AIAPP-149.
-- Provider capability fields are conditional immutable snapshots and therefore have no registry FK.
CREATE TABLE aiapp_application_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  application_id TEXT NOT NULL REFERENCES aiapp_applications(id),
  application_version_id TEXT NOT NULL REFERENCES aiapp_application_versions(id),
  application_template_version_id TEXT NOT NULL REFERENCES aiapp_application_template_versions(id),
  task_run_id TEXT UNIQUE,
  engine_instance_id TEXT NOT NULL REFERENCES aiapp_engine_instances(id),
  capability_source_type TEXT NOT NULL CHECK (capability_source_type IN ('comfyui_workflow', 'provider_capability')),
  source_revision TEXT NOT NULL,
  provider_capability_id TEXT,
  provider_capability_revision TEXT,
  provider_operation_id TEXT,
  workflow_contract_revision TEXT,
  capability_source_snapshot_json TEXT NOT NULL,
  input_snapshot_json TEXT NOT NULL,
  execution_snapshot_json TEXT NOT NULL,
  output_mapping_snapshot_json TEXT NOT NULL,
  task_creation_status TEXT NOT NULL DEFAULT 'pending' CHECK (task_creation_status IN ('pending', 'created', 'failed')),
  task_creation_failure TEXT DEFAULT '',
  task_status_projection TEXT,
  task_resource_version INTEGER NOT NULL DEFAULT 0,
  output_values_json TEXT NOT NULL DEFAULT '[]',
  failure_summary TEXT DEFAULT '',
  idempotency_key TEXT NOT NULL,
  CHECK (
    (capability_source_type = 'provider_capability' AND provider_capability_id IS NOT NULL AND provider_capability_revision IS NOT NULL AND provider_operation_id IS NOT NULL AND workflow_contract_revision IS NULL) OR
    (capability_source_type = 'comfyui_workflow' AND provider_capability_id IS NULL AND provider_capability_revision IS NULL AND provider_operation_id IS NULL AND workflow_contract_revision IS NOT NULL)
  ),
  CHECK (
    (task_creation_status = 'created' AND task_run_id IS NOT NULL AND task_status_projection IS NOT NULL) OR
    (task_creation_status IN ('pending', 'failed') AND task_run_id IS NULL AND task_status_projection IS NULL)
  )
);

CREATE UNIQUE INDEX idx_aiapp_runs_owner_idempotency ON aiapp_application_runs(owner_user_id, idempotency_key);
CREATE INDEX idx_aiapp_runs_application_created ON aiapp_application_runs(application_id, created_at);
CREATE INDEX idx_aiapp_runs_engine_created ON aiapp_application_runs(engine_instance_id, created_at);
CREATE INDEX idx_aiapp_runs_capability_revision ON aiapp_application_runs(provider_capability_id, provider_capability_revision);

-- s1_refs: US-AIAPP-043; BR-AIAPP-150.
CREATE TABLE aiapp_artifacts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  application_run_id TEXT NOT NULL REFERENCES aiapp_application_runs(id),
  output_key TEXT NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'text', 'pdf', 'other')),
  content_ref TEXT NOT NULL,
  registration_status TEXT NOT NULL DEFAULT 'pending' CHECK (registration_status IN ('pending', 'registered', 'failed')),
  asset_id TEXT,
  registration_error_code TEXT DEFAULT '',
  registration_failure_detail TEXT DEFAULT '',
  CHECK (
    (registration_status = 'registered' AND asset_id IS NOT NULL) OR
    (registration_status IN ('pending', 'failed') AND asset_id IS NULL)
  )
);

CREATE UNIQUE INDEX idx_aiapp_artifacts_run_output ON aiapp_artifacts(application_run_id, output_key);
CREATE INDEX idx_aiapp_artifacts_registration ON aiapp_artifacts(registration_status, updated_at);

-- RuntimeFormSchema and ProviderCapability load results are derived, process-local
-- objects. Persisting either would create a second fact source and is prohibited.
