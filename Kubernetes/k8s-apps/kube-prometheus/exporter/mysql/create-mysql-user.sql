CREATE USER 'exporter'@'%' IDENTIFIED BY 'TBVo!4RqH';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'%';
GRANT SELECT ON performance_schema.* TO 'exporter'@'%';
flush privileges;

