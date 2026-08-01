-- OmniMAM MCP design schema.
-- This file is a design contract, not a migration.

-- McpTaskBinding is the only MCP-owned durable resource in v1.
-- It maps an MCP Task to an already-persisted ApplicationRun/AtomicTask and
-- never copies source-domain execution state.
-- s1_refs: US-MCP-003, US-MCP-004; BR-MCP-009, BR-MCP-010, BR-MCP-011, BR-MCP-012, BR-MCP-013, BR-MCP-017
CREATE TABLE mcp_task_bindings (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,

  mcp_task_id TEXT NOT NULL UNIQUE,
  principal_id TEXT NOT NULL,
  client_name TEXT NOT NULL DEFAULT '',
  application_run_id TEXT NOT NULL,
  atomic_task_id TEXT NOT NULL,
  extension_id TEXT NOT NULL DEFAULT 'io.modelcontextprotocol/tasks',
  expires_at TIMESTAMPTZ NOT NULL,
  last_accessed_at TIMESTAMPTZ NOT NULL,

  CONSTRAINT chk_mcp_task_binding_resource_version
    CHECK (resource_version >= 0),
  CONSTRAINT chk_mcp_task_binding_ids
    CHECK (
      btrim(mcp_task_id) <> ''
      AND btrim(principal_id) <> ''
      AND btrim(application_run_id) <> ''
      AND btrim(atomic_task_id) <> ''
    ),
  CONSTRAINT chk_mcp_task_binding_extension
    CHECK (extension_id = 'io.modelcontextprotocol/tasks'),
  CONSTRAINT chk_mcp_task_binding_expiry
    CHECK (expires_at > created_at),
  CONSTRAINT uq_mcp_task_binding_principal_run
    UNIQUE (principal_id, application_run_id)
);

CREATE INDEX idx_mcp_task_bindings_expiry
  ON mcp_task_bindings (expires_at);

CREATE INDEX idx_mcp_task_bindings_principal_access
  ON mcp_task_bindings (principal_id, last_accessed_at DESC);

CREATE INDEX idx_mcp_task_bindings_atomic_task
  ON mcp_task_bindings (atomic_task_id);

-- application_run_id, atomic_task_id and principal_id are cross-domain stable
-- identifiers. This schema intentionally defines no cross-domain foreign keys:
-- MCP resolves and authorizes them through controlled module contracts.
--
-- Expired rows are physically deleted. There is no soft-delete field because a
-- binding is a short-lived protocol mapping, not a business history resource.
-- Deleting a binding MUST NOT delete or mutate ApplicationRun, AtomicTask,
-- Artifact, Asset, Identity session or audit facts.
--
-- MCP request audit records are written through the Identity audit boundary and
-- are not duplicated in an MCP-owned table.
