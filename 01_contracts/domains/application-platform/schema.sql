-- application-platform S2 design schema, v1.1.0.
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

-- s1_refs: US-AIAPP-044, US-AIAPP-045, US-AIAPP-046; BR-AIAPP-153, BR-AIAPP-156, BR-AIAPP-159, BR-AIAPP-160, BR-AIAPP-169, BR-AIAPP-173, BR-AIAPP-174, BR-AIAPP-186, BR-AIAPP-187.
-- A workflow import is deliberately not versioned. Re-import creates another row.
CREATE TABLE aiapp_comfyui_workflows (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  created_by_user_id TEXT NOT NULL,
  updated_by_user_id TEXT NOT NULL,
  source_type TEXT NOT NULL CHECK (source_type IN ('visual_workflow', 'api_workflow')),
  api_conversion_status TEXT NOT NULL CHECK (api_conversion_status IN ('pending', 'ready')),
  api_workflow_json TEXT,
  visual_workflow_json TEXT,
  source_checksum TEXT NOT NULL CHECK (source_checksum ~ '^sha256:[0-9a-f]{64}$'),
  api_workflow_checksum TEXT CHECK (api_workflow_checksum IS NULL OR api_workflow_checksum ~ '^sha256:[0-9a-f]{64}$'),
  converted_application_template_id TEXT,
  converted_template_version_id TEXT,
  conversion_idempotency_key TEXT,
  converted_at TIMESTAMPTZ,
  converted_by_user_id TEXT,
  CHECK (
    (converted_application_template_id IS NULL AND converted_template_version_id IS NULL AND conversion_idempotency_key IS NULL AND converted_at IS NULL AND converted_by_user_id IS NULL) OR
    (converted_application_template_id IS NOT NULL AND converted_template_version_id IS NOT NULL AND conversion_idempotency_key IS NOT NULL AND converted_at IS NOT NULL AND converted_by_user_id IS NOT NULL)
  ),
  CHECK (
    (source_type = 'api_workflow' AND api_conversion_status = 'ready' AND api_workflow_json IS NOT NULL AND api_workflow_checksum IS NOT NULL) OR
    (source_type = 'visual_workflow' AND visual_workflow_json IS NOT NULL AND ((api_conversion_status = 'pending' AND api_workflow_json IS NULL AND api_workflow_checksum IS NULL) OR (api_conversion_status = 'ready' AND api_workflow_json IS NOT NULL AND api_workflow_checksum IS NOT NULL)))
  )
);

CREATE INDEX idx_aiapp_comfyui_workflows_owner_created ON aiapp_comfyui_workflows(owner_user_id, created_at);
CREATE INDEX idx_aiapp_comfyui_workflows_filters ON aiapp_comfyui_workflows(owner_user_id, source_type, api_conversion_status);
CREATE INDEX idx_aiapp_comfyui_workflows_checksum ON aiapp_comfyui_workflows(owner_user_id, source_type, source_checksum);
CREATE UNIQUE INDEX idx_aiapp_comfyui_workflows_conversion_key ON aiapp_comfyui_workflows(owner_user_id, conversion_idempotency_key) WHERE conversion_idempotency_key IS NOT NULL;
CREATE UNIQUE INDEX idx_aiapp_comfyui_workflows_converted_template ON aiapp_comfyui_workflows(converted_application_template_id) WHERE converted_application_template_id IS NOT NULL;

-- s1_refs: US-AIAPP-045, US-AIAPP-046; BR-AIAPP-172, BR-AIAPP-173.
-- Validation rows retain immutable outcomes and diagnostics, never object_info bodies or checksums.
CREATE TABLE aiapp_comfyui_workflow_validations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  workflow_id TEXT NOT NULL REFERENCES aiapp_comfyui_workflows(id),
  owner_user_id TEXT NOT NULL,
  requested_by_user_id TEXT NOT NULL,
  engine_instance_id TEXT NOT NULL REFERENCES aiapp_engine_instances(id),
  status TEXT NOT NULL CHECK (status IN ('compatible', 'incompatible', 'failed')),
  comfyui_version TEXT DEFAULT '',
  node_summary_json TEXT NOT NULL,
  dependency_summary_json TEXT NOT NULL,
  errors_json TEXT NOT NULL DEFAULT '[]',
  warnings_json TEXT NOT NULL DEFAULT '[]',
  validated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_aiapp_comfyui_validations_workflow_created ON aiapp_comfyui_workflow_validations(workflow_id, created_at);
CREATE INDEX idx_aiapp_comfyui_validations_engine_status ON aiapp_comfyui_workflow_validations(engine_instance_id, status, validated_at);

-- s1_refs: US-AIAPP-048; BR-AIAPP-166, BR-AIAPP-167, BR-AIAPP-168.
CREATE TABLE aiapp_comfyui_workflow_test_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  workflow_id TEXT NOT NULL REFERENCES aiapp_comfyui_workflows(id),
  owner_user_id TEXT NOT NULL,
  engine_instance_id TEXT NOT NULL REFERENCES aiapp_engine_instances(id),
  workflow_validation_id TEXT NOT NULL REFERENCES aiapp_comfyui_workflow_validations(id),
  dag_task_group_id TEXT,
  external_job_id TEXT,
  idempotency_key TEXT NOT NULL,
  parameter_snapshot_json TEXT NOT NULL DEFAULT '[]',
  output_snapshot_json TEXT NOT NULL DEFAULT '[]',
  api_workflow_snapshot_json TEXT NOT NULL,
  output_descriptors_json TEXT NOT NULL DEFAULT '[]',
  task_creation_status TEXT NOT NULL CHECK (task_creation_status IN ('pending', 'created', 'failed')),
  task_creation_failure TEXT DEFAULT '',
  CHECK ((task_creation_status = 'created' AND dag_task_group_id IS NOT NULL) OR (task_creation_status IN ('pending', 'failed') AND dag_task_group_id IS NULL))
);

CREATE UNIQUE INDEX idx_aiapp_comfyui_test_runs_owner_key ON aiapp_comfyui_workflow_test_runs(owner_user_id, idempotency_key);
CREATE INDEX idx_aiapp_comfyui_test_runs_workflow_created ON aiapp_comfyui_workflow_test_runs(workflow_id, created_at);

-- s1_refs: US-AIAPP-042, US-AIAPP-046; BR-AIAPP-142, BR-AIAPP-144, BR-AIAPP-145, BR-AIAPP-147, BR-AIAPP-159, BR-AIAPP-174.
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

-- s1_refs: US-AIAPP-042, US-AIAPP-046; BR-AIAPP-142, BR-AIAPP-144, BR-AIAPP-145, BR-AIAPP-147, BR-AIAPP-159, BR-AIAPP-174.
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
  workflow_contract_revision TEXT CHECK (workflow_contract_revision IS NULL OR workflow_contract_revision ~ '^sha256:[0-9a-f]{64}$'),
  source_comfyui_workflow_id TEXT REFERENCES aiapp_comfyui_workflows(id),
  source_workflow_validation_id TEXT REFERENCES aiapp_comfyui_workflow_validations(id),
  template_contract_json TEXT NOT NULL,
  comfyui_api_workflow_json TEXT,
  published_at TIMESTAMPTZ,
  CHECK (
    (status = 'published' AND published_at IS NOT NULL) OR
    (status <> 'published')
  ),
  CHECK (
    (capability_source_type = 'provider_capability' AND provider_capability_id IS NOT NULL AND provider_capability_revision IS NOT NULL AND provider_operation_id IS NOT NULL AND workflow_contract_revision IS NULL AND comfyui_api_workflow_json IS NULL) OR
    (capability_source_type = 'comfyui_workflow' AND provider_capability_id IS NULL AND provider_capability_revision IS NULL AND provider_operation_id IS NULL AND workflow_contract_revision IS NOT NULL AND comfyui_api_workflow_json IS NOT NULL)
  )
);

CREATE UNIQUE INDEX idx_aiapp_template_versions_number ON aiapp_application_template_versions(application_template_id, version);

-- Deferred self-reference after both template tables are defined.
ALTER TABLE aiapp_application_templates
  ADD CONSTRAINT fk_aiapp_template_current_version
  FOREIGN KEY (current_version_id) REFERENCES aiapp_application_template_versions(id);

-- Deferred conversion references after template tables are defined.
ALTER TABLE aiapp_comfyui_workflows
  ADD CONSTRAINT fk_aiapp_comfyui_workflow_converted_template
  FOREIGN KEY (converted_application_template_id) REFERENCES aiapp_application_templates(id);

ALTER TABLE aiapp_comfyui_workflows
  ADD CONSTRAINT fk_aiapp_comfyui_workflow_converted_version
  FOREIGN KEY (converted_template_version_id) REFERENCES aiapp_application_template_versions(id);

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
  atomic_task_id TEXT UNIQUE,
  engine_instance_id TEXT NOT NULL REFERENCES aiapp_engine_instances(id),
  capability_source_type TEXT NOT NULL CHECK (capability_source_type IN ('comfyui_workflow', 'provider_capability')),
  source_revision TEXT NOT NULL,
  provider_capability_id TEXT,
  provider_capability_revision TEXT,
  provider_operation_id TEXT,
  workflow_contract_revision TEXT CHECK (workflow_contract_revision IS NULL OR workflow_contract_revision ~ '^sha256:[0-9a-f]{64}$'),
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
    (task_creation_status = 'created' AND atomic_task_id IS NOT NULL AND task_status_projection IS NOT NULL) OR
    (task_creation_status IN ('pending', 'failed') AND atomic_task_id IS NULL AND task_status_projection IS NULL)
  )
);

CREATE UNIQUE INDEX idx_aiapp_runs_owner_idempotency ON aiapp_application_runs(owner_user_id, idempotency_key);
CREATE INDEX idx_aiapp_runs_application_created ON aiapp_application_runs(application_id, created_at);
CREATE INDEX idx_aiapp_runs_engine_created ON aiapp_application_runs(engine_instance_id, created_at);
CREATE INDEX idx_aiapp_runs_capability_revision ON aiapp_application_runs(provider_capability_id, provider_capability_revision);

-- s1_refs: US-AIAPP-043, US-AIAPP-050; BR-AIAPP-150, BR-AIAPP-181..184.
-- Artifact facts are stored by asset-library; this table is a rebuildable ApplicationRun output reference projection.
CREATE TABLE aiapp_application_artifact_refs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  application_run_id TEXT NOT NULL REFERENCES aiapp_application_runs(id),
  artifact_id TEXT NOT NULL,
  output_key TEXT NOT NULL,
  sequence INTEGER NOT NULL DEFAULT 0 CHECK (sequence >= 0),
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'text', 'document', 'model_3d', 'prompt', 'prompt_template', 'pdf', 'other')),
  artifact_processing_status TEXT NOT NULL CHECK (artifact_processing_status IN ('created', 'transferring', 'processing', 'ready', 'failed', 'deleted')),
  artifact_registration_status TEXT NOT NULL CHECK (artifact_registration_status IN ('pending', 'registered', 'failed')),
  asset_id TEXT,
  asset_version_id TEXT,
  artifact_resource_version INTEGER NOT NULL DEFAULT 0,
  last_error_code TEXT DEFAULT '',
  UNIQUE (artifact_id),
  UNIQUE (application_run_id, output_key, sequence)
);

CREATE INDEX idx_aiapp_artifact_refs_run ON aiapp_application_artifact_refs(application_run_id, output_key, sequence);
CREATE INDEX idx_aiapp_artifact_refs_processing ON aiapp_application_artifact_refs(artifact_processing_status, updated_at);
CREATE INDEX idx_aiapp_artifact_refs_registration ON aiapp_application_artifact_refs(artifact_registration_status, updated_at);

-- RuntimeFormSchema and ProviderCapability load results are derived, process-local
-- objects. Persisting either would create a second fact source and is prohibited.
