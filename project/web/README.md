# Web 界面（轻量数据管理前端）

给「多边外交视角下国际会议与外交活动管理系统」加的一层简易界面：只读查询 + 少量录入/修改，用来在答辩或演示时把数据库里的数据“看起来”。

## 启动

```powershell
# 方式一：双击
启动.cmd

# 方式二：在项目根目录启动
node project/web/server.js
```

Linux/macOS在项目根目录执行（也可用脚本完整路径从其他目录启动）：

```bash
sh project/web/start.sh
```

浏览器打开 <http://127.0.0.1:8765>。

要求：本机有Node.js 18+和MySQL客户端，数据库服务为MySQL 8.0.16+，已按`01→02→03→04→06`建好。各系统均从PATH查找客户端，可通过MYSQL_BIN指定完整路径；sh入口也支持NODE_BIN。该入口检查依赖后直接启动网页，不重建数据库。

## Linux：root报1698时

如果`mysql -u root -p`返回1698，而`sudo mysql`能登录，通常是root使用auth_socket系统身份认证。管理数据库使用sudo；网页使用项目专用账号。

在项目根目录执行（会删除并重建项目同名数据库，已导入的数据需要先备份；已完成初始化则跳过）：

```bash
sudo sh project/run_all.sh -u root
```

这里输入Linux用户的sudo密码，不加`-p`。首次为网页创建账号，在本机终端进入MySQL：

```bash
sudo mysql
```

先在普通终端用`id -un`查看本机Linux用户名，再将以下SQL的`你的Linux用户名`替换为该结果：

```sql
CREATE USER 'diplomacy_web'@'localhost' IDENTIFIED WITH auth_socket AS '你的Linux用户名';
GRANT SELECT, INSERT, UPDATE, EXECUTE
ON `multilateral-diplomacy-system-schoolwork-`.*
TO 'diplomacy_web'@'localhost';
EXIT;
```

然后用普通终端启动，每次启动只需这一行：

```bash
MYSQL_USER=diplomacy_web MYSQL_PWD= sh project/web/start.sh
```

打开<http://127.0.0.1:8765>。这里通过本地socket匹配Linux用户，无需数据库密码。若使用已有的密码账号，同样可通过MYSQL_USER和MYSQL_PWD配置。

普通账号可能看不到触发器元数据，此时侧栏省略该数量；审计触发器仍按数据库定义运行。

认证与系统用户名映射见[MySQL auth_socket说明](https://dev.mysql.com/doc/refman/8.4/en/socket-pluggable-authentication.html)。此账号仅授权项目库的查询、录入、修改及例程执行，不授予建库或删库权限。

## 配置

改 `server.js` 顶部或设环境变量：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `PORT` | `8765` | 监听端口（只绑 127.0.0.1） |
| `MYSQL_BIN` | Linux/macOS为`mysql`，Windows为`mysql.exe` | 从PATH查找，也可指定完整路径 |
| `MYSQL_USER` | `root` | 数据库账号，可使用项目专用账号 |
| `MYSQL_HOST` | 客户端默认值 | 数据库主机，TCP连接可填`127.0.0.1` |
| `MYSQL_PORT` | 客户端默认值 | TCP端口，通常为`3306` |
| `MYSQL_SOCKET` | 客户端默认值 | Linux/macOS的本地socket路径 |
| `DB_NAME` | `multilateral-diplomacy-system-schoolwork-` | 库名 |
| `MYSQL_PWD` | 未设置时读取凭据文件 | 密码；显式设为空表示不用密码 |
| `MYSQL_CRED` | 当前用户主目录下的`.dsh-backups/db/mysql-root.txt` | 可选凭据文件，每行使用`password=...` |

密码账号可在普通终端读取密码后启动，密码不会写进命令历史（账号请换成已有账号）：

```bash
printf 'MySQL password: '
read -r -s MYSQL_PWD
printf '\n'
export MYSQL_PWD
MYSQL_USER=diplomacy_web MYSQL_HOST=127.0.0.1 MYSQL_PORT=3306 sh project/web/start.sh
unset MYSQL_PWD
```

这里的`read -s`用于Linux常见的Bash和macOS的zsh终端；无需为启动网页运行sudo。Windows可在PowerShell设置对应环境变量后运行`node project/web/server.js`。

## 功能

| 页面 | 内容 |
|---|---|
| 概览 | 6 个规模指标、会议类型分布、行动风险分布、最近会议 |
| 会议 | 按机制/年份/关键词筛选；点一行看详情（基本信息 + 参会国家 + 议题 + 成果文件 + 后续行动） |
| 成果文件 | 文件列表 + 联署/支持/保留人数 + 联署率（取数据库函数 `fn_consensus_ratio` 的口径）；点一行看逐国表态 |
| 后续行动 | 按风险筛选；风险列按日期实时推算（已完成/已逾期/无计划日期/进行中）；点一行可改进度、状态、实际完成日期 |
| 中国参与 | `v_china_multilateral` 的表格 + 参与场次、平均代表团人数等汇总 |
| 审计日志 | `operation_log` + `v_operation_audit`；改行动状态/进度后这里会出现记录 |
| 数据维护 | 新增会议、参会登记，以及两个「故意做错」的约束演示（非法进度、重复参会） |

## 技术取舍

- **零依赖**：不引 express / mysql-js，直接 `spawn` 系统里的MySQL客户端，用 `JSON_OBJECT` / `JSON_ARRAYAGG` 把结果整段取回再 `JSON.parse`。换台机器只要有 node + mysql 就能跑，不受 npm 源影响。
- **只读为主**：写操作只有「新增会议 / 参会登记 / 改进度」三个；**没有做删除**——本库 `conference` 的子表（参会、议题、文件、行动）都是 `ON DELETE CASCADE`，删一场会会连带删掉几十条记录，演示约束用「故意写非法值」更安全（失败即证明约束生效，数据不动）。
- **联表统计**：会议参会/议题/文件/行动数量都用相关子查询实时算，不缓存，避免和明细对不上。
- **SQL 安全**：所有用户输入走转义函数，数字字段强制 `Number.isInteger` 校验，枚举状态白名单；库名、接口路径都是写死的。
- **没做登录鉴权**：`app_user` 当前为空（数据录入说明里写明不编造历史账号），课程也没要求权限系统，所以界面不做登录；若要加，把 `app_user` 灌上数据后在这里补一个会话即可。
- **NULL 的处理**：新数据集里行动的日期/状态/进度大多为 NULL（未知）。界面把“风险”按日期现算，不用 `status` 字段，所以即使 `status` 为 NULL 也能看出哪些已逾期——预警视图允许状态为NULL；当前真实资料的精确计划日期仍为NULL，因此无逾期预警记录，演示效果见07和09。

## 自测

```powershell
node webtest.js      # 32 项回归：接口、筛选、404、约束拦截、静态资源、路径穿越
```

注意：`webtest.js`会把1号行动的进度改成45并产生审计记录。若要恢复初始资料，应先备份，再使用对应系统的run_all入口重建项目库。

## 接口一览

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/health` | 版本、表/视图/触发器/例程数 |
| GET | `/api/meta` | 机制、国家、会议类型、年份 |
| GET | `/api/overview` | 概览统计 |
| GET | `/api/conferences?q&mechanism&year` | 会议列表 |
| GET | `/api/conferences/:id` | 会议详情（含参会/议题/文件/行动） |
| POST | `/api/conferences` | 新增会议 |
| GET | `/api/documents?q` | 文件列表 |
| GET | `/api/documents/:id` | 文件详情（逐国表态） |
| GET | `/api/actions?q&risk` | 行动列表 |
| PUT | `/api/actions/:id` | 改进度/状态/完成日期 |
| POST | `/api/participants` | 参会登记 |
| GET | `/api/china` | 中国参与视图 |
| GET | `/api/audit` | 审计日志 |
