-- MySQL dump 10.13  Distrib 8.4.11, for Linux (x86_64)
--
-- Host: localhost    Database: multilateral-diplomacy-system-schoolwork-
-- ------------------------------------------------------
-- Server version	8.4.11

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
-- Current Database: `multilateral-diplomacy-system-schoolwork-`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `multilateral-diplomacy-system-schoolwork-` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `multilateral-diplomacy-system-schoolwork-`;

--
-- Table structure for table `app_user`
--

DROP TABLE IF EXISTS `app_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_user` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(40) NOT NULL,
  `real_name` varchar(40) NOT NULL,
  `user_role` varchar(10) NOT NULL DEFAULT '观察员',
  `country_id` int DEFAULT NULL,
  `org_id` int DEFAULT NULL,
  `is_active` smallint NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`),
  KEY `country_id` (`country_id`),
  KEY `org_id` (`org_id`),
  KEY `idx_user_role` (`user_role`),
  CONSTRAINT `app_user_ibfk_1` FOREIGN KEY (`country_id`) REFERENCES `country` (`country_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `app_user_ibfk_2` FOREIGN KEY (`org_id`) REFERENCES `international_organization` (`org_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `app_user_chk_1` CHECK ((`user_role` in (_utf8mb4'系统管理员',_utf8mb4'会议组织者',_utf8mb4'外交官',_utf8mb4'观察员'))),
  CONSTRAINT `app_user_chk_2` CHECK ((`is_active` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_user`
--

LOCK TABLES `app_user` WRITE;
/*!40000 ALTER TABLE `app_user` DISABLE KEYS */;
INSERT INTO `app_user` VALUES (1,'admin','系统管理员','系统管理员',NULL,1,1,'2026-10-24 15:49:27'),(2,'org_china','中方会议组织者','会议组织者',1,NULL,1,'2026-10-24 15:49:27'),(3,'org_brazil','巴方会议组织者','会议组织者',4,NULL,1,'2026-10-24 15:49:27'),(4,'org_sco','上合秘书处干事','会议组织者',NULL,2,1,'2026-10-24 15:49:27'),(5,'dip_china','中方外交官','外交官',1,NULL,1,'2026-10-24 15:49:27'),(6,'dip_southaf','南非常驻代表','外交官',5,NULL,1,'2026-10-24 15:49:27'),(7,'dip_egypt','埃及外交官','外交官',7,NULL,1,'2026-10-24 15:49:27'),(8,'obs_asean','东盟观察员','观察员',10,4,1,'2026-10-24 15:49:27'),(9,'obs_unfccc','气候公约观察员','观察员',NULL,5,1,'2026-10-24 15:49:27'),(10,'dip_retired','离任外交官','外交官',1,NULL,0,'2026-10-24 15:49:27');
/*!40000 ALTER TABLE `app_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `conference`
--

DROP TABLE IF EXISTS `conference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conference` (
  `conference_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(120) NOT NULL,
  `short_name` varchar(60) DEFAULT NULL,
  `mechanism_id` int DEFAULT NULL,
  `org_id` int DEFAULT NULL,
  `host_country_id` int NOT NULL,
  `host_city` varchar(60) DEFAULT NULL,
  `conference_type` varchar(10) NOT NULL,
  `session_label` varchar(20) DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `format` varchar(10) NOT NULL DEFAULT '线下',
  `status` varchar(10) NOT NULL DEFAULT '已闭幕',
  `theme` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`conference_id`),
  KEY `mechanism_id` (`mechanism_id`),
  KEY `org_id` (`org_id`),
  KEY `host_country_id` (`host_country_id`),
  KEY `idx_conf_dates` (`start_date`,`end_date`),
  CONSTRAINT `conference_ibfk_1` FOREIGN KEY (`mechanism_id`) REFERENCES `mechanism` (`mechanism_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `conference_ibfk_2` FOREIGN KEY (`org_id`) REFERENCES `international_organization` (`org_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `conference_ibfk_3` FOREIGN KEY (`host_country_id`) REFERENCES `country` (`country_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `conference_chk_1` CHECK ((`end_date` >= `start_date`)),
  CONSTRAINT `conference_chk_2` CHECK ((`conference_type` in (_utf8mb4'首脑峰会',_utf8mb4'部长级会议',_utf8mb4'高官会议',_utf8mb4'专家会议',_utf8mb4'大会',_utf8mb4'特别会议'))),
  CONSTRAINT `conference_chk_3` CHECK ((`format` in (_utf8mb4'线下',_utf8mb4'线上',_utf8mb4'混合'))),
  CONSTRAINT `conference_chk_4` CHECK ((`status` in (_utf8mb4'筹备中',_utf8mb4'进行中',_utf8mb4'已闭幕',_utf8mb4'取消')))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conference`
--

LOCK TABLES `conference` WRITE;
/*!40000 ALTER TABLE `conference` DISABLE KEYS */;
INSERT INTO `conference` VALUES (1,'上海合作组织成员国元首理事会第二十四次会议','上合组织阿斯塔纳峰会',1,2,8,'阿斯塔纳','首脑峰会','第24次','2024-07-04','2024-07-05','线下','已闭幕','加强多边对话，促进可持续和平与发展'),(2,'金砖国家领导人第十六次会晤','金砖喀山峰会',2,NULL,3,'喀山','首脑峰会','第16次','2024-10-22','2024-10-24','线下','已闭幕','加强多边主义，促进全球公平发展与安全'),(3,'2024年中非合作论坛北京峰会','中非合作论坛北京峰会',3,3,1,'北京','首脑峰会','第4届','2024-09-04','2024-09-06','线下','已闭幕','携手推进现代化，共筑高水平中非命运共同体'),(4,'二十国集团领导人第十九次峰会','G20里约峰会',4,NULL,4,'里约热内卢','首脑峰会','第19次','2024-11-18','2024-11-19','线下','已闭幕','构建公正世界和可持续的星球'),(5,'联合国气候变化大会第二十九次缔约方会议','COP29',5,5,16,'巴库','大会','第29次','2024-11-11','2024-11-22','线下','已闭幕','团结一致应对气候危机'),(6,'联合国大会第七十九届会议一般性辩论','UNGA79',6,1,2,'纽约','大会','第79届','2024-09-24','2024-09-30','线下','已闭幕','不让任何人掉队：携手共促和平、可持续发展与人类尊严'),(7,'上海合作组织成员国政府首脑（总理）理事会第二十三次会议','上合总理会',1,2,9,'伊斯兰堡','部长级会议','第23次','2024-10-16','2024-10-16','线下','已闭幕','深化务实合作，推动区域经济一体化'),(8,'金砖国家外长会晤','金砖外长会',2,NULL,4,'里约热内卢','部长级会议','2025','2025-04-28','2025-04-29','线下','已闭幕','加强多边主义与全球治理改革'),(9,'金砖国家领导人第十七次会晤','金砖峰会2026',2,NULL,6,'新德里','首脑峰会','第17次','2026-12-15','2026-12-16','线下','筹备中','建设更加公正合理的全球治理体系');
/*!40000 ALTER TABLE `conference` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `conference_participant`
--

DROP TABLE IF EXISTS `conference_participant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conference_participant` (
  `conference_id` int NOT NULL,
  `country_id` int NOT NULL,
  `role` varchar(10) NOT NULL DEFAULT '成员国',
  `delegation_level` varchar(10) NOT NULL DEFAULT '部长级',
  `delegation_size` int NOT NULL DEFAULT '0',
  `join_date` date DEFAULT NULL,
  PRIMARY KEY (`conference_id`,`country_id`),
  KEY `country_id` (`country_id`),
  CONSTRAINT `conference_participant_ibfk_1` FOREIGN KEY (`conference_id`) REFERENCES `conference` (`conference_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `conference_participant_ibfk_2` FOREIGN KEY (`country_id`) REFERENCES `country` (`country_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `conference_participant_chk_1` CHECK ((`delegation_size` >= 0)),
  CONSTRAINT `conference_participant_chk_2` CHECK ((`role` in (_utf8mb4'主办国',_utf8mb4'主席国',_utf8mb4'成员国',_utf8mb4'观察员',_utf8mb4'嘉宾国'))),
  CONSTRAINT `conference_participant_chk_3` CHECK ((`delegation_level` in (_utf8mb4'元首级',_utf8mb4'政府首脑级',_utf8mb4'外交部长级',_utf8mb4'部长级',_utf8mb4'高官级',_utf8mb4'专家级')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conference_participant`
--

LOCK TABLES `conference_participant` WRITE;
/*!40000 ALTER TABLE `conference_participant` DISABLE KEYS */;
INSERT INTO `conference_participant` VALUES (1,1,'成员国','元首级',42,'2024-06-01'),(1,3,'成员国','元首级',40,'2024-06-01'),(1,6,'成员国','元首级',38,'2024-06-05'),(1,8,'主办国','元首级',58,'2024-06-01'),(1,9,'成员国','政府首脑级',35,'2024-06-01'),(1,10,'观察员','部长级',20,'2024-06-10'),(1,11,'嘉宾国','部长级',18,'2024-06-12'),(2,1,'成员国','元首级',48,'2024-09-20'),(2,3,'主办国','元首级',65,'2024-09-20'),(2,4,'成员国','元首级',44,'2024-09-20'),(2,5,'成员国','元首级',36,'2024-09-20'),(2,6,'成员国','元首级',46,'2024-09-20'),(2,7,'成员国','元首级',30,'2024-09-25'),(2,11,'嘉宾国','外交部长级',22,'2024-09-28'),(2,17,'成员国','政府首脑级',26,'2024-09-25'),(3,1,'主办国','元首级',120,'2024-08-01'),(3,5,'成员国','元首级',45,'2024-08-05'),(3,7,'成员国','元首级',40,'2024-08-05'),(3,17,'成员国','元首级',32,'2024-08-05'),(3,18,'成员国','元首级',38,'2024-08-06'),(4,1,'成员国','元首级',55,'2024-10-01'),(4,2,'成员国','元首级',60,'2024-10-01'),(4,4,'主办国','元首级',80,'2024-10-01'),(4,5,'成员国','元首级',34,'2024-10-04'),(4,6,'成员国','元首级',48,'2024-10-02'),(4,11,'成员国','元首级',35,'2024-10-03'),(4,12,'成员国','元首级',40,'2024-10-01'),(4,13,'成员国','元首级',42,'2024-10-01'),(4,14,'成员国','元首级',41,'2024-10-02'),(4,15,'成员国','元首级',33,'2024-10-03'),(5,1,'成员国','部长级',60,'2024-10-01'),(5,2,'成员国','部长级',55,'2024-10-01'),(5,4,'成员国','部长级',42,'2024-10-03'),(5,5,'成员国','部长级',30,'2024-10-04'),(5,6,'成员国','部长级',38,'2024-10-03'),(5,10,'成员国','部长级',28,'2024-10-04'),(5,12,'成员国','部长级',48,'2024-10-02'),(5,13,'成员国','部长级',46,'2024-10-02'),(5,16,'主办国','部长级',90,'2024-10-01'),(6,1,'成员国','元首级',50,'2024-09-01'),(6,2,'主办国','元首级',100,'2024-09-01'),(6,3,'成员国','外交部长级',45,'2024-09-01'),(6,4,'成员国','元首级',40,'2024-09-02'),(6,5,'成员国','元首级',32,'2024-09-03'),(6,6,'成员国','外交部长级',34,'2024-09-04'),(6,11,'成员国','外交部长级',28,'2024-09-04'),(6,12,'成员国','外交部长级',36,'2024-09-02'),(6,13,'成员国','元首级',38,'2024-09-02'),(6,14,'成员国','元首级',37,'2024-09-03'),(7,1,'成员国','政府首脑级',40,'2024-09-01'),(7,3,'成员国','政府首脑级',38,'2024-09-01'),(7,6,'成员国','部长级',26,'2024-09-03'),(7,8,'成员国','政府首脑级',30,'2024-09-02'),(7,9,'主办国','政府首脑级',45,'2024-09-01'),(7,10,'观察员','部长级',18,'2024-09-05'),(8,1,'成员国','外交部长级',28,'2025-03-01'),(8,3,'成员国','外交部长级',26,'2025-03-01'),(8,4,'主办国','外交部长级',30,'2025-03-01'),(8,5,'成员国','外交部长级',22,'2025-03-02'),(8,6,'成员国','外交部长级',24,'2025-03-02'),(8,7,'成员国','外交部长级',20,'2025-03-03'),(9,1,'成员国','元首级',0,NULL),(9,3,'成员国','元首级',0,NULL),(9,4,'成员国','元首级',0,NULL),(9,5,'成员国','元首级',0,NULL),(9,6,'主办国','元首级',0,NULL);
/*!40000 ALTER TABLE `conference_participant` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `conference_topic`
--

DROP TABLE IF EXISTS `conference_topic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conference_topic` (
  `conference_id` int NOT NULL,
  `topic_id` int NOT NULL,
  `is_core` smallint NOT NULL DEFAULT '0',
  `discussion_date` date DEFAULT NULL,
  `summary` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`conference_id`,`topic_id`),
  KEY `topic_id` (`topic_id`),
  CONSTRAINT `conference_topic_ibfk_1` FOREIGN KEY (`conference_id`) REFERENCES `conference` (`conference_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `conference_topic_ibfk_2` FOREIGN KEY (`topic_id`) REFERENCES `topic` (`topic_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `conference_topic_chk_1` CHECK ((`is_core` in (0,1)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conference_topic`
--

LOCK TABLES `conference_topic` WRITE;
/*!40000 ALTER TABLE `conference_topic` DISABLE KEYS */;
INSERT INTO `conference_topic` VALUES (1,1,1,'2024-07-04','就共同、综合、合作、可持续的安全观达成共识'),(1,2,1,'2024-07-04','通过反恐合作纲要，强化联合演习与情报共享'),(1,3,0,'2024-07-05','推进跨境互联互通与产能合作'),(1,10,0,'2024-07-05','建立粮食安全合作机制'),(2,1,1,'2024-10-22','反对单边主义，推动政治解决热点问题'),(2,5,0,'2024-10-24','就气候融资与技术转移交换意见'),(2,8,1,'2024-10-23','支持扩大发展中国家在安理会的代表性'),(2,9,1,'2024-10-23','推动人工智能治理规则制定'),(3,3,0,'2024-09-06','共建\"一带一路\"与非洲基础设施对接'),(3,4,1,'2024-09-05','推进全球发展倡议与非盟发展议程对接'),(3,7,0,'2024-09-05','启动中非人文交流年'),(3,10,1,'2024-09-05','深化农业技术示范与粮食供应链合作'),(4,1,1,'2024-11-18','应对地区冲突与全球安全治理'),(4,5,1,'2024-11-18','推进气候融资与绿色转型'),(4,9,0,'2024-11-19','数字经济与人工智能治理合作'),(5,5,1,'2024-11-13','确立气候融资新集体量化目标'),(5,6,0,'2024-11-18','气候与公共卫生协同治理'),(5,10,0,'2024-11-16','农业与粮食系统适应气候变化'),(6,1,1,'2024-09-25','呼吁政治解决地区冲突'),(6,4,0,'2024-09-27','全球发展倡议与可持续发展目标对接'),(6,8,1,'2024-09-26','推动安理会改革政府间谈判'),(7,3,1,'2024-10-16','推进上合组织区域经济一体化'),(7,9,0,'2024-10-16','数字经济合作与跨境物流便利化'),(8,1,0,'2025-04-29','就地区热点问题协调立场'),(8,8,1,'2025-04-28','协调安理会改革共同立场'),(9,5,0,NULL,'拟讨论气候融资落实'),(9,9,1,NULL,'拟将人工智能治理列为峰会核心议题');
/*!40000 ALTER TABLE `conference_topic` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `country`
--

DROP TABLE IF EXISTS `country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `country` (
  `country_id` int NOT NULL AUTO_INCREMENT,
  `iso_code` char(3) NOT NULL,
  `name_cn` varchar(50) NOT NULL,
  `name_en` varchar(80) NOT NULL,
  `continent` varchar(10) NOT NULL,
  `development_status` varchar(10) NOT NULL DEFAULT '发展中国家',
  `is_un_member` smallint NOT NULL DEFAULT '1',
  `note` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`country_id`),
  UNIQUE KEY `iso_code` (`iso_code`),
  UNIQUE KEY `name_cn` (`name_cn`),
  KEY `idx_country_continent` (`continent`),
  CONSTRAINT `country_chk_1` CHECK ((`continent` in (_utf8mb4'亚洲',_utf8mb4'欧洲',_utf8mb4'非洲',_utf8mb4'北美洲',_utf8mb4'南美洲',_utf8mb4'大洋洲'))),
  CONSTRAINT `country_chk_2` CHECK ((`development_status` in (_utf8mb4'发达国家',_utf8mb4'发展中国家',_utf8mb4'最不发达国家'))),
  CONSTRAINT `country_chk_3` CHECK ((`is_un_member` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `country`
--

LOCK TABLES `country` WRITE;
/*!40000 ALTER TABLE `country` DISABLE KEYS */;
INSERT INTO `country` VALUES (1,'CHN','中国','China','亚洲','发展中国家',1,'多边外交重要参与方与贡献者'),(2,'USA','美国','United States','北美洲','发达国家',1,NULL),(3,'RUS','俄罗斯','Russia','欧洲','发展中国家',1,NULL),(4,'BRA','巴西','Brazil','南美洲','发展中国家',1,'金砖国家与二十国集团成员'),(5,'ZAF','南非','South Africa','非洲','发展中国家',1,'非洲大陆代表性和平与安全议题推动者'),(6,'IND','印度','India','亚洲','发展中国家',1,NULL),(7,'EGY','埃及','Egypt','非洲','发展中国家',1,NULL),(8,'KAZ','哈萨克斯坦','Kazakhstan','亚洲','发展中国家',1,'上海合作组织轮值主席国'),(9,'PAK','巴基斯坦','Pakistan','亚洲','发展中国家',1,NULL),(10,'IDN','印度尼西亚','Indonesia','亚洲','发展中国家',1,'东盟重要成员'),(11,'SAU','沙特阿拉伯','Saudi Arabia','亚洲','发展中国家',1,NULL),(12,'DEU','德国','Germany','欧洲','发达国家',1,NULL),(13,'FRA','法国','France','欧洲','发达国家',1,NULL),(14,'GBR','英国','United Kingdom','欧洲','发达国家',1,NULL),(15,'ARG','阿根廷','Argentina','南美洲','发展中国家',1,NULL),(16,'AZE','阿塞拜疆','Azerbaijan','亚洲','发展中国家',1,'气候变化大会主席国'),(17,'ETH','埃塞俄比亚','Ethiopia','非洲','最不发达国家',1,NULL),(18,'NGA','尼日利亚','Nigeria','非洲','发展中国家',1,'非洲人口最大国家');
/*!40000 ALTER TABLE `country` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document`
--

DROP TABLE IF EXISTS `document`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document` (
  `document_id` int NOT NULL AUTO_INCREMENT,
  `conference_id` int NOT NULL,
  `title` varchar(120) NOT NULL,
  `doc_type` varchar(10) NOT NULL,
  `doc_no` varchar(40) DEFAULT NULL,
  `issue_date` date NOT NULL,
  `adopt_method` varchar(10) NOT NULL DEFAULT '协商一致',
  `status` varchar(10) NOT NULL DEFAULT '已通过',
  `summary` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`document_id`),
  UNIQUE KEY `doc_no` (`doc_no`),
  KEY `conference_id` (`conference_id`),
  KEY `idx_doc_type` (`doc_type`),
  CONSTRAINT `document_ibfk_1` FOREIGN KEY (`conference_id`) REFERENCES `conference` (`conference_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `document_chk_1` CHECK (((`doc_no` is null) or (char_length(trim(`doc_no`)) > 0))),
  CONSTRAINT `document_chk_2` CHECK ((`doc_type` in (_utf8mb4'联合声明',_utf8mb4'联合公报',_utf8mb4'决议',_utf8mb4'行动计划',_utf8mb4'谅解备忘录',_utf8mb4'倡议'))),
  CONSTRAINT `document_chk_3` CHECK ((`adopt_method` in (_utf8mb4'协商一致',_utf8mb4'表决通过'))),
  CONSTRAINT `document_chk_4` CHECK ((`status` in (_utf8mb4'草案',_utf8mb4'已通过',_utf8mb4'已生效')))
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document`
--

LOCK TABLES `document` WRITE;
/*!40000 ALTER TABLE `document` DISABLE KEYS */;
INSERT INTO `document` VALUES (1,1,'上海合作组织成员国元首理事会阿斯塔纳宣言','联合声明','SCO-2024-DECL','2024-07-05','协商一致','已生效','重申共同安全观，深化反恐与经贸合作'),(2,2,'金砖国家领导人第十六次会晤喀山宣言','联合声明','BRICS-2024-KAZAN','2024-10-23','协商一致','已生效','加强多边主义，推动全球治理体系改革'),(3,3,'2024年中非合作论坛北京宣言','联合声明','FOCAC-2024-DECL','2024-09-05','协商一致','已生效','构建高水平中非命运共同体'),(4,3,'中非合作论坛北京行动计划（2025—2027）','行动计划','FOCAC-2024-ACT','2024-09-06','协商一致','已生效','明确未来三年中非合作重点领域'),(5,4,'二十国集团领导人里约热内卢峰会宣言','联合公报','G20-2024-RIO','2024-11-19','协商一致','已通过','构建公正世界与可持续星球'),(6,5,'COP29 关于气候融资新集体量化目标的决定','决议','COP29-2024-DEC','2024-11-22','表决通过','已通过','确立新的气候融资目标与落实安排'),(7,6,'第七十九届联合国大会一般性辩论主席总结','联合声明','UNGA79-2024-SUM','2024-09-30','协商一致','已通过','汇总各方关于和平与发展的立场'),(8,7,'上海合作组织成员国政府首脑理事会联合公报','联合公报','SCO-2024-PM','2024-10-16','协商一致','已通过','推进区域经济一体化与互联互通'),(9,8,'金砖国家外长会晤联合声明','联合声明','BRICS-2025-FM','2025-04-29','协商一致','已通过','协调安理会改革与地区热点立场'),(10,2,'金砖国家数字经济与人工智能治理合作倡议','倡议','BRICS-2024-DIGI','2024-10-23','协商一致','已通过','推动数字鸿沟弥合与人工智能治理'),(11,9,'金砖国家领导人第十七次会晤成果文件（草案）','联合声明',NULL,'2026-12-16','协商一致','草案','筹备阶段草案，尚未提交领导人会议通过');
/*!40000 ALTER TABLE `document` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_document_before_update` BEFORE UPDATE ON `document` FOR EACH ROW BEGIN
  IF NEW.conference_id <> OLD.conference_id AND EXISTS (
    SELECT * FROM follow_up_action a
    WHERE a.document_id = OLD.document_id AND a.conference_id <> NEW.conference_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'action document/conference mismatch';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `document_sponsor`
--

DROP TABLE IF EXISTS `document_sponsor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_sponsor` (
  `document_id` int NOT NULL,
  `country_id` int NOT NULL,
  `stance` varchar(10) NOT NULL DEFAULT '联署',
  PRIMARY KEY (`document_id`,`country_id`),
  KEY `country_id` (`country_id`),
  CONSTRAINT `document_sponsor_ibfk_1` FOREIGN KEY (`document_id`) REFERENCES `document` (`document_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `document_sponsor_ibfk_2` FOREIGN KEY (`country_id`) REFERENCES `country` (`country_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `document_sponsor_chk_1` CHECK ((`stance` in (_utf8mb4'联署',_utf8mb4'支持',_utf8mb4'保留')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_sponsor`
--

LOCK TABLES `document_sponsor` WRITE;
/*!40000 ALTER TABLE `document_sponsor` DISABLE KEYS */;
INSERT INTO `document_sponsor` VALUES (1,1,'联署'),(1,3,'联署'),(1,6,'联署'),(1,8,'联署'),(1,9,'联署'),(1,10,'支持'),(1,11,'支持'),(2,1,'联署'),(2,3,'联署'),(2,4,'联署'),(2,5,'联署'),(2,6,'联署'),(2,7,'联署'),(2,11,'支持'),(2,17,'支持'),(3,1,'联署'),(3,5,'联署'),(3,6,'支持'),(3,7,'联署'),(3,17,'联署'),(3,18,'联署'),(4,1,'联署'),(4,2,'保留'),(4,5,'联署'),(4,7,'联署'),(4,12,'支持'),(4,13,'支持'),(4,17,'联署'),(4,18,'联署'),(5,1,'联署'),(5,2,'联署'),(5,4,'联署'),(5,5,'联署'),(5,6,'联署'),(5,11,'联署'),(5,12,'联署'),(5,13,'联署'),(5,14,'联署'),(5,15,'联署'),(6,1,'支持'),(6,2,'联署'),(6,4,'联署'),(6,5,'支持'),(6,6,'支持'),(6,10,'支持'),(6,11,'保留'),(6,12,'联署'),(6,13,'联署'),(6,16,'联署'),(7,1,'联署'),(7,2,'联署'),(7,3,'支持'),(7,4,'联署'),(7,5,'联署'),(7,6,'支持'),(7,11,'支持'),(7,12,'联署'),(7,13,'联署'),(7,14,'联署'),(8,1,'联署'),(8,3,'联署'),(8,6,'支持'),(8,8,'联署'),(8,9,'联署'),(8,10,'支持'),(9,1,'联署'),(9,3,'联署'),(9,4,'联署'),(9,5,'联署'),(9,6,'联署'),(9,7,'联署'),(10,1,'联署'),(10,3,'联署'),(10,4,'联署'),(10,5,'支持'),(10,6,'联署');
/*!40000 ALTER TABLE `document_sponsor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `follow_up_action`
--

DROP TABLE IF EXISTS `follow_up_action`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `follow_up_action` (
  `action_id` int NOT NULL AUTO_INCREMENT,
  `conference_id` int NOT NULL,
  `document_id` int DEFAULT NULL,
  `action_name` varchar(120) NOT NULL,
  `lead_country_id` int NOT NULL,
  `responsible_org_id` int DEFAULT NULL,
  `start_date` date NOT NULL,
  `planned_end_date` date NOT NULL,
  `actual_end_date` date DEFAULT NULL,
  `progress_pct` int NOT NULL DEFAULT '0',
  `status` varchar(10) NOT NULL DEFAULT '进行中',
  `remarks` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`action_id`),
  KEY `conference_id` (`conference_id`),
  KEY `document_id` (`document_id`),
  KEY `lead_country_id` (`lead_country_id`),
  KEY `responsible_org_id` (`responsible_org_id`),
  KEY `idx_action_due` (`planned_end_date`),
  CONSTRAINT `follow_up_action_ibfk_1` FOREIGN KEY (`conference_id`) REFERENCES `conference` (`conference_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `follow_up_action_ibfk_2` FOREIGN KEY (`document_id`) REFERENCES `document` (`document_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `follow_up_action_ibfk_3` FOREIGN KEY (`lead_country_id`) REFERENCES `country` (`country_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `follow_up_action_ibfk_4` FOREIGN KEY (`responsible_org_id`) REFERENCES `international_organization` (`org_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `follow_up_action_chk_1` CHECK ((`progress_pct` between 0 and 100)),
  CONSTRAINT `follow_up_action_chk_2` CHECK ((`planned_end_date` >= `start_date`)),
  CONSTRAINT `follow_up_action_chk_3` CHECK (((`actual_end_date` is null) or (`actual_end_date` >= `start_date`))),
  CONSTRAINT `follow_up_action_chk_4` CHECK (((`status` <> _utf8mb4'已完成') or (`actual_end_date` is not null))),
  CONSTRAINT `follow_up_action_chk_5` CHECK ((`status` in (_utf8mb4'未启动',_utf8mb4'进行中',_utf8mb4'已完成',_utf8mb4'逾期',_utf8mb4'终止')))
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `follow_up_action`
--

LOCK TABLES `follow_up_action` WRITE;
/*!40000 ALTER TABLE `follow_up_action` DISABLE KEYS */;
INSERT INTO `follow_up_action` VALUES (1,3,4,'中非减贫示范项目落地实施',1,3,'2025-01-01','2026-06-30','2026-05-20',100,'已完成','已完成两批示范点建设'),(2,3,4,'非洲农业技术示范中心扩建',1,3,'2025-03-01','2027-12-31',NULL,45,'进行中','三个中心完成选址'),(3,1,1,'上合组织框架下联合反恐演习常态化',3,2,'2024-09-01','2025-06-30',NULL,60,'逾期','年度演习机制延续，待评估报告'),(4,1,1,'上合组织禁毒合作机制建设',8,2,'2024-10-01','2026-12-31',NULL,50,'进行中','工作组已成立'),(5,2,2,'金砖国家本币结算合作框架',3,NULL,'2024-11-01','2027-10-31',NULL,30,'进行中','本币结算比例稳步提升'),(6,2,10,'金砖国家人工智能治理联合研究',1,NULL,'2025-01-01','2026-12-31',NULL,55,'进行中','已发布阶段性研究报告'),(7,4,5,'二十国集团债务共同框架落实情况评估',4,NULL,'2024-12-01','2025-12-31',NULL,40,'逾期','评估报告延期提交'),(8,5,6,'气候融资新集体量化目标落实方案',16,5,'2025-01-01','2026-12-31',NULL,20,'进行中','资金核算口径仍在磋商'),(9,5,6,'全球适应目标指标体系构建',12,5,'2025-03-01','2025-11-30','2025-11-15',100,'已完成','指标体系获缔约方会议认可'),(10,6,7,'联合国安理会改革政府间谈判推进',5,1,'2024-10-01','2026-09-30',NULL,35,'逾期','各方立场仍存分歧'),(11,7,8,'上合组织跨境物流便利化',9,2,'2024-11-01','2026-12-31',NULL,40,'进行中','通关数据交换试点启动'),(12,8,9,'金砖国家外长会晤后续磋商机制',4,NULL,'2025-05-01','2026-03-31','2026-03-10',100,'已完成','已举行三轮磋商'),(13,3,3,'中非人文交流年系列活动',7,3,'2025-01-01','2026-12-31',NULL,70,'进行中','教育与青年交流项目已开展'),(14,2,2,'金砖国家新开发银行扩员研究',6,NULL,'2025-02-01','2025-08-31',NULL,45,'逾期','扩员研究未按期完成'),(15,9,NULL,'金砖国家领导人第十七次会晤筹备工作',6,NULL,'2026-11-01','2026-12-01',NULL,0,'未启动','待 2026 年峰会筹备启动'),(16,6,7,'安理会改革方案文本磋商',3,1,'2024-10-01','2025-06-30',NULL,20,'终止','各方立场分歧过大，磋商中止');
/*!40000 ALTER TABLE `follow_up_action` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_action_before_insert` BEFORE INSERT ON `follow_up_action` FOR EACH ROW BEGIN
  -- 文件可为空；填写文件时，其所属会议必须与行动来源一致。
  IF NEW.document_id IS NOT NULL AND NOT EXISTS (
    SELECT * FROM document d
    WHERE d.document_id = NEW.document_id AND d.conference_id = NEW.conference_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'action document/conference mismatch';
  END IF;
  IF NEW.actual_end_date IS NOT NULL THEN
    SET NEW.status = '已完成', NEW.progress_pct = 100;
  ELSEIF NEW.planned_end_date < CURDATE() AND NEW.status <> '终止' THEN
    SET NEW.status = '逾期';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_action_before_update` BEFORE UPDATE ON `follow_up_action` FOR EACH ROW BEGIN
  -- 文件可为空；填写文件时，其所属会议必须与行动来源一致。
  IF NEW.document_id IS NOT NULL AND NOT EXISTS (
    SELECT * FROM document d
    WHERE d.document_id = NEW.document_id AND d.conference_id = NEW.conference_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'action document/conference mismatch';
  END IF;
  IF NEW.actual_end_date IS NOT NULL THEN
    SET NEW.status = '已完成', NEW.progress_pct = 100;
  ELSEIF NEW.planned_end_date < CURDATE() AND NEW.status IN ('未启动', '进行中') THEN
    SET NEW.status = '逾期';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_action_audit` AFTER UPDATE ON `follow_up_action` FOR EACH ROW BEGIN
  IF OLD.status <> NEW.status OR OLD.progress_pct <> NEW.progress_pct THEN
    INSERT INTO operation_log
      (user_id, action_type, target_table, target_id, old_value, new_value, detail)
    VALUES
      (NULL, 'UPDATE', 'follow_up_action', NEW.action_id,
       CONCAT('status=', OLD.status, ', progress=', OLD.progress_pct),
       CONCAT('status=', NEW.status, ', progress=', NEW.progress_pct),
       '后续行动状态或进度变更（触发器自动记录）');
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `international_organization`
--

DROP TABLE IF EXISTS `international_organization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `international_organization` (
  `org_id` int NOT NULL AUTO_INCREMENT,
  `name_cn` varchar(80) NOT NULL,
  `abbr` varchar(20) DEFAULT NULL,
  `org_type` varchar(10) NOT NULL,
  `founded_year` smallint DEFAULT NULL,
  `hq_city` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`org_id`),
  UNIQUE KEY `name_cn` (`name_cn`),
  UNIQUE KEY `abbr` (`abbr`),
  CONSTRAINT `international_organization_chk_1` CHECK ((`org_type` in (_utf8mb4'联合国系统',_utf8mb4'区域性组织',_utf8mb4'多边机制',_utf8mb4'专门机构'))),
  CONSTRAINT `international_organization_chk_2` CHECK ((`founded_year` between 1 and 9999))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `international_organization`
--

LOCK TABLES `international_organization` WRITE;
/*!40000 ALTER TABLE `international_organization` DISABLE KEYS */;
INSERT INTO `international_organization` VALUES (1,'联合国','UN','联合国系统',1945,'纽约'),(2,'上海合作组织','SCO','区域性组织',2001,'北京'),(3,'非洲联盟','AU','区域性组织',2002,'亚的斯亚贝巴'),(4,'东盟','ASEAN','区域性组织',1967,'雅加达'),(5,'联合国气候变化框架公约秘书处','UNFCCC','联合国系统',1992,'波恩'),(6,'世界卫生组织','WHO','专门机构',1948,'日内瓦');
/*!40000 ALTER TABLE `international_organization` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mechanism`
--

DROP TABLE IF EXISTS `mechanism`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mechanism` (
  `mechanism_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `abbr` varchar(20) DEFAULT NULL,
  `category` varchar(10) NOT NULL,
  `founded_year` smallint DEFAULT NULL,
  `lead_org_id` int DEFAULT NULL,
  `description` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`mechanism_id`),
  UNIQUE KEY `name` (`name`),
  KEY `lead_org_id` (`lead_org_id`),
  CONSTRAINT `mechanism_ibfk_1` FOREIGN KEY (`lead_org_id`) REFERENCES `international_organization` (`org_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `mechanism_chk_1` CHECK ((`category` in (_utf8mb4'全球治理',_utf8mb4'区域合作',_utf8mb4'南南合作',_utf8mb4'大国协调',_utf8mb4'专门领域'))),
  CONSTRAINT `mechanism_chk_2` CHECK ((`founded_year` between 1 and 9999))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mechanism`
--

LOCK TABLES `mechanism` WRITE;
/*!40000 ALTER TABLE `mechanism` DISABLE KEYS */;
INSERT INTO `mechanism` VALUES (1,'上海合作组织元首理事会','SCO-Summit','区域合作',2001,2,'上合组织最高决策机构，每年举行一次成员国元首会议'),(2,'金砖国家领导人会晤','BRICS','南南合作',2009,NULL,'新兴市场与发展中国家合作机制'),(3,'中非合作论坛','FOCAC','南南合作',2000,3,'中国与非洲国家集体对话与合作平台'),(4,'二十国集团领导人峰会','G20','全球治理',2008,NULL,'主要经济体国际经济合作论坛'),(5,'联合国气候变化大会','COP','专门领域',1995,5,'《联合国气候变化框架公约》缔约方会议'),(6,'联合国大会一般性辩论','UNGA','全球治理',1946,1,'每年九月在联合国总部举行的一般性辩论');
/*!40000 ALTER TABLE `mechanism` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operation_log`
--

DROP TABLE IF EXISTS `operation_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operation_log` (
  `log_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `action_type` varchar(10) NOT NULL,
  `target_table` varchar(40) NOT NULL,
  `target_id` int DEFAULT NULL,
  `old_value` varchar(200) DEFAULT NULL,
  `new_value` varchar(200) DEFAULT NULL,
  `log_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `detail` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`log_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_log_time` (`log_time`),
  KEY `idx_log_target` (`target_table`,`target_id`),
  CONSTRAINT `operation_log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `operation_log_chk_1` CHECK ((`action_type` in (_utf8mb4'INSERT',_utf8mb4'UPDATE',_utf8mb4'DELETE')))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operation_log`
--

LOCK TABLES `operation_log` WRITE;
/*!40000 ALTER TABLE `operation_log` DISABLE KEYS */;
INSERT INTO `operation_log` VALUES (1,NULL,'UPDATE','follow_up_action',3,'status=进行中, progress=60','status=逾期, progress=60','2026-10-24 15:49:27','后续行动状态或进度变更（触发器自动记录）'),(2,NULL,'UPDATE','follow_up_action',7,'status=进行中, progress=40','status=逾期, progress=40','2026-10-24 15:49:27','后续行动状态或进度变更（触发器自动记录）'),(3,NULL,'UPDATE','follow_up_action',10,'status=进行中, progress=35','status=逾期, progress=35','2026-10-24 15:49:27','后续行动状态或进度变更（触发器自动记录）'),(4,NULL,'UPDATE','follow_up_action',14,'status=进行中, progress=45','status=逾期, progress=45','2026-10-24 15:49:27','后续行动状态或进度变更（触发器自动记录）');
/*!40000 ALTER TABLE `operation_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `topic`
--

DROP TABLE IF EXISTS `topic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `topic` (
  `topic_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(60) NOT NULL,
  `category` varchar(10) NOT NULL,
  `description` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`topic_id`),
  UNIQUE KEY `name` (`name`),
  KEY `idx_topic_category` (`category`),
  CONSTRAINT `topic_chk_1` CHECK ((`category` in (_utf8mb4'和平与安全',_utf8mb4'发展与合作',_utf8mb4'气候变化',_utf8mb4'公共卫生',_utf8mb4'人文交流',_utf8mb4'全球治理体系')))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `topic`
--

LOCK TABLES `topic` WRITE;
/*!40000 ALTER TABLE `topic` DISABLE KEYS */;
INSERT INTO `topic` VALUES (1,'全球安全治理','和平与安全','共同、综合、合作、可持续的安全观'),(2,'反恐与去极端化','和平与安全','联合反恐演习、情报共享与去极端化合作'),(3,'高质量共建\"一带一路\"','发展与合作','互联互通与产能合作'),(4,'全球发展倡议与减贫合作','发展与合作','减贫、粮食安全与共同发展'),(5,'应对气候变化与绿色低碳转型','气候变化','减排目标、气候融资与适应行动'),(6,'全球卫生治理与疫苗合作','公共卫生','公共卫生体系与疫苗可及性'),(7,'人文交流与教育合作','人文交流','青年、教育、文化旅游领域交流'),(8,'联合国安理会改革','全球治理体系','提升发展中国家代表性与发言权'),(9,'数字经济与人工智能治理','全球治理体系','数据跨境与人工智能治理规则'),(10,'粮食安全与农业合作','发展与合作','农业技术示范与粮食供应链稳定');
/*!40000 ALTER TABLE `topic` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_action_alert`
--

DROP TABLE IF EXISTS `v_action_alert`;
/*!50001 DROP VIEW IF EXISTS `v_action_alert`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_action_alert` AS SELECT
 1 AS `action_id`,
 1 AS `action_name`,
 1 AS `conference_name`,
 1 AS `lead_country`,
 1 AS `start_date`,
 1 AS `planned_end_date`,
 1 AS `overdue_days`,
 1 AS `progress_pct`,
 1 AS `status`,
 1 AS `remarks`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_active_user`
--

DROP TABLE IF EXISTS `v_active_user`;
/*!50001 DROP VIEW IF EXISTS `v_active_user`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_active_user` AS SELECT
 1 AS `user_id`,
 1 AS `username`,
 1 AS `real_name`,
 1 AS `user_role`,
 1 AS `country_id`,
 1 AS `org_id`,
 1 AS `is_active`,
 1 AS `created_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_china_multilateral`
--

DROP TABLE IF EXISTS `v_china_multilateral`;
/*!50001 DROP VIEW IF EXISTS `v_china_multilateral`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_china_multilateral` AS SELECT
 1 AS `conference_name`,
 1 AS `conference_type`,
 1 AS `start_date`,
 1 AS `host_city`,
 1 AS `host_country`,
 1 AS `mechanism_name`,
 1 AS `china_role`,
 1 AS `china_delegation_level`,
 1 AS `china_delegation_size`,
 1 AS `china_engagement`,
 1 AS `documents_of_conference`,
 1 AS `documents_china_signed`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_conference_overview`
--

DROP TABLE IF EXISTS `v_conference_overview`;
/*!50001 DROP VIEW IF EXISTS `v_conference_overview`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_conference_overview` AS SELECT
 1 AS `conference_id`,
 1 AS `short_name`,
 1 AS `conference_type`,
 1 AS `session_label`,
 1 AS `start_date`,
 1 AS `end_date`,
 1 AS `status`,
 1 AS `host_country`,
 1 AS `host_city`,
 1 AS `mechanism_name`,
 1 AS `org_name`,
 1 AS `participant_count`,
 1 AS `core_topic_count`,
 1 AS `document_count`,
 1 AS `action_count`,
 1 AS `action_done_count`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_document_consensus`
--

DROP TABLE IF EXISTS `v_document_consensus`;
/*!50001 DROP VIEW IF EXISTS `v_document_consensus`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_document_consensus` AS SELECT
 1 AS `document_id`,
 1 AS `doc_no`,
 1 AS `title`,
 1 AS `doc_type`,
 1 AS `adopt_method`,
 1 AS `issue_date`,
 1 AS `conference_name`,
 1 AS `signed_count`,
 1 AS `support_count`,
 1 AS `reserved_count`,
 1 AS `total_country_count`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_operation_audit`
--

DROP TABLE IF EXISTS `v_operation_audit`;
/*!50001 DROP VIEW IF EXISTS `v_operation_audit`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_operation_audit` AS SELECT
 1 AS `log_id`,
 1 AS `log_time`,
 1 AS `操作人`,
 1 AS `角色`,
 1 AS `操作类型`,
 1 AS `目标表`,
 1 AS `目标ID`,
 1 AS `变更前`,
 1 AS `变更后`,
 1 AS `说明`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping routines for database 'multilateral-diplomacy-system-schoolwork-'
--
/*!50003 DROP FUNCTION IF EXISTS `fn_consensus_ratio` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE FUNCTION `fn_consensus_ratio`(p_document_id INT) RETURNS decimal(5,2)
    READS SQL DATA
BEGIN
  DECLARE v_total  INT DEFAULT 0;
  DECLARE v_signed INT DEFAULT 0;
  SELECT COUNT(*), COALESCE(SUM(CASE WHEN stance = '联署' THEN 1 ELSE 0 END), 0)
    INTO v_total, v_signed
    FROM document_sponsor
   WHERE document_id = p_document_id;
  IF v_total = 0 THEN
    RETURN 0;
  END IF;
  RETURN ROUND(v_signed * 100 / v_total, 2);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_conference_dashboard` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_conference_dashboard`(IN p_conference_id INT)
    COMMENT '输出一场国际会议的：基本信息 / 参与国家 / 议题 / 成果文件 / 后续行动'
BEGIN
  -- 1 基本信息
  SELECT c.short_name AS 会议简称, c.title AS 会议全称, c.conference_type AS 会议类型,
         c.session_label AS 届次, c.start_date AS 开始日期, c.end_date AS 结束日期,
         c.status AS 状态, hc.name_cn AS 主办国, m.name AS 所属机制
  FROM conference c
  JOIN country hc        ON hc.country_id = c.host_country_id
  LEFT JOIN mechanism m  ON m.mechanism_id = c.mechanism_id
  WHERE c.conference_id = p_conference_id;

  -- 2 参与国家
  SELECT p.role AS 参会身份, p.delegation_level AS 出席级别,
         p.delegation_size AS 代表团人数, cn.name_cn AS 国家
  FROM conference_participant p
  JOIN country cn ON cn.country_id = p.country_id
  WHERE p.conference_id = p_conference_id
  ORDER BY FIELD(p.role, '主办国','主席国','成员国','观察员','嘉宾国'), cn.name_cn;

  -- 3 议题
  SELECT t.category AS 议题领域, t.name AS 议题, ct.is_core AS 是否核心,
         ct.discussion_date AS 讨论日期
  FROM conference_topic ct
  JOIN topic t ON t.topic_id = ct.topic_id
  WHERE ct.conference_id = p_conference_id
  ORDER BY ct.is_core DESC, t.name;

  -- 4 成果文件
  SELECT d.doc_type AS 文件类型, d.doc_no AS 编号, d.title AS 文件名称,
         d.issue_date AS 通过日期, d.adopt_method AS 通过方式, d.status AS 状态,
         fn_consensus_ratio(d.document_id) AS 共识率百分比
  FROM document d
  WHERE d.conference_id = p_conference_id
  ORDER BY d.issue_date;

  -- 5 后续行动
  SELECT a.action_name AS 行动名称, lc.name_cn AS 牵头国,
         a.planned_end_date AS 计划完成, a.actual_end_date AS 实际完成,
         a.progress_pct AS 进度, a.status AS 状态
  FROM follow_up_action a
  JOIN country lc ON lc.country_id = a.lead_country_id
  WHERE a.conference_id = p_conference_id
  ORDER BY a.action_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Current Database: `multilateral-diplomacy-system-schoolwork-`
--

USE `multilateral-diplomacy-system-schoolwork-`;

--
-- Final view structure for view `v_action_alert`
--

/*!50001 DROP VIEW IF EXISTS `v_action_alert`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_action_alert` AS select `a`.`action_id` AS `action_id`,`a`.`action_name` AS `action_name`,`c`.`short_name` AS `conference_name`,`lc`.`name_cn` AS `lead_country`,`a`.`start_date` AS `start_date`,`a`.`planned_end_date` AS `planned_end_date`,(to_days(curdate()) - to_days(`a`.`planned_end_date`)) AS `overdue_days`,`a`.`progress_pct` AS `progress_pct`,`a`.`status` AS `status`,`a`.`remarks` AS `remarks` from ((`follow_up_action` `a` join `conference` `c` on((`c`.`conference_id` = `a`.`conference_id`))) join `country` `lc` on((`lc`.`country_id` = `a`.`lead_country_id`))) where ((`a`.`actual_end_date` is null) and (`a`.`planned_end_date` < curdate()) and (`a`.`status` <> '终止')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_active_user`
--

/*!50001 DROP VIEW IF EXISTS `v_active_user`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_active_user` AS select `app_user`.`user_id` AS `user_id`,`app_user`.`username` AS `username`,`app_user`.`real_name` AS `real_name`,`app_user`.`user_role` AS `user_role`,`app_user`.`country_id` AS `country_id`,`app_user`.`org_id` AS `org_id`,`app_user`.`is_active` AS `is_active`,`app_user`.`created_at` AS `created_at` from `app_user` where (`app_user`.`is_active` = 1) */
/*!50002 WITH CASCADED CHECK OPTION */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_china_multilateral`
--

/*!50001 DROP VIEW IF EXISTS `v_china_multilateral`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_china_multilateral` AS select `c`.`short_name` AS `conference_name`,`c`.`conference_type` AS `conference_type`,`c`.`start_date` AS `start_date`,`c`.`host_city` AS `host_city`,`c`.`host_country` AS `host_country`,`c`.`mechanism_name` AS `mechanism_name`,`p`.`role` AS `china_role`,`p`.`delegation_level` AS `china_delegation_level`,`p`.`delegation_size` AS `china_delegation_size`,(case when (`p`.`role` = '主办国') then '主办' else '参与' end) AS `china_engagement`,`c`.`document_count` AS `documents_of_conference`,(select count(0) from (`document` `d` join `document_sponsor` `sp` on((`sp`.`document_id` = `d`.`document_id`))) where ((`d`.`conference_id` = `c`.`conference_id`) and (`sp`.`country_id` = `cn`.`country_id`) and (`sp`.`stance` = '联署'))) AS `documents_china_signed` from ((`v_conference_overview` `c` join `conference_participant` `p` on((`p`.`conference_id` = `c`.`conference_id`))) join `country` `cn` on((`cn`.`country_id` = `p`.`country_id`))) where (`cn`.`iso_code` = 'CHN') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_conference_overview`
--

/*!50001 DROP VIEW IF EXISTS `v_conference_overview`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_conference_overview` AS select `c`.`conference_id` AS `conference_id`,`c`.`short_name` AS `short_name`,`c`.`conference_type` AS `conference_type`,`c`.`session_label` AS `session_label`,`c`.`start_date` AS `start_date`,`c`.`end_date` AS `end_date`,`c`.`status` AS `status`,`hc`.`name_cn` AS `host_country`,`c`.`host_city` AS `host_city`,`m`.`name` AS `mechanism_name`,`o`.`name_cn` AS `org_name`,(select count(0) from `conference_participant` `p` where (`p`.`conference_id` = `c`.`conference_id`)) AS `participant_count`,(select count(0) from `conference_topic` `ct` where ((`ct`.`conference_id` = `c`.`conference_id`) and (`ct`.`is_core` = 1))) AS `core_topic_count`,(select count(0) from `document` `d` where (`d`.`conference_id` = `c`.`conference_id`)) AS `document_count`,(select count(0) from `follow_up_action` `a` where (`a`.`conference_id` = `c`.`conference_id`)) AS `action_count`,(select count(0) from `follow_up_action` `a` where ((`a`.`conference_id` = `c`.`conference_id`) and (`a`.`status` = '已完成'))) AS `action_done_count` from (((`conference` `c` join `country` `hc` on((`hc`.`country_id` = `c`.`host_country_id`))) left join `mechanism` `m` on((`m`.`mechanism_id` = `c`.`mechanism_id`))) left join `international_organization` `o` on((`o`.`org_id` = `c`.`org_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_document_consensus`
--

/*!50001 DROP VIEW IF EXISTS `v_document_consensus`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_document_consensus` AS select `d`.`document_id` AS `document_id`,`d`.`doc_no` AS `doc_no`,`d`.`title` AS `title`,`d`.`doc_type` AS `doc_type`,`d`.`adopt_method` AS `adopt_method`,`d`.`issue_date` AS `issue_date`,`c`.`short_name` AS `conference_name`,sum((case when (`ds`.`stance` = '联署') then 1 else 0 end)) AS `signed_count`,sum((case when (`ds`.`stance` = '支持') then 1 else 0 end)) AS `support_count`,sum((case when (`ds`.`stance` = '保留') then 1 else 0 end)) AS `reserved_count`,count(`ds`.`country_id`) AS `total_country_count` from ((`document` `d` join `conference` `c` on((`c`.`conference_id` = `d`.`conference_id`))) left join `document_sponsor` `ds` on((`ds`.`document_id` = `d`.`document_id`))) group by `d`.`document_id`,`d`.`doc_no`,`d`.`title`,`d`.`doc_type`,`d`.`adopt_method`,`d`.`issue_date`,`c`.`short_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_operation_audit`
--

/*!50001 DROP VIEW IF EXISTS `v_operation_audit`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_operation_audit` AS select `l`.`log_id` AS `log_id`,`l`.`log_time` AS `log_time`,coalesce(`u`.`real_name`,'系统触发器') AS `操作人`,coalesce(`u`.`user_role`,'系统') AS `角色`,`l`.`action_type` AS `操作类型`,`l`.`target_table` AS `目标表`,`l`.`target_id` AS `目标ID`,`l`.`old_value` AS `变更前`,`l`.`new_value` AS `变更后`,`l`.`detail` AS `说明` from (`operation_log` `l` left join `app_user` `u` on((`u`.`user_id` = `l`.`user_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed
