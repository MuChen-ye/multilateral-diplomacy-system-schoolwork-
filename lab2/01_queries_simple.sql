-- ============================================================
-- 实验二 1.(1) 简单查询（6 小题）
-- 基于实验一建立的 library_db071
-- 执行：mysql -u root --default-character-set=utf8mb4 -t -v < 01_queries_simple.sql
-- ============================================================

USE library_db071;

-- ① 查询 publishers 表中出版社都分布在哪些城市（重复城市只显示一次）
SELECT DISTINCT city AS '城市'
FROM publishers
ORDER BY city;

-- ② 查询所有男学生的姓名、性别、手机号，并按注册日期升序排列
SELECT name AS '姓名', gender AS '性别', phone AS '手机号'
FROM readers
WHERE gender = '男' AND reader_type = '学生'
ORDER BY registered ASC;

-- ③ 查询 2023-2024 年期间注册的所有读者的姓名、借书证号和注册日期
SELECT name AS '姓名', card_no AS '借书证号', registered AS '注册日期'
FROM readers
WHERE registered BETWEEN '2023-01-01' AND '2024-12-31'
ORDER BY registered ASC, reader_id ASC;

-- ④ 统计每种读者类型（学生、教师、职工）各有多少人
SELECT reader_type AS '读者类型', COUNT(*) AS '人数'
FROM readers
GROUP BY reader_type
ORDER BY 人数 DESC;

-- ⑤ 查询每本图书的“在借册数”（在借册数 = 馆藏总册数 − 可借册数），显示书名和在借册数
SELECT title AS '书名',
       total_copies - available AS '在借册数'
FROM books
ORDER BY 在借册数 DESC, book_id ASC;

-- ⑥ 查询可借出数量最多的前 3 本图书的书名和可借出数量
SELECT title AS '书名', available AS '可借出数量'
FROM books
ORDER BY available DESC, book_id ASC
LIMIT 3;
