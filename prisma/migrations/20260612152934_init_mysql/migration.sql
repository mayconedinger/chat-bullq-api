-- CreateTable
CREATE TABLE `users` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `password` VARCHAR(191) NOT NULL,
    `avatar_url` VARCHAR(191) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    UNIQUE INDEX `users_email_key`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `organizations` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `logo_url` VARCHAR(191) NULL,
    `plan` VARCHAR(191) NOT NULL DEFAULT 'free',
    `settings` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,
    `ai_enabled` BOOLEAN NOT NULL DEFAULT true,
    `ai_timezone` VARCHAR(191) NOT NULL DEFAULT 'America/Sao_Paulo',
    `ai_business_hours` JSON NULL,
    `ai_out_of_hours_message` VARCHAR(191) NULL,
    `ai_auto_disable_on_human` BOOLEAN NOT NULL DEFAULT true,
    `ai_monthly_token_cap` INTEGER NULL,
    `ai_business_notes` TEXT NULL,
    `ai_security_rules` JSON NULL,
    `ai_classifier_threshold` DECIMAL(3, 2) NULL DEFAULT 0.85,
    `allowed_url_domains` JSON NULL,
    `watchdog_enabled` BOOLEAN NOT NULL DEFAULT true,
    `watchdog_business_hours` JSON NULL,
    `watchdog_config` JSON NULL,

    UNIQUE INDEX `organizations_slug_key`(`slug`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_organizations` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `role` ENUM('OWNER', 'ADMIN', 'AGENT') NOT NULL DEFAULT 'AGENT',
    `agent_status` ENUM('ONLINE', 'AWAY', 'OFFLINE') NOT NULL DEFAULT 'OFFLINE',
    `max_concurrent` INTEGER NOT NULL DEFAULT 5,
    `preferences` JSON NOT NULL,
    `joined_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `user_organizations_user_id_organization_id_key`(`user_id`, `organization_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `invitations` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `role` ENUM('OWNER', 'ADMIN', 'AGENT') NOT NULL DEFAULT 'AGENT',
    `token` VARCHAR(191) NOT NULL,
    `status` ENUM('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED') NOT NULL DEFAULT 'PENDING',
    `invited_by_id` VARCHAR(191) NOT NULL,
    `expires_at` DATETIME(3) NOT NULL,
    `accepted_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `invitations_token_key`(`token`),
    INDEX `idx_invitation_email_status`(`email`, `status`),
    INDEX `idx_invitation_org`(`organization_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `channels` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `type` ENUM('WHATSAPP_OFFICIAL', 'WHATSAPP_ZAPPFY', 'INSTAGRAM') NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `config` JSON NOT NULL,
    `webhook_secret` VARCHAR(191) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `visibility` ENUM('ORG', 'PRIVATE') NOT NULL DEFAULT 'ORG',
    `ai_enabled` BOOLEAN NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    INDEX `idx_channel_org_type`(`organization_id`, `type`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `channel_agents` (
    `id` VARCHAR(191) NOT NULL,
    `channel_id` VARCHAR(191) NOT NULL,
    `user_organization_id` VARCHAR(191) NOT NULL,
    `granted_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `granted_by_id` VARCHAR(191) NULL,

    INDEX `idx_channel_agent_userorg`(`user_organization_id`),
    UNIQUE INDEX `channel_agents_channel_id_user_organization_id_key`(`channel_id`, `user_organization_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `webhook_events` (
    `id` VARCHAR(191) NOT NULL,
    `channel_id` VARCHAR(191) NULL,
    `channel_type` ENUM('WHATSAPP_OFFICIAL', 'WHATSAPP_ZAPPFY', 'INSTAGRAM') NOT NULL,
    `status` ENUM('RECEIVED', 'PROCESSED', 'FAILED', 'UNROUTED') NOT NULL DEFAULT 'RECEIVED',
    `raw_payload` JSON NOT NULL,
    `headers` JSON NOT NULL,
    `error_message` VARCHAR(191) NULL,
    `received_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `processed_at` DATETIME(3) NULL,

    INDEX `idx_webhook_channel_time`(`channel_id`, `received_at` DESC),
    INDEX `idx_webhook_type_status`(`channel_type`, `status`, `received_at` DESC),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `channel_sync_jobs` (
    `id` VARCHAR(191) NOT NULL,
    `channel_id` VARCHAR(191) NOT NULL,
    `status` ENUM('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    `mode` ENUM('INITIAL', 'MANUAL', 'DELTA') NOT NULL DEFAULT 'INITIAL',
    `lookback_days` INTEGER NOT NULL DEFAULT 90,
    `started_at` DATETIME(3) NULL,
    `finished_at` DATETIME(3) NULL,
    `conversations_total` INTEGER NOT NULL DEFAULT 0,
    `conversations_imported` INTEGER NOT NULL DEFAULT 0,
    `messages_imported` INTEGER NOT NULL DEFAULT 0,
    `contacts_imported` INTEGER NOT NULL DEFAULT 0,
    `error_message` VARCHAR(191) NULL,
    `last_cursor` VARCHAR(191) NULL,
    `metadata` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `idx_sync_channel_time`(`channel_id`, `created_at` DESC),
    INDEX `idx_sync_status`(`status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `contacts` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NULL,
    `phone` VARCHAR(191) NULL,
    `email` VARCHAR(191) NULL,
    `avatar_url` VARCHAR(191) NULL,
    `notes` VARCHAR(191) NULL,
    `metadata` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    INDEX `idx_contact_org_phone`(`organization_id`, `phone`),
    INDEX `idx_contact_org_email`(`organization_id`, `email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `contact_channels` (
    `id` VARCHAR(191) NOT NULL,
    `contact_id` VARCHAR(191) NOT NULL,
    `channel_id` VARCHAR(191) NOT NULL,
    `external_id` VARCHAR(191) NOT NULL,
    `profile_name` VARCHAR(191) NULL,
    `profile_avatar_url` VARCHAR(191) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `contact_channels_channel_id_external_id_key`(`channel_id`, `external_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `conversations` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `channel_id` VARCHAR(191) NOT NULL,
    `contact_id` VARCHAR(191) NOT NULL,
    `assigned_to_id` VARCHAR(191) NULL,
    `department_id` VARCHAR(191) NULL,
    `status` ENUM('PENDING', 'BOT', 'OPEN', 'WAITING', 'CLOSED') NOT NULL DEFAULT 'PENDING',
    `subject` VARCHAR(191) NULL,
    `protocol` VARCHAR(191) NULL,
    `is_group` BOOLEAN NOT NULL DEFAULT false,
    `last_message_at` DATETIME(3) NULL,
    `first_response_at` DATETIME(3) NULL,
    `closed_at` DATETIME(3) NULL,
    `reopened_at` DATETIME(3) NULL,
    `reopened_count` INTEGER NOT NULL DEFAULT 0,
    `deleted_at` DATETIME(3) NULL,
    `is_archived` BOOLEAN NOT NULL DEFAULT false,
    `archived_at` DATETIME(3) NULL,
    `archived_by_id` VARCHAR(191) NULL,
    `metadata` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `ai_enabled` BOOLEAN NULL,
    `ai_disabled_by` VARCHAR(191) NULL,
    `ai_disabled_at` DATETIME(3) NULL,
    `active_agent_id` VARCHAR(191) NULL,
    `stuck_attempts` INTEGER NOT NULL DEFAULT 0,
    `last_watchdog_check_at` DATETIME(3) NULL,
    `watchdog_job_id` VARCHAR(191) NULL,
    `is_stuck` BOOLEAN NOT NULL DEFAULT false,

    INDEX `idx_conv_org_status`(`organization_id`, `status`),
    INDEX `idx_conv_org_agent`(`organization_id`, `assigned_to_id`),
    INDEX `idx_conv_org_channel`(`organization_id`, `channel_id`),
    INDEX `idx_conv_org_archived`(`organization_id`, `is_archived`),
    INDEX `idx_conv_contact`(`contact_id`),
    INDEX `idx_conv_last_msg`(`last_message_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `conversation_ratings` (
    `id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `agent_id` VARCHAR(191) NULL,
    `score` INTEGER NOT NULL,
    `comment` VARCHAR(191) NULL,
    `token` VARCHAR(191) NOT NULL,
    `requested_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `responded_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `conversation_ratings_conversation_id_key`(`conversation_id`),
    UNIQUE INDEX `conversation_ratings_token_key`(`token`),
    INDEX `idx_rating_org_responded`(`organization_id`, `responded_at`),
    INDEX `idx_rating_org_agent`(`organization_id`, `agent_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `conversation_audit_logs` (
    `id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NOT NULL,
    `actor_id` VARCHAR(191) NULL,
    `action` VARCHAR(191) NOT NULL,
    `from_value` VARCHAR(191) NULL,
    `to_value` VARCHAR(191) NULL,
    `metadata` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_audit_conv_time`(`conversation_id`, `created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `internal_notes` (
    `id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NOT NULL,
    `author_id` VARCHAR(191) NOT NULL,
    `content` VARCHAR(191) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `messages` (
    `id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NOT NULL,
    `direction` ENUM('INBOUND', 'OUTBOUND') NOT NULL,
    `type` ENUM('TEXT', 'IMAGE', 'AUDIO', 'VIDEO', 'DOCUMENT', 'STICKER', 'LOCATION', 'REACTION', 'TEMPLATE', 'INTERACTIVE', 'SYSTEM') NOT NULL,
    `content` JSON NOT NULL,
    `external_id` VARCHAR(191) NULL,
    `status` ENUM('QUEUED', 'SENT', 'DELIVERED', 'READ', 'FAILED') NOT NULL DEFAULT 'QUEUED',
    `sender_name` VARCHAR(191) NULL,
    `sender_id` VARCHAR(191) NULL,
    `sent_at` DATETIME(3) NULL,
    `delivered_at` DATETIME(3) NULL,
    `read_at` DATETIME(3) NULL,
    `failed_reason` VARCHAR(191) NULL,
    `metadata` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `revoked_at` DATETIME(3) NULL,
    `revoked_by` VARCHAR(191) NULL,
    `revoke_succeeded_remote` BOOLEAN NULL,

    INDEX `idx_msg_conv_time`(`conversation_id`, `created_at`),
    INDEX `idx_msg_external_id`(`external_id`),
    UNIQUE INDEX `messages_conversation_id_external_id_key`(`conversation_id`, `external_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `departments` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `distribution_rule` ENUM('ROUND_ROBIN', 'LEAST_BUSY', 'MANUAL') NOT NULL DEFAULT 'ROUND_ROBIN',
    `is_default` BOOLEAN NOT NULL DEFAULT false,
    `sla_first_response` INTEGER NULL,
    `sla_resolution` INTEGER NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `department_agents` (
    `id` VARCHAR(191) NOT NULL,
    `department_id` VARCHAR(191) NOT NULL,
    `user_organization_id` VARCHAR(191) NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,

    UNIQUE INDEX `department_agents_department_id_user_organization_id_key`(`department_id`, `user_organization_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `chatbot_flows` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT false,
    `trigger_type` VARCHAR(191) NOT NULL DEFAULT 'KEYWORD',
    `trigger_config` JSON NOT NULL,
    `variables` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `chatbot_nodes` (
    `id` VARCHAR(191) NOT NULL,
    `flow_id` VARCHAR(191) NOT NULL,
    `type` ENUM('START', 'MESSAGE', 'MENU', 'CONDITION', 'WAIT', 'ACTION', 'TRANSFER', 'END_FLOW') NOT NULL,
    `name` VARCHAR(191) NULL,
    `position_x` DOUBLE NOT NULL DEFAULT 0,
    `position_y` DOUBLE NOT NULL DEFAULT 0,
    `data` JSON NOT NULL,
    `edges` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `chatbot_flow_channels` (
    `flow_id` VARCHAR(191) NOT NULL,
    `channel_id` VARCHAR(191) NOT NULL,

    PRIMARY KEY (`flow_id`, `channel_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `quick_replies` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `shortcut` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `content` VARCHAR(191) NOT NULL,
    `attachments` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    UNIQUE INDEX `quick_replies_organization_id_shortcut_key`(`organization_id`, `shortcut`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tags` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `color` VARCHAR(191) NOT NULL DEFAULT '#6B7280',

    UNIQUE INDEX `tags_organization_id_name_key`(`organization_id`, `name`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `conversation_tags` (
    `conversation_id` VARCHAR(191) NOT NULL,
    `tag_id` VARCHAR(191) NOT NULL,

    PRIMARY KEY (`conversation_id`, `tag_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `contact_tags` (
    `contact_id` VARCHAR(191) NOT NULL,
    `tag_id` VARCHAR(191) NOT NULL,

    PRIMARY KEY (`contact_id`, `tag_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `notifications` (
    `id` VARCHAR(191) NOT NULL,
    `recipient_id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `type` ENUM('NEW_MESSAGE', 'CONVERSATION_ASSIGNED', 'CONVERSATION_TRANSFERRED', 'SLA_WARNING', 'SLA_BREACH', 'MENTION', 'SYSTEM', 'AI_TOOL_FAILURE') NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `body` VARCHAR(191) NOT NULL,
    `data` JSON NOT NULL,
    `is_read` BOOLEAN NOT NULL DEFAULT false,
    `read_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_notif_user_unread`(`recipient_id`, `is_read`, `created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `push_subscriptions` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `endpoint` VARCHAR(191) NOT NULL,
    `p256dh_key` VARCHAR(191) NOT NULL,
    `auth_key` VARCHAR(191) NOT NULL,
    `user_agent` VARCHAR(191) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `push_subscriptions_endpoint_key`(`endpoint`),
    INDEX `idx_push_sub_user`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `notification_preferences` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `type` ENUM('NEW_MESSAGE', 'CONVERSATION_ASSIGNED', 'CONVERSATION_TRANSFERRED', 'SLA_WARNING', 'SLA_BREACH', 'MENTION', 'SYSTEM', 'AI_TOOL_FAILURE') NOT NULL,
    `in_app` BOOLEAN NOT NULL DEFAULT true,
    `browser_push` BOOLEAN NOT NULL DEFAULT true,
    `sound` BOOLEAN NOT NULL DEFAULT true,
    `dnd_start` VARCHAR(191) NULL,
    `dnd_end` VARCHAR(191) NULL,

    UNIQUE INDEX `notification_preferences_user_id_organization_id_type_key`(`user_id`, `organization_id`, `type`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `api_keys` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `prefix` VARCHAR(12) NOT NULL,
    `hashed_key` VARCHAR(191) NOT NULL,
    `last_used_at` DATETIME(3) NULL,
    `expires_at` DATETIME(3) NULL,
    `revoked_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `api_keys_hashed_key_key`(`hashed_key`),
    INDEX `idx_apikey_org`(`organization_id`),
    INDEX `idx_apikey_user`(`user_id`),
    INDEX `idx_apikey_hash`(`hashed_key`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_agents` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `avatar_url` VARCHAR(191) NULL,
    `kind` ENUM('ORCHESTRATOR', 'WORKER') NOT NULL DEFAULT 'WORKER',
    `category` VARCHAR(191) NULL,
    `capabilities` JSON NOT NULL,
    `parent_agent_id` VARCHAR(191) NULL,
    `department` VARCHAR(191) NULL,
    `squad` VARCHAR(191) NULL,
    `model_id` VARCHAR(191) NOT NULL,
    `model_params` JSON NULL,
    `system_prompt` VARCHAR(191) NOT NULL,
    `operational_context` VARCHAR(191) NULL,
    `operational_context_updated_at` DATETIME(3) NULL,
    `temperature` DOUBLE NOT NULL DEFAULT 0.7,
    `max_tokens` INTEGER NOT NULL DEFAULT 2048,
    `can_respond_directly` BOOLEAN NOT NULL DEFAULT true,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `follow_up_enabled` BOOLEAN NOT NULL DEFAULT true,
    `follow_up_cadence_hours` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    INDEX `idx_ai_agent_org`(`organization_id`),
    INDEX `idx_ai_agent_org_kind`(`organization_id`, `kind`),
    INDEX `idx_ai_agent_parent`(`parent_agent_id`),
    INDEX `idx_ai_agent_org_dept`(`organization_id`, `department`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_tools` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` TEXT NOT NULL,
    `source` ENUM('CUSTOM_HTTP', 'CUSTOM_SQL') NOT NULL,
    `http_base_url` VARCHAR(191) NULL,
    `http_headers` JSON NULL,
    `sql_connection_ref` VARCHAR(191) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    INDEX `idx_tool_org`(`organization_id`),
    UNIQUE INDEX `ai_tools_organization_id_name_key`(`organization_id`, `name`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_skills` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` TEXT NOT NULL,
    `category` VARCHAR(191) NULL,
    `prompt_instructions` TEXT NULL,
    `source` ENUM('BUILTIN', 'HTTP', 'SQL') NOT NULL DEFAULT 'HTTP',
    `parameters` JSON NOT NULL,
    `tool_id` VARCHAR(191) NULL,
    `http_method` VARCHAR(191) NULL,
    `http_path` VARCHAR(191) NULL,
    `http_headers_extra` JSON NULL,
    `http_body_template` TEXT NULL,
    `response_map` JSON NULL,
    `sql_query` TEXT NULL,
    `sql_param_map` JSON NULL,
    `sql_read_only` BOOLEAN NOT NULL DEFAULT true,
    `sql_max_rows` INTEGER NOT NULL DEFAULT 50,
    `timeout_ms` INTEGER NOT NULL DEFAULT 15000,
    `current_version` INTEGER NOT NULL DEFAULT 1,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    INDEX `idx_skill_org`(`organization_id`),
    INDEX `idx_skill_tool`(`tool_id`),
    UNIQUE INDEX `ai_skills_organization_id_name_key`(`organization_id`, `name`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_skill_versions` (
    `id` VARCHAR(191) NOT NULL,
    `skill_id` VARCHAR(191) NOT NULL,
    `version` INTEGER NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` TEXT NOT NULL,
    `category` VARCHAR(191) NULL,
    `prompt_instructions` TEXT NULL,
    `source` ENUM('BUILTIN', 'HTTP', 'SQL') NOT NULL,
    `parameters` JSON NOT NULL,
    `tool_id` VARCHAR(191) NULL,
    `http_method` VARCHAR(191) NULL,
    `http_path` VARCHAR(191) NULL,
    `http_headers_extra` JSON NULL,
    `http_body_template` TEXT NULL,
    `response_map` JSON NULL,
    `sql_query` TEXT NULL,
    `sql_param_map` JSON NULL,
    `sql_read_only` BOOLEAN NOT NULL DEFAULT true,
    `sql_max_rows` INTEGER NOT NULL DEFAULT 50,
    `timeout_ms` INTEGER NOT NULL DEFAULT 15000,
    `changed_by_id` VARCHAR(191) NULL,
    `change_note` VARCHAR(191) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_skill_version_skill`(`skill_id`),
    UNIQUE INDEX `ai_skill_versions_skill_id_version_key`(`skill_id`, `version`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_agent_skills` (
    `agent_id` VARCHAR(191) NOT NULL,
    `skill_id` VARCHAR(191) NOT NULL,
    `requires_approval` BOOLEAN NOT NULL DEFAULT false,

    PRIMARY KEY (`agent_id`, `skill_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_agent_channels` (
    `id` VARCHAR(191) NOT NULL,
    `agent_id` VARCHAR(191) NOT NULL,
    `channel_id` VARCHAR(191) NOT NULL,
    `mode` ENUM('AUTONOMOUS', 'COPILOT', 'DISABLED') NOT NULL DEFAULT 'AUTONOMOUS',
    `trigger` ENUM('ALWAYS', 'OFF_HOURS', 'NO_HUMAN_ASSIGNED') NOT NULL DEFAULT 'ALWAYS',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_ai_agent_channel_channel`(`channel_id`),
    UNIQUE INDEX `ai_agent_channels_agent_id_channel_id_key`(`agent_id`, `channel_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_agent_memories` (
    `id` VARCHAR(191) NOT NULL,
    `agent_id` VARCHAR(191) NOT NULL,
    `contact_id` VARCHAR(191) NOT NULL,
    `summary` VARCHAR(191) NULL,
    `facts` JSON NOT NULL,
    `total_interactions` INTEGER NOT NULL DEFAULT 0,
    `last_interaction_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `idx_ai_memory_agent`(`agent_id`),
    INDEX `idx_ai_memory_contact`(`contact_id`),
    UNIQUE INDEX `ai_agent_memories_agent_id_contact_id_key`(`agent_id`, `contact_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_agent_runs` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NOT NULL,
    `agent_id` VARCHAR(191) NOT NULL,
    `trigger_message_id` VARCHAR(191) NULL,
    `status` ENUM('RUNNING', 'COMPLETED', 'FAILED', 'SKIPPED') NOT NULL DEFAULT 'RUNNING',
    `final_action` ENUM('REPLIED', 'DELEGATED', 'HANDED_BACK', 'TRANSFERRED_TO_HUMAN', 'CLOSED_CONVERSATION', 'NO_ACTION') NULL,
    `error_message` VARCHAR(191) NULL,
    `model_id` VARCHAR(191) NOT NULL,
    `input_tokens` INTEGER NOT NULL DEFAULT 0,
    `output_tokens` INTEGER NOT NULL DEFAULT 0,
    `cache_read_tokens` INTEGER NOT NULL DEFAULT 0,
    `cache_write_tokens` INTEGER NOT NULL DEFAULT 0,
    `cost_usd` DECIMAL(10, 6) NOT NULL DEFAULT 0,
    `duration_ms` INTEGER NULL,
    `classified_intent` VARCHAR(191) NULL,
    `classifier_confidence` DECIMAL(4, 3) NULL,
    `skipped_orchestrator` BOOLEAN NOT NULL DEFAULT false,
    `started_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `finished_at` DATETIME(3) NULL,

    INDEX `idx_ai_run_org_time`(`organization_id`, `started_at`),
    INDEX `idx_ai_run_conv`(`conversation_id`),
    INDEX `idx_ai_run_agent`(`agent_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_tool_calls` (
    `id` VARCHAR(191) NOT NULL,
    `run_id` VARCHAR(191) NOT NULL,
    `tool_name` VARCHAR(191) NOT NULL,
    `input` JSON NOT NULL,
    `output` JSON NULL,
    `error` VARCHAR(191) NULL,
    `duration_ms` INTEGER NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_ai_tool_call_run`(`run_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_agent_handoffs` (
    `id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NOT NULL,
    `from_agent_id` VARCHAR(191) NULL,
    `to_agent_id` VARCHAR(191) NOT NULL,
    `reason` VARCHAR(191) NULL,
    `briefing` VARCHAR(191) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_ai_handoff_conv`(`conversation_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ai_pending_actions` (
    `id` VARCHAR(191) NOT NULL,
    `agent_run_id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NOT NULL,
    `agent_id` VARCHAR(191) NOT NULL,
    `tool_name` VARCHAR(191) NOT NULL,
    `args` JSON NOT NULL,
    `preview` JSON NOT NULL,
    `status` ENUM('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED', 'EXECUTED') NOT NULL DEFAULT 'PENDING',
    `expires_at` DATETIME(3) NOT NULL,
    `approved_by` VARCHAR(191) NULL,
    `approved_at` DATETIME(3) NULL,
    `rejected_by` VARCHAR(191) NULL,
    `rejected_at` DATETIME(3) NULL,
    `rejected_reason` VARCHAR(191) NULL,
    `execution_result` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `idx_ai_pending_conv_status`(`conversation_id`, `status`),
    INDEX `idx_ai_pending_status_exp`(`status`, `expires_at`),
    INDEX `idx_ai_pending_run`(`agent_run_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `inbox_views` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `icon` VARCHAR(191) NULL,
    `color` VARCHAR(191) NULL,
    `filters` JSON NOT NULL,
    `metadata` JSON NOT NULL,
    `order` INTEGER NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `inbox_views_user_id_order_idx`(`user_id`, `order`),
    INDEX `inbox_views_organization_id_user_id_idx`(`organization_id`, `user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `conversation_reads` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NOT NULL,
    `last_read_message_id` VARCHAR(191) NULL,
    `last_read_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `conversation_reads_user_id_idx`(`user_id`),
    INDEX `conversation_reads_conversation_id_idx`(`conversation_id`),
    UNIQUE INDEX `conversation_reads_user_id_conversation_id_key`(`user_id`, `conversation_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `pipelines` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `icon` VARCHAR(191) NULL,
    `color` VARCHAR(191) NULL,
    `is_default` BOOLEAN NOT NULL DEFAULT false,
    `archived` BOOLEAN NOT NULL DEFAULT false,
    `order` INTEGER NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `pipelines_organization_id_archived_idx`(`organization_id`, `archived`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `pipeline_stages` (
    `id` VARCHAR(191) NOT NULL,
    `pipeline_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `color` VARCHAR(191) NULL,
    `type` ENUM('NORMAL', 'WON', 'LOST') NOT NULL DEFAULT 'NORMAL',
    `order` INTEGER NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `pipeline_stages_pipeline_id_order_idx`(`pipeline_id`, `order`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `cards` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `pipeline_id` VARCHAR(191) NOT NULL,
    `stage_id` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `value` DECIMAL(14, 2) NULL,
    `currency` VARCHAR(191) NOT NULL DEFAULT 'BRL',
    `status` ENUM('OPEN', 'WON', 'LOST') NOT NULL DEFAULT 'OPEN',
    `order` INTEGER NOT NULL DEFAULT 0,
    `contact_id` VARCHAR(191) NULL,
    `conversation_id` VARCHAR(191) NULL,
    `assigned_to_id` VARCHAR(191) NULL,
    `metadata` JSON NOT NULL,
    `closed_at` DATETIME(3) NULL,
    `closed_reason` VARCHAR(191) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `cards_pipeline_id_stage_id_order_idx`(`pipeline_id`, `stage_id`, `order`),
    INDEX `cards_organization_id_status_idx`(`organization_id`, `status`),
    INDEX `cards_contact_id_idx`(`contact_id`),
    INDEX `cards_conversation_id_idx`(`conversation_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `products` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `category` VARCHAR(191) NULL,
    `shortLine` VARCHAR(191) NOT NULL,
    `pitch` TEXT NOT NULL,
    `price` VARCHAR(191) NULL,
    `payment_link` VARCHAR(191) NULL,
    `target_audience` VARCHAR(191) NULL,
    `differentiators` JSON NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `order` INTEGER NOT NULL DEFAULT 0,
    `metadata` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `products_organization_id_is_active_order_idx`(`organization_id`, `is_active`, `order`),
    UNIQUE INDEX `products_organization_id_slug_key`(`organization_id`, `slug`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `outbox_events` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `trigger` ENUM('TAG_ADDED', 'TAG_REMOVED', 'MESSAGE_RECEIVED', 'CONVERSATION_STATUS_CHANGED', 'CONVERSATION_ASSIGNED') NOT NULL,
    `payload` JSON NOT NULL,
    `dedup_key` VARCHAR(191) NULL,
    `trace_id` VARCHAR(191) NOT NULL,
    `cascade_depth` INTEGER NOT NULL DEFAULT 0,
    `actor_id` VARCHAR(191) NULL,
    `status` ENUM('PENDING', 'PROCESSING', 'PROCESSED', 'FAILED', 'DLQ') NOT NULL DEFAULT 'PENDING',
    `attempt_count` INTEGER NOT NULL DEFAULT 0,
    `last_error` TEXT NULL,
    `leased_by` VARCHAR(191) NULL,
    `leased_until` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `processed_at` DATETIME(3) NULL,

    UNIQUE INDEX `outbox_events_dedup_key_key`(`dedup_key`),
    INDEX `idx_outbox_status_time`(`status`, `created_at`),
    INDEX `idx_outbox_org_trigger`(`organization_id`, `trigger`, `created_at` DESC),
    INDEX `idx_outbox_trace`(`trace_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `automations` (
    `id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `trigger` ENUM('TAG_ADDED', 'TAG_REMOVED', 'MESSAGE_RECEIVED', 'CONVERSATION_STATUS_CHANGED', 'CONVERSATION_ASSIGNED') NOT NULL,
    `conditions` JSON NOT NULL,
    `actions` JSON NOT NULL,
    `schema_version` INTEGER NOT NULL DEFAULT 1,
    `enabled` BOOLEAN NOT NULL DEFAULT false,
    `actor_id` VARCHAR(191) NOT NULL,
    `priority` INTEGER NOT NULL DEFAULT 0,
    `consecutive_failures` INTEGER NOT NULL DEFAULT 0,
    `auto_paused_at` DATETIME(3) NULL,
    `auto_paused_reason` VARCHAR(191) NULL,
    `rate_limit_per_minute` INTEGER NOT NULL DEFAULT 10,
    `last_run_at` DATETIME(3) NULL,
    `run_count` INTEGER NOT NULL DEFAULT 0,
    `success_count` INTEGER NOT NULL DEFAULT 0,
    `failure_count` INTEGER NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,
    `deleted_at` DATETIME(3) NULL,

    INDEX `idx_automation_org_enabled`(`organization_id`, `enabled`, `trigger`),
    INDEX `idx_automation_org_deleted`(`organization_id`, `deleted_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `automation_runs` (
    `id` VARCHAR(191) NOT NULL,
    `automation_id` VARCHAR(191) NOT NULL,
    `organization_id` VARCHAR(191) NOT NULL,
    `outbox_event_id` VARCHAR(191) NOT NULL,
    `trace_id` VARCHAR(191) NOT NULL,
    `status` ENUM('SUCCESS', 'PARTIAL', 'FAILED', 'SKIPPED') NOT NULL,
    `error_code` VARCHAR(191) NULL,
    `error_message` TEXT NULL,
    `trigger_payload` JSON NOT NULL,
    `actions_log` JSON NOT NULL,
    `duration_ms` INTEGER NULL,
    `started_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `finished_at` DATETIME(3) NULL,

    INDEX `idx_run_automation_time`(`automation_id`, `started_at` DESC),
    INDEX `idx_run_org_time`(`organization_id`, `started_at` DESC),
    INDEX `idx_run_trace`(`trace_id`),
    INDEX `idx_run_status_time`(`status`, `started_at` DESC),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `user_organizations` ADD CONSTRAINT `user_organizations_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_organizations` ADD CONSTRAINT `user_organizations_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `invitations` ADD CONSTRAINT `invitations_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `invitations` ADD CONSTRAINT `invitations_invited_by_id_fkey` FOREIGN KEY (`invited_by_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `channels` ADD CONSTRAINT `channels_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `channel_agents` ADD CONSTRAINT `channel_agents_channel_id_fkey` FOREIGN KEY (`channel_id`) REFERENCES `channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `channel_agents` ADD CONSTRAINT `channel_agents_user_organization_id_fkey` FOREIGN KEY (`user_organization_id`) REFERENCES `user_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `channel_sync_jobs` ADD CONSTRAINT `channel_sync_jobs_channel_id_fkey` FOREIGN KEY (`channel_id`) REFERENCES `channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `contacts` ADD CONSTRAINT `contacts_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `contact_channels` ADD CONSTRAINT `contact_channels_contact_id_fkey` FOREIGN KEY (`contact_id`) REFERENCES `contacts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `contact_channels` ADD CONSTRAINT `contact_channels_channel_id_fkey` FOREIGN KEY (`channel_id`) REFERENCES `channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversations` ADD CONSTRAINT `conversations_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversations` ADD CONSTRAINT `conversations_channel_id_fkey` FOREIGN KEY (`channel_id`) REFERENCES `channels`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversations` ADD CONSTRAINT `conversations_contact_id_fkey` FOREIGN KEY (`contact_id`) REFERENCES `contacts`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversations` ADD CONSTRAINT `conversations_assigned_to_id_fkey` FOREIGN KEY (`assigned_to_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversations` ADD CONSTRAINT `conversations_department_id_fkey` FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversations` ADD CONSTRAINT `conversations_active_agent_id_fkey` FOREIGN KEY (`active_agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversation_ratings` ADD CONSTRAINT `conversation_ratings_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversation_audit_logs` ADD CONSTRAINT `conversation_audit_logs_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `internal_notes` ADD CONSTRAINT `internal_notes_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `messages` ADD CONSTRAINT `messages_revoked_by_fkey` FOREIGN KEY (`revoked_by`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `messages` ADD CONSTRAINT `messages_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `messages` ADD CONSTRAINT `messages_sender_id_fkey` FOREIGN KEY (`sender_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `departments` ADD CONSTRAINT `departments_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `department_agents` ADD CONSTRAINT `department_agents_department_id_fkey` FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `department_agents` ADD CONSTRAINT `department_agents_user_organization_id_fkey` FOREIGN KEY (`user_organization_id`) REFERENCES `user_organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `chatbot_flows` ADD CONSTRAINT `chatbot_flows_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `chatbot_nodes` ADD CONSTRAINT `chatbot_nodes_flow_id_fkey` FOREIGN KEY (`flow_id`) REFERENCES `chatbot_flows`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `chatbot_flow_channels` ADD CONSTRAINT `chatbot_flow_channels_flow_id_fkey` FOREIGN KEY (`flow_id`) REFERENCES `chatbot_flows`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `chatbot_flow_channels` ADD CONSTRAINT `chatbot_flow_channels_channel_id_fkey` FOREIGN KEY (`channel_id`) REFERENCES `channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `quick_replies` ADD CONSTRAINT `quick_replies_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tags` ADD CONSTRAINT `tags_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversation_tags` ADD CONSTRAINT `conversation_tags_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversation_tags` ADD CONSTRAINT `conversation_tags_tag_id_fkey` FOREIGN KEY (`tag_id`) REFERENCES `tags`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `contact_tags` ADD CONSTRAINT `contact_tags_contact_id_fkey` FOREIGN KEY (`contact_id`) REFERENCES `contacts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `contact_tags` ADD CONSTRAINT `contact_tags_tag_id_fkey` FOREIGN KEY (`tag_id`) REFERENCES `tags`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `notifications` ADD CONSTRAINT `notifications_recipient_id_fkey` FOREIGN KEY (`recipient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `notifications` ADD CONSTRAINT `notifications_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `push_subscriptions` ADD CONSTRAINT `push_subscriptions_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `api_keys` ADD CONSTRAINT `api_keys_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `api_keys` ADD CONSTRAINT `api_keys_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agents` ADD CONSTRAINT `ai_agents_parent_agent_id_fkey` FOREIGN KEY (`parent_agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agents` ADD CONSTRAINT `ai_agents_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_tools` ADD CONSTRAINT `ai_tools_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_skills` ADD CONSTRAINT `ai_skills_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_skills` ADD CONSTRAINT `ai_skills_tool_id_fkey` FOREIGN KEY (`tool_id`) REFERENCES `ai_tools`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_skill_versions` ADD CONSTRAINT `ai_skill_versions_skill_id_fkey` FOREIGN KEY (`skill_id`) REFERENCES `ai_skills`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_skills` ADD CONSTRAINT `ai_agent_skills_agent_id_fkey` FOREIGN KEY (`agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_skills` ADD CONSTRAINT `ai_agent_skills_skill_id_fkey` FOREIGN KEY (`skill_id`) REFERENCES `ai_skills`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_channels` ADD CONSTRAINT `ai_agent_channels_agent_id_fkey` FOREIGN KEY (`agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_channels` ADD CONSTRAINT `ai_agent_channels_channel_id_fkey` FOREIGN KEY (`channel_id`) REFERENCES `channels`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_memories` ADD CONSTRAINT `ai_agent_memories_agent_id_fkey` FOREIGN KEY (`agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_memories` ADD CONSTRAINT `ai_agent_memories_contact_id_fkey` FOREIGN KEY (`contact_id`) REFERENCES `contacts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_runs` ADD CONSTRAINT `ai_agent_runs_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_runs` ADD CONSTRAINT `ai_agent_runs_agent_id_fkey` FOREIGN KEY (`agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_tool_calls` ADD CONSTRAINT `ai_tool_calls_run_id_fkey` FOREIGN KEY (`run_id`) REFERENCES `ai_agent_runs`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_handoffs` ADD CONSTRAINT `ai_agent_handoffs_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_handoffs` ADD CONSTRAINT `ai_agent_handoffs_from_agent_id_fkey` FOREIGN KEY (`from_agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_agent_handoffs` ADD CONSTRAINT `ai_agent_handoffs_to_agent_id_fkey` FOREIGN KEY (`to_agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_pending_actions` ADD CONSTRAINT `ai_pending_actions_agent_run_id_fkey` FOREIGN KEY (`agent_run_id`) REFERENCES `ai_agent_runs`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_pending_actions` ADD CONSTRAINT `ai_pending_actions_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ai_pending_actions` ADD CONSTRAINT `ai_pending_actions_agent_id_fkey` FOREIGN KEY (`agent_id`) REFERENCES `ai_agents`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `inbox_views` ADD CONSTRAINT `inbox_views_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `inbox_views` ADD CONSTRAINT `inbox_views_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversation_reads` ADD CONSTRAINT `conversation_reads_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `conversation_reads` ADD CONSTRAINT `conversation_reads_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `pipelines` ADD CONSTRAINT `pipelines_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `pipeline_stages` ADD CONSTRAINT `pipeline_stages_pipeline_id_fkey` FOREIGN KEY (`pipeline_id`) REFERENCES `pipelines`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cards` ADD CONSTRAINT `cards_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cards` ADD CONSTRAINT `cards_pipeline_id_fkey` FOREIGN KEY (`pipeline_id`) REFERENCES `pipelines`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cards` ADD CONSTRAINT `cards_stage_id_fkey` FOREIGN KEY (`stage_id`) REFERENCES `pipeline_stages`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cards` ADD CONSTRAINT `cards_contact_id_fkey` FOREIGN KEY (`contact_id`) REFERENCES `contacts`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cards` ADD CONSTRAINT `cards_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cards` ADD CONSTRAINT `cards_assigned_to_id_fkey` FOREIGN KEY (`assigned_to_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `products` ADD CONSTRAINT `products_organization_id_fkey` FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `automation_runs` ADD CONSTRAINT `automation_runs_automation_id_fkey` FOREIGN KEY (`automation_id`) REFERENCES `automations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
