-- task-center spec-v1.0.0 design schema. This is not a runtime migration.

-- s1_refs: US-TASK-008, US-TASK-018..020, US-TASK-023..024, BR-TASK-073..077, BR-TASK-087..100, BR-TASK-120..126, BR-TASK-135, BR-TASK-142.
CREATE TABLE atomic_tasks (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  name_source TEXT NOT NULL DEFAULT 'USER' CHECK (name_source IN ('USER','SYSTEM')),
  system_name_key TEXT NOT NULL DEFAULT '',
  system_name_params_json TEXT NOT NULL DEFAULT '{}',
  function_ref TEXT NOT NULL,
  arguments_json TEXT NOT NULL DEFAULT '{}',
  required_capabilities TEXT DEFAULT '',
  retry_policy_json TEXT NOT NULL DEFAULT '{}',
  timeout_policy_json TEXT NOT NULL DEFAULT '{}',
  cancel_policy_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('PENDING','BLOCKED','READY','RUNNING','RETRYING','CANCEL_REQUESTED','SUCCESS','FAILED','CANCELED','TIMEOUT','SKIPPED')),
  progress REAL NOT NULL DEFAULT 0 CHECK (progress >= 0 AND progress <= 1),
  current_attempt INTEGER NOT NULL DEFAULT 0,
  -- Only small references such as artifact_refs/representation_refs; never media bodies or credentials.
  output_json TEXT NOT NULL DEFAULT '{}',
  last_error_json TEXT NOT NULL DEFAULT '{}',
  retry_of_task_id TEXT REFERENCES atomic_tasks(id),
  root_task_id TEXT REFERENCES atomic_tasks(id),
  owner_type TEXT DEFAULT '' CHECK (owner_type IN ('','TASK_GROUP','DAG_TASK_GROUP','TASK_SCHEDULE')),
  owner_id TEXT DEFAULT '',
  child_key TEXT DEFAULT '',
  dag_node_key TEXT NOT NULL DEFAULT '',
  child_order INTEGER NOT NULL DEFAULT 0,
  application_run_id TEXT DEFAULT '',
  canvas_run_id TEXT DEFAULT '',
  canvas_node_run_id TEXT DEFAULT '',
  idempotency_scope TEXT DEFAULT '',
  idempotency_key TEXT DEFAULT '',
  runtime_execution_id TEXT DEFAULT '',
  runtime_task_id TEXT DEFAULT '',
  runtime_revision TEXT DEFAULT '',
  schedule_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  tags TEXT DEFAULT '',
  deleted_at TIMESTAMPTZ,
  CHECK ((idempotency_scope = '' AND idempotency_key = '') OR (idempotency_scope <> '' AND idempotency_key <> '')),
  CHECK ((name_source = 'USER' AND system_name_key = '') OR (name_source = 'SYSTEM' AND system_name_key <> ''))
);

CREATE UNIQUE INDEX idx_atomic_tasks_idempotency ON atomic_tasks(project_id, namespace, idempotency_scope, idempotency_key) WHERE idempotency_scope <> '';
CREATE UNIQUE INDEX idx_atomic_tasks_owner_child ON atomic_tasks(owner_type, owner_id, child_key) WHERE owner_type IN ('TASK_GROUP','DAG_TASK_GROUP') AND child_key <> '';
CREATE INDEX idx_atomic_tasks_status ON atomic_tasks(status, schedule_at);
CREATE INDEX idx_atomic_tasks_owner ON atomic_tasks(owner_type, owner_id, child_order);
CREATE INDEX idx_atomic_tasks_dag_node ON atomic_tasks(owner_id, dag_node_key, child_order) WHERE owner_type = 'DAG_TASK_GROUP' AND dag_node_key <> '';
CREATE INDEX idx_atomic_tasks_retry_root ON atomic_tasks(root_task_id);
CREATE INDEX idx_atomic_tasks_application_run ON atomic_tasks(application_run_id) WHERE application_run_id <> '';
CREATE INDEX idx_atomic_tasks_canvas_run ON atomic_tasks(canvas_run_id) WHERE canvas_run_id <> '';
CREATE UNIQUE INDEX idx_atomic_tasks_runtime_task ON atomic_tasks(runtime_task_id) WHERE runtime_task_id <> '';

-- s1_refs: US-TASK-008, US-TASK-014, US-TASK-018, US-TASK-022..023, BR-TASK-075, BR-TASK-077, BR-TASK-120, BR-TASK-129..132, BR-TASK-138.
CREATE TABLE task_attempts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  atomic_task_id TEXT NOT NULL REFERENCES atomic_tasks(id),
  attempt_no INTEGER NOT NULL,
  runtime_task_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('SCHEDULED','RUNNING','SUCCESS','FAILED','CANCELED','TIMEOUT')),
  input_snapshot_json TEXT NOT NULL DEFAULT '{}',
  output_snapshot_json TEXT NOT NULL DEFAULT '{}',
  error_json TEXT NOT NULL DEFAULT '{}',
  external_job_id TEXT DEFAULT '',
  logs_ref TEXT DEFAULT '',
  executor_type TEXT NOT NULL DEFAULT '',
  executor_display_name TEXT NOT NULL DEFAULT '',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  duration_ms BIGINT NOT NULL DEFAULT 0,
  retryable BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (atomic_task_id, attempt_no),
  UNIQUE (runtime_task_id)
);

-- s1_refs: US-TASK-009, US-TASK-018, US-TASK-024, BR-TASK-078..080, BR-TASK-098..099, BR-TASK-120, BR-TASK-142.
CREATE TABLE task_groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  name_source TEXT NOT NULL DEFAULT 'USER' CHECK (name_source IN ('USER','SYSTEM')),
  system_name_key TEXT NOT NULL DEFAULT '',
  system_name_params_json TEXT NOT NULL DEFAULT '{}',
  mode TEXT NOT NULL CHECK (mode IN ('SERIAL','PARALLEL')),
  task_templates_json TEXT NOT NULL,
  strategy_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('PENDING','RUNNING','CANCEL_REQUESTED','SUCCESS','FAILED','CANCELED','TIMEOUT')),
  progress REAL NOT NULL DEFAULT 0 CHECK (progress >= 0 AND progress <= 1),
  summary_json TEXT NOT NULL DEFAULT '{}',
  result_json TEXT NOT NULL DEFAULT '{}',
  retry_of_id TEXT REFERENCES task_groups(id),
  runtime_execution_id TEXT DEFAULT '',
  runtime_definition_name TEXT DEFAULT '',
  runtime_definition_version INTEGER NOT NULL DEFAULT 0,
  idempotency_scope TEXT DEFAULT '',
  idempotency_key TEXT DEFAULT '',
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  CHECK ((idempotency_scope = '' AND idempotency_key = '') OR (idempotency_scope <> '' AND idempotency_key <> '')),
  CHECK ((name_source = 'USER' AND system_name_key = '') OR (name_source = 'SYSTEM' AND system_name_key <> ''))
);

CREATE UNIQUE INDEX idx_task_groups_idempotency ON task_groups(project_id, namespace, idempotency_scope, idempotency_key) WHERE idempotency_scope <> '';
CREATE INDEX idx_task_groups_status ON task_groups(status, created_at);

-- s1_refs: US-TASK-010, US-TASK-018, US-TASK-023..024, BR-TASK-081..082, BR-TASK-094..099, BR-TASK-120, BR-TASK-133..142.
CREATE TABLE dag_task_groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  name_source TEXT NOT NULL DEFAULT 'USER' CHECK (name_source IN ('USER','SYSTEM')),
  system_name_key TEXT NOT NULL DEFAULT '',
  system_name_params_json TEXT NOT NULL DEFAULT '{}',
  nodes_json TEXT NOT NULL,
  edges_json TEXT NOT NULL,
  input_mapping_json TEXT NOT NULL DEFAULT '{}',
  output_mapping_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('PENDING','RUNNING','CANCEL_REQUESTED','SUCCESS','FAILED','CANCELED','TIMEOUT')),
  progress REAL NOT NULL DEFAULT 0 CHECK (progress >= 0 AND progress <= 1),
  summary_json TEXT NOT NULL DEFAULT '{}',
  result_json TEXT NOT NULL DEFAULT '{}',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  trigger_type TEXT NOT NULL DEFAULT 'API' CHECK (trigger_type IN ('API','SCHEDULE','CANVAS','DOMAIN_EVENT','RETRY')),
  trigger_source_id TEXT NOT NULL DEFAULT '',
  trigger_source_name TEXT NOT NULL DEFAULT '',
  triggered_at TIMESTAMPTZ,
  retry_of_id TEXT REFERENCES dag_task_groups(id),
  canvas_version_id TEXT DEFAULT '',
  runtime_execution_id TEXT DEFAULT '',
  runtime_definition_name TEXT NOT NULL,
  runtime_definition_version INTEGER NOT NULL,
  runtime_definition_hash TEXT NOT NULL,
  idempotency_scope TEXT DEFAULT '',
  idempotency_key TEXT DEFAULT '',
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  CHECK ((idempotency_scope = '' AND idempotency_key = '') OR (idempotency_scope <> '' AND idempotency_key <> '')),
  CHECK ((name_source = 'USER' AND system_name_key = '') OR (name_source = 'SYSTEM' AND system_name_key <> ''))
);

CREATE INDEX idx_dag_groups_definition ON dag_task_groups(runtime_definition_name, runtime_definition_version);
CREATE UNIQUE INDEX idx_dag_groups_idempotency ON dag_task_groups(project_id, namespace, idempotency_scope, idempotency_key) WHERE idempotency_scope <> '';
CREATE INDEX idx_dag_groups_canvas_version ON dag_task_groups(canvas_version_id) WHERE canvas_version_id <> '';
CREATE INDEX idx_dag_groups_status_time ON dag_task_groups(status, started_at, completed_at);

-- s1_refs: US-TASK-011, US-TASK-013, US-TASK-017, US-TASK-024, BR-TASK-083..086, BR-TASK-107..118, BR-TASK-142.
CREATE TABLE task_schedules (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  name_source TEXT NOT NULL DEFAULT 'USER' CHECK (name_source IN ('USER','SYSTEM')),
  system_name_key TEXT NOT NULL DEFAULT '',
  system_name_params_json TEXT NOT NULL DEFAULT '{}',
  execution_mode TEXT NOT NULL DEFAULT 'MATERIALIZED' CHECK (execution_mode IN ('MATERIALIZED','RECONCILE')),
  management_mode TEXT NOT NULL DEFAULT 'USER' CHECK (management_mode IN ('USER','SYSTEM')),
  system_key TEXT NOT NULL DEFAULT '',
  trigger_type TEXT NOT NULL CHECK (trigger_type IN ('CRON','RUN_AT')),
  cron_expression TEXT DEFAULT '',
  run_at TIMESTAMPTZ,
  time_zone TEXT NOT NULL DEFAULT 'UTC',
  target_type TEXT NOT NULL DEFAULT '' CHECK (target_type IN ('','ATOMIC_TASK','TASK_GROUP','DAG_TASK_GROUP')),
  target_template_json TEXT NOT NULL DEFAULT '',
  reconcile_ref TEXT NOT NULL DEFAULT '',
  reconcile_config_json TEXT NOT NULL DEFAULT '{}',
  reconcile_max_parallelism INTEGER NOT NULL DEFAULT 16 CHECK (reconcile_max_parallelism BETWEEN 1 AND 64),
  reconcile_max_items_per_run INTEGER NOT NULL DEFAULT 1000 CHECK (reconcile_max_items_per_run BETWEEN 1 AND 1000),
  reconcile_per_item_timeout_seconds INTEGER NOT NULL DEFAULT 4 CHECK (reconcile_per_item_timeout_seconds BETWEEN 1 AND 30),
  reconcile_overall_timeout_seconds INTEGER NOT NULL DEFAULT 5 CHECK (reconcile_overall_timeout_seconds BETWEEN 1 AND 300),
  history_retention_json TEXT NOT NULL DEFAULT '{"success_count":4,"failure_count":20,"failure_duration_seconds":604800,"skipped_count":4,"runtime_retention_seconds":86400}',
  status TEXT NOT NULL CHECK (status IN ('ACTIVE','PAUSED','COMPLETED','DELETED')),
  misfire_policy TEXT NOT NULL DEFAULT 'SKIP' CHECK (misfire_policy = 'SKIP'),
  overlap_policy TEXT NOT NULL DEFAULT 'SKIP' CHECK (overlap_policy = 'SKIP'),
  runtime_schedule_name TEXT DEFAULT '',
  last_trigger_at TIMESTAMPTZ,
  next_trigger_at TIMESTAMPTZ,
  summary_json TEXT NOT NULL DEFAULT '{}',
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  CHECK ((trigger_type = 'CRON' AND cron_expression <> '' AND run_at IS NULL) OR (trigger_type = 'RUN_AT' AND cron_expression = '' AND run_at IS NOT NULL)),
  CHECK ((management_mode = 'USER' AND system_key = '') OR (management_mode = 'SYSTEM' AND system_key <> '')),
  CHECK (reconcile_overall_timeout_seconds >= reconcile_per_item_timeout_seconds),
  CHECK (
    (execution_mode = 'MATERIALIZED' AND target_type <> '' AND target_template_json <> '' AND reconcile_ref = '') OR
    (execution_mode = 'RECONCILE' AND trigger_type = 'CRON' AND target_type = '' AND target_template_json = '' AND reconcile_ref <> '')
  ),
  CHECK ((name_source = 'USER' AND system_name_key = '') OR (name_source = 'SYSTEM' AND system_name_key <> ''))
);

CREATE INDEX idx_task_schedules_status_next ON task_schedules(status, next_trigger_at);
CREATE UNIQUE INDEX idx_task_schedules_system_key ON task_schedules(system_key) WHERE system_key <> '';
CREATE INDEX idx_task_schedules_mode_status ON task_schedules(execution_mode, status, next_trigger_at);

-- s1_refs: US-TASK-017, BR-TASK-110, BR-TASK-113.
-- ScheduleReconcileState 是 TaskSchedule 的内部一对一运行投影，不是独立可命名资源，因此不嵌入通用 ObjectMeta。
CREATE TABLE task_schedule_reconcile_states (
  schedule_id TEXT PRIMARY KEY REFERENCES task_schedules(id) ON DELETE CASCADE,
  checkpoint_json TEXT NOT NULL DEFAULT '{}',
  current_runtime_execution_id TEXT NOT NULL DEFAULT '',
  last_started_at TIMESTAMPTZ,
  last_completed_at TIMESTAMPTZ,
  last_summary_json TEXT NOT NULL DEFAULT '{}',
  consecutive_failures INTEGER NOT NULL DEFAULT 0 CHECK (consecutive_failures >= 0),
  total_runs BIGINT NOT NULL DEFAULT 0 CHECK (total_runs >= 0),
  total_scanned BIGINT NOT NULL DEFAULT 0 CHECK (total_scanned >= 0),
  total_findings BIGINT NOT NULL DEFAULT 0 CHECK (total_findings >= 0),
  total_actions_created BIGINT NOT NULL DEFAULT 0 CHECK (total_actions_created >= 0),
  resource_version INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_schedule_reconcile_states_checkpoint
  ON task_schedule_reconcile_states(last_completed_at, updated_at);

-- s1_refs: US-TASK-011, US-TASK-013, US-TASK-017, BR-TASK-084..086, BR-TASK-111, BR-TASK-114..116.
CREATE TABLE task_schedule_executions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  schedule_id TEXT NOT NULL REFERENCES task_schedules(id),
  execution_mode TEXT NOT NULL CHECK (execution_mode IN ('MATERIALIZED','RECONCILE')),
  scheduled_at TIMESTAMPTZ NOT NULL,
  triggered_at TIMESTAMPTZ,
  target_type TEXT NOT NULL DEFAULT '' CHECK (target_type IN ('','ATOMIC_TASK','TASK_GROUP','DAG_TASK_GROUP')),
  target_id TEXT DEFAULT '',
  reconcile_summary_json TEXT NOT NULL DEFAULT '{}',
  runtime_execution_id TEXT DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('TRIGGERED','RUNNING','SUCCESS','FAILED','CANCELED','SKIPPED_OVERLAP','TRIGGER_FAILED')),
  reason TEXT DEFAULT '',
  completed_at TIMESTAMPTZ,
  UNIQUE (schedule_id, scheduled_at),
  CHECK (
    (execution_mode = 'MATERIALIZED' AND target_type <> '') OR
    (execution_mode = 'RECONCILE' AND target_type = '' AND target_id = '')
  )
);

CREATE INDEX idx_schedule_executions_status ON task_schedule_executions(schedule_id, status, scheduled_at);
CREATE UNIQUE INDEX idx_schedule_executions_active
  ON task_schedule_executions(schedule_id)
  WHERE status IN ('TRIGGERED','RUNNING');
CREATE INDEX idx_schedule_executions_reconcile_retention
  ON task_schedule_executions(schedule_id, execution_mode, status, completed_at DESC, scheduled_at DESC);

-- s1_refs: US-TASK-015, BR-TASK-087..088, BR-TASK-100.
CREATE TABLE runtime_projection_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  runtime_event_id TEXT NOT NULL UNIQUE,
  runtime_execution_id TEXT NOT NULL,
  runtime_task_id TEXT DEFAULT '',
  event_type TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL,
  projected_at TIMESTAMPTZ,
  projection_status TEXT NOT NULL CHECK (projection_status IN ('PENDING','APPLIED','IGNORED','FAILED')),
  failure_detail TEXT DEFAULT ''
);

CREATE INDEX idx_runtime_projection_pending ON runtime_projection_events(projection_status, occurred_at);
CREATE INDEX idx_runtime_projection_execution_time ON runtime_projection_events(runtime_execution_id, occurred_at, id);
