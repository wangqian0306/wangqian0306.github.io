---
title: PostgreSQL
date: 2023-07-19 23:09:32
tags:
- "PostgreSQL"
id: postgresql
no_word_count: true
no_toc: false
categories: 
- "PostgreSQL"
---

## PostgreSQL

### 简介

PostgreSQL 是一个对象关系数据库管理系统（ORDBMS）

### 部署方式

#### Docker

- 编写如下 Docker Compose 文件

```yaml
services:
  db:
    image: postgres
    restart: always
    environment:
      POSTGRES_PASSWORD: example
```

- 使用如下命令启动运行

```bash
docker-compose up -d
```

- 使用如下命令链接数据库

```bash
docker-compose exec db -it psql -U postgres
```

### 常见操作

在 psql 命令行中可用的快捷方式：

```bash
\l+           -- 查看 DB 清单
\dn+          -- 查看 Schema 清单
\c            -- 切换数据库
\dt+          -- 列出所有表及大小
\d table_name -- 查看指定表的详细结构
\di+          -- 列出所有索引
\dv+          -- 列出所有视图
\df+          -- 列出所有函数有
\du           -- 查看角色和权限
```

执行外部 SQL 的命令：

```bash
\i /path/to/script.sql     -- 执行指定路径下的 SQL 脚本文件
```

查看数据库大小：

```sql
-- 查看当前数据库大小
SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;

-- 查看所有数据库及其大小
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- 查看当前数据库中所有表的大小（含索引）
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(oid)) AS total_size,
    pg_size_pretty(pg_relation_size(oid)) AS table_size,
    pg_size_pretty(pg_total_relation_size(oid) - pg_relation_size(oid)) AS index_size
FROM pg_class
WHERE relkind = 'r'
  AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY pg_total_relation_size(oid) DESC;

-- 查看所有索引及其大小
SELECT
    indexrelname AS index_name,
    relname AS table_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;

-- 查看表空间使用情况
SELECT spcname, pg_size_pretty(pg_tablespace_size(spcname)) AS size
FROM pg_tablespace
ORDER BY pg_tablespace_size(spcname) DESC;
```

查看配置文件和数据存储位置：

```sql
SHOW hba_file;
SHOW config_file;
SHOW data_directory;
```

### 数据备份与恢复

- 备份单表

```bash
# 备份为自定义二进制格式（支持选择性恢复）
pg_dump -U postgres -d dbname -t tablename -F c -f tablename.dump
# 备份并压缩
pg_dump -U postgres -d dbname -t tablename -F c -Z 9 -f tablename.dump
```

- 恢复单表

```bash
# 恢复单个表
pg_restore -U postgres -d dbname -t tablename tablename.dump
# 恢复时创建表（如果不存在）
pg_restore -U postgres -d dbname --create tablename.dump
# 恢复到不同表名
pg_restore -U postgres -d dbname -t tablename --table=new_tablename tablename.dump
```

- 备份单库

```bash
# 标准备份
pg_dump -U postgres -F c -f dbname.dump dbname
# 备份并压缩（级别 9）
pg_dump -U postgres -F c -Z 9 -f dbname.dump dbname
# 并行备份（加快速度）
pg_dump -U postgres -F c -j 4 -f dbname.dump dbname
```

- 恢复单库

```bash
# 基本恢复
pg_restore -U postgres -d dbname -c dbname.dump
# 恢复到新数据库
createdb -U postgres new_dbname
pg_restore -U postgres -d new_dbname dbname.dump
# 并行恢复（加快速度）
pg_restore -U postgres -d dbname -j 4 -c dbname.dump
# 清空现有数据后恢复
pg_restore -U postgres -d dbname --clean --create dbname.dump
```

修改链接权限：

```bash
vim <path_to_hba_file>/pg_hba.conf
```

使用 SQL 刷新配置文件：

```sql
SELECT pg_reload_conf();
```

### 全库备份

PGSQL 提供了 `pg_dumpall` 和 `pg_basebackup` 两种工具，其中：

- `pg_dumpall` 会导出 SQL，在集群升级的时候可以使用
- `pg_basebackup` 会将当前数据库的存储文件进行导出

#### 备份 SQL 及恢复

备份采用如下命令：

```bash
# 简单备份
pg_dumpall -U postgres -h localhost -f /backup/all_databases.sql
# 备份并压缩
pg_dumpall -U postgres | gzip > /backup/all_databases.sql.gz
```

恢复采用如下命令：

```bash
# 简单恢复
psql -U postgres -f /backup/all_databases.sql
# 解压并恢复
gunzip < /backup/all_databases.sql.gz | psql -U postgres
```

#### 备份文件及恢复

使用如下 SQL 找到配置文件目录：

```sql
SHOW config_file;
SHOW hba_file;
```

编辑 `postgresql.conf` 文件，确保如下配置：

```text
wal_level = replica          # 至少为 replica，如果是 9.3 旧版本需要是 hot_standby
max_wal_senders = 3          # 允许复制连接数
wal_keep_segments = 32       # 如果是 9.3 等旧版本需要保留足够 WAL 段
```

在 `pg_hba.conf` 中添加复制权限：

```text
host replication replicator 127.0.0.1/32 scram-sha-256
# 或
host replication replicator 127.0.0.1/32 md5
```

重新启动服务确保配置生效：

```bash
systemctl restart postgresql 
```

导出备份文件：

```bash
# 基本全库物理备份（tar 格式）
pg_basebackup -U replicator -h localhost -D /backup/base_$(date +%Y%m%d) \
  -Ft -z -P -X stream

# 旧版备份 
pg_basebackup -U replicator -h localhost -D /backup/base_9.3_$(date +%Y%m%d) \
  -X stream -P

# 参数说明：
# -D    : 备份目标目录
# -Ft   : tar 格式（-Fp 为纯目录格式）
# -z    : gzip 压缩
# -P    : 显示进度
# -X stream : 流式传输 WAL，保证备份一致性
```

新版恢复：

```bash
# 1. 停止 PostgreSQL
systemctl stop postgresql
# 2. 清空或重命名原数据目录
mv /var/lib/postgresql/xx /var/lib/postgresql/xx_bk
# 3. 解压备份到数据目录
tar xzf /backup/base_xxxxxxxx/base.tar.gz -C /var/lib/postgresql/xx/main/
# 4. 配置 recovery（PG12+ 使用 standby.signal + postgresql.conf）
touch /var/lib/postgresql/16/main/standby.signal
# 如需 PITR，添加 restore_command 和 recovery_target_time
# 5. 启动 PostgreSQL，自动进入恢复模式
systemctl start postgresql
```

旧版恢复

```bash
# 1. 停止 PostgreSQL
systemctl stop postgresql
# 2. 清空或重命名原数据目录
mv /var/lib/postgresql/xx /var/lib/postgresql/xx_bk
# 3. 复制备份到数据目录
cp xxxxx /var/lib/postgresql/xx/main/
# 4. 配置 recovery.conf
cat > /var/lib/postgresql/9.3/main/recovery.conf <<EOF
restore_command = 'cp /wal_archive/%f %p'
recovery_target_time = '2026-06-07 12:00:00'
EOF
# 5. 设置权限
chown -R postgres:postgres /var/lib/postgresql/xx/main
# 6. 启动 PostgreSQL，自动进入恢复模式
systemctl start postgresql
```

### 数据库清理

PGSQL 提供了 `VACUUMDB` 命令去清理数据库，自 8.4 版本起就默认开启了自动清理任务 `autovacuum`。

查看是否启用了清理任务的 SQL 如下：

```sql
-- 1. 检查全局是否启用
SHOW autovacuum;

-- 2. 检查是否有 autovacuum 进程
SELECT count(*) FROM pg_stat_activity WHERE query LIKE '%autovacuum%';

-- 3. 检查最近的 autovacuum 活动
SELECT 
    tablename,
    last_autovacuum,
    autovacuum_count
FROM pg_stat_user_tables
ORDER BY last_autovacuum DESC NULLS LAST
LIMIT 10;
```

如需手动运行可以参照如下命令：

```bash
vacuumdb -d postgres -F -z -v -U postgres
```

### 权限检查与修改

可以使用如下命令查看到当前有权限访问特定数据库的用户：

```sql
SELECT 
    r.rolname                                        AS role_name,
    CASE 
        WHEN s.session_count > 0 THEN '🟢 在线'
        ELSE '⚪ 离线'
    END                                              AS status,
    COALESCE(s.session_count::text, '0')             AS session_count,
    COALESCE(s.client_addr, '-')                     AS client_ip,
    COALESCE(to_char(s.latest_connect, 'YYYY-MM-DD HH24:MI'), '-') AS connected_at,
    COALESCE(s.state, '-')                           AS current_state
FROM pg_roles r
LEFT JOIN (
    SELECT DISTINCT ON (usename)
        usename,
        count(*) OVER (PARTITION BY usename)           AS session_count,
        max(backend_start) OVER (PARTITION BY usename) AS latest_connect,
        client_addr::text                              AS client_addr,
        state
    FROM pg_stat_activity
    WHERE datname = '<db_name>'
    ORDER BY usename, backend_start DESC
) s ON r.rolname = s.usename
WHERE has_database_privilege(r.rolname, '<db_name>', 'CONNECT')
  AND r.rolcanlogin
  AND NOT r.rolname LIKE 'pg_%'
ORDER BY status DESC, COALESCE(s.session_count, 0) DESC, r.rolname;
```

取消用户的连接权限：

```sql
REVOKE CONNECT ON DATABASE <db_name> FROM <role_name>;
```

如果需要重新开放可以使用：

```sql
GRANT CONNECT ON DATABASE <db_name> TO <role_name>;
```

### 参考资料

[官方文档](https://www.postgresql.org/docs/current/index.html)
