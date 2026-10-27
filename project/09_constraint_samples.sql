-- S11—S16：约束与触发器的故意违反测试，共11条语句应报错。
-- 先执行01—04、06；本文件不加入run_all，避免预期错误中断正常建库。
-- Linux运行：sudo mysql --force --table < project/09_constraint_samples.sql
-- --force仅用于本文件，使预期失败后继续验证并执行ROLLBACK；也可逐条演示。
-- 全部演示数据都在同一事务内，结束后回滚。若手动中断，请在同一连接ROLLBACK。
USE `multilateral-diplomacy-system-schoolwork-`;

START TRANSACTION;
SET @check_day = CURDATE();
SET @check_china = (SELECT country_id FROM country WHERE iso_code = 'CHN');
SET @missing_country = (SELECT MAX(country_id) + 1 FROM country);
INSERT INTO conference (title, short_name, conference_type, start_date, end_date)
VALUES ('约束演示会议甲（虚构）', '约束演示甲', '专题会议', @check_day, @check_day);
SET @check_conf1 = LAST_INSERT_ID();
INSERT INTO conference (title, short_name, conference_type, start_date, end_date)
VALUES ('约束演示会议乙（虚构）', '约束演示乙', '专题会议', @check_day, @check_day);
SET @check_conf2 = LAST_INSERT_ID();
INSERT INTO conference_participant (conference_id, country_id, role)
VALUES (@check_conf1, @check_china, '主办国');
INSERT INTO document (conference_id, title, doc_type, doc_no, issue_date)
VALUES (@check_conf1, '约束演示文件', '联合声明', 'COURSE-CONSTRAINT', @check_day);
SET @check_doc = LAST_INSERT_ID();
INSERT INTO follow_up_action
  (conference_id, document_id, action_name, lead_country_id, start_date, planned_end_date, progress_pct, status)
VALUES
  (@check_conf1, @check_doc, '约束演示行动', @check_china, @check_day,
   DATE_ADD(@check_day, INTERVAL 10 DAY), 20, '进行中');
SET @check_action = LAST_INSERT_ID();
INSERT INTO app_user (username, real_name, user_role)
VALUES ('course_constraint_demo', '约束演示用户', '观察员');
SET @check_user = LAST_INSERT_ID();

-- @sample S11 复合主键：同一会议重复登记同一国家，应报1062。
INSERT INTO conference_participant (conference_id, country_id, role)
VALUES (@check_conf1, @check_china, '成员国');
SELECT COUNT(*) AS 该国参会记录仍为1
FROM conference_participant WHERE conference_id = @check_conf1 AND country_id = @check_china;

-- @sample S12 UNIQUE：重复非空正式文号，应报1062；多个NULL文号允许存在。
INSERT INTO document (conference_id, title, doc_type, doc_no, issue_date)
VALUES (@check_conf2, '重复文号演示', '联合声明', 'COURSE-CONSTRAINT', @check_day);
SELECT COUNT(*) AS 该文号记录仍为1 FROM document WHERE doc_no = 'COURSE-CONSTRAINT';

-- @sample S13 外键：不存在的国家应报1452；删除被引用的国家应报1451。
INSERT INTO conference_participant (conference_id, country_id, role)
VALUES (@check_conf1, @missing_country, '成员国');
DELETE FROM country WHERE country_id = @check_china;
SELECT COUNT(*) AS 中国记录仍为1 FROM country WHERE country_id = @check_china;
SELECT COUNT(*) AS 不存在国家的参会记录为0
FROM conference_participant WHERE conference_id = @check_conf1 AND country_id = @missing_country;

-- @sample S14 CHECK：进度越界、计划日期倒置、已完成却无完成日期均应报3819。
UPDATE follow_up_action SET progress_pct = 150 WHERE action_id = @check_action;
UPDATE follow_up_action SET planned_end_date = DATE_SUB(start_date, INTERVAL 1 DAY)
WHERE action_id = @check_action;
UPDATE follow_up_action SET status = '已完成' WHERE action_id = @check_action;
SELECT progress_pct AS 进度仍为20, status AS 状态仍为进行中, actual_end_date AS 完成日期仍为空
FROM follow_up_action WHERE action_id = @check_action;
-- 合法对照：NULL表示未知；已知期限已过但状态未知时，预警视图仍应显示该行动。
UPDATE follow_up_action
SET progress_pct = NULL, status = NULL,
    start_date = DATE_SUB(@check_day, INTERVAL 2 DAY),
    planned_end_date = DATE_SUB(@check_day, INTERVAL 1 DAY)
WHERE action_id = @check_action;
SELECT a.progress_pct AS 未知进度, a.status AS 未知状态, v.overdue_days AS 逾期天数
FROM follow_up_action a LEFT JOIN v_action_alert v ON v.action_id = a.action_id
WHERE a.action_id = @check_action;

-- @sample S15 触发器：插入行动、修改行动会议、修改文件会议的不一致均应报1644。
INSERT INTO follow_up_action (conference_id, document_id, action_name)
VALUES (@check_conf2, @check_doc, '来源不一致的演示行动');
UPDATE follow_up_action SET conference_id = @check_conf2 WHERE action_id = @check_action;
UPDATE document SET conference_id = @check_conf2 WHERE document_id = @check_doc;
SELECT a.conference_id = d.conference_id AS 行动文件会议仍一致
FROM follow_up_action a JOIN document d ON d.document_id = a.document_id
WHERE a.action_id = @check_action;

-- @sample S16 可更新视图：合法修改一行；违反is_active=1应报1369，基表保持启用。
UPDATE v_active_user SET real_name = '约束演示用户（已修改）' WHERE user_id = @check_user;
SELECT real_name AS 修改后姓名, is_active AS 启用状态 FROM app_user WHERE user_id = @check_user;
UPDATE v_active_user SET is_active = 0 WHERE user_id = @check_user;
SELECT is_active AS 启用状态仍为1 FROM app_user WHERE user_id = @check_user;

ROLLBACK;
SELECT (SELECT COUNT(*) FROM conference) AS 回滚后会议数,
       (SELECT COUNT(*) FROM follow_up_action) AS 回滚后行动数,
       (SELECT COUNT(*) FROM app_user) AS 回滚后用户数,
       (SELECT COUNT(*) FROM operation_log) AS 回滚后日志数;
