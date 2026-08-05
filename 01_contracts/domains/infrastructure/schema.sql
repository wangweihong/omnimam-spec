-- Infrastructure S2 design schema, v1.1.0-draft based on spec-v1.12.0. This is not a migration.
-- Infra 只保存运行层事实；Agent、AppStudio、Task Center 和 Artifact 业务事实不在本 schema 内。

-- s1_refs: R-INFRA-003, R-INFRA-004, R-INFRA-005, R-INFRA-020, R-INFRA-021, R-INFRA-022; source: 7 RuntimeProfile, 10 Runtime Provider.
CREATE TABLE infra_runtime_profiles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  revision TEXT NOT NULL,
  runtime_mode TEXT NOT NULL CHECK (runtime_mode IN ('JOB', 'SERVICE')),
  provider_type TEXT NOT NULL CHECK (provider_type IN ('docker')),
  capabilities_json TEXT NOT NULL DEFAULT '[]',
  policy_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'DISABLED')),
  UNIQUE (id, revision)
);

-- s1_refs: R-INFRA-003, R-INFRA-011, R-INFRA-017, R-INFRA-018; source: 8.1 InfraNode, 11 节点与资源管理.
CREATE TABLE infra_nodes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  provider_type TEXT NOT NULL CHECK (provider_type IN ('docker')),
  status TEXT NOT NULL CHECK (status IN ('ONLINE', 'DRAINING', 'OFFLINE', 'DISABLED')),
  cpu_cores NUMERIC NOT NULL DEFAULT 0,
  memory_mb BIGINT NOT NULL DEFAULT 0,
  disk_mb BIGINT NOT NULL DEFAULT 0,
  gpu_count INTEGER NOT NULL DEFAULT 0,
  gpu_memory_mb BIGINT NOT NULL DEFAULT 0,
  last_heartbeat_at TIMESTAMPTZ
);
CREATE INDEX idx_infra_nodes_status ON infra_nodes(status, updated_at);

-- s1_refs: R-INFRA-001, R-INFRA-002, R-INFRA-006, R-INFRA-008, R-INFRA-015, R-INFRA-016, R-INFRA-017, R-INFRA-018; source: 8.2 InfraRuntime, 20 幂等性, 23 对账.
CREATE TABLE infra_runtimes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  runtime_mode TEXT NOT NULL CHECK (runtime_mode IN ('JOB', 'SERVICE')),
  status TEXT NOT NULL CHECK (status IN ('ACCEPTED', 'VALIDATING', 'SCHEDULING', 'PREPARING', 'RUNNING', 'SUCCEEDED', 'DEGRADED', 'STOPPING', 'STOPPED', 'FAILED', 'CANCELED', 'EXPIRED', 'DELETING', 'DELETED')),
  requesting_service TEXT NOT NULL CHECK (requesting_service = 'task-center'),
  owner_domain TEXT NOT NULL CHECK (owner_domain IN ('agent', 'appstudio', 'task-center', 'asset-library')),
  owner_reference TEXT NOT NULL,
  request_user_id TEXT,
  request_id TEXT NOT NULL,
  request_fingerprint TEXT NOT NULL,
  runtime_profile_id TEXT NOT NULL,
  runtime_profile_revision TEXT NOT NULL,
  provider_type TEXT NOT NULL CHECK (provider_type IN ('docker')),
  provider_runtime_ref TEXT,
  selected_node_id TEXT REFERENCES infra_nodes(id),
  endpoint_ref TEXT,
  source_ref TEXT,
  failure_code TEXT,
  timeout_policy_json TEXT NOT NULL DEFAULT '{}',
  UNIQUE (requesting_service, request_id)
);
CREATE INDEX idx_infra_runtimes_owner ON infra_runtimes(owner_domain, owner_reference, status);
CREATE INDEX idx_infra_runtimes_status ON infra_runtimes(status, updated_at);

-- s1_refs: R-INFRA-002, R-INFRA-008, R-INFRA-014, R-INFRA-021; source: 8.3 RuntimeEndpoint, 14 网络管理.
CREATE TABLE infra_runtime_endpoints (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  runtime_id TEXT NOT NULL REFERENCES infra_runtimes(id),
  endpoint_name TEXT NOT NULL,
  protocol TEXT NOT NULL CHECK (protocol IN ('http', 'https')),
  container_port INTEGER NOT NULL CHECK (container_port BETWEEN 1 AND 65535),
  published_host TEXT,
  published_port INTEGER CHECK (published_port BETWEEN 1 AND 65535),
  visibility TEXT NOT NULL CHECK (visibility IN ('INTERNAL', 'USER_ACCESSIBLE', 'PUBLIC')),
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'READY', 'EXPIRED', 'REVOKED')),
  display_ref TEXT,
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  CHECK (name = endpoint_name),
  CHECK (status <> 'READY' OR (published_host IS NOT NULL AND published_port IS NOT NULL)),
  UNIQUE (runtime_id, endpoint_name)
);
CREATE INDEX idx_infra_runtime_endpoints_runtime ON infra_runtime_endpoints(runtime_id, status);

-- s1_refs: R-INFRA-009, R-INFRA-010, R-INFRA-011; source: 12 Workspace 与文件挂载, 21.3 运行隔离.
CREATE TABLE infra_runtime_mounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  runtime_id TEXT NOT NULL REFERENCES infra_runtimes(id),
  source_ref TEXT NOT NULL,
  mount_kind TEXT NOT NULL CHECK (mount_kind IN ('AGENT_WORKSPACE', 'STUDIO_WORKSPACE_REVISION', 'STUDIO_SNAPSHOT', 'ARTIFACT', 'TEMPORARY')),
  target_path TEXT NOT NULL,
  read_only BOOLEAN NOT NULL,
  authorization_ref TEXT,
  UNIQUE (runtime_id, target_path)
);

-- s1_refs: R-INFRA-012, R-INFRA-013, R-INFRA-014; source: 13 配置和 Secret 注入.
CREATE TABLE infra_runtime_config_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  runtime_id TEXT NOT NULL REFERENCES infra_runtimes(id),
  binding_type TEXT NOT NULL CHECK (binding_type IN ('PLAIN_CONFIG', 'MODEL_ACCESS', 'SECRET_REF', 'INTEGRATION_REF')),
  reference TEXT NOT NULL,
  injection_status TEXT NOT NULL CHECK (injection_status IN ('PENDING', 'RESOLVED', 'FAILED')),
  failure_code TEXT
);

-- s1_refs: R-INFRA-002, R-INFRA-008, R-INFRA-022; source: 8.6 RuntimeOutput, 12.3 输出目录.
CREATE TABLE infra_runtime_outputs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  runtime_id TEXT NOT NULL REFERENCES infra_runtimes(id),
  output_key TEXT NOT NULL,
  declared_relative_path TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'COLLECTED', 'FAILED')),
  artifact_id TEXT,
  media_type TEXT,
  size_bytes BIGINT CHECK (size_bytes >= 0),
  content_digest TEXT CHECK (content_digest ~ '^sha256:[0-9a-f]{64}$'),
  content_ref TEXT UNIQUE,
  staging_ref TEXT,
  collected_at TIMESTAMPTZ,
  artifact_attached_at TIMESTAMPTZ,
  failure_code TEXT,
  CHECK (declared_relative_path !~ '^/' AND declared_relative_path !~ '(^|/)\.\.(/|$)'),
  CHECK (content_ref IS NULL OR content_ref = 'infra-output://' || id),
  CHECK (
    status <> 'COLLECTED'
    OR (
      size_bytes IS NOT NULL
      AND content_digest IS NOT NULL
      AND content_ref IS NOT NULL
      AND collected_at IS NOT NULL
      AND (staging_ref IS NOT NULL OR artifact_id IS NOT NULL)
    )
  ),
  CHECK (
    (artifact_id IS NULL AND artifact_attached_at IS NULL)
    OR (artifact_id IS NOT NULL AND status = 'COLLECTED' AND artifact_attached_at IS NOT NULL)
  ),
  UNIQUE (runtime_id, output_key)
);

-- s1_refs: R-INFRA-017, R-INFRA-018; source: 8.7 RuntimeEvent, 23 对账与故障恢复.
CREATE TABLE infra_runtime_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  runtime_id TEXT NOT NULL REFERENCES infra_runtimes(id),
  event_type TEXT NOT NULL,
  provider_sequence TEXT,
  provider_status TEXT,
  safe_summary_json TEXT NOT NULL DEFAULT '{}',
  idempotency_key TEXT NOT NULL UNIQUE
);
CREATE INDEX idx_infra_runtime_events_runtime ON infra_runtime_events(runtime_id, created_at);
