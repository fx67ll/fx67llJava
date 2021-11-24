# MySQL学习笔记


### SQL语句分类
1. DDL(Data Definition Language)：数据定义语句，主要用于定义不同的数据段，数据库，表，列，索引等数据库对象的定义  
2. DML(Data Manipulation Language)：数据操作语句，主要用于增删改查数据库记录，并检查数据完整性  
3. DCL(Data Control Language)：数据控制语句，主要用于控制不同数据字段直接许可和访问级别的语句，这些语句定义了数据库、表、字段、用户的访问权限和安全级别  


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

# =======================================================
# 知识点提示！！！
# 主键约束（PRIMARY KEY）：没有明确的概念定义，是唯一性索引的一种，不能重复，一个表只能有一个主键
# 自动增加（AUTO_INCREMENT）：自动增加（需要和主键PRIMARY KEY一起使用）
# 非空约束（NOT NULL）：要求被装饰的字段非空
# 外键约束（FOREIGN KEY）：用来在表与表的数据之间建立链接，它可以是一列或者多列  
# 举个栗子帮助理解：班级表，10个班级，年级表，6个年级，每个班级只能所属1个年级，且必须是这6个年级中的1个，这个时候班级表就需要用年级表来建立外键，确保数据一致且完整  
# 唯一约束（UNIQUE KEY）：指所有记录中的字段的值不能重复出现，可以联合非空UNIQUE(字段1，字段2)  
# 数据类型，务必深入了解，对数据库的优化非常重要  
# AS 别名或者连接语句的操作符
# =======================================================

# 创建一个表，拥有主键
CREATE TABLE test(id INT, name VARCHAR(10), PRIMARY KEY (id));

# 创建另一个表，拥有主键，并包含前一个表的外键约束，以及唯一约束  
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

#### 表结构
```sql
# 添加表字段
ALTER TABLE test ADD age VARCHAR(2);

# 删除表字段
ALTER TABLE test DROP age;

# 更改表字段和表字段属性
ALTER TABLE test CHANGE age age_change INT;

# 只更改表字段属性
ALTER TABLE test MODIFY age VARCHAR(7);
```

#### 表数据
```sql
# 增加表数据
INSERT INTO test VALUES (1, 'alpha', '24'), (2, 'beta', '25'), (3, 'delta', '27');

# =======================================================
# 因为test表设置了主键无法用下面这种方式增加，前两个语句先重建一张表
CREATE TABLE test_insert(id INT, name VARCHAR(8));
INSERT INTO test_insert VALUES (1, 'alpha'), (2, 'beta'); 
# =======================================================

# 增加查询之后的表数据  
INSERT INTO test_insert SELECT * FROM test_insert;

# 删除表数据
DELETE FROM test_insert WHERE id = 2;

# 更改表数据
UPDATE test_insert SET name = 'delta' WHERE id = 1;

# =======================================================
# 为了下面的查询语句能够更直观一些我们再插入一些数据并把age_change的表字段改为age
INSERT INTO test VALUES (10, 'gamma', '39'), (6, 'zeta', '30'),
 (19, 'theta', '10'), (8, 'eta', '20'), (46, 'zeta', '11'), 
 (56, 'zeta', '9'), (66, 'zeta', '3');
ALTER TABLE test CHANGE age_change age VARCHAR(20);
# =======================================================

# =======================================================
# 知识点提示！！！
# SELECT DISTINCT * FROM '表名' WHERE '限制条件' GROUP BY '分组依据' HAVING '过滤条件' ORDER BY LIMIT '展示条数' OFFSET '跳过的条数'
# 以上关键字使用顺序不能错误，否则会产生错误信息
# DISTINCT 去重，注意如果是多个表字段去重，只有每个表字段都相同才会认为相同
# * 代表通配符，会返回所有字段数据
# WHERE 语句用来包含查询条件，对原始记录过滤
# HAVING 语句也是用来包含查询条件，但是HAVING是对WHERE查询分组之后的记录继续过滤
# ORDER BY 排序默认正序也就是升序，DESC表示反序也就是降序
# LIMIT 属性来设定返回的记录数，一般用于列表的分页
# OFFSET 属性来设定跳过的返回的记录数，一般配合LIMIT
# =======================================================

# 查找表数据
SELECT * FROM test;

# 查询去除重复数据之后的表数据
SELECT DISTINCT name FROM test;

# 根据表字段查找表数据
SELECT * FROM test WHERE name = 'zeta';

# 查找name为zeta并且id大于30的表数据
SELECT * FROM test WHERE name = 'zeta' HAVING id > 30;

# 查找根据name排序之后的表数据
SELECT * FROM test ORDER BY name;

# 查找根据name反序排序之后的表数据
SELECT * FROM test ORDER BY name DESC;
 
# =======================================================
# 注意下面这个排序，如果排序的第一个字段所有值都不同，那么第二列排序就没有意义了
# 所以我们之前加入了一些name相同的值，所以可以我们可以看下zeta字段的age排序
# =======================================================

# 查找先根据name排序，再根据age排序之后的表数据
SELECT * FROM test ORDER BY name, age;

# 查找先根据age反序，再根据name排序之后，年龄最大的前三位的表数据
SELECT * FROM test ORDER BY age DESC, name LIMIT 3;

# 查找先根据age反序，再根据name排序之后，年龄最大的前三位，并跳过第一条的表数据
SELECT * FROM test ORDER BY age DESC, name LIMIT 3 OFFSET 1;
SELECT * FROM test ORDER BY age DESC, name LIMIT 1,3;

# 使用正则查询name表字段中包含字母g的表数据
SELECT * FROM test WHERE name regexp '.*[g]+.*';
```

#### 表数据 —— 连接查询
```sql
# =======================================================
# 为了方便大家更为直观的看到连接查询的效果，我再重新建一个用于连接的表
CREATE TABLE test_join(id INT, join_name VARCHAR(20), join_desc VARCHAR(100));
INSERT INTO test_join VALUES (10, 'join_a', 'desc_a'), (11, 'join_b', 'desc_b'), (10, 'gamma', 'join_gamma');
# =======================================================

# =======================================================
# 解释一下下面的内连接查询为什么会有三种
# 第一种为不设置别名的写法
# 第二种为简写AS设置别名的写法
# 第三种为有AS关键字设置别名的写法
# 后续均使用第二种写法
# =======================================================

# 内连接查询
# 注意JOIN连接默认使用内连接
SELECT * FROM test INNER JOIN test_join ON test.id = test_join.id;
SELECT * FROM test m INNER JOIN test_join ON m.id = n.id;
SELECT * FROM test AS m INNER JOIN test_inert AS n ON m.id = n.id;

# 左外连接查询
SELECT * FROM test m LEFT JOIN test_join n ON m.id = n.id;

# 左外连接查询，左表独有数据
SELECT * FROM test m LEDT JOIN test_join n ON m.id = n.id WHERE n.id IS NULL;

# 右外连接查询
SELECT * FROM test m RIHGT JOIN test_join n ON m.id = n.id;

# 右外连接查询，右表独有数据
SELECT * FROM test m RIGHT JOIN test_join n ON m.id = n.id WHERE m.id IS NULL;

# 交叉连接查询，又叫笛卡尔连接
SELECT * FROM test CROSS JOIN test_join;
SELECT * FROM test,test_join;

# 全连接查询  
# UNION默认不返回重复的数据，UNION ALL则会返回重复的数据
SELECT id,name FROM test UNION SELECT id,join_name FROM test_join;
SELECT id,name FROM test UNION ALL SELECT id,join_name FROM test_join;
```

#### 键
```sql
# 添加主键
ALTER TABLE test ADD PAIMARY KEY (id);

# 删除主键
ALTER TABLE test DROP PRIMARY KEY;

# =======================================================
# 这里是指定主键约束名的添加和删除方式，但是主键只能有一个，所以感觉主键指定名称貌似有点多余？
ALTER TABLE test ADD CONSTRAINT pk_test PRIMARY KEY (id);
ALTER TABLE test DROP PRIMARY KEY `pk_test`;
# =======================================================

# =======================================================
# 知识点提示！！！
# 第一种方式是不指定外键约束名，会自动生成一个，但是不知道怎么查出来
# 有人说用SHOW CREATE TABLE 表名 可以查询出来但是我测试了一下不行
# 这个问题先放着，后期我来填坑
# =======================================================

# 添加外键，不指定外键的约束名
ALTER TABLE test ADD FOREIGN KEY (id) REFERENCES test_join(id);

# =======================================================
# 外键增删改查，都要通过外键的约束名，创建时尽量注意写外键的约束名
# =======================================================

# 添加外键
ALTER TABLE test ADD CONSTRAINT fk_id FOREIGN KEY (id) REFERENCES test_join(id);

# 删除外键
ALTER TABLE test DROP FOREIGN KEY `fk_id`;

# 修改外键
ALTER TABLE test DROP FOREIGN KEY `fk_id`,ADD CONSTRAINT fk_id_new FOREIGN KEY (id) REFERENCES test_join(id);

```