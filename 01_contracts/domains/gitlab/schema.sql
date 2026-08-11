-- GitLab S2 design schema, v1.0.0. This is not a migration.
-- s1_refs: US-GITLAB-001, BR-GITLAB-001..008, BR-GITLAB-012.

CREATE TABLE gitlab_servers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  api_url TEXT NOT NULL,
  external_url TEXT NOT NULL,
  namespace_path TEXT NOT NULL,
  credential TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'UNKNOWN' CHECK (status IN ('UNKNOWN', 'READY', 'ERROR')),
  last_checked_at TIMESTAMPTZ,
  last_error TEXT NOT NULL DEFAULT '',
  UNIQUE (name)
);
CREATE INDEX idx_gitlab_servers_status ON gitlab_servers(status, updated_at);

CREATE TABLE gitlab_projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  extend_shadow TEXT NOT NULL DEFAULT '',
  resource_version INTEGER NOT NULL DEFAULT 0,
  gitlab_server_id TEXT NOT NULL REFERENCES gitlab_servers(id) ON DELETE RESTRICT,
  external_project_id BIGINT NOT NULL,
  path TEXT NOT NULL,
  path_with_namespace TEXT NOT NULL,
  web_url TEXT NOT NULL,
  http_url_to_repo TEXT NOT NULL,
  ssh_url_to_repo TEXT NOT NULL DEFAULT '',
  default_branch TEXT NOT NULL DEFAULT 'main',
  UNIQUE (gitlab_server_id, external_project_id),
  UNIQUE (gitlab_server_id, path_with_namespace)
);
CREATE INDEX idx_gitlab_projects_server ON gitlab_projects(gitlab_server_id, created_at);
