-- ============================================================
-- 实验二 3. 使用 SQL 进行数据完整性控制（4 小题）
--
-- 执行时必须带 -f（强制继续），否则第一条“故意制造的报错”就会中断整个脚本：
--   mysql -u root --default-character-set=utf8mb4 -t -v -f < 05_constraints.sql
--
-- 实验一的建表语句里已经带了同类约束，所以每步先「删掉同名约束再加」，
-- 既能看到 ADD CONSTRAINT 的 DDL 执行过程，也保证本脚本可重复执行。
-- ============================================================

USE library_db071;

-- ① 为 readers 表的 card_no 字段添加唯一约束，保证借书证号不重复
SELECT IF(COUNT(*) > 0,
          '实验一已建同名唯一约束 uk_readers_card_no，先删除再重新添加以便演示',
          '当前无该约束，直接添加') AS '执行说明'
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'readers' AND INDEX_NAME = 'uk_readers_card_no';

SET @n := (SELECT COUNT(*) FROM information_schema.STATISTICS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'readers' AND INDEX_NAME = 'uk_readers_card_no');
SET @s := IF(@n > 0, 'ALTER TABLE readers DROP INDEX uk_readers_card_no', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

ALTER TABLE readers
  ADD UNIQUE KEY uk_readers_card_no (card_no);

--    验证：插入与已有 card_no 重复的记录，系统应拒绝
INSERT INTO readers (name, card_no, gender, phone, reader_type, max_borrow, registered)
VALUES ('测试重复证号', 'RD20230001', '男', '13500000999', '学生', 5, '2026-09-01');

-- ② 为 readers 表的 gender 字段添加约束：性别只能取 男 或 女
SET @n := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
           WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'readers'
             AND CONSTRAINT_TYPE = 'CHECK');
SET @s := IF(@n > 0,
             'ALTER TABLE readers DROP CHECK ck_readers_gender',
             'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

ALTER TABLE readers
  ADD CONSTRAINT ck_readers_gender CHECK (gender IN ('男', '女'));

--    验证：插入性别为 F 的记录，系统应拒绝
INSERT INTO readers (name, card_no, gender, phone, reader_type, max_borrow, registered)
VALUES ('测试性别', 'TEST0001', 'F', '13500000001', '学生', 5, '2026-09-01');

-- ③ 为 books 表添加 CHECK 约束：可借册数 available 只能是正数，且不超过馆藏总册数 total_copies
SET @n := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
           WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'books'
             AND CONSTRAINT_TYPE = 'CHECK' AND CONSTRAINT_NAME = 'ck_books_available');
SET @s := IF(@n > 0, 'ALTER TABLE books DROP CHECK ck_books_available', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

ALTER TABLE books
  ADD CONSTRAINT ck_books_available_positive
  CHECK (available > 0 AND available <= total_copies);

--    验证：把可借册数改成超过馆藏总册数，系统应拒绝
UPDATE books SET available = 999 WHERE book_id = 1;

-- ④ 修改 books 表的约束条件：可借册数不能是负数，且不超过馆藏总册数
ALTER TABLE books
  DROP CHECK ck_books_available_positive;

ALTER TABLE books
  ADD CONSTRAINT ck_books_available
  CHECK (available >= 0 AND available <= total_copies);

--    验证：把可借册数改成负数，系统应拒绝
UPDATE books SET available = -1 WHERE book_id = 1;

-- ⑤ 收尾：列出 readers / books 上当前的完整性约束，确认最终状态
SELECT TABLE_NAME AS '表名', CONSTRAINT_NAME AS '约束名', CONSTRAINT_TYPE AS '类型'
FROM information_schema.TABLE_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('readers', 'books')
ORDER BY TABLE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME;

--    被拒绝的 4 条非法写入没有留下任何数据，实例数据仍是实验一的 10 条
SELECT 'readers' AS '表', COUNT(*) AS '行数' FROM readers
UNION ALL
SELECT 'books', COUNT(*) FROM books;
