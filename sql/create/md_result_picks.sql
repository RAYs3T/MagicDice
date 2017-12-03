CREATE TABLE `md_result_picks` (
	`result_pick_id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Just the PK for the table',
	`server_id` INT(11) NOT NULL COMMENT 'ID of the server. This might be usefull for web integration',
	`result_id` INT(11) NOT NULL COMMENT 'The id specified in the results configuration',
	`user_steam_id` BIGINT(20) NOT NULL COMMENT 'The steamId64 of the user that diced',
	`user_team` TINYINT(4) NOT NULL COMMENT 'The teamId of the user that diced',
	`dice_time` TIMESTAMP NOT NULL DEFAULT '',
	PRIMARY KEY (`result_pick_id`)
)
COMMENT='The choosen dice results for MagicDice'
COLLATE='utf8_general_ci'
ENGINE=InnoDB
;
