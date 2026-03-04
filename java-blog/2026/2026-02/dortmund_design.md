# 功能设计大纲

## 自我心态约束管理铁则
+ 客观的盈利目标管理，初期只要能覆盖一周的支出之类的就可以，中期期覆盖整体亏损，后期争取第一桶金
+ 等待时机，耐心等待，只抓住合适的机会
+ 学会承认自己的错误
+ 永远保持谦逊，承认市场比你聪明
+ 兜底规则：多串一每天最多1个且只准1倍，二串一比值超过2.0即可，包含多特一律低额度且作为娱乐

--- 

### 前言
我已经通过若依落地了个人业务管理系统，整体架构大致是`SpringBoot + Mysql + Vue2`  
现在我想在这个业务系统上，再设计一个AI比赛赛前信息分析评分系统  

---

### 一、AI 业务表设计
下面这些表是`Prompt + Api`业务相关的表设计，与若依风格统一。

#### 1. 球队管理表
```sql
CREATE TABLE `fx67ll_ai_prompt_template` (
  `prompt_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '模板唯一标识（主键）',
  `prompt_name` varchar(233) NOT NULL COMMENT '模板业务名称',
  `group_id` bigint(20) NOT NULL COMMENT '所属分组ID（外键，关联fx67ll_ai_prompt_group.group_id，强制约束模板与分组的归属关系）',
  `scene_id` bigint(20) NOT NULL COMMENT '所属场景ID（外键，关联fx67ll_ai_prompt_scene.scene_id，定义模板的业务应用场景）',
  `model_id` bigint(20) NOT NULL COMMENT '默认绑定模型ID（外键，关联fx67ll_ai_prompt_model.model_id，指定模板调用的AI模型）',
  `prompt_content` text NOT NULL COMMENT 'Prompt模板主体内容（含变量占位符，如{{team_name}}）',
  `prompt_variable_config` text COMMENT '模板变量元数据配置（JSON格式，定义变量名、类型、校验规则、示例值等）',
  `prompt_custom_config_params` text COMMENT '模型调用参数覆盖配置（JSON格式，优先级高于模型表默认参数）',
  `prompt_status` char(1) DEFAULT '0' COMMENT '模板启用状态（字典码：0-启用，1-停用）',
  `prompt_remark` varchar(1023) DEFAULT '' COMMENT '模板业务备注（说明使用场景、注意事项等）',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`prompt_id`),
  KEY `idx_group_id` (`group_id`) COMMENT '分组ID索引（加速按分组查询模板列表）',
  KEY `idx_scene_id` (`scene_id`) COMMENT '场景ID索引（加速按场景筛选模板）',
  KEY `idx_model_id` (`model_id`) COMMENT '模型ID索引（加速按模型查询关联模板）',
  KEY `idx_group_scene_model` (`group_id`, `scene_id`, `model_id`) COMMENT '分组+场景+模型组合索引（优化多维度联合查询性能）',
  KEY `idx_prompt_status` (`prompt_status`) COMMENT '模板状态索引（加速筛选启用/停用模板）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询模板）',
  KEY `idx_user_id_status` (`user_id`, `prompt_status`) COMMENT '用户+状态组合索引（优化按用户筛选启用模板）',
  FOREIGN KEY (`group_id`) REFERENCES `fx67ll_ai_prompt_group`(`group_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`scene_id`) REFERENCES `fx67ll_ai_prompt_scene`(`scene_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`model_id`) REFERENCES `fx67ll_ai_prompt_model`(`model_id`) ON DELETE RESTRICT
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt模板管理表';
```

#### 2. AI Prompt模板分组表
```sql
CREATE TABLE `fx67ll_ai_prompt_group` (
  `group_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分组唯一标识（主键）',
  `group_code` varchar(233) NOT NULL COMMENT '分组业务编码（唯一，用于程序逻辑关联）',
  `group_name` varchar(233) NOT NULL COMMENT '分组业务名称（用于前端展示）',
  `group_desc` varchar(1023) DEFAULT '' COMMENT '分组业务描述（说明分组的用途、范围）',
  `group_status` char(1) DEFAULT '0' COMMENT '分组启用状态（字典码：0-启用，1-停用）',
  `group_sort` int(4) DEFAULT 0 COMMENT '分组展示排序（升序排列，数值越小越靠前）',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`group_id`),
  UNIQUE KEY `uk_group_code` (`group_code`) COMMENT '分组编码唯一索引（防止业务编码重复）',
  KEY `idx_group_status` (`group_status`) COMMENT '分组状态索引（加速筛选启用/停用分组）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询分组）',
  KEY `idx_user_id_status` (`user_id`, `group_status`) COMMENT '用户+状态组合索引（优化按用户筛选启用分组）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt模板分组表';
```

#### 3. AI Prompt场景管理表
```sql
CREATE TABLE `fx67ll_ai_prompt_scene` (
  `scene_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '场景唯一标识（主键）',
  `scene_code` varchar(233) NOT NULL COMMENT '场景业务编码（唯一，用于程序逻辑关联）',
  `scene_name` varchar(233) NOT NULL COMMENT '场景业务名称（用于前端展示）',
  `scene_desc` varchar(1023) DEFAULT '' COMMENT '场景业务描述（说明场景的业务背景、应用范围）',
  `scene_remark` varchar(1023) DEFAULT '' COMMENT '场景扩展备注',
  `scene_status` char(1) DEFAULT '0' COMMENT '场景启用状态（字典码：0-启用，1-停用）',
  `scene_sort` int(4) DEFAULT 0 COMMENT '场景展示排序（升序排列，数值越小越靠前）',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`scene_id`),
  UNIQUE KEY `uk_scene_code` (`scene_code`) COMMENT '场景编码唯一索引（防止业务编码重复）',
  KEY `idx_scene_status` (`scene_status`) COMMENT '场景状态索引（加速筛选启用/停用场景）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询场景）',
  KEY `idx_user_id_status` (`user_id`, `scene_status`) COMMENT '用户+状态组合索引（优化按用户筛选启用场景）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt场景管理表';
```

#### 4. AI Prompt模型配置表
```sql
CREATE TABLE `fx67ll_ai_prompt_model` (
  `model_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '模型唯一标识（主键）',
  `model_code` varchar(23) NOT NULL COMMENT '模型业务编码（唯一，如deepseek-v3）',
  `model_name` varchar(233) NOT NULL COMMENT '模型业务名称（用于前端展示）',
  `model_vendor` varchar(66) NOT NULL COMMENT '模型厂商标识（如Deepseek，doubao）',
  `model_api_key` bigint(20) NOT NULL COMMENT 'API密钥ID（外键，关联fx67ll_secret_key.secret_id，存储API Key的加密引用）',
  `model_secret_key` bigint(20) DEFAULT NULL COMMENT 'Secret密钥ID（外键，关联fx67ll_secret_key.secret_id，部分厂商需要，可为空）',
  `model_api_url` varchar(233) NOT NULL COMMENT '模型API调用地址（完整URL）',
  `model_api_version` varchar(10) DEFAULT '1' COMMENT 'API版本号（如v1）',
  `model_config_params` text NOT NULL COMMENT '模型默认调用参数（JSON格式，如temperature、max_tokens等）',
  `model_request_header` text COMMENT 'API请求头扩展配置（JSON格式，用于特殊鉴权或自定义头）',
  `model_remark` varchar(1023) DEFAULT '' COMMENT '模型业务备注（说明模型特点、使用限制等）',
  `model_status` char(1) DEFAULT '0' COMMENT '模型启用状态（字典码：0-启用，1-停用）',
  `model_sort` int(4) DEFAULT 0 COMMENT '模型展示排序（升序排列，数值越小越靠前）',
  `model_token_price` decimal(10,6) DEFAULT 0.000000 COMMENT '模型计费单价（元/千Token，用于成本估算）',
  `model_token_currency` varchar(10) DEFAULT 'CNY' COMMENT '计价货币类型（ISO 4217货币码，如CNY、USD）',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`model_id`),
  UNIQUE KEY `uk_model_code` (`model_code`) COMMENT '模型编码唯一索引（防止同一模型重复配置）',
  KEY `idx_model_vendor_status` (`model_vendor`, `model_status`) COMMENT '厂商+状态组合索引（加速筛选某厂商的启用模型）',
  KEY `idx_model_status` (`model_status`) COMMENT '模型状态索引（加速筛选启用/停用模型）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询模型）',
  KEY `idx_user_id_vendor` (`user_id`, `model_vendor`) COMMENT '用户+厂商组合索引（优化按用户筛选某厂商模型）',
  CONSTRAINT `fk_model_api_key` FOREIGN KEY (`model_api_key`) REFERENCES `fx67ll_secret_key`(`secret_id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_model_secret_key` FOREIGN KEY (`model_secret_key`) REFERENCES `fx67ll_secret_key`(`secret_id`) ON DELETE RESTRICT
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt模型配置表';
```

#### 5. AI Prompt 限流/熔断规则表（适配Sentinel框架）
```sql
CREATE TABLE `fx67ll_ai_prompt_limit_rule` (
  `limit_rule_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '规则唯一标识（主键）',
  `limit_rule_dimension` char(2) NOT NULL COMMENT '规则作用维度（字典码：1-模型，2-模板，3-场景，4-分组）',
  `limit_rule_target_id` bigint(20) NOT NULL COMMENT '规则作用目标ID（对应维度的业务ID，如model_id、prompt_id）',
  `limit_rule_type` char(2) NOT NULL COMMENT '规则类型（字典码：1-流量控制，2-熔断保护）',
  `flow_control_mode` char(1) DEFAULT 'D' COMMENT '流控模式（字典码：D-直接拒绝，A-关联控制，L-链路流控，仅流控规则有效）',
  `flow_control_effect` char(1) DEFAULT 'F' COMMENT '流控效果（字典码：F-快速失败，W-预热启动，Q-匀速排队，仅流控规则有效）',
  `flow_rule_type` char(1) DEFAULT 'Q' COMMENT '流控指标类型（字典码：Q-QPS阈值，C-并发线程数，仅流控规则有效）',
  `flow_threshold` decimal(10,2) NOT NULL COMMENT '流控阈值（QPS或并发数，保留2位小数）',
  `circuit_strategy` char(1) DEFAULT 'S' COMMENT '熔断策略（字典码：S-慢调用比例，E-异常比例，N-异常数，仅熔断规则有效）',
  `circuit_threshold` decimal(10,2) DEFAULT 0.5 COMMENT '熔断触发阈值（慢调用/异常比例：0-1；异常数：正整数）',
  `circuit_grade` int(4) DEFAULT 500 COMMENT '慢调用判定阈值（毫秒，仅慢调用熔断策略有效）',
  `circuit_window` int(4) DEFAULT 10000 COMMENT '熔断统计窗口时长（毫秒，默认10秒）',
  `circuit_timeout` int(4) DEFAULT 5000 COMMENT '熔断恢复超时时间（毫秒，默认5秒后尝试半开）',
  `limit_rule_status` char(1) DEFAULT '0' COMMENT '规则启用状态（字典码：0-启用，1-停用）',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`limit_rule_id`),
  KEY `idx_limit_dim_target` (`limit_rule_dimension`, `limit_rule_target_id`) COMMENT '维度+目标ID组合索引（加速查询某维度下的规则）',
  KEY `idx_limit_type_status` (`limit_rule_type`, `limit_rule_status`) COMMENT '类型+状态组合索引（加速筛选启用的流控/熔断规则）',
  KEY `idx_limit_dim_type_status` (`limit_rule_dimension`, `limit_rule_type`, `limit_rule_status`) COMMENT '维度+类型+状态组合索引（优化高频查询性能）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询规则）',
  KEY `idx_user_id_type_status` (`user_id`, `limit_rule_type`, `limit_rule_status`) COMMENT '用户+类型+状态组合索引（优化按用户筛选启用规则）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt 限流/熔断规则表（适配Sentinel框架）';
```

#### 6. AI 调用请求日志表（按request_time月份分区）
```sql
CREATE TABLE `fx67ll_ai_request_log` (
  `request_log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志唯一标识（分区表主键，与request_time组成复合聚集索引）',
  `prompt_id` bigint(20) DEFAULT NULL COMMENT '关联模板ID（外键，直接调用模型时为空）',
  `scene_id` bigint(20) DEFAULT NULL COMMENT '关联场景ID（外键，直接调用模型时为空）',
  `model_id` bigint(20) NOT NULL COMMENT '调用模型ID（外键，关联fx67ll_ai_prompt_model.model_id）',
  `model_vendor` varchar(66) NOT NULL COMMENT '模型厂商标识（冗余字段，避免关联查询）',
  `request_content` text COMMENT '请求完整内容（含最终渲染后的Prompt文本）',
  `response_content` text COMMENT '响应完整内容（大文本存储AI返回结果）',
  `prompt_tokens` int(11) DEFAULT 0 COMMENT '输入Token消耗量（Prompt部分）',
  `completion_tokens` int(11) DEFAULT 0 COMMENT '输出Token消耗量（Completion部分）',
  `total_tokens` int(11) DEFAULT 0 COMMENT '总Token消耗量（输入+输出）',
  `cost` decimal(10,6) DEFAULT 0.000000 COMMENT '本次调用预估费用（元，基于单价和Token数计算）',
  `duration_ms` int(11) DEFAULT 0 COMMENT '请求耗时（毫秒，从发送请求到接收响应的总时长）',
  `http_status` int(3) DEFAULT NULL COMMENT 'HTTP响应状态码（如200、400、500）',
  `call_status` char(2) DEFAULT '00' COMMENT '调用业务状态（字典码：00-成功，01-业务失败，02-限流拦截，03-熔断拦截）',
  `error_msg` text COMMENT '错误堆栈信息（调用失败时存储）',
  `caller_ip` varchar(233) DEFAULT '' COMMENT '调用者客户端IP地址',
  `request_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '请求发起时间（分区键，精确到秒）',
  `user_id` bigint(20) NOT NULL COMMENT '记录创建者标识用户名（关联系统用户表）',
  PRIMARY KEY (`request_log_id`, `request_time`),
  KEY `idx_request_log_id` (`request_log_id`),
  KEY `idx_request_time` (`request_time`),
  KEY `idx_prompt_id` (`prompt_id`),
  KEY `idx_scene_id` (`scene_id`),
  KEY `idx_model_id` (`model_id`),
  KEY `idx_call_status` (`call_status`),
  KEY `idx_request_time_vendor` (`request_time`, `model_vendor`),
  KEY `idx_scene_model_time` (`scene_id`, `model_id`, `request_time`),
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询调用日志）',
  KEY `idx_user_id_time` (`user_id`, `request_time`) COMMENT '用户+时间组合索引（优化按用户查询时间段日志）',
  KEY `idx_user_id_status` (`user_id`, `call_status`) COMMENT '用户+调用状态组合索引（优化按用户筛选失败日志）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 
COMMENT='AI 调用请求日志表（按request_time月份分区，记录所有AI API调用的详细信息）'
PARTITION BY RANGE (TO_DAYS(request_time)) (
  PARTITION p202603 VALUES LESS THAN (TO_DAYS('2026-04-01')),
  PARTITION p202604 VALUES LESS THAN (TO_DAYS('2026-05-01')),
  PARTITION p202605 VALUES LESS THAN (TO_DAYS('2026-06-01')),
  PARTITION p_default VALUES LESS THAN MAXVALUE
);
```

#### 7. AI 调用请求日统计日志表
```sql
CREATE TABLE `fx67ll_ai_request_daily_log` (
  `daily_log_date` date NOT NULL COMMENT '统计日期（yyyy-MM-dd，分区键）',
  `model_id` bigint(20) NOT NULL COMMENT '统计维度：模型ID（-1表示全模型汇总）',
  `scene_id` bigint(20) NOT NULL COMMENT '统计维度：场景ID（-1表示全场景汇总）',
  `total_requests` int(11) DEFAULT 0 COMMENT '统计周期内API总调用次数（含所有状态）',
  `fail_requests` int(11) DEFAULT 0 COMMENT '统计周期内业务失败调用次数',
  `limit_requests` int(11) DEFAULT 0 COMMENT '统计周期内限流拦截调用次数',
  `circuit_requests` int(11) DEFAULT 0 COMMENT '统计周期内熔断拦截调用次数',
  `total_prompt_tokens` bigint(20) DEFAULT 0 COMMENT '统计周期内总输入Token消耗量',
  `total_completion_tokens` bigint(20) DEFAULT 0 COMMENT '统计周期内总输出Token消耗量',
  `total_cost` decimal(12,6) DEFAULT 0.000000 COMMENT '统计周期内总预估费用（元）',
  `avg_duration_ms` int(11) DEFAULT 0 COMMENT '统计周期内平均请求耗时（毫秒，总耗时/成功请求数）',
  PRIMARY KEY (`daily_log_date`, `model_id`, `scene_id`) COMMENT '复合主键：日期+模型+场景（唯一确定一条统计记录）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='AI 调用请求日统计日志表';
```

#### 8. AI 调用请求月统计日志表
```sql
CREATE TABLE `fx67ll_ai_request_monthly_log` (
  `monthly_log_month` varchar(7) NOT NULL COMMENT '统计月份（yyyy-MM，分区键）',
  `model_id` bigint(20) NOT NULL COMMENT '统计维度：模型ID（-1表示全模型汇总）',
  `scene_id` bigint(20) NOT NULL COMMENT '统计维度：场景ID（-1表示全场景汇总）',
  `total_requests` int(11) DEFAULT 0 COMMENT '统计周期内API总调用次数（含所有状态）',
  `fail_requests` int(11) DEFAULT 0 COMMENT '统计周期内业务失败调用次数',
  `limit_requests` int(11) DEFAULT 0 COMMENT '统计周期内限流拦截调用次数',
  `circuit_requests` int(11) DEFAULT 0 COMMENT '统计周期内熔断拦截调用次数',
  `total_prompt_tokens` bigint(20) DEFAULT 0 COMMENT '统计周期内总输入Token消耗量',
  `total_completion_tokens` bigint(20) DEFAULT 0 COMMENT '统计周期内总输出Token消耗量',
  `total_cost` decimal(12,6) DEFAULT 0.000000 COMMENT '统计周期内总预估费用（元）',
  `avg_duration_ms` int(11) DEFAULT 0 COMMENT '统计周期内平均请求耗时（毫秒）',
  PRIMARY KEY (`monthly_log_month`, `model_id`, `scene_id`) COMMENT '复合主键：月份+模型+场景（唯一确定一条统计记录）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='AI 调用请求月统计日志表';
```

#### 9. AI 调用请求年统计日志表
```sql
CREATE TABLE `fx67ll_ai_request_yearly_log` (
  `yearly_log_year` varchar(4) NOT NULL COMMENT '统计年份（yyyy，分区键）',
  `model_id` bigint(20) NOT NULL COMMENT '统计维度：模型ID（-1表示全模型汇总）',
  `scene_id` bigint(20) NOT NULL COMMENT '统计维度：场景ID（-1表示全场景汇总）',
  `total_requests` bigint(20) DEFAULT 0 COMMENT '统计周期内API总调用次数（含所有状态）',
  `total_prompt_tokens` bigint(20) DEFAULT 0 COMMENT '统计周期内总输入Token消耗量',
  `total_completion_tokens` bigint(20) DEFAULT 0 COMMENT '统计周期内总输出Token消耗量',
  `total_cost` decimal(14,6) DEFAULT 0.000000 COMMENT '统计周期内总预估费用（元）',
  `avg_duration_ms` int(11) DEFAULT 0 COMMENT '统计周期内平均请求耗时（毫秒）',
  PRIMARY KEY (`yearly_log_year`, `model_id`, `scene_id`) COMMENT '复合主键：年份+模型+场景（唯一确定一条统计记录）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='AI 调用请求年统计日志表';
```

---

### 二、比赛业务流程闭环设计思路说明
```
1. 赛季管理：新增/编辑赛季（如2025-2026赛季）
   ↓
2. 比赛管理：新增比赛（选择赛季、主队/客队（新增或下拉）、比赛时间）
   ↓
3. AI分析：选择Prompt模板 → 调用AI → 存原始分析结果 → 存调用日志
   ↓
4. 标准化评分：基于AI结果按规则计算各项评分 → 存评分表 → 前端展示
```

---

### 三、比赛业务表设计
下面这些表是比赛业务相关的表设计，与若依风格统一。

#### 1. 赛季管理表
```sql
CREATE TABLE `fx67ll_dortmund_season` (
  `season_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '赛季唯一标识（主键）',
  `season_code` varchar(23) NOT NULL COMMENT '赛季业务编码（唯一，如2025-2026_Bundesliga）',
  `season_name` varchar(233) NOT NULL COMMENT '赛季业务名称（如2025-2026赛季德甲联赛）',
  `season_remark` varchar(1023) DEFAULT '' COMMENT '赛季业务备注（说明赛事级别、规则等）',
  `season_start_date` date NOT NULL COMMENT '赛季开始日期',
  `season_end_date` date NOT NULL COMMENT '赛季结束日期',
  `season_status` char(1) DEFAULT '0' COMMENT '赛季状态（字典码：0-进行中，1-已结束，2-未开始）',
  `season_sort` int(4) DEFAULT 0 COMMENT '赛季展示排序（升序排列，数值越小越靠前）',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`season_id`),
  UNIQUE KEY `uk_season_code` (`season_code`) COMMENT '赛季编码唯一索引（防止业务编码重复）',
  KEY `idx_season_status` (`season_status`) COMMENT '赛季状态索引（加速筛选进行中/已结束赛季）',
  KEY `idx_season_sort` (`season_sort`) COMMENT '赛季排序索引（加速前端展示排序）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询赛季）',
  KEY `idx_user_id_status` (`user_id`, `season_status`) COMMENT '用户+状态组合索引（优化按用户筛选进行中赛季）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='赛季管理表';
```

### 2. 球队管理表
```sql
CREATE TABLE `fx67ll_dortmund_team` (
  `team_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '球队唯一标识（主键）',
  `team_code` varchar(23) NOT NULL COMMENT '球队业务编码（唯一，如DORTMUND、BAYERN）',
  `team_name` varchar(233) NOT NULL COMMENT '球队全称（如多特蒙德足球俱乐部）',
  `team_name_short` varchar(10) DEFAULT '' COMMENT '球队简称或昵称（如我横、大黄蜂）',
  `team_name_en` varchar(233) DEFAULT '' COMMENT '球队英文全称（如Borussia Dortmund）',
  `team_logo_url` varchar(1023) DEFAULT '' COMMENT '球队Logo图片URL地址',
  `team_country` varchar(23) DEFAULT '' COMMENT '球队所属国家/地区（如德国、英格兰）',
  `team_tag` varchar(1023) DEFAULT '' COMMENT '球队标签（如主场龙、客场虫）',
  `team_remark` varchar(1023) DEFAULT '' COMMENT '球队业务备注',
  `team_status` char(1) DEFAULT '0' COMMENT '球队状态（字典码：0-启用，1-停用）',
  `team_sort` int(4) DEFAULT 0 COMMENT '球队展示排序（升序排列，数值越小越靠前）',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`team_id`),
  UNIQUE KEY `uk_team_code` (`team_code`) COMMENT '球队编码唯一索引（防止业务编码重复）',
  KEY `idx_team_status` (`team_status`) COMMENT '球队状态索引（加速筛选启用/停用球队）',
  KEY `idx_team_sort` (`team_sort`) COMMENT '球队排序索引（加速前端展示排序）',
  KEY `idx_team_country` (`team_country`) COMMENT '球队国家索引（加速按国家筛选球队）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询球队）',
  KEY `idx_user_id_country` (`user_id`, `team_country`) COMMENT '用户+国家组合索引（优化按用户筛选某国家球队）'
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='球队管理表';
```

### 3. 比赛记录表
```sql
CREATE TABLE `fx67ll_dortmund_match` (
  `match_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '比赛唯一标识（主键）',
  `match_code` varchar(23) NOT NULL COMMENT '比赛唯一业务编码（规则：season_code + match_time + home_team_code + away_team_code）',
  `season_id` bigint(20) NOT NULL COMMENT '所属赛季ID（外键，关联fx67ll_dortmund_season.season_id）',
  `home_team_id` bigint(20) NOT NULL COMMENT '主队球队ID（外键，关联fx67ll_dortmund_team.team_id）',
  `away_team_id` bigint(20) NOT NULL COMMENT '客队球队ID（外键，关联fx67ll_dortmund_team.team_id）',
  `match_time` datetime NOT NULL COMMENT '比赛开球时间',
  `match_venue` varchar(233) DEFAULT '' COMMENT '比赛举办场地名称',
  `match_remark` varchar(1023) DEFAULT '' COMMENT '比赛业务备注（如轮次、特殊说明）',
  `match_status` char(1) DEFAULT '0' COMMENT '比赛状态（字典码：0-未开始，1-进行中，2-已结束）',
  `analysis_count` int(4) DEFAULT 0 COMMENT 'AI分析次数（统计该比赛已生成的分析报告数量）',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`match_id`),
  UNIQUE KEY `uk_match_code` (`match_code`) COMMENT '比赛编码唯一索引（防止业务编码重复）',
  KEY `idx_season_id` (`season_id`) COMMENT '赛季ID索引（加速按赛季查询比赛）',
  KEY `idx_home_team_id` (`home_team_id`) COMMENT '主队ID索引（加速按主队查询比赛）',
  KEY `idx_away_team_id` (`away_team_id`) COMMENT '客队ID索引（加速按客队查询比赛）',
  KEY `idx_match_time` (`match_time`) COMMENT '比赛时间索引（加速按时间范围查询比赛）',
  KEY `idx_match_status` (`match_status`) COMMENT '比赛状态索引（加速筛选未开始/已结束比赛）',
  KEY `idx_match_create` (`match_id`, `create_time`) COMMENT '比赛ID+创建时间组合索引（优化按创建时间倒序查询）',
  KEY `idx_season_match_status` (`season_id`, `match_status`) COMMENT '赛季+状态组合索引（优化按赛季查询未开始比赛）',
  KEY `idx_season_match_time` (`season_id`, `match_time`) COMMENT '赛季+时间组合索引（优化某赛季比赛按时间排序）',
  KEY `idx_match_time_status` (`match_time`, `match_status`) COMMENT '时间+状态组合索引（优化查询近期未开始比赛）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询比赛）',
  KEY `idx_user_id_season` (`user_id`, `season_id`) COMMENT '用户+赛季组合索引（优化按用户筛选某赛季比赛）',
  KEY `idx_user_id_status` (`user_id`, `match_status`) COMMENT '用户+状态组合索引（优化按用户筛选已结束比赛）',
  FOREIGN KEY (`season_id`) REFERENCES `fx67ll_dortmund_season`(`season_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`home_team_id`) REFERENCES `fx67ll_dortmund_team`(`team_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`away_team_id`) REFERENCES `fx67ll_dortmund_team`(`team_id`) ON DELETE RESTRICT
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='比赛记录表';
```

### 4. AI比赛分析原始结果表
```sql
CREATE TABLE `fx67ll_dortmund_match_analysis` (
  `analysis_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分析唯一标识（主键）',
  `match_id` bigint(20) NOT NULL COMMENT '关联比赛ID（外键，关联fx67ll_dortmund_match.match_id）',
  `prompt_id` bigint(20) DEFAULT NULL COMMENT '使用的模板ID（外键，关联fx67ll_ai_prompt_template.prompt_id，自定义分析时为空）',
  `model_id` bigint(20) NOT NULL COMMENT '使用的模型ID（外键，关联fx67ll_ai_prompt_model.model_id）',
  `request_log_code` varchar(233) DEFAULT '' COMMENT 'AI调用日志关联码（格式：request_log_id|request_time，用于手动关联fx67ll_ai_request_log表）',
  `analysis_type` char(1) DEFAULT '0' COMMENT '分析类型（字典码：0-模板分析，1-自定义文本分析）',
  `raw_prompt` text NOT NULL COMMENT '最终请求Prompt（含渲染后的球队/比赛数据，自定义分析时为用户输入文本）',
  `raw_ai_response` text NOT NULL COMMENT 'AI原始响应内容（JSON格式字符串）',
  `analysis_remark` varchar(1023) DEFAULT '' COMMENT '分析业务备注',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  PRIMARY KEY (`analysis_id`),
  KEY `idx_match_id` (`match_id`) COMMENT '比赛ID索引（加速按比赛查询分析记录）',
  KEY `idx_prompt_id` (`prompt_id`) COMMENT '模板ID索引（加速按模板查询分析记录）',
  KEY `idx_model_id` (`model_id`) COMMENT '模型ID索引（加速按模型查询分析记录）',
  KEY `idx_create_time` (`create_time`) COMMENT '创建时间索引（加速按时间范围查询分析）',
  KEY `idx_match_prompt_model` (`match_id`, `prompt_id`, `model_id`) COMMENT '比赛+模板+模型组合索引（优化高频查询：某比赛的特定模板分析）',
  KEY `idx_analysis_type` (`analysis_type`) COMMENT '分析类型索引（加速筛选模板/自定义分析）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询分析记录）',
  KEY `idx_user_id_match` (`user_id`, `match_id`) COMMENT '用户+比赛组合索引（优化按用户查询某比赛分析）',
  KEY `idx_user_id_type` (`user_id`, `analysis_type`) COMMENT '用户+分析类型组合索引（优化按用户筛选自定义分析）',
  FOREIGN KEY (`match_id`) REFERENCES `fx67ll_dortmund_match`(`match_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`prompt_id`) REFERENCES `fx67ll_ai_prompt_template`(`prompt_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`model_id`) REFERENCES `fx67ll_ai_prompt_model`(`model_id`) ON DELETE RESTRICT
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='比赛AI分析原始结果表';
```

### 5. 比赛标准化评分表
```sql
CREATE TABLE `fx67ll_dortmund_match_score` (
  `score_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '评分唯一标识（主键）',
  `analysis_id` bigint(20) NOT NULL COMMENT '关联分析ID（外键，关联fx67ll_dortmund_match_analysis.analysis_id）',
  `match_id` bigint(20) NOT NULL COMMENT '关联比赛ID（外键，冗余字段，加速查询）',
  -- 主队评分
  `home_attack_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队进攻能力标准化评分（值域：[0,100]，基于近期进攻数据计算）',
  `home_defense_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队防守能力标准化评分（值域：[0,100]，基于近期防守数据计算）',
  `home_injury_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队健康状况评分（值域：[0,100]，分值越高表示伤病影响越小）',
  `home_history_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队历史交锋评分（值域：[0,100]，基于对阵客队的历史战绩计算）',
  `home_total_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队综合能力总评分（值域：[0,100]，多维度加权计算）',
  -- 客队评分
  `away_attack_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队进攻能力标准化评分（值域：[0,100]，基于近期进攻数据计算）',
  `away_defense_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队防守能力标准化评分（值域：[0,100]，基于近期防守数据计算）',
  `away_injury_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队健康状况评分（值域：[0,100]，分值越高表示伤病影响越小）',
  `away_history_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队历史交锋评分（值域：[0,100]，基于对阵主队的历史战绩计算）',
  `away_total_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队综合能力总评分（值域：[0,100]，多维度加权计算）',
  -- 预测结果
  `predicted_result` char(1) DEFAULT '0' COMMENT '比赛预测结果（字典码：0-主队胜，1-平局，2-客队胜）',
  `predicted_confidence` decimal(5,2) DEFAULT 0.00 COMMENT '预测结果置信度（值域：[0,100]，分值越高表示预测可靠性越强）',
  `score_calc_rule_version` varchar(23) DEFAULT '1' COMMENT '评分规则版本号（用于追溯评分逻辑变更）',
  -- 扩展评分字段
  `extra_score_str` varchar(2333) DEFAULT NULL COMMENT '扩展评分数据（JSON格式字符串，存储非标准化评分字段）',
  -- 基础通用字段
  `score_remark` varchar(1023) DEFAULT '' COMMENT '评分业务备注',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `create_by` varchar(64) DEFAULT '' COMMENT '记录创建者标识用户名（关联系统用户表）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '记录最后更新者标识用户名（关联系统用户表）',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '逻辑删除标志（字典码：0-存在，2-已删除）',
  -- 索引与约束
  PRIMARY KEY (`score_id`),
  UNIQUE KEY `uk_analysis_id` (`analysis_id`) COMMENT '分析ID唯一索引（一个分析对应唯一评分）',
  KEY `idx_match_id` (`match_id`) COMMENT '比赛ID索引（加速按比赛查询评分）',
  KEY `idx_predicted_result` (`predicted_result`) COMMENT '预测结果索引（加速按预测结果筛选）',
  KEY `idx_create_time` (`create_time`) COMMENT '创建时间索引（加速查询近期评分）',
  KEY `idx_match_predicted_result` (`match_id`, `predicted_result`) COMMENT '比赛+预测结果组合索引（优化高频查询：某比赛的预测结果）',
  KEY `idx_user_id` (`user_id`) COMMENT '用户ID索引（加速按用户查询评分）',
  KEY `idx_user_id_predicted` (`user_id`, `predicted_result`) COMMENT '用户+预测结果组合索引（优化按用户筛选某预测结果的评分）',
  -- 值域约束
  CONSTRAINT `chk_confidence_range` CHECK (`predicted_confidence` BETWEEN 0 AND 100),
  CONSTRAINT `chk_home_total_range` CHECK (`home_total_score` BETWEEN 0 AND 100),
  CONSTRAINT `chk_away_total_range` CHECK (`away_total_score` BETWEEN 0 AND 100),
  -- 外键约束
  FOREIGN KEY (`analysis_id`) REFERENCES `fx67ll_dortmund_match_analysis`(`analysis_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`match_id`) REFERENCES `fx67ll_dortmund_match`(`match_id`) ON DELETE RESTRICT
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COMMENT='比赛标准化评分表';
```

---

### 四、与现有AI业务系统的对接要点
| 现有AI系统表 | 新增业务表 | 对接方式 |
|--------------|------------|----------|
| `fx67ll_ai_prompt_template` | `fx67ll_football_match_analysis` | 分析时选择模板，关联 `prompt_id`，建议在足球业务中创建专属分组（如 football_analysis）和场景（如 pre_match），便于前端按分组筛选模板 |
| `fx67ll_ai_prompt_model` | `fx67ll_football_match_analysis` | 关联 `model_id`，复用模型配置 |
| `fx67ll_ai_request_log` | `fx67ll_football_match_analysis` | 分析表关联 log_id	在调用 AI 后，将生成的日志 ID 回填至分析表，关联 `ai_request_log_id`，实现全链路追踪 |
| `fx67ll_ai_prompt_limit_rule` | - | 调用AI时自动触发限流熔断，无需额外关联 |

---

### 七、大致必需的业务逻辑补充

- 需要在若依的基础用户功能之上，添加会员账号积分体系，这样后续如果对接支付系统的话，只需要按比例充钱给积分就好了  

- Prompt 模版管理界面，添加按钮用于模板编辑后支持一键测试，输入变量示例，调用 AI API 并展示响应结果，便于调试  

- 后端需要一个公共工具服务，根据variable_config解析传入变量，替换模板中的占位符（如{home_team}）  

- 对于耗时长的分析任务，需要设计任务表，将请求放入消息队列（如RocketMQ），后台消费者异步调用AI，轮询结果后通知前端  

- 设置限流、熔断（大概率使用Sentinel），防止恶意调用  

- 调用相应厂商的API，记录请求日志（包含请求/响应、token消耗、耗时等），提供token消耗统计报表，便于成本控制  

- 日志表数据量会快速增长，直接对海量数据做统计报表可能性能不佳，按年月日预聚合，创建汇总表  

- 通过定时任务（如每天凌晨）或异步队列在每次请求后更新汇总表  

- 新增比赛时，校验`home_team_id != away_team_id`（避免主队 = 客队）  

- 比赛分析次数更新的时候，每次新增`match_analysis`记录，同步更新`match`表的`analysis_count += 1`  

- 比赛自定义分析时，`prompt_id`和`ai_request_log_id`置空，同步更新`match`表的`analysis_count += 1`  
