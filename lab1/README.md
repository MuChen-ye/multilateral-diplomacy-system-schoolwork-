# 实验一 数据定义与插入 —— 实施记录

> 数据库：`library_db071`（`library_db` + 学号后 3 位，071 = 202511040071）
> 环境：MySQL Server 9.4.0（Windows 服务 `MySQL94`，端口 3306），Navicat Premium 17.3.11 客户端
> 字符集：`utf8mb4`（中文与 emoji 都不会乱码）
> 依据：`2026年 DB实验指导书-实验1-A4版-.doc`

## 一、指导书要求 → 实现位置对照

| 指导书步骤 | 原文要求 | 实现文件 | 本机实测 |
|---|---|---|---|
| 1 | 创建 `library_db学号后3位` 数据库 | [`01_create_database.sql`](01_create_database.sql) | `library_db071`，`utf8mb4_0900_ai_ci` |
| 2 | 建 5 张表 + 表间联系；定义合适的数据类型、长度；必要的列级/表级约束 | [`02_create_tables.sql`](02_create_tables.sql) | 5 表、18 个约束（5 主键 / 4 唯一 / 4 外键 / 5 CHECK）、13 个索引 |
| 3 | 使用 SQL 录入 5 张表的数据 | [`03_insert_data.sql`](03_insert_data.sql) | 10 / 6 / 6 / 10 / 10 行，数据与指导书表 1~表 5 逐字一致 |
| 4(1) | `book_categories` 增加 `floor` 列（楼层，允许为空） | [`04_alter_tables.sql`](04_alter_tables.sql) | `ADD COLUMN floor INT NULL` 成功 |
| 4(2) | `readers.phone` 数据长度改为 11 | 同上 | 实测 `varchar(11)`，10 条手机号均为 11 位未截断 |
| 4(3) | 删除 `book_categories` 的 `floor` 列 | 同上 | 删列成功，`information_schema` 中 `floor` 计数为 0 |
| 5 | 用两种方式备份并还原 | [`05_backup_restore.ps1`](05_backup_restore.ps1) + Navicat 手工（见第五节） | 方式一脚本化并通过；还原库逐表行数与内容摘要一致 |

## 二、文件清单与执行顺序

| 顺序 | 文件 | 作用 |
|---|---|---|
| 1 | `01_create_database.sql` | 步骤 1 建库 |
| 2 | `02_create_tables.sql` | 步骤 2 建 5 张表、外键、CHECK、唯一键 |
| 3 | `03_insert_data.sql` | 步骤 3 录入数据（可重复执行：先按外键逆序 TRUNCATE） |
| 4 | `04_alter_tables.sql` | 步骤 4 表结构修改三步（加列 → 改列长 → 删列） |
| 5 | `98_constraint_tests.sql` | **约束反证**：故意写 7 条非法数据，逐条报错（必须 `-f` 强制继续） |
| 6 | `99_verify.sql` | **只读自检**：库/表/字段/约束/外键/索引/行数/数据/修改结果，8 节输出，正好当报告截图素材 |
| 7 | `05_backup_restore.ps1` | 步骤 5 方式一：mysqldump 备份 → 还原 → 逐表比对行数与内容摘要 |
| 8 | `backup/library_db071_full.sql` | 上面脚本产生的备份文件（mysqldump 全量，10,240 字节） |
| — | `run_all.cmd` | **双击即可**一键跑 1~6（推荐），跑完自检并暂停看结果 |
| — | `05_backup_restore.cmd` | **双击即可**单独做步骤 5 |
| — | `run_all.ps1` | 上面 .cmd 实际调用的脚本；加 `-Backup` 可连步骤 5 一起跑 |

一键执行（推荐）：

```powershell
cd lab1
.\run_all.cmd            # 步骤 1~4 + 自检 + 约束反证
.\05_backup_restore.cmd  # 步骤 5 备份与还原

# 或者命令行一次跑完（含备份还原）
$env:MYSQL_PWD = "<root 密码>"; .\run_all.ps1 -Backup
```

命令行逐条执行方式（在 `lab1` 目录下）：

```powershell
$mysql = "C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe"
cmd /c "`"$mysql`" -u root -p --default-character-set=utf8mb4 < 01_create_database.sql"
# 02 / 03 / 04 / 99_verify 同理；98 需要加 -f（强制继续）
```

> 注意：Windows 默认执行策略会拦截未签名的 `.ps1`，直接双击 `.ps1` 会报
> `未对文件 run_all.ps1 进行数字签名`。所以给了一个 `.cmd` 外壳，它用
> `-ExecutionPolicy Bypass` 只为这一次运行放行，不改你系统的全局策略。

## 三、建表设计说明（对应指导书「定义必要的列级约束和表级约束」）

- **列级约束**：`NOT NULL`（`name`/`card_no`/`gender`/`phone`/`isbn`/`title`/`publisher_id`/`category_id`/`borrow_date`/`due_date`）、`AUTO_INCREMENT` 主键、`DEFAULT '借阅中'`、`CHECK`（`gender IN ('男','女')`、`max_borrow >= 0`、`price >= 0`、`available <= total_copies`、`due_date >= borrow_date`）。
- **表级约束**：`PRIMARY KEY`、`UNIQUE`（`card_no` 借书证号、`isbn`、出版社名称、分类名称）、`FOREIGN KEY`。
- **外键策略**：`ON UPDATE CASCADE ON DELETE RESTRICT` —— 主表主键变动时联动，但禁止删掉仍被图书/借阅记录引用的出版社、分类、读者和图书。
- **类型选择**：`gender CHAR(1)`（单字性别）；`reader_type` / `status` 用 `ENUM` 限值（`学生/教师/职工`、`借阅中/已归还/逾期`）；`price DECIMAL(8,2)` 避免浮点误差；`founded_year YEAR` 专存年份。

表间联系（指导书「建表和建立表间联系」要求）：

```
publishers 1 ──── n books n ──── 1 book_categories
readers    1 ──── n borrow_records n ──── 1 books
```

## 四、执行结果（本机实测）

5 张表全部建成、数据全部入库，行数与指导书完全一致：

| 表 | 行数 | 说明 |
|---|---|---|
| `readers` | 10 | 读者，`reader_id` 自增 1~10 |
| `publishers` | 6 | 出版社 |
| `book_categories` | 6 | 图书分类 |
| `books` | 10 | 图书 |
| `borrow_records` | 10 | 借阅记录（含 2 条已归还、1 条逾期） |

约束与索引统计（`99_verify.sql` 第 4、5 节实测）：

- 约束 18 个：`PRIMARY KEY` 5、`UNIQUE` 4、`FOREIGN KEY` 4、`CHECK` 5；
- 索引 13 个：5 个主键索引 + 4 个唯一索引 + 4 个外键索引；
- 4 条外键全部为 `ON UPDATE CASCADE ON DELETE RESTRICT`。

表结构修改三步验收（`99_verify.sql` 第 7 节）：

| 检查项 | 预期 | 实测 |
|---|---|---|
| `book_categories` 是否有 `floor` 列 | 无（加过又删了） | `floor` 计数 = 0，现存 3 列 |
| `readers.phone` 类型长度 | `varchar(11) NOT NULL` | `varchar(11)`，`允许为空 = NO` |
| 手机号是否被截断 | 10 条全 11 位 | `CHAR_LENGTH=11` 共 10 条 |

约束反证（`98_constraint_tests.sql`，故意写非法数据，全部被拒）：

| # | 非法操作 | 预期 | 实测报错 |
|---|---|---|---|
| 1 | 重复借书证号 `RD20230001` | 1062 | `ERROR 1062 Duplicate entry` |
| 2 | `card_no` 传 `NULL` | 1048 | `ERROR 1048 Column 'card_no' cannot be null` |
| 3 | `gender = 'X'` | 3819 | `ERROR 3819 ck_readers_gender is violated` |
| 4 | `publisher_id = 999`（不存在） | 1452 | `ERROR 1452 fk_books_publisher fails` |
| 5 | `available > total_copies` | 3819 | `ERROR 3819 ck_books_available is violated` |
| 6 | `status = '丢失'`（不在枚举内） | 1265 | `ERROR 1265 Data truncated for column 'status'` |
| 7 | `due_date < borrow_date` | 3819 | `ERROR 3819 ck_borrow_dates is violated` |

7 条全部被拒后复核行数仍为 10/6/6/10/10 —— 约束在库内真实生效，脏数据一条都没进去。

## 五、步骤 5：数据库的备份与还原（两种方式）

### 方式一：mysqldump 命令行（全量逻辑备份，脚本已实测通过）

一条命令（双击 `05_backup_restore.cmd` 等价于下面全部 4 步）：

```powershell
$dump  = "C:\Program Files\MySQL\MySQL Server 9.4\bin\mysqldump.exe"
cmd /c "`"$dump`" -u root -p --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF library_db071 > backup\library_db071_full.sql"
```

脚本会自动完成：备份 → 重建空库 `library_db071_restore` → 导入 → **逐表比对行数和内容摘要（MD5）**。
本次实测输出：

```
saved: lab1\backup\library_db071_full.sql (10,240 bytes)

table                 source    restored   content
--------------------------------------------------
readers                   10          10      SAME
publishers                 6           6      SAME
book_categories            6           6      SAME
books                     10          10      SAME
borrow_records            10          10      SAME

RESULT: PASS - restored DB matches the source table by table.
```

还原库抽样（中文无乱码）：`陈晨 / RD20230001 / 13511110001`、`刘洋 / RD20230002 / 13611110002`、`孙丽 / RD20180003 / 13711110003`。

### 方式二：Navicat 图形界面（报告截图用这条）

1. 左侧对象树选中 `library_db071` → 右键 **转储 SQL 文件 → 结构和数据**，保存为 `library_db071_navicat.sql`。
2. 新建连接下的空库 `library_db071_restore2` → 右键 **运行 SQL 文件**，选中上一步的文件执行。
3. 在 Navicat 里刷新左侧表列表，逐表核对行数与数据，**截图**。

也可用 Navicat 的「备份」向导（右键库 → 备份 → 新建备份 → 还原备份），效果等价。

### 方式三（可选）：CSV 导出 / 导入

`show variables like 'secure_file_priv';` 决定 CSV 只能写在哪个目录。本机为
`D:/ProgramData/MySQL/MySQL Server 9.4/Uploads/`。

```sql
SELECT * FROM books
  INTO OUTFILE 'D:/ProgramData/MySQL/MySQL Server 9.4/Uploads/books.csv'
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.4/Uploads/books.csv'
  INTO TABLE library_db071_csv.books
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';
```

## 六、实验报告截图清单（按指导书「四、撰写实验报告」）

指导书要求「所有题目的结果也都需要用截图进行展示」，按下面 7 组拍即可，每组都对应一个 SQL 文件：

1. **步骤 1 建库**：执行 `01_create_database.sql` + Navicat 左侧对象树出现 `library_db071`。
2. **步骤 2 建表**：`99_verify.sql` 第 2 节（5 张表清单）、第 3 节（字段类型/长度/可空）、第 4 节（约束清单）。
3. **步骤 2 表间联系**：Navicat 中 `books`、`borrow_records` 的「外键」标签页，或 `99_verify.sql` 第 4.1 节。
4. **步骤 3 录入数据**：`99_verify.sql` 第 6 节（5 张表的全量数据，10/6/6/10/10 行）。
5. **步骤 4 表结构修改**：`04_alter_tables.sql` 三条 ALTER 的执行结果 + `99_verify.sql` 第 7 节（要求 7.1~7.4 截图，证明 `floor` 已删、`phone` 变 11）。
6. **约束生效（加分项）**：`98_constraint_tests.sql` 的 7 条报错截图，说明约束不是摆设。
7. **步骤 5 备份与还原**：方式一 `05_backup_restore.cmd` 的 PASS 输出 + `backup\library_db071_full.sql` 文件；方式二 Navicat 转储与还原前后逐表对比截图。

## 七、注意

- `03_insert_data.sql` 会 `TRUNCATE` 全部 5 张表，`98`/`99` 不改数据；重跑 `run_all` 等于重建数据，演示前若手工改过数据请先备份。
- 库名写死为 `library_db071`；若学号后 3 位不是 071，把 5 个 SQL 文件和 `05`/`run_all` 脚本里的 `library_db071` 全部替换即可（文件名不必改）。
- 本机存在一个名字相近的历史库 `library_db 071`（中间带空格，内含空表 `cc`），属于早前试建，**未改动**。若确认无用可在 Navicat 里删除。
- `information_schema.CHECK_CONSTRAINTS.CHECK_CLAUSE` 里带中文的表达式会被 MySQL 9.4 二次编码显示成乱码（服务端元数据的小毛病，不影响约束本身），所以 `99_verify.sql` 第 4.2 节只列约束名，表达式原文看 `02_create_tables.sql`。
