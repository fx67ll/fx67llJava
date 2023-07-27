# Java & SpringBoot 知识点记录

*记录二次开发过程中涉及到的 Java & SpringBoot 知识点*  


### 注解、接参返参
```
@GetMapping

HttpServletRequest --> getParameter()
HttpServletResponse  --> setContentType()
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

**最后更新时间：2023年7月27日**