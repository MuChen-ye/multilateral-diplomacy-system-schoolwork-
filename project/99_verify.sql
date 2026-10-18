-- ============================================================
-- 验收自检脚本（只读，不修改数据）
-- 用途：答辩现场一键展示"表齐 / 约束齐 / 数据齐 / 对象齐"
-- ============================================================

USE `multilateral-diplomacy-system-schoolwork-`;

-- 1 各表精确行数
SELECT 'country'                  AS 表名, COUNT(*) AS 行数 FROM country
UNION ALL SELECT 'international_organization', COUNT(*) FROM international_organization
UNION ALL SELECT 'mechanism',                  COUNT(*) FROM mechanism
UNION ALL SELECT 'topic',                      COUNT(*) FROM topic
UNION ALL SELECT 'conference',                 COUNT(*) FROM conference
UNION ALL SELECT 'conference_participant',     COUNT(*) FROM conference_participant
UNION ALL SELECT 'conference_topic',           COUNT(*) FROM conference_topic
UNION ALL SELECT 'document',                   COUNT(*) FROM document
UNION ALL SELECT 'document_sponsor',           COUNT(*) FROM document_sponsor
UNION ALL SELECT 'follow_up_action',           COUNT(*) FROM follow_up_action
UNION ALL SELECT 'app_user',                   COUNT(*) FROM app_user
UNION ALL SELECT 'operation_log',              COUNT(*) FROM operation_log
ORDER BY 表名;

-- 2 约束清单（主键 / 唯一 / 外键 / 检查）
SELECT table_name AS 表, constraint_type AS 约束类型, COUNT(*) AS 数量
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
GROUP BY table_name, constraint_type
ORDER BY table_name, constraint_type;

-- 3 外键明细
SELECT constraint_name AS 外键名, table_name AS 子表, column_name AS 子表列,
       referenced_table_name AS 父表, referenced_column_name AS 父表列
FROM information_schema.key_column_usage
WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL
ORDER BY table_name, constraint_name;

-- 4 CHECK 约束数量
SELECT COUNT(*) AS 检查约束总数
FROM information_schema.check_constraints
WHERE constraint_schema = DATABASE();

-- 5 视图 / 触发器 / 存储过程 / 函数
SELECT table_name AS 视图名 FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_type = 'VIEW' ORDER BY table_name;

SELECT trigger_name AS 触发器, event_manipulation AS 时机, event_object_table AS 表
FROM information_schema.triggers WHERE trigger_schema = DATABASE();

SELECT routine_name AS 例程名, routine_type AS 类型
FROM information_schema.routines WHERE routine_schema = DATABASE();

-- 6 索引数量
SELECT table_name AS 表, COUNT(DISTINCT index_name) AS 索引数
FROM information_schema.statistics
WHERE table_schema = DATABASE() GROUP BY table_name ORDER BY table_name;
