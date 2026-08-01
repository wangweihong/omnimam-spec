-- AppStudio S2 design schema. This file is a design contract, not a migration.
-- Product source: 00_product/domains/appstudio/product-spec.md

-- StudioApplication is independent from application-platform.Application.
-- s1_refs: US-APPSTUDIO-001; BR-APPSTUDIO-001, BR-APPSTUDIO-002
CREATE TABLE studio_applications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  owner_user_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'ERROR', 'ARCHIVED')),
  status_reason_code TEXT,
  technology_profile TEXT NOT NULL DEFAULT 'typescript_light_bff',
  runtime_profile TEXT NOT NULL DEFAULT 'web_light_bff',
  source_repository_id TEXT,
  default_workspace_id TEXT,
  current_production_release_id TEXT,
  current_preview_release_id TEXT,
  archived_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_applications_version CHECK (resource_version >= 0),
  CONSTRAINT chk_studio_applications_archived CHECK (
    status <> 'ARCHIVED' OR archived_at IS NOT NULL
  )
);

CREATE INDEX idx_studio_applications_owner
  ON studio_applications (owner_user_id, created_at DESC);
CREATE INDEX idx_studio_applications_owner_status
  ON studio_applications (owner_user_id, status, updated_at DESC);

-- storage_ref is a Source Service private locator and MUST NOT appear in API,
-- events, logs or cross-domain calls.
-- s1_refs: US-APPSTUDIO-001; BR-APPSTUDIO-002
CREATE TABLE studio_source_repositories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  provider TEXT NOT NULL CHECK (provider IN ('built_in')),
  storage_ref TEXT NOT NULL,
  default_workspace_id TEXT,
  current_revision INTEGER NOT NULL DEFAULT 0 CHECK (current_revision >= 0),
  status TEXT NOT NULL CHECK (status IN ('INITIALIZING', 'READY', 'ERROR', 'ARCHIVED')),
  status_reason_code TEXT,

  CONSTRAINT chk_studio_source_repositories_version CHECK (resource_version >= 0),
  CONSTRAINT uq_studio_source_repository_application UNIQUE (studio_application_id)
);

CREATE INDEX idx_studio_source_repositories_status
  ON studio_source_repositories (status, updated_at);

-- s1_refs: US-APPSTUDIO-001, US-APPSTUDIO-002, US-APPSTUDIO-003; BR-APPSTUDIO-002, BR-APPSTUDIO-003, BR-APPSTUDIO-004
CREATE TABLE studio_workspaces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  source_repository_id TEXT NOT NULL REFERENCES studio_source_repositories(id),
  base_snapshot_id TEXT,
  current_revision INTEGER NOT NULL DEFAULT 0 CHECK (current_revision >= 0),
  preview_runtime_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('initializing', 'ready', 'modifying', 'previewing', 'conflicted', 'locked', 'archived')),
  status_reason_code TEXT,
  locked_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_workspaces_version CHECK (resource_version >= 0),
  CONSTRAINT chk_studio_workspaces_archive CHECK (
    status <> 'archived' OR archived_at IS NOT NULL
  )
);

CREATE INDEX idx_studio_workspaces_application
  ON studio_workspaces (studio_application_id, created_at DESC);
CREATE INDEX idx_studio_workspaces_repository
  ON studio_workspaces (source_repository_id, status);

-- File index only; source content is never stored in this business table.
-- s1_refs: US-APPSTUDIO-002, US-APPSTUDIO-003; BR-APPSTUDIO-002, BR-APPSTUDIO-003, BR-APPSTUDIO-004
CREATE TABLE studio_source_files (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  path TEXT NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN ('file', 'directory')),
  content_digest TEXT,
  size_bytes BIGINT NOT NULL DEFAULT 0 CHECK (size_bytes >= 0),
  indexed_revision INTEGER NOT NULL CHECK (indexed_revision >= 0),
  protected BOOLEAN NOT NULL DEFAULT FALSE,
  deleted BOOLEAN NOT NULL DEFAULT FALSE,

  CONSTRAINT chk_studio_source_files_version CHECK (resource_version >= 0),
  CONSTRAINT chk_studio_source_files_path CHECK (path <> '' AND path NOT LIKE '/%' AND path NOT LIKE '%..%'),
  CONSTRAINT uq_studio_source_file_path UNIQUE (workspace_id, path)
);

CREATE INDEX idx_studio_source_files_workspace_revision
  ON studio_source_files (workspace_id, indexed_revision, path);
CREATE INDEX idx_studio_source_files_digest
  ON studio_source_files (content_digest);

-- Revision records immutable edit history metadata. source_tree_ref is private
-- to Source Service and does not expose a storage backend URI.
-- s1_refs: US-APPSTUDIO-003; BR-APPSTUDIO-004
CREATE TABLE studio_workspace_revisions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  revision INTEGER NOT NULL CHECK (revision > 0),
  parent_revision INTEGER,
  source_revision INTEGER,
  change_set_id TEXT,
  source_tree_digest TEXT NOT NULL,
  source_tree_ref TEXT NOT NULL,
  created_by TEXT NOT NULL,
  revision_reason TEXT NOT NULL CHECK (revision_reason IN ('initialize', 'change_set', 'restore')),

  CONSTRAINT chk_studio_workspace_revisions_version CHECK (resource_version >= 0),
  CONSTRAINT uq_studio_workspace_revision UNIQUE (workspace_id, revision)
);

CREATE INDEX idx_studio_workspace_revisions_workspace
  ON studio_workspace_revisions (workspace_id, revision DESC);

-- Agent IDs are cross-domain stable references and intentionally have no FK.
-- change_manifest_json contains paths/operations/digests and failure summaries,
-- not unrestricted source storage locations or Secret values.
-- s1_refs: US-APPSTUDIO-003; BR-APPSTUDIO-003, BR-APPSTUDIO-004, BR-APPSTUDIO-013
CREATE TABLE studio_change_sets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  owner_user_id TEXT NOT NULL,
  agent_id TEXT,
  agent_session_id TEXT,
  agent_invocation_id TEXT,
  base_revision INTEGER NOT NULL CHECK (base_revision >= 0),
  target_revision INTEGER,
  files_added INTEGER NOT NULL DEFAULT 0 CHECK (files_added >= 0),
  files_modified INTEGER NOT NULL DEFAULT 0 CHECK (files_modified >= 0),
  files_deleted INTEGER NOT NULL DEFAULT 0 CHECK (files_deleted >= 0),
  change_manifest_json TEXT NOT NULL DEFAULT '[]',
  summary TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('validating', 'applied', 'rejected', 'conflict', 'failed')),
  failure_code TEXT,
  idempotency_key TEXT NOT NULL,
  completed_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_change_sets_version CHECK (resource_version >= 0),
  CONSTRAINT chk_studio_change_set_target CHECK (
    (status = 'applied' AND target_revision IS NOT NULL AND target_revision > base_revision)
    OR (status <> 'applied' AND target_revision IS NULL)
  ),
  CONSTRAINT uq_studio_change_set_idempotency UNIQUE (workspace_id, idempotency_key)
);

CREATE INDEX idx_studio_change_sets_workspace
  ON studio_change_sets (workspace_id, created_at DESC);
CREATE INDEX idx_studio_change_sets_invocation
  ON studio_change_sets (agent_invocation_id, created_at DESC);
CREATE INDEX idx_studio_change_sets_status
  ON studio_change_sets (status, updated_at);

-- Snapshot content is immutable. storage_ref is private to Source Service.
-- s1_refs: US-APPSTUDIO-004, US-APPSTUDIO-005; BR-APPSTUDIO-005, BR-APPSTUDIO-006
CREATE TABLE studio_source_snapshots (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  workspace_revision INTEGER NOT NULL CHECK (workspace_revision > 0),
  status TEXT NOT NULL CHECK (status IN ('creating', 'ready', 'failed')),
  content_digest TEXT,
  storage_ref TEXT,
  manifest_digest TEXT,
  size_bytes BIGINT NOT NULL DEFAULT 0 CHECK (size_bytes >= 0),
  created_by TEXT NOT NULL,
  error_code TEXT,
  completed_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_source_snapshots_version CHECK (resource_version >= 0),
  CONSTRAINT chk_studio_source_snapshot_ready CHECK (
    status <> 'ready'
    OR (content_digest IS NOT NULL AND storage_ref IS NOT NULL AND manifest_digest IS NOT NULL)
  ),
  CONSTRAINT uq_studio_source_snapshot_digest UNIQUE (studio_application_id, content_digest)
);

CREATE INDEX idx_studio_source_snapshots_workspace
  ON studio_source_snapshots (workspace_id, workspace_revision DESC);
CREATE INDEX idx_studio_source_snapshots_application
  ON studio_source_snapshots (studio_application_id, created_at DESC);

-- s1_refs: US-APPSTUDIO-004; BR-APPSTUDIO-005, BR-APPSTUDIO-006
CREATE TABLE studio_application_versions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  version TEXT NOT NULL,
  source_snapshot_id TEXT NOT NULL REFERENCES studio_source_snapshots(id),
  blueprint_revision_id TEXT,
  runtime_profile TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'ready', 'archived')),

  CONSTRAINT chk_studio_application_versions_version CHECK (resource_version >= 0),
  CONSTRAINT uq_studio_application_version UNIQUE (studio_application_id, version)
);

CREATE INDEX idx_studio_application_versions_snapshot
  ON studio_application_versions (source_snapshot_id);

-- Preview endpoint_ref and process_ref are private infrastructure references.
-- Public API returns only a controlled endpoint summary.
-- s1_refs: US-APPSTUDIO-006; BR-APPSTUDIO-003, BR-APPSTUDIO-009
CREATE TABLE studio_preview_runtimes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  workspace_id TEXT NOT NULL REFERENCES studio_workspaces(id),
  workspace_revision INTEGER NOT NULL CHECK (workspace_revision > 0),
  status TEXT NOT NULL CHECK (status IN ('starting', 'running', 'refreshing', 'failed', 'stopped', 'expired')),
  endpoint_ref TEXT,
  endpoint_summary_json TEXT NOT NULL DEFAULT '{}',
  process_ref TEXT,
  diagnostics_summary_json TEXT NOT NULL DEFAULT '{}',
  last_active_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  error_code TEXT,
  stopped_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_preview_runtimes_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_studio_preview_runtimes_workspace
  ON studio_preview_runtimes (workspace_id, created_at DESC);
CREATE INDEX idx_studio_preview_runtimes_expiry
  ON studio_preview_runtimes (expires_at) WHERE status IN ('starting', 'running', 'refreshing');

-- task_group_id/atomic_task_id and artifact_id are cross-domain stable IDs;
-- there are no cross-domain FKs. Artifact storage and task state are not copied.
-- s1_refs: US-APPSTUDIO-005, US-APPSTUDIO-007; BR-APPSTUDIO-005, BR-APPSTUDIO-007, BR-APPSTUDIO-008, BR-APPSTUDIO-013
CREATE TABLE studio_builds (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  owner_user_id TEXT NOT NULL,
  studio_application_version_id TEXT REFERENCES studio_application_versions(id),
  source_snapshot_id TEXT NOT NULL REFERENCES studio_source_snapshots(id),
  task_group_id TEXT,
  atomic_task_id TEXT,
  build_profile TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'validating', 'building', 'packaging', 'succeeded', 'failed', 'cancelled')),
  artifact_id TEXT,
  artifact_digest TEXT,
  artifact_size_snapshot BIGINT CHECK (artifact_size_snapshot >= 0),
  artifact_created_at_snapshot TIMESTAMPTZ,
  diagnostics_summary_json TEXT NOT NULL DEFAULT '{}',
  producer_idempotency_key TEXT NOT NULL,
  request_idempotency_key TEXT NOT NULL,
  error_code TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_builds_version CHECK (resource_version >= 0),
  CONSTRAINT chk_studio_build_artifact CHECK (
    status <> 'succeeded'
    OR (artifact_id IS NOT NULL AND artifact_digest IS NOT NULL)
  ),
  CONSTRAINT uq_studio_build_request UNIQUE (owner_user_id, request_idempotency_key),
  CONSTRAINT uq_studio_build_producer UNIQUE (producer_idempotency_key)
);

CREATE INDEX idx_studio_builds_application
  ON studio_builds (studio_application_id, created_at DESC);
CREATE INDEX idx_studio_builds_snapshot
  ON studio_builds (source_snapshot_id, created_at DESC);
CREATE INDEX idx_studio_builds_task_group
  ON studio_builds (task_group_id);
CREATE INDEX idx_studio_builds_artifact
  ON studio_builds (artifact_id);
CREATE INDEX idx_studio_builds_status
  ON studio_builds (owner_user_id, status, updated_at DESC);

-- Config stores reference identifiers only. Resolved Secret values are never
-- written to this table, API responses, events or logs.
-- s1_refs: US-APPSTUDIO-009; BR-APPSTUDIO-010, BR-APPSTUDIO-011
CREATE TABLE studio_runtime_configs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  studio_application_version_id TEXT NOT NULL REFERENCES studio_application_versions(id),
  environment TEXT NOT NULL CHECK (environment IN ('preview', 'production')),
  public_config_json TEXT NOT NULL DEFAULT '{}',
  secret_references_json TEXT NOT NULL DEFAULT '[]',
  integration_references_json TEXT NOT NULL DEFAULT '[]',
  resource_profile TEXT NOT NULL,
  validated_at TIMESTAMPTZ,
  validation_status TEXT NOT NULL CHECK (validation_status IN ('pending', 'valid', 'invalid')),
  validation_error_code TEXT,

  CONSTRAINT chk_studio_runtime_configs_version CHECK (resource_version >= 0),
  CONSTRAINT uq_studio_runtime_config UNIQUE (studio_application_version_id, environment)
);

CREATE INDEX idx_studio_runtime_configs_application
  ON studio_runtime_configs (studio_application_id, environment, updated_at DESC);

-- System-registered deployment component. config/credential values are not in
-- this business table.
-- s1_refs: US-APPSTUDIO-007, US-APPSTUDIO-008; BR-APPSTUDIO-009, BR-APPSTUDIO-011, BR-APPSTUDIO-012
CREATE TABLE studio_deployment_providers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  provider_type TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'DEGRADED', 'UNAVAILABLE', 'DISABLED')),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  capabilities_json TEXT NOT NULL DEFAULT '{}',
  status_reason_code TEXT,
  last_health_check_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_deployment_providers_version CHECK (resource_version >= 0),
  CONSTRAINT uq_studio_deployment_provider_name UNIQUE (name)
);

CREATE INDEX idx_studio_deployment_providers_status
  ON studio_deployment_providers (status, enabled);

-- artifact_id is owned by asset-library. deployment_task_id is owned by Task
-- Center. rollback_of_release_id is an immutable lineage reference.
-- s1_refs: US-APPSTUDIO-007, US-APPSTUDIO-008; BR-APPSTUDIO-008, BR-APPSTUDIO-009, BR-APPSTUDIO-010, BR-APPSTUDIO-011, BR-APPSTUDIO-012
CREATE TABLE studio_releases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  owner_user_id TEXT NOT NULL,
  studio_application_version_id TEXT NOT NULL REFERENCES studio_application_versions(id),
  studio_build_id TEXT NOT NULL REFERENCES studio_builds(id),
  runtime_config_id TEXT NOT NULL REFERENCES studio_runtime_configs(id),
  artifact_id TEXT NOT NULL,
  artifact_digest TEXT NOT NULL,
  environment TEXT NOT NULL CHECK (environment IN ('preview', 'production')),
  deployment_provider_id TEXT NOT NULL REFERENCES studio_deployment_providers(id),
  deployment_task_id TEXT,
  studio_runtime_instance_id TEXT,
  rollback_of_release_id TEXT REFERENCES studio_releases(id),
  hostname TEXT,
  endpoint_summary_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('pending', 'deploying', 'ready', 'failed', 'superseded')),
  error_code TEXT,
  request_idempotency_key TEXT NOT NULL,
  released_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_releases_version CHECK (resource_version >= 0),
  CONSTRAINT chk_studio_release_ready CHECK (
    status <> 'ready'
    OR (studio_runtime_instance_id IS NOT NULL AND released_at IS NOT NULL)
  ),
  CONSTRAINT uq_studio_release_request UNIQUE (owner_user_id, request_idempotency_key)
);

CREATE INDEX idx_studio_releases_application_env
  ON studio_releases (studio_application_id, environment, created_at DESC);
CREATE INDEX idx_studio_releases_build
  ON studio_releases (studio_build_id);
CREATE INDEX idx_studio_releases_artifact
  ON studio_releases (artifact_id, artifact_digest);
CREATE INDEX idx_studio_releases_status
  ON studio_releases (status, updated_at);

-- provider_runtime_id and endpoint_ref are private provider references. Public
-- API exposes only endpoint_summary_json after visibility filtering.
-- s1_refs: US-APPSTUDIO-007, US-APPSTUDIO-008; BR-APPSTUDIO-009, BR-APPSTUDIO-011, BR-APPSTUDIO-012
CREATE TABLE studio_runtime_instances (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  studio_application_id TEXT NOT NULL REFERENCES studio_applications(id),
  studio_release_id TEXT NOT NULL REFERENCES studio_releases(id),
  artifact_id TEXT NOT NULL,
  artifact_digest TEXT NOT NULL,
  deployment_provider_id TEXT NOT NULL REFERENCES studio_deployment_providers(id),
  provider_runtime_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'STARTING', 'READY', 'UNHEALTHY', 'STOPPING', 'STOPPED', 'FAILED')),
  health_status TEXT NOT NULL CHECK (health_status IN ('unknown', 'checking', 'healthy', 'unhealthy')),
  endpoint_ref TEXT,
  endpoint_summary_json TEXT NOT NULL DEFAULT '{}',
  error_code TEXT,
  heartbeat_at TIMESTAMPTZ,
  ready_at TIMESTAMPTZ,
  stopped_at TIMESTAMPTZ,

  CONSTRAINT chk_studio_runtime_instances_version CHECK (resource_version >= 0),
  CONSTRAINT chk_studio_runtime_ready CHECK (
    status <> 'READY'
    OR (health_status = 'healthy' AND endpoint_ref IS NOT NULL AND ready_at IS NOT NULL)
  )
);

CREATE INDEX idx_studio_runtime_instances_release
  ON studio_runtime_instances (studio_release_id, created_at DESC);
CREATE INDEX idx_studio_runtime_instances_provider
  ON studio_runtime_instances (deployment_provider_id, status, updated_at);
CREATE INDEX idx_studio_runtime_instances_application
  ON studio_runtime_instances (studio_application_id, status, created_at DESC);

-- Circular current pointers in studio_applications, studio_workspaces and
-- studio_releases intentionally omit FKs. AppStudio validates them within one
-- aggregate transaction and never points them at a different application.

-- Reliable event outbox; payloads conform to events.yaml and exclude source
-- content, storage refs, Secret values and provider private configuration.
-- s1_refs: US-APPSTUDIO-001, US-APPSTUDIO-003, US-APPSTUDIO-004, US-APPSTUDIO-005, US-APPSTUDIO-006, US-APPSTUDIO-007, US-APPSTUDIO-008; BR-APPSTUDIO-014
CREATE TABLE appstudio_outbox (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  aggregate_version INTEGER NOT NULL CHECK (aggregate_version >= 0),
  event_name TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  idempotency_key TEXT NOT NULL UNIQUE,
  delivery_status TEXT NOT NULL CHECK (delivery_status IN ('pending', 'delivering', 'delivered', 'failed')),
  delivery_attempts INTEGER NOT NULL DEFAULT 0 CHECK (delivery_attempts >= 0),
  next_attempt_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,

  CONSTRAINT chk_appstudio_outbox_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_appstudio_outbox_delivery
  ON appstudio_outbox (delivery_status, next_attempt_at, created_at);
CREATE INDEX idx_appstudio_outbox_aggregate
  ON appstudio_outbox (aggregate_type, aggregate_id, aggregate_version);
