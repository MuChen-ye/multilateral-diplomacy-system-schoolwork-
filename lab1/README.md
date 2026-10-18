# 实验一 数据定义与插入 —— 实施记录

> 数据库：`library_db071`（`library_db` + 学号后 3 位）
> 环境：MySQL Server 9.4.0（Windows 服务 `MySQL94`，端口 3306），Navicat Premium 17.3.11 客户端
> 字符集：`utf8mb4`（中文与 emoji 都不会乱码）

## 一、文件清单与执行顺序

| 顺序 | 文件 | 对应实验步骤 |
|---|---|---|
| 1 | `01_create_database.sql` | 步骤 1 创建数据库 |
| 2 | `02_create_tables.sql` | 步骤 2 创建 5 张表与表间联系 |
| 3 | `03_insert_data.sql` | 步骤 3 录入各表数据 |
| 4 | `04_alter_tables.sql` | 步骤 3(3) 表结构修改（加列 / 改列长 / 删列） |
| 5 | `backup/library_db071_full.sql` | 步骤 4 方式一产生的备份文件（mysqldump 全量） |
| - | `run_all.cmd` | **双击即可**一键执行 1~4 并自检（推荐） |
| - | `run_all.ps1` | 上面 .cmd 实际调用的脚本，也可手动跑 |

命令行执行方式（在 `lab1` 目录下）：

```powershell
$mysql = "C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe"
cmd /c "`"$mysql`" -u root -p --default-character-set=utf8mb4 < 01_create_database.sql"
# 02 / 03 / 04 同理
```

或者**双击 `run_all.cmd`**（会提示输入 MySQL 密码，跑完自动暂停让你看结果）。

> 注意：Windows 默认执行策略会拦截未签名的 `.ps1`，直接双击 `.ps1` 会报
> `未对文件 run_all.ps1 进行数字签名`。所以给了一个 `.cmd` 外壳，它用
> `-ExecutionPolicy Bypass` 只为这一次运行放行，不改你系统的全局策略。

## 二、建表设计说明（对应"定义必要的列级约束和表级约束"）

- **列级约束**：`NOT NULL`、`AUTO_INCREMENT`、`DEFAULT`、`CHECK`（`gender IN ('男','女')`、`max_borrow >= 0`、`price >= 0`、`due_date >= borrow_date`、`available <= total_copies`）。
- **表级约束**：`PRIMARY KEY`、`UNIQUE`（`card_no` 借书证号唯一、`isbn` 唯一、出版社与分类名称唯一）、`FOREIGN KEY`。
- **外键策略**：`ON UPDATE CASCADE ON DELETE RESTRICT`——主表主键变动时联动，但禁止删掉仍被图书/借阅记录引用的出版社、分类、读者和图书。
- **类型选择**：`gender CHAR(1)`（单字性别）；`reader_type` / `status` 用 `ENUM` 限值；`price DECIMAL(8,2)` 避免浮点误差；`founded_year YEAR` 专存年份。

表间联系：

```
publishers 1 ──── n books n ──── 1 book_categories
readers    1 ──── n borrow_records n ──── 1 books
```

## 三、执行结果（本机实测）

5 张表全部建成，数据全部入库：

| 表 | 行数 | 说明 |
|---|---|---|
| readers | 10 | 读者，`reader_id` 自增 1~10 |
| publishers | 6 | 出版社 |
| book_categories | 6 | 图书分类 |
| books | 10 | 图书 |
| borrow_records | 10 | 借阅记录 |

表结构修改三步验证通过：

- `book_categories` 曾增加 `floor INT NULL COMMENT '楼层'`，随后已删除 —— 现在 `show columns from book_categories` 只有 `category_id / name / location`；
- `readers.phone` 已从 `varchar(20)` 改为 `varchar(11)`（实测 11 位手机号完整保留）。

外键实测 4 条全部生效：

```
fk_books_category    books.category_id          -> book_categories.category_id
fk_books_publisher   books.publisher_id         -> publishers.publisher_id
fk_borrow_book       borrow_records.book_id     -> books.book_id
fk_borrow_reader     borrow_records.reader_id   -> readers.reader_id
```

## 四、步骤 4：数据库的备份与还原（两种方式）

### 方式一：mysqldump 命令行（全量逻辑备份，已验证）

```powershell
$dump = "C:\Program Files\MySQL\MySQL Server 9.4\bin\mysqldump.exe"
cmd /c "`"$dump`" -u root -p --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF library_db071 > backup\library_db071_full.sql"
```

还原到一个新库验证：

```powershell
$mysql = "C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe"
& $mysql -u root -e "CREATE DATABASE library_db071_restore DEFAULT CHARACTER SET utf8mb4;"
cmd /c "`"$mysql`" -u root -p --default-character-set=utf8mb4 library_db071_restore < backup\library_db071_full.sql"
```

**实测结果**（备份文件 10,426 字节）：还原库与原库逐表行数完全一致 ——
`readers 10/10`、`publishers 6/6`、`book_categories 6/6`、`books 10/10`、`borrow_records 10/10`，中文数据抽样（陈晨 / 计算机科学 / A区1架）无乱码。

### 方式二：Navicat 图形界面（需截图）

1. 右侧对象树选中 `library_db071` → 右键 **转储 SQL 文件 → 结构和数据**，保存为 `library_db071_navicat.sql`。
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

## 五、实验报告需要的截图清单

1. Navicat 左侧对象树：`library_db071` 下的 5 张表（证明建库建表）。
2. 每张表的「设计表」界面：字段、类型、约束（证明数据类型与列级约束）。
3. `books` / `borrow_records` 的「外键」标签页（证明表间联系）。
4. 每张表的数据视图（证明 10/6/6/10/10 行数据）。
5. 表结构修改三条 SQL 的执行与结果（`floor` 加/删、`phone` 变为 11）。
6. 备份文件生成 + 还原后新库的表与数据（方式一、方式二各一套）。

## 六、注意

- 本机存在一个名为 `library_db071` 之外的历史库 `library_db 071`（中间带空格，内含空表 `cc`），属于早前试建，**未改动**。若确认无用可在 Navicat 里删除，或让我执行 `DROP DATABASE \`library_db 071\``。
- 若老师要求库名严格为「library_db + 学号后 3 位」且学号不是 071，只需把 5 个文件里的 `library_db071` 全部替换即可。
