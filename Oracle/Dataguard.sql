select "created_at" from bbgo."t_pay_info" order by "created_at" desc;
--查询dataguard的状态
select * from v$dataguard_stats;
select sequence#,name, applied from v$archived_log where name is not null order by applied;
select count(*) from bbgo."t_pay_info";
select dbid,name,switchover_status,db_unique_name,database_role,open_mode,current_scn from v$database;
select group#,bytes/1024/1024 from v$standby_log;
select * from v$managed_standby;
select  message from  V$DATAGUARD_STATUS order by TIMESTAMP;
SELECT * FROM V$ARCHIVE_DEST_STATUS;
select * from v$thread;
select group#,type, member from v$logfile;
select group#,thread#,archived,status, bytes/1024/1024 from v$log;
select * from v$archive_gap;
select dest_name,error,status from v$archive_dest;
select * from v$log;
select * from v$logfile;
select * from v$dataguard_status;
select * from v$log_history order by sequence# desc;
--查询数据文件的大小
select name,round(bytes/(1024*1024*1024),4) total_name from v$datafile;
select SID,SERIAL#,USERNAME,OSUSER,MACHINE,PREV_EXEC_START,ACTION,PROGRAM from v$session where type='USER' order by username;
select * from v$instance;
select flashback_on from v$database;
select * from v$archive_dest_status;
select * from bbgps."e_cargps" order by "credate" desc;
select "credate" from bbgps."e_cargps" where "credate" > to_date('2018-08-14 11:30:00','yyyy-MM-dd hh24:mi:ss');
--查询表空间和数据文件
select file_id,file_name,tablespace_name from dba_data_files;
--查询表空间数据文件类型
select tablespace_name,bigfile from dba_tablespaces;
--查询表的大小
select * from (select segment_name,segment_type,bytes / 1024 / 1024 AS MB
                from dba_segments
                where tablespace_name = 'BBGODB'
                and bytes / 1024 / 1024 >100
                order by bytes desc);
