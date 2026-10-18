-- ============================================================
-- 数据库原理 实验一  步骤 1：创建数据库
-- 命名规则：library_db + 学号后 3 位（本机为 071）
-- 执行：mysql -u root --default-character-set=utf8mb4 < 01_create_database.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS library_db071
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE library_db071;
