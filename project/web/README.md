# Web 界面（轻量数据管理前端）

给「多边外交视角下国际会议与外交活动管理系统」加的一层简易界面：只读查询 + 少量录入/修改，用来在答辩或演示时把数据库里的数据“看起来”。

## 启动

```powershell
# 方式一：双击
启动.cmd

# 方式二：命令行
node server.js
```

浏览器打开 <http://127.0.0.1:8765>。

要求：本机有 Node.js 18+ 和 MySQL 客户端（默认 `C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe`），数据库已按 `01→02→03` 建好。

## 配置

改 `server.js` 顶部或设环境变量：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `PORT` | `8765` | 监听端口（只绑 127.0.0.1） |
| `MYSQL_BIN` | `C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe` | mysql 客户端路径 |
| `DB_NAME` | `multilateral-diplomacy-system-schoolwork-` | 库名 |
| `MYSQL_PWD` | 读 `C:\Users\nbd99\.dsh-backups\db\mysql-root.txt` | 数据库密码 |
| `MYSQL_CRED` | 上面的凭据文件 | 改密码时就改这个文件 |

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

- **零依赖**：不引 express / mysql-js，直接 `spawn` 系统里的 `mysql.exe`，用 `JSON_OBJECT` / `JSON_ARRAYAGG` 把结果整段取回再 `JSON.parse`。换台机器只要有 node + mysql 就能跑，不受 npm 源影响。
- **只读为主**：写操作只有「新增会议 / 参会登记 / 改进度」三个；**没有做删除**——本库 `conference` 的子表（参会、议题、文件、行动）都是 `ON DELETE CASCADE`，删一场会会连带删掉几十条记录，演示约束用「故意写非法值」更安全（失败即证明约束生效，数据不动）。
- **联表统计**：会议参会/议题/文件/行动数量都用相关子查询实时算，不缓存，避免和明细对不上。
- **SQL 安全**：所有用户输入走转义函数，数字字段强制 `Number.isInteger` 校验，枚举状态白名单；库名、接口路径都是写死的。
- **没做登录鉴权**：`app_user` 当前为空（数据录入说明里写明不编造历史账号），课程也没要求权限系统，所以界面不做登录；若要加，把 `app_user` 灌上数据后在这里补一个会话即可。
- **NULL 的处理**：新数据集里行动的日期/状态/进度大多为 NULL（未知）。界面把“风险”按日期现算，不用 `status` 字段，所以即使 `status` 为 NULL 也能看出哪些已逾期——这也是当前 `v_action_alert` 返回 0 行的原因（`status <> '终止'` 在 NULL 下为 UNKNOWN），修视图时可以对照这里。

## 自测

```powershell
node webtest.js      # 32 项回归：接口、筛选、404、约束拦截、静态资源、路径穿越
```

注意：`webtest.js` 会把 1 号行动的进度改成 45 并产生审计记录（这是它在验证写接口）。跑完想恢复干净数据，重新执行一次 `project/run_all.ps1` 即可（3 秒）。

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
