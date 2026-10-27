-- ============================================================
-- 课件补充示例：基础条件、自身连接、IN、ANY/ALL、UNION、空值和视图更新。
-- 来源章节：3.3 数据查询、3.5 视图；本文件可重复执行。
-- ============================================================
USE `multilateral-diplomacy-system-schoolwork-`;

-- 1. BETWEEN + LIKE：2026年已举行的上合组织会议。
SELECT short_name AS 会议, start_date AS 日期
FROM conference
WHERE start_date BETWEEN '2026-01-01' AND '2026-12-31'
  AND title LIKE '%上海合作组织%'
ORDER BY start_date, conference_id;

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

-- 5. ANY + 聚合：已登记参会国数超过至少一场部长会的会议。
-- COUNT得到已知数量，避免拿未公开的代表团人数作比较。
SELECT c.short_name AS 会议, COUNT(p.country_id) AS 已登记参会国数
FROM conference c LEFT JOIN conference_participant p ON p.conference_id = c.conference_id
GROUP BY c.conference_id, c.short_name
HAVING COUNT(p.country_id) > ANY (
  SELECT COUNT(x.country_id)
  FROM conference y LEFT JOIN conference_participant x ON x.conference_id = y.conference_id
  WHERE y.conference_type = '部长级会议'
  GROUP BY y.conference_id
)
ORDER BY 已登记参会国数 DESC, c.conference_id;

-- 6. ALL + 聚合：已登记参会国数最多的会议，保留并列结果。
-- 对应课件13第24页HAVING AVG(...) >= ALL(...)的结构。
SELECT c.short_name AS 会议, COUNT(p.country_id) AS 已登记参会国数
FROM conference c LEFT JOIN conference_participant p ON p.conference_id = c.conference_id
GROUP BY c.conference_id, c.short_name
HAVING COUNT(p.country_id) >= ALL (
  SELECT COUNT(*) FROM conference_participant GROUP BY conference_id
)
ORDER BY c.conference_id;

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

-- 9. 可更新视图：先建立事务内演示用户，保证UPDATE确实改到一行。
START TRANSACTION;
INSERT INTO app_user (username, real_name, user_role)
VALUES ('course_view_demo', '课程视图演示用户', '观察员');
SET @view_user = LAST_INSERT_ID();
UPDATE v_active_user SET real_name = '课程视图演示用户（已修改）'
WHERE user_id = @view_user;
SELECT username, real_name, is_active FROM app_user WHERE user_id = @view_user;
ROLLBACK;
-- WITH CHECK OPTION的违反测试及实际报错见09_constraint_samples.sql和SAMPLES.md。
