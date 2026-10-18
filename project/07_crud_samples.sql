-- ============================================================
-- 实验项目 步骤 5（对齐优秀作品第 5 章「数据增删改查样例」）
-- 在一段显式事务里完整演示 INSERT / UPDATE / DELETE / SELECT，
-- 最后由 ROLLBACK 撤掉演示数据，保证可重复执行、不污染原有 16 项行动。
-- 触发器联动：插入时自动判定逾期状态；更新时自动记录审计日志。
-- ============================================================

USE `multilateral-diplomacy-system-schoolwork-`;

START TRANSACTION;

-- ---------- 1. INSERT：新建一场会议（筹备中） ----------
INSERT INTO conference
  (title, short_name, mechanism_id, org_id, host_country_id, host_city,
   conference_type, session_label, start_date, end_date, format, status, theme)
VALUES
  ('上海合作组织成员国元首理事会第二十五次会议', '上合组织2026峰会', 1, 2, 1, '北京',
   '首脑峰会', '第25次', '2026-11-20', '2026-11-21', '线下', '筹备中',
   '弘扬"上海精神"，推动构建更加紧密的上合组织命运共同体');
SET @conf := LAST_INSERT_ID();

-- ---------- 2. INSERT：登记参会国家（主办国 + 两个成员国 + 一个观察员） ----------
INSERT INTO conference_participant
  (conference_id, country_id, role, delegation_level, delegation_size, join_date)
VALUES
  (@conf, 1,  '主办国', '元首级', 60, '2026-10-01'),
  (@conf, 8,  '成员国', '元首级', 40, '2026-10-02'),
  (@conf, 3,  '成员国', '元首级', 38, '2026-10-02'),
  (@conf, 10, '观察员', '部长级', 20, '2026-10-03');

-- ---------- 3. INSERT：挂接议题 ----------
INSERT INTO conference_topic (conference_id, topic_id, is_core, discussion_date, summary)
VALUES
  (@conf, 1, 1, '2026-11-20', '共同、综合、合作、可持续的安全观'),
  (@conf, 9, 1, '2026-11-21', '人工智能治理与数字丝绸之路');

-- ---------- 4. INSERT：产出成果文件 + 联署国 ----------
INSERT INTO document
  (conference_id, title, doc_type, doc_no, issue_date, adopt_method, status, summary)
VALUES
  (@conf, '上合组织北京宣言（草案）', '联合声明', 'SCO-2026-BJ', '2026-11-21', '协商一致', '草案',
   '筹备阶段草案，待元首理事会通过');
SET @doc := LAST_INSERT_ID();

INSERT INTO document_sponsor (document_id, country_id, stance)
VALUES (@doc, 1, '联署'), (@doc, 8, '联署'), (@doc, 3, '支持');

-- ---------- 5. INSERT：派生一项后续行动（计划完成日期已过 → 触发器判为逾期） ----------
INSERT INTO follow_up_action
  (conference_id, document_id, action_name, lead_country_id, responsible_org_id,
   start_date, planned_end_date, actual_end_date, progress_pct, status, remarks)
VALUES
  (@conf, @doc, '上合组织人工智能治理联合研究', 1, 2,
   '2026-01-01', '2026-09-30', NULL, 30, '进行中', '演示记录：计划完成日期早于当前日期');
SET @act := LAST_INSERT_ID();

-- SELECT 验证 1：新写入的会议全链条
SELECT c.conference_id, c.short_name, c.status,
       (SELECT COUNT(*) FROM conference_participant p WHERE p.conference_id = c.conference_id) AS 参与国数,
       (SELECT COUNT(*) FROM conference_topic ct WHERE ct.conference_id = c.conference_id)       AS 议题数,
       (SELECT COUNT(*) FROM document d WHERE d.conference_id = c.conference_id)                 AS 文件数
FROM conference c WHERE c.conference_id = @conf;

SELECT action_id, action_name, status AS 触发器判定结果, progress_pct
FROM follow_up_action WHERE action_id = @act;

-- ---------- 6. UPDATE：补录完成情况（进度 100% + 实际完成日期 → 触发器改判已完成并写审计） ----------
UPDATE follow_up_action
SET actual_end_date = '2026-10-15', progress_pct = 100
WHERE action_id = @act;

SELECT action_id, action_name, status, progress_pct, actual_end_date
FROM follow_up_action WHERE action_id = @act;

-- SELECT 验证 2：审计日志（触发器自动留痕）
SELECT log_id, action_type, target_table, target_id, old_value, new_value
FROM operation_log WHERE target_table = 'follow_up_action' AND target_id = @act
ORDER BY log_id;

-- ---------- 7. DELETE：撤销错误的参会登记与行动记录 ----------
DELETE FROM conference_participant WHERE conference_id = @conf AND country_id = 10;
DELETE FROM follow_up_action WHERE action_id = @act;

SELECT COUNT(*) AS 删除后该会议参与国数
FROM conference_participant WHERE conference_id = @conf;

-- ---------- 8. 回滚整个演示事务，库里数据保持原样 ----------
ROLLBACK;

SELECT (SELECT COUNT(*) FROM conference)         AS 回滚后会议数,
       (SELECT COUNT(*) FROM follow_up_action)   AS 回滚后行动数,
       (SELECT COUNT(*) FROM document)           AS 回滚后文件数;

-- 说明：以下语句故意不执行，用于答辩时演示约束拦截（单独跑，预期报错）
--   INSERT INTO conference_participant (conference_id, country_id, role) VALUES (1, 999, '成员国');
--   → ERROR 1452 外键约束失败
--   UPDATE follow_up_action SET progress_pct = 150 WHERE action_id = 2;
--   → ERROR 3819 Check constraint 'ck_action_progress' is violated
--   DELETE FROM country WHERE iso_code = 'CHN';
--   → ERROR 1451 被外键引用，ON DELETE RESTRICT 拒绝删除
