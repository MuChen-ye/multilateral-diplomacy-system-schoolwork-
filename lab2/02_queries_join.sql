-- ============================================================
-- 实验二 1.(2) 连接查询（6 小题）
-- 执行：mysql -u root --default-character-set=utf8mb4 -t -v < 02_queries_join.sql
-- ============================================================

USE library_db071;

-- ① 查询每种分类的图书名称、馆藏总册数合计，并按馆藏量降序排列
SELECT c.name AS '分类',
       GROUP_CONCAT(b.title ORDER BY b.book_id SEPARATOR '、') AS '图书名称',
       SUM(b.total_copies) AS '馆藏总册数合计'
FROM book_categories c
JOIN books b ON b.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY 馆藏总册数合计 DESC;

-- ② 查询状态为“逾期”的借阅记录，显示借阅人、借阅日期、应还日期，按借阅日期升序排列
SELECT r.name AS '借阅人', br.borrow_date AS '借阅日期', br.due_date AS '应还日期'
FROM borrow_records br
JOIN readers r ON r.reader_id = br.reader_id
WHERE br.status = '逾期'
ORDER BY br.borrow_date ASC;

-- ③ 查询书名中包含“计算机”三个字的图书信息，显示书名、作者、出版社、馆藏总册数、可借册数、馆藏位置
SELECT b.title AS '书名', b.author AS '作者', p.name AS '出版社',
       b.total_copies AS '馆藏总册数', b.available AS '可借册数', c.location AS '馆藏位置'
FROM books b
JOIN publishers p      ON p.publisher_id = b.publisher_id
JOIN book_categories c ON c.category_id  = b.category_id
WHERE b.title LIKE '%计算机%';

-- ④ 查询陈晨所有状态为“借阅中”的记录应去哪个馆藏位置还书，显示读者姓名、书名和馆藏位置
SELECT r.name AS '读者姓名', b.title AS '书名', c.location AS '馆藏位置'
FROM borrow_records br
JOIN readers r         ON r.reader_id  = br.reader_id
JOIN books b           ON b.book_id    = br.book_id
JOIN book_categories c ON c.category_id = b.category_id
WHERE r.name = '陈晨' AND br.status = '借阅中'
ORDER BY br.borrow_date;

-- ⑤ 统计每个出版社出版的图书数量，仅显示出版数量不少于 2 本的出版社，按图书数量降序排列
SELECT p.name AS '出版社', COUNT(*) AS '图书数量'
FROM publishers p
JOIN books b ON b.publisher_id = p.publisher_id
GROUP BY p.publisher_id, p.name
HAVING COUNT(*) >= 2
ORDER BY 图书数量 DESC, p.publisher_id;

-- ⑥ 查询借过“计算机科学”分类图书的读者姓名和图书名称
SELECT DISTINCT r.name AS '读者姓名', b.title AS '图书名称'
FROM borrow_records br
JOIN readers r         ON r.reader_id  = br.reader_id
JOIN books b           ON b.book_id    = br.book_id
JOIN book_categories c ON c.category_id = b.category_id
WHERE c.name = '计算机科学'
ORDER BY r.name, b.title;
