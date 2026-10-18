# multilateral-diplomacy-system-schoolwork-

面向多边外交活动管理，管理“国际会议—参与国家—议题—成果文件—后续行动”全要素数据，支撑外交活动的组织协调与成果跟踪。

《数据库原理》三级项目 · 选题 3（多边外交 / 全球治理，★★★ 系数 1.0）· 纯 SQL 实现，无前后端依赖

---

## 仓库结构

| 目录 | 内容 | 说明 |
|---|---|---|
| [`lab1/`](lab1/README.md) | 实验一 数据定义与插入 | `library_db071`：建库、5 表、数据、表结构修改、备份还原；按 2026 指导书逐条对表，另附只读自检 `99_verify.sql` 与 7 条约束反证 `98_constraint_tests.sql` |
| [`project/`](project/README.md) | 三级项目：多边外交数据库 | 选题 3 完整实现：12 表、5 视图、3 触发器、存储过程、14 条核心查询，报告按六章结构成文 |

每个目录都自带 `README.md`（设计与实测记录）、编号 SQL 脚本，以及一键构建脚本 `run_all.cmd`。

## 快速开始

```powershell
# 方式一：双击一键构建（会提示输入 MySQL 密码）
cd project
.\run_all.cmd        # 依次执行 01→02→03→04→06→05→07→99

cd ..\lab1
.\run_all.cmd            # 实验一同样一键跑通（步骤 1~4 + 自检 + 约束反证）
.\05_backup_restore.cmd  # 实验一步骤 5：备份 → 还原 → 逐表比对
```

```text
方式二：Navicat
1. 左侧连接 MySQL94 → 右键「刷新」
2. 右键库 →「运行 SQL 文件」，按目录内 README 给出的顺序执行
```

> ⚠️ `project/01_create_database.sql` 开头是 `DROP DATABASE IF EXISTS`，`03_insert_data.sql` 会 TRUNCATE 所有表——重跑等于重建。演示前若改过数据，先备份。

## 数据库设计摘要

库名：`` `multilateral-diplomacy-system-schoolwork-` ``（与仓库同名，含连字符，SQL 中必须加反引号）

主题链：**国际会议 → 参与国家 → 议题 → 成果文件 → 后续行动**

| 表 | 行数 | 关键约束 |
|---|---|---|
| `country` | 18 | 主键；`iso_code`、`name_cn` 唯一 |
| `international_organization` | 6 | 名称与简称唯一 |
| `mechanism` | 6 | 外键 → 组织 |
| `topic` | 10 | 议题名称唯一 |
| `conference` | 9 | 3 外键；CHECK `end_date >= start_date` |
| `conference_participant` | 66 | (会议,国家) 唯一；CHECK 人数 ≥ 0 |
| `conference_topic` | 27 | 复合主键 + 2 外键 |
| `document` | 11 | `doc_no` 唯一；CHECK 编号非空串 |
| `document_sponsor` | 76 | 复合主键 + 2 外键 |
| `follow_up_action` | 16 | 4 外键 + **4 CHECK**（进度 0–100、日期合法、完成必须有完成日期） |
| `app_user` | 10 | 账号唯一；角色枚举；2 外键（国家/组织） |
| `operation_log` | 4 | 审计日志，由触发器自动写入；外键 → 用户 |

合计 **18 个外键、7 个 CHECK、9 个 UNIQUE**，全部在库内生效；12 个关系模式均满足 **3NF/BCNF**（不冗余统计字段，聚合全部交给视图）。

## 数据库对象

| 类型 | 数量 | 清单 |
|---|---|---|
| 视图 | 5 | `v_conference_overview`、`v_document_consensus`、`v_action_alert`、`v_china_multilateral`、`v_operation_audit` |
| 触发器 | 3 | `trg_action_before_insert`、`trg_action_before_update`（逾期自动判定）、`trg_action_audit`（变更留痕） |
| 存储过程 | 1 | `sp_conference_dashboard(会议ID)` —— 一次输出 5 个结果集 |
| 函数 | 1 | `fn_consensus_ratio(文件ID)` —— 成果文件联署率 |

## 核心查询（14 条，均在 MySQL 9.4 实测跑通）

| # | 查询 | 技术点 |
|---|---|---|
| 1 | 会议全景 | 4 表连接 + 视图 |
| 2 | 机制维度统计 | 多重 `COUNT(DISTINCT)` |
| 3 | 参与国 ≥ 8 的会议 | `GROUP BY` + `HAVING` |
| 4 | 无后续行动的成果文件 | `NOT EXISTS` 相关子查询 |
| 5 | 各国主办会议数排名 | 窗口函数 `DENSE_RANK` |
| 6 | 后续行动逾期预警 | 视图 + `DATEDIFF` |
| 7 | 成果文件共识广度 | 条件聚合 + `LIMIT` |
| 8 | 议题热度 | 按领域分组 + 条件求和 |
| 9 | 中国多边参与全景 | 视图（思政报表） |
| 10 | 行动状态分布 | 分组 + 条件计数 |
| 11 | 年度会议统计 | `YEAR()` 分组 |
| 12 | 全链条汇总 | `GROUP_CONCAT` + 条件聚合 |
| 13 | 用户角色与国别分布 | 分组 + 条件求和 |
| 14 | 操作审计日志 | 视图 + 时间倒序 |

## 环境与实测

| 项 | 值 |
|---|---|
| 数据库 | MySQL Server 9.4.0（Windows 服务 `MySQL94`，端口 3306） |
| 客户端 | Navicat Premium 17.3.11 / `mysql.exe` |
| 字符集 | `utf8mb4` / `utf8mb4_0900_ai_ci` |
| 约束实测 | 4 条非法写入全部被拒：`ERROR 1452` 外键 · `3819` CHECK · `1062` 唯一键 · `1265` 非法枚举 |
| 触发器实测 | 16 项行动中 4 项被按当前日期自动改判「逾期」 |

## 数据来源与声明

示例数据依据外交部官网、国际组织公开发布的议程与会议成果**整理**，用于课程演示，**非官方发布文本**。仓库内仅包含自建 SQL 脚本与文档，不包含任何第三方软件安装包或课程发放材料。

---

**评分点对照、E-R 图、3NF 论证与答辩演示清单见 [`project/README.md`](project/README.md)。**
