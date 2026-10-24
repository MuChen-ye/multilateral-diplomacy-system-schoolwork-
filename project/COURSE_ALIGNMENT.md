# 课件对应与修改说明

按课程课件（3.2 数据定义、3.3 数据查询、3.4 数据更新、3.5 视图）核对，不复制课件中的作业指令。保留 12 表业务结构，主要示例使用基础 SQL。

| 课件（页码为幻灯片序号） | 项目对应 |
|---|---|
| 10《SQL简介和数据定义》23、27–34 页 | 01–02：建库、基本类型、主键/外键/唯一/CHECK；普通索引使用独立 CREATE INDEX |
| 11–12《SQL的数据查询1》12–15 页 | 08 示例 2：等值连接、自身连接 |
| 同上 17–30 页 | 05 查询 4/12，08 示例 3–6：IN、NOT IN、ANY、ALL、EXISTS 与关系除法 |
| 13《SQL的数据查询2》5–10、15–24 页 | 05：聚合、GROUP BY、HAVING、排序；08：UNION、BETWEEN、LIKE、NULL |
| 14–15《SQL的数据更新和视图》6–14 页 | 07：VALUES、INSERT … SELECT、带子查询的 UPDATE/DELETE |
| 同上 18–29 页 | 04：多表、分组、表达式、基于视图和可更新视图；08 示例 9 验证视图更新 |
| 16–17《设计问题和函数依赖》、18《分解特性》、19–20《范式》 | README 3.4：候选键、部分/传递依赖、无损分解及现存冗余 |

## 建库建表的本次调整

- 01 使用 CREATE DATABASE 和统一的 utf8mb4 字符集；不套用 MySQL 不支持的 AUTHORIZATION 子句。
- 02 按“字段在前、表级约束在后”的课件格式书写。ENUM 改为 VARCHAR + CHECK，布尔标记与年份改为 SMALLINT；年份可空，已知值为 1—9999。
- 三张多对多关联表统一使用复合主键。参会表移除 participant_id 及重复的联合 UNIQUE；查询 2 同步改为分别计数，保持参会国次的统计含义。
- 12 张表、18 个外键及原有级联策略保留；增加取值约束后为 29 个 CHECK、8 个 UNIQUE。建表前按依赖逆序删除，无需关闭外键检查。
- 8 个普通查询索引按课件使用 CREATE INDEX；外键所需索引交给 InnoDB 自动建立。
- 06 增加文件更新前的一致性检查，补齐“单独修改文件所属会议”留下的漏洞。
- 项目数据字典、关系模型、完整备份及约束演示同步更新。

## 精简与修复

- 04 的 6 个视图统一使用 CREATE OR REPLACE，修复遗漏 v_operation_audit 导致重跑失败。
- 修正“10 张表 / 12 条查询 / v_consensus_report”等注释，以及示例数据的分类数量。
- 05 保留 14 条核心查询，主办数量用分组排序，全参与查询用双重 NOT EXISTS，去掉窗口函数、GROUP_CONCAT 和 LIMIT。
- 中国文件联署统计只计 stance = '联署'，不再把“支持”算作联署。
- 07 补充 INSERT … SELECT 与带子查询的更新/删除，08 补齐基础查询及视图更新演示。
- Windows 入口自动寻找 mysql.exe，并保留手动指定路径；临时文件及临时密码在退出时清理。新增 Linux/macOS 入口。
- 保留触发器与例程作为扩展。两个行动触发器额外拒绝行动插入/更新时文件和会议不匹配的写入。

## SQL 方言说明

课件采用通用 SQL。项目保留必要的 MySQL AUTO_INCREMENT、InnoDB、DATETIME、日期函数及 DELIMITER；建表已不使用 ENUM、YEAR、TINYINT 和 KEY 子句；CREATE OR REPLACE VIEW 用于可重复执行。未照搬 MySQL 不支持的 CREATE DOMAIN、CREATE SCHEMA … AUTHORIZATION、UPDATE … SET ROW 等写法。

WITH CHECK OPTION 检查更新后的行是否满足视图条件，不会自动补齐 WHERE 中的字段值。聚合报表用于查询；修改姓名的演示使用单表视图。

## 验证

验证结果见项目 README 5.4：本次调整在 MySQL 8.4.11 独立实例通过 63 项检查；保留此前版本的 Windows + MySQL 9.4.0 实测记录。逾期天数和审计数量随执行日期变化，以实际查询为准。
