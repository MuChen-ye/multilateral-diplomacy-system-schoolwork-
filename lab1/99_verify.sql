-- ============================================================
-- 实验一 全流程自检（只读，不改数据）
-- 对应指导书：步骤 1 建库 / 步骤 2 建表 / 步骤 3 录入 /
--             步骤 4 表结构修改 / 表间联系与约束
-- 用法：mysql -u root --default-character-set=utf8mb4 < 99_verify.sql
--
-- 输出按 1~7 分节，每节都对应实验报告里的一张截图，可直接照拍。
-- ============================================================

USE library_db071;

-- ------------------------------------------------------------
-- 1. 数据库：存在、字符集
-- ------------------------------------------------------------
SELECT '===== 1. 数据库 library_db071 =====' AS '';
SELECT SCHEMA_NAME AS '库名',
       DEFAULT_CHARACTER_SET_NAME AS '字符集',
       DEFAULT_COLLATION_NAME AS '排序规则'
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'library_db071';

-- ------------------------------------------------------------
-- 2. 数据表：5 张表是否齐全
-- ------------------------------------------------------------
SELECT '===== 2. 数据表清单（应为 5 张） =====' AS '';
SELECT TABLE_NAME AS '表名', ENGINE AS '引擎',
       TABLE_COLLATION AS '排序规则', TABLE_COMMENT AS '注释'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'library_db071'
ORDER BY TABLE_NAME;

-- ------------------------------------------------------------
-- 3. 表结构：每张表的字段、类型、可空、键、默认值、注释
--    （对应指导书表 1~表 5 的数据类型/长度/是否允许为空）
-- ------------------------------------------------------------
SELECT '===== 3. 字段定义 =====' AS '';
SELECT TABLE_NAME     AS '表名',
       ORDINAL_POSITION AS '序',
       COLUMN_NAME    AS '字段名',
       COLUMN_TYPE    AS '数据类型(含长度/精度)',
       IS_NULLABLE    AS '允许为空',
       COLUMN_KEY     AS '键',
       IFNULL(COLUMN_DEFAULT, 'NULL') AS '默认值',
       EXTRA          AS '附加',
       COLUMN_COMMENT AS '注释'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'library_db071'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- ------------------------------------------------------------
-- 4. 约束：主键 / 唯一 / 外键 / CHECK
-- ------------------------------------------------------------
SELECT '===== 4. 约束清单 =====' AS '';
SELECT TABLE_NAME AS '表名', CONSTRAINT_NAME AS '约束名', CONSTRAINT_TYPE AS '类型'
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'library_db071'
ORDER BY TABLE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME;

SELECT '===== 4.1 表间联系（外键） =====' AS '';
SELECT k.CONSTRAINT_NAME AS '外键名',
       k.TABLE_NAME      AS '从表',
       k.COLUMN_NAME     AS '从表列',
       k.REFERENCED_TABLE_NAME  AS '主表',
       k.REFERENCED_COLUMN_NAME AS '主表列',
       r.UPDATE_RULE AS '更新策略',
       r.DELETE_RULE AS '删除策略'
FROM information_schema.KEY_COLUMN_USAGE k
JOIN information_schema.REFERENTIAL_CONSTRAINTS r
  ON r.CONSTRAINT_SCHEMA = k.CONSTRAINT_SCHEMA
 AND r.CONSTRAINT_NAME   = k.CONSTRAINT_NAME
WHERE k.TABLE_SCHEMA = 'library_db071'
  AND k.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY k.TABLE_NAME, k.CONSTRAINT_NAME;

-- 注：MySQL 9.4 的 information_schema.CHECK_CONSTRAINTS.CHECK_CLAUSE 会把
--     带中文的表达式二次编码成乱码（服务端元数据的已知小毛病），所以这里只列
--     约束名；校验表达式的原文请直接看 02_create_tables.sql 或 Navicat 的「检查」页。
SELECT '===== 4.2 CHECK 约束（表达式原文见 02_create_tables.sql） =====' AS '';
SELECT TABLE_NAME AS '表名', CONSTRAINT_NAME AS '约束名'
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'library_db071' AND CONSTRAINT_TYPE = 'CHECK'
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- ------------------------------------------------------------
-- 5. 索引（含自增主键、唯一键、外键索引）
-- ------------------------------------------------------------
SELECT '===== 5. 索引 =====' AS '';
SELECT TABLE_NAME AS '表名', INDEX_NAME AS '索引名',
       GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS '列',
       IF(NON_UNIQUE = 0, '唯一', '普通') AS '唯一性'
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'library_db071'
GROUP BY TABLE_NAME, INDEX_NAME, NON_UNIQUE
ORDER BY TABLE_NAME, INDEX_NAME;

-- ------------------------------------------------------------
-- 6. 数据：行数 + 全量数据（10/6/6/10/10）
-- ------------------------------------------------------------
SELECT '===== 6. 各表行数 =====' AS '';
SELECT 'readers'         AS '表', COUNT(*) AS '行数' FROM readers
UNION ALL SELECT 'publishers',     COUNT(*) FROM publishers
UNION ALL SELECT 'book_categories', COUNT(*) FROM book_categories
UNION ALL SELECT 'books',          COUNT(*) FROM books
UNION ALL SELECT 'borrow_records', COUNT(*) FROM borrow_records;

SELECT '===== 6.1 readers 读者表 =====' AS '';
SELECT reader_id AS 'ID', name AS '姓名', card_no AS '借书证号', gender AS '性别',
       phone AS '手机号', birthday AS '出生日期', reader_type AS '读者类型',
       max_borrow AS '最大可借', registered AS '注册日期'
FROM readers ORDER BY reader_id;

SELECT '===== 6.2 publishers 出版社表 =====' AS '';
SELECT publisher_id AS 'ID', name AS '出版社', city AS '城市', founded_year AS '成立年份'
FROM publishers ORDER BY publisher_id;

SELECT '===== 6.3 book_categories 图书分类表 =====' AS '';
SELECT category_id AS 'ID', name AS '分类', location AS '馆藏位置'
FROM book_categories ORDER BY category_id;

SELECT '===== 6.4 books 图书表 =====' AS '';
SELECT book_id AS 'ID', isbn AS 'ISBN', title AS '书名', author AS '作者',
       publisher_id AS '出版社ID', category_id AS '分类ID',
       price AS '定价', total_copies AS '总册数', available AS '可借'
FROM books ORDER BY book_id;

SELECT '===== 6.5 borrow_records 借阅记录表 =====' AS '';
SELECT record_id AS 'ID', reader_id AS '读者ID', book_id AS '图书ID',
       borrow_date AS '借阅日期', due_date AS '应还日期',
       IFNULL(return_date, 'NULL') AS '归还日期', status AS '状态'
FROM borrow_records ORDER BY record_id;

-- ------------------------------------------------------------
-- 7. 步骤 4 表结构修改：逐条验收
-- ------------------------------------------------------------
SELECT '===== 7. 表结构修改验收 =====' AS '';

-- (1)(3) book_categories 中 floor 列：加过又删掉，最终不应存在
SELECT '7.1 book_categories 当前列（final 应无 floor）' AS '';
SELECT ORDINAL_POSITION AS '序', COLUMN_NAME AS '字段名', COLUMN_TYPE AS '类型'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'library_db071' AND TABLE_NAME = 'book_categories'
ORDER BY ORDINAL_POSITION;

SELECT '7.2 floor 列是否已删除（预期 0）' AS '';
SELECT COUNT(*) AS 'floor 列个数'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'library_db071'
  AND TABLE_NAME = 'book_categories'
  AND COLUMN_NAME = 'floor';

-- (2) readers.phone 长度应为 11
SELECT '7.3 readers.phone 的长度（预期 11）' AS '';
SELECT COLUMN_NAME AS '字段名', COLUMN_TYPE AS '类型',
       CHARACTER_MAXIMUM_LENGTH AS '长度',
       IS_NULLABLE AS '允许为空'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'library_db071'
  AND TABLE_NAME = 'readers'
  AND COLUMN_NAME = 'phone';

-- 11 位手机号是否完整未被截断（预期 10 条均为 11 位）
SELECT '7.4 手机号位数分布（预期 全部 11 位）' AS '';
SELECT CHAR_LENGTH(phone) AS '位数', COUNT(*) AS '条数'
FROM readers GROUP BY CHAR_LENGTH(phone);

-- ------------------------------------------------------------
-- 8. 表间联系可用性：多表连接查询抽样
-- ------------------------------------------------------------
SELECT '===== 8. 多表连接抽样（证明外键关系可用） =====' AS '';
SELECT b.book_id AS 'ID', b.title AS '书名', p.name AS '出版社',
       c.name AS '分类', b.price AS '定价'
FROM books b
JOIN publishers p     ON p.publisher_id = b.publisher_id
JOIN book_categories c ON c.category_id = b.category_id
ORDER BY b.book_id;

SELECT '===== 8.1 借阅全链路（读者-图书-出版社） =====' AS '';
SELECT r.record_id AS '记录', rd.name AS '读者', bk.title AS '书名',
       p.name AS '出版社', r.borrow_date AS '借阅', r.due_date AS '应还',
       r.status AS '状态'
FROM borrow_records r
JOIN readers rd ON rd.reader_id = r.reader_id
JOIN books bk   ON bk.book_id   = r.book_id
JOIN publishers p ON p.publisher_id = bk.publisher_id
ORDER BY r.record_id;

-- 借阅中/逾期 的记录不应有归还日期，已归还的必须有 —— 一致性自检
SELECT '===== 8.2 状态与归还日期一致性（预期 0 行异常） =====' AS '';
SELECT record_id, status, return_date
FROM borrow_records
WHERE (status IN ('借阅中','逾期') AND return_date IS NOT NULL)
   OR (status = '已归还'  AND return_date IS NULL);
