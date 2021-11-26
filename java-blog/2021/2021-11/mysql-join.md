# 详解MySQL中的连接查询以及基本应用

内连接查询

左连接查询

右连接查询

全连接查询
注意ORACLE中的full join，MySQL中是没有的，需要使用UNION来实现 

自连接查询，相当于自己和自己做外连接查询


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

### 自连接
相信各位一定见过电商网站中的产品分类，一个大类小面有若干子类，一个子类下面也会分更细的子类，

行转列了解一下

[参考文档 ———— Mysql自连接查询](https://blog.csdn.net/xiaoyaoyulinger/article/details/54175483)  
[参考文档 ———— SQL查询cross join 的用法(笛卡尔积)](https://blog.csdn.net/xiaolinyouni/article/details/6943337?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7Edefault-1.no_search_link&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7Edefault-1.no_search_link)  
[参考文档 ———— MySQL—内连接和外连接区别](https://blog.csdn.net/johnhan9/article/details/88686288)  
[参考文档 ———— mysql中的几种join 及 full join问题](https://blog.csdn.net/lukabruce/article/details/80568796)  

我是 [fx67ll.com](https://fx67ll.com)，如果您发现本文有什么错误，欢迎在评论区讨论指正，感谢您的阅读！  
如果您喜欢这篇文章，欢迎访问我的 [本文github仓库地址](https://github.com/fx67ll/fx67llJava/blob/main/java-blog/2021/2021-11/mysql-join.md)，为我点一颗Star，Thanks~ :)  
***转发请注明参考文章地址，非常感谢！！！***