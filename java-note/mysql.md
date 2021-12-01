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

# 查询所有表信息
SHOW TABLE STATUS;
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

# 根据id分组查询age小于20的表数据
SELECT * FROM test GROUP BY id HAVING age < 20;

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
# =======================================================
# 这里是指定主键约束名的添加和删除方式，但是主键只能有一个，所以感觉主键指定名称貌似有点多余？
ALTER TABLE test ADD CONSTRAINT pk_test PRIMARY KEY (id);
ALTER TABLE test DROP PRIMARY KEY `pk_test`;
# =======================================================

# 添加主键
ALTER TABLE test ADD PAIMARY KEY (id);

# 删除主键
ALTER TABLE test DROP PRIMARY KEY;

# =======================================================
# 知识点提示！！！
# 不指定外键约束名，会自动生成一个，但是不知道怎么查出来，有人说用SHOW CREATE TABLE 表名 可以查询出来但是我测试了一下不行
# 这个问题先放着，后期我来填坑
# =======================================================

# =======================================================
# 外键增删改查，都要通过外键的约束名，创建时尽量注意写外键的约束名，所以不建议下面这种不指定外键约束名的方式
ALTER TABLE test ADD FOREIGN KEY (id) REFERENCES test_join(id);
# =======================================================

# =======================================================
# 建两个表用于测试
CREATE TABLE test_key(id INT, key_name VARCHAR(20), PRIMARY KEY(id));
CREATE TABLE test_foreign_key(id INT, foreign_key_name VARCHAR(20), PRIMARY KEY(id));
# =======================================================

# 添加外键
ALTER TABLE test_key ADD CONSTRAINT fk_id FOREIGN KEY (id) REFERENCES test_foreign_key(id);

# 删除外键
ALTER TABLE test_key DROP FOREIGN KEY `fk_id`;

# 修改外键
ALTER TABLE test_key DROP FOREIGN KEY `fk_id`, ADD CONSTRAINT fk_id_new FOREIGN KEY (id) REFERENCES test_foreign_key(id);

# 添加唯一键
# 这种不指定唯一键约束名的方式，可以用SHOW CREATE TABLE 查看约束名
ALTER TABLE test_key ADD UNIQUE(key_name);

# 添加唯一键，指定键名
ALTER TABLE test_key ADD UNIQUE un_name (name);
ALTER TABLE test_key ADD UNIQUE INDEX un_name (name);
ALTER TABLE test_key ADD CONSTRAINT un_name UNIQUE (name);
CREATE UNIQUE INDEX un_name ON test_key(name);

# 删除唯一键
DROP INDEX un_name ON test_key;

# 添加索引
ALTER TABLE test_key ADD INDEX (key_name);

# 添加索引，指定索引名
ALTER TABLE test_key ADD INDEX in_name (key_name);
CREATE INDEX in_name ON test_key(key_name);

# 删除索引
DROP INDEX in_name ON test_key;
```

#### 函数
```sql
# =======================================================
# 聚合函数
# =======================================================

# 求总数
SELECT count(id) AS total FROM test;

# 求和
SELECT sum(age) AS total_age FROM test;

# 求平均值
SELECT avg(age) AS avg_age FROM test;

# 求最大值
SELECT max(age) AS max_age FROM test;

# 求最小值
SELECT min(age) AS min_age FROM test;


# =======================================================
# 数学函数
# =======================================================

# 绝对值：8
SELECT abs(-8);

# 二进制：1010，八进制：12，十六进制：A
SELECT bin(10), oct(10), hex(10);

# 圆周率：3.141593
SELECT pi();

# 大于x的最小整数值：6
SELECT ceil(5.5);

# 小于x的最大整数值：5
SELECT floor(5.5);

# 返回集合中最大的值：86
SELECT greatest(13, 21, 34, 41, 55, 69, 72, 86);

# 返回集合中最小的值：13
SELECT least(13, 21, 34, 41, 55, 69, 72, 86);

# 余数：3
SELECT mod(1023, 10);

# 返回0-1内的随机值，每次不一样
SELECT rand();

# 提供一个参数生成一个指定值
SELECT rand(9);  # 0.406868412538309
SELECT rand('test123');  # 0.15522042769493574

# 四舍五入：1023
SELECT round(1023.1023);

# 四舍五入，保留三位数：1023.102
SELECT round(1023.1023, 3);

# 四舍五入整数位：
SELECT round(1023.1023, -1);  # 1020
SELECT round(1025.1025, -1);  # 1030，注意和truncate的区别

# 截短为3位小数：1023.102
SELECT truncate(1023.1023, 3);

# 截短为-1位小数：1020
SELECT truncate(1023.1023, -1);  # 1020
SELECT truncate(1025.1025, -1);  # 1020，注意和round的区别

# 符号的值的符号(负数，零或正)对应-1，0或1
SELECT sign(-6);  # -1
SELECT sign(0);  # 0
SELECT sign(6);  # 1

# 平方根：10
SELECT sqrt(10);


# =======================================================
# 字符串函数
# =======================================================

# 连接字符串 'fx67ll'
SELECT concat('f', 'x', '67', 'll');

# 用分隔符连接字符串 'fx67ll'，注意如果分隔符为NULL，则结果为NULL
SELECT concat_ws('-', 'fx', '6', '7', 'l', 'l');  # fx-6-7-l-l
SELECT concat_ws(NULL, 'fx', '6', '7', 'l', 'l');  # NULL

# 将字符串 'fx67ll' 从3位置开始的2个字符替换为 '78'
SELECT insert('fx67ll', 3, 2, '78');  # fx78ll

# 返回字符串 'fx67ll' 左边的3个字符：fx6
SELECT left('fx67ll', 3);

# 返回字符串 'fx67ll' 右边的4个字符: 67ll
SELECT right('fx67ll', 4);

# 返回字符串 'fx67ll' 第3个字符之后的子字符串：67ll
SELECT substring('fx67ll', 3);

# 返回字符串 'fx67ll' 倒数第3个字符之后的子字符串：7ll
SELECT substring('fx67ll', -3);

# 返回字符串 'fx67ll' 第3个字符之后的2个字符：67
SELECT substring('fx67ll', 3, 2);

# 切割字符串 ' fx67ll ' 两边的空字符，注意字符串左右有空格：'fx67ll'
SELECT trim(' fx67ll ');

# 切割字符串 ' fx67ll ' 左边的空字符：'fx67ll '
SELECT ltrim(' fx67ll ');

# 切割字符串 ' fx67ll ' 右边的字符串：' fx67ll'
SELECT rtrim(' fx67ll ');

# 重复字符 'fx67ll' 三次：fx67llfx67llfx67ll
SELECT repeat('fx67ll', 3);

# 对字符串 'fx67ll' 进行反向排序：ll76xf
SELECT reverse('fx67ll');

# 返回字符串的长度：6
SELECT length('fx67ll');

# 对字符串进行大小写处理，大小写各两种方式
SELECT upper('FX67ll');  # FX67LL
SELECT lower('fx67LL');  # fx67ll
SELECT ucase('fX67Ll');  # FX67LL
SELECT lcase('Fx67lL');  # fx67ll


# 返回 'f' 在 'fx67ll' 中的第一个位置：1
SELECT position('f' IN 'fx67ll');

# 返回 '1' 在 'fx67ll' 中的第一个位置，不存在返回0：0
SELECT position('1' IN 'fx67ll');

# 比较字符串，第一个参数小于第二个返回负数，否则返回正数，相等返回0
SELECT strcmp('abc', 'abd');  # -1
SELECT strcmp('abc', 'abb');  # 1
SELECT strcmp('abc', 'abc');  # 0


# =======================================================
# 时间函数
# =======================================================

# 返回当前日期，时间，日期时间
SELECT current_date, current_time, now();

# 返回当前时间的时，分，秒
SELECT hour(current_time), minute(current_time), second(current_time);

# 返回当前日期的年，月，日
SELECT year(current_date), month(current_date), day(current_date);

# 返回当前日期的季度
SELECT quarter(current_date);

# 返回当前月份的名称，当前星期的名称
SELECT monthname(current_date), dayname(current_date);

# 返回当前日在星期的天数，当前日在月的天数，当前日在年的天数
SELECT dayofweek(current_date), dayofmonth(current_date), dayofyear(current_date);


# =======================================================
# 控制流函数
# =======================================================
	
# IF判断：1
SELECT IF(2>1, '1', '0')  # 1

# IFNULL判断
# 判断第一个表达式是否为NULL，如果为NULL则返回第二个参数的值，否则返回第一个参数的值
SELECT IFNULL(NULL, 1);  # 1
SELECT IFNULL('fx67ll', 0);  # fx67ll

# ISNULL判断
# 接受1个参数，并测试该参数是否为NULL，如果参数为NULL，则返回1，否则返回0
SELECT ISNULL(1);  # 0
SELECT ISNULL(1/0);  # 1


# NULLIF判断
# 接受2个参数，如果第1个参数等于第2个参数，则返回NULL，否则返回第1个参数
SELECT NULLIF('fx67ll', 'fx67ll');  # NULL
SELECT NULLIF('fx67ll', 'll76xf');  # fx67ll

# NULLIF类似于下面的CASE表达式
CASE WHEN expression_1 = expression_2
   THEN NULL
ELSE
   expression_1
END;

# CASE判断：second
SELECT CASE 2
	WHEN 1 THEN 'first'
	WHEN 2 THEN 'second'
	WHEN 3 THEN 'third'
	ELSE 'other'
	END;


# =======================================================
# 系统信息函数
# =======================================================

# 显示当前数据库名
SELECT database();

# 显示当前用户id
SELECT connection_id();

# 显示当前用户
SELECT user();

# 显示当前mysql版本
SELECT version();

# 返回上次查询的检索行数
SELECT found_rows();
```


#### 视图
#### 存储过程
#### 备份还原
#### 用户