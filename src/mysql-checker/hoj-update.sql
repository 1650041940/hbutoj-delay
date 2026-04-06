USE `hoj`;

/*
* 2026.04.06 user_info增加年级列grade（如22/23/24...）
*/
DROP PROCEDURE
IF EXISTS user_info_Add_grade;
DELIMITER $$

CREATE PROCEDURE user_info_Add_grade ()
BEGIN

IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_schema = DATABASE()
		AND table_name = 'user_info'
		AND column_name = 'grade'
) THEN
	ALTER TABLE user_info ADD COLUMN grade varchar(20) DEFAULT NULL COMMENT '年级';
END
IF ; END$$

DELIMITER ;
CALL user_info_Add_grade ;

DROP PROCEDURE user_info_Add_grade;


/*
* 2026.04.06 新增团队获奖(team_award)及配置(team_award_config)
*/
DROP PROCEDURE
IF EXISTS Add_team_award_tables;
DELIMITER $$

CREATE PROCEDURE Add_team_award_tables ()
BEGIN

IF NOT EXISTS (
	SELECT 1 FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'team_award'
) THEN
	CREATE TABLE `team_award` (
	  `id` bigint(20) NOT NULL AUTO_INCREMENT,
	  `title` varchar(255) DEFAULT NULL COMMENT '标题',
	  `contest_name` varchar(255) DEFAULT NULL COMMENT '比赛名称',
	  `award` varchar(255) DEFAULT NULL COMMENT '奖项/等级',
	  `award_time` datetime DEFAULT NULL COMMENT '获奖时间',
	  `photo` varchar(255) DEFAULT NULL COMMENT '获奖照片URL',
	  `description` mediumtext COMMENT '描述',
	  `status` int(11) NOT NULL DEFAULT '0' COMMENT '0可见，1不可见',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
END
IF ;

IF NOT EXISTS (
	SELECT 1 FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'team_award_config'
) THEN
	CREATE TABLE `team_award_config` (
	  `id` bigint(20) NOT NULL COMMENT '固定为1',
	  `page_size` int(11) NOT NULL DEFAULT '6' COMMENT '每页数量',
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END
IF ;

IF EXISTS (
	SELECT 1 FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'team_award_config'
) THEN
	IF NOT EXISTS (SELECT 1 FROM team_award_config WHERE id = 1) THEN
		INSERT INTO team_award_config (id, page_size) VALUES (1, 6);
	END IF;
END IF;

END$$

DELIMITER ;
CALL Add_team_award_tables;

DROP PROCEDURE Add_team_award_tables;

/*
* 2026.04.05 增加题目难度分 difficulty_rating（用于做题 rating/推荐）
*/
DROP PROCEDURE IF EXISTS problem_Add_difficulty_rating;
DELIMITER $$

CREATE PROCEDURE problem_Add_difficulty_rating ()
BEGIN

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.`COLUMNS`
	WHERE table_schema = DATABASE()
	  AND table_name = 'problem'
	  AND column_name = 'difficulty_rating'
) THEN
	ALTER TABLE `problem` ADD COLUMN `difficulty_rating` INT(11) DEFAULT '0' COMMENT '题目难度分(用于做题rating/推荐，建议600~2600)' AFTER `difficulty`;
END IF;

END$$

DELIMITER ;
CALL problem_Add_difficulty_rating;
DROP PROCEDURE problem_Add_difficulty_rating;

/*
* 2026.04.05 增加 rating 相关表（老库增量升级）
*/
DROP PROCEDURE IF EXISTS Add_rating_tables;
DELIMITER $$

CREATE PROCEDURE Add_rating_tables ()
BEGIN

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'user_practice_rating'
) THEN
	CREATE TABLE `user_practice_rating` (
		`uid` varchar(32) NOT NULL COMMENT '用户uuid',
		`rating` int(11) NOT NULL DEFAULT '1200' COMMENT '做题rating',
		`solved_count` int(11) NOT NULL DEFAULT '0' COMMENT '已AC题目数（用于快速展示）',
		`last_calc_month` varchar(7) DEFAULT NULL COMMENT '最后一次月度计算月份 yyyy-MM',
		`gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
		`gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`uid`),
		CONSTRAINT `user_practice_rating_ibfk_1` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END IF;

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'user_practice_rating_history'
) THEN
	CREATE TABLE `user_practice_rating_history` (
		`id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
		`uid` varchar(32) NOT NULL COMMENT '用户uuid',
		`month` varchar(7) NOT NULL COMMENT '月份 yyyy-MM',
		`old_rating` int(11) NOT NULL,
		`delta` int(11) NOT NULL,
		`new_rating` int(11) NOT NULL,
		`solved_count` int(11) NOT NULL DEFAULT '0',
		`gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uid_month_unique` (`uid`,`month`),
		KEY `uid` (`uid`),
		CONSTRAINT `user_practice_rating_history_ibfk_1` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END IF;

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'user_contest_rating'
) THEN
	CREATE TABLE `user_contest_rating` (
		`uid` varchar(32) NOT NULL COMMENT '用户uuid',
		`rating` int(11) NOT NULL DEFAULT '1500' COMMENT '比赛rating',
		`contest_count` int(11) NOT NULL DEFAULT '0' COMMENT '计入rating的比赛次数',
		`gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
		`gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`uid`),
		CONSTRAINT `user_contest_rating_ibfk_1` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END IF;

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'user_contest_rating_history'
) THEN
	CREATE TABLE `user_contest_rating_history` (
		`id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
		`uid` varchar(32) NOT NULL COMMENT '用户uuid',
		`cid` bigint(20) unsigned NOT NULL COMMENT '比赛id',
		`old_rating` int(11) NOT NULL,
		`delta` int(11) NOT NULL,
		`new_rating` int(11) NOT NULL,
		`rank` int(11) DEFAULT NULL COMMENT '名次',
		`participants` int(11) DEFAULT NULL COMMENT '参赛人数',
		`gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uid_cid_unique` (`uid`,`cid`),
		KEY `uid` (`uid`),
		KEY `cid` (`cid`),
		CONSTRAINT `user_contest_rating_history_ibfk_1` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE,
		CONSTRAINT `user_contest_rating_history_ibfk_2` FOREIGN KEY (`cid`) REFERENCES `contest` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END IF;

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'problem_difficulty_history'
) THEN
	CREATE TABLE `problem_difficulty_history` (
		`id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
		`pid` bigint(20) unsigned NOT NULL COMMENT '题目id',
		`month` varchar(7) NOT NULL COMMENT '月份 yyyy-MM',
		`old_difficulty` int(11) NOT NULL,
		`delta` int(11) NOT NULL,
		`new_difficulty` int(11) NOT NULL,
		`attempted_users` int(11) NOT NULL DEFAULT '0',
		`accepted_users` int(11) NOT NULL DEFAULT '0',
		`avg_attempts` double DEFAULT NULL,
		`gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		UNIQUE KEY `pid_month_unique` (`pid`,`month`),
		KEY `pid` (`pid`),
		CONSTRAINT `problem_difficulty_history_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `problem` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END IF;

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.`TABLES`
	WHERE table_schema = DATABASE()
		AND table_name = 'contest_rating_event'
) THEN
	CREATE TABLE `contest_rating_event` (
		`cid` bigint(20) unsigned NOT NULL COMMENT '比赛id',
		`processed` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已处理',
		`participants` int(11) DEFAULT NULL COMMENT '参赛人数',
		`processed_time` datetime DEFAULT NULL COMMENT '处理时间',
		`gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
		`gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`cid`),
		CONSTRAINT `contest_rating_event_ibfk_1` FOREIGN KEY (`cid`) REFERENCES `contest` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END IF;

END$$

DELIMITER ;
CALL Add_rating_tables;
DROP PROCEDURE Add_rating_tables;

/*
* 2026.04.05 回填默认 rating 行（保证排行榜覆盖全部用户）
*/
INSERT IGNORE INTO user_practice_rating(uid, rating, solved_count, last_calc_month)
SELECT u.uuid, 1200, 0, NULL
FROM user_info u;

INSERT IGNORE INTO user_contest_rating(uid, rating, contest_count)
SELECT u.uuid, 1500, 0
FROM user_info u;

/*
* 2026.04.05 首次部署/升级后立刻回填做题 rating（避免等到下月定时任务才变化）
* 说明：仅对 last_calc_month IS NULL 的用户执行一次。
*/
DROP PROCEDURE IF EXISTS Init_practice_rating_once;
DELIMITER $$

CREATE PROCEDURE Init_practice_rating_once ()
BEGIN

IF EXISTS (
	SELECT 1
	FROM user_practice_rating
	WHERE last_calc_month IS NULL
	LIMIT 1
) THEN

	UPDATE user_practice_rating upr
	LEFT JOIN (
		SELECT uid,
			   solved_count,
			   LEAST(2600, GREATEST(600,
				 ROUND(0.9 * avg_w + 50.0 * (LOG(1 + solved_count) / LOG(2)))
			   )) AS rating
		FROM (
			SELECT uid,
				   COUNT(*) AS solved_count,
				   SUM(eff_difficulty * weight) / COUNT(*) AS avg_w
			FROM (
				SELECT uap.uid AS uid,
					   uap.pid AS pid,
					   (CASE
							WHEN p.difficulty_rating IS NULL OR p.difficulty_rating <= 0 THEN
								(CASE p.difficulty
									 WHEN 0 THEN 900
									 WHEN 1 THEN 1400
									 WHEN 2 THEN 1900
									 ELSE 1500
								 END)
							ELSE p.difficulty_rating
						END) AS eff_difficulty,
					   (1.0 / (1.0 + 0.35 * (GREATEST(COUNT(j.submit_id), 1) - 1))) AS weight
				FROM user_acproblem uap
						 INNER JOIN problem p ON p.id = uap.pid
						 INNER JOIN judge j ON j.uid = uap.uid
					AND j.pid = uap.pid
					AND j.cid = 0
					AND j.submit_id <= uap.submit_id
				GROUP BY uap.uid, uap.pid
			) per_problem
			GROUP BY uid
		) per_user
	) calc ON calc.uid = upr.uid
	SET upr.solved_count = IFNULL(calc.solved_count, 0),
		upr.rating = IFNULL(calc.rating, 1200),
		upr.last_calc_month = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m')
	WHERE upr.last_calc_month IS NULL;

END IF;

END$$

DELIMITER ;
CALL Init_practice_rating_once;
DROP PROCEDURE Init_practice_rating_once;

/*
* 2026.04.05 新用户自动初始化 rating（避免新增用户不出现在排行榜）
*/
DROP PROCEDURE IF EXISTS Add_rating_triggers;
DELIMITER $$

CREATE PROCEDURE Add_rating_triggers ()
BEGIN

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.TRIGGERS
	WHERE trigger_schema = DATABASE()
		AND trigger_name = 'trg_user_info_after_insert_practice_rating'
) THEN
	SET @sql := '
		CREATE TRIGGER trg_user_info_after_insert_practice_rating
		AFTER INSERT ON user_info
		FOR EACH ROW
		BEGIN
			INSERT IGNORE INTO user_practice_rating(uid, rating, solved_count, last_calc_month)
			VALUES (NEW.uuid, 1200, 0, NULL);
		END
	';
	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END IF;

IF NOT EXISTS (
	SELECT 1
	FROM information_schema.TRIGGERS
	WHERE trigger_schema = DATABASE()
		AND trigger_name = 'trg_user_info_after_insert_contest_rating'
) THEN
	SET @sql := '
		CREATE TRIGGER trg_user_info_after_insert_contest_rating
		AFTER INSERT ON user_info
		FOR EACH ROW
		BEGIN
			INSERT IGNORE INTO user_contest_rating(uid, rating, contest_count)
			VALUES (NEW.uuid, 1500, 0);
		END
	';
	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END IF;

END$$

DELIMITER ;
CALL Add_rating_triggers;
DROP PROCEDURE Add_rating_triggers;

/*
* 2021.08.07 修改OI题目得分在OI排行榜新计分字段 分数计算为：OI题目总得分*0.1+2*题目难度
*/
DROP PROCEDURE
IF EXISTS judge_Add_oi_rank_score;
DELIMITER $$
 
CREATE PROCEDURE judge_Add_oi_rank_score ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'judge'
	AND column_name = 'oi_rank'
) THEN
	ALTER TABLE judge ADD COLUMN oi_rank INT(11) NULL COMMENT '该题在OI排行榜的分数';
END
IF ; END$$
 
DELIMITER ; 
CALL judge_Add_oi_rank_score ;

DROP PROCEDURE judge_Add_oi_rank_score;

/*
* 2021.08.08 增加vjudge_submit_id在vjudge判题获取提交id后存储，当等待结果超时，下次重判时可用该提交id直接获取结果。
			 同时vjudge_username、vjudge_password分别记录提交账号密码
*/
DROP PROCEDURE
IF EXISTS judge_Add_vjudge_submit_id;
DELIMITER $$
 
CREATE PROCEDURE judge_Add_vjudge_submit_id ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'judge'
	AND column_name = 'vjudge_submit_id'
) THEN
	ALTER TABLE judge ADD COLUMN vjudge_submit_id BIGINT UNSIGNED NULL  COMMENT 'vjudge判题在其它oj的提交id';
	ALTER TABLE judge ADD COLUMN vjudge_username VARCHAR(255) NULL  COMMENT 'vjudge判题在其它oj的提交用户名';
	ALTER TABLE judge ADD COLUMN vjudge_password VARCHAR(255) NULL  COMMENT 'vjudge判题在其它oj的提交账号密码';
END
IF ; END$$
 
DELIMITER ; 
CALL judge_Add_vjudge_submit_id ;

DROP PROCEDURE judge_Add_vjudge_submit_id;


/*
* 2021.09.21 比赛增加打印、账号限制的功能，增大真实姓名长度
*/

DROP PROCEDURE
IF EXISTS contest_Add_print_and_limit;
DELIMITER $$
 
CREATE PROCEDURE contest_Add_print_and_limit ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest'
	AND column_name = 'open_print'
) THEN
	ALTER TABLE contest ADD COLUMN open_print tinyint(1) DEFAULT '0' COMMENT '是否打开打印功能';
    ALTER TABLE contest ADD COLUMN open_account_limit tinyint(1) DEFAULT '0' COMMENT '是否开启账号限制';
    ALTER TABLE contest ADD COLUMN account_limit_rule mediumtext COMMENT '账号限制规则';
	ALTER TABLE `hoj`.`user_info` CHANGE `realname` `realname` VARCHAR(100) CHARSET utf8 COLLATE utf8_general_ci NULL  COMMENT '真实姓名';
END
IF ; END$$
 
DELIMITER ; 
CALL contest_Add_print_and_limit ;

DROP PROCEDURE contest_Add_print_and_limit;



DROP PROCEDURE
IF EXISTS Add_contest_print;
DELIMITER $$
 
CREATE PROCEDURE Add_contest_print ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest_print'
) THEN
	CREATE TABLE `contest_print` (
	  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
	  `username` varchar(100) DEFAULT NULL,
	  `realname` varchar(100) DEFAULT NULL,
	  `cid` bigint(20) unsigned DEFAULT NULL,
	  `content` longtext NOT NULL,
	  `status` int(11) DEFAULT '0',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  KEY `cid` (`cid`),
	  KEY `username` (`username`),
	  CONSTRAINT `contest_print_ibfk_1` FOREIGN KEY (`cid`) REFERENCES `contest` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `contest_print_ibfk_2` FOREIGN KEY (`username`) REFERENCES `user_info` (`username`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END
IF ; END$$
 
DELIMITER ; 
CALL Add_contest_print ;

DROP PROCEDURE Add_contest_print;


/*
* 2021.10.04 增加站内消息系统，包括评论我的、收到的赞、回复我的、系统通知、我的消息五个模块
*/

DROP PROCEDURE
IF EXISTS Add_msg_table;
DELIMITER $$
 
CREATE PROCEDURE Add_msg_table ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'msg_remind'
) THEN
	CREATE TABLE `admin_sys_notice` (
	  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
	  `title` varchar(255) DEFAULT NULL COMMENT '标题',
	  `content` longtext COMMENT '内容',
	  `type` varchar(255) DEFAULT NULL COMMENT '发给哪些用户类型',
	  `state` tinyint(1) DEFAULT '0' COMMENT '是否已拉取给用户',
	  `recipient_id` varchar(32) DEFAULT NULL COMMENT '接受通知的用户id',
	  `admin_id` varchar(32) DEFAULT NULL COMMENT '发送通知的管理员id',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
	  PRIMARY KEY (`id`),
	  KEY `recipient_id` (`recipient_id`),
	  KEY `admin_id` (`admin_id`),
	  CONSTRAINT `admin_sys_notice_ibfk_1` FOREIGN KEY (`recipient_id`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `admin_sys_notice_ibfk_2` FOREIGN KEY (`admin_id`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	
	CREATE TABLE `msg_remind` (
	  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
	  `action` varchar(255) NOT NULL COMMENT '动作类型，如点赞讨论帖Like_Post、点赞评论Like_Discuss、评论Discuss、回复Reply等',
	  `source_id` int(10) unsigned DEFAULT NULL COMMENT '消息来源id，讨论id或比赛id',
	  `source_type` varchar(255) DEFAULT NULL COMMENT '事件源类型：''Discussion''、''Contest''等',
	  `source_content` varchar(255) DEFAULT NULL COMMENT '事件源的内容，比如回复的内容，评论的帖子标题等等',
	  `quote_id` int(10) unsigned DEFAULT NULL COMMENT '事件引用上一级评论或回复id',
	  `quote_type` varchar(255) DEFAULT NULL COMMENT '事件引用上一级的类型：Comment、Reply',
	  `url` varchar(255) DEFAULT NULL COMMENT '事件所发生的地点链接 url',
	  `state` tinyint(1) DEFAULT '0' COMMENT '是否已读',
	  `sender_id` varchar(32) DEFAULT NULL COMMENT '操作者的id',
	  `recipient_id` varchar(32) DEFAULT NULL COMMENT '接受消息的用户id',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
	  PRIMARY KEY (`id`),
	  KEY `sender_id` (`sender_id`),
	  KEY `recipient_id` (`recipient_id`),
	  CONSTRAINT `msg_remind_ibfk_1` FOREIGN KEY (`sender_id`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `msg_remind_ibfk_2` FOREIGN KEY (`recipient_id`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	
	CREATE TABLE `user_sys_notice` (
	  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
	  `sys_notice_id` bigint(20) unsigned DEFAULT NULL COMMENT '系统通知的id',
	  `recipient_id` varchar(32) DEFAULT NULL COMMENT '接受通知的用户id',
	  `type` varchar(255) DEFAULT NULL COMMENT '消息类型，系统通知sys、我的信息mine',
	  `state` tinyint(1) DEFAULT '0' COMMENT '是否已读',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '读取时间',
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  KEY `sys_notice_id` (`sys_notice_id`),
	  KEY `recipient_id` (`recipient_id`),
	  CONSTRAINT `user_sys_notice_ibfk_1` FOREIGN KEY (`sys_notice_id`) REFERENCES `admin_sys_notice` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `user_sys_notice_ibfk_2` FOREIGN KEY (`recipient_id`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END
IF ; END$$
 
DELIMITER ; 
CALL Add_msg_table;

DROP PROCEDURE Add_msg_table;




/*
* 2021.10.06 user_info增加性别列gender 比赛榜单用户名称显示可选
			 
*/
DROP PROCEDURE
IF EXISTS user_info_Add_gender;
DELIMITER $$
 
CREATE PROCEDURE user_info_Add_gender ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'user_info'
	AND column_name = 'gender'
) THEN
	ALTER TABLE user_info ADD COLUMN gender varchar(20) DEFAULT 'secrecy'  NOT NULL COMMENT '性别';
END
IF ; END$$
 
DELIMITER ; 
CALL user_info_Add_gender ;

DROP PROCEDURE user_info_Add_gender;


DROP PROCEDURE
IF EXISTS contest_Add_rank_show_name;
DELIMITER $$
 
CREATE PROCEDURE contest_Add_rank_show_name ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest'
	AND column_name = 'rank_show_name'
) THEN
	ALTER TABLE contest ADD COLUMN rank_show_name varchar(20) DEFAULT 'username' COMMENT '排行榜显示（username、nickname、realname）';
END
IF ; END$$
 
DELIMITER ; 
CALL contest_Add_rank_show_name ;

DROP PROCEDURE contest_Add_rank_show_name;

/*
* 2021.10.08 user_info增加性别列gender 比赛榜单用户名称显示可选
			 
*/
DROP PROCEDURE
IF EXISTS contest_problem_Add_color;
DELIMITER $$
 
CREATE PROCEDURE contest_problem_Add_color ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest_problem'
	AND column_name = 'color'
) THEN
	ALTER TABLE contest_problem ADD COLUMN `color` VARCHAR(255) NULL   COMMENT '气球颜色';
	ALTER TABLE user_info ADD COLUMN `title_name` VARCHAR(255) NULL   COMMENT '头衔、称号';
	ALTER TABLE user_info ADD COLUMN `title_color` VARCHAR(255) NULL   COMMENT '头衔、称号的颜色';
END
IF ; END$$
 
DELIMITER ; 
CALL contest_problem_Add_color ;

DROP PROCEDURE contest_problem_Add_color;


/*
* 2021.11.17 judge_server增加cf_submittable控制单台判题机只能一个账号提交CF
			 
*/
DROP PROCEDURE
IF EXISTS judge_server_Add_cf_submittable;
DELIMITER $$
 
CREATE PROCEDURE judge_serverm_Add_cf_submittable ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'judge_server'
	AND column_name = 'cf_submittable'
) THEN
	ALTER TABLE `hoj`.`judge_server`  ADD COLUMN `cf_submittable` BOOLEAN DEFAULT 1  NULL  COMMENT '是否可提交CF';
END
IF ; END$$
 
DELIMITER ; 
CALL judge_serverm_Add_cf_submittable ;

DROP PROCEDURE judge_serverm_Add_cf_submittable;



/*
* 2021.11.29 增加训练模块
*/

DROP PROCEDURE
IF EXISTS Add_training_table;
DELIMITER $$
 
CREATE PROCEDURE Add_training_table ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'training'
) THEN
	
	CREATE TABLE `training` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `title` varchar(255) DEFAULT NULL COMMENT '训练题单名称',
	  `description` longtext COMMENT '训练题单简介',
	  `author` varchar(255) NOT NULL COMMENT '训练题单创建者用户名',
	  `auth` varchar(255) NOT NULL COMMENT '训练题单权限类型：Public、Private',
	  `private_pwd` varchar(255) DEFAULT NULL COMMENT '训练题单权限为Private时的密码',
	  `rank` int DEFAULT '0' COMMENT '编号，升序',
	  `status` tinyint(1) DEFAULT '1' COMMENT '是否可用',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;


	CREATE TABLE `training_category` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `name` varchar(255) DEFAULT NULL,
	  `color` varchar(255) DEFAULT NULL,
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;

	CREATE TABLE `training_problem` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `tid` bigint unsigned NOT NULL COMMENT '训练id',
	  `pid` bigint unsigned NOT NULL COMMENT '题目id',
	  `rank` int DEFAULT '0',
	  `display_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  KEY `tid` (`tid`),
	  KEY `pid` (`pid`),
	  KEY `display_id` (`display_id`),
	  CONSTRAINT `training_problem_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `training` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_problem_ibfk_2` FOREIGN KEY (`pid`) REFERENCES `problem` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_problem_ibfk_3` FOREIGN KEY (`display_id`) REFERENCES `problem` (`problem_id`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;

	CREATE TABLE `training_record` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `tid` bigint unsigned NOT NULL,
	  `tpid` bigint unsigned NOT NULL,
	  `pid` bigint unsigned NOT NULL,
	  `uid` varchar(255) NOT NULL,
	  `submit_id` bigint unsigned NOT NULL,
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  KEY `tid` (`tid`),
	  KEY `tpid` (`tpid`),
	  KEY `pid` (`pid`),
	  KEY `uid` (`uid`),
	  KEY `submit_id` (`submit_id`),
	  CONSTRAINT `training_record_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `training` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_record_ibfk_2` FOREIGN KEY (`tpid`) REFERENCES `training_problem` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_record_ibfk_3` FOREIGN KEY (`pid`) REFERENCES `problem` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_record_ibfk_4` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_record_ibfk_5` FOREIGN KEY (`submit_id`) REFERENCES `judge` (`submit_id`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;


	CREATE TABLE `training_register` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `tid` bigint unsigned NOT NULL COMMENT '训练id',
	  `uid` varchar(255) NOT NULL COMMENT '用户id',
	  `status` tinyint(1) DEFAULT '1' COMMENT '是否可用',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  KEY `tid` (`tid`),
	  KEY `uid` (`uid`),
	  CONSTRAINT `training_register_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `training` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_register_ibfk_2` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;


	CREATE TABLE `mapping_training_category` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `tid` bigint unsigned NOT NULL,
	  `cid` bigint unsigned NOT NULL,
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  KEY `tid` (`tid`),
	  KEY `cid` (`cid`),
	  CONSTRAINT `mapping_training_category_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `training` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `mapping_training_category_ibfk_2` FOREIGN KEY (`cid`) REFERENCES `training_category` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	
	ALTER TABLE `hoj`.`judge` ADD COLUMN `tid` BIGINT UNSIGNED NULL AFTER `cpid`,
	ADD FOREIGN KEY (`tid`) REFERENCES `hoj`.`training`(`id`) ON UPDATE CASCADE ON DELETE CASCADE;
END
IF ; END$$
 
DELIMITER ; 
CALL Add_training_table;

DROP PROCEDURE Add_training_table;


/*
* 2021.12.05 contest增加auto_real_rank比赛结束是否自动解除封榜,自动转换成真实榜单
			 
*/
DROP PROCEDURE
IF EXISTS contest_Add_auto_real_rank;
DELIMITER $$
 
CREATE PROCEDURE contest_Add_auto_real_rank()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest'
	AND column_name = 'auto_real_rank'
) THEN
	ALTER TABLE `hoj`.`contest`  ADD COLUMN `auto_real_rank` BOOLEAN DEFAULT 1  NULL  COMMENT '比赛结束是否自动解除封榜,自动转换成真实榜单';
	DROP TABLE `hoj`.`training_problem`;
	DROP TABLE `hoj`.`training_record`;
	CREATE TABLE `training_problem` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `tid` bigint unsigned NOT NULL COMMENT '训练id',
	  `pid` bigint unsigned NOT NULL COMMENT '题目id',
	  `rank` int DEFAULT '0',
	  `display_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  KEY `tid` (`tid`),
	  KEY `pid` (`pid`),
	  KEY `display_id` (`display_id`),
	  CONSTRAINT `training_problem_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `training` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_problem_ibfk_2` FOREIGN KEY (`pid`) REFERENCES `problem` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_problem_ibfk_3` FOREIGN KEY (`display_id`) REFERENCES `problem` (`problem_id`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;

	CREATE TABLE `training_record` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `tid` bigint unsigned NOT NULL,
	  `tpid` bigint unsigned NOT NULL,
	  `pid` bigint unsigned NOT NULL,
	  `uid` varchar(255) NOT NULL,
	  `submit_id` bigint unsigned NOT NULL,
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  KEY `tid` (`tid`),
	  KEY `tpid` (`tpid`),
	  KEY `pid` (`pid`),
	  KEY `uid` (`uid`),
	  KEY `submit_id` (`submit_id`),
	  CONSTRAINT `training_record_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `training` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_record_ibfk_2` FOREIGN KEY (`tpid`) REFERENCES `training_problem` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_record_ibfk_3` FOREIGN KEY (`pid`) REFERENCES `problem` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_record_ibfk_4` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `training_record_ibfk_5` FOREIGN KEY (`submit_id`) REFERENCES `judge` (`submit_id`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END
IF ; END$$
 
DELIMITER ; 
CALL contest_Add_auto_real_rank; 

DROP PROCEDURE contest_Add_auto_real_rank;




/*
* 2021.12.07 contest增加打星账号列表、是否开放榜单
			 
*/
DROP PROCEDURE
IF EXISTS contest_Add_star_account_And_open_rank;
DELIMITER $$
 
CREATE PROCEDURE contest_Add_star_account_And_open_rank ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest'
	AND column_name = 'star_account'
) THEN
	ALTER TABLE `hoj`.`contest`  ADD COLUMN `star_account` mediumtext COMMENT '打星用户列表';
	ALTER TABLE `hoj`.`contest`  ADD COLUMN `open_rank` BOOLEAN DEFAULT 0 NULL  COMMENT '是否开放赛外榜单';
END
IF ; END$$
 
DELIMITER ; 
CALL contest_Add_star_account_And_open_rank ;

DROP PROCEDURE contest_Add_star_account_And_open_rank;



/*
* 2021.12.19 judge表删除tid
			 
*/
DROP PROCEDURE
IF EXISTS judge_Delete_tid;
DELIMITER $$
 
CREATE PROCEDURE judge_Delete_tid ()
BEGIN
 
IF EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'judge'
	AND column_name = 'tid'
) THEN
	ALTER TABLE `hoj`.`judge` DROP foreign key `judge_ibfk_4`;
	ALTER TABLE `hoj`.`judge` DROP COLUMN `tid`;
END
IF ; END$$
 
DELIMITER ; 
CALL judge_Delete_tid ;

DROP PROCEDURE judge_Delete_tid;


/*
* 2022.01.03 problem表增加mode，user_extra_file，judge_extra_file用于区别普通判题、特殊判题、交互判题
			 
*/
DROP PROCEDURE
IF EXISTS problem_Add_judge_mode;
DELIMITER $$
 
CREATE PROCEDURE problem_Add_judge_mode ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'problem'
	AND column_name = 'judge_mode'
) THEN
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `judge_mode` varchar(255) DEFAULT 'default' COMMENT '题目评测模式,default、spj、interactive';
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `user_extra_file` mediumtext DEFAULT NULL COMMENT '题目评测时用户程序的额外额外文件 json key:name value:content';
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `judge_extra_file` mediumtext DEFAULT NULL COMMENT '题目评测时交互或特殊程序的额外额外文件 json key:name value:content';
END
IF ; END$$
 
DELIMITER ; 
CALL problem_Add_judge_mode ;

DROP PROCEDURE problem_Add_judge_mode;


/*
* 2022.03.02 contest表增加oi_rank_score_type
			 
*/
DROP PROCEDURE
IF EXISTS contest_Add_oi_rank_score_type;
DELIMITER $$
 
CREATE PROCEDURE contest_Add_oi_rank_score_type ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest'
	AND column_name = 'oi_rank_score_type'
) THEN
	ALTER TABLE `hoj`.`contest`  ADD COLUMN `oi_rank_score_type` varchar(255) DEFAULT 'Recent' COMMENT 'oi排行榜得分方式，Recent、Highest';
END
IF ; END$$
 
DELIMITER ; 
CALL contest_Add_oi_rank_score_type ;

DROP PROCEDURE contest_Add_oi_rank_score_type;


/*
* 2022.03.28 增加团队模块
			 
*/
DROP PROCEDURE
IF EXISTS add_group;
DELIMITER $$
 
CREATE PROCEDURE add_group ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'group'
) THEN
	CREATE TABLE `group` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `avatar` varchar(255) DEFAULT NULL COMMENT '头像地址',
	  `name` varchar(25) DEFAULT NULL COMMENT '团队名称',
	  `short_name` varchar(10) DEFAULT NULL COMMENT '团队简称，创建题目时题号自动添加的前缀',
	  `brief` varchar(50) COMMENT '团队简介',
	  `description` longtext COMMENT '团队介绍',
	  `owner` varchar(255) NOT NULL COMMENT '团队拥有者用户名',
	  `uid` varchar(32) NOT NULL COMMENT '团队拥有者用户id',
	  `auth` int(11) NOT NULL COMMENT '0为Public，1为Protected，2为Private',
	  `visible` tinyint(1) DEFAULT '1' COMMENT '是否可见',
	  `status` tinyint(1) DEFAULT '0' COMMENT '是否封禁',
	  `code` varchar(6) DEFAULT NULL COMMENT '邀请码',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  UNIQUE KEY `NAME_UNIQUE` (`name`),
	  UNIQUE KEY `short_name` (`short_name`),
	  CONSTRAINT `group_ibfk_1` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8;

	CREATE TABLE `group_member` (
	  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `gid` bigint unsigned NOT NULL COMMENT '团队id',
	  `uid` varchar(32) NOT NULL COMMENT '用户id',
	  `auth` int(11) DEFAULT '1' COMMENT '1未审批，2拒绝，3普通成员，4团队管理员，5团队拥有者',
	  `reason` varchar(100) DEFAULT NULL COMMENT '申请理由',
	  `gmt_create` datetime DEFAULT CURRENT_TIMESTAMP,
	  `gmt_modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`),
	  UNIQUE KEY `gid_uid_unique` (`gid`, `uid`),
	  KEY `gid` (`gid`),
	  KEY `uid` (`uid`),
	  CONSTRAINT `group_member_ibfk_1` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	  CONSTRAINT `group_member_ibfk_2` FOREIGN KEY (`uid`) REFERENCES `user_info` (`uuid`) ON DELETE CASCADE ON UPDATE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	
	ALTER TABLE `hoj`.`announcement`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`announcement` ADD CONSTRAINT `announcement_ibfk_2` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
	

	ALTER TABLE `hoj`.`contest`  ADD COLUMN `is_group` tinyint(1) DEFAULT '0';
	ALTER TABLE `hoj`.`contest`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`contest` ADD CONSTRAINT `contest_ibfk_2` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
	
	ALTER TABLE `hoj`.`judge`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`judge` ADD CONSTRAINT `judge_ibfk_4` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
	
	
	ALTER TABLE `hoj`.`discussion`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`discussion` ADD CONSTRAINT `discussion_ibfk_3` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
	
	ALTER TABLE `hoj`.`file`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`file` ADD  CONSTRAINT `file_ibfk_2` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
	
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `is_group` tinyint(1) DEFAULT '0';
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`problem` ADD CONSTRAINT `problem_ibfk_2` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

	ALTER TABLE `hoj`.`tag`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`tag` ADD CONSTRAINT `tag_ibfk_1` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
	

	ALTER TABLE `hoj`.`training`  ADD COLUMN `is_group` tinyint(1) DEFAULT '0';
	ALTER TABLE `hoj`.`training`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`training` ADD CONSTRAINT `training_ibfk_1` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
	
	ALTER TABLE `hoj`.`training_category`  ADD COLUMN `gid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`training_category` ADD CONSTRAINT `training_category_ibfk_1` FOREIGN KEY (`gid`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
	
	insert  into `auth`(`id`,`name`,`permission`,`status`,`gmt_create`,`gmt_modified`) values (13,'group','group_add',0,'2022-03-11 13:36:55','2022-03-11 13:36:55'),
	(14,'group','group_del',0,'2022-03-11 13:36:55','2022-03-11 13:36:55');
	
	insert  into `role_auth`(`auth_id`,`role_id`,`gmt_create`,`gmt_modified`) values (13,1000,'2021-06-12 23:16:58','2021-06-12 23:16:58'),(13,1001,'2021-06-12 23:16:58','2021-06-12 23:16:58'),
	(13,1002,'2021-06-12 23:16:58','2021-06-12 23:16:58'),(13,1008,'2021-06-12 23:16:58','2021-06-12 23:16:58'),(14,1000,'2021-06-12 23:16:58','2021-06-12 23:16:58'),
	(14,1001,'2021-06-12 23:16:58','2021-06-12 23:16:58'),(14,1002,'2021-06-12 23:16:58','2021-06-12 23:16:58'),(14,1008,'2021-06-12 23:16:58','2021-06-12 23:16:58');
	
END
IF ; END$$
 
DELIMITER ; 
CALL add_group ;

DROP PROCEDURE add_group;



/*
* 2022.04.13 problem表增加apply_public_progress
			 
*/
DROP PROCEDURE
IF EXISTS problem_Add_apply_public_progress;
DELIMITER $$
 
CREATE PROCEDURE problem_Add_apply_public_progress ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'problem'
	AND column_name = 'apply_public_progress'
) THEN
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `apply_public_progress` int(11) DEFAULT NULL COMMENT '申请公开的进度：null为未申请，1为申请中，2为申请通过，3为申请拒绝';
END
IF ; END$$
 
DELIMITER ; 
CALL problem_Add_apply_public_progress ;

DROP PROCEDURE problem_Add_apply_public_progress;



/*
* 2022.06.26 给指定表的字段修改字符集为utf8mb4
			 
*/
DROP PROCEDURE
IF EXISTS table_Change_utf8mb4;
DELIMITER $$
 
CREATE PROCEDURE table_Change_utf8mb4 ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'announcement'
	AND column_name = 'title' AND CHARACTER_SET_NAME = 'utf8mb4'
) THEN
	ALTER TABLE hoj.announcement MODIFY COLUMN `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;	
	ALTER TABLE hoj.announcement MODIFY COLUMN `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.admin_sys_notice MODIFY COLUMN `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.admin_sys_notice MODIFY COLUMN `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.contest MODIFY COLUMN `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.contest MODIFY COLUMN `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.contest_explanation MODIFY COLUMN `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.contest_problem MODIFY COLUMN `display_title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.contest_print MODIFY COLUMN `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.discussion MODIFY COLUMN `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.discussion MODIFY COLUMN `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.discussion MODIFY COLUMN `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.discussion_report MODIFY COLUMN `content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.group MODIFY COLUMN `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.group_member MODIFY COLUMN `reason` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.language MODIFY COLUMN `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.msg_remind MODIFY COLUMN `source_content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.problem MODIFY COLUMN `source` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.problem MODIFY COLUMN `input` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.problem MODIFY COLUMN `output` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.problem MODIFY COLUMN `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.problem MODIFY COLUMN `hint` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.problem MODIFY COLUMN `spj_code` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.problem MODIFY COLUMN `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.reply MODIFY COLUMN `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.training MODIFY COLUMN `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.training MODIFY COLUMN `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.user_info MODIFY COLUMN `signature` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.judge MODIFY COLUMN `code` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	ALTER TABLE hoj.comment MODIFY COLUMN `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

END
IF ; END$$
 
DELIMITER ; 
CALL table_Change_utf8mb4 ;

DROP PROCEDURE table_Change_utf8mb4;


/*
* 2022.08.05 题目标签添加分类
			 
*/
DROP PROCEDURE
IF EXISTS problem_tag_Add_classification;
DELIMITER $$
 
CREATE PROCEDURE problem_tag_Add_classification ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'tag'
	AND column_name = 'tcid'
) THEN
	CREATE TABLE `tag_classification`  (
	  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
	  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '标签分类名称',
	  `oj` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '标签分类所属oj',
	  `gmt_create` datetime NULL DEFAULT NULL,
	  `gmt_modified` datetime NULL DEFAULT NULL,
	  `rank` int(10) UNSIGNED ZEROFILL NULL DEFAULT NULL COMMENT '标签分类优先级 越小越高',
	  PRIMARY KEY (`id`) USING BTREE
	) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;
	
	ALTER TABLE `hoj`.`tag`  ADD COLUMN `tcid` bigint(20) unsigned DEFAULT NULL;
	ALTER TABLE `hoj`.`tag` ADD CONSTRAINT `tag_ibfk_2` FOREIGN KEY (`tcid`) REFERENCES `tag_classification` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
	
END
IF ; END$$
 
DELIMITER ; 
CALL problem_tag_Add_classification ;

DROP PROCEDURE problem_tag_Add_classification;


/*
* 2022.08.21 提交评测增加人工评测标记
			 
*/
DROP PROCEDURE
IF EXISTS judge_tag_Add_is_manual;
DELIMITER $$
 
CREATE PROCEDURE judge_tag_Add_is_manual ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'judge'
	AND column_name = 'is_manual'
) THEN
	
	ALTER TABLE `hoj`.`judge`  ADD COLUMN `is_manual` tinyint(1) DEFAULT '0' COMMENT '是否为人工评测';
	
END
IF ; END$$
 
DELIMITER ; 
CALL judge_tag_Add_is_manual ;

DROP PROCEDURE judge_tag_Add_is_manual;

/*
* 2022.08.30 OI题目增加subtask
			 
*/
DROP PROCEDURE
IF EXISTS add_Problem_Subtask;
DELIMITER $$
 
CREATE PROCEDURE add_Problem_Subtask ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'problem'
	AND column_name = 'judge_case_mode'
) THEN
	
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `judge_case_mode` varchar(255) DEFAULT 'default' COMMENT '题目样例评测模式,default,subtask_lowest,subtask_average';
	ALTER TABLE `hoj`.`problem_case`  ADD COLUMN `group_num` int(11) DEFAULT '1' COMMENT 'subtask分组的编号';
	ALTER TABLE `hoj`.`judge_case`  ADD COLUMN `group_num` int(11) DEFAULT NULL COMMENT 'subtask分组的组号';
	ALTER TABLE `hoj`.`judge_case`  ADD COLUMN `seq` int(11) DEFAULT NULL COMMENT '排序';
	ALTER TABLE `hoj`.`judge_case`  ADD COLUMN `mode` varchar(255) DEFAULT 'default' COMMENT 'default,subtask_lowest,subtask_average';
	
END
IF ; END$$
 
DELIMITER ; 
CALL add_Problem_Subtask ;

DROP PROCEDURE add_Problem_Subtask;



/*
* 2022.10.02  比赛增加奖项排名显示
			 
*/
DROP PROCEDURE
IF EXISTS add_Contest_Award;
DELIMITER $$
 
CREATE PROCEDURE add_Contest_Award ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest'
	AND column_name = 'award_type'
) THEN
	
	ALTER TABLE `hoj`.`contest`  ADD COLUMN `award_type` int(11) DEFAULT '0' COMMENT '奖项类型：0(不设置),1(设置占比),2(设置人数)';
	ALTER TABLE `hoj`.`contest`  ADD COLUMN `award_config` text DEFAULT NULL COMMENT '奖项配置 json';
	
END
IF ; END$$
 
DELIMITER ; 
CALL add_Contest_Award ;

DROP PROCEDURE add_Contest_Award;

/*
* 2022.11.23  调整增加C++语言
			 
*/
DROP PROCEDURE
IF EXISTS add_Language_Change;
DELIMITER $$
 
CREATE PROCEDURE add_Language_Change ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'language'
	AND column_name = 'seq'
) THEN
	
	ALTER TABLE `hoj`.`language`  ADD COLUMN `seq` int(11) DEFAULT '0' COMMENT '语言排序';
	UPDATE `language` set `seq` = 5, `description` = 'G++ 9.4.0' WHERE (`name` = 'C++ With O2' OR `name` = 'C++') AND `oj`='ME';
	UPDATE `language` set `seq` = 10, `description` = 'GCC 9.4.0' WHERE (`name` = 'C With O2' OR `name` = 'C') AND `oj`='ME';
	UPDATE `language` set `description` = 'Golang 1.19' WHERE `name`='Golang' AND `oj`='ME';
	INSERT INTO `language`(`content_type`,`description`,`name`,`compile_command`,`template`, `code_template`, `is_spj`, `oj`, `seq`) VALUES ('text/x-c++src', 'G++ 9.4.0', 'C++ 17', '/usr/bin/g++ -DONLINE_JUDGE -w -fmax-errors=1 -std=c++17 {src_path} -lm -o {exe_path}', '#include<iostream>\r\nusing namespace std;\r\nint main()\r\n{\r\n    int a,b;\r\n    cin >> a >> b;\r\n    cout << a + b;\r\n    return 0;\r\n}', '//PREPEND BEGIN\r\n#include <iostream>\r\nusing namespace std;\r\n//PREPEND END\r\n\r\n//TEMPLATE BEGIN\r\nint add(int a, int b) {\r\n  // Please fill this blank\r\n  return ___________;\r\n}\r\n//TEMPLATE END\r\n\r\n//APPEND BEGIN\r\nint main() {\r\n  cout << add(1, 2);\r\n  return 0;\r\n}\r\n//APPEND END', 0, 'ME', 5);
	INSERT INTO `language`(`content_type`,`description`,`name`,`compile_command`,`template`, `code_template`, `is_spj`, `oj`, `seq`) VALUES ('text/x-c++src', 'G++ 9.4.0', 'C++ 17 With O2', '/usr/bin/g++ -DONLINE_JUDGE -O2 -w -fmax-errors=1 -std=c++17 {src_path} -lm -o {exe_path}', '#include<iostream>\r\nusing namespace std;\r\nint main()\r\n{\r\n    int a,b;\r\n    cin >> a >> b;\r\n    cout << a + b;\r\n    return 0;\r\n}', '//PREPEND BEGIN\r\n#include <iostream>\r\nusing namespace std;\r\n//PREPEND END\r\n\r\n//TEMPLATE BEGIN\r\nint add(int a, int b) {\r\n  // Please fill this blank\r\n  return ___________;\r\n}\r\n//TEMPLATE END\r\n\r\n//APPEND BEGIN\r\nint main() {\r\n  cout << add(1, 2);\r\n  return 0;\r\n}\r\n//APPEND END', 0, 'ME', 5);
	INSERT INTO `language`(`content_type`,`description`,`name`,`compile_command`,`template`, `code_template`, `is_spj`, `oj`, `seq`) VALUES ('text/x-c++src', 'G++ 9.4.0', 'C++ 20', '/usr/bin/g++ -DONLINE_JUDGE -w -fmax-errors=1 -std=c++20 {src_path} -lm -o {exe_path}', '#include<iostream>\r\nusing namespace std;\r\nint main()\r\n{\r\n    int a,b;\r\n    cin >> a >> b;\r\n    cout << a + b;\r\n    return 0;\r\n}', '//PREPEND BEGIN\r\n#include <iostream>\r\nusing namespace std;\r\n//PREPEND END\r\n\r\n//TEMPLATE BEGIN\r\nint add(int a, int b) {\r\n  // Please fill this blank\r\n  return ___________;\r\n}\r\n//TEMPLATE END\r\n\r\n//APPEND BEGIN\r\nint main() {\r\n  cout << add(1, 2);\r\n  return 0;\r\n}\r\n//APPEND END', 0, 'ME', 5);
	INSERT INTO `language`(`content_type`,`description`,`name`,`compile_command`,`template`, `code_template`, `is_spj`, `oj`, `seq`) VALUES ('text/x-c++src', 'G++ 9.4.0', 'C++ 20 With O2', '/usr/bin/g++ -DONLINE_JUDGE -O2 -w -fmax-errors=1 -std=c++20 {src_path} -lm -o {exe_path}', '#include<iostream>\r\nusing namespace std;\r\nint main()\r\n{\r\n    int a,b;\r\n    cin >> a >> b;\r\n    cout << a + b;\r\n    return 0;\r\n}', '//PREPEND BEGIN\r\n#include <iostream>\r\nusing namespace std;\r\n//PREPEND END\r\n\r\n//TEMPLATE BEGIN\r\nint add(int a, int b) {\r\n  // Please fill this blank\r\n  return ___________;\r\n}\r\n//TEMPLATE END\r\n\r\n//APPEND BEGIN\r\nint main() {\r\n  cout << add(1, 2);\r\n  return 0;\r\n}\r\n//APPEND END', 0, 'ME', 5);
	
END
IF ; END$$
 
DELIMITER ; 
CALL add_Language_Change ;

DROP PROCEDURE add_Language_Change;


/*
* 2023.05.01  增加读写模式 支持文件IO
			 
*/
DROP PROCEDURE
IF EXISTS add_Problem_FileIO;
DELIMITER $$
 
CREATE PROCEDURE add_Problem_FileIO ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'problem'
	AND column_name = 'is_file_io'
) THEN
	
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `is_file_io` tinyint(1) DEFAULT '0' COMMENT '是否是file io自定义输入输出文件模式';
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `io_read_file_name` VARCHAR(255) NULL COMMENT '题目指定的file io输入文件的名称';
	ALTER TABLE `hoj`.`problem`  ADD COLUMN `io_write_file_name` VARCHAR(255) NULL COMMENT '题目指定的file io输出文件的名称';
END
IF ; END$$
 
DELIMITER ; 
CALL add_Problem_FileIO ;

DROP PROCEDURE add_Problem_FileIO;


/*
* 2023.06.10  增加允许比赛结束后进行交题的开关
			 
*/
DROP PROCEDURE
IF EXISTS add_Contest_allow_end_submit;
DELIMITER $$
 
CREATE PROCEDURE add_Contest_allow_end_submit ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'contest'
	AND column_name = 'allow_end_submit'
) THEN
	
	ALTER TABLE `hoj`.`contest`  ADD COLUMN `allow_end_submit` tinyint(1) DEFAULT '0' COMMENT '是否允许比赛结束后进行提交';
END
IF ; END$$
 
DELIMITER ; 
CALL add_Contest_allow_end_submit ;

DROP PROCEDURE add_Contest_allow_end_submit;

/*
* 2024.08.07  judge表ip字段修改字符长度为64
			 
*/
DROP PROCEDURE
IF EXISTS change_judge_ip_length;
DELIMITER $$
 
CREATE PROCEDURE change_judge_ip_length ()
BEGIN
 
IF NOT EXISTS (
	SELECT
		1
	FROM
		information_schema.`COLUMNS`
	WHERE
		table_name = 'judge'
	AND column_name = 'ip' AND CHAR_LENGTH(ip) = 20
) THEN

	ALTER TABLE `hoj`.`judge`  MODIFY COLUMN `ip` varchar(64);
	
END
IF ; END$$