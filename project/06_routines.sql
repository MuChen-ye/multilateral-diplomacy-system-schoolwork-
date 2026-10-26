-- ============================================================
-- 实验项目 步骤 6：扩展功能（触发器 + 存储过程 + 函数）
-- 课件 3.7 将存储过程列为自学内容；基础查询见 05 和 08。
-- 触发器：后续行动状态自动判定（逾期预警的业务保障）
-- 存储过程：单场会议全景仪表盘（验收演示用，一次输出 5 个结果集）
-- 函数：成果文件共识率（联署国占比）
-- ============================================================

USE `multilateral-diplomacy-system-schoolwork-`;

DROP TRIGGER IF EXISTS trg_document_before_update;
DROP TRIGGER IF EXISTS trg_action_before_insert;
DROP TRIGGER IF EXISTS trg_action_before_update;
DROP TRIGGER IF EXISTS trg_action_audit;
DROP PROCEDURE IF EXISTS sp_conference_dashboard;
DROP FUNCTION IF EXISTS fn_consensus_ratio;

DELIMITER $$

-- 文件换会议前，检查已关联行动，避免与行动的来源会议不一致。
CREATE TRIGGER trg_document_before_update
BEFORE UPDATE ON document
FOR EACH ROW
BEGIN
  IF NEW.conference_id <> OLD.conference_id AND EXISTS (
    SELECT * FROM follow_up_action a
    WHERE a.document_id = OLD.document_id AND a.conference_id <> NEW.conference_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'action document/conference mismatch';
  END IF;
END$$

-- ---------- 触发器 1：插入时自动判定状态 ----------
CREATE TRIGGER trg_action_before_insert
BEFORE INSERT ON follow_up_action
FOR EACH ROW
BEGIN
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
END$$

-- ---------- 触发器 2：更新时自动判定状态 ----------
CREATE TRIGGER trg_action_before_update
BEFORE UPDATE ON follow_up_action
FOR EACH ROW
BEGIN
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
END$$

-- ---------- 触发器 3：操作审计（状态/进度变化自动留痕） ----------
CREATE TRIGGER trg_action_audit
AFTER UPDATE ON follow_up_action
FOR EACH ROW
BEGIN
  -- MySQL的<=>为空值安全比较，能记录NULL与已知值之间的变化。
  IF NOT (OLD.status <=> NEW.status) OR NOT (OLD.progress_pct <=> NEW.progress_pct) THEN
    INSERT INTO operation_log
      (user_id, action_type, target_table, target_id, old_value, new_value, detail)
    VALUES
      (NULL, 'UPDATE', 'follow_up_action', NEW.action_id,
       CONCAT('status=', COALESCE(OLD.status, '未知'), ', progress=', COALESCE(CAST(OLD.progress_pct AS CHAR), '未知')),
       CONCAT('status=', COALESCE(NEW.status, '未知'), ', progress=', COALESCE(CAST(NEW.progress_pct AS CHAR), '未知')),
       '后续行动状态或进度变更（触发器自动记录）');
  END IF;
END$$

-- ---------- 函数：文件共识率（联署国 / 涉国总数 %） ----------
CREATE FUNCTION fn_consensus_ratio(p_document_id INT)
RETURNS DECIMAL(5,2)
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
END$$

-- ---------- 存储过程：会议全景仪表盘 ----------
CREATE PROCEDURE sp_conference_dashboard(IN p_conference_id INT)
COMMENT '输出一场国际会议的：基本信息 / 参与国家 / 议题 / 成果文件 / 后续行动'
BEGIN
  -- 1 基本信息
  SELECT c.short_name AS 会议简称, c.title AS 会议全称, c.conference_type AS 会议类型,
         c.session_label AS 届次, c.start_date AS 开始日期, c.end_date AS 结束日期,
         c.status AS 状态, hc.name_cn AS 举办地国家, m.name AS 所属机制
  FROM conference c
  LEFT JOIN country hc   ON hc.country_id = c.host_country_id
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
  LEFT JOIN country lc ON lc.country_id = a.lead_country_id
  WHERE a.conference_id = p_conference_id
  ORDER BY a.action_id;
END$$

DELIMITER ;

-- 按已知期限刷新行动状态；NULL不推定为0或进行中
UPDATE follow_up_action SET progress_pct = progress_pct;
