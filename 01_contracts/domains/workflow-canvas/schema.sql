-- workflow-canvas design schema for the S1 v1.1 draft (PostgreSQL).
-- This file is a design contract, not an executable migration.
-- s1_refs: US-WORKFLOW-001..009; BR-WORKFLOW-001..034.

-- s1_refs: US-WORKFLOW-001, US-WORKFLOW-007, US-WORKFLOW-009;
-- BR-WORKFLOW-003..005, BR-WORKFLOW-017, BR-WORKFLOW-028..031.
CREATE TABLE workflow_node_definitions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  node_type TEXT NOT NULL,
  definition_version TEXT NOT NULL,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  node_kind TEXT NOT NULL CHECK (node_kind IN ('data', 'processor', 'generator', 'controller', 'orchestrator', 'viewer')),
  ports_json JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(ports_json) = 'array'),
  config_schema_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(config_schema_json) = 'object'),
  controller_state_schema_json JSONB CHECK (controller_state_schema_json IS NULL OR jsonb_typeof(controller_state_schema_json) = 'object'),
  controller_schema_version TEXT,
  execution_mode TEXT NOT NULL CHECK (execution_mode IN ('passive', 'atomic', 'expanded')),
  function_ref TEXT,
  application_version_id TEXT,
  binding_version TEXT NOT NULL,
  max_dynamic_tasks INTEGER CHECK (max_dynamic_tasks BETWEEN 1 AND 1000),
  renderer_key TEXT,
  renderer_version TEXT,
  supports_client_generated_output BOOLEAN NOT NULL DEFAULT FALSE,
  cache_allowed BOOLEAN NOT NULL DEFAULT FALSE,
  reuse_ttl_seconds INTEGER CHECK (reuse_ttl_seconds IS NULL OR reuse_ttl_seconds > 0),
  availability_scope TEXT NOT NULL CHECK (availability_scope IN ('SYSTEM', 'PROJECT')),
  project_id TEXT,
  namespace TEXT,
  registered_by TEXT NOT NULL,
  deprecated BOOLEAN NOT NULL DEFAULT FALSE,
  deprecated_at TIMESTAMPTZ,
  UNIQUE (node_type, definition_version),
  CHECK ((availability_scope = 'SYSTEM' AND project_id IS NULL AND namespace IS NULL) OR availability_scope = 'PROJECT'),
  CHECK (
    (execution_mode = 'passive' AND function_ref IS NULL AND application_version_id IS NULL) OR
    (execution_mode IN ('atomic', 'expanded') AND (function_ref IS NOT NULL) <> (application_version_id IS NOT NULL))
  ),
  CHECK (controller_state_schema_json IS NULL OR controller_schema_version IS NOT NULL)
);

CREATE INDEX idx_workflow_node_definitions_catalog
  ON workflow_node_definitions (category, node_kind, deprecated, node_type, definition_version);
CREATE INDEX idx_workflow_node_definitions_project
  ON workflow_node_definitions (project_id, namespace, deprecated)
  WHERE availability_scope = 'PROJECT';

-- s1_refs: US-WORKFLOW-001, US-WORKFLOW-007, US-WORKFLOW-009;
-- BR-WORKFLOW-001, BR-WORKFLOW-012, BR-WORKFLOW-029, BR-WORKFLOW-031.
CREATE TABLE canvases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  visibility TEXT NOT NULL CHECK (visibility IN ('PRIVATE', 'PROJECT')),
  draft_graph_json JSONB NOT NULL DEFAULT '{"nodes":[],"edges":[],"flows":[]}'::jsonb CHECK (jsonb_typeof(draft_graph_json) = 'object'),
  draft_revision BIGINT NOT NULL DEFAULT 1 CHECK (draft_revision > 0),
  latest_version INTEGER NOT NULL DEFAULT 0 CHECK (latest_version >= 0),
  latest_published_version_id TEXT,
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  UNIQUE (project_id, namespace, id)
);

CREATE INDEX idx_canvases_scope_updated
  ON canvases (project_id, namespace, updated_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_canvases_creator_updated
  ON canvases (created_by, updated_at DESC)
  WHERE deleted_at IS NULL;

-- s1_refs: US-WORKFLOW-001, US-WORKFLOW-002, US-WORKFLOW-004;
-- BR-WORKFLOW-001..004, BR-WORKFLOW-011..012, BR-WORKFLOW-017..018, BR-WORKFLOW-034.
CREATE TABLE canvas_versions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  canvas_id TEXT NOT NULL REFERENCES canvases(id),
  version INTEGER NOT NULL CHECK (version > 0),
  graph_snapshot_json JSONB NOT NULL CHECK (jsonb_typeof(graph_snapshot_json) = 'object'),
  definition_snapshots_json JSONB NOT NULL CHECK (jsonb_typeof(definition_snapshots_json) = 'array'),
  input_schema_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(input_schema_json) = 'object'),
  output_schema_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(output_schema_json) = 'object'),
  content_digest TEXT NOT NULL,
  execution_template_digest TEXT NOT NULL,
  workflow_definition_name TEXT NOT NULL,
  workflow_definition_version TEXT NOT NULL,
  compile_summary_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(compile_summary_json) = 'object'),
  node_count INTEGER NOT NULL CHECK (node_count BETWEEN 0 AND 1000),
  edge_count INTEGER NOT NULL CHECK (edge_count BETWEEN 0 AND 5000),
  published_by TEXT NOT NULL,
  published_at TIMESTAMPTZ NOT NULL,
  UNIQUE (canvas_id, version),
  UNIQUE (canvas_id, content_digest),
  UNIQUE (workflow_definition_name, workflow_definition_version)
);

ALTER TABLE canvases
  ADD CONSTRAINT fk_canvases_latest_published_version
  FOREIGN KEY (latest_published_version_id) REFERENCES canvas_versions(id);

CREATE INDEX idx_canvas_versions_canvas_published
  ON canvas_versions (canvas_id, published_at DESC);

-- s1_refs: US-WORKFLOW-002..006, US-WORKFLOW-008..009;
-- BR-WORKFLOW-006..007, BR-WORKFLOW-013..016, BR-WORKFLOW-019..021,
-- BR-WORKFLOW-023, BR-WORKFLOW-027..028, BR-WORKFLOW-031..034.
CREATE TABLE canvas_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  canvas_id TEXT NOT NULL REFERENCES canvases(id),
  canvas_version_id TEXT NOT NULL REFERENCES canvas_versions(id),
  idempotency_key TEXT NOT NULL,
  request_digest TEXT NOT NULL,
  input_snapshot_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(input_snapshot_json) = 'object'),
  scope_json JSONB NOT NULL CHECK (jsonb_typeof(scope_json) = 'object'),
  run_policy_json JSONB NOT NULL CHECK (jsonb_typeof(run_policy_json) = 'object'),
  reuse_decisions_json JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(reuse_decisions_json) = 'array'),
  execution_plan_json JSONB NOT NULL CHECK (jsonb_typeof(execution_plan_json) = 'object'),
  execution_plan_digest TEXT NOT NULL,
  dag_task_group_id TEXT UNIQUE,
  task_creation_status TEXT NOT NULL CHECK (task_creation_status IN ('PENDING', 'CREATED', 'RETRYABLE_FAILED')),
  task_creation_attempts INTEGER NOT NULL DEFAULT 0 CHECK (task_creation_attempts >= 0),
  next_task_creation_retry_at TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'RUNNING', 'SUCCESS', 'PARTIAL_SUCCESS', 'FAILED', 'CANCELED', 'TIMEOUT')),
  progress REAL NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  summary_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(summary_json) = 'object'),
  result_summary_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(result_summary_json) = 'object'),
  warnings_json JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(warnings_json) = 'array'),
  last_error_json JSONB CHECK (last_error_json IS NULL OR jsonb_typeof(last_error_json) = 'object'),
  dag_task_group_resource_version BIGINT NOT NULL DEFAULT 0 CHECK (dag_task_group_resource_version >= 0),
  aggregate_version BIGINT NOT NULL DEFAULT 0 CHECK (aggregate_version >= 0),
  retry_of_canvas_run_id TEXT REFERENCES canvas_runs(id),
  retry_intent TEXT CHECK (retry_intent IS NULL OR retry_intent IN ('retry_failed', 'retry_node', 'retry_from_node', 'retry_flow', 'rerun_all')),
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  UNIQUE (project_id, namespace, created_by, idempotency_key),
  CHECK (
    (task_creation_status = 'CREATED' AND dag_task_group_id IS NOT NULL) OR
    (task_creation_status IN ('PENDING', 'RETRYABLE_FAILED') AND dag_task_group_id IS NULL)
  ),
  CHECK ((retry_of_canvas_run_id IS NULL AND retry_intent IS NULL) OR (retry_of_canvas_run_id IS NOT NULL AND retry_intent IS NOT NULL))
);

CREATE INDEX idx_canvas_runs_scope_created
  ON canvas_runs (project_id, namespace, created_at DESC);
CREATE INDEX idx_canvas_runs_canvas_created
  ON canvas_runs (canvas_id, created_at DESC);
CREATE INDEX idx_canvas_runs_version_created
  ON canvas_runs (canvas_version_id, created_at DESC);
CREATE INDEX idx_canvas_runs_task_creation_recovery
  ON canvas_runs (next_task_creation_retry_at, id)
  WHERE task_creation_status = 'RETRYABLE_FAILED';

-- s1_refs: US-WORKFLOW-002, US-WORKFLOW-004..006, US-WORKFLOW-008;
-- BR-WORKFLOW-007, BR-WORKFLOW-014, BR-WORKFLOW-020, BR-WORKFLOW-023, BR-WORKFLOW-026, BR-WORKFLOW-034.
CREATE TABLE canvas_flow_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  canvas_run_id TEXT NOT NULL REFERENCES canvas_runs(id),
  flow_id TEXT NOT NULL,
  execution_keys_json JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(execution_keys_json) = 'array'),
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'RUNNING', 'SUCCESS', 'PARTIAL_SUCCESS', 'FAILED', 'CANCELED', 'TIMEOUT')),
  progress REAL NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  summary_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(summary_json) = 'object'),
  result_summary_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(result_summary_json) = 'object'),
  warnings_json JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(warnings_json) = 'array'),
  aggregate_version BIGINT NOT NULL DEFAULT 0 CHECK (aggregate_version >= 0),
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  UNIQUE (canvas_run_id, flow_id)
);

CREATE INDEX idx_canvas_flow_runs_run_status
  ON canvas_flow_runs (canvas_run_id, status, flow_id);

-- s1_refs: US-WORKFLOW-002..008;
-- BR-WORKFLOW-008..009, BR-WORKFLOW-014, BR-WORKFLOW-020..023,
-- BR-WORKFLOW-027..030, BR-WORKFLOW-033..034.
CREATE TABLE canvas_node_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  canvas_run_id TEXT NOT NULL REFERENCES canvas_runs(id),
  node_id TEXT NOT NULL,
  execution_key TEXT NOT NULL,
  node_type TEXT NOT NULL,
  definition_version TEXT NOT NULL,
  execution_fingerprint TEXT NOT NULL,
  resolved_input_snapshot_json JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(resolved_input_snapshot_json) = 'object'),
  result_mode TEXT NOT NULL CHECK (result_mode IN ('executed', 'reused', 'passive', 'client_generated')),
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'BLOCKED', 'READY', 'RUNNING', 'RETRYING', 'SUCCESS', 'PARTIAL_SUCCESS', 'FAILED', 'CANCELED', 'TIMEOUT', 'SKIPPED', 'REUSED')),
  status_reason TEXT,
  progress REAL NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  task_count INTEGER NOT NULL DEFAULT 0 CHECK (task_count >= 0),
  output_count INTEGER NOT NULL DEFAULT 0 CHECK (output_count >= 0),
  required_output_count INTEGER NOT NULL DEFAULT 0 CHECK (required_output_count >= 0),
  ready_required_output_count INTEGER NOT NULL DEFAULT 0 CHECK (ready_required_output_count >= 0),
  warnings_json JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(warnings_json) = 'array'),
  last_error_json JSONB CHECK (last_error_json IS NULL OR jsonb_typeof(last_error_json) = 'object'),
  source_canvas_run_id TEXT REFERENCES canvas_runs(id),
  source_canvas_node_run_id TEXT REFERENCES canvas_node_runs(id),
  aggregate_version BIGINT NOT NULL DEFAULT 0 CHECK (aggregate_version >= 0),
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  UNIQUE (canvas_run_id, execution_key),
  CHECK (
    (result_mode = 'reused' AND status = 'REUSED' AND source_canvas_run_id IS NOT NULL AND source_canvas_node_run_id IS NOT NULL AND task_count = 0) OR
    (result_mode <> 'reused' AND status <> 'REUSED' AND source_canvas_run_id IS NULL AND source_canvas_node_run_id IS NULL)
  ),
  CHECK (ready_required_output_count <= required_output_count)
);

CREATE INDEX idx_canvas_node_runs_run_status
  ON canvas_node_runs (canvas_run_id, status, node_id);
CREATE INDEX idx_canvas_node_runs_fingerprint
  ON canvas_node_runs (execution_fingerprint, finished_at DESC)
  WHERE status IN ('SUCCESS', 'REUSED');

-- A NodeRun execution instance can be referenced by multiple FlowRuns.
-- s1_refs: US-WORKFLOW-002, US-WORKFLOW-005; BR-WORKFLOW-020, BR-WORKFLOW-026.
CREATE TABLE canvas_node_run_flow_refs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  canvas_node_run_id TEXT NOT NULL REFERENCES canvas_node_runs(id),
  canvas_flow_run_id TEXT NOT NULL REFERENCES canvas_flow_runs(id),
  UNIQUE (canvas_node_run_id, canvas_flow_run_id)
);

CREATE INDEX idx_canvas_node_run_flow_refs_flow
  ON canvas_node_run_flow_refs (canvas_flow_run_id, canvas_node_run_id);

-- AtomicTask and DAGTaskGroup are cross-domain facts; only stable IDs and observed versions are stored.
-- s1_refs: US-WORKFLOW-002..004, US-WORKFLOW-008;
-- BR-WORKFLOW-007..008, BR-WORKFLOW-014, BR-WORKFLOW-016, BR-WORKFLOW-018, BR-WORKFLOW-027.
CREATE TABLE canvas_node_run_task_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  canvas_node_run_id TEXT NOT NULL REFERENCES canvas_node_runs(id),
  dag_task_group_id TEXT NOT NULL,
  atomic_task_id TEXT NOT NULL,
  task_child_key TEXT NOT NULL,
  binding_role TEXT NOT NULL CHECK (binding_role IN ('primary', 'worker', 'dependency', 'join')),
  shard_key TEXT NOT NULL DEFAULT 'root',
  shard_index INTEGER CHECK (shard_index IS NULL OR shard_index >= 0),
  task_resource_version BIGINT NOT NULL DEFAULT 0 CHECK (task_resource_version >= 0),
  UNIQUE (canvas_node_run_id, task_child_key),
  UNIQUE (atomic_task_id)
);

CREATE INDEX idx_canvas_node_run_task_bindings_node
  ON canvas_node_run_task_bindings (canvas_node_run_id, binding_role, shard_index);
CREATE INDEX idx_canvas_node_run_task_bindings_dag
  ON canvas_node_run_task_bindings (dag_task_group_id, task_child_key);

-- Artifact is owned by Asset Library. structured_value_json is only for bounded typed values;
-- large media and file content must use artifact_id.
-- s1_refs: US-WORKFLOW-002..007;
-- BR-WORKFLOW-015, BR-WORKFLOW-021..023, BR-WORKFLOW-029..031, BR-WORKFLOW-033..034.
CREATE TABLE canvas_node_run_output_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  canvas_node_run_id TEXT NOT NULL REFERENCES canvas_node_runs(id),
  port_key TEXT NOT NULL,
  required BOOLEAN NOT NULL,
  shard_key TEXT NOT NULL DEFAULT 'root',
  shard_index INTEGER CHECK (shard_index IS NULL OR shard_index >= 0),
  producer_key TEXT NOT NULL,
  atomic_task_id TEXT,
  artifact_id TEXT,
  structured_value_json JSONB,
  availability_status TEXT NOT NULL CHECK (availability_status IN ('PENDING', 'READY', 'FAILED')),
  artifact_resource_version BIGINT NOT NULL DEFAULT 0 CHECK (artifact_resource_version >= 0),
  warning_json JSONB CHECK (warning_json IS NULL OR jsonb_typeof(warning_json) = 'object'),
  source_output_binding_id TEXT REFERENCES canvas_node_run_output_bindings(id),
  aggregate_version BIGINT NOT NULL DEFAULT 0 CHECK (aggregate_version >= 0),
  UNIQUE (canvas_node_run_id, port_key, shard_key),
  UNIQUE (producer_key),
  CHECK (artifact_id IS NULL OR structured_value_json IS NULL),
  CHECK (availability_status <> 'READY' OR ((artifact_id IS NOT NULL) <> (structured_value_json IS NOT NULL))),
  CHECK ((source_output_binding_id IS NULL) OR (availability_status = 'READY'))
);

CREATE INDEX idx_canvas_node_run_outputs_node_port
  ON canvas_node_run_output_bindings (canvas_node_run_id, port_key, shard_index);
CREATE INDEX idx_canvas_node_run_outputs_artifact
  ON canvas_node_run_output_bindings (artifact_id)
  WHERE artifact_id IS NOT NULL;

-- Reliable event publication belongs to workflow-canvas, so the outbox is modeled explicitly.
-- s1_refs: US-WORKFLOW-004, US-WORKFLOW-006; BR-WORKFLOW-014, BR-WORKFLOW-022..025, BR-WORKFLOW-034.
CREATE TABLE workflow_canvas_outbox (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  event_name TEXT NOT NULL,
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  aggregate_version BIGINT NOT NULL CHECK (aggregate_version >= 0),
  payload_json JSONB NOT NULL CHECK (jsonb_typeof(payload_json) = 'object'),
  delivery_status TEXT NOT NULL CHECK (delivery_status IN ('PENDING', 'PUBLISHED', 'FAILED')),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  UNIQUE (aggregate_type, aggregate_id, aggregate_version, event_name)
);

CREATE INDEX idx_workflow_canvas_outbox_delivery
  ON workflow_canvas_outbox (delivery_status, next_attempt_at, created_at);

-- Reconciliation cursors are durable workflow-canvas resources; they do not copy foreign facts.
-- s1_refs: US-WORKFLOW-004, US-WORKFLOW-006; BR-WORKFLOW-014, BR-WORKFLOW-022..025, BR-WORKFLOW-034.
CREATE TABLE workflow_canvas_reconcile_cursors (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0 CHECK (resource_version >= 0),
  source_domain TEXT NOT NULL CHECK (source_domain IN ('task-center', 'asset-library')),
  partition_key TEXT NOT NULL,
  cursor_value TEXT NOT NULL,
  last_reconciled_at TIMESTAMPTZ,
  last_error_json JSONB CHECK (last_error_json IS NULL OR jsonb_typeof(last_error_json) = 'object'),
  UNIQUE (source_domain, partition_key)
);
