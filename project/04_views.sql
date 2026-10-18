-- ============================================================
-- 实验项目 步骤 4：视图
-- 用途：把多表连接与聚合固化成可直接演示的"报表"，
--       其中 v_china_multilateral 与 v_consensus_report 用于呈现思政主题。
-- ============================================================

USE `multilateral-diplomacy-system-schoolwork-`;

DROP VIEW IF EXISTS v_conference_overview;
DROP VIEW IF EXISTS v_document_consensus;
DROP VIEW IF EXISTS v_action_alert;
DROP VIEW IF EXISTS v_china_multilateral;

-- ---------- 视图 1 v_conference_overview 会议全景 ----------
CREATE VIEW v_conference_overview AS
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
CREATE VIEW v_document_consensus AS
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
CREATE VIEW v_action_alert AS
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

-- ---------- 视图 4 v_china_multilateral 中国多边外交参与全景（思政报表） ----------
CREATE VIEW v_china_multilateral AS
SELECT
  c.short_name                                 AS conference_name,
  c.conference_type,
  c.start_date,
  c.host_city,
  hc.name_cn                                   AS host_country,
  m.name                                       AS mechanism_name,
  p.role                                       AS china_role,
  p.delegation_level                           AS china_delegation_level,
  p.delegation_size                            AS china_delegation_size,
  CASE WHEN p.role = '主办国' THEN '主办' ELSE '参与' END AS china_engagement,
  (SELECT COUNT(*) FROM document d
     WHERE d.conference_id = c.conference_id)   AS documents_of_conference,
  (SELECT COUNT(*) FROM document d
     JOIN document_sponsor sp ON sp.document_id = d.document_id
     WHERE d.conference_id = c.conference_id
       AND sp.country_id = cn.country_id)       AS documents_china_signed
FROM conference c
JOIN country cn              ON cn.iso_code = 'CHN'
JOIN conference_participant p ON p.conference_id = c.conference_id
                            AND p.country_id = cn.country_id
JOIN country hc              ON hc.country_id = c.host_country_id
LEFT JOIN mechanism m        ON m.mechanism_id = c.mechanism_id;
