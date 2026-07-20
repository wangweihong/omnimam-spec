-- asset-library S2 design schema.
-- Product source: 00_product/domains/asset-library/product-spec.md
-- 本文件是设计态 schema，不是实际数据库 migration。

-- S1 refs: US-USER-ASSET-01..US-USER-ASSET-04, US-USER-ASSET-09..US-USER-ASSET-18, US-USER-ASSET-40, US-USER-ASSET-43;
-- BR-USER-ASSET-02..BR-USER-ASSET-10, BR-USER-ASSET-18..BR-USER-ASSET-34, BR-USER-ASSET-57..BR-USER-ASSET-58.
CREATE TABLE user_assets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  original_name TEXT DEFAULT '',
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'text', 'document', 'model_3d', 'prompt', 'prompt_template', 'pdf', 'other')),
  format TEXT DEFAULT '',
  size_bytes BIGINT NOT NULL,
  width INTEGER DEFAULT 0,
  height INTEGER DEFAULT 0,
  duration_seconds REAL DEFAULT 0,
  source_type TEXT NOT NULL CHECK (source_type IN ('upload', 'canvas_output', 'application_output')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
  current_version_id TEXT,
  thumbnail_status TEXT NOT NULL CHECK (thumbnail_status IN ('none', 'pending', 'ready', 'failed')),
  preview_status TEXT NOT NULL DEFAULT 'none' CHECK (preview_status IN ('none', 'pending', 'ready', 'failed')),
  sha256 TEXT DEFAULT '',
  reference_count INTEGER NOT NULL DEFAULT 0,
  reference_sources_json TEXT NOT NULL DEFAULT '[]',
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_user_assets_owner ON user_assets(owner_user_id);
CREATE INDEX idx_user_assets_owner_created ON user_assets(owner_user_id, created_at);
CREATE INDEX idx_user_assets_media_type ON user_assets(owner_user_id, media_type);
CREATE INDEX idx_user_assets_format ON user_assets(owner_user_id, format);
CREATE INDEX idx_user_assets_source_type ON user_assets(owner_user_id, source_type);
CREATE INDEX idx_user_assets_thumbnail_status ON user_assets(owner_user_id, thumbnail_status);
CREATE INDEX idx_user_assets_sha256 ON user_assets(owner_user_id, sha256);
CREATE INDEX idx_user_assets_reference_count ON user_assets(owner_user_id, reference_count);
CREATE INDEX idx_user_assets_display_name ON user_assets(owner_user_id, display_name);
CREATE INDEX idx_user_assets_original_name ON user_assets(owner_user_id, original_name);
CREATE UNIQUE INDEX idx_user_assets_owner_id_unique ON user_assets(owner_user_id, id);

-- S1 refs: US-USER-ASSET-42..US-USER-ASSET-44; BR-USER-ASSET-64..BR-USER-ASSET-78.
CREATE TABLE storage_backends (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  backend_type TEXT NOT NULL CHECK (backend_type IN ('local', 's3', 'minio', 'oss', 'cos', 'azure_blob')),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  config_ref TEXT NOT NULL
);

CREATE TABLE blobs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  storage_backend_id TEXT NOT NULL REFERENCES storage_backends(id),
  object_key TEXT NOT NULL,
  sha256 TEXT NOT NULL,
  size_bytes BIGINT NOT NULL CHECK (size_bytes >= 0),
  mime_type TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'available', 'corrupted', 'missing', 'deleting', 'deleted')),
  UNIQUE (storage_backend_id, object_key)
);

CREATE INDEX idx_blobs_sha256 ON blobs(sha256);
CREATE INDEX idx_blobs_status ON blobs(status);

-- Artifact is owned by asset-library; provider credentials and arbitrary URLs are forbidden.
-- S1 refs: US-USER-ASSET-42, US-USER-ASSET-45; BR-USER-ASSET-64..BR-USER-ASSET-68, BR-USER-ASSET-76..BR-USER-ASSET-78.
CREATE TABLE artifacts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  artifact_type TEXT NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'text', 'document', 'model_3d', 'prompt', 'prompt_template', 'pdf', 'other')),
  producer_type TEXT NOT NULL CHECK (producer_type IN ('application_run', 'canvas_run', 'atomic_task')),
  producer_id TEXT NOT NULL,
  producer_idempotency_key TEXT NOT NULL,
  atomic_task_id TEXT,
  task_attempt_id TEXT,
  application_run_id TEXT,
  canvas_run_id TEXT,
  node_run_id TEXT,
  node_id TEXT,
  output_key TEXT NOT NULL,
  sequence INTEGER NOT NULL DEFAULT 0 CHECK (sequence >= 0),
  blob_id TEXT REFERENCES blobs(id),
  content_json TEXT NOT NULL DEFAULT '{}',
  metadata_json TEXT NOT NULL DEFAULT '{}',
  processing_status TEXT NOT NULL CHECK (processing_status IN ('created', 'transferring', 'processing', 'ready', 'failed', 'deleted')),
  registration_status TEXT NOT NULL CHECK (registration_status IN ('pending', 'registered', 'failed')),
  save_policy TEXT NOT NULL CHECK (save_policy IN ('transient', 'manual_save', 'auto_save')),
  processing_profile_version TEXT NOT NULL,
  preview_available BOOLEAN NOT NULL DEFAULT FALSE,
  preview_ref TEXT,
  thumbnail_ref TEXT,
  processing_error_code TEXT,
  processing_error_detail TEXT,
  registration_error_code TEXT,
  registration_error_detail TEXT,
  asset_id TEXT,
  asset_version_id TEXT,
  expires_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  UNIQUE (owner_user_id, producer_type, producer_idempotency_key)
);

CREATE INDEX idx_artifacts_owner_created ON artifacts(owner_user_id, created_at);
CREATE INDEX idx_artifacts_atomic_task ON artifacts(atomic_task_id);
CREATE INDEX idx_artifacts_application_run ON artifacts(application_run_id);
CREATE INDEX idx_artifacts_processing_status ON artifacts(owner_user_id, processing_status);
CREATE INDEX idx_artifacts_expires_at ON artifacts(expires_at) WHERE registration_status <> 'registered' AND deleted_at IS NULL;

-- S1 refs: US-USER-ASSET-10, US-USER-ASSET-43..US-USER-ASSET-45; BR-USER-ASSET-19..BR-USER-ASSET-20, BR-USER-ASSET-69..BR-USER-ASSET-77.
CREATE TABLE asset_versions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  asset_id TEXT NOT NULL REFERENCES user_assets(id),
  owner_user_id TEXT NOT NULL,
  version_no INTEGER NOT NULL CHECK (version_no > 0),
  status TEXT NOT NULL CHECK (status IN ('uploading', 'processing', 'ready', 'ready_with_warnings', 'failed')),
  source_type TEXT NOT NULL CHECK (source_type IN ('upload', 'artifact', 'asset_edit', 'asset_conversion', 'external_import')),
  source_ref_id TEXT,
  content_json TEXT NOT NULL DEFAULT '{}',
  metadata_json TEXT NOT NULL DEFAULT '{}',
  version_note TEXT DEFAULT '',
  processing_error_json TEXT NOT NULL DEFAULT '{}',
  profile_version TEXT NOT NULL,
  expected_count INTEGER NOT NULL DEFAULT 0,
  completed_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  deleted_at TIMESTAMPTZ,
  UNIQUE (asset_id, version_no)
);

CREATE INDEX idx_asset_versions_owner_status ON asset_versions(owner_user_id, status);
CREATE INDEX idx_asset_versions_asset ON asset_versions(asset_id, version_no);

CREATE TABLE asset_representations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  asset_version_id TEXT NOT NULL REFERENCES asset_versions(id),
  owner_user_id TEXT NOT NULL,
  representation_type TEXT NOT NULL CHECK (representation_type IN ('original', 'canonical', 'thumbnail', 'preview', 'playback', 'package', 'manifest')),
  profile TEXT NOT NULL DEFAULT 'default',
  profile_version TEXT NOT NULL,
  blob_id TEXT REFERENCES blobs(id),
  content_json TEXT NOT NULL DEFAULT '{}',
  metadata_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'ready', 'failed', 'irreparable', 'deleted')),
  required BOOLEAN NOT NULL DEFAULT FALSE,
  retry_count INTEGER NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
  retry_after TIMESTAMPTZ,
  error_code TEXT,
  error_detail TEXT,
  deleted_at TIMESTAMPTZ,
  UNIQUE (asset_version_id, representation_type, profile, profile_version)
);

CREATE INDEX idx_asset_representations_version ON asset_representations(asset_version_id);
CREATE INDEX idx_asset_representations_missing ON asset_representations(status, retry_after) WHERE status IN ('failed', 'irreparable');

CREATE TABLE representation_build_requests (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  asset_version_id TEXT NOT NULL REFERENCES asset_versions(id),
  owner_user_id TEXT NOT NULL,
  profile_version TEXT NOT NULL,
  dag_task_group_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'submitted', 'running', 'completed', 'failed')),
  requested_types_json TEXT NOT NULL DEFAULT '[]',
  idempotency_key TEXT NOT NULL UNIQUE,
  last_error TEXT
);

CREATE UNIQUE INDEX idx_representation_build_version_profile ON representation_build_requests(asset_version_id, profile_version);

-- S1 refs: US-USER-ASSET-41..US-USER-ASSET-43; BR-USER-ASSET-64..BR-USER-ASSET-72.
CREATE TABLE artifact_asset_registrations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  artifact_id TEXT NOT NULL REFERENCES artifacts(id),
  application_run_id TEXT,
  owner_user_id TEXT NOT NULL,
  asset_id TEXT NOT NULL,
  asset_version_id TEXT NOT NULL REFERENCES asset_versions(id),
  registration_mode TEXT NOT NULL CHECK (registration_mode IN ('create_asset', 'append_version')),
  registration_result TEXT NOT NULL CHECK (registration_result IN ('created', 'already_registered')),
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'text', 'document', 'model_3d', 'prompt', 'prompt_template', 'pdf', 'other')),
  FOREIGN KEY (owner_user_id, asset_id) REFERENCES user_assets(owner_user_id, id)
);

CREATE UNIQUE INDEX idx_artifact_asset_registrations_artifact ON artifact_asset_registrations(artifact_id);
CREATE INDEX idx_artifact_asset_registrations_run ON artifact_asset_registrations(application_run_id);
CREATE INDEX idx_artifact_asset_registrations_asset ON artifact_asset_registrations(asset_id);
CREATE UNIQUE INDEX idx_artifact_asset_registrations_version ON artifact_asset_registrations(asset_version_id);

-- 模糊搜索索引建议：生产部署可在启用 PostgreSQL pg_trgm 后，为 display_name、original_name、
-- description 分别建立包含 owner_user_id 过滤条件的 GIN trigram 索引。扩展安装与实际 migration
-- 不属于本设计态 schema。

-- S1 refs: US-USER-ASSET-19, US-USER-ASSET-20, US-USER-ASSET-21, US-USER-ASSET-23,
-- US-USER-ASSET-25, US-USER-ASSET-28; BR-USER-ASSET-35..BR-USER-ASSET-40.
CREATE TABLE user_asset_labels (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  asset_id TEXT NOT NULL,
  label_key TEXT NOT NULL,
  label_value TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL CHECK (source IN ('manual', 'auto')),
  deleted_at TIMESTAMPTZ,
  FOREIGN KEY (owner_user_id, asset_id) REFERENCES user_assets(owner_user_id, id),
  CHECK (name = label_key),
  CHECK (label_key = btrim(label_key)),
  CHECK (char_length(label_key) BETWEEN 1 AND 63),
  CHECK (label_key !~ '[[:space:][:cntrl:],;()=!"#@]'),
  CHECK (label_value = btrim(label_value)),
  CHECK (char_length(label_value) BETWEEN 0 AND 63)
);

CREATE INDEX idx_user_asset_labels_asset ON user_asset_labels(owner_user_id, asset_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_asset_labels_query ON user_asset_labels(owner_user_id, label_key, label_value) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_user_asset_labels_key_unique ON user_asset_labels(asset_id, label_key) WHERE deleted_at IS NULL;

-- S1 refs: US-USER-ASSET-20, US-USER-ASSET-21, US-USER-ASSET-23, US-USER-ASSET-26..US-USER-ASSET-30;
-- BR-USER-ASSET-35..BR-USER-ASSET-40.
CREATE TABLE user_asset_tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  asset_id TEXT NOT NULL,
  tag TEXT NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('manual', 'auto')),
  deleted_at TIMESTAMPTZ,
  FOREIGN KEY (owner_user_id, asset_id) REFERENCES user_assets(owner_user_id, id),
  CHECK (name = tag),
  CHECK (tag = btrim(tag)),
  CHECK (char_length(tag) BETWEEN 1 AND 64)
);

CREATE INDEX idx_user_asset_tags_asset ON user_asset_tags(owner_user_id, asset_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_asset_tags_query ON user_asset_tags(owner_user_id, tag) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_user_asset_tags_value_unique ON user_asset_tags(asset_id, tag) WHERE deleted_at IS NULL;

-- 每个素材最多 20 个有效 Labels 和 30 个有效 Tags，由 labeling 模块在同一素材事务内计数校验；
-- 普通 CHECK 无法跨行表达该约束。Label/Tag 精确匹配沿用 PostgreSQL 默认区分大小写比较，
-- 实现不得对查询或唯一性判断使用 lower() 大小写折叠。通用资源字段 name 分别镜像
-- label_key 和 tag，并由 CHECK 保证一致，不构成第二个业务事实源。

-- S1 refs: US-USER-ASSET-05..US-USER-ASSET-08; BR-USER-ASSET-11..BR-USER-ASSET-18.
CREATE TABLE user_asset_upload_sessions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  client_upload_key TEXT NOT NULL,
  sha256 TEXT NOT NULL,
  file_name TEXT NOT NULL,
  display_name TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes BIGINT NOT NULL,
  target_asset_id TEXT REFERENCES user_assets(id),
  version_note TEXT DEFAULT '',
  profile_version TEXT NOT NULL,
  upload_mode TEXT NOT NULL CHECK (upload_mode IN ('single', 'chunked')),
  chunk_size_bytes BIGINT DEFAULT 0,
  uploaded_parts_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL CHECK (status IN ('initialized', 'uploading', 'completed', 'cancelled', 'failed')),
  pending_labels_payload TEXT NOT NULL DEFAULT '{}',
  pending_tags_payload TEXT NOT NULL DEFAULT '[]',
  UNIQUE (owner_user_id, client_upload_key)
);

CREATE INDEX idx_user_asset_upload_sessions_owner ON user_asset_upload_sessions(owner_user_id);
CREATE INDEX idx_user_asset_upload_sessions_sha256 ON user_asset_upload_sessions(owner_user_id, sha256);
CREATE INDEX idx_user_asset_upload_sessions_status ON user_asset_upload_sessions(owner_user_id, status);

-- S1 refs: US-USER-ASSET-34, US-USER-ASSET-36, US-USER-ASSET-38, US-USER-ASSET-39;
-- BR-USER-ASSET-49..BR-USER-ASSET-56.
CREATE TABLE user_asset_groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  parent_group_id TEXT REFERENCES user_asset_groups(id),
  color TEXT DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_user_asset_groups_owner ON user_asset_groups(owner_user_id);
CREATE INDEX idx_user_asset_groups_parent ON user_asset_groups(owner_user_id, parent_group_id);
CREATE INDEX idx_user_asset_groups_sort ON user_asset_groups(owner_user_id, sort_order);
CREATE UNIQUE INDEX idx_user_asset_groups_owner_name_unique ON user_asset_groups(owner_user_id, lower(trim(name))) WHERE deleted_at IS NULL;

-- S1 refs: US-USER-ASSET-35, US-USER-ASSET-36, US-USER-ASSET-37, US-USER-ASSET-38, US-USER-ASSET-39;
-- BR-USER-ASSET-51..BR-USER-ASSET-54, BR-USER-ASSET-56.
CREATE TABLE user_asset_group_memberships (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  group_id TEXT NOT NULL REFERENCES user_asset_groups(id),
  asset_id TEXT NOT NULL REFERENCES user_assets(id),
  pinned_version_id TEXT REFERENCES asset_versions(id),
  role TEXT NOT NULL DEFAULT '',
  metadata_json TEXT NOT NULL DEFAULT '{}',
  created_by TEXT NOT NULL,
  joined_at TIMESTAMPTZ NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_user_asset_group_memberships_owner ON user_asset_group_memberships(owner_user_id);
CREATE INDEX idx_user_asset_group_memberships_group ON user_asset_group_memberships(owner_user_id, group_id);
CREATE INDEX idx_user_asset_group_memberships_asset ON user_asset_group_memberships(owner_user_id, asset_id);
CREATE INDEX idx_user_asset_group_memberships_sort ON user_asset_group_memberships(group_id, sort_order);
CREATE UNIQUE INDEX idx_user_asset_group_memberships_unique ON user_asset_group_memberships(owner_user_id, group_id, asset_id) WHERE deleted_at IS NULL;

-- S1 refs: US-USER-ASSET-09..US-USER-ASSET-12; BR-USER-ASSET-07, BR-USER-ASSET-19..BR-USER-ASSET-23, BR-USER-ASSET-27, BR-USER-ASSET-28.
CREATE TABLE user_asset_previews (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  asset_id TEXT NOT NULL REFERENCES user_assets(id),
  owner_user_id TEXT NOT NULL,
  thumbnail_path TEXT DEFAULT '',
  preview_path TEXT DEFAULT '',
  preview_type TEXT DEFAULT '' CHECK (preview_type IN ('', 'image', 'video', 'audio', 'text', 'pdf', 'embed', 'fallback')),
  status TEXT NOT NULL CHECK (status IN ('none', 'pending', 'ready', 'failed')),
  reason TEXT DEFAULT ''
);

CREATE UNIQUE INDEX idx_user_asset_previews_asset ON user_asset_previews(asset_id);
CREATE INDEX idx_user_asset_previews_owner ON user_asset_previews(owner_user_id);
CREATE INDEX idx_user_asset_previews_status ON user_asset_previews(owner_user_id, status);

-- S1 refs: US-USER-ASSET-09, US-USER-ASSET-32; BR-USER-ASSET-19, BR-USER-ASSET-27, BR-USER-ASSET-28, BR-USER-ASSET-43.
CREATE TABLE user_asset_processing_tasks (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  asset_id TEXT NOT NULL REFERENCES user_assets(id),
  task_type TEXT NOT NULL CHECK (task_type IN ('thumbnail', 'preview_derivative', 'sha256_backfill')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  reason TEXT DEFAULT ''
);

CREATE INDEX idx_user_asset_processing_tasks_owner ON user_asset_processing_tasks(owner_user_id);
CREATE INDEX idx_user_asset_processing_tasks_asset ON user_asset_processing_tasks(asset_id);
CREATE INDEX idx_user_asset_processing_tasks_status ON user_asset_processing_tasks(status);

-- S1 refs: US-USER-ASSET-16, US-USER-ASSET-17; BR-USER-ASSET-29..BR-USER-ASSET-31.
CREATE TABLE canvas_asset_outputs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  canvas_id TEXT NOT NULL,
  node_id TEXT NOT NULL,
  asset_id TEXT NOT NULL REFERENCES user_assets(id)
);

CREATE INDEX idx_canvas_asset_outputs_owner ON canvas_asset_outputs(owner_user_id);
CREATE INDEX idx_canvas_asset_outputs_canvas ON canvas_asset_outputs(owner_user_id, canvas_id);
CREATE INDEX idx_canvas_asset_outputs_asset ON canvas_asset_outputs(asset_id);
