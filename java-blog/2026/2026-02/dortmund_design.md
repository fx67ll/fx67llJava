# 功能设计大纲

## 自我心态约束管理铁则
+ 客观的盈利目标管理，初期只要能覆盖一周的支出之类的就可以，中期期覆盖整体亏损，后期争取第一桶金
+ 等待时机，耐心等待，只抓住合适的机会
+ 学会承认自己的错误
+ 永远保持谦逊，承认市场比你聪明
+ 兜底规则：多串一每天最多1个且只准1倍，二串一比值超过2.0即可，包含多特一律低额度且作为娱乐

--- 

### 前言
我已经通过若依落地了个人业务管理系统，具体是springboot + mysql，现在我想设计一个足球比赛赛前信息分析评分系统

---

### 一、AI 业务设计 --> Prompt + API
下面这些表是我目前设计的Prompt相关和接口调用相关的基础功能表。

---

### 二、AI 业务表设计（与若依风格统一）
#### 1. 球队管理表
```sql
CREATE TABLE `fx67ll_ai_prompt_template` (
  `prompt_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `prompt_name` varchar(233) NOT NULL COMMENT '模板名称',
  `group_id` bigint(20) NOT NULL COMMENT '关联分组ID（外键，模板仅属于一个分组）',
  `scene_id` bigint(20) NOT NULL COMMENT '关联场景ID（外键，模板仅属于一个场景）',
  `model_id` bigint(20) NOT NULL COMMENT '关联模型ID（外键，模板仅使用一个模型）',
  `prompt_content` text NOT NULL COMMENT 'Prompt模板内容（含变量占位符）',
  `prompt_variable_config` text COMMENT '变量配置（JSON格式字符串，示例：[{"name":"team","type":"string","required":true}]）',
  `prompt_custom_config_params` text COMMENT '模板自定义参数（JSON格式字符串，覆盖模型默认参数）',
  `prompt_status` char(1) DEFAULT '0' COMMENT '状态（0正常 1停用）',
  `prompt_remark` varchar(1023) DEFAULT '' COMMENT '备注',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`prompt_id`),
  KEY `idx_group_id` (`group_id`) COMMENT '分组ID索引（快速按分组查询模板）',
  KEY `idx_scene_id` (`scene_id`) COMMENT '场景ID索引（快速按场景查询模板）',
  KEY `idx_model_id` (`model_id`) COMMENT '模型ID索引（快速按模型查询模板）',
  KEY `idx_group_scene_model` (`group_id`, `scene_id`, `model_id`) COMMENT '分组+场景+模型组合索引（优化多维度组合查询）',
  KEY `idx_prompt_status` (`prompt_status`) COMMENT '模板状态索引（快速筛选启用/停用模板）',
  FOREIGN KEY (`group_id`) REFERENCES `fx67ll_ai_prompt_group`(`group_id`) ON DELETE RESTRICT COMMENT '分组外键：删除分组时禁止删除关联模板',
  FOREIGN KEY (`scene_id`) REFERENCES `fx67ll_ai_prompt_scene`(`scene_id`) ON DELETE RESTRICT COMMENT '场景外键：删除场景时禁止删除关联模板',
  FOREIGN KEY (`model_id`) REFERENCES `fx67ll_ai_prompt_model`(`model_id`) ON DELETE RESTRICT COMMENT '模型外键：删除模型时禁止删除关联模板'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt模板管理表';
```

#### 2. AI Prompt模板分组表
```sql
CREATE TABLE `fx67ll_ai_prompt_group` (
  `group_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分组ID（主键）',
  `group_code` varchar(233) NOT NULL COMMENT '分组编码（如football_analysis、code_helper）',
  `group_name` varchar(233) NOT NULL COMMENT '分组名称（如足球分析、代码助手）',
  `group_desc` varchar(1023) DEFAULT '' COMMENT '分组描述（如“跨场景的足球相关Prompt模板分组”）',
  `group_status` char(1) DEFAULT '0' COMMENT '状态（0正常 1停用）',
  `group_sort` int(4) DEFAULT 0 COMMENT '排序（用于前端展示，数值越小越靠前）',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`group_id`),
  UNIQUE KEY `uk_group_code` (`group_code`) COMMENT '分组编码唯一索引：防止分组编码重复',
  KEY `idx_group_status` (`group_status`) COMMENT '分组状态索引（快速筛选启用/停用分组）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt模板分组表';
```

#### 3. AI Prompt场景管理表
```sql
CREATE TABLE `fx67ll_ai_prompt_scene` (
  `scene_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '场景ID（主键）',
  `scene_code` varchar(233) NOT NULL COMMENT '场景编码（如football_pre_match，唯一标识场景，用于接口/配置关联）',
  `scene_name` varchar(233) NOT NULL COMMENT '场景名称',
  `scene_desc` varchar(1023) DEFAULT '' COMMENT '场景描述',
  `scene_remark` varchar(1023) DEFAULT '' COMMENT '备注',
  `scene_status` char(1) DEFAULT '0' COMMENT '状态（0正常 1停用）',
  `scene_sort` int(4) DEFAULT 0 COMMENT '排序（用于前端展示，数值越小越靠前）',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`scene_id`),
  UNIQUE KEY `uk_scene_code` (`scene_code`) COMMENT '场景编码唯一索引：防止场景编码重复',
  KEY `idx_scene_status` (`scene_status`) COMMENT '场景状态索引（快速筛选启用/停用场景）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt场景管理表';
```

#### 4. AI Prompt模型配置表
```sql
CREATE TABLE `fx67ll_ai_prompt_model` (
  `model_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '模型ID（主键）',
  `model_code` varchar(233) NOT NULL COMMENT '模型编码（如deepseek_chat/doubao_pro）',
  `model_name` varchar(233) NOT NULL COMMENT '模型名称（如DeepSeek通用对话模型/豆包Pro）',
  `model_vendor` varchar(233) NOT NULL COMMENT '厂商标识（如deepseek/doubao/tongyi）',
  `model_api_key` varchar(1023) NOT NULL COMMENT 'API密钥键（关联fx67ll_secret_key.secret_key，字段类型varchar(1023)）',
  `model_secret_key` varchar(1023) DEFAULT '' COMMENT 'Secret密钥键（关联fx67ll_secret_key.secret_key，可为空）',
  `model_api_url` varchar(233) NOT NULL COMMENT '模型API调用地址',
  `model_api_version` varchar(10) DEFAULT 'v1' COMMENT 'API版本（如v1/v3，贴合主流模型默认值）',
  `model_config_params` text NOT NULL COMMENT '模型配置参数（JSON格式字符串，兼容所有模型参数）',
  `model_request_header` text COMMENT '请求头配置（JSON格式字符串）',
  `model_remark` varchar(1023) DEFAULT '' COMMENT '备注',
  `model_status` char(1) DEFAULT '0' COMMENT '状态（0正常 1停用）',
  `model_sort` int(4) DEFAULT 0 COMMENT '排序（前端展示用，数值越小越靠前）',
  `model_token_price` decimal(10,6) DEFAULT 0.000000 COMMENT '每1000 token价格（元），用于计算调用费用',
  `model_token_currency` varchar(10) DEFAULT 'CNY' COMMENT '计价货币（默认CNY，支持USD等）',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`model_id`),
  UNIQUE KEY `uk_model_code` (`model_code`) COMMENT '模型编码唯一索引：避免重复配置同一模型',
  KEY `idx_model_vendor_status` (`model_vendor`, `model_status`) COMMENT '厂商+状态组合索引（快速筛选某厂商的启用模型）',
  KEY `idx_model_status` (`model_status`) COMMENT '模型状态索引（快速筛选启用/停用模型）',
  CONSTRAINT `fk_model_api_key` FOREIGN KEY (`model_api_key`) REFERENCES `fx67ll_secret_key`(`secret_key`) ON DELETE RESTRICT COMMENT 'API密钥外键：删除密钥时禁止删除关联模型'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt模型配置表';
```

#### 5. AI Prompt 限流/熔断规则表（适配Sentinel框架）
```sql
CREATE TABLE `fx67ll_ai_prompt_limit_rule` (
  `limit_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '限流/熔断规则主键ID',
  `limit_dimension` char(2) NOT NULL COMMENT '规则维度（1:模型 2:模板 3:场景 4:分组）',
  `limit_target_id` bigint(20) NOT NULL COMMENT '关联维度ID（如model_id/prompt_id/scene_id/group_id）',
  `limit_type` char(2) NOT NULL COMMENT '规则类型（1:流控 2:熔断）',
  `flow_control_mode` char(1) DEFAULT 'D' COMMENT '流控模式（D:直接  A:关联  L:链路，仅limit_type=1时有效）',
  `flow_control_effect` char(1) DEFAULT 'F' COMMENT '流控效果（F:快速失败 W:WarmUp Q:排队等待，仅limit_type=1时有效）',
  `flow_rule_type` char(1) DEFAULT 'Q' COMMENT '流控规则类型（Q:QPS C:并发数，仅limit_type=1时有效）',
  `flow_threshold` decimal(10,2) NOT NULL COMMENT '流控阈值（QPS/并发数，保留2位小数）',
  `circuit_strategy` char(1) DEFAULT 'S' COMMENT '熔断策略（S:慢调用比例 E:异常比例 N:异常数，仅limit_type=2时有效）',
  `circuit_threshold` decimal(10,2) DEFAULT 0.5 COMMENT '熔断阈值（慢调用比例/异常比例:0-1；异常数:整数，保留2位小数）',
  `circuit_grade` int(4) DEFAULT 500 COMMENT '慢调用阈值（ms，仅circuit_strategy=S时有效）',
  `circuit_window` int(4) DEFAULT 10000 COMMENT '统计窗口时长（ms，默认10s，仅limit_type=2时有效）',
  `circuit_timeout` int(4) DEFAULT 5000 COMMENT '熔断恢复时间（ms，默认5s，仅limit_type=2时有效）',
  `limit_status` char(1) DEFAULT '0' COMMENT '规则状态（0:启用 1:停用）',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`limit_id`),
  KEY `idx_limit_dim_target` (`limit_dimension`, `limit_target_id`) COMMENT '维度+目标ID索引（快速查询某维度下的规则）',
  KEY `idx_limit_type_status` (`limit_type`, `limit_status`) COMMENT '规则类型+状态索引（筛选启用的流控/熔断规则）',
  KEY `idx_limit_dim_type_status` (`limit_dimension`, `limit_type`, `limit_status`) COMMENT '维度+类型+状态索引（高频查询：某维度启用的流控/熔断规则）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Prompt 限流/熔断规则表（适配Sentinel框架）';
```

#### 6. AI 调用请求日志表（按request_time月份分区）
```sql
CREATE TABLE `fx67ll_ai_request_log` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID（主键）',
  `prompt_id` bigint(20) DEFAULT NULL COMMENT '使用的模板ID（可为空，若直接调用非模板）',
  `scene_id` bigint(20) DEFAULT NULL COMMENT '关联场景ID',
  `model_id` bigint(20) NOT NULL COMMENT '调用的模型ID',
  `model_vendor` varchar(233) NOT NULL COMMENT '模型厂商（冗余存储，避免关联查询）',
  `request_content` text COMMENT '请求内容（含最终渲染后的Prompt）',
  `response_content` text COMMENT '响应内容（大文本存储）',
  `prompt_tokens` int(11) DEFAULT 0 COMMENT '输入token数',
  `completion_tokens` int(11) DEFAULT 0 COMMENT '输出token数',
  `total_tokens` int(11) DEFAULT 0 COMMENT '总token数',
  `cost` decimal(10,6) DEFAULT 0.000000 COMMENT '预估费用（元）',
  `duration_ms` int(11) DEFAULT 0 COMMENT '请求耗时（毫秒）',
  `http_status` int(3) DEFAULT NULL COMMENT 'HTTP状态码',
  `call_status` char(2) DEFAULT '00' COMMENT '调用状态（00:成功 01:失败 02:限流 03:熔断）',
  `error_msg` text COMMENT '错误信息',
  `caller_ip` varchar(233) DEFAULT '' COMMENT '调用者IP',
  `request_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '请求时间（精确到秒）',
  `create_by` varchar(64) DEFAULT '' COMMENT '调用者标识',
  PRIMARY KEY (`log_id`, `request_time`),
  KEY `idx_request_time` (`request_time`),
  KEY `idx_prompt_id` (`prompt_id`),
  KEY `idx_scene_id` (`scene_id`),
  KEY `idx_model_id` (`model_id`),
  KEY `idx_create_by` (`create_by`),
  KEY `idx_call_status` (`call_status`),
  KEY `idx_request_time_vendor` (`request_time`, `model_vendor`),
  KEY `idx_scene_model_time` (`scene_id`, `model_id`, `request_time`),
  KEY `idx_create_by_time` (`create_by`, `request_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 
PARTITION BY RANGE (TO_DAYS(request_time)) (
  PARTITION p202603 VALUES LESS THAN (TO_DAYS('2026-04-01')), -- 2026年3月
  PARTITION p202604 VALUES LESS THAN (TO_DAYS('2026-05-01')), -- 2026年4月
  PARTITION p202605 VALUES LESS THAN (TO_DAYS('2026-06-01')), -- 2026年5月
  PARTITION p_default VALUES LESS THAN MAXVALUE -- 默认分区（防止未提前创建月份分区）
) COMMENT='AI 调用请求日志表（按request_time月份分区）';
```

#### 7. AI 调用请求日统计日志表
```sql
CREATE TABLE `fx67ll_ai_request_daily_log` (
  `daily_log_date` date NOT NULL COMMENT '统计日期（yyyy-MM-dd）',
  `model_id` bigint(20) NOT NULL COMMENT '模型ID',
  `scene_id` bigint(20) NOT NULL COMMENT '场景ID（可选，若需要场景级统计）',
  `total_requests` int(11) DEFAULT 0 COMMENT '总请求次数',
  `fail_requests` int(11) DEFAULT 0 COMMENT '失败请求次数',
  `limit_requests` int(11) DEFAULT 0 COMMENT '限流请求次数',
  `circuit_requests` int(11) DEFAULT 0 COMMENT '熔断请求次数',
  `total_prompt_tokens` bigint(20) DEFAULT 0 COMMENT '总输入token数',
  `total_completion_tokens` bigint(20) DEFAULT 0 COMMENT '总输出token数',
  `total_cost` decimal(12,6) DEFAULT 0.000000 COMMENT '总费用（元）',
  `avg_duration_ms` int(11) DEFAULT 0 COMMENT '平均耗时（毫秒，计算逻辑：总耗时/总请求数）',
  PRIMARY KEY (`daily_log_date`, `model_id`, `scene_id`) COMMENT '复合主键：日期+模型+场景（唯一确定一条日统计记录）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI 调用请求日统计日志表';
```

#### 8. AI 调用请求月统计日志表
```sql
CREATE TABLE `fx67ll_ai_request_monthly_log` (
  `monthly_log_month` varchar(7) NOT NULL COMMENT '统计年月（yyyy-MM）',
  `model_id` bigint(20) NOT NULL COMMENT '模型ID',
  `scene_id` bigint(20) NOT NULL COMMENT '场景ID（可选，若需要场景级统计）',
  `total_requests` int(11) DEFAULT 0 COMMENT '月总请求次数',
  `fail_requests` int(11) DEFAULT 0 COMMENT '月失败请求次数',
  `limit_requests` int(11) DEFAULT 0 COMMENT '月限流请求次数',
  `circuit_requests` int(11) DEFAULT 0 COMMENT '月熔断请求次数',
  `total_prompt_tokens` bigint(20) DEFAULT 0 COMMENT '月总输入token数',
  `total_completion_tokens` bigint(20) DEFAULT 0 COMMENT '月总输出token数',
  `total_cost` decimal(12,6) DEFAULT 0.000000 COMMENT '月总费用（元）',
  `avg_duration_ms` int(11) DEFAULT 0 COMMENT '月平均耗时（毫秒）',
  PRIMARY KEY (`monthly_log_month`, `model_id`, `scene_id`) COMMENT '复合主键：年月+模型+场景（唯一确定一条月统计记录）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI 调用请求月统计日志表';
```

#### 9. AI 调用请求年统计日志表
```sql
CREATE TABLE `fx67ll_ai_request_yearly_log` (
  `yearly_log_year` varchar(4) NOT NULL COMMENT '统计年份（yyyy）',
  `model_id` bigint(20) NOT NULL COMMENT '模型ID',
  `scene_id` bigint(20) NOT NULL COMMENT '场景ID（可选，若需要场景级统计）',
  `total_requests` bigint(20) DEFAULT 0 COMMENT '年总请求次数',
  `total_prompt_tokens` bigint(20) DEFAULT 0 COMMENT '年总输入token数',
  `total_completion_tokens` bigint(20) DEFAULT 0 COMMENT '年总输出token数',
  `total_cost` decimal(14,6) DEFAULT 0.000000 COMMENT '年总费用（元，保留6位小数）',
  `avg_duration_ms` int(11) DEFAULT 0 COMMENT '年平均耗时（毫秒）',
  PRIMARY KEY (`yearly_log_year`, `model_id`, `scene_id`) COMMENT '复合主键：年份+模型+场景（唯一确定一条年统计记录）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI 调用请求年统计日志表';
```

---

### 三、AI重要必需的业务逻辑补充
+ 统计数据汇总表：日志表数据量会快速增长，直接对海量数据做统计报表可能性能不佳。建议按年月日预聚合，创建汇总表。可通过定时任务（如每天凌晨）或异步队列在每次请求后更新汇总表。这样报表查询极快，无需扫描原始日志。  
+ 业务需求包括：会员账号积分体系（后续如果对接支付系统，只需要按比例充钱给积分就好了）  
+ Prompt 管理站点，模板编辑后支持一键测试，输入变量示例，调用 AI API 并展示响应结果，便于调试  
+ 开发一个服务，根据variable_config解析传入变量，替换模板中的占位符（如{home_team}）  
+ 对于耗时长的分析任务，可设计任务表，将请求放入消息队列（如RocketMQ），后台消费者异步调用AI，轮询结果后通知前端  
+ 设置限流、熔断（大概率使用Sentinel），防止恶意调用  
+ 调用相应厂商的API，记录请求日志（包含请求/响应、token消耗、耗时等），提供token消耗统计报表，便于成本控制


---

### 四、比赛业务流程闭环设计思路说明
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

### 五、比赛业务表设计（与若依风格统一）
#### 1. 赛季管理表
```sql
CREATE TABLE `fx67ll_dortmund_season` (
  `season_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '赛季ID（主键）',
  `season_code` varchar(23) NOT NULL COMMENT '赛季编码（如2025-2026，唯一标识）',
  `season_name` varchar(233) NOT NULL COMMENT '赛季名称（如2025-2026赛季）',
  `season_remark` varchar(1023) DEFAULT '' COMMENT '赛季备注（如“包含欧冠、英超等主流赛事”）',
  `start_date` date NOT NULL COMMENT '赛季开始日期',
  `end_date` date NOT NULL COMMENT '赛季结束日期',
  `season_status` char(1) DEFAULT '0' COMMENT '赛季状态（0正常 1停用）',
  `season_sort` int(4) DEFAULT 0 COMMENT '赛季排序（前端展示用）',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`season_id`),
  UNIQUE KEY `uk_season_code` (`season_code`) COMMENT '赛季编码唯一索引',
  KEY `idx_season_status` (`season_status`) COMMENT '赛季状态索引（筛选启用/停用赛季）',
  KEY `idx_season_sort` (`season_sort`) COMMENT '赛季排序索引（前端展示排序）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='赛季管理表';
```

### 2. 球队管理表
```sql
CREATE TABLE `fx67ll_dortmund_team` (
  `team_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '球队ID（主键）',
  `team_code` varchar(23) NOT NULL COMMENT '球队编码（如dort，唯一标识）',
  `team_name` varchar(233) NOT NULL COMMENT '球队名称（如多特蒙德）',
  `team_name_short` varchar(10) DEFAULT '' COMMENT '球队简称或外号（如多特叫我横）',
  `team_name_en` varchar(233) DEFAULT '' COMMENT '球队英文名称（如Manchester City）',
  `team_logo_url` varchar(1023) DEFAULT '' COMMENT '球队Logo地址',
  `team_country` varchar(23) DEFAULT '' COMMENT '球队所属国家/地区（如英格兰、西班牙）',
  `team_remark` varchar(1023) DEFAULT '' COMMENT '球队备注',
  `team_status` char(1) DEFAULT '0' COMMENT '球队状态（0正常 1停用）',
  `team_sort` int(4) DEFAULT 0 COMMENT '球队排序（前端展示用）',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`team_id`),
  UNIQUE KEY `uk_team_code` (`team_code`) COMMENT '球队编码唯一索引',
  KEY `idx_team_status` (`team_status`) COMMENT '球队状态索引（筛选启用/停用球队）',
  KEY `idx_team_sort` (`team_sort`) COMMENT '球队排序索引（前端展示排序）',
  KEY `idx_team_country` (`team_country`) COMMENT '球队国家索引（筛选某国球队）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='球队管理表';
```

### 3. 比赛记录表
```sql
CREATE TABLE `fx67ll_dortmund_match` (
  `match_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '比赛ID（主键）',
  `match_code` varchar(50) NOT NULL COMMENT '比赛编码（可考虑使用 season_code + 日期 + 主客队编码 拼接，确保唯一且可读）',
  `season_id` bigint(20) NOT NULL COMMENT '关联赛季ID（外键）',
  `home_team_id` bigint(20) NOT NULL COMMENT '主队ID（外键）',
  `away_team_id` bigint(20) NOT NULL COMMENT '客队ID（外键）',
  `match_time` datetime NOT NULL COMMENT '比赛时间',
  `match_venue` varchar(233) DEFAULT '' COMMENT '比赛场地（如伊杜纳信号公园球场）',
  `match_remark` varchar(1023) DEFAULT '' COMMENT '比赛备注（如欧冠1/4决赛首回合）',
  `match_status` char(1) DEFAULT '0' COMMENT '比赛状态（0未开始 1进行中 2已结束）',
  `analysis_count` int(4) DEFAULT 0 COMMENT '分析次数（替代原analysis_status，体现多次分析）',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`match_id`),
  UNIQUE KEY `uk_match_code` (`match_code`) COMMENT '比赛编码唯一索引',
  KEY `idx_season_id` (`season_id`) COMMENT '赛季ID索引',
  KEY `idx_home_team_id` (`home_team_id`) COMMENT '主队ID索引',
  KEY `idx_away_team_id` (`away_team_id`) COMMENT '客队ID索引',
  KEY `idx_match_time` (`match_time`) COMMENT '比赛时间索引',
  KEY `idx_match_status` (`match_status`) COMMENT '比赛状态索引',
  KEY `idx_match_create` (`match_id`, `create_time`) COMMENT '比赛+创建时间（高频：按创建时间倒序）',
  KEY `idx_season_match_status` (`season_id`, `match_status`) COMMENT '赛季+比赛状态索引（高频：按赛季查未开始比赛）',
  KEY `idx_season_match_time` (`season_id`, `match_time`) COMMENT '赛季+比赛时间索引（高频：某赛季的比赛列表按时间排序）',
  KEY `idx_match_time_status` (`match_time`, `match_status`) COMMENT '比赛时间+状态索引（高频：查近期未开始比赛）',
  FOREIGN KEY (`season_id`) REFERENCES `fx67ll_football_season`(`season_id`) ON DELETE RESTRICT COMMENT '赛季外键：删除赛季时禁止删除关联比赛',
  FOREIGN KEY (`home_team_id`) REFERENCES `fx67ll_football_team`(`team_id`) ON DELETE RESTRICT COMMENT '主队外键：删除球队时禁止删除关联比赛',
  FOREIGN KEY (`away_team_id`) REFERENCES `fx67ll_football_team`(`team_id`) ON DELETE RESTRICT COMMENT '客队外键：删除球队时禁止删除关联比赛'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='比赛记录表';
```

### 4. AI比赛分析原始结果表
```sql
CREATE TABLE `fx67ll_dortmund_match_analysis` (
  `analysis_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分析ID（主键）',
  `match_id` bigint(20) NOT NULL COMMENT '关联比赛ID（外键）',
  `prompt_id` bigint(20) DEFAULT NULL COMMENT '使用的Prompt模板ID（外键，关联fx67ll_ai_prompt_template，自定义分析时为空）',
  `model_id` bigint(20) NOT NULL COMMENT '使用的模型ID（外键，关联fx67ll_ai_prompt_model）',
  `ai_request_log_id` bigint(20) DEFAULT NULL COMMENT '关联AI调用日志ID（外键，自定义文本分析时为空）',
  `analysis_type` char(1) DEFAULT '0' COMMENT '分析类型（0模板分析 1自定义文本分析）',
  `raw_prompt` text NOT NULL COMMENT '最终渲染后的Prompt（含球队/比赛数据，自定义分析时为用户输入文本）',
  `raw_ai_response` text NOT NULL COMMENT 'AI返回的原始JSON结果',
  `analysis_remark` varchar(1023) DEFAULT '' COMMENT '分析备注',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',
  PRIMARY KEY (`analysis_id`),
  KEY `idx_match_id` (`match_id`) COMMENT '比赛ID索引',
  KEY `idx_prompt_id` (`prompt_id`) COMMENT 'Prompt模板ID索引',
  KEY `idx_model_id` (`model_id`) COMMENT '模型ID索引',
  KEY `idx_create_time` (`create_time`) COMMENT '创建时间索引',
  KEY `idx_ai_request_log_id` (`ai_request_log_id`) COMMENT 'AI调用日志ID索引（关联日志查询）',
  KEY `idx_match_prompt_model` (`match_id`, `prompt_id`, `model_id`) COMMENT '比赛+模板+模型索引（高频：查某比赛的特定模板分析）',
  KEY `idx_analysis_type` (`analysis_type`) COMMENT '分析类型索引（筛选模板/自定义分析）',
  FOREIGN KEY (`match_id`) REFERENCES `fx67ll_football_match`(`match_id`) ON DELETE RESTRICT COMMENT '比赛外键：删除比赛时禁止删除关联分析',
  FOREIGN KEY (`prompt_id`) REFERENCES `fx67ll_ai_prompt_template`(`prompt_id`) ON DELETE RESTRICT COMMENT 'Prompt模板外键：删除模板时禁止删除关联分析',
  FOREIGN KEY (`model_id`) REFERENCES `fx67ll_ai_prompt_model`(`model_id`) ON DELETE RESTRICT COMMENT '模型外键：删除模型时禁止删除关联分析',
  FOREIGN KEY (`ai_request_log_id`) REFERENCES `fx67ll_ai_request_log`(`log_id`) ON DELETE RESTRICT COMMENT 'AI日志外键：删除日志时禁止删除关联分析'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI比赛分析原始结果表';
```

### 5. 比赛标准化评分表
```sql
CREATE TABLE `fx67ll_dortmund_match_score` (
  `score_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '评分ID（主键）',
  `analysis_id` bigint(20) NOT NULL COMMENT '关联分析ID（外键）',
  `match_id` bigint(20) NOT NULL COMMENT '关联比赛ID（外键，冗余字段，便于查询）',

  -- 主队评分
  `home_attack_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队进攻评分（0-100）',
  `home_defense_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队防守评分（0-100）',
  `home_injury_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队伤病评分（0-100，越高越健康）',
  `home_history_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队历史交锋评分（0-100）',
  `home_total_score` decimal(5,2) DEFAULT 0.00 COMMENT '主队总评分（0-100）',

  -- 客队评分
  `away_attack_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队进攻评分（0-100）',
  `away_defense_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队防守评分（0-100）',
  `away_injury_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队伤病评分（0-100）',
  `away_history_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队历史交锋评分（0-100）',
  `away_total_score` decimal(5,2) DEFAULT 0.00 COMMENT '客队总评分（0-100）',

  -- 预测结果
  `predicted_result` char(1) DEFAULT '0' COMMENT '预测结果（0主队胜 1平局 2客队胜）',
  `predicted_confidence` decimal(5,2) DEFAULT 0.00 COMMENT '预测置信度（0-100）',
  `score_calc_rule_version` varchar(23) DEFAULT '1' COMMENT '评分计算规则版本（便于追溯规则变更）',

  -- 扩展评分字段：JSON字符串（varchar类型，仅存储不查询）
  `extra_score_str` varchar(2333) DEFAULT NULL COMMENT '扩展评分JSON字符串',

  -- 基础通用字段
  `score_remark` varchar(1023) DEFAULT '' COMMENT '评分备注',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` char(1) DEFAULT '0' COMMENT '删除标志（0存在 2删除）',

  -- 索引与约束
  PRIMARY KEY (`score_id`),
  UNIQUE KEY `uk_analysis_id` (`analysis_id`) COMMENT '分析ID唯一索引（一个分析对应一个评分）',
  KEY `idx_match_id` (`match_id`) COMMENT '比赛ID索引',
  KEY `idx_predicted_result` (`predicted_result`) COMMENT '预测结果索引',
  KEY `idx_create_time` (`create_time`) COMMENT '评分创建时间索引（查近期评分）',
  KEY `idx_match_predicted_result` (`match_id`, `predicted_result`) COMMENT '比赛+预测结果索引（高频：查某比赛的预测结果）',

  -- 核心字段范围约束（保证基础评分有效性）
  CONSTRAINT `chk_confidence_range` CHECK (`predicted_confidence` BETWEEN 0 AND 100),
  CONSTRAINT `chk_home_total_range` CHECK (`home_total_score` BETWEEN 0 AND 100),
  CONSTRAINT `chk_away_total_range` CHECK (`away_total_score` BETWEEN 0 AND 100),

  -- 外键约束
  FOREIGN KEY (`analysis_id`) REFERENCES `fx67ll_football_match_analysis`(`analysis_id`) ON DELETE RESTRICT COMMENT '分析外键：删除分析时禁止删除关联评分',
  FOREIGN KEY (`match_id`) REFERENCES `fx67ll_football_match`(`match_id`) ON DELETE RESTRICT COMMENT '比赛外键：删除比赛时禁止删除关联评分'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='比赛标准化评分表';
```

---

### 六、与现有AI业务系统的对接要点
| 现有AI系统表 | 新增业务表 | 对接方式 |
|--------------|------------|----------|
| `fx67ll_ai_prompt_template` | `fx67ll_football_match_analysis` | 分析时选择模板，关联 `prompt_id`，建议在足球业务中创建专属分组（如 football_analysis）和场景（如 pre_match），便于前端按分组筛选模板 |
| `fx67ll_ai_prompt_model` | `fx67ll_football_match_analysis` | 关联 `model_id`，复用模型配置 |
| `fx67ll_ai_request_log` | `fx67ll_football_match_analysis` | 分析表关联 log_id	在调用 AI 后，将生成的日志 ID 回填至分析表，关联 `ai_request_log_id`，实现全链路追踪 |
| `fx67ll_ai_prompt_limit_rule` | - | 调用AI时自动触发限流熔断，无需额外关联 |

---

### 七、比赛分析重要必需的业务逻辑补充
1. 新增比赛时，校验`home_team_id != away_team_id`（避免主队 = 客队）；
2. 分析次数更新：每次新增`match_analysis`记录时，同步更新`match`表的`analysis_count += 1`；
3. 自定义分析时，`prompt_id`和`ai_request_log_id`置空，`analysis_type`设为 1；
