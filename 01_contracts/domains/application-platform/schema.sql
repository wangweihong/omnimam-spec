-- application-platform S2 design schema, phase 1.
-- Product source: 00_product/domains/application-platform/product-spec.md

CREATE TABLE aiapp_app_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('comfyui', 'saas_api')),
  saas_platform_type TEXT DEFAULT '',
  capability_type TEXT DEFAULT '',
  operation_key TEXT DEFAULT '',
  operation_contract_json TEXT NOT NULL DEFAULT '{}',
  config_json TEXT NOT NULL,
  parsed_fields_json TEXT NOT NULL DEFAULT '[]',
  reference_application_count INTEGER NOT NULL DEFAULT 0
);

-- S1 refs: US-AIAPP-001, US-AIAPP-002, US-AIAPP-003; BR-AIAPP-001..BR-AIAPP-009.
CREATE UNIQUE INDEX idx_aiapp_app_templates_owner_name ON aiapp_app_templates(owner_user_id, name);
CREATE INDEX idx_aiapp_app_templates_owner ON aiapp_app_templates(owner_user_id);
CREATE INDEX idx_aiapp_app_templates_kind ON aiapp_app_templates(kind);
CREATE INDEX idx_aiapp_app_templates_saas_platform ON aiapp_app_templates(saas_platform_type);
CREATE INDEX idx_aiapp_app_templates_capability ON aiapp_app_templates(capability_type);

CREATE TABLE aiapp_applications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  template_id TEXT NOT NULL REFERENCES aiapp_app_templates(id),
  kind TEXT NOT NULL CHECK (kind IN ('comfyui', 'saas_api')),
  saas_platform_type TEXT DEFAULT '',
  capability_type TEXT DEFAULT '',
  operation_key TEXT DEFAULT '',
  fixed_parameters_json TEXT NOT NULL DEFAULT '{}',
  reference_run_count INTEGER NOT NULL DEFAULT 0
);

-- S1 refs: US-AIAPP-004, US-AIAPP-006, US-AIAPP-007, US-AIAPP-009, US-AIAPP-012; BR-AIAPP-010..BR-AIAPP-015, BR-AIAPP-021..BR-AIAPP-027, BR-AIAPP-045, BR-AIAPP-046.
CREATE INDEX idx_aiapp_applications_owner ON aiapp_applications(owner_user_id);
CREATE INDEX idx_aiapp_applications_template ON aiapp_applications(template_id);
CREATE INDEX idx_aiapp_applications_kind ON aiapp_applications(kind);
CREATE INDEX idx_aiapp_applications_saas_platform ON aiapp_applications(saas_platform_type);
CREATE INDEX idx_aiapp_applications_capability ON aiapp_applications(capability_type);
CREATE INDEX idx_aiapp_applications_reference_run_count ON aiapp_applications(reference_run_count);

CREATE TABLE aiapp_app_engines (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  engine_type TEXT NOT NULL CHECK (engine_type IN ('comfyui', 'saas_api')),
  saas_platform_type TEXT DEFAULT '',
  endpoint TEXT NOT NULL,
  auth_type TEXT NOT NULL CHECK (auth_type IN ('bearer_token', 'api_key', 'ak_sk', 'none')),
  auth_config_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('active', 'disabled')),
  health_status TEXT NOT NULL CHECK (health_status IN ('unknown', 'healthy', 'unhealthy')),
  supported_capability_types_json TEXT NOT NULL DEFAULT '[]',
  health_check_config_json TEXT NOT NULL DEFAULT '{}',
  capability_tags_json TEXT NOT NULL DEFAULT '[]',
  reference_run_count INTEGER NOT NULL DEFAULT 0,
  last_health_check_at TIMESTAMPTZ,
  unhealthy_reason TEXT DEFAULT ''
);

-- S1 refs: US-AIAPP-010, US-AIAPP-011, US-AIAPP-013; BR-AIAPP-028..BR-AIAPP-035, BR-AIAPP-047..BR-AIAPP-049.
CREATE UNIQUE INDEX idx_aiapp_app_engines_owner_name ON aiapp_app_engines(owner_user_id, name);
CREATE INDEX idx_aiapp_app_engines_owner ON aiapp_app_engines(owner_user_id);
CREATE INDEX idx_aiapp_app_engines_type ON aiapp_app_engines(engine_type);
CREATE INDEX idx_aiapp_app_engines_saas_platform ON aiapp_app_engines(saas_platform_type);
CREATE INDEX idx_aiapp_app_engines_status ON aiapp_app_engines(status);
CREATE INDEX idx_aiapp_app_engines_health ON aiapp_app_engines(health_status);

CREATE TABLE aiapp_field_mappings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  application_id TEXT NOT NULL REFERENCES aiapp_applications(id) ON DELETE CASCADE,
  template_id TEXT NOT NULL REFERENCES aiapp_app_templates(id),
  field_key TEXT NOT NULL,
  field_label TEXT NOT NULL,
  field_type TEXT NOT NULL,
  source_path TEXT NOT NULL,
  default_value_json TEXT DEFAULT '',
  required BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- S1 refs: US-AIAPP-004, US-AIAPP-005; BR-AIAPP-013, BR-AIAPP-016..BR-AIAPP-020.
CREATE UNIQUE INDEX idx_aiapp_field_mappings_app_key ON aiapp_field_mappings(application_id, field_key);
CREATE INDEX idx_aiapp_field_mappings_template ON aiapp_field_mappings(template_id);
CREATE INDEX idx_aiapp_field_mappings_source_path ON aiapp_field_mappings(template_id, source_path);

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
  app_template_id TEXT NOT NULL REFERENCES aiapp_app_templates(id),
  app_engine_id TEXT NOT NULL REFERENCES aiapp_app_engines(id),
  task_run_id TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('comfyui', 'saas_api')),
  saas_platform_type TEXT DEFAULT '',
  capability_type TEXT DEFAULT '',
  operation_key TEXT DEFAULT '',
  input_snapshot_json TEXT NOT NULL DEFAULT '{}',
  rendered_payload_snapshot_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'success', 'failed', 'canceled', 'timeout')),
  output_summary_json TEXT NOT NULL DEFAULT '{}',
  failure_reason TEXT DEFAULT ''
);

-- S1 refs: US-AIAPP-013; BR-AIAPP-050..BR-AIAPP-054.
CREATE INDEX idx_aiapp_application_runs_owner ON aiapp_application_runs(owner_user_id);
CREATE INDEX idx_aiapp_application_runs_application ON aiapp_application_runs(application_id);
CREATE INDEX idx_aiapp_application_runs_engine ON aiapp_application_runs(app_engine_id);
CREATE INDEX idx_aiapp_application_runs_task_run ON aiapp_application_runs(task_run_id);
CREATE INDEX idx_aiapp_application_runs_status ON aiapp_application_runs(status);
