-- Notification Center design-time schema only. This file is not a runtime migration.

-- Preset notification topic and rule catalog. FUTURE/CONTRACT_GAP topics stay disabled.
-- s1_refs: US-NOTIFY-003, US-NOTIFY-006..007; BR-NOTIFY-002..003, BR-NOTIFY-011, BR-NOTIFY-014..015, BR-NOTIFY-020..021.
CREATE TABLE notification_topics (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  topic TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL CHECK (category IN ('system','task','asset','application','provider','storage','security','agent','canvas')),
  activation_status TEXT NOT NULL CHECK (activation_status IN ('ACTIVE','CONTRACT_GAP','FUTURE')),
  enabled BOOLEAN NOT NULL DEFAULT FALSE,
  mandatory_in_app BOOLEAN NOT NULL DEFAULT FALSE,
  default_severity TEXT NOT NULL CHECK (default_severity IN ('info','success','warning','error','critical')),
  default_attention_status TEXT NOT NULL CHECK (default_attention_status IN ('informational','action_required','resolved')),
  aggregation_mode TEXT NOT NULL CHECK (aggregation_mode IN ('immediate','per_source','1_minute','5_minutes','1_hour','daily_digest')),
  rule_version INTEGER NOT NULL DEFAULT 1 CHECK (rule_version >= 1),
  source_mapping_json JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(source_mapping_json) = 'array'),
  rule_config_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(rule_config_json) = 'object'),
  navigation_config_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(navigation_config_json) = 'object'),
  CHECK (enabled = FALSE OR activation_status = 'ACTIVE'),
  CHECK (topic ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$')
);

CREATE INDEX idx_notification_topics_activation
  ON notification_topics(activation_status, enabled, category);

-- Normalized candidate derived from one reliable source event. It is not the source business fact.
-- s1_refs: US-NOTIFY-006..007; BR-NOTIFY-001..007, BR-NOTIFY-010, BR-NOTIFY-017..021.
CREATE TABLE notification_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  source_domain TEXT NOT NULL,
  source_event_type TEXT NOT NULL,
  source_event_id TEXT NOT NULL,
  source_aggregate_type TEXT NOT NULL,
  source_aggregate_id TEXT NOT NULL,
  source_aggregate_version BIGINT NOT NULL CHECK (source_aggregate_version >= 0),
  notification_topic TEXT NOT NULL REFERENCES notification_topics(topic),
  source_type TEXT NOT NULL CHECK (source_type IN ('atomic_task','task_group','dag_task_group','application_run','artifact','asset','asset_version','application_engine_instance','provider_model','storage_backend','canvas_run','scan_run','asset_batch','user_action','agent_run','system')),
  source_id TEXT NOT NULL,
  recipient_basis_json JSONB NOT NULL CHECK (jsonb_typeof(recipient_basis_json) = 'object'),
  actor_type TEXT NOT NULL DEFAULT '',
  actor_id TEXT NOT NULL DEFAULT '',
  occurred_at TIMESTAMPTZ NOT NULL,
  payload_snapshot_json JSONB NOT NULL CHECK (jsonb_typeof(payload_snapshot_json) = 'object'),
  processing_status TEXT NOT NULL CHECK (processing_status IN ('PENDING','PROCESSED','IGNORED','FAILED','DEAD_LETTER')),
  processing_attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (processing_attempt_count >= 0),
  next_attempt_at TIMESTAMPTZ,
  processed_at TIMESTAMPTZ,
  last_error_code TEXT NOT NULL DEFAULT '',
  last_error_summary TEXT NOT NULL DEFAULT '',
  deduplication_key TEXT NOT NULL UNIQUE,
  rule_version INTEGER NOT NULL CHECK (rule_version >= 1),
  expires_at TIMESTAMPTZ NOT NULL,
  UNIQUE (source_domain, source_event_id, notification_topic),
  CHECK (expires_at > occurred_at)
);

CREATE INDEX idx_notification_events_processing
  ON notification_events(processing_status, next_attempt_at, created_at);
CREATE INDEX idx_notification_events_source_aggregate
  ON notification_events(source_domain, source_aggregate_type, source_aggregate_id, source_aggregate_version);
CREATE INDEX idx_notification_events_expiry
  ON notification_events(expires_at);

-- User-visible inbox fact. name maps to title and description maps to content in the public DTO.
-- s1_refs: US-NOTIFY-001..002, US-NOTIFY-004..007; BR-NOTIFY-001, BR-NOTIFY-005..013, BR-NOTIFY-016..019, BR-NOTIFY-022.
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  recipient_user_id TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('system','task','asset','application','provider','storage','security','agent','canvas')),
  notification_topic TEXT NOT NULL REFERENCES notification_topics(topic),
  severity TEXT NOT NULL CHECK (severity IN ('info','success','warning','error','critical')),
  inbox_status TEXT NOT NULL CHECK (inbox_status IN ('unread','read','archived')),
  attention_status TEXT NOT NULL CHECK (attention_status IN ('informational','action_required','resolved')),
  source_type TEXT NOT NULL CHECK (source_type IN ('atomic_task','task_group','dag_task_group','application_run','artifact','asset','asset_version','application_engine_instance','provider_model','storage_backend','canvas_run','scan_run','asset_batch','user_action','agent_run','system')),
  source_id TEXT NOT NULL,
  source_aggregate_version BIGINT NOT NULL CHECK (source_aggregate_version >= 0),
  navigation_target_json JSONB CHECK (navigation_target_json IS NULL OR jsonb_typeof(navigation_target_json) = 'object'),
  action_path TEXT,
  deduplication_key TEXT NOT NULL,
  aggregate_key TEXT NOT NULL DEFAULT '',
  aggregation_window TEXT NOT NULL CHECK (aggregation_window IN ('immediate','per_source','1_minute','5_minutes','1_hour','daily_digest')),
  aggregation_bucket TIMESTAMPTZ,
  occurrence_count INTEGER NOT NULL DEFAULT 1 CHECK (occurrence_count >= 1),
  first_occurred_at TIMESTAMPTZ NOT NULL,
  last_occurred_at TIMESTAMPTZ NOT NULL,
  read_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  UNIQUE (recipient_user_id, deduplication_key),
  CHECK (last_occurred_at >= first_occurred_at),
  CHECK (expires_at IS NULL OR expires_at > first_occurred_at),
  CHECK ((inbox_status = 'unread' AND read_at IS NULL) OR (inbox_status = 'read' AND read_at IS NOT NULL) OR inbox_status = 'archived'),
  CHECK ((inbox_status = 'archived' AND archived_at IS NOT NULL) OR (inbox_status <> 'archived' AND archived_at IS NULL)),
  CHECK ((attention_status = 'resolved' AND resolved_at IS NOT NULL) OR (attention_status <> 'resolved' AND resolved_at IS NULL)),
  CHECK ((aggregate_key = '' AND aggregation_bucket IS NULL) OR (aggregate_key <> '' AND aggregation_bucket IS NOT NULL))
);

CREATE UNIQUE INDEX idx_notifications_aggregate_window
  ON notifications(recipient_user_id, aggregate_key, aggregation_window, aggregation_bucket)
  WHERE aggregate_key <> '' AND deleted_at IS NULL;
CREATE INDEX idx_notifications_recipient_inbox
  ON notifications(recipient_user_id, inbox_status, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_notifications_recipient_attention
  ON notifications(recipient_user_id, attention_status, severity, last_occurred_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_notifications_recipient_category
  ON notifications(recipient_user_id, category, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_notifications_source
  ON notifications(source_type, source_id, source_aggregate_version);
CREATE INDEX idx_notifications_expiry
  ON notifications(expires_at)
  WHERE expires_at IS NOT NULL AND deleted_at IS NULL;

-- N:M provenance for aggregated notifications. It never changes source business facts.
-- s1_refs: US-NOTIFY-001, US-NOTIFY-007; BR-NOTIFY-005..007, BR-NOTIFY-017..018.
CREATE TABLE notification_event_links (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  notification_id TEXT NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  notification_event_id TEXT NOT NULL REFERENCES notification_events(id) ON DELETE RESTRICT,
  source_aggregate_version BIGINT NOT NULL CHECK (source_aggregate_version >= 0),
  occurrence_delta INTEGER NOT NULL DEFAULT 1 CHECK (occurrence_delta >= 1),
  UNIQUE (notification_id, notification_event_id)
);

CREATE INDEX idx_notification_event_links_event
  ON notification_event_links(notification_event_id, notification_id);

-- Per-recipient counter projection updated atomically with inbox mutations.
-- s1_refs: US-NOTIFY-001..002, US-NOTIFY-004; BR-NOTIFY-008, BR-NOTIFY-012, BR-NOTIFY-016..017.
CREATE TABLE notification_recipient_counters (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  recipient_user_id TEXT NOT NULL UNIQUE,
  unread_count INTEGER NOT NULL DEFAULT 0 CHECK (unread_count >= 0),
  critical_count INTEGER NOT NULL DEFAULT 0 CHECK (critical_count >= 0),
  action_required_count INTEGER NOT NULL DEFAULT 0 CHECK (action_required_count >= 0)
);

-- Explicit user overrides. Empty topic means category-level preference.
-- Future channel columns are reserved but not exposed as writable first-phase API.
-- s1_refs: US-NOTIFY-003; BR-NOTIFY-011..015, BR-NOTIFY-020, BR-NOTIFY-024.
CREATE TABLE notification_preferences (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  user_id TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('system','task','asset','application','provider','storage','security','agent','canvas')),
  notification_topic TEXT NOT NULL DEFAULT '',
  in_app_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  email_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  webhook_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  mobile_push_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  minimum_severity TEXT NOT NULL DEFAULT 'info' CHECK (minimum_severity IN ('info','success','warning','error','critical')),
  merge_repeated BOOLEAN NOT NULL DEFAULT TRUE,
  digest_mode TEXT NOT NULL DEFAULT 'none' CHECK (digest_mode IN ('none','daily','weekly')),
  mute_until TIMESTAMPTZ,
  UNIQUE (user_id, category, notification_topic),
  CHECK (notification_topic = '' OR notification_topic ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$')
);

CREATE INDEX idx_notification_preferences_user
  ON notification_preferences(user_id, category, notification_topic);

-- Reserved multi-channel delivery record. First phase may omit in_app rows and must not create external rows.
-- s1_refs: US-NOTIFY-007; BR-NOTIFY-015, BR-NOTIFY-017, BR-NOTIFY-019, BR-NOTIFY-024.
CREATE TABLE notification_deliveries (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  notification_id TEXT NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('in_app','email','webhook','mobile_push')),
  delivery_status TEXT NOT NULL CHECK (delivery_status IN ('PENDING','SENDING','SENT','FAILED','DEAD_LETTER','CANCELED')),
  destination TEXT NOT NULL DEFAULT '',
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  last_error_code TEXT NOT NULL DEFAULT '',
  last_error_summary TEXT NOT NULL DEFAULT '',
  scheduled_at TIMESTAMPTZ,
  next_attempt_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  UNIQUE (notification_id, channel, destination)
);

CREATE INDEX idx_notification_deliveries_dispatch
  ON notification_deliveries(channel, delivery_status, next_attempt_at, scheduled_at);

-- Notification changes and counter changes are atomically persisted before SSE projection.
-- s1_refs: US-NOTIFY-004, US-NOTIFY-007; BR-NOTIFY-016..017, BR-NOTIFY-021.
CREATE TABLE notification_outbox (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  event_name TEXT NOT NULL CHECK (event_name IN ('notification_created','notification_updated','notification_deleted','notification_unread_count_changed')),
  aggregate_type TEXT NOT NULL CHECK (aggregate_type IN ('notification','notification_recipient_counter')),
  aggregate_id TEXT NOT NULL,
  aggregate_version BIGINT NOT NULL CHECK (aggregate_version >= 0),
  recipient_user_id TEXT NOT NULL,
  payload_json JSONB NOT NULL CHECK (jsonb_typeof(payload_json) = 'object'),
  delivery_status TEXT NOT NULL CHECK (delivery_status IN ('PENDING','PUBLISHED','FAILED')),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  UNIQUE (aggregate_type, aggregate_id, aggregate_version, event_name)
);

CREATE INDEX idx_notification_outbox_delivery
  ON notification_outbox(delivery_status, next_attempt_at, created_at);
