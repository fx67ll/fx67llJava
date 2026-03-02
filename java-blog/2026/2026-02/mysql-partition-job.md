# MySQL 分区表 + Java 定时任务 实战：基于若依架构的 API 调用日志系统优化

## 引言

在AI服务调用日益频繁的业务场景中，`fx67ll_ai_request_log`作为记录每一次AI请求的明细日志表，会随着时间推移积累海量数据。日调用量达到十万级别时，半年后单表数据量轻松突破千万甚至上亿。此时，针对时间范围的查询（如统计某个月的token消耗）会因全表扫描变得极其缓慢，严重影响前端报表的响应速度，甚至拖累主业务。

为了解决这一问题，我们引入两大优化方案：
1. **按`request_time`字段进行月份分区**：将数据物理拆分到不同分区，查询时仅扫描对应分区。
2. **定时任务生成统计数据**：将海量明细数据的实时统计转换为离线预计算，结果存入日/月/年统计表，前端查询毫秒级响应。

本文结合若依（SpringBoot+MySQL）架构，详细讲解这两个方案的具体实现逻辑、操作步骤以及生产环境落地的自动化保障措施。

---

## 一、优化1：fx67ll_ai_request_log 按 request_time 月份分区

### 1.1 什么是月份分区表？

MySQL分区表在逻辑上仍是一张表，但物理存储上根据指定的规则（如`RANGE`、`LIST`、`HASH`）将数据分散到多个物理文件中。我们采用**RANGE分区**，以`request_time`的日期值作为分区依据，每个月的数据独立存放。查询时，优化器会自动过滤掉无关分区，只扫描必要分区，极大提升查询效率。

### 1.2 为什么要做这个优化？

- **查询性能提升**：统计某月的token用量时，普通表需扫描全表（可能数千万行），而分区表仅扫描对应月份分区（约几十万行），效率提升10倍以上。
- **维护便捷**：删除半年以上的历史数据，只需`DROP PARTITION`，瞬间释放磁盘空间，远快于`DELETE`操作。
- **备份灵活**：可针对单个分区进行备份，降低运维成本。

### 1.3 分区表创建步骤（基于原表结构）

#### （1）调整主键，包含分区字段

MySQL要求**分区字段必须包含在主键或唯一索引中**。原表主键为`log_id`，需改为联合主键`(log_id, request_time)`。

#### （2）创建分区表（替换原创建语句）

```sql
CREATE TABLE `fx67ll_ai_request_log` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID（主键）',
  `prompt_id` bigint(20) DEFAULT NULL COMMENT '使用的模板ID',
  `scene_id` bigint(20) DEFAULT NULL COMMENT '关联场景ID',
  `model_id` bigint(20) NOT NULL COMMENT '调用的模型ID',
  `model_vendor` varchar(30) NOT NULL COMMENT '模型厂商',
  `request_content` text DEFAULT '' COMMENT '请求内容',
  `response_content` text DEFAULT '' COMMENT '响应内容',
  `prompt_tokens` int(11) DEFAULT 0 COMMENT '输入token数',
  `completion_tokens` int(11) DEFAULT 0 COMMENT '输出token数',
  `total_tokens` int(11) DEFAULT 0 COMMENT '总token数',
  `cost` decimal(10,6) DEFAULT 0.000000 COMMENT '预估费用',
  `duration_ms` int(11) DEFAULT 0 COMMENT '请求耗时',
  `http_status` int(3) DEFAULT NULL COMMENT 'HTTP状态码',
  `call_status` char(2) DEFAULT '00' COMMENT '调用状态（00:成功 01:失败 02:限流 03:熔断）',
  `error_msg` text DEFAULT '' COMMENT '错误信息',
  `caller_ip` varchar(32) DEFAULT '' COMMENT '调用者IP',
  `request_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '请求时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '调用者标识',
  PRIMARY KEY (`log_id`, `request_time`)   -- 分区字段必须包含在主键中
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
PARTITION BY RANGE (TO_DAYS(request_time)) ( 
  PARTITION p202602 VALUES LESS THAN (TO_DAYS('2026-03-01')), -- 2026年2月
  PARTITION p202603 VALUES LESS THAN (TO_DAYS('2026-04-01')), -- 2026年3月
  PARTITION p202604 VALUES LESS THAN (TO_DAYS('2026-05-01')), -- 2026年4月
  PARTITION p_default VALUES LESS THAN MAXVALUE               -- 默认分区（防止数据落入异常）
) COMMENT='AI调用请求日志表（按request_time月份分区）';

-- 保留原有索引（分区表自动适配）
ALTER TABLE `fx67ll_ai_request_log` 
ADD KEY `idx_request_time` (`request_time`),
ADD KEY `idx_prompt_id` (`prompt_id`),
ADD KEY `idx_scene_id` (`scene_id`),
ADD KEY `idx_model_id` (`model_id`),
ADD KEY `idx_create_by` (`create_by`),
ADD KEY `idx_call_status` (`call_status`),
ADD KEY `idx_request_time_vendor` (`request_time`, `model_vendor`),
ADD KEY `idx_scene_model_time` (`scene_id`, `model_id`, `request_time`),
ADD KEY `idx_create_by_time` (`create_by`, `request_time`);
```

#### （3）分区维护（手动示例）

- **新增分区**（月底前创建下月分区）：
  ```sql
  -- 删除默认分区（临时）
  ALTER TABLE fx67ll_ai_request_log DROP PARTITION p_default;
  -- 创建2026年5月分区
  ALTER TABLE fx67ll_ai_request_log ADD PARTITION (
    PARTITION p202605 VALUES LESS THAN (TO_DAYS('2026-06-01'))
  );
  -- 重建默认分区
  ALTER TABLE fx67ll_ai_request_log ADD PARTITION (
    PARTITION p_default VALUES LESS THAN MAXVALUE
  );
  ```

- **删除历史分区**（如删除6个月前数据）：
  ```sql
  ALTER TABLE fx67ll_ai_request_log DROP PARTITION p202602;
  ```

#### （4）查询优势示例

```sql
-- 统计2026年3月某模型的token消耗
SELECT model_id, SUM(total_tokens) AS total 
FROM fx67ll_ai_request_log 
WHERE request_time BETWEEN '2026-03-01 00:00:00' AND '2026-03-31 23:59:59'
  AND model_id = 1001;
-- 执行计划会显示只扫描p202603分区
```

### 1.4 注意事项

- 分区字段`request_time`必须包含在主键中（MySQL限制）。
- 跨分区查询（如2月至4月）性能仍优于全表扫描，但尽量缩小时间范围。
- 若使用MyBatis/MyBatis-Plus，无需修改代码，SQL完全兼容。

---

## 二、分区自动化创建：告别手动维护

### 2.1 为什么需要自动化？

手动每月创建分区存在巨大风险：
- 可能遗忘创建，导致新数据落入`p_default`默认分区，后续查询无法享受分区剪枝优势；
- 操作失误（如分区名写错、临界值算错）可能导致数据存储异常；
- 增加运维负担，无法应对快速发展的业务。

生产环境必须实现分区自动创建，核心原则：
- **提前创建**：每月提前5-7天创建下月分区（如25号），留足缓冲；
- **幂等性**：创建前检查分区是否已存在，避免重复执行报错；
- **可监控**：失败时及时告警。

### 2.2 方案一：SpringBoot定时任务（推荐，贴合若依架构）

利用若依框架自带的`@Scheduled`定时任务能力，将分区创建与业务统计任务整合，统一监控。

#### （1）Mapper接口扩展

在`AiRequestLogMapper`中添加检查分区是否存在和执行DDL的方法：

```java
public interface AiRequestLogMapper {
    // ... 其他方法

    /**
     * 检查分区是否已存在
     * @param tableName 表名
     * @param partitionName 分区名（如p202603）
     * @return 存在返回1，不存在返回0
     */
    @Select("SELECT COUNT(*) FROM information_schema.PARTITIONS " +
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = #{tableName} AND PARTITION_NAME = #{partitionName}")
    int checkPartitionExists(@Param("tableName") String tableName, @Param("partitionName") String partitionName);

    /**
     * 执行分区创建的原生SQL（动态SQL）
     * @param sql 要执行的DDL语句
     */
    @Update({"${sql}"})
    void executePartitionSql(@Param("sql") String sql);
}
```

#### （2）定时任务类：自动创建下月分区

在原有的统计任务类中新增方法（复用若依的定时任务配置，`@EnableScheduling`已默认开启）：

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import javax.annotation.Resource;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Slf4j
@Component
public class AiRequestStatTask {

    @Resource
    private AiRequestLogMapper aiRequestLogMapper;

    private static final String TABLE_NAME = "fx67ll_ai_request_log";

    /**
     * 每月25号凌晨3点执行：自动创建下月的分区
     * cron = "0 0 3 25 * ?"
     */
    @Scheduled(cron = "0 0 3 25 * ?")
    public void autoCreateNextMonthPartition() {
        log.info("开始执行AI日志表自动创建下月分区任务");
        try {
            LocalDate now = LocalDate.now();
            LocalDate nextMonth = now.plusMonths(1);       // 下月
            LocalDate nextNextMonth = nextMonth.plusMonths(1); // 下下月（临界值）

            String partitionName = "p" + nextMonth.format(DateTimeFormatter.ofPattern("yyyyMM"));
            String partitionLimitDate = nextNextMonth.format(DateTimeFormatter.ISO_DATE); // yyyy-MM-dd
            String partitionLimitSql = "TO_DAYS('" + partitionLimitDate + "')";

            // 检查分区是否已存在
            int exists = aiRequestLogMapper.checkPartitionExists(TABLE_NAME, partitionName);
            if (exists > 0) {
                log.info("下月分区{}已存在，无需重复创建", partitionName);
                return;
            }

            // 执行分区创建：删默认分区 → 建下月分区 → 重建默认分区
            aiRequestLogMapper.executePartitionSql("ALTER TABLE " + TABLE_NAME + " DROP PARTITION p_default");
            String createSql = String.format(
                "ALTER TABLE %s ADD PARTITION (PARTITION %s VALUES LESS THAN (%s))",
                TABLE_NAME, partitionName, partitionLimitSql
            );
            aiRequestLogMapper.executePartitionSql(createSql);
            aiRequestLogMapper.executePartitionSql("ALTER TABLE " + TABLE_NAME + " ADD PARTITION (PARTITION p_default VALUES LESS THAN MAXVALUE)");

            log.info("AI日志表下月分区{}创建成功，临界值：{}", partitionName, partitionLimitDate);
        } catch (Exception e) {
            log.error("AI日志表自动创建分区任务执行失败", e);
            // 调用告警服务（若依可集成钉钉/企业微信）
            // alarmService.sendAlarm("AI日志表分区创建失败", e.getMessage());
        }
    }
}
```

#### （3）拓展：自动删除历史分区（保留6个月数据）

每月1号凌晨执行，删除6个月前的分区：

```java
/**
 * 每月1号凌晨4点执行：删除6个月前的历史分区（保留6个月日志）
 * cron = "0 0 4 1 * ?"
 */
@Scheduled(cron = "0 0 4 1 * ?")
public void autoDeleteHistoryPartition() {
    log.info("开始执行AI日志表自动删除历史分区任务");
    try {
        LocalDate delMonth = LocalDate.now().minusMonths(6);
        String partitionName = "p" + delMonth.format(DateTimeFormatter.ofPattern("yyyyMM"));

        int exists = aiRequestLogMapper.checkPartitionExists(TABLE_NAME, partitionName);
        if (exists > 0) {
            aiRequestLogMapper.executePartitionSql("ALTER TABLE " + TABLE_NAME + " DROP PARTITION " + partitionName);
            log.info("历史分区{}删除成功", partitionName);
        } else {
            log.info("历史分区{}不存在，无需删除", partitionName);
        }
    } catch (Exception e) {
        log.error("AI日志表自动删除历史分区任务失败", e);
        // alarmService.sendAlarm("AI日志表分区删除失败", e.getMessage());
    }
}
```

### 2.3 方案二：MySQL事件调度器（纯数据库实现）

适合无代码侵入、DBA主导的场景。需开启MySQL事件调度器。

#### （1）创建存储过程

```sql
DELIMITER //
CREATE PROCEDURE auto_create_ai_log_partition()
BEGIN
    DECLARE table_name VARCHAR(50) DEFAULT 'fx67ll_ai_request_log';
    DECLARE next_month VARCHAR(6);
    DECLARE next_next_month_date VARCHAR(10);
    DECLARE partition_name VARCHAR(20);
    DECLARE partition_count INT DEFAULT 0;

    SET next_month = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y%m');
    SET next_next_month_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 2 MONTH), '%Y-%m-01');
    SET partition_name = CONCAT('p', next_month);

    SELECT COUNT(*) INTO partition_count
    FROM information_schema.PARTITIONS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = table_name AND PARTITION_NAME = partition_name;

    IF partition_count = 0 THEN
        SET @sql = CONCAT('ALTER TABLE ', table_name, ' DROP PARTITION p_default');
        PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

        SET @sql = CONCAT('ALTER TABLE ', table_name, ' ADD PARTITION (PARTITION ', partition_name, 
                          ' VALUES LESS THAN (TO_DAYS(\'', next_next_month_date, '\')))');
        PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

        SET @sql = CONCAT('ALTER TABLE ', table_name, ' ADD PARTITION (PARTITION p_default VALUES LESS THAN MAXVALUE)');
        PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

        -- 可写入操作日志表
        INSERT INTO sys_oper_log (title, business_type, oper_type, oper_content, create_time)
        VALUES ('AI日志表分区自动创建', 1, 1, CONCAT('创建分区：', partition_name), NOW());
    END IF;
END //
DELIMITER ;
```

#### （2）创建定时事件（每月25号3点执行）

```sql
CREATE EVENT IF NOT EXISTS event_ai_log_auto_create_partition
ON SCHEDULE EVERY 1 MONTH
STARTS DATE_ADD(DATE_FORMAT(CURDATE(), '%Y-%m-25'), INTERVAL 3 HOUR)
DO
CALL auto_create_ai_log_partition();

ALTER EVENT event_ai_log_auto_create_partition ENABLE;
```

#### （3）维护命令

```sql
SHOW EVENTS;                         -- 查看事件
ALTER EVENT event_xxx DISABLE;       -- 关闭事件
DROP EVENT event_xxx;                -- 删除事件
```

### 2.4 方案对比与选型建议

| 特性                | 方案1：SpringBoot定时任务        | 方案2：MySQL事件调度器          |
|---------------------|----------------------------------|--------------------------------|
| 技术栈贴合度        | 极高（复用若依体系）             | 低（纯数据库，与代码解耦）      |
| 维护成本            | 低（开发统一维护）               | 中（需DBA维护MySQL事件）       |
| 监控能力            | 强（若依定时任务监控+告警）      | 弱（需额外监控事件执行状态）    |
| 侵入性              | 低（仅新增Mapper+方法）          | 无（纯数据库）                 |
| 跨库适配性          | 强（支持多数据源）               | 弱（单库生效）                 |

**推荐采用方案1**：完全贴合若依架构，可与现有的统计任务整合，利用若依的定时任务监控页面查看执行状态、失败告警，且便于扩展多数据源场景。

### 2.5 生产兜底措施

- **默认分区保底**：始终保留`p_default`分区，即使自动创建任务失败，新数据也能正常插入（后续人工处理后可迁移数据）。
- **分区状态监控**：在若依监控中增加数据库分区检查，若发现下月分区未创建，及时告警。
- **手动重试机制**：若依的定时任务支持手动执行，分区创建失败后可人工触发。

---

## 三、优化2：定时任务生成统计数据（日/月/年）

### 3.1 为什么需要定时统计？

直接对亿级明细日志表执行`SUM`、`COUNT`等聚合查询，会导致：
- 响应缓慢（数秒至数十秒），前端报表用户体验差；
- 高并发下大量计算占用数据库IO和CPU，影响AI调用的主业务。

解决方案：通过定时任务（每日凌晨）预统计前一天的数据，将结果存入轻量级的日统计表；再基于日统计表生成月/年统计，前端查询直接读取统计表，实现毫秒级响应。

### 3.2 统计表设计

- **日统计表** `fx67ll_ai_request_daily_log`：按`daily_log_date`（日期）、`model_id`、`scene_id`聚合，存储调用次数、token数、费用等。
- **月统计表** `fx67ll_ai_request_monthly_log`：按月聚合，数据来自日统计表。
- **年统计表** `fx67ll_ai_request_yearly_log`：按年聚合，数据来自月统计表。

（表结构略，可根据实际需求设计）

### 3.3 日统计定时任务实现

#### （1）若依定时任务配置（已默认开启）

```java
@Configuration
@EnableScheduling
public class ScheduleConfig {
}
```

#### （2）日统计任务代码

```java
@Component
@Slf4j
public class AiRequestStatTask {

    @Resource
    private AiRequestLogMapper aiRequestLogMapper;
    @Resource
    private AiRequestDailyLogMapper aiRequestDailyLogMapper;

    /**
     * 每日凌晨1点执行：统计前一天的AI调用数据
     * cron = "0 0 1 * * ?"
     */
    @Scheduled(cron = "0 0 1 * * ?")
    @Transactional(rollbackFor = Exception.class)
    public void statDailyData() {
        log.info("开始执行日统计任务");
        try {
            LocalDate yesterday = LocalDate.now().minusDays(1);
            String yesterdayStr = yesterday.format(DateTimeFormatter.ISO_DATE);
            String startTime = yesterdayStr + " 00:00:00";
            String endTime = yesterdayStr + " 23:59:59";

            // 幂等性：删除该日期已有的统计数据（避免重复执行导致数据翻倍）
            aiRequestDailyLogMapper.deleteByDate(yesterdayStr);

            // 从明细表汇总
            List<DailyStatDTO> statList = aiRequestLogMapper.statDailyData(startTime, endTime);
            if (statList != null && !statList.isEmpty()) {
                for (DailyStatDTO dto : statList) {
                    AiRequestDailyLog dailyLog = new AiRequestDailyLog();
                    dailyLog.setDailyLogDate(yesterday);
                    dailyLog.setModelId(dto.getModelId());
                    dailyLog.setSceneId(dto.getSceneId());
                    dailyLog.setTotalRequests(dto.getTotalRequests());
                    dailyLog.setFailRequests(dto.getFailRequests());
                    dailyLog.setLimitRequests(dto.getLimitRequests());
                    dailyLog.setCircuitRequests(dto.getCircuitRequests());
                    dailyLog.setTotalPromptTokens(dto.getTotalPromptTokens());
                    dailyLog.setTotalCompletionTokens(dto.getTotalCompletionTokens());
                    dailyLog.setTotalCost(dto.getTotalCost());
                    dailyLog.setAvgDurationMs(dto.getTotalDurationMs() / dto.getTotalRequests());
                    aiRequestDailyLogMapper.insert(dailyLog);
                }
            }
            log.info("日统计任务执行完成，日期：{}", yesterdayStr);
        } catch (Exception e) {
            log.error("日统计任务执行失败", e);
            // 告警通知
        }
    }
}
```

#### （3）MyBatis映射文件（统计SQL）

```xml
<!-- AiRequestLogMapper.xml -->
<select id="statDailyData" resultType="com.xxx.dto.DailyStatDTO">
    SELECT 
        model_id,
        scene_id,
        COUNT(*) AS total_requests,
        SUM(CASE WHEN call_status = '01' THEN 1 ELSE 0 END) AS fail_requests,
        SUM(CASE WHEN call_status = '02' THEN 1 ELSE 0 END) AS limit_requests,
        SUM(CASE WHEN call_status = '03' THEN 1 ELSE 0 END) AS circuit_requests,
        SUM(prompt_tokens) AS total_prompt_tokens,
        SUM(completion_tokens) AS total_completion_tokens,
        SUM(cost) AS total_cost,
        SUM(duration_ms) AS total_duration_ms
    FROM fx67ll_ai_request_log
    WHERE request_time BETWEEN #{startTime} AND #{endTime}
    GROUP BY model_id, scene_id
</select>
```

```xml
<!-- AiRequestDailyLogMapper.xml -->
<delete id="deleteByDate">
    DELETE FROM fx67ll_ai_request_daily_log
    WHERE daily_log_date = #{date}
</delete>
```

### 3.4 月/年统计任务

月统计任务在每月1日凌晨2点执行，汇总上月的日统计数据；年统计在每年1月1日凌晨执行。代码结构与日统计类似，只需修改时间范围和来源表。

**月统计核心SQL示例**（从日统计表聚合）：

```sql
SELECT 
    DATE_FORMAT(daily_log_date, '%Y-%m') AS stat_month,
    model_id,
    scene_id,
    SUM(total_requests) AS total_requests,
    SUM(total_prompt_tokens) AS total_prompt_tokens,
    SUM(total_cost) AS total_cost
FROM fx67ll_ai_request_daily_log
WHERE daily_log_date BETWEEN #{startDate} AND #{endDate}
GROUP BY stat_month, model_id, scene_id
```

### 3.5 注意事项

- **幂等性**：统计前先删除目标日期/月份的数据，保证任务可重复执行而不产生重复记录。
- **事务**：统计方法添加`@Transactional`，确保写入一致性。
- **执行时间**：选择业务低峰期（凌晨），避免影响主业务。
- **异常监控**：任务内捕获异常，记录日志并触发告警（若依支持集成钉钉、邮件等）。

---

## 四、总结与落地建议

### 4.1 两大优化方案的核心价值

- **月份分区表**：从根本上解决了海量明细日志的查询性能问题，将查询范围从全表缩小到单月分区；同时简化了历史数据清理操作。
- **定时任务统计数据**：将实时聚合转化为离线预计算，避免高频聚合查询拖垮数据库，前端报表响应速度从秒级降至毫秒级。

### 4.2 落地优先级建议

1. **首先实施分区表**：创建分区表并迁移历史数据（可使用`ALTER TABLE ... REORGANIZE PARTITION`或`pt-online-schema-change`工具），同时实现分区自动化创建。
2. **然后实现日统计任务**：先建立日统计表，每日凌晨统计前一日数据，支撑近期的报表需求。
3. **最后扩展月/年统计**：基于日统计表聚合生成月/年统计，满足长期成本核算和趋势分析。

### 4.3 整体收益

- 查询性能提升10倍以上，用户体验大幅改善。
- 数据库负载降低，主业务稳定性得到保障。
- 运维自动化，减少人工操作风险，释放开发/运维精力。

通过以上两个优化，你的AI日志系统将具备处理亿级数据的能力，为业务快速增长打下坚实基础。

---

**附：若依框架定时任务监控**  
在若依管理后台的“系统监控”→“定时任务”中，可查看所有`@Scheduled`任务的执行记录，支持手动执行一次、暂停、恢复等操作，极大方便了生产维护。

希望本文能帮助你顺利落地MySQL分区表与定时统计任务，如有疑问或需要进一步探讨，欢迎交流！


我是 [fx67ll.com](https://fx67ll.com)，如果您发现本文有什么错误，欢迎在评论区讨论指正，感谢您的阅读！
如果您喜欢这篇文章，欢迎访问我的 [本文 github 仓库地址](https://github.com/fx67ll/fx67llJava/blob/main/java-blog/2026/2026-02/mysql-partition-job)，为我点一颗 Star，Thanks~ :)
***转发请注明参考文章地址，非常感谢！！！***
