-- ============================================================
-- 实验项目 步骤 5：核心查询（12 条，覆盖评分点"典型查询种类较多"）
--   1 多表连接  2 聚合统计  3 HAVING  4 子查询  5 窗口函数  6 预警
--   7 排序取前 N 8 分组多指标 9 半连接/存在  10 状态分布  11 时间维度  12 全链条串联
-- ============================================================

USE `multilateral-diplomacy-system-schoolwork-`;

-- 查询 1：会议全景（会议 + 主办国 + 机制 + 参与国数 + 文件数）
SELECT short_name AS 会议简称, conference_type AS 类型, host_country AS 主办国,
       host_city AS 城市, start_date AS 开始日期, participant_count AS 参与国数,
       document_count AS 成果文件数, action_count AS 后续行动数
FROM v_conference_overview
ORDER BY start_date;

-- 查询 2：按机制统计会议数、成果文件数、参与国总人次
SELECT m.name AS 机制, m.category AS 类别,
       COUNT(DISTINCT c.conference_id) AS 会议数,
       COUNT(DISTINCT d.document_id)   AS 成果文件数,
       COUNT(DISTINCT p.participant_id) AS 参会国次
FROM mechanism m
LEFT JOIN conference c            ON c.mechanism_id = m.mechanism_id
LEFT JOIN document d              ON d.conference_id = c.conference_id
LEFT JOIN conference_participant p ON p.conference_id = c.conference_id
GROUP BY m.mechanism_id, m.name, m.category
ORDER BY 会议数 DESC, 成果文件数 DESC;

-- 查询 3：参与国不少于 8 个的多边会议（HAVING 过滤分组结果）
SELECT c.short_name AS 会议简称, COUNT(p.country_id) AS 参与国数
FROM conference c
JOIN conference_participant p ON p.conference_id = c.conference_id
GROUP BY c.conference_id, c.short_name
HAVING COUNT(p.country_id) >= 8
ORDER BY 参与国数 DESC;

-- 查询 4：没有产生任何后续行动的成果文件（相关子查询 + NOT EXISTS）
SELECT COALESCE(d.doc_no, '（无编号）') AS 文件编号, d.title AS 文件名称,
       d.doc_type AS 类型, d.status AS 状态
FROM document d
WHERE NOT EXISTS (SELECT 1 FROM follow_up_action a WHERE a.document_id = d.document_id)
ORDER BY d.issue_date;

-- 查询 5：各国主办会议数排名（窗口函数 DENSE_RANK）
SELECT hc.name_cn AS 主办国,
       COUNT(*) AS 主办会议数,
       DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS 名次
FROM conference c
JOIN country hc ON hc.country_id = c.host_country_id
GROUP BY hc.country_id, hc.name_cn
ORDER BY 名次, 主办国;

-- 查询 6：后续行动逾期预警（视图 + 逾期天数）
SELECT action_name AS 行动名称, conference_name AS 来源会议, lead_country AS 牵头国,
       planned_end_date AS 计划完成, overdue_days AS 逾期天数,
       progress_pct AS 进度百分比
FROM v_action_alert
ORDER BY overdue_days DESC;

-- 查询 7：成果文件共识广度排行（按联署国数量取前 5）
SELECT title AS 文件名称, conference_name AS 会议,
       signed_count AS 联署国数, support_count AS 支持国数,
       reserved_count AS 保留国数, total_country_count AS 涉国总数
FROM v_document_consensus
ORDER BY signed_count DESC, total_country_count DESC
LIMIT 5;

-- 查询 8：议题热度（按领域统计被多少场会议讨论、其中多少为核心议题）
SELECT t.category AS 议题领域,
       COUNT(DISTINCT t.topic_id)  AS 议题数,
       COUNT(DISTINCT ct.conference_id) AS 涉及会议数,
       SUM(CASE WHEN ct.is_core = 1 THEN 1 ELSE 0 END) AS 核心议题次数
FROM topic t
JOIN conference_topic ct ON ct.topic_id = t.topic_id
GROUP BY t.category
ORDER BY 涉及会议数 DESC;

-- 查询 9：中国在多边机制中的参与全景与文件联署情况（思政报表，基于视图）
SELECT conference_name AS 会议, china_role AS 中国身份, china_delegation_level AS 出席级别,
       host_country AS 主办国, mechanism_name AS 所属机制,
       documents_of_conference AS 会议文件数, documents_china_signed AS 中国联署文件数
FROM v_china_multilateral
ORDER BY start_date;

-- 查询 10：后续行动状态分布与平均进度
SELECT status AS 状态, COUNT(*) AS 行动数,
       ROUND(AVG(progress_pct), 1) AS 平均进度,
       SUM(CASE WHEN actual_end_date IS NOT NULL THEN 1 ELSE 0 END) AS 已实际完成数
FROM follow_up_action
GROUP BY status
ORDER BY 行动数 DESC;

-- 查询 11：按年份统计国际会议数量与参与国次
SELECT YEAR(c.start_date) AS 年份,
       COUNT(DISTINCT c.conference_id) AS 会议数,
       COUNT(p.country_id)             AS 参与国次,
       COUNT(DISTINCT c.host_country_id) AS 主办国数
FROM conference c
LEFT JOIN conference_participant p ON p.conference_id = c.conference_id
GROUP BY YEAR(c.start_date)
ORDER BY 年份;

-- 查询 12："会议—议题—成果文件—后续行动"全链条汇总（GROUP_CONCAT + 条件聚合）
SELECT c.short_name AS 会议,
       GROUP_CONCAT(DISTINCT t.name ORDER BY t.name SEPARATOR ' / ')  AS 议题链,
       GROUP_CONCAT(DISTINCT d.title ORDER BY d.title SEPARATOR ' / ') AS 成果文件,
       COUNT(DISTINCT a.action_id) AS 行动数,
       COUNT(DISTINCT CASE WHEN a.status = '已完成' THEN a.action_id END) AS 已完成,
       COUNT(DISTINCT CASE WHEN a.status = '逾期'   THEN a.action_id END) AS 逾期
FROM conference c
LEFT JOIN conference_topic ct   ON ct.conference_id = c.conference_id
LEFT JOIN topic t               ON t.topic_id = ct.topic_id
LEFT JOIN document d            ON d.conference_id = c.conference_id
LEFT JOIN follow_up_action a    ON a.conference_id = c.conference_id
GROUP BY c.conference_id, c.short_name
ORDER BY c.start_date;

-- 查询 13：系统用户角色与国别分布（权限视角）
SELECT user_role AS 角色, COUNT(*) AS 人数,
       SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS 启用人数,
       COUNT(DISTINCT country_id) AS 涉及国家数
FROM app_user
GROUP BY user_role
ORDER BY 人数 DESC;

-- 查询 14：操作审计日志（触发器自动留痕，按时间倒序取最近 10 条）
SELECT 操作人, 角色, 操作类型, 目标表, 目标ID, 变更前, 变更后, log_time AS 记录时间
FROM v_operation_audit
ORDER BY log_time DESC, log_id DESC
LIMIT 10;
