# MySQL学习笔记

### 废话不多说直接上语句练习

#### 连接MySQL
```sql
# 用户名和密码要紧跟-u-p不能有空格
mysql -u用户名 -p密码

# 如果不想明文显示密码，执行命令后会提示输入密码，并且不会明文显示密码
mysql -u 用户名 -p
```

#### 数据库
```sql
# 查看所有的数据库
SHOW DATABASES;

# 创建一个数据库
CREATE DATABASE test;

# 删除一个数据库
DROP DATABASE test;

# 使用数据库
USE test;
```

#### 表
```sql
# 查看所有的表
SHOW TABLES;

# 创建一个表，拥有主键
# 主键约束（PRIMARY KEY）：没有明确的概念定义，是唯一性索引的一种，不能重复，一个表只能有一个主键
# 数据类型，务必深入了解，对数据库的优化非常重要  
CREATE TABLE test(id INT, name VARCHAR(10), PRIMARY KEY (id));

# 创建另一个表，拥有主键，并包含前一个表的外键约束，以及唯一约束  
# 外键约束（FOREIGN KEY）：用来在表与表的数据之间建立链接，它可以是一列或者多列  
# 举个栗子帮助理解：班级表，10个班级，年级表，6个年级，每个班级只能所属1个年级，且必须是这6个年级中的1个，这个时候班级表就需要用年级表来建立外键，确保数据一致且完整  
# 唯一约束（UNIQUE KEY）：指所有记录中的字段的值不能重复出现  
CREATE TABLE test_key(id INT, name VARCHAR(10), PRIMARY KEY (id), FOREIGN KEY (id) REFERENCES test(id), UNIQUE (name));

# 直接将查询结果导入或复制到，一个新创建的表
CREATE TABLE test_copy SELECT * FROM test;
CREATE TABLE test_copy_as AS SELECT * FROM test;

# 将一个已存在表的数据结构克隆到，一个新创建的表
CREATE TABLE test_clone LIKE test;

# 创建一个临时表，各种方式  
# 临时表将在你连接MySQL期间存在，当断开连接时，MySQL将自动删除表并释放所用的空间，也可手动删除。
CREATE TEMPORARY TABLE test_tem(id INT, name VARCHAR(10));
CREATE TEMPORARY TABLE test_tem_copy SELECT * FROM test;

# 删除一个存在表
DROP TABLE IF EXISTS test;

# 更改存在表的名称
ALTER TABLE test RENAME test_rename;
RENAME TABLE test_rename TO test;

# 查看表的结构
# 以下五条语句效果相同，推荐第一条，因为简单  
DESC test;
DESCRIBE test;
SHOW COLUMNS IN test;
SHOW COLUMNS FROM test;
EXPLAIN test;

# 查看表的创建语句
SHOW CREATE TABLE test;
```