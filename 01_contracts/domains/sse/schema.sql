-- Design-time schema only. This file is not a migration.

-- s1_refs: US-SSE-001..005; BR-SSE-003..012, BR-SSE-014..016.
CREATE TABLE sse_user_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  event_sequence BIGSERIAL NOT NULL UNIQUE,
  recipient_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_version INTEGER NOT NULL DEFAULT 1 CHECK (event_version >= 1),
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  aggregate_version INTEGER NOT NULL CHECK (aggregate_version >= 0),
  correlation_id TEXT,
  causation_id TEXT,
  application_run_id TEXT,
  task_group_id TEXT,
  dag_task_group_id TEXT,
  atomic_task_id TEXT,
  task_attempt_id TEXT,
  artifact_id TEXT,
  payload_json TEXT NOT NULL,
  source_domain TEXT NOT NULL,
  source_event_id TEXT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  CHECK (expires_at > occurred_at)
);

CREATE UNIQUE INDEX idx_sse_user_events_source
  ON sse_user_events(recipient_user_id, source_domain, source_event_id, event_type);
CREATE INDEX idx_sse_user_events_recipient_sequence
  ON sse_user_events(recipient_user_id, event_sequence);
CREATE INDEX idx_sse_user_events_recipient_occurred
  ON sse_user_events(recipient_user_id, occurred_at);
CREATE INDEX idx_sse_user_events_aggregate
  ON sse_user_events(aggregate_type, aggregate_id, aggregate_version);
CREATE INDEX idx_sse_user_events_expires
  ON sse_user_events(expires_at);

-- Connection state is process-local and diagnostic-only. Persisting active SSE
-- connections as a business resource would create a stale second source and is
-- prohibited; connection.ready/server_draining are generated control events.
