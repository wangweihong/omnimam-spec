-- task-center S2 design schema.
-- Product source: 00_product/domains/task-center/product-spec.md
-- 本文件是设计态 schema，不是实际数据库 migration。

-- S1 refs: US-TASK-001, US-TASK-004, US-TASK-005, US-TASK-006; BR-TASK-001..BR-TASK-006.
CREATE TABLE task_definitions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  definition_type TEXT NOT NULL CHECK (definition_type IN ('ATOMIC', 'TASK_GROUP', 'DAG_FLOW')),
  function_ref TEXT DEFAULT '',
  app_id TEXT DEFAULT '',
  engine_ref TEXT DEFAULT '',
  default_arguments_json TEXT NOT NULL DEFAULT '{}',
  required_capabilities TEXT DEFAULT '',
  group_type TEXT DEFAULT '' CHECK (group_type IN ('', 'SERIAL', 'PARALLEL')),
  children_json TEXT NOT NULL DEFAULT '[]',
  dag_nodes_json TEXT NOT NULL DEFAULT '[]',
  dag_edges_json TEXT NOT NULL DEFAULT '[]',
  strategy_config_json TEXT NOT NULL DEFAULT '{}',
  timeout_policy_json TEXT NOT NULL DEFAULT '{}',
  retry_policy_json TEXT NOT NULL DEFAULT '{}',
  cancel_policy_json TEXT NOT NULL DEFAULT '{}',
  tags TEXT DEFAULT '',
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  deleted_at TEXT DEFAULT ''
);

CREATE INDEX idx_task_definitions_project_namespace ON task_definitions(project_id, namespace);
CREATE INDEX idx_task_definitions_type ON task_definitions(definition_type);
CREATE INDEX idx_task_definitions_function_ref ON task_definitions(function_ref);

-- S1 refs: US-TASK-001, US-TASK-004, US-TASK-005, US-TASK-006; BR-TASK-007, BR-TASK-011, BR-TASK-025, BR-TASK-026, BR-TASK-037..BR-TASK-041.
CREATE TABLE task_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  definition_type TEXT NOT NULL CHECK (definition_type IN ('ATOMIC', 'TASK_GROUP', 'DAG_FLOW')),
  definition_id TEXT NOT NULL REFERENCES task_definitions(id),
  parent_run_id TEXT DEFAULT '',
  root_run_id TEXT DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'READY', 'CLAIMED', 'RUNNING', 'RETRYING', 'CANCEL_REQUESTED', 'PAUSED', 'SUCCESS', 'FAILED', 'CANCELED', 'TIMEOUT', 'LOST')),
  schedule_at TEXT DEFAULT '',
  timeout_at TEXT DEFAULT '',
  current_attempt INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 1,
  progress REAL NOT NULL DEFAULT 0,
  input_json TEXT NOT NULL DEFAULT '{}',
  output_json TEXT NOT NULL DEFAULT '{}',
  last_error_json TEXT NOT NULL DEFAULT '{}',
  started_at TEXT DEFAULT '',
  completed_at TEXT DEFAULT '',
  canceled_at TEXT DEFAULT '',
  created_by TEXT NOT NULL,
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  tags TEXT DEFAULT '',
  deleted_at TEXT DEFAULT ''
);

CREATE INDEX idx_task_runs_project_namespace ON task_runs(project_id, namespace);
CREATE INDEX idx_task_runs_status ON task_runs(status);
CREATE INDEX idx_task_runs_definition ON task_runs(definition_type, definition_id);
CREATE INDEX idx_task_runs_parent ON task_runs(parent_run_id);
CREATE INDEX idx_task_runs_root ON task_runs(root_run_id);
CREATE INDEX idx_task_runs_schedule ON task_runs(schedule_at);

-- S1 refs: US-TASK-003, US-TASK-007; BR-TASK-008..BR-TASK-012, BR-TASK-032, BR-TASK-033, BR-TASK-042..BR-TASK-047.
CREATE TABLE task_attempts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  run_id TEXT NOT NULL REFERENCES task_runs(id),
  attempt_no INTEGER NOT NULL,
  worker_id TEXT DEFAULT '',
  lease_id TEXT DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('CLAIMED', 'RUNNING', 'SUCCESS', 'FAILED', 'TIMEOUT', 'CANCELED', 'WORKER_LOST', 'LEASE_EXPIRED', 'STALLED')),
  input_snapshot_json TEXT NOT NULL DEFAULT '{}',
  output_snapshot_json TEXT NOT NULL DEFAULT '{}',
  error_json TEXT NOT NULL DEFAULT '{}',
  started_at TEXT NOT NULL,
  heartbeat_at TEXT DEFAULT '',
  progress_at TEXT DEFAULT '',
  completed_at TEXT DEFAULT '',
  duration_ms INTEGER NOT NULL DEFAULT 0,
  retryable BOOLEAN NOT NULL DEFAULT FALSE,
  failure_type TEXT DEFAULT '' CHECK (failure_type IN ('', 'FUNCTION_ERROR', 'TIMEOUT', 'CANCELED', 'WORKER_LOST', 'LEASE_EXPIRED', 'EXTERNAL_EXECUTOR_ERROR', 'SYSTEM_ERROR', 'STALLED')),
  logs_ref TEXT DEFAULT '',
  external_job_id TEXT DEFAULT ''
);

CREATE UNIQUE INDEX idx_task_attempts_run_attempt_no ON task_attempts(run_id, attempt_no);
CREATE INDEX idx_task_attempts_worker ON task_attempts(worker_id);
CREATE INDEX idx_task_attempts_status ON task_attempts(status);
CREATE INDEX idx_task_attempts_lease ON task_attempts(lease_id);

-- S1 refs: US-TASK-007; BR-TASK-013, BR-TASK-014, BR-TASK-017, BR-TASK-020, BR-TASK-042.
CREATE TABLE task_workers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  worker_type TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('ONLINE', 'BUSY', 'DRAINING', 'OFFLINE', 'LOST', 'DISABLED')),
  capabilities TEXT NOT NULL,
  labels TEXT DEFAULT '',
  max_concurrency INTEGER NOT NULL DEFAULT 1,
  running_count INTEGER NOT NULL DEFAULT 0,
  heartbeat_at TEXT NOT NULL,
  registered_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL
);

CREATE INDEX idx_task_workers_status ON task_workers(status);
CREATE INDEX idx_task_workers_type ON task_workers(worker_type);
CREATE INDEX idx_task_workers_heartbeat ON task_workers(heartbeat_at);

-- S1 refs: US-TASK-007; BR-TASK-015, BR-TASK-016, BR-TASK-018, BR-TASK-027..BR-TASK-031, BR-TASK-043.
CREATE TABLE task_execution_leases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  run_id TEXT NOT NULL REFERENCES task_runs(id),
  attempt_id TEXT NOT NULL REFERENCES task_attempts(id),
  worker_id TEXT NOT NULL REFERENCES task_workers(id),
  acquired_at TEXT NOT NULL,
  expire_at TEXT NOT NULL,
  renewed_at TEXT DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'RENEWED', 'EXPIRED', 'RELEASED', 'REVOKED'))
);

CREATE UNIQUE INDEX idx_task_execution_leases_active_run
  ON task_execution_leases(run_id)
  WHERE status IN ('ACTIVE', 'RENEWED');
CREATE INDEX idx_task_execution_leases_worker ON task_execution_leases(worker_id);
CREATE INDEX idx_task_execution_leases_expire_at ON task_execution_leases(expire_at);

-- S1 refs: US-TASK-001, US-TASK-002, US-TASK-003, US-TASK-007; BR-TASK-010, BR-TASK-011, BR-TASK-012, BR-TASK-037..BR-TASK-047.
CREATE TABLE task_run_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  run_id TEXT NOT NULL REFERENCES task_runs(id),
  attempt_id TEXT DEFAULT '',
  worker_id TEXT DEFAULT '',
  event_type TEXT NOT NULL,
  from_status TEXT DEFAULT '',
  to_status TEXT DEFAULT '',
  payload_json TEXT NOT NULL DEFAULT '{}',
  occurred_at TEXT NOT NULL
);

CREATE INDEX idx_task_run_events_run ON task_run_events(run_id);
CREATE INDEX idx_task_run_events_type ON task_run_events(event_type);
CREATE INDEX idx_task_run_events_occurred ON task_run_events(occurred_at);

-- S1 refs: US-TASK-007; BR-TASK-042..BR-TASK-047.
CREATE TABLE task_watchdog_records (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  scan_type TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  action_taken TEXT NOT NULL,
  result_status TEXT NOT NULL,
  detail_json TEXT NOT NULL DEFAULT '{}',
  occurred_at TEXT NOT NULL
);

CREATE INDEX idx_task_watchdog_records_target ON task_watchdog_records(target_type, target_id);
CREATE INDEX idx_task_watchdog_records_occurred ON task_watchdog_records(occurred_at);
