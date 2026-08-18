-- Model Deployment S2 design schema v1.0.0. This is not a migration.

-- s1_refs: US-MODELDEP-001, US-MODELDEP-002; BR-MODELDEP-001..010.
CREATE TABLE model_deployments (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  provider_type TEXT NOT NULL CHECK (provider_type IN ('vllm', 'lmstudio')),
  model_name TEXT NOT NULL CHECK (model_name ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$'),
  desired_state TEXT NOT NULL DEFAULT 'RUNNING' CHECK (desired_state IN ('RUNNING', 'STOPPED')),
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'DEPLOYING', 'RUNNING', 'STOPPING', 'STOPPED', 'RESTARTING', 'FAILED', 'DELETING')),
  health_status TEXT NOT NULL DEFAULT 'UNKNOWN' CHECK (health_status IN ('UNKNOWN', 'HEALTHY', 'UNHEALTHY')),
  infra_runtime_id TEXT,
  endpoint_ref TEXT,
  current_dag_task_group_id TEXT,
  current_atomic_task_id TEXT,
  current_action TEXT CHECK (current_action IS NULL OR current_action IN ('DEPLOY', 'START', 'STOP', 'RESTART', 'DELETE')),
  current_idempotency_key TEXT,
  failure_code TEXT NOT NULL DEFAULT '',
  failure_message TEXT NOT NULL DEFAULT '',
  last_health_check_at TIMESTAMPTZ,
  CHECK (status <> 'RUNNING' OR (infra_runtime_id IS NOT NULL AND endpoint_ref IS NOT NULL AND health_status = 'HEALTHY')),
  CHECK (NOT (current_dag_task_group_id IS NOT NULL AND current_atomic_task_id IS NOT NULL)),
  CHECK (((current_dag_task_group_id IS NULL AND current_atomic_task_id IS NULL)) = (current_action IS NULL)),
  CHECK (((current_dag_task_group_id IS NULL AND current_atomic_task_id IS NULL)) = (current_idempotency_key IS NULL))
);

CREATE UNIQUE INDEX idx_model_deployments_name ON model_deployments(name);
CREATE INDEX idx_model_deployments_provider_status ON model_deployments(provider_type, status, health_status);
CREATE INDEX idx_model_deployments_current_dag ON model_deployments(current_dag_task_group_id) WHERE current_dag_task_group_id IS NOT NULL;
CREATE INDEX idx_model_deployments_current_task ON model_deployments(current_atomic_task_id) WHERE current_atomic_task_id IS NOT NULL;
