-- application-platform S2 design schema, phase 1.
-- Product source: 00_product/domains/application-platform/product-spec.md v0.5.0-draft.
-- ProviderAdapter and ProviderOperation are code-registered read-only catalogs and have no user-writable tables.

-- S1 refs: US-AIAPP-002, US-AIAPP-003; BR-AIAPP-006..BR-AIAPP-012.
CREATE TABLE aiapp_app_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  source_kind TEXT NOT NULL CHECK (source_kind IN ('comfyui_workflow', 'provider_workflow')),
  adapter_key TEXT NOT NULL,
  operation_key TEXT NOT NULL,
  operation_version TEXT NOT NULL,
  raw_config_json TEXT NOT NULL,
  capability_graph_json TEXT NOT NULL,
  required_node_types_json TEXT NOT NULL DEFAULT '[]',
  required_model_refs_json TEXT NOT NULL DEFAULT '[]',
  unresolved_node_count INTEGER NOT NULL DEFAULT 0,
  reference_application_count INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX idx_aiapp_templates_owner_name ON aiapp_app_templates(owner_user_id, name);
CREATE INDEX idx_aiapp_templates_adapter_operation ON aiapp_app_templates(adapter_key, operation_key, operation_version);

-- S1 refs: US-AIAPP-003, US-AIAPP-004, US-AIAPP-005, US-AIAPP-008; BR-AIAPP-013..BR-AIAPP-020.
CREATE TABLE aiapp_applications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  source_type TEXT NOT NULL CHECK (source_type IN ('template', 'provider_operation')),
  template_id TEXT REFERENCES aiapp_app_templates(id),
  adapter_key TEXT NOT NULL,
  operation_key TEXT NOT NULL,
  operation_version TEXT NOT NULL,
  capability_type TEXT NOT NULL,
  fixed_parameters_json TEXT NOT NULL DEFAULT '{}',
  latest_test_status TEXT NOT NULL DEFAULT 'untested' CHECK (latest_test_status IN ('untested', 'running', 'passed', 'failed')),
  last_tested_at TIMESTAMPTZ,
  latest_test_failure_summary TEXT DEFAULT '',
  reference_run_count INTEGER NOT NULL DEFAULT 0,
  CHECK (
    (source_type = 'template' AND template_id IS NOT NULL) OR
    (source_type = 'provider_operation' AND template_id IS NULL)
  )
);

CREATE INDEX idx_aiapp_applications_owner ON aiapp_applications(owner_user_id);
CREATE INDEX idx_aiapp_applications_source ON aiapp_applications(source_type, template_id);
CREATE INDEX idx_aiapp_applications_operation ON aiapp_applications(adapter_key, operation_key, operation_version);

-- S1 refs: US-AIAPP-003, US-AIAPP-004, US-AIAPP-005; BR-AIAPP-015..BR-AIAPP-019.
CREATE TABLE aiapp_input_mappings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  application_id TEXT NOT NULL REFERENCES aiapp_applications(id) ON DELETE CASCADE,
  input_key TEXT NOT NULL,
  input_label TEXT NOT NULL,
  source_port_key TEXT NOT NULL,
  source_path TEXT NOT NULL,
  data_type TEXT NOT NULL,
  required BOOLEAN NOT NULL,
  default_value_json TEXT DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX idx_aiapp_input_mappings_app_key ON aiapp_input_mappings(application_id, input_key);
CREATE UNIQUE INDEX idx_aiapp_input_mappings_app_path ON aiapp_input_mappings(application_id, source_path);

-- S1 refs: US-AIAPP-003, US-AIAPP-004, US-AIAPP-005; BR-AIAPP-015, BR-AIAPP-016, BR-AIAPP-018.
CREATE TABLE aiapp_output_mappings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  application_id TEXT NOT NULL REFERENCES aiapp_applications(id) ON DELETE CASCADE,
  output_key TEXT NOT NULL,
  output_label TEXT NOT NULL,
  source_port_key TEXT NOT NULL,
  source_path TEXT NOT NULL,
  data_type TEXT NOT NULL,
  cardinality TEXT NOT NULL CHECK (cardinality IN ('single', 'multiple')),
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  materialization TEXT NOT NULL CHECK (materialization IN ('inline', 'reference', 'asset')),
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX idx_aiapp_output_mappings_app_key ON aiapp_output_mappings(application_id, output_key);
CREATE UNIQUE INDEX idx_aiapp_output_mappings_app_path ON aiapp_output_mappings(application_id, source_path);
CREATE UNIQUE INDEX idx_aiapp_output_mappings_primary ON aiapp_output_mappings(application_id) WHERE is_primary = TRUE;

-- S1 refs: US-AIAPP-006, US-AIAPP-007; BR-AIAPP-021..BR-AIAPP-028.
CREATE TABLE aiapp_app_engines (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  adapter_key TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  auth_type TEXT NOT NULL CHECK (auth_type IN ('bearer_token', 'api_key', 'ak_sk', 'none')),
  auth_config_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
  health_status TEXT NOT NULL DEFAULT 'unknown' CHECK (health_status IN ('unknown', 'healthy', 'unhealthy')),
  runtime_version TEXT DEFAULT '',
  supported_operations_json TEXT NOT NULL DEFAULT '[]',
  node_types_json TEXT NOT NULL DEFAULT '[]',
  model_refs_json TEXT NOT NULL DEFAULT '[]',
  priority INTEGER NOT NULL DEFAULT 100,
  max_concurrency INTEGER NOT NULL DEFAULT 1 CHECK (max_concurrency > 0),
  current_inflight INTEGER NOT NULL DEFAULT 0 CHECK (current_inflight >= 0 AND current_inflight <= max_concurrency),
  reference_run_count INTEGER NOT NULL DEFAULT 0,
  last_health_check_at TIMESTAMPTZ,
  unhealthy_reason TEXT DEFAULT ''
);

CREATE UNIQUE INDEX idx_aiapp_engines_owner_name ON aiapp_app_engines(owner_user_id, name);
CREATE INDEX idx_aiapp_engines_route ON aiapp_app_engines(owner_user_id, adapter_key, status, health_status, priority);

-- S1 refs: US-AIAPP-008, US-AIAPP-009, US-AIAPP-010, US-AIAPP-011; BR-AIAPP-029..BR-AIAPP-046.
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
  task_run_id TEXT NOT NULL UNIQUE,
  run_mode TEXT NOT NULL CHECK (run_mode IN ('test', 'normal')),
  requested_engine_id TEXT REFERENCES aiapp_app_engines(id),
  resolved_engine_id TEXT REFERENCES aiapp_app_engines(id),
  adapter_key TEXT NOT NULL,
  operation_key TEXT NOT NULL,
  operation_version TEXT NOT NULL,
  input_snapshot_json TEXT NOT NULL,
  rendered_payload_snapshot_json TEXT NOT NULL,
  output_mapping_snapshot_json TEXT NOT NULL,
  task_status_projection TEXT NOT NULL DEFAULT 'READY',
  task_progress_projection_json TEXT NOT NULL DEFAULT '{}',
  task_resource_version INTEGER NOT NULL DEFAULT 0,
  output_values_json TEXT NOT NULL DEFAULT '[]',
  failure_summary TEXT DEFAULT ''
);

CREATE INDEX idx_aiapp_runs_owner_created ON aiapp_application_runs(owner_user_id, created_at);
CREATE INDEX idx_aiapp_runs_application ON aiapp_application_runs(application_id, created_at);
CREATE INDEX idx_aiapp_runs_resolved_engine ON aiapp_application_runs(resolved_engine_id);
