# SQL练习之打卡记录数据统计类问题

最近老婆的公司，关闭了OA系统中，各类打卡时间数据统计的功能，为了不麻烦老婆手算，就做了一个简单的打卡系统，方便自动统计老婆想要知道的各类数据。
做的过程中就遇到了几个还挺有意思的SQL，这里写成一篇博文，方便后期练习~

*Tip：需要答案的盆友可以访问 [参考答案的链接](https://fx67ll.xyz/archives/sql-practice-punch-answer)，密码是`123456`~*  

### 建表语句
```sql
drop table if exists fx67ll_punch_log;
create table fx67ll_punch_log (
  punch_id             bigint(20)      not null auto_increment    comment '打卡记录主键',
  punch_type           char(1)                                    comment '打卡类型（1代表上班 2代表下班）',
  punch_remark         varchar(1023)   default ''                 comment '打卡记录备注',
  del_flag             char(1)         default '0'                comment '删除标志（0代表存在 2代表删除）',
  user_id              bigint(20)                                 comment '用户ID',
  create_by            varchar(64)     default ''                 comment '记录创建者',
  create_time 	       datetime                                   comment '记录创建时间',
  update_by            varchar(64)     default ''                 comment '记录更新者',
  update_time          datetime                                   comment '记录更新时间',
  primary key (punch_id)
) engine=innodb auto_increment=1 comment = '打卡记录表';
```

### 插入测试数据
```sql
INSERT INTO `ruoyi-mysql`.fx67ll_punch_log (punch_type,punch_remark,del_flag,user_id,create_by,create_time,update_by,update_time) VALUES
	 ('1','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-06 00:00:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-06 21:00:00'),
	 ('1','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-08 15:00:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-08 18:19:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-08 21:00:00'),
	 ('1','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-10 20:50:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-10 21:44:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-10 22:50:00'),
	 ('1','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-11 10:00:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-11 20:00:00'),
	 ('1','','0',101,'user','2023-12-13 17:03:22','user','2023-12-13 00:06:00'),
	 ('2','e e e','0',101,'user','2023-12-13 17:03:14','user','2023-12-11 01:01:00'),
	 ('1','123','0',1,'fx67ll','2023-12-14 09:53:54','fx67ll','2023-12-14 09:53:50'),
	 ('2','','0',101,'user','2024-03-13 17:49:16','user','2024-03-13 17:49:00'),
	 ('1','324','0',101,'user','2024-03-21 11:22:16','user','2024-03-21 11:22:17'),
	 ('2','','0',101,'user','2024-03-21 11:22:43','user','2024-03-21 22:22:39'),
	 ('2','','0',1,'fx67ll','2024-03-30 20:01:10','fx67ll','2024-03-30 20:01:00'),
	 ('1','','0',1,'fx67ll','2024-04-30 15:01:16','fx67ll','2024-04-30 00:01:06'),
	 ('2','','0',1,'fx67ll','2024-04-30 15:01:25','fx67ll','2024-04-30 23:01:16'),
	 ('1','','0',1,'fx67ll','2024-04-30 15:01:31','fx67ll','2024-04-24 15:01:25'),
	 ('1','','0',101,'user','2024-05-03 02:39:33','user','2024-05-03 02:39:29'),
	 ('1','','0',101,'user','2024-05-03 02:39:41','user','2024-05-04 00:39:33'),
	 ('2','123','0',101,'user','2024-05-03 02:39:52','user','2024-05-04 23:39:41');
```

## 问题一：统计每个用户每个月的工作总时长、总打卡天数、有效打卡天数以及日均工时  
#### 需要得到如下的统计数据，每个字段的含义分别是：
1. `punch_user`：打卡的用户  
2. `punch_month`：本条记录统计的打卡月份  
3. `total_work_hours`：当月的工作总时长，小时为单位  
4. `total_work_minutes`：当月的工作总时长，分钟为单位  
5. `total_work_seconds`：当月的工作总时长，秒为单位  
6. `total_punch_days`：当月的总打卡天数，只要有打卡记录就算，可能只打了上班卡，或者只打了下班卡，但是，没有打卡记录的天数则不算  
7. `total_work_days`：当月的有效打卡天数，必须满足条件，既有上班打卡记录，又有下班打卡记录，才算一个有效打卡天数  
8. `work_hours_per_day`：当月的日均工时，小时为单位  

```
punch_user|punch_month|total_work_hours|total_work_minutes|total_work_seconds|total_punch_days|total_work_days|work_hours_per_day|
----------+-----------+----------------+------------------+------------------+----------------+---------------+------------------+
fx67ll    |2023-12    |         39.0000|              2340|            140400|               5|              4|        9.75000000|
fx67ll    |2024-03    |                |                  |                  |               1|              0|                  |
fx67ll    |2024-04    |         23.0028|              1380|             82810|               2|              1|       23.00277778|
user      |2023-12    |                |                  |                  |               2|              0|                  |
user      |2024-03    |         11.0061|               660|             39622|               2|              1|       11.00611111|
user      |2024-05    |         23.0022|              1380|             82808|               2|              1|       23.00222222|
```


## 问题二：统计每个用户当月的只打了一次卡的缺卡记录  
#### 需要得到如下的统计数据，每个字段的含义分别是：
1. `punch_user`：缺卡的用户  
2. `punch_month`：本条记录的缺卡月份  
3. `punch_day`：本条记录的缺卡日期  
4. `lost_punch_type`：本条记录的缺卡类型，需要输出是上班缺卡还是下班缺卡  

```
punch_user|punch_month|punch_day |lost_punch_type|
----------+-----------+----------+---------------+
fx67ll    |2023-12    |2023-12-14|下班缺卡           |
fx67ll    |2024-03    |2024-03-30|上班缺卡           |
fx67ll    |2024-04    |2024-04-24|下班缺卡           |
user      |2023-12    |2023-12-11|上班缺卡           |
user      |2023-12    |2023-12-13|下班缺卡           |
user      |2024-03    |2024-03-13|上班缺卡           |
user      |2024-05    |2024-05-03|下班缺卡           |
```

我是 [fx67ll.com](https://fx67ll.com)，如果您发现本文有什么错误，欢迎在评论区讨论指正，感谢您的阅读！  
如果您喜欢这篇文章，欢迎访问我的 [本文github仓库地址](https://github.com/fx67ll/fx67llJava/blob/main/java-blog/2024/2024-05/sql-practice-punch.md)，为我点一颗Star，Thanks~ :)  
***转发请注明参考文章地址，非常感谢！！！***



# SQL练习之打卡记录数据统计类问题（参考答案）

*Tip: 本答案仅供参考，并非唯一正确的方式，欢迎在评论区留下你的答案，相互交流~*

## 问题一：统计每个用户每个月的工作总时长、总打卡天数、有效打卡天数以及日均工时  
```sql
SELECT
	fx67ll_punch_log_result.punch_user,
	fx67ll_punch_log_result.punch_month,
	SUM(TIME_TO_SEC(TIMEDIFF( fx67ll_punch_log_result.max_punch_time, fx67ll_punch_log_result.min_punch_time ))) / 3600 AS total_work_hours,
	SUM(TIMESTAMPDIFF(MINUTE, fx67ll_punch_log_result.min_punch_time, fx67ll_punch_log_result.max_punch_time )) AS total_work_minutes,
	SUM(TIME_TO_SEC(TIMEDIFF( fx67ll_punch_log_result.max_punch_time, fx67ll_punch_log_result.min_punch_time ))) AS total_work_seconds,
	COUNT(*) AS total_punch_days,
	COUNT(max_punch_time) AS total_work_days,
	SUM(TIME_TO_SEC(TIMEDIFF( fx67ll_punch_log_result.max_punch_time, fx67ll_punch_log_result.min_punch_time ))) / 3600 / COUNT(max_punch_time) AS work_hours_per_day
FROM
	(
	SELECT
		update_by AS punch_user,
		DATE_FORMAT(update_time, '%Y-%m') AS punch_month,
		DATE(update_time) AS punch_day,
		IF(MAX(update_time) != MIN(update_time),
		MAX(update_time),
		NULL) AS max_punch_time,
		IF(MAX(update_time) != MIN(update_time),
		MIN(update_time),
		NULL) AS min_punch_time
	FROM
		fx67ll_punch_log
	GROUP BY
		punch_user,
		punch_month,
		punch_day
	) 
AS fx67ll_punch_log_result
GROUP BY
	punch_user,
	punch_month;
```

## 问题二：统计每个用户当月的只打了一次卡的缺卡记录  
```sql
SELECT
	fx67ll_punch_log_result.punch_user AS punch_user,
	fx67ll_punch_log_result.punch_month AS punch_month,
	fx67ll_punch_log_result.punch_day AS punch_day,
	IF(fx67ll_punch_log_result.punch_type = '2',
	'上班缺卡',
	'下班缺卡') AS lost_punch_type
FROM
	(
	SELECT
		punch_type AS punch_type,
		update_by AS punch_user,
		DATE_FORMAT(update_time, '%Y-%m') AS punch_month,
		DATE(update_time) AS punch_day,
		IF(punch_type = '2',
		MAX(update_time),
		MIN(update_time)) AS punch_time
	FROM
		fx67ll_punch_log
	GROUP BY
		punch_type,
		punch_user,
		punch_month,
		punch_day
	) 
AS fx67ll_punch_log_result
GROUP BY 
	punch_user,
	punch_day
HAVING
	COUNT(CASE WHEN punch_type = '1' THEN 1 END) = 0
	OR COUNT(CASE WHEN punch_type = '2' THEN 1 END) = 0;
```

我是 [fx67ll.com](https://fx67ll.com)，如果您发现本文有什么错误，欢迎在评论区讨论指正，感谢您的阅读！  
如果您喜欢这篇文章，欢迎访问我的 [本文github仓库地址](https://github.com/fx67ll/fx67llJava/blob/main/java-blog/2024/2024-05/sql-practice-punch.md)，为我点一颗Star，Thanks~ :)  
***转发请注明参考文章地址，非常感谢！！！***