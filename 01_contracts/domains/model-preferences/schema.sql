-- Model Preferences S2 design schema. This is not a migration.
-- Product source: 00_product/domains/model-preferences/product-spec.md
-- No foreign keys target Model Gateway private tables; provider_resource_id is a cross-domain stable ID.

-- s1_refs: US-MODELPREF-001, BR-MODELPREF-001, BR-MODELPREF-002
CREATE TABLE model_preferences (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  provider_resource_id TEXT NOT NULL,
  display_name_override TEXT,
  model_group TEXT,
  feature_labels JSONB NOT NULL DEFAULT '[]'::jsonb,
  UNIQUE (owner_user_id, provider_resource_id)
);

CREATE INDEX idx_model_preferences_owner_group ON model_preferences(owner_user_id, model_group);

-- s1_refs: US-MODELPREF-002, US-MODELPREF-003, BR-MODELPREF-006, BR-MODELPREF-008
CREATE TABLE default_model_preferences (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  usage TEXT NOT NULL CHECK (usage IN ('assistant.default', 'quick', 'translation', 'agent.chat', 'agent.coding', 'application.default')),
  provider_resource_id TEXT NOT NULL,
  UNIQUE (owner_user_id, usage)
);

-- Reliable outbox infrastructure, not a user-facing resource; generic resource metadata is inapplicable.
-- s1_refs: BR-MODELPREF-001, BR-MODELPREF-006
CREATE TABLE model_preferences_outbox (
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

CREATE INDEX idx_model_preferences_outbox_pending ON model_preferences_outbox(published_at, occurred_at);
