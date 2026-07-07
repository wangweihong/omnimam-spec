-- ai-chatting S2 design schema.
-- Product source: 00_product/domains/ai-chatting/product-spec.md
-- 本文件是设计态 schema，不是实际数据库 migration。
-- AI 聊天不维护独立模型配置表；model_id 引用 model-management.UserProviderModel.id。

-- S1 refs: US-AICHAT-06; BR-AICHAT-02, BR-AICHAT-09, BR-AICHAT-10.
CREATE TABLE ai_chat_assistants (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  system_prompt TEXT DEFAULT '',
  is_system BOOLEAN NOT NULL DEFAULT FALSE,
  suggested_model_id TEXT DEFAULT '',
  use_suggested_model BOOLEAN NOT NULL DEFAULT FALSE,
  runtime_config_json TEXT NOT NULL DEFAULT '{}',
  deleted_at TEXT DEFAULT ''
);

CREATE UNIQUE INDEX idx_ai_chat_assistants_owner_name
  ON ai_chat_assistants(owner_user_id, name)
  WHERE deleted_at = '';
CREATE INDEX idx_ai_chat_assistants_owner ON ai_chat_assistants(owner_user_id);

-- S1 refs: US-AICHAT-01, US-AICHAT-05, US-AICHAT-06; BR-AICHAT-01, BR-AICHAT-02, BR-AICHAT-08, BR-AICHAT-24.
CREATE TABLE ai_chat_topics (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  pinned BOOLEAN NOT NULL DEFAULT FALSE,
  assistant_id TEXT NOT NULL REFERENCES ai_chat_assistants(id),
  model_id TEXT NOT NULL,
  branch_source_json TEXT NOT NULL DEFAULT '{}',
  last_active_at TEXT NOT NULL,
  deleted_at TEXT DEFAULT ''
);

CREATE INDEX idx_ai_chat_topics_owner ON ai_chat_topics(owner_user_id);
CREATE INDEX idx_ai_chat_topics_last_active ON ai_chat_topics(owner_user_id, last_active_at);

-- S1 refs: US-AICHAT-01, US-AICHAT-02, US-AICHAT-03, US-AICHAT-05; BR-AICHAT-03..BR-AICHAT-07.
CREATE TABLE ai_chat_messages (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  topic_id TEXT NOT NULL REFERENCES ai_chat_topics(id),
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('queued', 'generating', 'done', 'interrupted', 'failed')),
  version INTEGER NOT NULL DEFAULT 1,
  parent_message_id TEXT DEFAULT '',
  model_snapshot_json TEXT NOT NULL DEFAULT '{}',
  assistant_snapshot_json TEXT NOT NULL DEFAULT '{}',
  attachment_icons_json TEXT NOT NULL DEFAULT '[]',
  deleted_at TEXT DEFAULT ''
);

CREATE INDEX idx_ai_chat_messages_topic ON ai_chat_messages(topic_id);
CREATE INDEX idx_ai_chat_messages_parent ON ai_chat_messages(parent_message_id);

-- S1 refs: US-AICHAT-02, US-AICHAT-03, US-AICHAT-04, US-AICHAT-09; BR-AICHAT-04, BR-AICHAT-14, BR-AICHAT-20, BR-AICHAT-21.
CREATE TABLE ai_chat_generation_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  topic_id TEXT NOT NULL REFERENCES ai_chat_topics(id),
  assistant_message_id TEXT NOT NULL REFERENCES ai_chat_messages(id),
  operation TEXT NOT NULL CHECK (operation IN ('chat', 'translate')),
  status TEXT NOT NULL CHECK (status IN ('queued', 'generating', 'done', 'interrupted', 'failed')),
  started_at TEXT DEFAULT '',
  finished_at TEXT DEFAULT ''
);

CREATE INDEX idx_ai_chat_generation_runs_topic ON ai_chat_generation_runs(topic_id);
CREATE INDEX idx_ai_chat_generation_runs_status ON ai_chat_generation_runs(status);

-- S1 refs: US-AICHAT-01, US-AICHAT-06, US-AICHAT-07; BR-AICHAT-02, BR-AICHAT-11.
CREATE TABLE ai_chat_quick_phrases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  owner_user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  scope TEXT NOT NULL CHECK (scope IN ('global', 'assistant')),
  assistant_id TEXT DEFAULT '',
  phrase_type TEXT NOT NULL CHECK (phrase_type IN ('plain', 'prompt')),
  deleted_at TEXT DEFAULT ''
);

CREATE INDEX idx_ai_chat_quick_phrases_owner ON ai_chat_quick_phrases(owner_user_id);
CREATE INDEX idx_ai_chat_quick_phrases_assistant ON ai_chat_quick_phrases(assistant_id);

-- S1 refs: US-AICHAT-09; BR-AICHAT-12, BR-AICHAT-13, BR-AICHAT-14.
CREATE TABLE ai_chat_message_translations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  description TEXT DEFAULT '',
  extend_shadow TEXT DEFAULT '',
  resource_version INTEGER DEFAULT 0,
  message_id TEXT NOT NULL REFERENCES ai_chat_messages(id),
  target_language TEXT NOT NULL,
  translated_content TEXT NOT NULL,
  model_snapshot_json TEXT NOT NULL
);

CREATE INDEX idx_ai_chat_message_translations_message ON ai_chat_message_translations(message_id);
