-- Agent S2 design schema, v1.0.0-draft. This is not a migration.
-- 当前 Agent S1 未提供 US/BR 编号；表级追溯使用 R-AGENT-* 与源章节。

-- s1_refs: R-AGENT-001, R-AGENT-010, R-AGENT-017; source: 8.1 Agent, 23 权限模型.
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
  agent_profile_id TEXT NOT NULL,
  agent_profile_revision TEXT NOT NULL,
  workspace_type TEXT NOT NULL CHECK (workspace_type IN ('agent', 'studio')),
  workspace_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'READY', 'STARTING', 'RUNNING', 'IDLE', 'SUSPENDED', 'ERROR', 'DISABLED', 'DELETING')),
  disabled BOOLEAN NOT NULL DEFAULT FALSE,
  runtime_policy_json TEXT NOT NULL DEFAULT '{}',
  last_active_at TIMESTAMPTZ
);
CREATE INDEX idx_agents_owner_status ON agents(owner_user_id, status, created_at);
CREATE INDEX idx_agents_workspace ON agents(workspace_type, workspace_id);

-- s1_refs: R-AGENT-002, R-AGENT-017; source: 8.2 AgentSession, 12 消息与交互.
CREATE TABLE agent_sessions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  agent_id TEXT NOT NULL REFERENCES agents(id),
  owner_user_id TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('OPEN', 'CLOSED', 'ARCHIVED')),
  runtime_session_ref TEXT,
  last_message_at TIMESTAMPTZ
);
CREATE INDEX idx_agent_sessions_agent_status ON agent_sessions(agent_id, status, updated_at);

-- s1_refs: R-AGENT-002, R-AGENT-020; source: 8.3 AgentMessage, 12 消息与交互.
CREATE TABLE agent_messages (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  session_id TEXT NOT NULL REFERENCES agent_sessions(id),
  agent_id TEXT NOT NULL REFERENCES agents(id),
  invocation_id TEXT,
  role TEXT NOT NULL CHECK (role IN ('USER', 'ASSISTANT', 'SYSTEM', 'TOOL')),
  content TEXT NOT NULL,
  attachments_json TEXT NOT NULL DEFAULT '[]'
);
CREATE INDEX idx_agent_messages_session_created ON agent_messages(session_id, created_at);

-- s1_refs: R-AGENT-002, R-AGENT-014, R-AGENT-018; source: 8.4 AgentOperation, 21 Task Center 集成.
CREATE TABLE agent_invocations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  agent_id TEXT NOT NULL REFERENCES agents(id),
  session_id TEXT NOT NULL REFERENCES agent_sessions(id),
  type TEXT NOT NULL CHECK (type IN ('CHAT', 'CODING', 'TOOL_OPERATION', 'BACKGROUND_OPERATION')),
  status TEXT NOT NULL CHECK (status IN ('QUEUED', 'STARTING', 'RUNNING', 'WAITING_FOR_TOOL', 'WAITING_FOR_USER', 'SUCCEEDED', 'FAILED', 'CANCELING', 'CANCELED')),
  user_message_id TEXT,
  assistant_message_id TEXT,
  atomic_task_id TEXT,
  runtime_operation_ref TEXT,
  failure_code TEXT,
  failure_message TEXT NOT NULL DEFAULT '',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  idempotency_key TEXT NOT NULL
);
CREATE UNIQUE INDEX idx_agent_invocations_idempotency ON agent_invocations(agent_id, idempotency_key);
CREATE INDEX idx_agent_invocations_session_status ON agent_invocations(session_id, status, created_at);
CREATE INDEX idx_agent_invocations_task ON agent_invocations(atomic_task_id);

-- s1_refs: R-AGENT-002; source: 14 Memory.
CREATE TABLE agent_memories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  agent_id TEXT NOT NULL REFERENCES agents(id),
  session_id TEXT REFERENCES agent_sessions(id),
  scope TEXT NOT NULL CHECK (scope IN ('AGENT', 'SESSION')),
  type TEXT NOT NULL CHECK (type IN ('FACT', 'PREFERENCE', 'SUMMARY', 'INSTRUCTION', 'CONTEXT')),
  content TEXT NOT NULL,
  source_message_id TEXT,
  deleted_at TIMESTAMPTZ,
  CHECK ((scope = 'AGENT' AND session_id IS NULL) OR (scope = 'SESSION' AND session_id IS NOT NULL))
);
CREATE INDEX idx_agent_memories_scope ON agent_memories(agent_id, scope, updated_at);

-- s1_refs: R-AGENT-006, R-AGENT-007, R-AGENT-008; source: 8.6 AgentModelBinding, 24 Secret 与模型凭证.
CREATE TABLE agent_model_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  agent_id TEXT NOT NULL REFERENCES agents(id),
  source_type TEXT NOT NULL CHECK (source_type IN ('USER_DEFAULT_MODEL', 'USER_PROVIDER_MODEL', 'PLATFORM_MODEL')),
  source_ref TEXT NOT NULL,
  purpose TEXT NOT NULL CHECK (purpose IN ('CHAT', 'CODING', 'VISION', 'EMBEDDING')),
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INVALID', 'DISABLED')),
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (agent_id, purpose, name)
);

-- s1_refs: R-AGENT-010, R-AGENT-015, R-AGENT-016; source: 8.7 AgentWorkspaceBinding, 18 Workspace.
CREATE TABLE agent_workspace_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  agent_id TEXT NOT NULL REFERENCES agents(id),
  workspace_type TEXT NOT NULL CHECK (workspace_type IN ('agent', 'studio')),
  workspace_id TEXT NOT NULL,
  access_mode TEXT NOT NULL CHECK (access_mode IN ('READ_ONLY', 'READ_WRITE')),
  mount_path TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  authorization_ref TEXT,
  UNIQUE (agent_id, workspace_type, workspace_id)
);

-- s1_refs: R-AGENT-016; source: 15 Skills, 17 工具权限.
CREATE TABLE agent_skill_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  agent_id TEXT NOT NULL REFERENCES agents(id),
  skill_id TEXT NOT NULL,
  skill_version TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  configuration_json TEXT NOT NULL DEFAULT '{}',
  UNIQUE (agent_id, skill_id)
);

-- s1_refs: R-AGENT-016; source: 16 MCP Server Binding.
CREATE TABLE agent_mcp_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  agent_id TEXT NOT NULL REFERENCES agents(id),
  server_type TEXT NOT NULL CHECK (server_type IN ('PLATFORM', 'REMOTE', 'RUNTIME_LOCAL')),
  endpoint_ref TEXT NOT NULL,
  credential_ref TEXT,
  allowed_tools_json TEXT NOT NULL DEFAULT '[]',
  configuration_json TEXT NOT NULL DEFAULT '{}',
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);

-- s1_refs: R-AGENT-001, R-AGENT-003, R-AGENT-004, R-AGENT-018, R-AGENT-019; source: 8.8 AgentRuntimeBinding, 9 状态模型, 20 异常恢复.
CREATE TABLE agent_runtime_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  agent_id TEXT NOT NULL REFERENCES agents(id),
  infra_runtime_id TEXT,
  endpoint_ref TEXT,
  runtime_profile_id TEXT NOT NULL,
  runtime_profile_revision TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('CREATING', 'STARTING', 'READY', 'RUNNING', 'STOPPING', 'STOPPED', 'FAILED', 'DELETED')),
  activity_state TEXT NOT NULL CHECK (activity_state IN ('IDLE', 'ACTIVE', 'SUSPENDED')),
  health_status TEXT NOT NULL CHECK (health_status IN ('UNKNOWN', 'HEALTHY', 'UNHEALTHY')),
  last_health_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  stopped_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX idx_agent_runtime_current ON agent_runtime_bindings(agent_id) WHERE state NOT IN ('DELETED', 'STOPPED', 'FAILED');

-- s1_refs: R-AGENT-002, R-AGENT-014, R-AGENT-019; source: 28 事件.
CREATE TABLE agent_operation_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  invocation_id TEXT NOT NULL REFERENCES agent_invocations(id),
  event_type TEXT NOT NULL,
  sequence_no INTEGER NOT NULL,
  payload_json TEXT NOT NULL DEFAULT '{}',
  UNIQUE (invocation_id, sequence_no)
);

-- s1_refs: R-AGENT-014, R-AGENT-019; source: 21 Task Center 集成, 28 事件.
CREATE TABLE agent_outbox (
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
CREATE INDEX idx_agent_outbox_delivery ON agent_outbox(delivery_status, next_attempt_at);
