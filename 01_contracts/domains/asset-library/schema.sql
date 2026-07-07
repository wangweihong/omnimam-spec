-- asset-library S2 design schema.
-- Product source: 00_product/domains/asset-library/product-spec.md
-- 本文件是设计态 schema，不是实际数据库 migration。

-- S1 refs: US-USER-ASSET-01..US-USER-ASSET-04, US-USER-ASSET-09..US-USER-ASSET-18;
-- BR-USER-ASSET-02..BR-USER-ASSET-10, BR-USER-ASSET-18..BR-USER-ASSET-34.
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

-- S1 refs: US-USER-ASSET-09; BR-USER-ASSET-19, BR-USER-ASSET-27, BR-USER-ASSET-28.
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
  task_type TEXT NOT NULL CHECK (task_type IN ('thumbnail', 'preview_derivative')),
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
