-- ============================================================
-- 实验一 约束反证：故意写入非法数据，验证约束真的在库内生效
--
-- 必须用「强制继续」方式执行，否则第一条报错就会中断整个脚本：
--     mysql -u root --default-character-set=utf8mb4 -f < 98_constraint_tests.sql
-- （run_all.ps1 已带 -f；Navicat 里执行时会逐条弹错，选「继续」即可）
--
-- 每条 INSERT 后面都写明了「预期报错」，全部被拒绝才说明约束有效；
-- 执行完数据一条都不会多（下面第 8 节会复核行数）。
-- ============================================================

USE library_db071;

-- ------------------------------------------------------------
-- 1. 唯一约束：借书证号重复（预期 ERROR 1062 Duplicate entry）
-- ------------------------------------------------------------
SELECT '===== 1. 唯一键：重复借书证号（预期 1062） =====' AS '';
INSERT INTO readers (name, card_no, gender, phone)
VALUES ('测试重复', 'RD20230001', '男', '13500000000');

-- ------------------------------------------------------------
-- 2. 非空约束：card_no 传 NULL（预期 ERROR 1048 Column cannot be null）
-- ------------------------------------------------------------
SELECT '===== 2. 非空：card_no 为 NULL（预期 1048） =====' AS '';
INSERT INTO readers (name, card_no, gender, phone)
VALUES ('测试空值', NULL, '男', '13500000001');

-- ------------------------------------------------------------
-- 3. CHECK 约束：性别不在 男/女 之内（预期 ERROR 3819 Check constraint violated）
-- ------------------------------------------------------------
SELECT '===== 3. CHECK：gender = X（预期 3819） =====' AS '';
INSERT INTO readers (name, card_no, gender, phone)
VALUES ('测试性别', 'TEST0003', 'X', '13500000003');

-- ------------------------------------------------------------
-- 4. 外键约束：引用不存在的出版社 999（预期 ERROR 1452 Cannot add or update a child row）
-- ------------------------------------------------------------
SELECT '===== 4. 外键：publisher_id = 999（预期 1452） =====' AS '';
INSERT INTO books (isbn, title, publisher_id, category_id)
VALUES ('9999999999999', '测试书', 999, 1);

-- ------------------------------------------------------------
-- 5. CHECK 约束：可借册数 > 馆藏总册数（预期 ERROR 3819）
-- ------------------------------------------------------------
SELECT '===== 5. CHECK：available > total_copies（预期 3819） =====' AS '';
INSERT INTO books (isbn, title, publisher_id, category_id, total_copies, available)
VALUES ('9999999999998', '测试库存', 1, 1, 2, 5);

-- ------------------------------------------------------------
-- 6. ENUM 约束：状态写成「丢失」（预期 ERROR 1265 Data truncated / 错误值）
-- ------------------------------------------------------------
SELECT '===== 6. ENUM：status = 丢失（预期 1265） =====' AS '';
INSERT INTO borrow_records (reader_id, book_id, borrow_date, due_date, status)
VALUES (1, 1, '2026-01-01', '2026-02-01', '丢失');

-- ------------------------------------------------------------
-- 7. CHECK 约束：应还日期早于借阅日期（预期 ERROR 3819）
-- ------------------------------------------------------------
SELECT '===== 7. CHECK：due_date < borrow_date（预期 3819） =====' AS '';
INSERT INTO borrow_records (reader_id, book_id, borrow_date, due_date)
VALUES (1, 1, '2026-02-01', '2026-01-01');

-- ------------------------------------------------------------
-- 8. 复核：以上 7 条全部被拒，数据应保持 10/6/6/10/10 不变
-- ------------------------------------------------------------
SELECT '===== 8. 反证后行数复核（应仍是 10/6/6/10/10） =====' AS '';
SELECT 'readers'         AS '表', COUNT(*) AS '行数' FROM readers
UNION ALL SELECT 'publishers',      COUNT(*) FROM publishers
UNION ALL SELECT 'book_categories', COUNT(*) FROM book_categories
UNION ALL SELECT 'books',           COUNT(*) FROM books
UNION ALL SELECT 'borrow_records',  COUNT(*) FROM borrow_records;

-- ------------------------------------------------------------
-- 9. 拨回自增计数器
--    InnoDB 即使插入被约束拒绝，也会先占掉一个自增值，
--    所以上面 7 次失败让 readers/books 的计数器跳到了 12。
--    这里拨回「最大 ID + 1」，让库里重新是干净的 id 1~10。
-- ------------------------------------------------------------
SELECT '===== 9. 复原自增计数器（下一个 ID 应为 11） =====' AS '';
ALTER TABLE readers        AUTO_INCREMENT = 11;
ALTER TABLE books          AUTO_INCREMENT = 11;
ALTER TABLE borrow_records AUTO_INCREMENT = 11;

SELECT TABLE_NAME AS '表', AUTO_INCREMENT AS '下一个ID'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'library_db071'
ORDER BY TABLE_NAME;
