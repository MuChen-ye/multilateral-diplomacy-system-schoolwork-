-- ============================================================
-- 实验项目 步骤 2：建立关系模式（12 张表）
-- 主题链：国际会议 — 参与国家 — 议题 — 成果文件 — 后续行动
--
-- 无外键依赖：country / international_organization / topic
-- mechanism 依赖 international_organization；app_user 依赖国家/组织；operation_log 依赖用户。
-- 课件对应：CREATE TABLE、PRIMARY KEY、FOREIGN KEY、UNIQUE、CHECK。
-- ENUM、AUTO_INCREMENT、KEY、InnoDB 为本项目使用的 MySQL 扩展。
-- 从表：conference -> conference_participant, conference_topic, document
--      document -> document_sponsor
--      conference/document -> follow_up_action
-- ============================================================

USE `multilateral-diplomacy-system-schoolwork-`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS operation_log;
DROP TABLE IF EXISTS app_user;
DROP TABLE IF EXISTS follow_up_action;
DROP TABLE IF EXISTS document_sponsor;
DROP TABLE IF EXISTS document;
DROP TABLE IF EXISTS conference_topic;
DROP TABLE IF EXISTS conference_participant;
DROP TABLE IF EXISTS conference;
DROP TABLE IF EXISTS topic;
DROP TABLE IF EXISTS mechanism;
DROP TABLE IF EXISTS international_organization;
DROP TABLE IF EXISTS country;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------- 表 1 country 参与国家表 ----------
CREATE TABLE country (
  country_id         INT          NOT NULL AUTO_INCREMENT COMMENT '国家ID',
  iso_code           CHAR(3)      NOT NULL                COMMENT 'ISO三位代码',
  name_cn            VARCHAR(50)  NOT NULL                COMMENT '国家名称(中文)',
  name_en            VARCHAR(80)  NOT NULL                COMMENT '国家名称(英文)',
  continent          ENUM('亚洲','欧洲','非洲','北美洲','南美洲','大洋洲') NOT NULL COMMENT '所属大洲',
  development_status ENUM('发达国家','发展中国家','最不发达国家') NOT NULL DEFAULT '发展中国家' COMMENT '发展水平',
  is_un_member       TINYINT(1)   NOT NULL DEFAULT 1      COMMENT '是否联合国成员国',
  note               VARCHAR(200)     NULL                COMMENT '备注',
  PRIMARY KEY (country_id),
  UNIQUE KEY uk_country_iso  (iso_code),
  UNIQUE KEY uk_country_name (name_cn),
  KEY idx_country_continent  (continent)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='参与国家表';

-- ---------- 表 2 international_organization 国际组织表 ----------
CREATE TABLE international_organization (
  org_id       INT          NOT NULL AUTO_INCREMENT COMMENT '组织ID',
  name_cn      VARCHAR(80)  NOT NULL                COMMENT '组织中文名',
  abbr         VARCHAR(20)      NULL                COMMENT '组织简称',
  org_type     ENUM('联合国系统','区域性组织','多边机制','专门机构') NOT NULL COMMENT '组织类型',
  founded_year YEAR             NULL                COMMENT '成立年份',
  hq_city      VARCHAR(50)      NULL                COMMENT '总部所在地',
  PRIMARY KEY (org_id),
  UNIQUE KEY uk_org_name (name_cn),
  UNIQUE KEY uk_org_abbr (abbr)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='国际组织表';

-- ---------- 表 3 mechanism 多边机制表（会议所属的合作框架/序列） ----------
CREATE TABLE mechanism (
  mechanism_id INT          NOT NULL AUTO_INCREMENT COMMENT '机制ID',
  name         VARCHAR(80)  NOT NULL                COMMENT '机制名称',
  abbr         VARCHAR(20)      NULL                COMMENT '机制简称',
  category     ENUM('全球治理','区域合作','南南合作','大国协调','专门领域') NOT NULL COMMENT '机制类别',
  founded_year YEAR             NULL                COMMENT '启动年份',
  lead_org_id  INT              NULL                COMMENT '牵头组织',
  description  VARCHAR(200)     NULL                COMMENT '机制说明',
  PRIMARY KEY (mechanism_id),
  UNIQUE KEY uk_mechanism_name (name),
  KEY idx_mechanism_org (lead_org_id),
  CONSTRAINT fk_mechanism_org FOREIGN KEY (lead_org_id) REFERENCES international_organization (org_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='多边机制表';

-- ---------- 表 4 topic 议题表 ----------
CREATE TABLE topic (
  topic_id    INT          NOT NULL AUTO_INCREMENT COMMENT '议题ID',
  name        VARCHAR(60)  NOT NULL                COMMENT '议题名称',
  category    ENUM('和平与安全','发展与合作','气候变化','公共卫生','人文交流','全球治理体系') NOT NULL COMMENT '议题领域',
  description VARCHAR(200)     NULL                COMMENT '议题说明',
  PRIMARY KEY (topic_id),
  UNIQUE KEY uk_topic_name (name),
  KEY idx_topic_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='议题表';

-- ---------- 表 5 conference 国际会议表 ----------
CREATE TABLE conference (
  conference_id  INT          NOT NULL AUTO_INCREMENT COMMENT '会议ID',
  title          VARCHAR(120) NOT NULL                COMMENT '会议全称',
  short_name     VARCHAR(60)      NULL                COMMENT '会议简称',
  mechanism_id   INT              NULL                COMMENT '所属机制',
  org_id         INT              NULL                COMMENT '主办国际组织',
  host_country_id INT         NOT NULL                COMMENT '主办/承办国家',
  host_city      VARCHAR(60)      NULL                COMMENT '举办城市',
  conference_type ENUM('首脑峰会','部长级会议','高官会议','专家会议','大会','特别会议') NOT NULL COMMENT '会议类型',
  session_label  VARCHAR(20)      NULL                COMMENT '届次(如 第24次)',
  start_date     DATE         NOT NULL                COMMENT '开始日期',
  end_date       DATE         NOT NULL                COMMENT '结束日期',
  format         ENUM('线下','线上','混合') NOT NULL DEFAULT '线下' COMMENT '会议形式',
  status         ENUM('筹备中','进行中','已闭幕','取消') NOT NULL DEFAULT '已闭幕' COMMENT '会议状态',
  theme          VARCHAR(200)     NULL                COMMENT '会议主题',
  PRIMARY KEY (conference_id),
  KEY idx_conf_dates     (start_date, end_date),
  KEY idx_conf_mechanism (mechanism_id),
  KEY idx_conf_host      (host_country_id),
  KEY idx_conf_org       (org_id),
  CONSTRAINT fk_conf_mechanism FOREIGN KEY (mechanism_id) REFERENCES mechanism (mechanism_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_conf_org FOREIGN KEY (org_id) REFERENCES international_organization (org_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_conf_host FOREIGN KEY (host_country_id) REFERENCES country (country_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_conf_dates CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='国际会议表';

-- ---------- 表 6 conference_participant 会议参与国家表 ----------
CREATE TABLE conference_participant (
  participant_id  INT         NOT NULL AUTO_INCREMENT COMMENT '参与记录ID',
  conference_id   INT         NOT NULL                COMMENT '会议ID',
  country_id      INT         NOT NULL                COMMENT '国家ID',
  role            ENUM('主办国','主席国','成员国','观察员','嘉宾国') NOT NULL DEFAULT '成员国' COMMENT '参会身份',
  delegation_level ENUM('元首级','政府首脑级','外交部长级','部长级','高官级','专家级') NOT NULL DEFAULT '部长级' COMMENT '出席级别',
  delegation_size INT         NOT NULL DEFAULT 0      COMMENT '代表团人数',
  join_date       DATE            NULL                COMMENT '确认参会日期',
  PRIMARY KEY (participant_id),
  UNIQUE KEY uk_participant (conference_id, country_id),
  KEY idx_participant_country (country_id),
  CONSTRAINT fk_participant_conf FOREIGN KEY (conference_id) REFERENCES conference (conference_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_participant_country FOREIGN KEY (country_id) REFERENCES country (country_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_participant_size CHECK (delegation_size >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会议参与国家表';

-- ---------- 表 7 conference_topic 会议议题关联表 ----------
CREATE TABLE conference_topic (
  conference_id   INT      NOT NULL COMMENT '会议ID',
  topic_id        INT      NOT NULL COMMENT '议题ID',
  is_core         TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否核心议题',
  discussion_date DATE         NULL COMMENT '讨论日期',
  summary         VARCHAR(300) NULL COMMENT '议题讨论要点',
  PRIMARY KEY (conference_id, topic_id),
  KEY idx_ct_topic (topic_id),
  CONSTRAINT fk_ct_conf  FOREIGN KEY (conference_id) REFERENCES conference (conference_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ct_topic FOREIGN KEY (topic_id) REFERENCES topic (topic_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会议议题关联表';

-- ---------- 表 8 document 成果文件表 ----------
CREATE TABLE document (
  document_id   INT          NOT NULL AUTO_INCREMENT COMMENT '文件ID',
  conference_id INT          NOT NULL                COMMENT '所属会议',
  title         VARCHAR(120) NOT NULL                COMMENT '文件名称',
  doc_type      ENUM('联合声明','联合公报','决议','行动计划','谅解备忘录','倡议') NOT NULL COMMENT '文件类型',
  doc_no        VARCHAR(40)      NULL                COMMENT '文件编号',
  issue_date    DATE         NOT NULL                COMMENT '发布/通过日期',
  adopt_method  ENUM('协商一致','表决通过') NOT NULL DEFAULT '协商一致' COMMENT '通过方式',
  status        ENUM('草案','已通过','已生效') NOT NULL DEFAULT '已通过' COMMENT '文件状态',
  summary       VARCHAR(300)     NULL                COMMENT '内容概要',
  PRIMARY KEY (document_id),
  UNIQUE KEY uk_document_no (doc_no),
  KEY idx_doc_conf (conference_id),
  KEY idx_doc_type (doc_type),
  CONSTRAINT fk_doc_conf FOREIGN KEY (conference_id) REFERENCES conference (conference_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT ck_doc_no_empty CHECK (doc_no IS NULL OR CHAR_LENGTH(TRIM(doc_no)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成果文件表';

-- ---------- 表 9 document_sponsor 文件联署/支持国家表 ----------
CREATE TABLE document_sponsor (
  document_id INT NOT NULL COMMENT '文件ID',
  country_id  INT NOT NULL COMMENT '国家ID',
  stance      ENUM('联署','支持','保留') NOT NULL DEFAULT '联署' COMMENT '国别立场',
  PRIMARY KEY (document_id, country_id),
  KEY idx_sponsor_country (country_id),
  CONSTRAINT fk_sponsor_doc FOREIGN KEY (document_id) REFERENCES document (document_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_sponsor_country FOREIGN KEY (country_id) REFERENCES country (country_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文件联署/支持国家表';

-- ---------- 表 10 follow_up_action 后续行动表 ----------
CREATE TABLE follow_up_action (
  action_id         INT          NOT NULL AUTO_INCREMENT COMMENT '行动ID',
  conference_id     INT          NOT NULL                COMMENT '来源会议',
  document_id       INT              NULL                COMMENT '依据文件',
  action_name       VARCHAR(120) NOT NULL                COMMENT '行动名称',
  lead_country_id   INT          NOT NULL                COMMENT '牵头国家',
  responsible_org_id INT             NULL                COMMENT '责任国际组织',
  start_date        DATE         NOT NULL                COMMENT '启动日期',
  planned_end_date  DATE         NOT NULL                COMMENT '计划完成日期',
  actual_end_date   DATE             NULL                COMMENT '实际完成日期(未完成为NULL)',
  progress_pct      INT          NOT NULL DEFAULT 0      COMMENT '进度百分比',
  status            ENUM('未启动','进行中','已完成','逾期','终止') NOT NULL DEFAULT '进行中' COMMENT '行动状态',
  remarks           VARCHAR(200)     NULL                COMMENT '备注',
  PRIMARY KEY (action_id),
  KEY idx_action_conf (conference_id),
  KEY idx_action_doc  (document_id),
  KEY idx_action_lead (lead_country_id),
  KEY idx_action_org  (responsible_org_id),
  KEY idx_action_due  (planned_end_date),
  CONSTRAINT fk_action_conf FOREIGN KEY (conference_id) REFERENCES conference (conference_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_action_doc FOREIGN KEY (document_id) REFERENCES document (document_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_action_lead FOREIGN KEY (lead_country_id) REFERENCES country (country_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_action_org FOREIGN KEY (responsible_org_id) REFERENCES international_organization (org_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT ck_action_progress CHECK (progress_pct BETWEEN 0 AND 100),
  CONSTRAINT ck_action_dates CHECK (planned_end_date >= start_date),
  CONSTRAINT ck_action_actual CHECK (actual_end_date IS NULL OR actual_end_date >= start_date),
  CONSTRAINT ck_action_done CHECK (status <> '已完成' OR actual_end_date IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后续行动表';

-- ---------- 表 11 app_user 系统用户表（操作者与角色） ----------
CREATE TABLE app_user (
  user_id    INT         NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  username   VARCHAR(40) NOT NULL                COMMENT '登录账号',
  real_name  VARCHAR(40) NOT NULL                COMMENT '姓名',
  user_role  ENUM('系统管理员','会议组织者','外交官','观察员') NOT NULL DEFAULT '观察员' COMMENT '角色',
  country_id INT             NULL                COMMENT '所属国家',
  org_id     INT             NULL                COMMENT '所属国际组织',
  is_active  TINYINT(1)  NOT NULL DEFAULT 1      COMMENT '是否启用',
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (user_id),
  UNIQUE KEY uk_user_username (username),
  KEY idx_user_role (user_role),
  KEY idx_user_country (country_id),
  CONSTRAINT fk_user_country FOREIGN KEY (country_id) REFERENCES country (country_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_user_org FOREIGN KEY (org_id) REFERENCES international_organization (org_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统用户表';

-- ---------- 表 12 operation_log 操作审计表（由触发器自动写入） ----------
CREATE TABLE operation_log (
  log_id      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  user_id     INT             NULL                COMMENT '操作人(周界外为NULL)',
  action_type ENUM('INSERT','UPDATE','DELETE') NOT NULL COMMENT '操作类型',
  target_table VARCHAR(40) NOT NULL               COMMENT '目标表',
  target_id   INT             NULL                COMMENT '目标记录主键',
  old_value   VARCHAR(200)    NULL                COMMENT '变更前摘要',
  new_value   VARCHAR(200)    NULL                COMMENT '变更后摘要',
  log_time    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  detail      VARCHAR(300)    NULL                COMMENT '说明',
  PRIMARY KEY (log_id),
  KEY idx_log_time (log_time),
  KEY idx_log_target (target_table, target_id),
  KEY idx_log_user (user_id),
  CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES app_user (user_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作审计表';
