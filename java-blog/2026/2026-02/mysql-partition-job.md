# MySQL 分区表 + Java 定时任务 ——> 实战

### 核心需求复述
你希望我详细讲解针对 `fx67ll_ai_request_log` 日志表开启**按request_time月份分区**，以及通过**定时任务生成统计数据**这两个优化方案的具体实现逻辑、操作步骤和核心价值，并且结合你使用的「若依（SpringBoot+MySQL）」架构给出落地建议。

---

## 一、优化1：fx67ll_ai_request_log 按 request_time 月份分区
### 1. 什么是「按月份分区表」？
可以把普通数据表理解成一个“大文件柜”，所有日志都堆在一起；而**分区表**是把这个大文件柜按「月份」拆成多个“小抽屉”（每个月一个抽屉），查询时只需要打开对应月份的抽屉，不用遍历整个文件柜。
MySQL的分区表是在逻辑上还是一张表，但物理存储上按指定字段（这里是`request_time`）拆分成多个分区文件，核心适配「按时间范围查询日志」的高频场景（比如查2026年3月的AI调用日志）。

### 2. 为什么要做这个优化？
你的`fx67ll_ai_request_log`是**细节日志表**，会存储每一次AI调用的全量信息，随着调用量增加（比如日调用10万次，半年就是1800万条），会出现以下问题：
- 普通表：查询“某月份的token消耗”时，需要扫描全表索引，耗时极长；
- 分区表：仅扫描对应月份的分区，查询效率提升10倍以上；
- 额外优势：维护方便（比如删除1年前的日志，直接删除对应分区即可，无需delete全表）。

### 3. 具体实现步骤（MySQL + 原表结构）
#### （1）前提条件
- MySQL版本 ≥ 5.5（推荐5.7+/8.0+），且`fx67ll_ai_request_log`使用`InnoDB`引擎（你的表已满足）；
- 分区字段`request_time`必须是`datetime`/`timestamp`类型（你的表已满足）。

#### （2）创建带月份分区的日志表（替换原创建语句）
```sql
CREATE TABLE `fx67ll_ai_request_log` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID（主键）',
  `prompt_id` bigint(20) DEFAULT NULL COMMENT '使用的模板ID（可为空，若直接调用非模板）',
  `scene_id` bigint(20) DEFAULT NULL COMMENT '关联场景ID',
  `model_id` bigint(20) NOT NULL COMMENT '调用的模型ID',
  `model_vendor` varchar(30) NOT NULL COMMENT '模型厂商（冗余存储，避免关联查询）',
  `request_content` text DEFAULT '' COMMENT '请求内容（含最终渲染后的Prompt）',
  `response_content` text DEFAULT '' COMMENT '响应内容（大文本存储）',
  `prompt_tokens` int(11) DEFAULT 0 COMMENT '输入token数',
  `completion_tokens` int(11) DEFAULT 0 COMMENT '输出token数',
  `total_tokens` int(11) DEFAULT 0 COMMENT '总token数',
  `cost` decimal(10,6) DEFAULT 0.000000 COMMENT '预估费用（元）',
  `duration_ms` int(11) DEFAULT 0 COMMENT '请求耗时（毫秒）',
  `http_status` int(3) DEFAULT NULL COMMENT 'HTTP状态码',
  `call_status` char(2) DEFAULT '00' COMMENT '调用状态（00:成功 01:失败 02:限流 03:熔断）',
  `error_msg` text DEFAULT '' COMMENT '错误信息',
  `caller_ip` varchar(32) DEFAULT '' COMMENT '调用者IP',
  `request_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '请求时间（精确到秒）',
  `create_by` varchar(64) DEFAULT '' COMMENT '调用者标识',
  PRIMARY KEY (`log_id`, `request_time`) -- 分区字段必须包含在主键/唯一索引中
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
PARTITION BY RANGE (TO_DAYS(request_time)) ( -- 按request_time的日期值分区
  PARTITION p202602 VALUES LESS THAN (TO_DAYS('2026-03-01')), -- 2026年2月
  PARTITION p202603 VALUES LESS THAN (TO_DAYS('2026-04-01')), -- 2026年3月
  PARTITION p202604 VALUES LESS THAN (TO_DAYS('2026-05-01')), -- 2026年4月
  PARTITION p_default VALUES LESS THAN MAXVALUE -- 默认分区（防止未提前创建月份分区）
) COMMENT='AI 调用请求日志表（按request_time月份分区）';

-- 保留原索引（分区表索引会自动适配分区）
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

#### （3）分区维护（关键！避免分区溢出）
- **新增月份分区**：每月底提前创建下一个月的分区（比如2026年3月底创建p202604），示例SQL：
  ```sql
  -- 先删除默认分区（避免冲突）
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
- **归档/删除历史分区**：比如删除6个月前的日志，直接删除分区（比DELETE快100倍）：
  ```sql
  ALTER TABLE fx67ll_ai_request_log DROP PARTITION p202602;
  ```

#### （4）分区表的查询优势
查询2026年3月的日志时，MySQL会自动只扫描p202603分区，示例SQL：
```sql
-- 统计2026年3月某模型的token消耗
SELECT model_id, SUM(total_tokens) AS total 
FROM fx67ll_ai_request_log 
WHERE request_time BETWEEN '2026-03-01 00:00:00' AND '2026-03-31 23:59:59'
AND model_id = 1001;
```

### 4. 注意事项
- 分区字段`request_time`必须包含在主键中（MySQL分区表的规则），所以主键调整为`(log_id, request_time)`；
- 避免跨分区查询（比如查2026年2-4月的日志），尽量缩小时间范围；
- 若使用MyBatis/MyBatis-Plus，无需修改代码，SQL查询逻辑完全兼容。

---

## 二、优化2：定时任务生成统计数据（日/月/年）
### 1. 为什么要做定时任务统计？
如果每次前端查“某模型本月的token消耗”都直接查`fx67ll_ai_request_log`（海量细节日志），会出现：
- 实时统计需要扫描百万/千万级数据，响应慢（前端等待5+秒）；
- 高并发下多次实时统计会抢占数据库资源，导致AI调用主业务卡顿；
- 定时任务**离线统计**（比如每日凌晨1点统计前日数据），把结果写入日统计表（`fx67ll_ai_request_daily_log`），前端查询时直接查统计结果，响应时间<100ms。

### 2. 核心逻辑
- **日统计**：每日凌晨统计前一天的细节日志，汇总到`fx67ll_ai_request_daily_log`；
- **月统计**：每月1日凌晨统计上月的日统计数据，汇总到`fx67ll_ai_request_monthly_log`；
- **年统计**：每年1月1日凌晨统计上年的月统计数据，汇总到`fx67ll_ai_request_yearly_log`。

### 3. 具体实现（若依SpringBoot架构）
#### （1）定时任务配置（开启@Scheduled）
在若依框架的配置类中开启定时任务（若依默认已开启，只需添加注解）：
```java
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableScheduling
public class ScheduleConfig {
}
```

#### （2）日统计定时任务实现（核心）
```java
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import javax.annotation.Resource;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Component
public class AiRequestStatTask {

    @Resource
    private AiRequestLogMapper aiRequestLogMapper;
    @Resource
    private AiRequestDailyLogMapper aiRequestDailyLogMapper;

    /**
     * 每日凌晨1点执行：统计前一天的AI调用数据
     * cron表达式：0 0 1 * * ? （秒 分 时 日 月 周）
     */
    @Scheduled(cron = "0 0 1 * * ?")
    @Transactional(rollbackFor = Exception.class)
    public void statDailyData() {
        // 1. 获取前一天的日期（比如今天是2026-03-01，统计2026-02-29）
        LocalDate yesterday = LocalDate.now().minusDays(1);
        String yesterdayStr = yesterday.format(DateTimeFormatter.ISO_DATE);
        // 时间范围：前一天00:00:00 到 23:59:59
        String startTime = yesterdayStr + " 00:00:00";
        String endTime = yesterdayStr + " 23:59:59";

        // 2. 先删除该日期已有的统计数据（避免重复统计，保证幂等性）
        aiRequestDailyLogMapper.deleteByDate(yesterdayStr);

        // 3. 汇总前一天的细节日志数据
        AiRequestDailyLogStatDTO statDTO = aiRequestLogMapper.statDailyData(startTime, endTime);

        // 4. 写入日统计表
        if (statDTO != null && statDTO.getTotalRequests() > 0) {
            AiRequestDailyLog dailyLog = new AiRequestDailyLog();
            dailyLog.setDailyLogDate(yesterday); // 统计日期
            dailyLog.setModelId(statDTO.getModelId());
            dailyLog.setSceneId(statDTO.getSceneId());
            dailyLog.setTotalRequests(statDTO.getTotalRequests());
            dailyLog.setFailRequests(statDTO.getFailRequests());
            dailyLog.setLimitRequests(statDTO.getLimitRequests());
            dailyLog.setCircuitRequests(statDTO.getCircuitRequests());
            dailyLog.setTotalPromptTokens(statDTO.getTotalPromptTokens());
            dailyLog.setTotalCompletionTokens(statDTO.getTotalCompletionTokens());
            dailyLog.setTotalCost(statDTO.getTotalCost());
            // 计算平均耗时：总耗时/总请求数
            dailyLog.setAvgDurationMs(statDTO.getTotalDurationMs() / statDTO.getTotalRequests());
            
            aiRequestDailyLogMapper.insert(dailyLog);
        }
    }
}
```

#### （3）MyBatis映射文件（统计SQL示例）
```xml
<!-- AiRequestLogMapper.xml -->
<select id="statDailyData" resultType="com.xxx.dto.AiRequestDailyLogStatDTO">
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
    GROUP BY model_id, scene_id;
</select>

<!-- AiRequestDailyLogMapper.xml -->
<delete id="deleteByDate">
    DELETE FROM fx67ll_ai_request_daily_log
    WHERE daily_log_date = #{date};
</delete>
```

#### （4）月/年统计任务（类似日统计）
```java
/**
 * 每月1日凌晨2点执行：统计上月的日统计数据
 * cron表达式：0 0 2 1 * ?
 */
@Scheduled(cron = "0 0 2 1 * ?")
@Transactional(rollbackFor = Exception.class)
public void statMonthlyData() {
    // 1. 获取上月的年月（比如今天是2026-03-01，统计2026-02）
    LocalDate lastMonth = LocalDate.now().minusMonths(1);
    String lastMonthStr = lastMonth.format(DateTimeFormatter.ofPattern("yyyy-MM"));
    
    // 2. 删除上月已有的月统计数据
    aiRequestMonthlyLogMapper.deleteByMonth(lastMonthStr);
    
    // 3. 汇总上月的日统计数据
    List<AiRequestMonthlyLogStatDTO> statList = aiRequestDailyLogMapper.statMonthlyData(lastMonthStr);
    
    // 4. 写入月统计表（逻辑同日报表）
    for (AiRequestMonthlyLogStatDTO dto : statList) {
        AiRequestMonthlyLog monthlyLog = new AiRequestMonthlyLog();
        monthlyLog.setMonthlyLogMonth(lastMonthStr);
        monthlyLog.setModelId(dto.getModelId());
        monthlyLog.setSceneId(dto.getSceneId());
        monthlyLog.setTotalRequests(dto.getTotalRequests());
        // ... 其他字段赋值
        aiRequestMonthlyLogMapper.insert(monthlyLog);
    }
}
```

### 4. 关键注意事项
- **幂等性**：每次统计前先删除对应日期/月份的统计数据，避免重复执行（比如定时任务异常重启导致重复统计）；
- **事务控制**：统计逻辑加`@Transactional`，确保数据一致性；
- **执行时间**：选择业务低峰期（凌晨1-3点）执行，避免占用业务资源；
- **异常监控**：给定时任务加日志+告警（比如统计失败时发邮件/钉钉通知），示例：
  ```java
  try {
      // 统计逻辑
  } catch (Exception e) {
      log.error("日统计任务执行失败：{}", e.getMessage(), e);
      // 调用告警接口
      alarmService.sendAlarm("AI统计任务失败", e.getMessage());
  }
  ```

---

### 总结
#### 1. 月份分区表核心价值
- 解决海量日志的**查询性能问题**，按时间范围查询效率提升10倍以上；
- 简化日志维护，删除历史数据只需删除分区，无需全表扫描。

#### 2. 定时任务统计核心价值
- 把“实时海量计算”转为“离线预计算”，**避免主业务性能损耗**；
- 统计结果存储在轻量化的日/月/年表中，前端报表查询响应速度大幅提升；
- 统计逻辑分层（日→月→年），数据来源统一，保证统计结果准确。

#### 3. 落地优先级
先实现**月份分区表**（解决日志查询痛点），再实现**日统计定时任务**（支撑核心报表），最后扩展月/年统计（满足长期成本核算需求）。




------




## 分区表需要每月自己手动创建吗？实际生产业务中不应该自动创建吗？
你这个问题非常贴合**生产实际场景**，完全正确！生产环境中绝对不能依靠人工手动创建分区，不仅极易因遗漏、操作失误导致数据落入默认分区（破坏分区表的性能优势），还增加了运维成本，**必须实现分区的自动化创建**。

### 核心需求复述
结合你使用的**若依SpringBoot+MySQL**架构，生产中主流有**两种自动化创建分区的方案**，我会按**贴合你的技术栈、易维护、低侵入**的优先级讲解，核心是**提前创建下月分区**（比如每月25号创建下一个月的分区，留足缓冲期），同时规避重复创建、分区溢出等问题。

### 先明确核心原则
生产中分区自动化创建的核心要求：
1. **提前创建**：每月提前5-7天创建下月分区（如25号建下月），避免月底漏建；
2. **幂等性**：创建前先检查分区是否已存在，防止重复创建报错；
3. **低侵入**：结合现有架构实现（复用若依的定时任务体系，无需额外引入组件）；
4. **可监控**：添加日志+异常告警，分区创建失败能及时发现。

## 方案1：SpringBoot定时任务实现（**推荐**，贴合若依架构）
### 核心优势
和你之前实现的**日/月/年统计定时任务**整合在**同一个任务类**中，**无数据库层面的配置修改**，开发、维护、监控都和业务代码统一（若依框架自带定时任务监控，可直接复用），适合开发主导的架构。

### 实现步骤
#### 1. 核心思路
- 在原有`AiRequestStatTask`定时任务类中，新增**每月25号凌晨3点**执行的定时方法；
- 方法逻辑：**计算下月的分区名称+分区临界值** → 检查该分区是否已存在 → 若不存在则执行创建（沿用之前的「删默认分区→建下月分区→重建默认分区」逻辑）；
- 通过MyBatis执行原生SQL实现分区检查和创建（无额外依赖）。

#### 2. 新增分区检查&创建的Mapper接口（AiRequestLogMapper）
```java
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

public interface AiRequestLogMapper {
    // 其他原有方法...

    /**
     * 检查分区是否已存在
     * @param tableName 表名
     * @param partitionName 分区名（如p202603）
     * @return 存在返回1，不存在返回0
     */
    @Select("SELECT COUNT(*) FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = #{tableName} AND PARTITION_NAME = #{partitionName}")
    int checkPartitionExists(@Param("tableName") String tableName, @Param("partitionName") String partitionName);

    /**
     * 执行分区创建的原生SQL（动态SQL）
     */
    @Update({"${sql}"})
    void executePartitionSql(@Param("sql") String sql);
}
```

#### 3. 在定时任务类中新增**自动创建下月分区**的方法
复用原有统计任务的类，整合在一起，方便维护：
```java
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import javax.annotation.Resource;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
public class AiRequestStatTask {

    @Resource
    private AiRequestLogMapper aiRequestLogMapper;
    // 其他mapper注入...

    // ========== 原有统计任务方法（日/月/年）==========
    @Scheduled(cron = "0 0 1 * * ?")
    public void statDailyData() { /* 原有逻辑 */ }

    @Scheduled(cron = "0 0 2 1 * ?")
    public void statMonthlyData() { /* 原有逻辑 */ }

    // ========== 新增：自动创建下月分区（核心）==========
    /**
     * 每月25号凌晨3点执行：自动创建下月的分区（提前5天，留缓冲）
     * cron表达式：0 0 3 25 * ? （秒 分 时 日 月 周）
     */
    @Scheduled(cron = "0 0 3 25 * ?")
    public void autoCreateNextMonthPartition() {
        try {
            log.info("开始执行AI日志表自动创建下月分区任务");
            // 1. 定义常量
            String tableName = "fx67ll_ai_request_log"; // 日志表名
            LocalDate now = LocalDate.now();
            LocalDate nextMonth = now.plusMonths(1); // 下月日期
            LocalDate nextNextMonth = nextMonth.plusMonths(1); // 下下月（分区临界值为下下月1号）

            // 2. 构造分区名（如p202603）、分区临界值（如TO_DAYS('2026-04-01')）
            String partitionName = "p" + nextMonth.format(DateTimeFormatter.ofPattern("yyyyMM"));
            String partitionLimitDate = nextNextMonth.format(DateTimeFormatter.ISO_DATE); // 下下月1号
            String partitionLimitSql = "TO_DAYS('" + partitionLimitDate + "')";

            // 3. 检查分区是否已存在，存在则直接返回（幂等性）
            int exists = aiRequestLogMapper.checkPartitionExists(tableName, partitionName);
            if (exists > 0) {
                log.info("下月分区{}已存在，无需重复创建", partitionName);
                return;
            }

            // 4. 执行分区创建：删默认分区→建下月分区→重建默认分区（MySQL RANGE分区的固定逻辑）
            // 4.1 删除默认分区p_default
            aiRequestLogMapper.executePartitionSql("ALTER TABLE " + tableName + " DROP PARTITION p_default");
            // 4.2 创建下月分区
            String createPartitionSql = String.format(
                "ALTER TABLE %s ADD PARTITION (PARTITION %s VALUES LESS THAN (%s))",
                tableName, partitionName, partitionLimitSql
            );
            aiRequestLogMapper.executePartitionSql(createPartitionSql);
            // 4.3 重建默认分区（防止未提前创建的情况，数据落入默认分区）
            aiRequestLogMapper.executePartitionSql("ALTER TABLE " + tableName + " ADD PARTITION (PARTITION p_default VALUES LESS THAN MAXVALUE)");

            log.info("AI日志表下月分区{}创建成功，临界值：{}", partitionName, partitionLimitDate);
        } catch (Exception e) {
            log.error("AI日志表自动创建下月分区任务执行失败", e);
            // 生产中添加告警：钉钉/企业微信/邮件（复用若依的告警体系）
            // alarmService.sendAlarm("AI日志表分区创建失败", e.getMessage());
        }
    }
}
```

#### 4. 核心细节说明
- **cron表达式**：`0 0 3 25 * ?` → 每月25号凌晨3点执行，避开业务高峰，且提前5天创建，即使任务执行失败，也有时间人工介入；
- **分区临界值**：比如创建2026年3月的分区`p202603`，临界值是`TO_DAYS('2026-04-01')`，和你之前手动创建的逻辑完全一致；
- **幂等性**：通过`information_schema.PARTITIONS`查询分区是否存在，避免重复创建报错；
- **异常处理**：捕获所有异常，打印详细日志，生产中必须对接告警体系（若依框架可集成钉钉/企业微信告警，分区创建失败直接推送给开发/运维）；
- **无事务**：分区操作是DDL语句，会自动提交事务，因此该方法**无需加@Transactional**。

## 方案2：MySQL事件调度器实现（纯数据库层面，无代码侵入）
### 核心优势
无需修改任何业务代码，纯数据库层面实现自动化，适合**DBA主导**的运维体系，对代码无侵入；
### 实现步骤
#### 1. 前提：开启MySQL事件调度器（生产中需持久化配置，避免重启失效）
```sql
-- 临时开启（重启MySQL后失效）
SET GLOBAL event_scheduler = ON;
-- 永久开启（修改my.cnf/my.ini，重启后生效）
# 在[mysqld]节点添加
event_scheduler = ON
```

#### 2. 创建**自动建分区的存储过程**（封装分区检查+创建逻辑）
```sql
DELIMITER // -- 临时修改语句结束符为//，避免存储过程内;截断
CREATE PROCEDURE auto_create_ai_log_partition()
BEGIN
    -- 定义变量
    DECLARE table_name VARCHAR(50) DEFAULT 'fx67ll_ai_request_log';
    DECLARE next_month VARCHAR(6); -- 下月yyyyMM，如202603
    DECLARE next_next_month_date VARCHAR(10); -- 下下月1号yyyy-MM-dd，如2026-04-01
    DECLARE partition_name VARCHAR(20); -- 分区名p+yyyyMM
    DECLARE partition_count INT DEFAULT 0; -- 分区存在标识

    -- 计算下月和下下月日期
    SET next_month = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y%m');
    SET next_next_month_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 2 MONTH), '%Y-%m-01');
    SET partition_name = CONCAT('p', next_month);

    -- 检查分区是否已存在
    SELECT COUNT(*) INTO partition_count
    FROM information_schema.PARTITIONS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = table_name AND PARTITION_NAME = partition_name;

    -- 若不存在则创建分区
    IF partition_count = 0 THEN
        -- 删默认分区
        SET @sql = CONCAT('ALTER TABLE ', table_name, ' DROP PARTITION p_default');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- 建下月分区
        SET @sql = CONCAT('ALTER TABLE ', table_name, ' ADD PARTITION (PARTITION ', partition_name, ' VALUES LESS THAN (TO_DAYS(\'', next_next_month_date, '\')))');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- 重建默认分区
        SET @sql = CONCAT('ALTER TABLE ', table_name, ' ADD PARTITION (PARTITION p_default VALUES LESS THAN MAXVALUE)');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- 写入数据库日志（可选）
        INSERT INTO sys_oper_log (title, business_type, oper_type, oper_content, create_time)
        VALUES ('AI日志表分区自动创建', 1, 1, CONCAT('创建分区：', partition_name, '，临界值：', next_next_month_date), NOW());
    END IF;
END //
DELIMITER ; -- 恢复语句结束符为;
```

#### 3. 创建**MySQL定时事件**，每月25号执行存储过程
```sql
-- 创建事件：每月25号凌晨3点执行auto_create_ai_log_partition存储过程
CREATE EVENT IF NOT EXISTS event_ai_log_auto_create_partition
ON SCHEDULE EVERY 1 MONTH
STARTS DATE_ADD(DATE_FORMAT(CURDATE(), '%Y-%m-25'), INTERVAL 3 HOUR)
DO
CALL auto_create_ai_log_partition();

-- 开启事件（默认创建后开启）
ALTER EVENT event_ai_log_auto_create_partition ENABLE;
```

#### 4. 维护命令（查看/关闭/删除事件）
```sql
-- 查看当前数据库的所有事件
SHOW EVENTS;
-- 关闭事件
ALTER EVENT event_ai_log_auto_create_partition DISABLE;
-- 删除事件
DROP EVENT IF EXISTS event_ai_log_auto_create_partition;
```

## 两种方案的对比&生产选型建议
| 特性                | 方案1：SpringBoot定时任务       | 方案2：MySQL事件调度器           |
|---------------------|--------------------------------|---------------------------------|
| 技术栈贴合度        | 极高（复用若依定时任务体系）    | 低（纯数据库，与业务代码解耦）  |
| 维护成本            | 低（开发统一维护，无需DBA介入）| 中（需DBA维护MySQL事件/存储过程）|
| 监控能力            | 强（复用若依定时任务监控+告警） | 弱（需单独监控MySQL事件状态）   |
| 侵入性              | 低（仅新增Mapper+方法，无改业务）| 无（纯数据库操作）              |
| 跨库适配性          | 强（适配多数据源/分库）        | 弱（单库生效，多库需逐个配置）  |

### **生产选型推荐**
**优先选方案1（SpringBoot定时任务）**，原因：
1. 完全贴合你的**若依SpringBoot架构**，和现有统计任务整合，开发、维护、监控一体化，无需额外沟通DBA；
2. 若依框架自带**定时任务监控页面**，可直接查看分区创建任务的执行状态、执行日志，失败后可手动触发重试；
3. 适配多数据源/分库场景（若后续业务分库，只需修改Mapper的数据源注解，无需逐个库配置MySQL事件）。

**方案2仅作为备选**，适合DBA主导运维、业务代码不允许新增任何逻辑的场景。

## 生产额外保障：分区监控&兜底方案
即使实现了自动化，生产中仍需添加**兜底措施**，避免分区创建失败导致的问题：
1. **分区状态监控**：在若依的监控页面新增「数据库分区监控」，定时查询`fx67ll_ai_request_log`的分区列表，若发现下月分区未创建，直接触发告警；
2. **默认分区兜底**：保留`p_default`默认分区，即使分区创建失败，数据也会落入默认分区，不会导致插入失败（后续人工创建分区后，可通过`ALTER TABLE ... REORGANIZE PARTITION`将默认分区的数据迁移到对应月份分区）；
3. **历史分区清理**：同时实现**历史分区的自动删除**（比如保留6个月的日志），和分区创建任务整合，每月1号删除6个月前的分区（如2026年3月删除2025年9月的分区），避免磁盘占满。

### 历史分区自动删除（方案1拓展，加一行定时方法即可）
```java
/**
 * 每月1号凌晨4点执行：删除6个月前的历史分区（保留6个月日志）
 * cron表达式：0 0 4 1 * ?
 */
@Scheduled(cron = "0 0 4 1 * ?")
public void autoDeleteHistoryPartition() {
    try {
        log.info("开始执行AI日志表自动删除历史分区任务");
        String tableName = "fx67ll_ai_request_log";
        LocalDate delMonth = LocalDate.now().minusMonths(6); // 6个月前的日期
        String partitionName = "p" + delMonth.format(DateTimeFormatter.ofPattern("yyyyMM"));

        // 检查分区是否存在，存在则删除
        int exists = aiRequestLogMapper.checkPartitionExists(tableName, partitionName);
        if (exists > 0) {
            aiRequestLogMapper.executePartitionSql("ALTER TABLE " + tableName + " DROP PARTITION " + partitionName);
            log.info("AI日志表历史分区{}删除成功", partitionName);
        } else {
            log.info("AI日志表6个月前的历史分区{}不存在，无需删除", partitionName);
        }
    } catch (Exception e) {
        log.error("AI日志表自动删除历史分区任务执行失败", e);
        // alarmService.sendAlarm("AI日志表分区删除失败", e.getMessage());
    }
}
```

## 最终总结
1. 生产中**绝对不能手动创建分区**，必须实现自动化，核心是**提前5-7天创建下月分区**+**幂等性检查**；
2. 结合你的**若依SpringBoot+MySQL**架构，**优先使用SpringBoot定时任务实现**，和现有统计任务整合，维护、监控更便捷；
3. 必须添加**异常告警+默认分区兜底+历史分区自动清理**，形成完整的分区生命周期管理；
4. 分区操作是DDL语句，无需加事务，且执行频率极低（每月1次），对数据库性能无任何影响。