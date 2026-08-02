-- AppStudio S2 design schema, v1.0.0-draft. This is not a migration.
-- 源码正文和存储定位属于 Source Service 私有边界；本 schema 只保存索引、摘要和业务引用。

-- s1_refs: R-STUDIO-001, R-STUDIO-010, R-STUDIO-013; source: 2.1, 6 项目创建, 16 生命周期.
CREATE TABLE studio_applications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'ARCHIVED', 'ERROR')),
  template_id TEXT,
  technology_stack TEXT,
  default_workspace_id TEXT,
  current_version_id TEXT
);
CREATE UNIQUE INDEX idx_studio_applications_owner_name ON studio_applications(owner_user_id, name);
CREATE INDEX idx_studio_applications_owner_status ON studio_applications(owner_user_id, status, created_at);

-- s1_refs: R-STUDIO-001, R-STUDIO-002; source: 3 源码管理总体架构, 4.3 Workspace Service.
CREATE TABLE studio_source_repositories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  provider_type TEXT NOT NULL CHECK (provider_type IN ('BUILT_IN')),
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'ARCHIVED', 'ERROR')),
  current_revision INTEGER NOT NULL DEFAULT 0
);

-- s1_refs: R-STUDIO-002, R-STUDIO-003, R-STUDIO-010; source: 5.3 WorkspaceBinding, 7 Coding Agent 开发.
CREATE TABLE studio_workspaces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  repository_id TEXT NOT NULL REFERENCES studio_source_repositories(id),
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'ARCHIVED', 'ERROR')),
  current_revision INTEGER NOT NULL DEFAULT 0,
  current_revision_digest TEXT
);
CREATE INDEX idx_studio_workspaces_application ON studio_workspaces(studio_application_id);

-- s1_refs: R-STUDIO-002, R-STUDIO-005; source: 3.2 源码不保存到数据库字段.
CREATE TABLE studio_source_files (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  revision INTEGER NOT NULL,
  path TEXT NOT NULL,
  content_digest TEXT NOT NULL,
  size_bytes BIGINT NOT NULL CHECK (size_bytes >= 0),
  deleted BOOLEAN NOT NULL DEFAULT FALSE,
  protected BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (workspace_id, revision, path)
);
CREATE INDEX idx_studio_source_files_revision ON studio_source_files(workspace_id, revision, path);

-- s1_refs: R-STUDIO-002, R-STUDIO-003, R-STUDIO-004; source: 5 核心领域对象, 7 Coding Agent 开发.
CREATE TABLE studio_workspace_revisions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  revision INTEGER NOT NULL,
  content_digest TEXT NOT NULL,
  parent_revision INTEGER,
  created_by TEXT NOT NULL,
  change_set_id TEXT,
  UNIQUE (workspace_id, revision)
);

-- s1_refs: R-STUDIO-003, R-STUDIO-004, R-STUDIO-005; source: 7.1, 7.2, 7.4 Coding Agent.
CREATE TABLE studio_change_sets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  base_revision INTEGER NOT NULL,
  target_revision INTEGER,
  actor_id TEXT NOT NULL,
  agent_id TEXT,
  agent_session_id TEXT,
  agent_invocation_id TEXT,
  operations_json TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'APPLIED', 'REJECTED', 'FAILED')),
  failure_code TEXT,
  idempotency_key TEXT NOT NULL,
  UNIQUE (workspace_id, idempotency_key)
);

-- s1_refs: R-STUDIO-011, R-STUDIO-012; source: 10 Build, 5.4 WorkspaceSnapshot.
CREATE TABLE studio_source_snapshots (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  workspace_revision INTEGER NOT NULL,
  content_digest TEXT,
  manifest_digest TEXT,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'READY', 'FAILED')),
  failure_code TEXT,
  created_by TEXT NOT NULL
);
CREATE UNIQUE INDEX idx_studio_snapshots_digest ON studio_source_snapshots(studio_application_id, content_digest) WHERE content_digest IS NOT NULL;

-- s1_refs: R-STUDIO-011, R-STUDIO-012; source: 10 Build, 11 Release.
CREATE TABLE studio_application_versions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  source_snapshot_id TEXT NOT NULL REFERENCES studio_source_snapshots(id),
  version TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  published_at TIMESTAMPTZ,
  UNIQUE (studio_application_id, version)
);

-- s1_refs: R-STUDIO-004, R-STUDIO-009, R-STUDIO-010; source: 9 Preview.
CREATE TABLE studio_preview_runtimes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  workspace_revision INTEGER NOT NULL,
  infra_runtime_id TEXT,
  endpoint_ref TEXT,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'RUNNING', 'STOPPED', 'FAILED', 'EXPIRED')),
  diagnostics_summary_json TEXT NOT NULL DEFAULT '{}',
  expires_at TIMESTAMPTZ
);
CREATE INDEX idx_studio_preview_runtimes_workspace ON studio_preview_runtimes(workspace_id, workspace_revision, updated_at);

-- s1_refs: R-STUDIO-008, R-STUDIO-015; source: 18 Secret 与配置.
CREATE TABLE studio_runtime_configs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  studio_application_version_id TEXT NOT NULL REFERENCES studio_application_versions(id),
  environment TEXT NOT NULL CHECK (environment IN ('preview', 'production')),
  public_config_json TEXT NOT NULL DEFAULT '{}',
  secret_references_json TEXT NOT NULL DEFAULT '[]',
  integration_references_json TEXT NOT NULL DEFAULT '[]',
  validation_status TEXT NOT NULL CHECK (validation_status IN ('VALID', 'INVALID', 'UNAVAILABLE')),
  UNIQUE (studio_application_version_id, environment, resource_version)
);

-- s1_refs: R-STUDIO-011, R-STUDIO-013, R-STUDIO-018; source: 10 Build.
CREATE TABLE studio_builds (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  source_snapshot_id TEXT NOT NULL REFERENCES studio_source_snapshots(id),
  studio_application_version_id TEXT REFERENCES studio_application_versions(id),
  atomic_task_id TEXT,
  task_group_id TEXT,
  artifact_id TEXT,
  artifact_digest TEXT,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED', 'CANCELED')),
  diagnostics_summary_json TEXT NOT NULL DEFAULT '{}',
  idempotency_key TEXT NOT NULL,
  UNIQUE (studio_application_id, idempotency_key)
);
CREATE INDEX idx_studio_builds_status ON studio_builds(studio_application_id, status, created_at);

-- s1_refs: R-STUDIO-004, R-STUDIO-009, R-STUDIO-012; source: 11 Release, 12 发布与 Deployment.
CREATE TABLE studio_releases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  studio_application_version_id TEXT NOT NULL REFERENCES studio_application_versions(id),
  studio_build_id TEXT NOT NULL REFERENCES studio_builds(id),
  runtime_config_id TEXT NOT NULL REFERENCES studio_runtime_configs(id),
  artifact_id TEXT NOT NULL,
  artifact_digest TEXT NOT NULL,
  environment TEXT NOT NULL CHECK (environment IN ('preview', 'production')),
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'DEPLOYING', 'READY', 'FAILED', 'SUPERSEDED')),
  rollback_of_release_id TEXT,
  idempotency_key TEXT NOT NULL,
  UNIQUE (studio_application_id, idempotency_key)
);
CREATE INDEX idx_studio_releases_application_env ON studio_releases(studio_application_id, environment, created_at);

-- s1_refs: R-STUDIO-004, R-STUDIO-009, R-STUDIO-012; source: 12 发布与 Deployment.
CREATE TABLE studio_runtime_instances (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  studio_release_id TEXT NOT NULL REFERENCES studio_releases(id),
  infra_runtime_id TEXT,
  endpoint_ref TEXT,
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'DEGRADED', 'STOPPED', 'FAILED')),
  health_status TEXT NOT NULL CHECK (health_status IN ('UNKNOWN', 'HEALTHY', 'UNHEALTHY')),
  error_code TEXT,
  is_current BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_studio_runtime_instances_release ON studio_runtime_instances(studio_release_id, status);
CREATE UNIQUE INDEX idx_studio_runtime_current ON studio_runtime_instances(studio_application_id, studio_release_id) WHERE is_current = TRUE;

-- s1_refs: R-STUDIO-014; source: 21 事件.
CREATE TABLE appstudio_outbox (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  idempotency_key TEXT NOT NULL UNIQUE,
  delivery_status TEXT NOT NULL CHECK (delivery_status IN ('PENDING', 'DELIVERED', 'FAILED')),
  next_attempt_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ
);
CREATE INDEX idx_appstudio_outbox_delivery ON appstudio_outbox(delivery_status, next_attempt_at);
