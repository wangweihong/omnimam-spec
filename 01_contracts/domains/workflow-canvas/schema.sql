-- workflow-canvas design schema for spec-v1.0.0 (PostgreSQL).
-- s1_refs: US-WORKFLOW-001..004; BR-WORKFLOW-001..015.

CREATE TABLE canvases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  visibility TEXT NOT NULL CHECK (visibility IN ('PRIVATE', 'PROJECT')),
  draft_graph_json TEXT NOT NULL DEFAULT '{"nodes":[],"edges":[]}',
  draft_revision BIGINT NOT NULL DEFAULT 1 CHECK (draft_revision > 0),
  latest_version INTEGER NOT NULL DEFAULT 0 CHECK (latest_version >= 0),
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  deleted_at TIMESTAMPTZ,
  UNIQUE (project_id, namespace, id)
);

CREATE INDEX idx_canvases_scope_updated
  ON canvases (project_id, namespace, updated_at DESC)
  WHERE deleted_at IS NULL;

CREATE TABLE canvas_versions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  canvas_id TEXT NOT NULL REFERENCES canvases(id),
  version INTEGER NOT NULL CHECK (version > 0),
  graph_snapshot_json TEXT NOT NULL,
  input_schema_json TEXT NOT NULL DEFAULT '{}',
  output_schema_json TEXT NOT NULL DEFAULT '{}',
  content_digest TEXT NOT NULL,
  compiled_definition_name TEXT NOT NULL,
  compiled_definition_version INTEGER NOT NULL CHECK (compiled_definition_version > 0),
  node_count INTEGER NOT NULL CHECK (node_count BETWEEN 1 AND 1000),
  edge_count INTEGER NOT NULL CHECK (edge_count BETWEEN 0 AND 5000),
  published_by TEXT NOT NULL,
  published_at TIMESTAMPTZ NOT NULL,
  UNIQUE (canvas_id, version),
  UNIQUE (canvas_id, content_digest)
);

CREATE TABLE canvas_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  canvas_id TEXT NOT NULL REFERENCES canvases(id),
  canvas_version_id TEXT NOT NULL REFERENCES canvas_versions(id),
  idempotency_key TEXT NOT NULL,
  request_digest TEXT NOT NULL,
  input_snapshot_json TEXT NOT NULL DEFAULT '{}',
  dag_task_group_id TEXT UNIQUE,
  task_creation_status TEXT NOT NULL CHECK (task_creation_status IN ('PENDING', 'CREATED', 'FAILED')),
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'RUNNING', 'SUCCESS', 'FAILED', 'CANCELED', 'TIMEOUT')),
  progress REAL NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  summary_json TEXT NOT NULL DEFAULT '{}',
  output_json TEXT NOT NULL DEFAULT '{}',
  last_error_json TEXT NOT NULL DEFAULT '{}',
  task_resource_version BIGINT NOT NULL DEFAULT 0 CHECK (task_resource_version >= 0),
  retry_of_canvas_run_id TEXT REFERENCES canvas_runs(id),
  project_id TEXT NOT NULL,
  namespace TEXT NOT NULL,
  created_by TEXT NOT NULL,
  finished_at TIMESTAMPTZ,
  UNIQUE (project_id, namespace, created_by, idempotency_key),
  CHECK (
    (task_creation_status = 'CREATED' AND dag_task_group_id IS NOT NULL) OR
    (task_creation_status IN ('PENDING', 'FAILED') AND dag_task_group_id IS NULL)
  )
);

CREATE INDEX idx_canvas_runs_scope_created
  ON canvas_runs (project_id, namespace, created_at DESC);
CREATE INDEX idx_canvas_runs_version
  ON canvas_runs (canvas_version_id, created_at DESC);

CREATE TABLE canvas_node_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  canvas_run_id TEXT NOT NULL REFERENCES canvas_runs(id),
  node_key TEXT NOT NULL,
  node_type TEXT NOT NULL CHECK (node_type IN ('APPLICATION', 'FUNCTION', 'DYNAMIC_FORK')),
  atomic_task_id TEXT UNIQUE,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'BLOCKED', 'READY', 'RUNNING', 'RETRYING', 'SUCCESS', 'FAILED', 'CANCELED', 'TIMEOUT', 'SKIPPED')),
  progress REAL NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  output_json TEXT NOT NULL DEFAULT '{}',
  last_error_json TEXT NOT NULL DEFAULT '{}',
  task_resource_version BIGINT NOT NULL DEFAULT 0 CHECK (task_resource_version >= 0),
  finished_at TIMESTAMPTZ,
  UNIQUE (canvas_run_id, node_key),
  CHECK (node_type = 'DYNAMIC_FORK' OR atomic_task_id IS NOT NULL)
);

CREATE INDEX idx_canvas_node_runs_run_status
  ON canvas_node_runs (canvas_run_id, status, node_key);
