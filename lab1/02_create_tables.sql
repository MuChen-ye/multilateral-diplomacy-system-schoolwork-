-- ============================================================
-- 实验一 步骤 2：创建数据表与表间联系
-- 5 张表：readers / publishers / book_categories / books / borrow_records
-- 外键：books -> publishers, book_categories
--       borrow_records -> readers, books
-- ============================================================

USE library_db071;

-- 先按外键依赖的逆序删表，保证脚本可重复执行
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS borrow_records;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS book_categories;
DROP TABLE IF EXISTS publishers;
DROP TABLE IF EXISTS readers;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------- 表 1 readers 读者表 ----------
CREATE TABLE readers (
  reader_id   INT         NOT NULL AUTO_INCREMENT COMMENT '读者ID',
  name        VARCHAR(20) NOT NULL                COMMENT '姓名',
  card_no     VARCHAR(20) NOT NULL                COMMENT '借书证号',
  gender      CHAR(1)     NOT NULL                COMMENT '性别',
  phone       VARCHAR(20) NOT NULL                COMMENT '手机号',
  birthday    DATE             NULL               COMMENT '出生日期',
  reader_type ENUM('学生','教师','职工') NULL     COMMENT '读者类型',
  max_borrow  INT              NULL               COMMENT '最大可借册数',
  registered  DATE             NULL               COMMENT '注册日期',
  PRIMARY KEY (reader_id),
  UNIQUE KEY uk_readers_card_no (card_no),
  CONSTRAINT ck_readers_gender     CHECK (gender IN ('男','女')),
  CONSTRAINT ck_readers_max_borrow CHECK (max_borrow IS NULL OR max_borrow >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='读者表';

-- ---------- 表 2 publishers 出版社表 ----------
CREATE TABLE publishers (
  publisher_id INT         NOT NULL AUTO_INCREMENT COMMENT '出版社ID',
  name         VARCHAR(30) NOT NULL                COMMENT '出版社名称',
  city         VARCHAR(30)     NULL                COMMENT '所在城市',
  founded_year YEAR            NULL                COMMENT '成立年份',
  PRIMARY KEY (publisher_id),
  UNIQUE KEY uk_publishers_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='出版社表';

-- ---------- 表 3 book_categories 图书分类表 ----------
CREATE TABLE book_categories (
  category_id INT         NOT NULL AUTO_INCREMENT COMMENT '分类ID',
  name        VARCHAR(20) NOT NULL                COMMENT '分类名称',
  location    VARCHAR(20)     NULL                COMMENT '馆藏位置(如:A区1架)',
  PRIMARY KEY (category_id),
  UNIQUE KEY uk_categories_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书分类表';

-- ---------- 表 4 books 图书表 ----------
CREATE TABLE books (
  book_id      INT         NOT NULL AUTO_INCREMENT COMMENT '图书ID',
  isbn         VARCHAR(20) NOT NULL                COMMENT 'ISBN号',
  title        VARCHAR(50) NOT NULL                COMMENT '书名',
  author       VARCHAR(20)     NULL                COMMENT '作者',
  publisher_id INT         NOT NULL                COMMENT '出版社ID',
  category_id  INT         NOT NULL                COMMENT '分类ID',
  price        DECIMAL(8,2)    NULL                COMMENT '定价',
  total_copies INT             NULL                COMMENT '馆藏总册数',
  available    INT             NULL                COMMENT '可借册数',
  PRIMARY KEY (book_id),
  UNIQUE KEY uk_books_isbn (isbn),
  KEY idx_books_publisher (publisher_id),
  KEY idx_books_category  (category_id),
  CONSTRAINT fk_books_publisher FOREIGN KEY (publisher_id) REFERENCES publishers (publisher_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_books_category  FOREIGN KEY (category_id)  REFERENCES book_categories (category_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_books_price     CHECK (price IS NULL OR price >= 0),
  CONSTRAINT ck_books_available CHECK (available IS NULL OR total_copies IS NULL OR available <= total_copies)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书表';

-- ---------- 表 5 borrow_records 借阅记录表 ----------
CREATE TABLE borrow_records (
  record_id   INT      NOT NULL AUTO_INCREMENT COMMENT '借阅记录ID',
  reader_id   INT      NOT NULL                COMMENT '读者ID',
  book_id     INT      NOT NULL                COMMENT '图书ID',
  borrow_date DATE     NOT NULL                COMMENT '借阅日期',
  due_date    DATE     NOT NULL                COMMENT '应还日期',
  return_date DATE         NULL                COMMENT '实际归还日期(未还为NULL)',
  status      ENUM('借阅中','已归还','逾期') NULL DEFAULT '借阅中' COMMENT '状态',
  PRIMARY KEY (record_id),
  KEY idx_borrow_reader (reader_id),
  KEY idx_borrow_book   (book_id),
  CONSTRAINT fk_borrow_reader FOREIGN KEY (reader_id) REFERENCES readers (reader_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_borrow_book   FOREIGN KEY (book_id)   REFERENCES books (book_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_borrow_dates  CHECK (due_date >= borrow_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='借阅记录表';
