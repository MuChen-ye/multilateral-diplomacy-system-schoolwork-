-- ============================================================
-- 实验二 2. 数据更新与删除（4 小题）
-- 每步都先 SELECT 出「更新前」，UPDATE 后用 ROW_COUNT() 显示影响行数，
-- 再 SELECT 出「更新后」，保证截图能自证。
--
-- 注意：本文件会改动数据，重复执行前请先用实验一的 03_insert_data.sql 重置数据
--       （lab2/run_all.ps1 已按「先重建实验一 → 再跑实验二」的顺序编排）。
-- ============================================================

USE library_db071;

-- ① 把所有学生的最大可借册数统一改为 6
SELECT name AS '姓名', reader_type AS '读者类型', max_borrow AS '最大可借(改前)'
FROM readers WHERE reader_type = '学生' ORDER BY reader_id;

UPDATE readers
SET max_borrow = 6
WHERE reader_type = '学生';

SELECT ROW_COUNT() AS '本次影响行数';

SELECT name AS '姓名', reader_type AS '读者类型', max_borrow AS '最大可借(改后)'
FROM readers ORDER BY reader_id;

-- ② 图书馆采购了 2 本《数据结构(C语言版)》，更新其馆藏总册数和可借册数
SELECT title AS '书名', total_copies AS '总册数(改前)', available AS '可借(改前)'
FROM books WHERE title = '数据结构(C语言版)';

UPDATE books
SET total_copies = total_copies + 2,
    available    = available + 2
WHERE title = '数据结构(C语言版)';

SELECT ROW_COUNT() AS '本次影响行数';

SELECT title AS '书名', total_copies AS '总册数(改后)', available AS '可借(改后)'
FROM books WHERE title = '数据结构(C语言版)';

-- ③ 读者“陈晨”归还了《百年孤独》：实际归还日期 2026-10-11、状态改为已归还，
--    并把该书的可借册数加 1（两步放在一个事务里，避免只改一半）
SELECT r.name AS '读者', b.title AS '书名', br.borrow_date AS '借阅日期',
       br.due_date AS '应还日期', IFNULL(br.return_date, 'NULL') AS '归还日期',
       br.status AS '状态', b.available AS '可借(改前)'
FROM borrow_records br
JOIN readers r ON r.reader_id = br.reader_id
JOIN books b   ON b.book_id   = br.book_id
WHERE r.name = '陈晨' AND b.title = '百年孤独';

START TRANSACTION;

UPDATE borrow_records br
JOIN readers r ON r.reader_id = br.reader_id
JOIN books   b ON b.book_id   = br.book_id
SET br.return_date = '2026-10-11',
    br.status      = '已归还'
WHERE r.name = '陈晨' AND b.title = '百年孤独' AND br.status = '借阅中';

SELECT ROW_COUNT() AS '借阅记录影响行数';

UPDATE books
SET available = available + 1
WHERE title = '百年孤独';

SELECT ROW_COUNT() AS '图书影响行数';

COMMIT;

SELECT r.name AS '读者', b.title AS '书名', br.return_date AS '归还日期',
       br.status AS '状态', b.available AS '可借(改后)'
FROM borrow_records br
JOIN readers r ON r.reader_id = br.reader_id
JOIN books b   ON b.book_id   = br.book_id
WHERE r.name = '陈晨' AND b.title = '百年孤独';

-- ④ 在 publishers 表中录入一条测试数据：“测试出版社，秦皇岛，2026”，然后再删除
SELECT COUNT(*) AS '录入前出版社数量' FROM publishers;

INSERT INTO publishers (name, city, founded_year)
VALUES ('测试出版社', '秦皇岛', 2026);

SELECT publisher_id AS 'ID', name AS '出版社', city AS '城市', founded_year AS '成立年份'
FROM publishers WHERE name = '测试出版社';

DELETE FROM publishers
WHERE name = '测试出版社';

SELECT ROW_COUNT() AS '删除行数';

SELECT COUNT(*) AS '删除后出版社数量' FROM publishers;
