package com.fx67ll.jdbc;

import java.math.BigDecimal;
import java.sql.*;

public class jdbcTest {
    public void run() throws ClassNotFoundException, SQLException {
        String driverClassName = "com.mysql.cj.jdbc.Driver";

        // useUnicode=true
        // characterEncoding=UTF-8
        // 连接地址的其他参数说明：https://www.cnblogs.com/mracale/p/5842572.html

        // rewriteBatchedStatements=true 开启MySQL批处理，即多个语句拼接起来一次发送后执行
        // useServerPrepStmts=true 开启MySQL的预编译，sql占位符和值分开发送
        // 参考文章：https://blog.csdn.net/lgh1117/article/details/80212924

        // cachePrepStmts=true 开启MySQL的预编译缓存，即相同的语句只解析一次，原理是解析过存储，下次解析先检查是否有解析过
        // 参考文章一：https://blog.csdn.net/maqingbin8888/article/details/87897150
        // 参考文章二：https://axman.blog.csdn.net/article/details/6913527

        // mysql本身并没有预编译的概念，mysql只有一个query cache，预编译是jdbc的功能，开启预编译的同时开启预编译缓存，并且使用长连接比较有效果

        String dbUrl = "jdbc:mysql://localhost:3306/test?useUnicode=true&characterEncoding=UTF-8&rewriteBatchedStatements=true";

        String dbUsername = "localhost";
        String dbPassword = "localhost";
        Class.forName(driverClassName);
        Connection connection = DriverManager.getConnection(dbUrl, dbUsername, dbPassword);

//        // 1. 使用Statement发送sql，可能会导致sql注入攻击
//        // 获得Statement对象
//        Statement stmt = connection.createStatement();
//        // 获得ResultSet结果集
//        ResultSet rs = stmt.executeQuery("SELECT * FROM test");
//        // 循环打印结果集中的信息
//        while (rs.next()) {
//            int tid = rs.getInt(1);
//            String tName = rs.getString("name");
//            System.out.println(tid + "." + tName);
//        }
//        // 依次关闭
//        rs.close();
//        stmt.close();

//        // 2. 使用更为安全的PreparedStatement
//        String sql1 = "SELECT * FROM test WHERE name = ? AND id = ?";
//        PreparedStatement ptst = connection.prepareStatement(sql1);
//        ptst.setString(1, "zeta");
//        ptst.setString(2, "66");
//        ResultSet rs = ptst.executeQuery();
//        while (rs.next()) {
//            int tid = rs.getInt(1);
//            String tName = rs.getString("name");
//            System.out.println(tid + "." + tName);
//        }
//        rs.close();
//        ptst.close();


//        // 3. 插入十条数据
//        String[] arr = {"handset", "pad", "laptop", "desktop", "camera", "earphone",
//                "watcher", "memorybank", "harddisk", "udisk"};
//        try {
//            String sqlInsert = "INSERT INTO commoditytype (ctname) VALUES (?)";
//            PreparedStatement ptst = (PreparedStatement) connection.prepareStatement(sqlInsert);
//            for (int i = 0; i < arr.length; i++) {
//                ptst.setString(1, arr[i]);
//                ptst.executeUpdate();
//            }
//            ptst.close();
//        } catch (SQLException e) {
//            e.printStackTrace();
//        }

//        // 4. 插入五万条数据，使用for循环
//        int randomNum;
//        try {
//            String sqlInsertMany = "INSERT INTO commodityinfo (ctid,cmmname,cmmprice,salecount) VALUES (?,?,?,?)";
//            PreparedStatement ptstm = (PreparedStatement) connection.prepareStatement(sqlInsertMany);
//            for (int i = 0; i < 50000; i++) {
//                randomNum = (int) (Math.random() * (10 - 1) + 1);
//                ptstm.setInt(1, randomNum);
//
//                randomNum = (int) (Math.random() * (50000 - 1) + 1);
//                ptstm.setString(2, String.valueOf(randomNum));
//                ptstm.setBigDecimal(3, BigDecimal.valueOf(randomNum * 0.01));
//                ptstm.setInt(4, randomNum);
//
//                ptstm.executeUpdate();
//            }
//            ptstm.close();
//        } catch (SQLException e) {
//            e.printStackTrace();
//        }

        // 5. 插入五万条数据，使用批处理，前提是连接要开启设置，删除的时候请配合LIMIT关键字，否则删除会导致锁死问题
        // 示例：DELETE FROM commodityinfo WHERE ctid < 11 LIMIT 50000;
        try {
            String sqlInsertMany = "INSERT INTO commodityinfo (ctid,cmmname,cmmprice,salecount) VALUES (?,?,?,?)";
            PreparedStatement ptstb = (PreparedStatement) connection.prepareStatement(sqlInsertMany);
            connection.setAutoCommit(false);
            Long startTime = System.currentTimeMillis();
            System.out.println("插入开始~");
            for (int i = 1; i < 50001; i++) {
                ptstb.setInt(1, (int) (Math.random() * (10 - 1) + 1));
                ptstb.setString(2, String.valueOf((int) (Math.random() * (50000 - 1) + 1)));
                ptstb.setBigDecimal(3, BigDecimal.valueOf((int) (Math.random() * (50000 - 1) + 1) * 0.01));
                ptstb.setInt(4, (int) (Math.random() * (50000 - 1) + 1));
                ptstb.addBatch();
//                // 如果有限制提交事务的大小，这里可以用循环多次处理，这里暂时不需要
//                if (i % 10000 == 0 && i != 0) {
//                    System.out.println("第" + i + "条需要提交了");
//                    ptstb.executeBatch();
//                    connection.commit();
//                    Long nowTime = System.currentTimeMillis();
//                    System.out.println("第" + i + "条插入完毕,用时：" + (nowTime - startTime));
//                }
            }
            ptstb.executeBatch();
            connection.commit();
            ptstb.close();
            Long endTime = System.currentTimeMillis();
            System.out.println("插入完毕,用时：" + (endTime - startTime));
        } catch (SQLException e) {
            e.printStackTrace();
        }

//        6. 修改字段
//        try {
//            String sqlUpdate = "update commoditytype set ctname=? where ctid=?";
//            PreparedStatement ptstu = (PreparedStatement) connection.prepareStatement(sqlUpdate);
//            ptstu.setString(1, "padtop");
//            ptstu.setInt(2, 2);
//            ptstu.executeUpdate();
//            ptstu.close();
//        } catch (SQLException e) {
//            e.printStackTrace();
//        }

        connection.close();
    }

    public static void main(String[] args) {
        jdbcTest jt = new jdbcTest();
        try {
            jt.run();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        } catch (SQLException e) {
            e.printStackTrace();
        }

    }
}

