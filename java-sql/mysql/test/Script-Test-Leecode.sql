-- 创建测试用数据库表
USE leecode_test;

-- 部门工资前三高的所有员工
DROP TABLE leecode_test.test_employee;
DROP TABLE leecode_test.test_department;

CREATE TABLE IF NOT EXISTS `test_employee`(
   `id` INT UNSIGNED AUTO_INCREMENT,
   `name` VARCHAR(100) NOT NULL,
   `salary` INT NOT NULL,
   `departmentId` INT NOT NULL,
   PRIMARY KEY ( `id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO test_employee 
( id, name, salary, departmentId)
VALUES
( 1, "Joe", 85000, 1),
( 2, "Henry", 80000, 2),
( 3, "Sam", 60000, 2),
( 4, "Max", 90000, 1),
( 5, "Janet", 69000, 1),
( 6, "Randy", 85000, 1),
( 7, "Will", 70000, 1);

CREATE TABLE IF NOT EXISTS `test_department`(
   `id` INT UNSIGNED AUTO_INCREMENT,
   `name` VARCHAR(100) NOT NULL,
   PRIMARY KEY ( `id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO test_department 
( id, name)
VALUES
( 1, "IT"),
( 2, "Sales");

SELECT * FROM test_employee;
SELECT * FROM test_department;


-- 游戏玩法分析 V
DROP TABLE leecode_test.test_activity;

CREATE TABLE IF NOT EXISTS `test_activity`(
   `id` INT UNSIGNED AUTO_INCREMENT,
   `player_id` INT NOT NULL,
   `device_id` INT NOT NULL,
   `event_date` VARCHAR(100) NOT NULL,
   `games_played` INT NOT NULL,
   PRIMARY KEY ( `id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO test_activity 
( id, player_id, device_id, event_date, games_played)
VALUES
( 1, 1, 2, "2016-03-01", 5),
( 2, 1, 2, "2016-03-02", 6),
( 3, 2, 3, "2017-06-25", 1),
( 4, 3, 1, "2016-03-01", 0),
( 5, 3, 4, "2016-07-03", 5),
( 6, 4, 5, "2016-03-02", 4),
( 7, 4, 6, "2016-03-03", 3),
( 8, 4, 7, "2016-03-04", 2),
( 9, 6, 5, "2016-04-09", 1),
( 10, 5, 5, "2016-06-03", 4),
( 11, 5, 6, "2016-06-02", 3),
( 12, 5, 7, "2016-06-01", 2),
( 13, 6, 5, "2016-04-10", 1),
( 14, 7, 5, "2016-04-09", 4),
( 15, 7, 6, "2016-04-11", 3),
( 16, 8, 7, "2016-04-10", 2),
( 17, 8, 5, "2016-04-09", 1),
( 18, 55, 88, "2019-01-07", 77),
( 19, 83, 146, "2019-01-07", 47),
( 20, 29, 12, "2019-01-07", 70),
( 21, 95, 111, "2019-01-07", 63),
( 22, 93, 115, "2019-01-07", 5),
( 23, 77, 45, "2019-01-07", 89),
( 24, 15, 162, "2019-01-07", 71),
( 25, 23, 25, "2019-01-07", 7),
( 26, 54, 187, "2019-01-07", 3),
( 27, 67, 168, "2019-01-07", 8),
( 28, 73, 193, "2019-01-07", 74),
( 29, 56, 79, "2019-01-08", 99),
( 30, 24, 134, "2019-01-08", 23),
( 31, 25, 52, "2019-01-08", 71),
( 32, 39, 174, "2019-01-08", 25),
( 33, 48, 154, "2019-01-08", 76),
( 34, 2, 36, "2019-01-08", 80),
( 35, 34, 123, "2019-01-08", 0),
( 36, 55, 56, "2019-01-08", 5),
( 37, 96, 133, "2019-01-08", 76),
( 38, 67, 4, "2019-01-08", 32),
( 39, 22, 32, "2019-01-08", 34),
( 40, 78, 8, "2019-01-08", 85);

SELECT * FROM test_activity;


-- 体育馆的人流量 
DROP TABLE leecode_test.test_stadium;

CREATE TABLE IF NOT EXISTS `test_stadium`(
   `id` INT UNSIGNED AUTO_INCREMENT,
   `visit_date` VARCHAR(100) NOT NULL,
   `people` INT NOT NULL,
   PRIMARY KEY ( `id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO test_stadium 
( id, visit_date, people)
VALUES
( 1, "2017-01-01", 10),
( 2, "2017-01-02", 109),
( 3, "2017-01-03", 150),
( 4, "2017-01-04", 99),
( 5, "2017-01-05", 145),
( 6, "2017-01-06", 1455),
( 7, "2017-01-07", 199),
( 8, "2017-01-09", 188);

SELECT * FROM test_stadium;

WITH t1 AS(
SELECT *,
		(id - ROW_NUMBER() OVER()) AS id_temp
FROM test_stadium
WHERE people >= 100
),
t2 AS(
SELECT id_temp
FROM t1
GROUP BY id_temp
HAVING COUNT(id) >= 3
),
t3 AS(
SELECT *
FROM t1
WHERE id_temp IN (SELECT * FROM t2)
)
SELECT id,
        visit_date,
        people
FROM t3;


-- 找出每个公司的工资中位数
DROP TABLE leecode_test.test_company;

CREATE TABLE IF NOT EXISTS `test_company`(
   `id` INT UNSIGNED AUTO_INCREMENT,
   `company` VARCHAR(100) NOT NULL,
   `salary` INT NOT NULL,
   PRIMARY KEY ( `id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO test_company 
( id, company, salary)
VALUES
( 1, "A", 2341),
( 2, "A", 341),
( 3, "A", 15),
( 4, "A", 15341),
( 5, "A", 451),
( 6, "A", 513),
( 7, "B", 15),
( 8, "B", 13),
( 9, "B", 1154),
( 10, "B", 1345),
( 11, "B", 1221),
( 12, "B", 234),
( 13, "C", 2345),
( 14, "C", 2645),
( 15, "C", 2645),
( 16, "C", 2652),
( 17, "C", 65);

SELECT * FROM test_company;

WITH t1 AS(
SELECT *,
        ROW_NUMBER() OVER(PARTITION BY company ORDER BY salary) AS temp_rank
FROM test_company
),
t2 AS(
SELECT *,
		COUNT(*) AS count_rank
FROM t1
GROUP BY company 
)
SELECT t1.id,
		t1.company,
		t1.salary
FROM t1 RIGHT JOIN t2
ON t1.company = t2.company
AND t1.temp_rank BETWEEN t2.count_rank/2 AND t2.count_rank/2 + 1;
-- AND t1.temp_rank IN (count_rank/2, count_rank/2+1, count_rank/2+0.5);

WITH t1 AS(
SELECT *,
        ROW_NUMBER() OVER(PARTITION BY company ORDER BY salary) AS temp_rank
FROM test_company
),
t2 AS(
SELECT *,
		COUNT(*) AS count_rank
FROM t1
GROUP BY company 
)
SELECT t1.id,
		t1.company,
		t1.salary
FROM t1, t2
WHERE t1.company = t2.company
AND t1.temp_rank BETWEEN t2.count_rank/2 AND t2.count_rank/2 + 1;
-- AND t1.temp_rank IN (count_rank/2, count_rank/2+1, count_rank/2+0.5);

WITH t1 AS(
SELECT *,
        ROW_NUMBER() OVER(PARTITION BY company ORDER BY salary) AS temp_rank,
        COUNT(salary) OVER(PARTITION BY company) AS count_rank
FROM test_company
)
SELECT id,company,salary 
FROM t1 WHERE temp_rank IN (count_rank/2, count_rank/2+1, count_rank/2+0.5);
-- FROM t1 WHERE temp_rank BETWEEN count_rank/2 AND count_rank/2 + 1;

WITH t1 AS(
SELECT table_test.*,
		(@i:=CASE WHEN @company_pre=table_test.company THEN @i+1 ELSE 1 END) AS temp_rank,
		(@company_pre:=company) AS company_rank
FROM test_company AS table_test, 
(SELECT @i:=0, @company_pre:='') AS table_temp
GROUP BY company,id
ORDER BY company,salary DESC
),
t2 AS(
SELECT *,
		COUNT(*) AS count_company
FROM t1
GROUP BY company
)
SELECT t1.id,
		t1.company,
		t1.salary
FROM t1, t2
WHERE t1.company = t2.company
AND t1.temp_rank BETWEEN t2.count_company/2 AND t2.count_company/2 + 1;


-- 每次访问的交易次数
DROP TABLE leecode_test.test_visit;
DROP TABLE leecode_test.test_transaction;

CREATE TABLE IF NOT EXISTS `test_visit`(
   `id` INT UNSIGNED AUTO_INCREMENT,
   `user_id` INT NOT NULL,
   `visit_date` VARCHAR(100) NOT NULL,
   PRIMARY KEY ( `id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO test_visit 
( id, user_id, visit_date)
VALUES
( 1, 1, "2020-01-01"),
( 2, 2, "2020-01-02"),
( 3, 12, "2020-01-01"),
( 4, 19, "2020-01-03"),
( 5, 1, "2020-01-02"),
( 6, 2, "2020-01-03"),
( 7, 1, "2020-01-04"),
( 8, 7, "2020-01-11"),
( 9, 9, "2020-01-25"),
( 10, 8, "2020-01-28");

CREATE TABLE IF NOT EXISTS `test_transaction`(
   `id` INT UNSIGNED AUTO_INCREMENT,
   `user_id` INT NOT NULL,
   `transaction_date` VARCHAR(100) NOT NULL,
   `amount` INT NOT NULL,
   PRIMARY KEY ( `id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO test_transaction 
( id, user_id, transaction_date, amount)
VALUES
( 1, 1, "2020-01-02", 120),
( 2, 2, "2020-01-03", 22),
( 3, 7, "2020-01-11", 232),
( 4, 1, "2020-01-04", 7),
( 5, 9, "2020-01-25", 33),
( 6, 9, "2020-01-25", 66),
( 7, 8, "2020-01-28", 1),
( 8, 9, "2020-01-25", 99);

SELECT * FROM test_visit;
SELECT * FROM test_transaction;

WITH t1 AS(
SELECT t1.user_id,
		t1.visit_date,
		t2.transaction_date,
		t2.amount
FROM test_visit AS t1 LEFT JOIN test_transaction AS t2
ON t1.user_id = t2.user_id
AND t1.visit_date = t2.transaction_date
),
t2 AS(
SELECT *,
		COUNT(*) OVER(PARTITION BY transaction_date) AS transactions_count
FROM t1
)
SELECT * FROM t2;












