-- CreateTable
CREATE TABLE `ai_vector_entries` (
    `id` VARCHAR(191) NOT NULL,
    `owner_type` VARCHAR(191) NOT NULL,
    `owner_id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NULL,
    `agent_id` VARCHAR(191) NULL,
    `contact_id` VARCHAR(191) NULL,
    `content` TEXT NOT NULL,
    `embedding` LONGBLOB NOT NULL,
    `metadata` JSON NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `ai_vector_entries_owner_type_owner_id_idx`(`owner_type`, `owner_id`),
    INDEX `ai_vector_entries_conversation_id_idx`(`conversation_id`),
    INDEX `ai_vector_entries_agent_id_idx`(`agent_id`),
    INDEX `ai_vector_entries_contact_id_idx`(`contact_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
