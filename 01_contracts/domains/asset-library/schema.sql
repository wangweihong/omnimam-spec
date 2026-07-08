-- asset-library S2 design schema.
-- Product source: 00_product/domains/asset-library/product-spec.md
-- 本文件是设计态 schema，不是实际数据库 migration。

-- S1 refs: US-USER-ASSET-01..US-USER-ASSET-04, US-USER-ASSET-09..US-USER-ASSET-18, US-USER-ASSET-40;
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
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'text', 'pdf', 'other')),
  format TEXT DEFAULT '',
  size_bytes BIGINT NOT NULL,
  width INTEGER DEFAULT 0,
  height INTEGER DEFAULT 0,
  duration_seconds REAL DEFAULT 0,
  source_type TEXT NOT NULL CHECK (source_type IN ('upload', 'canvas_output')),
  object_path TEXT NOT NULL,
  thumbnail_status TEXT NOT NULL CHECK (thumbnail_status IN ('none', 'pending', 'ready', 'failed')),
  preview_status TEXT NOT NULL DEFAULT 'none' CHECK (preview_status IN ('none', 'pending', 'ready', 'failed')),
  sha256 TEXT DEFAULT '',
  reference_count INTEGER NOT NULL DEFAULT 0,
  reference_sources_json TEXT NOT NULL DEFAULT '[]',
  tags_json TEXT NOT NULL DEFAULT '[]',
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
  checksum TEXT NOT NULL,
  file_name TEXT NOT NULL,
  size_bytes BIGINT NOT NULL,
  chunk_size_bytes BIGINT DEFAULT 0,
  uploaded_parts_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL CHECK (status IN ('initialized', 'uploading', 'completed', 'cancelled', 'failed')),
  tags_json TEXT NOT NULL DEFAULT '[]'
);

CREATE INDEX idx_user_asset_upload_sessions_owner ON user_asset_upload_sessions(owner_user_id);
CREATE INDEX idx_user_asset_upload_sessions_checksum ON user_asset_upload_sessions(owner_user_id, checksum);
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
  color TEXT DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_user_asset_groups_owner ON user_asset_groups(owner_user_id);
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
