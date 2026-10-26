# 多边外交会议与活动管理数据库

《数据库原理》课程项目，使用 MySQL SQL 脚本管理会议、参会国家、议题、成果文件与后续行动。

- 12 张表、6 个视图、14 条核心查询。
- 包含50场真实会议的录入脚本，其中2026年10场；来源与执行方法见[数据录入说明](project/DATA_IMPORT.md)。
- 建表采用课件中的基本类型、主外键、UNIQUE 与 CHECK；三个多对多关系统一使用复合主键。
- 基础示例采用课件中的连接、聚合、嵌套查询、数据更新和视图语法。
- 触发器、存储过程与函数保留在 `06_routines.sql`，作为扩展功能。

## 运行

需要 MySQL 8.0.16 及以上版本（CHECK 约束需要实际生效）。此前版本已在 **MySQL 9.4.0（Windows 服务 MySQL94）** 上完整跑通过；本次建库建表调整在 MySQL 8.4.11 独立实例验证通过。

```powershell
# Windows：mysql.exe 所在目录已加入 PATH
.\project\run_all.cmd
# 也可指定客户端位置
.\project\run_all.ps1 -MySqlPath "C:\path\to\mysql.exe"
```

```bash
# Linux / macOS
./project/run_all.sh -u root -p
```

Navicat 中依次运行 `01 → 02 → 03 → 04 → 06 → 05 → 07 → 08 → 99`。
**01会删除同名数据库，02会重建表，运行前请备份。03用于新版空表首次录入，不清理已有数据。**

数据库名为 `` `multilateral-diplomacy-system-schoolwork-` ``，包含连字符，SQL 中需要反引号。

[项目设计与运行说明](project/README.md) · [课件对应与本次修改](project/COURSE_ALIGNMENT.md)

[project/backup/](project/backup/)保留旧版示例快照。本次50场真实资料以新版01—03脚本重建；07中的虚构数据仅在事务中演示并回滚。
