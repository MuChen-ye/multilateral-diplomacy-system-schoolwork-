-- ============================================================
-- 实验一 步骤 3(3)：使用 SQL 语言进行表结构的修改
-- 三步顺序执行：加列 -> 改列长 -> 删列
-- （加列后再删列，脚本可重复执行）
-- ============================================================

USE library_db071;

-- (1) 在 book_categories 表中增加 floor 属性列（楼层，默认允许为空）
ALTER TABLE book_categories
  ADD COLUMN floor INT NULL COMMENT '楼层';

-- (2) 把 readers 表中 phone 列的数据长度修改为 11
ALTER TABLE readers
  MODIFY COLUMN phone VARCHAR(11) NOT NULL COMMENT '手机号';

-- (3) 在 book_categories 表中删除 floor 列
ALTER TABLE book_categories
  DROP COLUMN floor;
