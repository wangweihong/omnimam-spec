-- model-management S2 design schema.
-- Product source: 00_product/domains/model-management/product-spec.md
-- 本文件是设计态 schema，不是实际数据库 migration。

-- S1 refs: US-USER-MODEL-01..US-USER-MODEL-05; BR-USER-MODEL-01..BR-USER-MODEL-09, BR-USER-MODEL-30, BR-USER-MODEL-31.
CREATE TABLE user_model_providers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  "createdAt" TEXT NOT NULL,
  "updateAt" TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  owner_user_id TEXT NOT NULL,
  provider_type TEXT NOT NULL,
  api_base_url TEXT NOT NULL,
  auth_type TEXT NOT NULL,
  api_key_ref TEXT DEFAULT '',
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  extra_config_json TEXT NOT NULL DEFAULT '{}',
  deleted_at TEXT DEFAULT ''
);

CREATE UNIQUE INDEX idx_user_model_providers_owner_name
  ON user_model_providers(owner_user_id, name)
  WHERE deleted_at = '';
CREATE INDEX idx_user_model_providers_owner ON user_model_providers(owner_user_id);
CREATE INDEX idx_user_model_providers_type ON user_model_providers(provider_type);

-- S1 refs: US-USER-MODEL-06..US-USER-MODEL-11, US-USER-MODEL-13; BR-USER-MODEL-10..BR-USER-MODEL-22, BR-USER-MODEL-26, BR-USER-MODEL-27.
CREATE TABLE user_provider_models (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  "createdAt" TEXT NOT NULL,
  "updateAt" TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  owner_user_id TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES user_model_providers(id),
  model TEXT NOT NULL,
  display_name TEXT NOT NULL,
  model_group TEXT DEFAULT '',
  capabilities_json TEXT NOT NULL DEFAULT '[]',
  stream_supported BOOLEAN NOT NULL DEFAULT TRUE,
  health_status TEXT NOT NULL CHECK (health_status IN ('unknown', 'healthy', 'unhealthy')),
  unhealthy_reason TEXT DEFAULT '',
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  deleted_at TEXT DEFAULT ''
);

CREATE UNIQUE INDEX idx_user_provider_models_provider_model
  ON user_provider_models(owner_user_id, provider_id, model)
  WHERE deleted_at = '';
CREATE UNIQUE INDEX idx_user_provider_models_provider_display
  ON user_provider_models(owner_user_id, provider_id, display_name)
  WHERE deleted_at = '';
CREATE INDEX idx_user_provider_models_owner ON user_provider_models(owner_user_id);
CREATE INDEX idx_user_provider_models_provider ON user_provider_models(provider_id);
CREATE INDEX idx_user_provider_models_health ON user_provider_models(health_status);

-- S1 refs: US-USER-MODEL-12, US-USER-MODEL-13; BR-USER-MODEL-23..BR-USER-MODEL-29.
CREATE TABLE user_default_model_configs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  "createdAt" TEXT NOT NULL,
  "updateAt" TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  owner_user_id TEXT NOT NULL,
  usage TEXT NOT NULL CHECK (usage IN ('assistant.default', 'quick', 'translation')),
  provider_id TEXT NOT NULL REFERENCES user_model_providers(id),
  model_id TEXT NOT NULL REFERENCES user_provider_models(id)
);

CREATE UNIQUE INDEX idx_user_default_model_configs_owner_usage
  ON user_default_model_configs(owner_user_id, usage);
CREATE INDEX idx_user_default_model_configs_model ON user_default_model_configs(model_id);

-- S1 refs: US-USER-MODEL-05, US-USER-MODEL-10; BR-USER-MODEL-08, BR-USER-MODEL-09, BR-USER-MODEL-15..BR-USER-MODEL-21.
CREATE TABLE model_health_checks (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  "createdAt" TEXT NOT NULL,
  "updateAt" TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  owner_user_id TEXT NOT NULL,
  target_type TEXT NOT NULL CHECK (target_type IN ('provider', 'model')),
  provider_id TEXT NOT NULL REFERENCES user_model_providers(id),
  model_id TEXT DEFAULT '',
  success BOOLEAN NOT NULL,
  health_status TEXT NOT NULL CHECK (health_status IN ('unknown', 'healthy', 'unhealthy')),
  message TEXT DEFAULT '',
  checked_at TEXT NOT NULL
);

CREATE INDEX idx_model_health_checks_owner ON model_health_checks(owner_user_id);
CREATE INDEX idx_model_health_checks_provider ON model_health_checks(provider_id);
CREATE INDEX idx_model_health_checks_model ON model_health_checks(model_id);
