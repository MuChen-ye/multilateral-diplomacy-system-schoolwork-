-- ============================================================
-- 实验项目 步骤 4：视图
-- 用途：把多表连接与聚合固化成可直接演示的"报表"，
--       其中 v_china_multilateral 与 v_document_consensus 用于呈现思政主题。
-- 6 个视图覆盖多表、分组、表达式、基于视图及行列子集视图。
-- CREATE OR REPLACE 是 MySQL 对 CREATE VIEW 的扩展，使本文件可单独重跑。
-- ============================================================

USE `multilateral-diplomacy-system-schoolwork-`;

-- ---------- 视图 1 v_conference_overview 会议全景 ----------
CREATE OR REPLACE VIEW v_conference_overview AS
SELECT
  c.conference_id,
  c.short_name,
  c.conference_type,
  c.session_label,
  c.start_date,
  c.end_date,
  c.status,
  hc.name_cn                       AS host_country,
  c.host_city,
  m.name                           AS mechanism_name,
  o.name_cn                        AS org_name,
  (SELECT COUNT(*) FROM conference_participant p
     WHERE p.conference_id = c.conference_id)                       AS participant_count,
  (SELECT COUNT(*) FROM conference_topic ct
     WHERE ct.conference_id = c.conference_id AND ct.is_core = 1)    AS core_topic_count,
  (SELECT COUNT(*) FROM document d
     WHERE d.conference_id = c.conference_id)                        AS document_count,
  (SELECT COUNT(*) FROM follow_up_action a
     WHERE a.conference_id = c.conference_id)                        AS action_count,
  (SELECT COUNT(*) FROM follow_up_action a
     WHERE a.conference_id = c.conference_id AND a.status = '已完成') AS action_done_count
FROM conference c
JOIN country hc
  ON hc.country_id = c.host_country_id
LEFT JOIN mechanism m
  ON m.mechanism_id = c.mechanism_id
LEFT JOIN international_organization o
  ON o.org_id = c.org_id;

-- ---------- 视图 2 v_document_consensus 成果文件共识广度 ----------
CREATE OR REPLACE VIEW v_document_consensus AS
SELECT
  d.document_id,
  d.doc_no,
  d.title,
  d.doc_type,
  d.adopt_method,
  d.issue_date,
  c.short_name                                          AS conference_name,
  SUM(CASE WHEN ds.stance = '联署' THEN 1 ELSE 0 END)   AS signed_count,
  SUM(CASE WHEN ds.stance = '支持' THEN 1 ELSE 0 END)   AS support_count,
  SUM(CASE WHEN ds.stance = '保留' THEN 1 ELSE 0 END)   AS reserved_count,
  COUNT(ds.country_id)                                  AS total_country_count
FROM document d
JOIN conference c            ON c.conference_id = d.conference_id
LEFT JOIN document_sponsor ds ON ds.document_id = d.document_id
GROUP BY d.document_id, d.doc_no, d.title, d.doc_type, d.adopt_method,
         d.issue_date, c.short_name;

-- ---------- 视图 3 v_action_alert 后续行动逾期预警 ----------
CREATE OR REPLACE VIEW v_action_alert AS
SELECT
  a.action_id,
  a.action_name,
  c.short_name                                          AS conference_name,
  lc.name_cn                                            AS lead_country,
  a.start_date,
  a.planned_end_date,
  DATEDIFF(CURDATE(), a.planned_end_date)               AS overdue_days,
  a.progress_pct,
  a.status,
  a.remarks
FROM follow_up_action a
JOIN conference c ON c.conference_id = a.conference_id
JOIN country lc   ON lc.country_id = a.lead_country_id
WHERE a.actual_end_date IS NULL
  AND a.planned_end_date < CURDATE()
  AND a.status <> '终止';

-- ---------- 视图 4 v_china_multilateral 基于视图的中国参与全景 ----------
CREATE OR REPLACE VIEW v_china_multilateral AS
SELECT
  c.short_name AS conference_name,
  c.conference_type,
  c.start_date,
  c.host_city,
  c.host_country,
  c.mechanism_name,
  p.role AS china_role,
  p.delegation_level AS china_delegation_level,
  p.delegation_size AS china_delegation_size,
  CASE WHEN p.role = '主办国' THEN '主办' ELSE '参与' END AS china_engagement,
  c.document_count AS documents_of_conference,
  (SELECT COUNT(*)
   FROM document d JOIN document_sponsor sp ON sp.document_id = d.document_id
   WHERE d.conference_id = c.conference_id
     AND sp.country_id = cn.country_id AND sp.stance = '联署') AS documents_china_signed
FROM v_conference_overview c
JOIN conference_participant p ON p.conference_id = c.conference_id
JOIN country cn ON cn.country_id = p.country_id
WHERE cn.iso_code = 'CHN';

-- ---------- 视图 5 v_operation_audit 操作审计视图 ----------
CREATE OR REPLACE VIEW v_operation_audit AS
SELECT
  l.log_id,
  l.log_time,
  COALESCE(u.real_name, '系统触发器') AS 操作人,
  COALESCE(u.user_role, '系统')       AS 角色,
  l.action_type                       AS 操作类型,
  l.target_table                      AS 目标表,
  l.target_id                         AS 目标ID,
  l.old_value                         AS 变更前,
  l.new_value                         AS 变更后,
  l.detail                            AS 说明
FROM operation_log l
LEFT JOIN app_user u ON u.user_id = l.user_id;

-- ---------- 视图 6 v_active_user 可更新的行列子集视图 ----------
-- 课件 3.5：单表选择、投影并保留主键；CHECK OPTION 限制写入后仍满足视图条件。
CREATE OR REPLACE VIEW v_active_user AS
SELECT user_id, username, real_name, user_role, country_id, org_id, is_active, created_at
FROM app_user
WHERE is_active = 1
WITH CHECK OPTION;
