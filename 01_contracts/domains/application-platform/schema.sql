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
  config_json TEXT NOT NULL,
  parsed_fields_json TEXT NOT NULL DEFAULT '[]',
  reference_application_count INTEGER NOT NULL DEFAULT 0
);

-- S1 refs: US-AIAPP-001, US-AIAPP-002, US-AIAPP-003; BR-AIAPP-001..BR-AIAPP-009.
CREATE UNIQUE INDEX idx_aiapp_app_templates_owner_name ON aiapp_app_templates(owner_user_id, name);
CREATE INDEX idx_aiapp_app_templates_owner ON aiapp_app_templates(owner_user_id);
CREATE INDEX idx_aiapp_app_templates_kind ON aiapp_app_templates(kind);

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
  kind TEXT NOT NULL CHECK (kind IN ('comfyui', 'saas_api'))
);

-- S1 refs: US-AIAPP-004, US-AIAPP-006, US-AIAPP-007, US-AIAPP-009; BR-AIAPP-010..BR-AIAPP-015, BR-AIAPP-021..BR-AIAPP-027.
CREATE INDEX idx_aiapp_applications_owner ON aiapp_applications(owner_user_id);
CREATE INDEX idx_aiapp_applications_template ON aiapp_applications(template_id);
CREATE INDEX idx_aiapp_applications_kind ON aiapp_applications(kind);

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
