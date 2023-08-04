# Java & SpringBoot 知识点记录

*记录二次开发过程中涉及到的 Java & SpringBoot 知识点*  


### 注解、接参返参
```
@GetMapping
HttpServletRequest --> getParameter()
HttpServletResponse  --> setContentType()

@RequestMapping
用来处理请求地址映射的注解，可用于映射一个请求或一个方法，可以用在类或方法上。
用于方法上，表示在类的父路径下追加方法上注解中的地址将会访问到。
用于类上，表示类中的所有响应请求的方法都是以该地址作为父路径。
```

### 数据类型、包装类、工具类
```
int
byte[]  

Integer  --> parseInt()  
Double  --> compareTo()  
String  --> isEmpty()/equals()

List<>  
ArrayList<>  --> add()  
Base64  --> getEncoder().encodeToString()
Random  --> nextDouble()/nextInt()  
Math --> round()  
```
#### 参考资料
1. [Java 基本数据类型 - 四类八种](https://zhuanlan.zhihu.com/p/25439066)  
2. [JAVA基础编程——基本数据类型的包装类](https://blog.csdn.net/SAKURASANN/article/details/124647622)  


### 图片文件和图片流
```
BufferedImage  
ImageIO  --> createImageOutputStream()

File  
FileOutputStream  

OutputStream  --> write()/flush()/close()
BufferedOutputStream  
ByteArrayOutputStream  --> write()/toByteArray()

InputStream  --> read()/close()
inputStream2Base64  
```

### 异常
```
Exception  
IOException  
```

### 分层
```
1.entity(model)层:
model是模型的意思，与entity、domain、pojo类似，是存放实体的类，类中定义了多个类属性，并与数据库表的字段保持一致，一张表对应一个model类。 
主要用于定义与数据库对象应的属性，提供get/set方法,tostring方法,有参无参构造函数。

2.dao(mapper)层:
又被成为mapper层，叫数据持久层，先设计接口，然后在配置文件中进行配置其实现的关联。 
dao层的作用为访问数据库，向数据库发送sql语句，完成数据的增删改查任务。 数据持久化操作就是指，把数据放到持久化的介质中，同时提供增删改查操作，比如数据通过hibernate插入到数据库中

3.service层:
业务逻辑层，完成功能的设计 和dao层一样都是先设计接口，再创建要实现的类，然后在配置文件中进行配置其实现的关联。
接下来就可以在service层调用dao层的接口进行业务逻辑应用的处理。 service的impl是把mapper和service进行整合的文件 封装Service层的业务逻辑有利于业务逻辑的独立性和重复利用性。

4.controller层:
控制层，控制业务逻辑service，控制请求和响应，负责前后端交互 controller层主要调用Service层里面的接口控制具体的业务流程，控制的配置也要在配置文件中进行

业务逻辑总结：
controller层(处理前台发送的请求)--->service定义接口(业务逻辑)--->serviceImpl(对接口函数进行实现)
--->mapper(Mapper接口，方法名与Mapper.xml中定义的statement的id相同)--->mapper.xml(写sql语句查询数据库)
```
1. 简单说明 ———— [Springboot中各层分析](https://blog.csdn.net/javaargs/article/details/118276204)
2. 详细说明 ———— [五个分层维度：SpringBoot工程分层实战](https://blog.csdn.net/BASK2311/article/details/128198005)  


### pom.xml
```
modelVersion  指定了当前Maven模型的版本号，对于Maven2和Maven3来说，它只能是4.0.0
```
1. 说明了为什么modelVersion必须是`4.0.0` ———— [Maven详解](https://blog.csdn.net/m0_68006260/article/details/123771074)  
2. [Pom.xml详解](https://blog.csdn.net/lukabruce/article/details/129046286)


**最后更新时间：2023年8月4日**