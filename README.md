# 多边外交会议与活动管理数据库

《数据库原理》课程项目，使用 MySQL SQL 脚本管理会议、参会国家、议题、成果文件与后续行动。

- 12 张表、6 个视图、14 条核心查询。
- 包含50场真实会议的录入脚本，其中2026年10场；来源与执行方法见[数据录入说明](project/DATA_IMPORT.md)。
- 建表采用课件中的基本类型、主外键、UNIQUE 与 CHECK；三个多对多关系统一使用复合主键。
- 基础示例采用课件中的连接、聚合、嵌套查询、数据更新和视图语法。
- 触发器、存储过程与函数保留在 `06_routines.sql`，作为扩展功能。
- [16个样例及实际运行结果](project/SAMPLES.md)：含5个复杂查询与11条预期违规拒绝。

## 运行

需要 MySQL 8.0.16 及以上版本（CHECK 约束需要实际生效）。此前版本已在 **MySQL 9.4.0（Windows 服务 MySQL94）** 上完整跑通过；本次建库建表调整在 MySQL 8.4.11 独立实例验证通过。

```powershell
# Windows：mysql.exe 所在目录已加入 PATH
.\project\run_all.cmd
# 也可指定客户端位置
.\project\run_all.ps1 -MySqlPath "C:\path\to\mysql.exe"
```

```bash
# Linux / macOS：在项目根目录执行，不依赖脚本的执行权限或 Bash
sh project/run_all.sh -u root -p
# Ubuntu 等系统：仅当 root 使用系统身份认证（报1698）时
sudo sh project/run_all.sh -u root
```

脚本按自身位置查找SQL，支持中文、空格路径，也可从其他目录通过完整路径运行。客户端从PATH查找；自定义位置可用`MYSQL_BIN="/完整路径/mysql" sh project/run_all.sh -u root -p`。TCP连接可追加`-h 127.0.0.1 -P 3306`，本地socket可追加`--socket=/路径/mysql.sock`。只建立一次连接，遇到SQL错误立即停止，并返回失败状态。

Navicat 中依次运行 `01 → 02 → 03 → 04 → 06 → 05 → 07 → 08 → 99`。
**01会删除同名数据库，02会重建表，运行前请备份。03用于新版空表首次录入，不清理已有数据。**

数据库名为 `` `multilateral-diplomacy-system-schoolwork-` ``，包含连字符，SQL 中需要反引号。

[项目设计与运行说明](project/README.md) · [课件对应与本次修改](project/COURSE_ALIGNMENT.md) · [Web 界面](project/web/README.md)（`node project/web/server.js` → <http://127.0.0.1:8765>）

Linux/macOS也可运行`sh project/web/start.sh`启动网页；Windows使用`project/web/启动.cmd`。网页需要Node.js 18+，账号、密码及连接位置见[配置说明](project/web/README.md#配置)。脚本不自动安装数据库，各电脑须先安装MySQL并准备可登录的账号。

[project/backup/](project/backup/)保留旧版示例快照。本次50场真实资料以新版01—03脚本重建；07中的虚构数据仅在事务中演示并回滚。
