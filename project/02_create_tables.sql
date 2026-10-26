-- 步骤 2：建立 12 张表，先建被引用表，再建引用表；删除顺序相反。
-- 课件 3.2：基本类型、PRIMARY KEY、FOREIGN KEY、UNIQUE、CHECK、CREATE INDEX。
-- MySQL 适配：实体 ID 自增，InnoDB 支持外键，DATETIME 记录日志时刻。
USE `multilateral-diplomacy-system-schoolwork-`;

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

-- 真实资料未公开的分类、人数、核心标记、通过方式和执行情况允许NULL。
-- 1. 参与国家表
CREATE TABLE country (
  country_id INT AUTO_INCREMENT,
  iso_code CHAR(3) NOT NULL,
  name_cn VARCHAR(50) NOT NULL,
  name_en VARCHAR(80) NOT NULL,
  continent VARCHAR(10) NOT NULL,
  development_status VARCHAR(10),
  is_un_member SMALLINT NOT NULL DEFAULT 1,
  note VARCHAR(200),
  PRIMARY KEY (country_id),
  UNIQUE (iso_code),
  UNIQUE (name_cn),
  CHECK (continent IN ('亚洲','欧洲','非洲','北美洲','南美洲','大洋洲')),
  CHECK (development_status IN ('发达国家','发展中国家','最不发达国家')),
  CHECK (is_un_member IN (0,1))
) ENGINE=InnoDB;

-- 2. 国际组织表
CREATE TABLE international_organization (
  org_id INT AUTO_INCREMENT,
  name_cn VARCHAR(80) NOT NULL,
  abbr VARCHAR(20),
  org_type VARCHAR(10) NOT NULL,
  founded_year SMALLINT,
  hq_city VARCHAR(50),
  PRIMARY KEY (org_id),
  UNIQUE (name_cn),
  UNIQUE (abbr),
  CHECK (org_type IN ('联合国系统','区域性组织','多边机制','专门机构')),
  CHECK (founded_year BETWEEN 1 AND 9999)
) ENGINE=InnoDB;

-- 3. 多边机制表
CREATE TABLE mechanism (
  mechanism_id INT AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  abbr VARCHAR(20),
  category VARCHAR(10) NOT NULL,
  founded_year SMALLINT,
  lead_org_id INT,
  description VARCHAR(200),
  PRIMARY KEY (mechanism_id),
  UNIQUE (name),
  FOREIGN KEY (lead_org_id) REFERENCES international_organization (org_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CHECK (category IN ('全球治理','区域合作','南南合作','大国协调','专门领域')),
  CHECK (founded_year BETWEEN 1 AND 9999)
) ENGINE=InnoDB;

-- 4. 议题表
CREATE TABLE topic (
  topic_id INT AUTO_INCREMENT,
  name VARCHAR(60) NOT NULL,
  category VARCHAR(10) NOT NULL,
  description VARCHAR(200),
  PRIMARY KEY (topic_id),
  UNIQUE (name),
  CHECK (category IN ('和平与安全','发展与合作','气候变化','公共卫生','人文交流','全球治理体系'))
) ENGINE=InnoDB;

-- 5. 国际会议表：host_country_id记录举办地国家；纯线上会议可为空。
CREATE TABLE conference (
  conference_id INT AUTO_INCREMENT,
  title VARCHAR(120) NOT NULL,
  short_name VARCHAR(60),
  mechanism_id INT,
  org_id INT,
  host_country_id INT,
  host_city VARCHAR(60),
  conference_type VARCHAR(10) NOT NULL,
  session_label VARCHAR(20),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  format VARCHAR(10),
  status VARCHAR(10) NOT NULL DEFAULT '已闭幕',
  theme VARCHAR(200),
  PRIMARY KEY (conference_id),
  FOREIGN KEY (mechanism_id) REFERENCES mechanism (mechanism_id) ON UPDATE CASCADE ON DELETE SET NULL,
  FOREIGN KEY (org_id) REFERENCES international_organization (org_id) ON UPDATE CASCADE ON DELETE SET NULL,
  FOREIGN KEY (host_country_id) REFERENCES country (country_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (end_date >= start_date),
  CHECK (conference_type IN ('首脑峰会','部长级会议','高官会议','专家会议','大会','特别会议','专题会议')),
  CHECK (format IN ('线下','线上','混合')),
  CHECK (status IN ('筹备中','进行中','已闭幕','取消'))
) ENGINE=InnoDB;

-- 6. 会议参与国家表
CREATE TABLE conference_participant (
  conference_id INT NOT NULL,
  country_id INT NOT NULL,
  role VARCHAR(10) NOT NULL DEFAULT '成员国',
  delegation_level VARCHAR(10),
  delegation_size INT,
  join_date DATE,
  PRIMARY KEY (conference_id, country_id),
  FOREIGN KEY (conference_id) REFERENCES conference (conference_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (country_id) REFERENCES country (country_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (delegation_size >= 0),
  CHECK (role IN ('主办国','主席国','成员国','观察员','嘉宾国','对话伙伴')),
  CHECK (delegation_level IN ('元首级','政府首脑级','外交部长级','部长级','高官级','专家级'))
) ENGINE=InnoDB;

-- 7. 会议议题关联表
CREATE TABLE conference_topic (
  conference_id INT NOT NULL,
  topic_id INT NOT NULL,
  is_core SMALLINT,
  discussion_date DATE,
  summary VARCHAR(300),
  PRIMARY KEY (conference_id, topic_id),
  FOREIGN KEY (conference_id) REFERENCES conference (conference_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (topic_id) REFERENCES topic (topic_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (is_core IN (0,1))
) ENGINE=InnoDB;

-- 8. 成果文件表
CREATE TABLE document (
  document_id INT AUTO_INCREMENT,
  conference_id INT NOT NULL,
  title VARCHAR(120) NOT NULL,
  doc_type VARCHAR(10) NOT NULL,
  doc_no VARCHAR(40),
  issue_date DATE NOT NULL,
  adopt_method VARCHAR(10),
  status VARCHAR(10) NOT NULL DEFAULT '已通过',
  summary VARCHAR(300),
  PRIMARY KEY (document_id),
  UNIQUE (doc_no),
  FOREIGN KEY (conference_id) REFERENCES conference (conference_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CHECK (doc_no IS NULL OR CHAR_LENGTH(TRIM(doc_no)) > 0),
  CHECK (doc_type IN ('宣言','政治宣言','联合声明','声明','联合公报','决议','联合国大会决议','决定',
    '行动计划','行动执行计划','主席声明','条约','议定书','谅解备忘录','倡议')),
  CHECK (adopt_method IN ('协商一致','表决通过')),
  CHECK (status IN ('草案','已通过','已生效','已发布','已签署'))
) ENGINE=InnoDB;

-- 9. 文件联署/支持国家表
CREATE TABLE document_sponsor (
  document_id INT NOT NULL,
  country_id INT NOT NULL,
  stance VARCHAR(10) NOT NULL DEFAULT '联署',
  PRIMARY KEY (document_id, country_id),
  FOREIGN KEY (document_id) REFERENCES document (document_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (country_id) REFERENCES country (country_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (stance IN ('联署','支持','保留'))
) ENGINE=InnoDB;

-- 10. 后续行动表
CREATE TABLE follow_up_action (
  action_id INT AUTO_INCREMENT,
  conference_id INT NOT NULL,
  document_id INT,
  action_name VARCHAR(120) NOT NULL,
  lead_country_id INT,
  responsible_org_id INT,
  start_date DATE,
  planned_end_date DATE,
  actual_end_date DATE,
  progress_pct INT,
  status VARCHAR(10),
  remarks VARCHAR(200),
  PRIMARY KEY (action_id),
  FOREIGN KEY (conference_id) REFERENCES conference (conference_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (document_id) REFERENCES document (document_id) ON UPDATE CASCADE ON DELETE SET NULL,
  FOREIGN KEY (lead_country_id) REFERENCES country (country_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (responsible_org_id) REFERENCES international_organization (org_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CHECK (progress_pct BETWEEN 0 AND 100),
  CHECK (planned_end_date >= start_date),
  CHECK (actual_end_date IS NULL OR actual_end_date >= start_date),
  CHECK (status <> '已完成' OR actual_end_date IS NOT NULL),
  CHECK (status IN ('未启动','进行中','已完成','逾期','终止'))
) ENGINE=InnoDB;

-- 11. 系统用户表
CREATE TABLE app_user (
  user_id INT AUTO_INCREMENT,
  username VARCHAR(40) NOT NULL,
  real_name VARCHAR(40) NOT NULL,
  user_role VARCHAR(10) NOT NULL DEFAULT '观察员',
  country_id INT,
  org_id INT,
  is_active SMALLINT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE (username),
  FOREIGN KEY (country_id) REFERENCES country (country_id) ON UPDATE CASCADE ON DELETE SET NULL,
  FOREIGN KEY (org_id) REFERENCES international_organization (org_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CHECK (user_role IN ('系统管理员','会议组织者','外交官','观察员')),
  CHECK (is_active IN (0,1))
) ENGINE=InnoDB;

-- 12. 操作审计表
CREATE TABLE operation_log (
  log_id BIGINT AUTO_INCREMENT,
  user_id INT,
  action_type VARCHAR(10) NOT NULL,
  target_table VARCHAR(40) NOT NULL,
  target_id INT,
  old_value VARCHAR(200),
  new_value VARCHAR(200),
  log_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  detail VARCHAR(300),
  PRIMARY KEY (log_id),
  FOREIGN KEY (user_id) REFERENCES app_user (user_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CHECK (action_type IN ('INSERT','UPDATE','DELETE'))
) ENGINE=InnoDB;

-- 查询索引（课件 3.2.4）；外键所需索引由 InnoDB 自动建立。
CREATE INDEX idx_country_continent ON country (continent);
CREATE INDEX idx_topic_category ON topic (category);
CREATE INDEX idx_conf_dates ON conference (start_date, end_date);
CREATE INDEX idx_doc_type ON document (doc_type);
CREATE INDEX idx_action_due ON follow_up_action (planned_end_date);
CREATE INDEX idx_user_role ON app_user (user_role);
CREATE INDEX idx_log_time ON operation_log (log_time);
CREATE INDEX idx_log_target ON operation_log (target_table, target_id);
