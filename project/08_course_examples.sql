-- ============================================================
-- 课件补充示例：基础条件、自身连接、IN、ANY/ALL、UNION、空值和视图更新。
-- 来源章节：3.3 数据查询、3.5 视图；本文件可重复执行。
-- ============================================================
USE `multilateral-diplomacy-system-schoolwork-`;

-- 1. BETWEEN + LIKE：进度为 30～70、名称含“合作”的行动。
SELECT action_name AS 行动, progress_pct AS 进度
FROM follow_up_action
WHERE progress_pct BETWEEN 30 AND 70 AND action_name LIKE '%合作%'
ORDER BY action_id;

-- 2. 自身连接：同时有中国和巴西参加的会议（课件使用 FROM 多表 + WHERE）。
SELECT c.short_name AS 会议
FROM conference c, conference_participant x, conference_participant y
WHERE c.conference_id = x.conference_id AND x.conference_id = y.conference_id
  AND x.country_id = (SELECT country_id FROM country WHERE iso_code = 'CHN')
  AND y.country_id = (SELECT country_id FROM country WHERE iso_code = 'BRA')
ORDER BY c.conference_id;

-- 3. IN：参加 1 号会议的国家。
SELECT name_cn AS 国家 FROM country
WHERE country_id IN (SELECT country_id FROM conference_participant WHERE conference_id = 1)
ORDER BY country_id;

-- 4. NOT IN：未参加 1 号会议的国家。
-- 此处子查询的 country_id 为 NOT NULL；可空列应优先使用 NOT EXISTS。
SELECT name_cn AS 国家 FROM country
WHERE country_id NOT IN (SELECT country_id FROM conference_participant WHERE conference_id = 1)
ORDER BY country_id;

-- 5. ANY：代表团人数超过中国至少一次参会人数的记录。
SELECT conference_id AS 会议编号, country_id AS 国家编号, delegation_size AS 人数
FROM conference_participant
WHERE delegation_size > ANY (
  SELECT delegation_size FROM conference_participant
  WHERE country_id = (SELECT country_id FROM country WHERE iso_code = 'CHN')
    AND delegation_size > 0
)
ORDER BY conference_id, country_id;

-- 6. ALL + 相关子查询：各会议进度最高的行动，保留并列结果。
SELECT a.conference_id AS 会议编号, a.action_name AS 行动, a.progress_pct AS 进度
FROM follow_up_action a
WHERE a.progress_pct >= ALL (
  SELECT b.progress_pct FROM follow_up_action b WHERE b.conference_id = a.conference_id
)
ORDER BY a.conference_id, a.action_id;

-- 7. UNION：作为会议举办地或牵头过行动的国家，自动去重。
SELECT country_id AS 国家编号, name_cn AS 国家 FROM country
WHERE country_id IN (SELECT host_country_id FROM conference)
UNION
SELECT country_id, name_cn FROM country
WHERE country_id IN (SELECT lead_country_id FROM follow_up_action)
ORDER BY 国家编号;

-- 8. IS NULL：尚未编号的成果文件。
SELECT document_id AS 文件编号, title AS 文件名称 FROM document
WHERE doc_no IS NULL
ORDER BY document_id;

-- 9. 可更新视图：修改启用用户的姓名，并查询基本表验证；回滚后恢复。
START TRANSACTION;
UPDATE v_active_user SET real_name = '中方外交官（演示）' WHERE username = 'dip_china';
SELECT username, real_name, is_active FROM app_user WHERE username = 'dip_china';
ROLLBACK;
-- 将 is_active 改为 0 会违反 WITH CHECK OPTION，请单独演示预期报错。
-- UPDATE v_active_user SET is_active = 0 WHERE username = 'dip_china';
