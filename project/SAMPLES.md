# 3.4 样例设计与实际运行结果

本节共16个样例，包含5个复杂查询，覆盖增加、删除、修改、查询、综合统计、事务、主键、唯一、外键、CHECK、视图和触发器。结果于2026-10-27在MySQL 8.4.11独立临时实例实际取得，时区为+08:00，启用严格模式和ONLY_FULL_GROUP_BY。

测试使用03中的50场真实会议资料，所有虚构数据仅用于事务内演示。07—09重复执行后，10张业务表的5036个字段值与执行前一致，用户表和日志表也恢复原样。这里没有对现有业务数据库运行初始化或测试。

## 要求与样例对应

| 编号 | 类型 | 内容 | 执行位置 |
|---|---|---|---|
| S01 | 查询 | 按机制统计会议、文件与参会国次 | [05_queries.sql 查询2](05_queries.sql) |
| S02 | 查询 | 筛选已登记参会国不少于8个的会议 | [05_queries.sql 查询3](05_queries.sql) |
| S03 | 查询 | 同时有中国和巴西参会的会议 | [08_course_examples.sql 示例2](08_course_examples.sql) |
| S04 | 查询 | 参加1号会议的国家 | [08_course_examples.sql 示例3](08_course_examples.sql) |
| S05 | 查询 | 参加中国所参加全部已登记会议的国家 | [05_queries.sql 查询12](05_queries.sql) |
| S06 | 增加＋触发器 | 插入会议及关联资料，观察插入触发器 | [07_crud_samples.sql S06](07_crud_samples.sql) |
| S07 | 修改＋触发器 | 填写完成日期，触发状态、进度与审计联动 | [07_crud_samples.sql S07](07_crud_samples.sql) |
| S08 | 删除 | 删除观察员登记及演示行动 | [07_crud_samples.sql S08](07_crud_samples.sql) |
| S09 | 综合 | 综合统计文件联署比例 | [07_crud_samples.sql S09](07_crud_samples.sql) |
| S10 | 事务与完整性 | 回滚并核对真实数据 | [07_crud_samples.sql S10](07_crud_samples.sql) |
| S11 | 主键约束 | 复合主键拒绝重复参会登记 | [09_constraint_samples.sql S11](09_constraint_samples.sql) |
| S12 | 唯一约束 | 唯一约束拒绝重复非空文号 | [09_constraint_samples.sql S12](09_constraint_samples.sql) |
| S13 | 外键约束 | 外键拒绝不存在的国家与受引用父行删除 | [09_constraint_samples.sql S13](09_constraint_samples.sql) |
| S14 | 检查约束 | CHECK拒绝非法值并验证NULL的含义 | [09_constraint_samples.sql S14](09_constraint_samples.sql) |
| S15 | 触发器违反 | 触发器拒绝行动与文件来源会议不一致 | [09_constraint_samples.sql S15](09_constraint_samples.sql) |
| S16 | 视图与约束 | 可更新视图的合法修改与CHECK OPTION拒绝 | [09_constraint_samples.sql S16；08示例9](09_constraint_samples.sql) |

## 执行方法

前置条件：已建立01、02、03、04、06中的基础数据与对象。已有库不需要为演示重新运行01或02。更新后先单独运行04，刷新预警视图，再运行以下样例：

```bash
# 在项目根目录；Linux的root使用系统身份认证时：
sudo mysql < project/04_views.sql
sudo mysql --table < project/05_queries.sql
sudo mysql --table < project/07_crud_samples.sql
sudo mysql --table < project/08_course_examples.sql
sudo mysql --force --table < project/09_constraint_samples.sql
```

09故意包含11条非法语句，应显示错误；--force只用于该文件，让后续核对与ROLLBACK继续执行。正常建库流程不启用--force，也不自动执行09。图形客户端可按编号逐条演示；手动中断后应在同一连接执行ROLLBACK。

查询结果只反映已采集的记录。示例日期按CURDATE生成；日期、自增编号、已有账号和日志数量可能随实际运行变化。真实资料的未知值仍为NULL，不能为得到演示结果而补造人数、进度和日期。

## SQL与实际结果

### S01 按机制统计会议、文件与参会国次

课件对应：11—12第16、28页；13第5—10页。使用相关子查询、连接和COUNT分别统计，避免把参会记录与文件直接连接后重复计数。参会国次为已登记的“会议＋国家”组合数。

```sql
SELECT m.name AS 机制, m.category AS 类别,
       (SELECT COUNT(*) FROM conference c
        WHERE c.mechanism_id = m.mechanism_id) AS 会议数,
       (SELECT COUNT(*) FROM conference c, document d
        WHERE c.conference_id = d.conference_id
          AND c.mechanism_id = m.mechanism_id) AS 成果文件数,
       (SELECT COUNT(*) FROM conference c, conference_participant p
        WHERE c.conference_id = p.conference_id
          AND c.mechanism_id = m.mechanism_id) AS 参会国次
FROM mechanism m
ORDER BY 会议数 DESC, 成果文件数 DESC, m.mechanism_id;
```

实际查询结果：

| 机制 | 类别 | 会议数 | 成果文件数 | 参会国次 |
| --- | --- | --- | --- | --- |
| 金砖国家合作机制 | 南南合作 | 8 | 7 | 40 |
| 上海合作组织元首理事会 | 区域合作 | 6 | 6 | 68 |
| 上海合作组织政府首脑理事会 | 区域合作 | 5 | 5 | 64 |
| 中非合作论坛 | 南南合作 | 4 | 7 | 19 |
| 二十国集团 | 全球治理 | 4 | 4 | 7 |
| 联合国大会一般性辩论 | 全球治理 | 4 | 0 | 19 |
| 中国—东盟领导人会议 | 区域合作 | 3 | 6 | 25 |
| 联合国气候变化大会 | 专门领域 | 3 | 4 | 2 |
| 中国—阿拉伯国家合作论坛 | 南南合作 | 2 | 4 | 22 |
| 中国—中亚机制 | 区域合作 | 2 | 3 | 12 |
| 澜沧江—湄公河合作 | 区域合作 | 1 | 2 | 6 |
| 中国—拉共体论坛 | 南南合作 | 1 | 2 | 4 |
| 联合国可持续发展高级别政治论坛 | 全球治理 | 1 | 1 | 2 |
| 上海合作组织外长理事会 | 区域合作 | 1 | 1 | 1 |
| 中国—东盟外长会 | 区域合作 | 1 | 1 | 2 |
| 亚洲相互协作与信任措施会议 | 区域合作 | 1 | 1 | 2 |
| 全球发展倡议 | 全球治理 | 1 | 0 | 4 |

### S02 筛选已登记参会国不少于8个的会议

课件对应：13第9—10页。先连接会议与参会记录，再GROUP BY分组，最后HAVING筛选。这里统计已采集名册，不推定为完整参会名单。

```sql
SELECT c.short_name AS 会议简称, COUNT(p.country_id) AS 参与国数
FROM conference c
JOIN conference_participant p ON p.conference_id = c.conference_id
GROUP BY c.conference_id, c.short_name
HAVING COUNT(p.country_id) >= 8
ORDER BY 参与国数 DESC, c.conference_id;
```

实际查询结果：

| 会议简称 | 参与国数 |
| --- | --- |
| 上合莫斯科总理会 | 16 |
| 首届中阿利雅得峰会2022 | 16 |
| UNGA80一般性辩论 | 15 |
| 上合撒马尔罕元首理事会2022 | 14 |
| 上合伊斯兰堡总理会 | 12 |
| 上合新德里视频峰会 | 12 |
| 上合比什凯克总理会 | 12 |
| 中国—东盟万象会议2024 | 12 |
| 上合杜尚别总理会2026 | 12 |
| 上合总理视频会议2022 | 12 |
| 上合杜尚别元首理事会2021 | 12 |
| 中国—东盟雅加达会议2023 | 11 |
| 上合阿斯塔纳峰会 | 10 |
| 上合天津元首理事会 | 10 |
| 上合比什凯克元首理事会2026 | 10 |
| 金砖新德里峰会2026 | 10 |
| 金砖喀山峰会 | 9 |

### S03 同时有中国和巴西参会的会议

课件对应：11—12第12—15页。同一参会表使用两个别名，与会议表作等值连接。复合主键保证同一国家在每场会议最多一条记录。

```sql
SELECT c.short_name AS 会议
FROM conference c, conference_participant x, conference_participant y
WHERE c.conference_id = x.conference_id AND x.conference_id = y.conference_id
  AND x.country_id = (SELECT country_id FROM country WHERE iso_code = 'CHN')
  AND y.country_id = (SELECT country_id FROM country WHERE iso_code = 'BRA')
ORDER BY c.conference_id;
```

实际查询结果：

| 会议 |
| --- |
| 金砖喀山峰会 |
| G20里约峰会 |
| 金砖里约外长会 |
| 金砖里约峰会2025 |
| 金砖约翰内斯堡峰会 |
| 中拉论坛北京部长会2025 |
| 金砖新德里峰会2026 |
| 金砖领导人视频会晤2022 |
| 金砖新德里视频会晤2021 |

### S04 参加1号会议的国家

课件对应：11—12第17—21页。用IN子查询从国家表取出已登记参加1号会议的国家。

```sql
SELECT name_cn AS 国家 FROM country
WHERE country_id IN (SELECT country_id FROM conference_participant WHERE conference_id = 1)
ORDER BY country_id;
```

实际查询结果：

| 国家 |
| --- |
| 中国 |
| 俄罗斯 |
| 印度 |
| 哈萨克斯坦 |
| 巴基斯坦 |
| 乌兹别克斯坦 |
| 伊朗 |
| 吉尔吉斯斯坦 |
| 塔吉克斯坦 |
| 白俄罗斯 |

### S05 参加中国所参加全部已登记会议的国家

课件对应：11—12第30、36页。用双重NOT EXISTS表达关系除法：不存在一场中国参加、而该国没有参加的已登记会议。结果包含中国本身。

```sql
SELECT cn.country_id AS 国家编号, cn.name_cn AS 国家
FROM country cn
WHERE NOT EXISTS (
  SELECT * FROM conference_participant p
  WHERE p.country_id = (SELECT country_id FROM country WHERE iso_code = 'CHN')
    AND NOT EXISTS (
      SELECT * FROM conference_participant x
      WHERE x.conference_id = p.conference_id AND x.country_id = cn.country_id
    )
)
ORDER BY cn.country_id;
```

实际查询结果：

| 国家编号 | 国家 |
| --- | --- |
| 1 | 中国 |

### S06 插入会议及关联资料，观察插入触发器

课件对应：14—15第6—8页。同时演示单行VALUES、多行VALUES和INSERT ... SELECT。所有数据均明确标为虚构，只在事务内存在。计划完成日设为运行日前一天，输入状态为进行中，触发器自动改为逾期。

S06—S10在同一连接顺序执行，先作以下准备：

```sql
-- 课件3.4：单行/多行INSERT、INSERT ... SELECT、带子查询的UPDATE/DELETE。
-- S06—S10：只在事务中建立虚构演示数据，最后ROLLBACK；真实资料保持原样。
-- MySQL适配：用户变量、LAST_INSERT_ID、CURDATE和DATE_SUB。
USE `multilateral-diplomacy-system-schoolwork-`;

START TRANSACTION;
SET @demo_day = CURDATE();
SET @china = (SELECT country_id FROM country WHERE iso_code = 'CHN');
SET @kaz = (SELECT country_id FROM country WHERE iso_code = 'KAZ');
SET @rus = (SELECT country_id FROM country WHERE iso_code = 'RUS');
SET @security = (SELECT topic_id FROM topic WHERE name = '全球安全治理');
SET @ai = (SELECT topic_id FROM topic WHERE name = '人工智能治理');
```

```sql
INSERT INTO conference
  (title, short_name, host_country_id, host_city, conference_type, start_date, end_date, format)
VALUES
  ('课程综合演示会议（虚构）', '课件演示会议', @china, '北京', '专题会议',
   DATE_SUB(@demo_day, INTERVAL 10 DAY), DATE_SUB(@demo_day, INTERVAL 9 DAY), '线下');
SET @conf = LAST_INSERT_ID();

INSERT INTO conference_participant
  (conference_id, country_id, role, delegation_level, delegation_size)
VALUES
  (@conf, @china, '主办国', '元首级', 60),
  (@conf, @kaz, '成员国', '元首级', 40),
  (@conf, @rus, '成员国', '元首级', 38);

INSERT INTO conference_participant
  (conference_id, country_id, role, delegation_level, delegation_size)
SELECT @conf, country_id, '观察员', '部长级', 20
FROM country WHERE iso_code = 'IDN';

INSERT INTO conference_topic (conference_id, topic_id, is_core, summary)
VALUES (@conf, @security, 1, '共同安全与多边合作'),
       (@conf, @ai, 1, '人工智能治理与技术合作');

INSERT INTO document (conference_id, title, doc_type, doc_no, issue_date, adopt_method)
VALUES (@conf, '课程演示联合声明', '联合声明', 'COURSE-DEMO', @demo_day, '协商一致');
SET @doc = LAST_INSERT_ID();
INSERT INTO document_sponsor (document_id, country_id, stance)
VALUES (@doc, @china, '联署'), (@doc, @kaz, '联署'), (@doc, @rus, '支持');

INSERT INTO follow_up_action
  (conference_id, document_id, action_name, lead_country_id,
   start_date, planned_end_date, progress_pct, status)
VALUES
  (@conf, @doc, '课程人工智能合作研究（虚构）', @china,
   DATE_SUB(@demo_day, INTERVAL 8 DAY), DATE_SUB(@demo_day, INTERVAL 1 DAY), 30, '进行中');
SET @act = LAST_INSERT_ID();

SELECT c.short_name AS 会议,
       (SELECT COUNT(*) FROM conference_participant p WHERE p.conference_id = c.conference_id) AS 参会国数,
       (SELECT COUNT(*) FROM conference_topic t WHERE t.conference_id = c.conference_id) AS 议题数,
       (SELECT COUNT(*) FROM document d WHERE d.conference_id = c.conference_id) AS 文件数
FROM conference c WHERE c.conference_id = @conf;
SELECT status AS 插入后状态, progress_pct AS 进度
FROM follow_up_action WHERE action_id = @act;
```

实际查询结果：

| 会议 | 参会国数 | 议题数 | 文件数 |
| --- | --- | --- | --- |
| 课件演示会议 | 4 | 2 | 1 |

| 插入后状态 | 进度 |
| --- | --- |
| 逾期 | 30 |

### S07 填写完成日期，触发状态、进度与审计联动

课件对应：14—15第12—14页。UPDATE只写入完成日期，不直接设置状态或100%进度。查询结果用来证明触发器确实执行了自动补全，并记录变更前后值。

```sql
UPDATE follow_up_action
SET actual_end_date = @demo_day
WHERE action_id = @act
  AND lead_country_id IN (SELECT country_id FROM country WHERE iso_code = 'CHN');
SELECT status AS 状态, progress_pct AS 进度, actual_end_date AS 完成日期
FROM follow_up_action WHERE action_id = @act;
SELECT action_type AS 操作, old_value AS 变更前, new_value AS 变更后
FROM operation_log WHERE target_table = 'follow_up_action' AND target_id = @act
ORDER BY log_id;
```

实际查询结果：

| 状态 | 进度 | 完成日期 |
| --- | --- | --- |
| 已完成 | 100 | 2026-10-27 |

| 操作 | 变更前 | 变更后 |
| --- | --- | --- |
| UPDATE | status=逾期, progress=30 | status=已完成, progress=100 |

### S08 删除观察员登记及演示行动

课件对应：14—15第10—11页。DELETE的条件使用IN子查询，限制在本次演示会议内；随后验证实际剩余数量。

```sql
DELETE FROM conference_participant
WHERE conference_id = @conf
  AND country_id IN (SELECT country_id FROM country WHERE iso_code = 'IDN');
DELETE FROM follow_up_action WHERE action_id = @act;
SELECT (SELECT COUNT(*) FROM conference_participant WHERE conference_id = @conf) AS 剩余参会国数,
       (SELECT COUNT(*) FROM follow_up_action WHERE action_id = @act) AS 剩余演示行动数;
```

实际查询结果：

| 剩余参会国数 | 剩余演示行动数 |
| --- | --- |
| 3 | 0 |

### S09 综合统计文件联署比例

课件对应：13第5—6页；06自定义函数为MySQL扩展。COUNT、条件SUM与自定义函数同时使用。3个国家有已记录立场，其中2个联署、1个支持，联署比例为2÷3×100%=66.67%。分母不是整场会议的全部参会国。

```sql
SELECT COUNT(*) AS 已记录立场国数,
       SUM(CASE WHEN stance = '联署' THEN 1 ELSE 0 END) AS 联署国数,
       fn_consensus_ratio(@doc) AS 联署比例百分比
FROM document_sponsor WHERE document_id = @doc;
```

实际查询结果：

| 已记录立场国数 | 联署国数 | 联署比例百分比 |
| --- | --- | --- |
| 3 | 2 | 66.67 |

### S10 回滚并核对真实数据

课件对应：事务为MySQL执行适配。ROLLBACK撤销本次演示会议、关联数据及触发器写入的日志。结果对应03原始数据；验证程序还逐项比对了5036个字段值。自增序列不回退，编号可能留空号。

```sql
ROLLBACK;
SELECT (SELECT COUNT(*) FROM conference) AS 会议数,
       (SELECT COUNT(*) FROM document) AS 文件数,
       (SELECT COUNT(*) FROM conference_participant) AS 参会记录数,
       (SELECT COUNT(*) FROM follow_up_action) AS 行动数,
       (SELECT COUNT(*) FROM operation_log) AS 审计记录数;
```

实际查询结果：

| 会议数 | 文件数 | 参会记录数 | 行动数 | 审计记录数 |
| --- | --- | --- | --- | --- |
| 50 | 56 | 304 | 38 | 0 |

### S11 复合主键拒绝重复参会登记

课件对应：10第28—29页。同一会议、同一国家重复插入，违反PRIMARY KEY(conference_id,country_id)。失败后该组合仍只有1条记录。

S11—S16使用09中的公共演示数据，在同一事务中执行：

```sql
-- S11—S16：约束与触发器的故意违反测试，共11条语句应报错。
-- 先执行01—04、06；本文件不加入run_all，避免预期错误中断正常建库。
-- Linux运行：sudo mysql --force --table < project/09_constraint_samples.sql
-- --force仅用于本文件，使预期失败后继续验证并执行ROLLBACK；也可逐条演示。
-- 全部演示数据都在同一事务内，结束后回滚。若手动中断，请在同一连接ROLLBACK。
USE `multilateral-diplomacy-system-schoolwork-`;

START TRANSACTION;
SET @check_day = CURDATE();
SET @check_china = (SELECT country_id FROM country WHERE iso_code = 'CHN');
SET @missing_country = (SELECT MAX(country_id) + 1 FROM country);
INSERT INTO conference (title, short_name, conference_type, start_date, end_date)
VALUES ('约束演示会议甲（虚构）', '约束演示甲', '专题会议', @check_day, @check_day);
SET @check_conf1 = LAST_INSERT_ID();
INSERT INTO conference (title, short_name, conference_type, start_date, end_date)
VALUES ('约束演示会议乙（虚构）', '约束演示乙', '专题会议', @check_day, @check_day);
SET @check_conf2 = LAST_INSERT_ID();
INSERT INTO conference_participant (conference_id, country_id, role)
VALUES (@check_conf1, @check_china, '主办国');
INSERT INTO document (conference_id, title, doc_type, doc_no, issue_date)
VALUES (@check_conf1, '约束演示文件', '联合声明', 'COURSE-CONSTRAINT', @check_day);
SET @check_doc = LAST_INSERT_ID();
INSERT INTO follow_up_action
  (conference_id, document_id, action_name, lead_country_id, start_date, planned_end_date, progress_pct, status)
VALUES
  (@check_conf1, @check_doc, '约束演示行动', @check_china, @check_day,
   DATE_ADD(@check_day, INTERVAL 10 DAY), 20, '进行中');
SET @check_action = LAST_INSERT_ID();
INSERT INTO app_user (username, real_name, user_role)
VALUES ('course_constraint_demo', '约束演示用户', '观察员');
SET @check_user = LAST_INSERT_ID();
```

```sql
INSERT INTO conference_participant (conference_id, country_id, role)
VALUES (@check_conf1, @check_china, '成员国');
SELECT COUNT(*) AS 该国参会记录仍为1
FROM conference_participant WHERE conference_id = @check_conf1 AND country_id = @check_china;
```

实际错误输出：

```text
ERROR 1062 (23000): Duplicate entry '53-1' for key 'conference_participant.PRIMARY'
```

实际查询结果：

| 该国参会记录仍为1 |
| --- |
| 1 |

### S12 唯一约束拒绝重复非空文号

课件对应：10基本表完整性约束。向另一场会议插入相同的非空doc_no，UNIQUE拒绝该语句。未知文号保留NULL，不使用虚构文号占位。

```sql
INSERT INTO document (conference_id, title, doc_type, doc_no, issue_date)
VALUES (@check_conf2, '重复文号演示', '联合声明', 'COURSE-CONSTRAINT', @check_day);
SELECT COUNT(*) AS 该文号记录仍为1 FROM document WHERE doc_no = 'COURSE-CONSTRAINT';
```

实际错误输出：

```text
ERROR 1062 (23000): Duplicate entry 'COURSE-CONSTRAINT' for key 'document.doc_no'
```

实际查询结果：

| 该文号记录仍为1 |
| --- |
| 1 |

### S13 外键拒绝不存在的国家与受引用父行删除

课件对应：10第28—29页。分别测试引用不存在的国家，以及删除已被参会记录引用的国家。两条失败语句都没有改变原有行。

```sql
INSERT INTO conference_participant (conference_id, country_id, role)
VALUES (@check_conf1, @missing_country, '成员国');
DELETE FROM country WHERE country_id = @check_china;
SELECT COUNT(*) AS 中国记录仍为1 FROM country WHERE country_id = @check_china;
SELECT COUNT(*) AS 不存在国家的参会记录为0
FROM conference_participant WHERE conference_id = @check_conf1 AND country_id = @missing_country;
```

实际错误输出：

```text
ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails (`multilateral-diplomacy-system-schoolwork-`.`conference_participant`, CONSTRAINT `conference_participant_ibfk_2` FOREIGN KEY (`country_id`) REFERENCES `country` (`country_id`) ON DELETE REST
ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key constraint fails (`multilateral-diplomacy-system-schoolwork-`.`conference`, CONSTRAINT `conference_ibfk_3` FOREIGN KEY (`host_country_id`) REFERENCES `country` (`country_id`) ON DELETE RESTRICT ON UPDATE CASC
```

实际查询结果：

| 中国记录仍为1 |
| --- |
| 1 |

| 不存在国家的参会记录为0 |
| --- |
| 0 |

### S14 CHECK拒绝非法值并验证NULL的含义

课件对应：10第28—29页；13第22页。依次测试进度150、计划日期早于启动日期、无完成日期却标记已完成。合法对照将未知进度与状态写为NULL；在期限明确已过时，预警仍显示1天，不把未知进度误填成0。

```sql
UPDATE follow_up_action SET progress_pct = 150 WHERE action_id = @check_action;
UPDATE follow_up_action SET planned_end_date = DATE_SUB(start_date, INTERVAL 1 DAY)
WHERE action_id = @check_action;
UPDATE follow_up_action SET status = '已完成' WHERE action_id = @check_action;
SELECT progress_pct AS 进度仍为20, status AS 状态仍为进行中, actual_end_date AS 完成日期仍为空
FROM follow_up_action WHERE action_id = @check_action;
-- 合法对照：NULL表示未知；已知期限已过但状态未知时，预警视图仍应显示该行动。
UPDATE follow_up_action
SET progress_pct = NULL, status = NULL,
    start_date = DATE_SUB(@check_day, INTERVAL 2 DAY),
    planned_end_date = DATE_SUB(@check_day, INTERVAL 1 DAY)
WHERE action_id = @check_action;
SELECT a.progress_pct AS 未知进度, a.status AS 未知状态, v.overdue_days AS 逾期天数
FROM follow_up_action a LEFT JOIN v_action_alert v ON v.action_id = a.action_id
WHERE a.action_id = @check_action;
```

实际错误输出：

```text
ERROR 3819 (HY000): Check constraint 'follow_up_action_chk_1' is violated.
ERROR 3819 (HY000): Check constraint 'follow_up_action_chk_2' is violated.
ERROR 3819 (HY000): Check constraint 'follow_up_action_chk_4' is violated.
```

实际查询结果：

| 进度仍为20 | 状态仍为进行中 | 完成日期仍为空 |
| --- | --- | --- |
| 20 | 进行中 | NULL |

| 未知进度 | 未知状态 | 逾期天数 |
| --- | --- | --- |
| NULL | NULL | 1 |

### S15 触发器拒绝行动与文件来源会议不一致

课件对应：MySQL触发器扩展；复用课件EXISTS结构。分别尝试插入来源不一致的行动、修改已有行动的会议、修改已有文件的会议。三条路径均由相应触发器拒绝，最终会议关系仍一致。

```sql
INSERT INTO follow_up_action (conference_id, document_id, action_name)
VALUES (@check_conf2, @check_doc, '来源不一致的演示行动');
UPDATE follow_up_action SET conference_id = @check_conf2 WHERE action_id = @check_action;
UPDATE document SET conference_id = @check_conf2 WHERE document_id = @check_doc;
SELECT a.conference_id = d.conference_id AS 行动文件会议仍一致
FROM follow_up_action a JOIN document d ON d.document_id = a.document_id
WHERE a.action_id = @check_action;
```

实际错误输出：

```text
ERROR 1644 (45000): action document/conference mismatch
ERROR 1644 (45000): action document/conference mismatch
ERROR 1644 (45000): action document/conference mismatch
```

实际查询结果：

| 行动文件会议仍一致 |
| --- |
| 1 |

### S16 可更新视图的合法修改与CHECK OPTION拒绝

课件对应：14—15第26—27页。先创建事务内演示用户，保证合法UPDATE实际修改到一行；再把is_active改成0，违反视图WHERE is_active=1，基表仍保持启用。最后回滚全部约束演示。

```sql
UPDATE v_active_user SET real_name = '约束演示用户（已修改）' WHERE user_id = @check_user;
SELECT real_name AS 修改后姓名, is_active AS 启用状态 FROM app_user WHERE user_id = @check_user;
UPDATE v_active_user SET is_active = 0 WHERE user_id = @check_user;
SELECT is_active AS 启用状态仍为1 FROM app_user WHERE user_id = @check_user;

ROLLBACK;
SELECT (SELECT COUNT(*) FROM conference) AS 回滚后会议数,
       (SELECT COUNT(*) FROM follow_up_action) AS 回滚后行动数,
       (SELECT COUNT(*) FROM app_user) AS 回滚后用户数,
       (SELECT COUNT(*) FROM operation_log) AS 回滚后日志数;
```

实际错误输出：

```text
ERROR 1369 (HY000): CHECK OPTION failed 'multilateral-diplomacy-system-schoolwork-.v_active_user'
```

实际查询结果：

| 修改后姓名 | 启用状态 |
| --- | --- |
| 约束演示用户（已修改） | 1 |

| 启用状态仍为1 |
| --- |
| 1 |

| 回滚后会议数 | 回滚后行动数 | 回滚后用户数 | 回滚后日志数 |
| --- | --- | --- | --- |
| 50 | 38 | 0 | 0 |

## 本次调整与核对

- 保留05的14条核心查询，选取其中2、3、12及08的自身连接、IN查询形成5个正式查询样例；没有再建立一套重复查询脚本。
- 07按运行日生成相对日期，避免固定日期使逾期触发器演示随时间失效；议题按名称查找，修正原先9号议题与人工智能说明不一致的问题。
- 07的完成演示只更新完成日期，由触发器生成已完成状态和100%进度，审计结果可直接观察。
- 08的ANY/ALL改用已登记参会国数的COUNT，参照课件聚合＋HAVING的结构；视图更新先插入事务内用户，避免空用户表导致修改0行。
- 04的预警条件显式接纳NULL状态；精确期限未知时仍不推定逾期。05查询4改称尚未关联行动，避免把未建立关联误说成没有任何后续行动。
- 09集中展示11次预期拒绝：1062两次、1452一次、1451一次、3819三次、1644三次、1369一次。每类错误后均查询原行，验证拒绝确实生效。

## 实际执行记录

- [07的SQL及表格输出](sample-results/07_运行记录.txt)
- [09的SQL、表格及完整错误输出](sample-results/09_运行记录.txt)
- [05全部14条查询的XML结果](sample-results/05_queries.xml)
- [08全部9项示例的XML结果](sample-results/08_course_examples.xml)

MySQL适配说明：演示主体使用课件中的SELECT、连接、IN、EXISTS、聚合、GROUP BY/HAVING及INSERT/UPDATE/DELETE。用户变量、LAST_INSERT_ID、日期函数、事务执行和触发器属于本项目的MySQL实现，不将它们表述为全部逐字来自课件。
