CREATE TABLE `md_result_module_call_log` (
	`module_call_id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Just the PK',
	`dice_result_id` INT(11) NOT NULL DEFAULT '',
	`module_name` VARCHAR(64) NOT NULL DEFAULT '0' COMMENT 'Name of the invoked module',
	`parameter_1` VARCHAR(128) NULL DEFAULT '0' COMMENT '1 module parameter value',
	`parameter_2` VARCHAR(128) NULL DEFAULT '0' COMMENT '2 module parameter value',
	`parameter_3` VARCHAR(128) NULL DEFAULT '0' COMMENT '3 module parameter value',
	`parameter_4` VARCHAR(128) NULL DEFAULT '0' COMMENT '4 module parameter value',
	`parameter_5` VARCHAR(128) NULL DEFAULT '0' COMMENT '5 module parameter value',
	PRIMARY KEY (`module_call_id`),
	INDEX `fk_md_result_module_call_log_dice_result` (`dice_result_id`),
	CONSTRAINT `fk_md_result_module_call_log_dice_result` FOREIGN KEY (`dice_result_id`) REFERENCES `md_result_picks` (`pick_id`) ON DELETE CASCADE
)
COMMENT='Log for the invoked module when a user diced a result'
COLLATE='utf8_general_ci'
ENGINE=InnoDB
;
