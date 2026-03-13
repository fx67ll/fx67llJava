# 功能设计大纲
*最后更新时间：2026年3月4日18:00PM（后期暂不更新了，仅做前期简单记录）*

--- 

### 前言
我已经通过若依落地了个人业务管理系统，整体架构大致是`SpringBoot + Mysql + Vue2`  
现在我想在这个业务系统上，再设计一个AI比赛赛前信息分析评分系统  

---

### 一、AI 业务表设计
```sql
-- AI Prompt 模板表
DROP TABLE IF EXISTS fx67ll_ai_prompt_template;
-- AI Prompt 模版分组表  
DROP TABLE IF EXISTS fx67ll_ai_prompt_group;
-- AI Prompt 场景编码表
DROP TABLE IF EXISTS fx67ll_ai_prompt_scene;
-- AI Prompt 模型配置表
DROP TABLE IF EXISTS fx67ll_ai_prompt_model;
-- AI 调用请求限流/熔断规则表（适配Sentinel框架）
DROP TABLE IF EXISTS fx67ll_ai_request_limit_rule;
-- AI 调用请求日志表
DROP TABLE IF EXISTS fx67ll_ai_request_log;
-- AI 调用请求日统计日志表
DROP TABLE IF EXISTS fx67ll_ai_request_daily_log;
-- AI 调用请求月统计日志表
DROP TABLE IF EXISTS fx67ll_ai_request_monthly_log;
-- AI 调用请求年统计日志表
DROP TABLE IF EXISTS fx67ll_ai_request_yearly_log;
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
```sql
-- 赛季管理表
DROP TABLE IF EXISTS fx67ll_dortmund_season;
-- 球队管理表
DROP TABLE IF EXISTS fx67ll_dortmund_team;
-- 比赛记录表
DROP TABLE IF EXISTS fx67ll_dortmund_match;
-- 比赛AI分析原始结果表
DROP TABLE IF EXISTS fx67ll_dortmund_match_analysis;
-- 比赛标准化评分表
DROP TABLE IF EXISTS fx67ll_dortmund_match_score;
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
