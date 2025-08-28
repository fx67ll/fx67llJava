use test;

drop table if exists fx67ll_punch_log;

create table fx67ll_punch_log (
  punch_id bigint(20) not null auto_increment comment '打卡记录主键',
  punch_type char(1) comment '打卡类型（1代表上班 2代表下班）',
  punch_remark varchar(1023) default '' comment '打卡记录备注',
  del_flag char(1) default '0' comment '删除标志（0代表存在 2代表删除）',
  user_id bigint(20) comment '用户ID',
  create_by varchar(64) default '' comment '记录创建者',
  create_time datetime comment '记录创建时间',
  update_by varchar(64) default '' comment '记录更新者',
  update_time datetime comment '记录更新时间',
  primary key (punch_id)
) engine = innodb auto_increment = 1 comment = '打卡记录表';

INSERT INTO fx67ll_punch_log (punch_type,punch_remark,del_flag,user_id,create_by,create_time,update_by,update_time) VALUES
	 ('1','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-06 00:00:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-06 21:00:00'),
	 ('1','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-08 15:00:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-08 18:19:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-08 21:00:00'),
	 ('1','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-10 20:50:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-10 21:44:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-10 22:50:00'),
	 ('1','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-11 10:00:00'),
	 ('2','','0',1,'fx67ll','2023-12-12 19:49:41','fx67ll','2023-12-11 20:00:00');
INSERT INTO fx67ll_punch_log (punch_type,punch_remark,del_flag,user_id,create_by,create_time,update_by,update_time) VALUES
	 ('1','','0',101,'user','2023-12-13 17:03:22','user','2023-12-13 00:06:00'),
	 ('2','e e e','0',101,'user','2023-12-13 17:03:14','user','2023-12-13 01:01:00'),
	 ('1','123','0',1,'fx67ll','2023-12-14 09:53:54','fx67ll','2023-12-14 09:53:50');
	
SELECT * FROM fx67ll_punch_log;
