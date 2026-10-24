-- ============================================================
-- 实验项目 步骤 5：核心查询（14 条）
-- 课件对应：连接、聚合、GROUP BY/HAVING、嵌套查询与视图查询。
-- IN、ANY/ALL、自身连接与 UNION 示例另见 08_course_examples.sql。
-- 日期函数 DATEDIFF、CURDATE、YEAR 用于适配 MySQL。
-- ============================================================

USE `multilateral-diplomacy-system-schoolwork-`;

-- 查询 1：会议全景（会议 + 主办国 + 机制 + 参与国数 + 文件数）
SELECT short_name AS 会议简称, conference_type AS 类型, host_country AS 主办国,
       host_city AS 城市, start_date AS 开始日期, participant_count AS 参与国数,
       document_count AS 成果文件数, action_count AS 后续行动数
FROM v_conference_overview
ORDER BY start_date;

-- 查询 2：按机制统计会议数、成果文件数、参会国次（按会议与国家组合计数）
-- 分别计数，避免文件与参会记录连接后相互放大。
SELECT m.name AS 机制, m.category AS 类别,
       (SELECT COUNT(*) FROM conference c
        WHERE c.mechanism_id = m.mechanism_id) AS 会议数,
       (SELECT COUNT(*) FROM conference c, document d
        WHERE c.conference_id = d.conference_id
          AND c.mechanism_id = m.mechanism_id) AS 成果文件数,
       (SELECT COUNT(*) FROM conference c, conference_participant p
        WHERE c.conference_id = p.conference_id
          AND c.mechanism_id = m.mechanism_id) AS 参会国次
FROM mechanism m
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

-- 查询 5：各国主办会议数（分组统计 + 排序，包含未主办的国家）
SELECT hc.name_cn AS 主办国, COUNT(c.conference_id) AS 主办会议数
FROM country hc
LEFT JOIN conference c ON c.host_country_id = hc.country_id
GROUP BY hc.country_id, hc.name_cn
ORDER BY 主办会议数 DESC, hc.country_id;

-- 查询 6：后续行动逾期预警（视图 + 逾期天数）
SELECT action_name AS 行动名称, conference_name AS 来源会议, lead_country AS 牵头国,
       planned_end_date AS 计划完成, overdue_days AS 逾期天数,
       progress_pct AS 进度百分比
FROM v_action_alert
ORDER BY overdue_days DESC;

-- 查询 7：成果文件共识广度（按联署国数排序）
SELECT title AS 文件名称, conference_name AS 会议,
       signed_count AS 联署国数, support_count AS 支持国数,
       reserved_count AS 保留国数, total_country_count AS 涉国总数
FROM v_document_consensus
ORDER BY signed_count DESC, total_country_count DESC, document_id;

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

-- 查询 12：参加了中国所参加的全部会议的国家（双重 NOT EXISTS，关系除法）
-- 含义：不存在一场中国参加、但该国没有参加的会议；结果包含中国本身。
SELECT cn.country_id AS 国家编号, cn.name_cn AS 国家
FROM country cn
WHERE NOT EXISTS (
  SELECT * FROM conference_participant p
  WHERE p.country_id = (SELECT country_id FROM country WHERE iso_code = 'CHN')
    AND NOT EXISTS (
      SELECT * FROM conference_participant x
      WHERE x.conference_id = p.conference_id AND x.country_id = cn.country_id
    )
)
ORDER BY cn.country_id;

-- 查询 13：系统用户角色与国别分布（权限视角）
SELECT user_role AS 角色, COUNT(*) AS 人数,
       SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS 启用人数,
       COUNT(DISTINCT country_id) AS 涉及国家数
FROM app_user
GROUP BY user_role
ORDER BY 人数 DESC;

-- 查询 14：操作审计日志（视图查询 + 按时间倒序）
SELECT 操作人, 角色, 操作类型, 目标表, 目标ID, 变更前, 变更后, log_time AS 记录时间
FROM v_operation_audit
ORDER BY log_time DESC, log_id DESC;
