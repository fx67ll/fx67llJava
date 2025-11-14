# 使用若依开发一套基础CRUD业务时候的标准流程

这篇博文，记录一下自己总结的快速开发流程，看到的朋友请忽略我的水文~  

## 前言
我也想顺便记录下自己这两年开发的一些小感触，随着AI的快速发展，导致我在接触一些工作中难以思考和负责的后端复杂业务之时，
可以非常方便快速的获得大量的思路和灵感，甚至完全使用AI生成的解决方案，这对于效率和知识边界的改变是巨大的。

虽然会有一定试错成本，但是新人码农获得了巨大的机会快速成长，在我这么多年的工作经验看来，真的是时代的机遇。

未来，熟练使用AI的码农和故步自封的码农一定会在短时间内形成非常大的差距，最近一段时间，我必须强迫自己快速学习AI领域的开发和业务经验。  

只有不断学习这一条道路，才有一定可能，让自己在喜爱的代码开发领域，有一席工作的机会。


## 前后端公共标准流程
1. 考虑功能点，设计表结构  
2. 使用若依管理系统同步表结构数据，点击导出代码  
3. 压缩包里直接包含了前后端最基础的CRUD代码


## 后端公共代码补充流程
1. 导出的后台代码修改 import package 的路径，格式化代码
	+ PS1: 需要仔细检查包括 mapper.xml 里面也可能有 import 地址是错的
	+ PS2: 新建文件夹一定要小心打开资源文件夹看看是否正确生成了，idea中resource下面生成mapper文件夹的.符合不会自动生成2个文件夹，但是package可以
2. mapper.xml 里的列表查询 sql 添加按创建时间倒序的排序 `order by STR_TO_DATE(update_time, "%Y-%m-%d %H:%i:%s") desc`  
3. service + serviceimpl 添加 ByUserId 的列表查询接口
4. serviceimpl 添加诸如以下的代码，fx67ll替换各自的实体类
```java
fx67ll.setUserId(SecurityUtils.getUserId());
fx67ll.setCreateBy(SecurityUtils.getUsername());
fx67ll.setCreateTime(DateUtils.getNowDate());
fx67ll.setUpdateBy(SecurityUtils.getUsername());
fx67ll.setUpdateTime(DateUtils.getNowDate());
```
5. controller 里的列表查询接口添加以下代码判断，非管理员不允许查询所有数据
```java
if (SecurityUtils.getUsername().equals("fx67ll")) {
	List<Fx67ll> list = fx67llService.selectFx67llList(fx67ll);
	return getDataTable(list);
} else {
	List<Fx67ll> list = fx67llService.selectFx67llListByUserId(fx67ll);
	return getDataTable(list);
}
```
6. domain 里添加前端后期查询需要的时间区间字段
```java
/**
 * 创建开始时间
 */
private String beginCreateTime;

/**
 * 创建结束时间
 */
private String endCreateTime;

/**
 * 更新开始时间
 */
private String beginUpdateTime;

/**
 * 更新结束时间
 */
private String endUpdateTime;


public String getBeginCreateTime() {
	return beginCreateTime;
}

public void setBeginCreateTime(String beginCreateTime) {
	this.beginCreateTime = beginCreateTime;
}

public String getEndCreateTime() {
	return endCreateTime;
}

public void setEndCreateTime(String endCreateTime) {
	this.endCreateTime = endCreateTime;
}

public String getBeginUpdateTime() {
	return beginUpdateTime;
}

public void setBeginUpdateTime(String beginUpdateTime) {
	this.beginUpdateTime = beginUpdateTime;
}

public String getEndUpdateTime() {
	return endUpdateTime;
}

public void setEndUpdateTime(String endUpdateTime) {
	this.endUpdateTime = endUpdateTime;
}
```
7. mapper.xml 里的列表查询的where条件添加相关时间参数
```xml
<if test="delFlag != null  and delFlag != ''">and del_flag = #{delFlag}</if>
<if test="userId != null ">and user_id = #{userId}</if>
<if test="createBy != null  and createBy != ''">and create_by = #{createBy}</if>
<if test="beginCreateTime != null and endCreateTime != ''">and create_time between #{beginCreateTime} and
	#{endCreateTime}
</if>
<if test="updateBy != null  and updateBy != ''">and update_by = #{updateBy}</if>
<if test="beginUpdateTime != null and endUpdateTime != ''">and update_time between #{beginUpdateTime} and
	#{endUpdateTime}
</if>
```


## 前端公共代码补充流程
1. 把api文件放到指定目录，修改导入路径 ` "@/api/fx67ll/"`  
2. el-dialog 添加只允许点击close关闭的属性 `:close-on-click-modal="false"`  
3. 查询表单添加时间相关参数
```vue
<el-form-item label="创建时间">
<el-date-picker v-model="daterangeCreateTime" style="width: 240px" value-format="yyyy-MM-dd" type="daterange"
  range-separator="-" start-placeholder="开始日期" end-placeholder="结束日期" clearable></el-date-picker>
</el-form-item>
<el-form-item label="更新时间">
<el-date-picker v-model="daterangeUpdateTime" style="width: 240px" value-format="yyyy-MM-dd" type="daterange"
  range-separator="-" start-placeholder="开始日期" end-placeholder="结束日期" clearable></el-date-picker>
</el-form-item>
```
4. 表格里添加相关记录信息
```vue
<el-table-column label="记录创建者" align="center" prop="createBy" width="100" />
<el-table-column label="记录创建时间" align="center" prop="createTime" width="160">
<template slot-scope="scope">
  <span>{{ parseTime(scope.row.createTime, "{y}-{m}-{d} {h}:{i}:{s}") }}
  </span>
</template>
</el-table-column>
<el-table-column label="记录更新者" align="center" prop="updateBy" width="100" />
<el-table-column label="记录更新时间" align="center" prop="updateTime" width="160">
<template slot-scope="scope">
  <span>{{
	parseTime(scope.row.updateTime, "{y}-{m}-{d} {h}:{i}:{s}")
  }}</span>
</template>
</el-table-column>
```
5. 查询方法里添加时间相关代码
```js
// 重置时间段查询
clearDateQueryParams() {
  this.queryParams.beginCreateTime = null;
  this.queryParams.endCreateTime = null;
  this.queryParams.beginUpdateTime = null;
  this.queryParams.endUpdateTime = null;
}
```
6. getList 方法添加相关时间查询逻辑
```js
this.clearDateQueryParams();
if (null != this.daterangeCreateTime && "" != this.daterangeCreateTime) {
  this.queryParams.beginCreateTime = this.daterangeCreateTime[0];
  this.queryParams.endCreateTime = this.daterangeCreateTime[1];
}
if (null != this.daterangeUpdateTime && "" != this.daterangeUpdateTime) {
  this.queryParams.beginUpdateTime = this.daterangeUpdateTime[0];
  this.queryParams.endUpdateTime = this.daterangeUpdateTime[1];
}
```
7. 添加时间查询相关参数
```js
// 创建时间范围
daterangeCreateTime: [],
// 更新时间范围
daterangeUpdateTime: [],
// 查询参数
queryParams: {
	// 原来的参数基础上追加
	beginCreateTime: null,
	endCreateTime: null,
	beginUpdateTime: null,
	endUpdateTime: null,

}
```
8. getList 方法添加处置表格空值的公共方法 `this.formatObjectArrayNullProperty(response.rows);`  