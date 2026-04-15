CREATE TABLE IF NOT EXISTS `xyz_daily_rewards` (
  `id` int NOT NULL AUTO_INCREMENT,
  `identifier` varchar(90) NOT NULL,
  `reward_year` int NOT NULL,
  `reward_month` int NOT NULL,
  `claimed_days` longtext,
  `last_claim_day` int NOT NULL DEFAULT 0,
  `streak` int NOT NULL DEFAULT 0,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_reward_period` (`identifier`,`reward_year`,`reward_month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;