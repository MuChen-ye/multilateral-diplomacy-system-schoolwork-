-- MySQL dump 10.13  Distrib 9.4.0, for Win64 (x86_64)
--
-- Host: localhost    Database: library_db071
-- ------------------------------------------------------
-- Server version	9.4.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `book_categories`
--

DROP TABLE IF EXISTS `book_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_categories` (
  `category_id` int NOT NULL AUTO_INCREMENT COMMENT '分类ID',
  `name` varchar(20) NOT NULL COMMENT '分类名称',
  `location` varchar(20) DEFAULT NULL COMMENT '馆藏位置(如:A区1架)',
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `uk_categories_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='图书分类表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_categories`
--

LOCK TABLES `book_categories` WRITE;
/*!40000 ALTER TABLE `book_categories` DISABLE KEYS */;
INSERT INTO `book_categories` VALUES (1,'计算机科学','A区1架'),(2,'文学小说','B区2架'),(3,'历史传记','C区1架'),(4,'经济管理','D区3架'),(5,'自然科学','E区1架'),(6,'教育心理','F区2架');
/*!40000 ALTER TABLE `book_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `books`
--

DROP TABLE IF EXISTS `books`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `books` (
  `book_id` int NOT NULL AUTO_INCREMENT COMMENT '图书ID',
  `isbn` varchar(20) NOT NULL COMMENT 'ISBN号',
  `title` varchar(50) NOT NULL COMMENT '书名',
  `author` varchar(20) DEFAULT NULL COMMENT '作者',
  `publisher_id` int NOT NULL COMMENT '出版社ID',
  `category_id` int NOT NULL COMMENT '分类ID',
  `price` decimal(8,2) DEFAULT NULL COMMENT '定价',
  `total_copies` int DEFAULT NULL COMMENT '馆藏总册数',
  `available` int DEFAULT NULL COMMENT '可借册数',
  PRIMARY KEY (`book_id`),
  UNIQUE KEY `uk_books_isbn` (`isbn`),
  KEY `idx_books_publisher` (`publisher_id`),
  KEY `idx_books_category` (`category_id`),
  CONSTRAINT `fk_books_category` FOREIGN KEY (`category_id`) REFERENCES `book_categories` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_books_publisher` FOREIGN KEY (`publisher_id`) REFERENCES `publishers` (`publisher_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `ck_books_available` CHECK (((`available` is null) or (`total_copies` is null) or (`available` <= `total_copies`))),
  CONSTRAINT `ck_books_price` CHECK (((`price` is null) or (`price` >= 0)))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='图书表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `books`
--

LOCK TABLES `books` WRITE;
/*!40000 ALTER TABLE `books` DISABLE KEYS */;
INSERT INTO `books` VALUES (1,'9787115561331','算法导论(原书第3版)','Thomas H. Cormen',1,1,128.00,3,2),(2,'9787111557930','深入理解计算机系统','Randal E. Bryant',1,1,139.00,2,1),(3,'9787115424911','MySQL必知必会','Ben Forta',2,1,49.00,5,4),(4,'9787302423287','数据结构(C语言版)','严蔚敏',3,1,35.00,6,5),(5,'9787020002207','红楼梦','曹雪芹',5,2,59.70,4,3),(6,'9787532770974','百年孤独','加西亚·马尔克斯',6,2,39.50,3,2),(7,'9787101052768','万历十五年','黄仁宇',5,3,32.00,2,1),(8,'9787111593193','经济学原理(第7版)','曼昆',2,4,88.00,2,2),(9,'9787115474891','时间简史','史蒂芬·霍金',4,5,45.00,3,3),(10,'9787302590996','乌合之众: 大众心理研究','古斯塔夫·勒庞',3,6,29.80,4,4);
/*!40000 ALTER TABLE `books` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `borrow_records`
--

DROP TABLE IF EXISTS `borrow_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `borrow_records` (
  `record_id` int NOT NULL AUTO_INCREMENT COMMENT '借阅记录ID',
  `reader_id` int NOT NULL COMMENT '读者ID',
  `book_id` int NOT NULL COMMENT '图书ID',
  `borrow_date` date NOT NULL COMMENT '借阅日期',
  `due_date` date NOT NULL COMMENT '应还日期',
  `return_date` date DEFAULT NULL COMMENT '实际归还日期(未还为NULL)',
  `status` enum('借阅中','已归还','逾期') DEFAULT '借阅中' COMMENT '状态',
  PRIMARY KEY (`record_id`),
  KEY `idx_borrow_reader` (`reader_id`),
  KEY `idx_borrow_book` (`book_id`),
  CONSTRAINT `fk_borrow_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`book_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_borrow_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `ck_borrow_dates` CHECK ((`due_date` >= `borrow_date`))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='借阅记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `borrow_records`
--

LOCK TABLES `borrow_records` WRITE;
/*!40000 ALTER TABLE `borrow_records` DISABLE KEYS */;
INSERT INTO `borrow_records` VALUES (1,1,1,'2026-08-20','2026-09-20',NULL,'借阅中'),(2,1,6,'2026-09-01','2026-10-01',NULL,'借阅中'),(3,2,3,'2026-08-25','2026-09-25','2026-09-10','已归还'),(4,2,5,'2026-09-05','2026-10-05',NULL,'借阅中'),(5,3,2,'2026-08-15','2026-10-15',NULL,'借阅中'),(6,4,7,'2026-08-01','2026-08-31','2026-08-28','已归还'),(7,5,9,'2026-09-10','2026-10-10',NULL,'借阅中'),(8,6,4,'2026-07-20','2026-08-20',NULL,'逾期'),(9,7,8,'2026-09-12','2026-11-12',NULL,'借阅中'),(10,8,10,'2026-09-15','2026-10-15',NULL,'借阅中');
/*!40000 ALTER TABLE `borrow_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `publishers`
--

DROP TABLE IF EXISTS `publishers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publishers` (
  `publisher_id` int NOT NULL AUTO_INCREMENT COMMENT '出版社ID',
  `name` varchar(30) NOT NULL COMMENT '出版社名称',
  `city` varchar(30) DEFAULT NULL COMMENT '所在城市',
  `founded_year` year DEFAULT NULL COMMENT '成立年份',
  PRIMARY KEY (`publisher_id`),
  UNIQUE KEY `uk_publishers_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='出版社表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publishers`
--

LOCK TABLES `publishers` WRITE;
/*!40000 ALTER TABLE `publishers` DISABLE KEYS */;
INSERT INTO `publishers` VALUES (1,'人民邮电出版社','北京',1953),(2,'机械工业出版社','北京',1952),(3,'清华大学出版社','北京',1980),(4,'电子工业出版社','北京',1982),(5,'人民文学出版社','北京',1951),(6,'上海译文出版社','上海',1978);
/*!40000 ALTER TABLE `publishers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `readers`
--

DROP TABLE IF EXISTS `readers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `readers` (
  `reader_id` int NOT NULL AUTO_INCREMENT COMMENT '读者ID',
  `name` varchar(20) NOT NULL COMMENT '姓名',
  `card_no` varchar(20) NOT NULL COMMENT '借书证号',
  `gender` char(1) NOT NULL COMMENT '性别',
  `phone` varchar(11) NOT NULL COMMENT '手机号',
  `birthday` date DEFAULT NULL COMMENT '出生日期',
  `reader_type` enum('学生','教师','职工') DEFAULT NULL COMMENT '读者类型',
  `max_borrow` int DEFAULT NULL COMMENT '最大可借册数',
  `registered` date DEFAULT NULL COMMENT '注册日期',
  PRIMARY KEY (`reader_id`),
  UNIQUE KEY `uk_readers_card_no` (`card_no`),
  CONSTRAINT `ck_readers_gender` CHECK ((`gender` in (_utf8mb4'男',_utf8mb4'女'))),
  CONSTRAINT `ck_readers_max_borrow` CHECK (((`max_borrow` is null) or (`max_borrow` >= 0)))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='读者表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `readers`
--

LOCK TABLES `readers` WRITE;
/*!40000 ALTER TABLE `readers` DISABLE KEYS */;
INSERT INTO `readers` VALUES (1,'陈晨','RD20230001','男','13511110001','2005-01-30','学生',5,'2023-09-01'),(2,'刘洋','RD20230002','女','13611110002','2005-05-01','学生',5,'2023-09-01'),(3,'孙丽','RD20180003','女','13711110003','1987-10-18','教师',10,'2018-03-15'),(4,'周杰','RD20150004','男','13811110004','1989-09-15','职工',3,'2015-06-20'),(5,'吴倩','RD20240005','女','13911110005','2006-07-22','学生',5,'2024-09-01'),(6,'郑浩','RD20230006','男','13511110006','2004-11-17','学生',5,'2023-09-01'),(7,'林芳','RD20160007','女','13611110007','1986-06-28','教师',10,'2016-03-10'),(8,'程文','RD20120008','男','13711110008','1986-04-20','职工',3,'2012-07-02'),(9,'沈念','RD20090009','女','13811110009','1978-09-02','教师',10,'2009-09-10'),(10,'黄凯','RD20240010','男','13911110010','2006-03-11','学生',5,'2024-09-01');
/*!40000 ALTER TABLE `readers` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-18 20:53:14
