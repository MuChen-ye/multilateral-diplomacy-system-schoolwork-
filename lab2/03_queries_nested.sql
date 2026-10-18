-- ============================================================
-- 实验二 1.(3) 嵌套查询（6 小题）
-- 执行：mysql -u root --default-character-set=utf8mb4 -t -v < 03_queries_nested.sql
-- ============================================================

USE library_db071;

-- ① 查询馆藏总册数最多的那本书的书名和总册数
SELECT title AS '书名', total_copies AS '总册数'
FROM books
WHERE total_copies = (SELECT MAX(total_copies) FROM books);

-- ② 查询与“沈念”读者类型相同的其他读者的姓名和读者类型
SELECT name AS '姓名', reader_type AS '读者类型'
FROM readers
WHERE reader_type = (SELECT reader_type FROM readers WHERE name = '沈念')
  AND name <> '沈念'
ORDER BY name;

-- ③ 查询存在“借阅中”记录的所有读者的姓名和读者类型
SELECT name AS '姓名', reader_type AS '读者类型'
FROM readers
WHERE reader_id IN (SELECT reader_id FROM borrow_records WHERE status = '借阅中')
ORDER BY reader_id;

-- ④ 查询定价高于“经济管理”分类中所有图书定价的图书的书名、价格、所属类别
SELECT b.title AS '书名', b.price AS '价格', c.name AS '所属类别'
FROM books b
JOIN book_categories c ON c.category_id = b.category_id
WHERE b.price > ALL (
        SELECT b2.price
        FROM books b2
        JOIN book_categories c2 ON c2.category_id = b2.category_id
        WHERE c2.name = '经济管理' AND b2.price IS NOT NULL
      )
ORDER BY b.price DESC;

-- ⑤ 查询借过“计算机科学”分类图书的读者姓名
SELECT name AS '读者姓名'
FROM readers
WHERE reader_id IN (
        SELECT br.reader_id
        FROM borrow_records br
        JOIN books b           ON b.book_id    = br.book_id
        JOIN book_categories c ON c.category_id = b.category_id
        WHERE c.name = '计算机科学'
      )
ORDER BY reader_id;

-- ⑥ 查询出版图书数量比“上海译文出版社”多的出版社名称
SELECT p.name AS '出版社', COUNT(*) AS '图书数量'
FROM publishers p
JOIN books b ON b.publisher_id = p.publisher_id
GROUP BY p.publisher_id, p.name
HAVING COUNT(*) > (
        SELECT COUNT(*)
        FROM books b2
        JOIN publishers p2 ON p2.publisher_id = b2.publisher_id
        WHERE p2.name = '上海译文出版社'
      )
ORDER BY 图书数量 DESC, p.publisher_id;
