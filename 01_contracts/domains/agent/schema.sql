-- Agent S2 design schema. This file is a design contract, not a migration.
-- Product source: 00_product/domains/agent/product-spec.md

-- AgentRuntimeProvider is a system-registered resource. It contains no secret
-- value or raw infrastructure configuration.
-- s1_refs: US-AGENT-004, US-AGENT-008; BR-AGENT-007, BR-AGENT-008, BR-AGENT-012
CREATE TABLE agent_runtime_providers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  provider_type TEXT NOT NULL CHECK (provider_type IN ('docker', 'kubernetes')),
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'DEGRADED', 'UNAVAILABLE', 'DISABLED')),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  capabilities_json TEXT NOT NULL DEFAULT '{}',
  capacity_summary_json TEXT NOT NULL DEFAULT '{}',
  status_reason_code TEXT,
  last_health_check_at TIMESTAMPTZ,
  last_reconciled_at TIMESTAMPTZ,

  CONSTRAINT chk_agent_runtime_providers_version CHECK (resource_version >= 0)
);

CREATE UNIQUE INDEX uq_agent_runtime_provider_type
  ON agent_runtime_providers (provider_type);
CREATE UNIQUE INDEX uq_agent_runtime_provider_default
  ON agent_runtime_providers (is_default) WHERE is_default = TRUE;
CREATE INDEX idx_agent_runtime_providers_status
  ON agent_runtime_providers (status, enabled);

-- AgentWorkspace stores only Platform Agent workspace metadata. storage_ref is
-- private to the workspace module and MUST NOT appear in public API responses.
-- s1_refs: US-AGENT-005; BR-AGENT-002, BR-AGENT-003, BR-AGENT-014
CREATE TABLE agent_workspaces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  owner_type TEXT NOT NULL CHECK (owner_type IN ('agent', 'user', 'system')),
  owner_id TEXT NOT NULL,
  owner_user_id TEXT,
  created_by_type TEXT NOT NULL CHECK (created_by_type IN ('user', 'system')),
  created_by_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'MOUNTED', 'ERROR', 'DELETING', 'DELETED')),
  storage_type TEXT NOT NULL CHECK (storage_type IN ('local_directory', 'docker_volume', 'nfs', 'pvc')),
  storage_ref TEXT NOT NULL,
  size_bytes BIGINT NOT NULL DEFAULT 0 CHECK (size_bytes >= 0),
  quota_bytes BIGINT NOT NULL DEFAULT 0 CHECK (quota_bytes >= 0),
  current_snapshot_id TEXT,
  status_reason_code TEXT,
  deleted_at TIMESTAMPTZ,

  CONSTRAINT chk_agent_workspaces_version CHECK (resource_version >= 0),
  CONSTRAINT chk_agent_workspaces_owner CHECK (btrim(owner_id) <> ''),
  CONSTRAINT chk_agent_workspaces_deleted CHECK (
    (status = 'DELETED' AND deleted_at IS NOT NULL)
    OR status <> 'DELETED'
  )
);

CREATE INDEX idx_agent_workspaces_owner
  ON agent_workspaces (owner_type, owner_id, status);
CREATE INDEX idx_agent_workspaces_owner_user
  ON agent_workspaces (owner_user_id, created_at DESC);
CREATE INDEX idx_agent_workspaces_status
  ON agent_workspaces (status, updated_at);

-- s1_refs: US-AGENT-005; BR-AGENT-003
CREATE TABLE agent_workspace_snapshots (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  workspace_id TEXT NOT NULL REFERENCES agent_workspaces(id),
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'RESTORING', 'FAILED', 'DELETING', 'DELETED')),
  content_digest TEXT,
  size_bytes BIGINT NOT NULL DEFAULT 0 CHECK (size_bytes >= 0),
  storage_ref TEXT,
  created_by TEXT NOT NULL,
  error_code TEXT,
  completed_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,

  CONSTRAINT chk_agent_workspace_snapshots_version CHECK (resource_version >= 0),
  CONSTRAINT chk_agent_workspace_snapshot_ready CHECK (
    status <> 'READY' OR (content_digest IS NOT NULL AND storage_ref IS NOT NULL)
  )
);

CREATE INDEX idx_agent_workspace_snapshots_workspace
  ON agent_workspace_snapshots (workspace_id, created_at DESC);
CREATE INDEX idx_agent_workspace_snapshots_status
  ON agent_workspace_snapshots (status, updated_at);

-- workspace_id is polymorphic: workspace_type=agent resolves through
-- agent_workspaces; workspace_type=studio resolves only through AppStudio's
-- controlled projection. No cross-domain FK is allowed.
-- s1_refs: US-AGENT-001, US-AGENT-006; BR-AGENT-001, BR-AGENT-002, BR-AGENT-014
CREATE TABLE agents (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  owner_user_id TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('platform', 'coding')),
  provider TEXT NOT NULL CHECK (provider IN ('hermes', 'opencode')),
  workspace_type TEXT NOT NULL CHECK (workspace_type IN ('agent', 'studio')),
  workspace_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'STARTING', 'RUNNING', 'IDLE', 'SUSPENDED', 'ERROR', 'DISABLED', 'DELETING')),
  status_reason_code TEXT,
  disabled BOOLEAN NOT NULL DEFAULT FALSE,
  current_runtime_id TEXT,
  runtime_profile_id TEXT,
  preferred_runtime_provider_id TEXT REFERENCES agent_runtime_providers(id),
  provider_config_json TEXT NOT NULL DEFAULT '{}',
  system_prompt TEXT NOT NULL DEFAULT '',
  permission_profile_id TEXT,
  last_started_at TIMESTAMPTZ,
  last_active_at TIMESTAMPTZ,
  last_suspended_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,

  CONSTRAINT chk_agents_version CHECK (resource_version >= 0),
  CONSTRAINT chk_agents_workspace_kind CHECK (
    (kind = 'platform' AND workspace_type = 'agent')
    OR (kind = 'coding' AND workspace_type = 'studio')
  ),
  CONSTRAINT chk_agents_disabled_status CHECK (
    disabled = FALSE OR status IN ('DISABLED', 'DELETING')
  )
);

CREATE INDEX idx_agents_owner_created
  ON agents (owner_user_id, created_at DESC);
CREATE INDEX idx_agents_owner_status
  ON agents (owner_user_id, status, updated_at DESC);
CREATE INDEX idx_agents_workspace
  ON agents (workspace_type, workspace_id);
CREATE INDEX idx_agents_runtime_provider
  ON agents (preferred_runtime_provider_id);

-- s1_refs: US-AGENT-002, US-AGENT-007; BR-AGENT-004, BR-AGENT-006
CREATE TABLE agent_sessions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  agent_id TEXT NOT NULL REFERENCES agents(id),
  owner_user_id TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'ACTIVE', 'PROCESSING', 'IDLE', 'SUSPENDED', 'CLOSED', 'ERROR')),
  status_reason_code TEXT,
  provider_session_id TEXT,
  current_runtime_id TEXT,
  context_version INTEGER NOT NULL DEFAULT 0 CHECK (context_version >= 0),
  summary TEXT NOT NULL DEFAULT '',
  last_message_at TIMESTAMPTZ,
  last_invocation_at TIMESTAMPTZ,
  last_compacted_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,

  CONSTRAINT chk_agent_sessions_version CHECK (resource_version >= 0),
  CONSTRAINT chk_agent_sessions_closed CHECK (
    status <> 'CLOSED' OR closed_at IS NOT NULL
  )
);

CREATE INDEX idx_agent_sessions_agent
  ON agent_sessions (agent_id, updated_at DESC);
CREATE INDEX idx_agent_sessions_owner_status
  ON agent_sessions (owner_user_id, status, updated_at DESC);

-- atomic_task_id is a Task Center stable ID, not a cross-domain FK. Task
-- execution state is never copied into this table beyond Agent's projection.
-- s1_refs: US-AGENT-002, US-AGENT-003; BR-AGENT-004, BR-AGENT-005, BR-AGENT-010
CREATE TABLE agent_invocations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  agent_id TEXT NOT NULL REFERENCES agents(id),
  session_id TEXT NOT NULL REFERENCES agent_sessions(id),
  owner_user_id TEXT NOT NULL,
  runtime_id TEXT,
  atomic_task_id TEXT NOT NULL,
  sequence_no INTEGER NOT NULL CHECK (sequence_no > 0),
  parent_invocation_id TEXT REFERENCES agent_invocations(id),
  input_message_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('QUEUED', 'WAITING_RUNTIME', 'RESTORING_CONTEXT', 'RUNNING', 'WAITING_USER', 'SUCCEEDED', 'FAILED', 'CANCELED', 'TIMEOUT', 'LOST')),
  started_at TIMESTAMPTZ,
  heartbeat_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  output_summary TEXT NOT NULL DEFAULT '',
  result_json TEXT NOT NULL DEFAULT '{}',
  error_code TEXT,
  error_message TEXT,
  idempotency_key TEXT NOT NULL,

  CONSTRAINT chk_agent_invocations_version CHECK (resource_version >= 0),
  CONSTRAINT uq_agent_invocation_sequence UNIQUE (session_id, sequence_no),
  CONSTRAINT uq_agent_invocation_idempotency UNIQUE (owner_user_id, idempotency_key)
);

CREATE INDEX idx_agent_invocations_agent_status
  ON agent_invocations (agent_id, status, created_at DESC);
CREATE INDEX idx_agent_invocations_session
  ON agent_invocations (session_id, sequence_no DESC);
CREATE INDEX idx_agent_invocations_atomic_task
  ON agent_invocations (atomic_task_id);
CREATE UNIQUE INDEX uq_agent_active_write_invocation
  ON agent_invocations (agent_id)
  WHERE status IN ('QUEUED', 'WAITING_RUNTIME', 'RESTORING_CONTEXT', 'RUNNING');

-- Message content is a conversation fact. It MUST NOT contain raw Secret or
-- AppStudio source storage locations.
-- s1_refs: US-AGENT-002, US-AGENT-003, US-AGENT-007; BR-AGENT-006
CREATE TABLE agent_messages (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  session_id TEXT NOT NULL REFERENCES agent_sessions(id),
  invocation_id TEXT REFERENCES agent_invocations(id),
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system', 'tool')),
  message_type TEXT NOT NULL CHECK (message_type IN ('text', 'tool_call', 'tool_result', 'code_diff', 'artifact', 'approval_request', 'error', 'status')),
  content TEXT NOT NULL DEFAULT '',
  structured_content_json TEXT NOT NULL DEFAULT '{}',
  sequence_no INTEGER NOT NULL CHECK (sequence_no > 0),
  parent_message_id TEXT REFERENCES agent_messages(id),
  token_count INTEGER NOT NULL DEFAULT 0 CHECK (token_count >= 0),

  CONSTRAINT chk_agent_messages_version CHECK (resource_version >= 0),
  CONSTRAINT uq_agent_message_sequence UNIQUE (session_id, sequence_no)
);

CREATE INDEX idx_agent_messages_session
  ON agent_messages (session_id, sequence_no);
CREATE INDEX idx_agent_messages_invocation
  ON agent_messages (invocation_id, sequence_no);

-- scope_id is polymorphic within this domain and is validated by the memory
-- module according to scope_type.
-- s1_refs: US-AGENT-007; BR-AGENT-006
CREATE TABLE agent_memories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  owner_user_id TEXT NOT NULL,
  scope_type TEXT NOT NULL CHECK (scope_type IN ('session', 'agent')),
  scope_id TEXT NOT NULL,
  memory_type TEXT NOT NULL CHECK (memory_type IN ('user_preference', 'project_fact', 'architecture_decision', 'environment_fact', 'unresolved_issue', 'workflow_state', 'summary')),
  memory_key TEXT NOT NULL,
  content TEXT NOT NULL,
  structured_content_json TEXT NOT NULL DEFAULT '{}',
  source_session_id TEXT REFERENCES agent_sessions(id),
  source_invocation_id TEXT REFERENCES agent_invocations(id),
  source_message_ids_json TEXT NOT NULL DEFAULT '[]',
  confidence NUMERIC(5,4) NOT NULL DEFAULT 1 CHECK (confidence >= 0 AND confidence <= 1),
  memory_version INTEGER NOT NULL DEFAULT 1 CHECK (memory_version > 0),
  status TEXT NOT NULL CHECK (status IN ('active', 'superseded', 'deleted')),

  CONSTRAINT chk_agent_memories_version CHECK (resource_version >= 0),
  CONSTRAINT uq_agent_memory_version UNIQUE (scope_type, scope_id, memory_key, memory_version)
);

CREATE INDEX idx_agent_memories_scope
  ON agent_memories (scope_type, scope_id, status, updated_at DESC);
CREATE INDEX idx_agent_memories_source_session
  ON agent_memories (source_session_id);

-- AgentRuntime only runs Hermes/OpenCode. workspace_id is copied as a stable
-- runtime-generation snapshot and is resolved by workspace_type.
-- s1_refs: US-AGENT-004; BR-AGENT-005, BR-AGENT-007, BR-AGENT-008, BR-AGENT-012
CREATE TABLE agent_runtimes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  agent_id TEXT NOT NULL REFERENCES agents(id),
  owner_user_id TEXT NOT NULL,
  runtime_provider_id TEXT NOT NULL REFERENCES agent_runtime_providers(id),
  provider_runtime_id TEXT,
  agent_provider TEXT NOT NULL CHECK (agent_provider IN ('hermes', 'opencode')),
  state TEXT NOT NULL CHECK (state IN ('PENDING', 'CREATING', 'STARTING', 'RUNNING', 'SUSPENDING', 'SUSPENDED', 'STOPPING', 'FAILED', 'DELETING', 'DELETED')),
  activity_state TEXT NOT NULL CHECK (activity_state IN ('IDLE', 'BUSY', 'UNKNOWN')),
  workspace_type TEXT NOT NULL CHECK (workspace_type IN ('agent', 'studio')),
  workspace_id TEXT NOT NULL,
  image TEXT NOT NULL,
  image_digest TEXT NOT NULL,
  bootstrap_endpoint_ref TEXT,
  generation INTEGER NOT NULL DEFAULT 1 CHECK (generation > 0),
  idempotency_key TEXT NOT NULL,
  heartbeat_at TIMESTAMPTZ,
  ready_at TIMESTAMPTZ,
  idle_since TIMESTAMPTZ,
  stopped_at TIMESTAMPTZ,
  error_code TEXT,
  error_message TEXT,
  deleted_at TIMESTAMPTZ,

  CONSTRAINT chk_agent_runtimes_version CHECK (resource_version >= 0),
  CONSTRAINT uq_agent_runtime_generation UNIQUE (agent_id, generation),
  CONSTRAINT uq_agent_runtime_idempotency UNIQUE (runtime_provider_id, idempotency_key)
);

CREATE INDEX idx_agent_runtimes_agent
  ON agent_runtimes (agent_id, generation DESC);
CREATE INDEX idx_agent_runtimes_provider_state
  ON agent_runtimes (runtime_provider_id, state, updated_at);
CREATE INDEX idx_agent_runtimes_workspace
  ON agent_runtimes (workspace_type, workspace_id);
CREATE UNIQUE INDEX uq_agent_active_runtime
  ON agent_runtimes (agent_id)
  WHERE state IN ('PENDING', 'CREATING', 'STARTING', 'RUNNING', 'SUSPENDING', 'STOPPING', 'DELETING');

-- agents.current_runtime_id and agent_sessions.current_runtime_id intentionally
-- avoid circular FKs. They are validated against agent_runtimes by the Agent
-- module and cleared before runtime history is removed.

-- Reliable event outbox; payloads conform to events.yaml and exclude message
-- bodies, secrets, file paths, provider raw responses and Studio source.
-- s1_refs: US-AGENT-001, US-AGENT-002, US-AGENT-004, US-AGENT-005, US-AGENT-008; BR-AGENT-011, BR-AGENT-012
CREATE TABLE agent_outbox (
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

  CONSTRAINT chk_agent_outbox_version CHECK (resource_version >= 0)
);

CREATE INDEX idx_agent_outbox_delivery
  ON agent_outbox (delivery_status, next_attempt_at, created_at);
CREATE INDEX idx_agent_outbox_aggregate
  ON agent_outbox (aggregate_type, aggregate_id, aggregate_version);
