#!/bin/bash
#Purpose:Create 6 groups named 'oinstall','dba','asmadmin','asmdba','asmoper','oper', plus 2 users named 'oracle','grid'.
#Also setting the Environment
#variable for oracle user.
#variable for grid user.
#Usage:Log on as the superuser('root'),and then execute the command:#./1preusers.sh
#Author:Asher Huang
  
echo "Now create 6 groups named 'oinstall','dba','asmadmin','asmdba','asmoper','oper'"
echo "Plus 2 users named 'oracle','grid',Also setting the Environment"
  
groupadd -g 1000 oinstall 
groupadd -g 1300 dba 
groupadd -g 1301 oper 
useradd -u 501 -g oinstall -G dba,oper -d /home/oracle -s /bin/bash -c "Oracle Software Owner" oracle 
echo "oracle" | passwd --stdin oracle
  
#echo 'export PS1="`/bin/hostname -s`-> "'>> /home/oracle/.bash_profile 
echo "export TMP=/tmp">> /home/oracle/.bash_profile  
echo 'export TMPDIR=$TMP'>>/home/oracle/.bash_profile 
echo "export ORACLE_HOSTNAME=dataguard">> /home/oracle/.bash_profile 
echo "export ORACLE_SID=bbdg">> /home/oracle/.bash_profile 
echo "export ORACLE_BASE=/u01/app/oracle">> /home/oracle/.bash_profile
echo 'export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1'>> /home/oracle/.bash_profile
echo "export ORACLE_UNQNAME=bbdg">> /home/oracle/.bash_profile
echo 'export TNS_ADMIN=$ORACLE_HOME/network/admin'  >> /home/oracle/.bash_profile
echo "export ORACLE_TERM=xterm">> /home/oracle/.bash_profile
echo 'export PATH=/usr/sbin:$PATH'>> /home/oracle/.bash_profile
echo 'export PATH=$ORACLE_HOME/bin:$PATH'>> /home/oracle/.bash_profile
echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib'>> /home/oracle/.bash_profile
echo 'export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib'>> /home/oracle/.bash_profile
echo "export EDITOR=vi" >> /home/oracle/.bash_profile
echo "export LANG=en_US" >> /home/oracle/.bash_profile
echo "export NLS_LANG=american_america.AL32UTF8" >> /home/oracle/.bash_profile
echo "export NLS_DATE_FORMAT='yyyy/mm/dd hh24:mi:ss'" >> /home/oracle/.bash_profile
echo "umask 022">> /home/oracle/.bash_profile
  
echo "The Groups and users has been created"
echo "The Environment for grid,oracle also has been set successfully"
