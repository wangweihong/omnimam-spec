-- Model Deployment S2 design schema v2.0.0. This is not a migration.
-- spec-v1.25.1 intentionally does not migrate spec-v1.24.x data.

-- s1_refs: US-MODELDEP-001..004; BR-MODELDEP-001..020.
CREATE TABLE model_deployments (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  active_spec_revision_id TEXT,
  pending_spec_revision_id TEXT,
  current_rollout_id TEXT,
  desired_state TEXT NOT NULL DEFAULT 'RUNNING' CHECK (desired_state IN ('RUNNING', 'STOPPED')),
  status TEXT NOT NULL CHECK (status IN ('CREATING', 'DEPLOYING', 'APPLYING', 'RUNNING', 'STOPPING', 'STOPPED', 'RESTARTING', 'ROLLING_BACK', 'FAILED', 'DELETING')),
  health_status TEXT NOT NULL DEFAULT 'UNKNOWN' CHECK (health_status IN ('UNKNOWN', 'HEALTHY', 'UNHEALTHY')),
  infra_runtime_id TEXT,
  endpoint_ref TEXT,
  current_atomic_task_id TEXT,
  current_action TEXT CHECK (current_action IS NULL OR current_action IN ('STOP', 'DELETE')),
  current_idempotency_key TEXT,
  failure_code TEXT NOT NULL DEFAULT '',
  failure_message TEXT NOT NULL DEFAULT '',
  CHECK (status <> 'RUNNING' OR (active_spec_revision_id IS NOT NULL AND infra_runtime_id IS NOT NULL AND endpoint_ref IS NOT NULL AND health_status = 'HEALTHY')),
  CHECK (NOT (current_rollout_id IS NOT NULL AND current_atomic_task_id IS NOT NULL)),
  CHECK ((current_atomic_task_id IS NULL) = (current_action IS NULL)),
  CHECK ((current_atomic_task_id IS NULL) = (current_idempotency_key IS NULL))
);

-- Immutable expected configuration SSOT. UPDATE and DELETE are forbidden by module policy.
CREATE TABLE model_deployment_spec_revisions (
  id TEXT PRIMARY KEY,
  model_deployment_id TEXT NOT NULL REFERENCES model_deployments(id) ON DELETE CASCADE,
  revision_no INTEGER NOT NULL CHECK (revision_no >= 1),
  configuration_mode TEXT NOT NULL CHECK (configuration_mode IN ('ENGINE_MANAGED', 'PROVIDER_NATIVE')),
  serving_engine TEXT NOT NULL CHECK (serving_engine IN ('vllm', 'lmstudio')),
  runtime_provider TEXT NOT NULL CHECK (runtime_provider IN ('docker')),
  model_source_json JSONB NOT NULL,
  serving_spec_json JSONB NOT NULL,
  runtime_spec_json JSONB NOT NULL,
  runtime_profile_revision_id TEXT,
  spec_digest TEXT NOT NULL CHECK (spec_digest ~ '^sha256:[0-9a-f]{64}$'),
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  UNIQUE (model_deployment_id, revision_no),
  UNIQUE (model_deployment_id, spec_digest),
  CHECK (NOT (model_source_json ? 'engine') AND NOT (model_source_json ? 'provider')),
  CHECK (NOT (serving_spec_json ? 'engine') AND NOT (serving_spec_json ? 'provider')),
  CHECK (NOT (runtime_spec_json ? 'engine') AND NOT (runtime_spec_json ? 'provider')),
  CHECK (
    (configuration_mode = 'ENGINE_MANAGED' AND runtime_spec_json ->> 'mode' = 'STRUCTURED' AND serving_spec_json ->> 'mode' IN ('STRUCTURED', 'ARGUMENTS'))
    OR
    (configuration_mode = 'PROVIDER_NATIVE' AND runtime_spec_json ->> 'mode' = 'NATIVE' AND serving_spec_json ->> 'mode' = 'METADATA_ONLY')
  )
);

-- s1_refs: US-MODELDEP-002..004; BR-MODELDEP-009..017.
CREATE TABLE model_deployment_rollouts (
  id TEXT PRIMARY KEY,
  model_deployment_id TEXT NOT NULL REFERENCES model_deployments(id) ON DELETE CASCADE,
  spec_revision_id TEXT NOT NULL REFERENCES model_deployment_spec_revisions(id),
  kind TEXT NOT NULL CHECK (kind IN ('INITIAL', 'APPLY', 'MANUAL_ROLLBACK', 'START', 'RESTART', 'AUTO_ROLLBACK')),
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED', 'CANCELED')),
  phase TEXT NOT NULL CHECK (phase IN ('PENDING', 'VALIDATING', 'CREATING_RUNTIME', 'WAITING_RUNTIME', 'WAITING_ENDPOINT', 'HEALTH_CHECKING', 'SWITCHING_ACTIVE', 'CLEANING_PREVIOUS_RUNTIME', 'ROLLING_BACK', 'COMPLETED')),
  previous_active_spec_revision_id TEXT REFERENCES model_deployment_spec_revisions(id),
  previous_infra_runtime_id TEXT,
  dag_task_group_id TEXT,
  infra_runtime_id TEXT,
  rollback_on_failure BOOLEAN NOT NULL DEFAULT TRUE,
  rollback_rollout_id TEXT REFERENCES model_deployment_rollouts(id),
  idempotency_key TEXT NOT NULL,
  failure_code TEXT NOT NULL DEFAULT '',
  failure_message TEXT NOT NULL DEFAULT '',
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  UNIQUE (model_deployment_id, idempotency_key),
  CHECK ((status IN ('SUCCEEDED', 'FAILED', 'CANCELED')) = (completed_at IS NOT NULL)),
  CHECK (kind = 'AUTO_ROLLBACK' OR rollback_rollout_id IS NULL),
  CHECK (kind <> 'AUTO_ROLLBACK' OR rollback_rollout_id IS NOT NULL)
);

ALTER TABLE model_deployments
  ADD CONSTRAINT fk_model_deployments_active_revision FOREIGN KEY (active_spec_revision_id) REFERENCES model_deployment_spec_revisions(id),
  ADD CONSTRAINT fk_model_deployments_pending_revision FOREIGN KEY (pending_spec_revision_id) REFERENCES model_deployment_spec_revisions(id),
  ADD CONSTRAINT fk_model_deployments_current_rollout FOREIGN KEY (current_rollout_id) REFERENCES model_deployment_rollouts(id);

CREATE UNIQUE INDEX idx_model_deployments_name ON model_deployments(name);
CREATE INDEX idx_model_deployments_status_health ON model_deployments(status, health_status);
CREATE INDEX idx_model_deployments_current_task ON model_deployments(current_atomic_task_id) WHERE current_atomic_task_id IS NOT NULL;
CREATE INDEX idx_model_deployment_revisions_engine_provider ON model_deployment_spec_revisions(serving_engine, runtime_provider, created_at DESC);
CREATE INDEX idx_model_deployment_rollouts_history ON model_deployment_rollouts(model_deployment_id, created_at DESC, id DESC);
CREATE UNIQUE INDEX idx_model_deployment_one_active_rollout ON model_deployment_rollouts(model_deployment_id) WHERE status IN ('PENDING', 'RUNNING');

COMMENT ON TABLE model_deployment_spec_revisions IS 'Immutable S1 expected configuration; application roles must not receive UPDATE or DELETE privileges.';
COMMENT ON COLUMN model_deployment_spec_revisions.spec_digest IS 'RFC 8785 canonical JSON SHA-256 over the final effective configuration.';
COMMENT ON COLUMN model_deployments.active_spec_revision_id IS 'Last revision that reached RUNNING, READY endpoint, and HEALTHY.';
COMMENT ON COLUMN model_deployments.pending_spec_revision_id IS 'Candidate revision only while current_rollout_id is non-terminal.';
