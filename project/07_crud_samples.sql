-- 课件3.4：单行/多行INSERT、INSERT ... SELECT、带子查询的UPDATE/DELETE。
-- S06—S10：只在事务中建立虚构演示数据，最后ROLLBACK；真实资料保持原样。
-- MySQL适配：用户变量、LAST_INSERT_ID、CURDATE和DATE_SUB。
USE `multilateral-diplomacy-system-schoolwork-`;

START TRANSACTION;
SET @demo_day = CURDATE();
SET @china = (SELECT country_id FROM country WHERE iso_code = 'CHN');
SET @kaz = (SELECT country_id FROM country WHERE iso_code = 'KAZ');
SET @rus = (SELECT country_id FROM country WHERE iso_code = 'RUS');
SET @security = (SELECT topic_id FROM topic WHERE name = '全球安全治理');
SET @ai = (SELECT topic_id FROM topic WHERE name = '人工智能治理');

-- @sample S06 新增会议及关联数据，插入时触发器自动判为逾期。
INSERT INTO conference
  (title, short_name, host_country_id, host_city, conference_type, start_date, end_date, format)
VALUES
  ('课程综合演示会议（虚构）', '课件演示会议', @china, '北京', '专题会议',
   DATE_SUB(@demo_day, INTERVAL 10 DAY), DATE_SUB(@demo_day, INTERVAL 9 DAY), '线下');
SET @conf = LAST_INSERT_ID();

INSERT INTO conference_participant
  (conference_id, country_id, role, delegation_level, delegation_size)
VALUES
  (@conf, @china, '主办国', '元首级', 60),
  (@conf, @kaz, '成员国', '元首级', 40),
  (@conf, @rus, '成员国', '元首级', 38);

INSERT INTO conference_participant
  (conference_id, country_id, role, delegation_level, delegation_size)
SELECT @conf, country_id, '观察员', '部长级', 20
FROM country WHERE iso_code = 'IDN';

INSERT INTO conference_topic (conference_id, topic_id, is_core, summary)
VALUES (@conf, @security, 1, '共同安全与多边合作'),
       (@conf, @ai, 1, '人工智能治理与技术合作');

INSERT INTO document (conference_id, title, doc_type, doc_no, issue_date, adopt_method)
VALUES (@conf, '课程演示联合声明', '联合声明', 'COURSE-DEMO', @demo_day, '协商一致');
SET @doc = LAST_INSERT_ID();
INSERT INTO document_sponsor (document_id, country_id, stance)
VALUES (@doc, @china, '联署'), (@doc, @kaz, '联署'), (@doc, @rus, '支持');

INSERT INTO follow_up_action
  (conference_id, document_id, action_name, lead_country_id,
   start_date, planned_end_date, progress_pct, status)
VALUES
  (@conf, @doc, '课程人工智能合作研究（虚构）', @china,
   DATE_SUB(@demo_day, INTERVAL 8 DAY), DATE_SUB(@demo_day, INTERVAL 1 DAY), 30, '进行中');
SET @act = LAST_INSERT_ID();

SELECT c.short_name AS 会议,
       (SELECT COUNT(*) FROM conference_participant p WHERE p.conference_id = c.conference_id) AS 参会国数,
       (SELECT COUNT(*) FROM conference_topic t WHERE t.conference_id = c.conference_id) AS 议题数,
       (SELECT COUNT(*) FROM document d WHERE d.conference_id = c.conference_id) AS 文件数
FROM conference c WHERE c.conference_id = @conf;
SELECT status AS 插入后状态, progress_pct AS 进度
FROM follow_up_action WHERE action_id = @act;

-- @sample S07 只填写完成日期，观察触发器将状态改为已完成、进度改为100并写审计。
UPDATE follow_up_action
SET actual_end_date = @demo_day
WHERE action_id = @act
  AND lead_country_id IN (SELECT country_id FROM country WHERE iso_code = 'CHN');
SELECT status AS 状态, progress_pct AS 进度, actual_end_date AS 完成日期
FROM follow_up_action WHERE action_id = @act;
SELECT action_type AS 操作, old_value AS 变更前, new_value AS 变更后
FROM operation_log WHERE target_table = 'follow_up_action' AND target_id = @act
ORDER BY log_id;

-- @sample S08 带子查询的DELETE，查询实际剩余数量。
DELETE FROM conference_participant
WHERE conference_id = @conf
  AND country_id IN (SELECT country_id FROM country WHERE iso_code = 'IDN');
DELETE FROM follow_up_action WHERE action_id = @act;
SELECT (SELECT COUNT(*) FROM conference_participant WHERE conference_id = @conf) AS 剩余参会国数,
       (SELECT COUNT(*) FROM follow_up_action WHERE action_id = @act) AS 剩余演示行动数;

-- @sample S09 综合统计：调用自定义函数，分母为已记录的文件立场国家数。
SELECT COUNT(*) AS 已记录立场国数,
       SUM(CASE WHEN stance = '联署' THEN 1 ELSE 0 END) AS 联署国数,
       fn_consensus_ratio(@doc) AS 联署比例百分比
FROM document_sponsor WHERE document_id = @doc;

-- @sample S10 回滚演示，真实数据及审计记录恢复原样；自增编号可能留下空号。
ROLLBACK;
SELECT (SELECT COUNT(*) FROM conference) AS 会议数,
       (SELECT COUNT(*) FROM document) AS 文件数,
       (SELECT COUNT(*) FROM conference_participant) AS 参会记录数,
       (SELECT COUNT(*) FROM follow_up_action) AS 行动数,
       (SELECT COUNT(*) FROM operation_log) AS 审计记录数;
