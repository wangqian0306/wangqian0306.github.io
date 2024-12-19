---
title: MySQL 优化
date: 2024-12-09 22:12:59
tags: "MySQL"
id: mysql-optimization
no_word_count: true
no_toc: false
categories: MySQL
---

## MySQL 优化

### 简介

数据库性能取决于数据库中的几个因素 级别，例如 tables、queries 和 configuration settings。这些软件结构导致硬件级别产生不同的 CPU 指令和 I/O 操作，为了优化性能需要将操作数进可能缩减。在提高数据库性能时，首先需要试用设计上的基础规则和软件的指导手册，并采用时间所为评判工具来进行优化。想成为专家，可以更多地了解软件内部发生的事情， 并开始测量 CPU 周期和 I/O 操作等内容。

典型用户的目标是从其现有的软件和硬件配置中获得最佳数据库性能。高级用户寻找机会改进 MySQL 软件本身，或开发自己的存储引擎和硬件设备来扩展 MySQL 生态系统。在官方文档中针对优化方式进行了如下分类：

- 在数据库级别进行优化
- 在硬件级别进行优化
- 平衡可移植性和性能(略)

### 在数据库级别进行优化

从基础设计上进行优化是最主要的提升方向，具体项目如下：

- 表结构(tables structure)
- 索引(indexes)
- 存储引擎(storage engine)
- 行格式(row format)
- 锁策略(locking strategy)
- 缓存大小(memory areas used for caching)

在上述优化执行前可以先考虑通过优化 SQL 的角度来提升检索速度。

#### 优化 SQL 语句

在优化 SQL 时主要遵循的思路是：

- 利用索引
- 隔离并优化查询的任何部分
- 减少全表扫描
- 让优化器读取到最新的表结构
- 了解存储引擎的优化技术、索引技术和配置参数
- 调整 MySQL 缓存中关于内存区域的大小和配置
- 减少缓存的大小
- 处理锁的问题

> 注：由于此处内容过多且杂乱，此时暂不整理。如有需求请参照 [Optimizing SQL Statements](https://dev.mysql.com/doc/refman/8.0/en/statement-optimization.html)

#### 优化索引

大多数 MySQL 索引(PRIMARY KEY ,UNIQUE ,INDEX, FULLTEXT)存储在 B 树(B-Trees,统称，一般应该是 B+ 树)。例外： SPECIAL 类型的索引使用 R 树; MEMORY table 还支持哈希索引; InnoDB 对 FULLTEXT 索引使用倒排索引。

在索引使用上遵循如下规则：

- 如果有多列索引，检索时要从左往右进行索引拼接。
- 如果需要跨表，最好让链接列具有相同的数据类型和大小且如果是字符串需要相同的字符集。
- 如果是 SPATIAL 索引需要指定 SRID(Spatial Reference System Identifier, 例如：EPSG:4326)。
- 在遇到非二进制数据时需要确保字段编码后长度小于 767 字节。

在检索时可以使用 Explain 语句查看检索方式，优化查询逻辑。

MySQL 存储引擎还会通过读取表统计信息的方式来对查询进行优化，索引对应的数据条目数如果太多则 MySQL 可能不会使用该索引。索引对应的数据条目数可以通过 `SHOW INDEX` 语句查看，它会显示基于 N/S 的基数值，其中 N 是表中的行数，S 是索引对应的数据条目大小。

在使用索引时 InnoDB 存储引擎默认打开了索引扩展功能，在优化器中会执行索引扩展操作，将二级索引拼接在主键前，在使用时可以检查是否采用此功能。

为了减少数据扫描，可以在创建索引时指定排序方式，例如：`CREATE INDEX idx_name ON table_name (col1 ASC ,col2 DESC)`。

> 注：在进行索引优化时如果表比较大删除和重新添加索引的成本会很高，此时可以先将其设置为隐形索引，然后再去检查 optimizer 是否使用隐形索引做检索条件，将其关闭即可进行测试。

#### 优化数据结构

数据结构的优化要安排在设计阶段，目的是将表使用的数据空间尽可能缩小。此时花费的内存也会减少，并且索引也会相对较小检索速度也就会提升。

MySQL 支持许多不同的存储引擎(表类型)和 行格式。对于每个表，可以单独指定存储引擎和要使用的索引方法。

主要的方法如下：

- 表列(Table Columns)
  - 选择合适的数据类型，比方说 MEDIUMINT 比 INT 使用的空间少 25%。
  - 如有可能，请将列设置为 NOT NULL。它支持更好的使用索引并消除测试每个值为 NULL 的开销并缩减 1 位的空间。
- 行格式(Row Format)
  - 在不同的存储引擎中支持了不同的行格式，如果使用紧凑的行格式可能会增加 CPU 负载但是会减少磁盘负载。需结合具体需求进行确定。
  - 对于 MyISAM 表，如果没有可变长度的列(VARCHAR, TEXT, BLOB)，可以使用固定大小的行格式(FIXED)。这样会更快，但是浪费了空间。
- 索引(Indexes)
  - 表的主索引应尽可能短。
  - 仅创建提高查询性能所需的索引。索引的 Key 应当以检索频率进行排序，最左侧的应该是常见且经常重复的列。
  - 如果说长字符串的前 N 位已经足够表达唯一性了，后续内容可以忽略则可以在创建索引的时候指定位数。
- 链接(Joins)
  - 将频繁被查询的数据和不用于查询只展示的数据进行分离。
  - 在具有相同数据类型的不同表中声明具有相同信息的列，以加快基于相应列的连接。
  - 保持列名简单，以便在不同的表中使用相同的名称并简化联接查询。
- 范式化(Normalization)
  - 通常，尽量保持所有数据不冗余。
  - 如果速度比磁盘空间和保留多个数据副本的维护成本更重要，则可以考虑冗余。

在选择列数据类型时可以遵循如下逻辑：

- 数值型
  - 优先选择用数值型进行存储而不要使用字符串。
  - 如果是数值数据，在实时链接下比读取文件快。
- 字符型
  - 在不需要语言特行排序和比较特性的情况下，可以使用二进制（binary）排序规则（collation）来提高比较和排序操作的性能。
  - 在比较不同列的值时，尽可能使用相同的字符集和排序规则声明这些列，以避免在运行查询时进行字符串转换。
  - 对于内容小于 8KB 的列值，请使用二进制 VARCHAR 而不是 BLOB。
  - 如果表包含字符串列，例如 name 和 address，但许多查询不会检索这些列， 考虑将字符串列拆分为单独的 table 并使用带有外键的联接查询。
  - 如果使用随机的值作为主键(类似 UUID)时最好在前面附加时间数据，便于 InnoDB 索引插入和检索。
- BLOB 型
  - 存储包含文本数据的大型 blob 时， 首先考虑压缩它。
  - 对于具有多个列的表，为了减少不使用 BLOB 列的查询的内存需求，可以考虑将 BLOB 列拆分为一个单独的表，并在需要时用联接查询引用它。
  - 可以将 BLOB 数据存储在独立的存储设备或单独的数据库实例上。
  - 可以将列值的哈希值存储在单独的列中，为该列编制索引，并在查询中测试哈希值，而不是针对很长的文本字符串测试内容是否相同。

在库和表以及配置上可以遵循如下逻辑：

- 确定集群的缓存策略，调整 `open_files_limit` 系统配置，以便更好地利用缓存策略，还可以微调 table_open_cache 和 max_connections 配置项。
- 如果库中有许多 MyISAM 表，则需要增加缓存条目数避免打开、关闭和创建操作影响性能。
- 如果在使用中有很多临时表的创建也会遇到性能问题，可以尝试优化 SQL 或者修改配置将临时表存储在内存中。

### 优化存储引擎

此处暂时只针对 InnoDB 进行整理，后期如有时间会进行补充完善。

#### InnoDB

- 优化表的存储布局
  - 一旦数据趋于稳定或有大量数据插入后可以使用 `OPTIMIZE TABLE` 语句整理表空间和索引。
  - 尝试避免长字符串主键。
  - 使用 VARCHAR 而不是 CHAR 存储可变长度字符串。
  - 对于较大的表格或包含大量重复文本的表格或数值数据，请考虑使用 COMPRESSED 行格式。
- 优化事务管理
  - 将事务功能的性能开销和服务器的工作负载之间找到理想的平衡。相关业务逻辑合并到单个事务中，可以减少事务的开销。
  - 对于仅包含单个 SELECT 语句的事务，启用 AUTOCOMMIT 会有所帮助 InnoDB 识别只读事务并对其进行优化。
  - 避免在单个事务中插入更新或删除大量行然后进行回滚，此时数据库若性能下降不要终结数据库进程。回滚会在服务启动时重新执行。为了避免此问题可以做如下处理：
    - 增加缓冲池大小。
    - 设置 `innodb_change_buffering=all` ，以便 update 和 delete 操作存储在缓存中。
    - 考虑将大量数据分批次处理。
  - 修改或删除行时，行和关联的 redo log 不会立即以物理删除，甚至不会在事务提交后立即删除。旧数据将保留，直到较早或同时开始的事务完成，以便这些事务可以访问已修改或删除行的先前状态。因此，长时间运行的事务可能会阻止 InnoDB 清除由其他事务更改的数据。
  - 在长时间运行的事务中，如果使用 READ COMMITED 和 REPEATABLE READ 隔离级别的其他事务读取相同的行，则必须做更多的工作来重建旧数据。
  - 当一个长时间运行的事务修改了表中的数据时，其他并发事务对同一表的查询可能会失去使用覆盖索引(covering index)的能力。
- 优化只读事务
  - InnoDB 可以通过识别只读事务并优化其处理方式来减少与设置 TRX_ID 相关的开销。对于明确为只读的事务，不需要分配事务 ID，因为这些事务不会执行写操作或锁定读取。这种优化减少了内部数据结构的大小和复杂度，进而提升了查询性能，尤其是在高并发环境下。
- 优化 Redo Log
  - 增加 Redo Log 文件的大小。什么时候 InnoDB 已将重做日志文件写入完整，它必须在检查点中将缓冲池的修改内容写入磁盘。若配置较小会导致许多不必要的磁盘写入。
  - 考虑增加 log 缓冲区。
  - 配置 innodb_log_write_ahead_size 与操作系统或文件系统缓存块大小相匹配的值，使用如下命令即可查看 `stat -f --format="%S" <path>`。
  - 若并发低则关闭 innodb_log_writer_threads 。
  - 优化用户线程在等待刷新重做日志（flushed redo）时的自旋延迟（spin delay）设置，可以帮助你根据系统负载情况调整性能和资源使用。通过合理配置 innodb_log_wait_for_flush_spin_hwm、innodb_log_spin_cpu_abs_lwm 和 innodb_log_spin_cpu_pct_hwm 系统变量，可以在高并发和低并发期间实现更高效的资源利用。
    - innodb_log_wait_for_flush_spin_hwm 当平均日志刷新时间超过该值时，用户线程将不再进行自旋等待，而是进入睡眠状态。高并发时减少，低时增加。
    - innodb_log_spin_cpu_abs_lwm CPU 使用率低于该阈值时，用户线程将不再进行自旋等待。这个值是基于绝对 CPU 核心使用量的总和。如果系统 CPU 使用率较低，可以通过提高这个阈值。
    - innodb_log_spin_cpu_pct_hwm 当总的 CPU 使用率超过该百分比时，用户线程将不再进行自旋等待。这个值是基于绝对 CPU 核心使用量的总和。在高并发情况下，降低这个值。
- 批量插入优化。
  - 在插入大量数据时先关闭 `SET autocommit=0` 然后结束后再 `COMMIT;` 。
  - 对于包含唯一约束（UNIQUE 约束）的二级索引，在导入大量数据时临时关闭唯一性检查可以显著提高导入速度。这是因为 InnoDB 可以利用其更改缓冲区(change buffer)来批量写入二级索引记录，从而减少大量的磁盘 I/O 操作。
  - 关闭外键检查可以节省磁盘 I/O ，增加插入性能。
  - 使用多行 INSERT 语法来减少客户端和服务器之间的通信开销。
  - 设置 innodb_autoinc_lock_mode 为 2（交错模式，interleaved）可以在执行批量插入到带有自增列（AUTO_INCREMENT）的表时显著提升性能，特别是在高并发环境下。
  - 在执行批量插入时，按照主键(PRIMARY KEY)顺序插入行可以显著提高性能，尤其是在 InnoDB 表中。这是因为 InnoDB 使用聚簇索引，数据物理上是按照主键顺序存储的。因此，按主键顺序插入数据可以减少页面分裂和随机 I/O 操作，从而提升插入速度。对于那些不能完全放入缓冲池(buffer pool)的大表来说，这一点尤为重要。
  - 为了在将数据加载到InnoDB FULLTEXT索引时获得最佳性能，请执行以下步骤：
    - 在表创建时定义一个类型为 BIGINT UNSIGNED NOT NULL 的列 FTS_DOC_ID，该列具有一个名为 FTS_DOC_ID_index 的唯一索引。
    - 将数据加载到表中。
    - 创建 FULLTEXT 索引。
  - 在向新的 MySQL 实例加载大量数据时，考虑临时禁用重做日志（redo log）可以显著提高数据加载速度。
  - 使用 MySQL Shell 的 util.importTable() 和 util.loadDump() 指令可以显著提高大规模数据文件的导入速度，特别是当处理大容量数据时。这些工具提供了并行加载功能，能够充分利用多核处理器的优势，从而加快数据导入过程。
- 优化 InnoDB 查询。
  - 选择最重要的列作为主键。
  - 不要在主键中指定太多或太长的列，因为这些列值在每个辅助索引中都是重复的。当索引包含不必要的数据时，读取这些数据的 I/O 和缓存这些数据的内存会降低服务器的性能和可扩展性。
  - 不要为每列创建单独的索引，而是根据查询情况设置联合索引。
  - 如果索引列不能包含任何 NULL 值，请在创建表时将其声明为 NOT NULL。优化器当知道每列是否包含 NULL 值可以更好地确定哪个索引最有效地用于查询。
  - 优化只读事务
- 优化 InnoDB DDL。
  - 对表和索引的 DDL 操作可以不影响之前的环境。
  - 加载数据之后再建立索引会快一些。
  - 在没有外键时可以使用 `TRUNCATE TABLE` 清空表，如果有外键的话使用 `DROP TABLE` 和 `CREATE TABLE` 的命令可能是最快的方法。
- 优化 InnoDB 磁盘 I/O。
  - 增加缓冲池大小到系统内存的 50%-75%。
  - 如果数据写入磁盘的速度很慢，可以将 innodb_flush_method 设置为 O_DSYNC。
  - 在多实例多租户情况下考虑调整 innodb_fsync_threshold 的值，批量将数据写入磁盘。
  - 打开 innodb_use_fdatasync 配置。
  - 在 Linux 系统中可以使用 noop 和 deadline 调度器，使用如下命令检查 `cat /sys/block/sd<device>/queue/scheduler` 输出结果是支持的调度器，用方括号选中的是现在正在使用的。
  - 将数据文件和日志文件分离放置。
  - 使用 SSD 存储数据，并检查如下配置：
    - innodb_checksum_algorithm 应当设置为 crc32。
    - innodb_flush_neighbors 设置为 0。
    - 调整 innodb_idle_flush_pct 参数，调大会增加硬盘读写次数损耗寿命调小会让内存压力增大。
    - 调整 innodb_io_capacity 参数，例如 1000。
    - 调整 innodb_io_capacity_max 参数，例如 2500。
    - 如果 redo log 在 SSD 上，需要禁用 innodb_log_compressed_pages。
    - 如果 redo log 在 SSD 上，增加 innodb_redo_log_capacity。
    - 查看硬件的扇区大小与 innodb_page_size 进行匹配。
    - 如果日志在 SSD 上，并且所有表都有主键可以将 binlog_row_image 设置为 minimal。
    - 增加 innodb_doublewrite_pages 参数。
    - 调整 innodb_read_io_threads 和 innodb_write_io_threads 线程数，默认配置跑不满磁盘。
  - 调整 innodb_io_capacity 参数。
  - 禁用压缩页面的日志记录 innodb_log_compressed_pages。
- 优化 InnoDB 配置变量。
  - 配置 InnoDB 缓存的数据操作类型 innodb_change_buffering。
  - 在写入多时可以尝试关闭 innodb_adaptive_hash_index。
  - 配置并发线程数 innodb_thread_concurrency。
  - 合理配置预读缓存 innodb_read_ahead_threshold。
  - 合理配置 InnoDB 的缓冲池刷新算法 (Buffer Pool Flushing Algorithm)。
  - 利用多核处理器及其缓存内存配置优化自旋锁，以最小化上下文切换延迟。
  - 防止 table scans 等一次性操作，干扰 InnoDB 缓冲区缓存。
  - 将日志文件调整为对可靠性和崩溃恢复有意义的大小。
  - 配置多个缓冲池实例。
  - 增加并发事务的最大数量。
  - 将垃圾回收策略配置为后台线程。
  - 调整 innodb_thread_concurrency 和 innodb_concurrency_tickets 参数，限制同时处理的线程数量，并允许每个线程在被换出之前完成更多的工作，从而保持等待线程的数量较低，并使操作能够在不过度进行上下文切换的情况下完成。
- 如果使用了非持久化优化器统计信息，需要在打开数据库后进行一次读取预热数据。

### 在硬件级别进行优化

任何数据库应用程序最终都会达到硬件限制，因为数据库变得越来越繁忙。DBA 必须进行评估，然后调整应用程序或重新配置服务器。要避免性能瓶颈，可以使用纵向扩展的思路，增加或优化硬件资源。系统瓶颈通常来自以下来源：

- 磁盘查找(Disk seeks)
- 磁盘读取和写入(Disk reading and writing)
- CPU 周期(CPU cycles)
- 内存带宽(Memory bandwidth)

### 参考资料

[官方文档](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
