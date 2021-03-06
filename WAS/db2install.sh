#!/bin/bash
echo -e "\n \n \n подключи директорию с базой в /mnt\nи задать имя хоcта \n \n"
sleep 5
cp /root/bash/WAS/ListDependenciesRHEL /run/packages_installed
line=$(wc -l /run/packages_installed|cut -c -2)
while [ $line -gt 0 ]
do
package=$(sed -n 1p /run/packages_installed)
yum install -y $package
sed -i 1d /run/packages_installed
line=$(wc -l /run/packages_installed|cut -c -2)
done
db2=$(find /mnt -name "db2_install"|sed -n 1p)
db2home=$(echo '/opt/IBM/db2/V10.5')
groupadd db2iadm1
groupadd db2fadm1
groupadd dasadm1
useradd -G db2iadm1 -p 'b7g7hhp5gc'  -u 2000 -m db2inst1
useradd -G db2fadm1 -p 'b7g7hhp5gc'  -u 2001 -m db2fenc1
useradd -G dasadm1 -p 'b7g7hhp5gc'  -u 2002 -m dasusr1
useradd -p 'b7g7hhp5gc' cpeuser
useradd -p 'b7g7hhp5gc' os0user
useradd -p 'b7g7hhp5gc' os1user
useradd -p 'b7g7hhp5gc' refuser
chown -R db2fenc1:db2fadm1 /home/db2fenc1
chown -R db2inst1:db2iadm1 /home/db2inst1
chown -R dasusr1:dasadm1 /home/dasusr1
mkdir -p /db/DB
mkdir -p /db/alog/db2inst1/GCDDB
mkdir /db/alog/db2inst1/OSDB
mkdir /db/alog/db2inst1/REFDB
mkdir -p /db/mlog/db2inst1/GCDDB
mkdir /db/mlog/db2inst1/OSDB
mkdir /db/mlog/db2inst1/REFDB
chmod -R 0775 /db/alog/db2inst1
chmod -R 0775 /db/mlog/db2inst1
chown -R db2inst1:db2iadm1 /db/alog
chown -R db2inst1:db2iadm1 /db/mlog 
chown -R db2inst1:db2iadm1 /db
$db2 -b $db2home -p SERVER -f NOTSAMP -f sysreq
bashprofile=$(sudo -u root grep -E ".*bin.*instance" /root/.bashrc|wc -w)
if [[ $bashprofile < 1 ]]
then
sudo -u root echo "export PATH=$PATH:/opt/IBM/db2/V10.5/bin">>"/root/.bashrc"
sudo -u root echo "export PATH=$PATH:/opt/IBM/db2/V10.5/instance">>"/root/.bashrc"
sudo -u root echo "export PATH=$PATH:/opt/IBM/db2/V10.5/adm">>"/root/.bashrc"
sudo -u root echo 'alias startmanager="/opt/IBM/WebSphere/AppServer/bin/startManager.sh"'>>"/root/.bashrc"
sudo -u root echo 'alias stopmanager="/opt/IBM/WebSphere/AppServer/bin/stopManager.sh -user wsadmin -password o9p0[-]="'>>"/root/.bashrc"
sudo -u root echo 'alias stopnode02="/opt/IBM/WebSphere/AppServer/profiles/CPE02/bin/stopNode.sh -user wsadmin -password o9p0[-]="'>>"/root/.bashrc"
sudo -u root echo 'alias startnode02="/opt/IBM/WebSphere/AppServer/profiles/CPE02/bin/startNode.sh"'>>"/root/.bashrc"
sudo -u root echo 'alias stopnode01="/opt/IBM/WebSphere/AppServer/profiles/CPE01/bin/stopNode.sh -user wsadmin -password o9p0[-]="'>>"/root/.bashrc"
sudo -u root echo 'alias startnode01="/opt/IBM/WebSphere/AppServer/profiles/CPE01/bin/startNode.sh"'>>"/root/.bashrc"
sudo -u root echo 'alias restartwas="stopnode01; stopnode02; stopmanager; startmanager; startnode01; startnode02"'>>"/root/.bashrc"
sudo -u root echo 'alias pmt="/opt/IBM/WebSphere/AppServer/bin/ProfileManagement/pmt.sh &"'>>"/root/.bashrc"
sudo -u root echo 'echo -e "configType=remote\nmapWebServerToApplications=true\nwasMachineHostName=dmgr\nwebServerConfigFile1=/opt/IBM/HTTPServer/conf/httpd.conf\nwebServerDefinition=httpserver1\nwebServerHostName=dmgr\nwebServerInstallArch=64\nwebServerPortNumber=80\nwebServerSelected=ihs\nwebServerType=IHS">/run/wct.tmp'>>/root/.bashrc
sudo -u root echo 'alias wct="/opt/IBM/WebSphere/Toolbox/WCT/wctcmd.sh -tool pct -defLocPathname /opt/IBM/WebSphere/Plugins -defLocName plugin -createDefinition -response /run/wct.tmp"'>>/root/.bashrc
fi
#$db2home/bin/db2val
$db2home/instance/db2icrt -s ese -a SERVER -p 50000 -u db2inst1 db2inst1
su - db2inst1 -c 'db2 update dbm cfg using DFTDBPATH /db/DB IMMEDIATE'
su - db2inst1 -c 'db2set DB2COMM=tcpip'
su - db2inst1 -c 'db2set DB2_WORKLOAD=FILENET_CM'
su - db2inst1 -c 'db2set DB2_MINIMIZE_LISTPREFETCH=ON' 
su - db2inst1 -c 'db2set DB2_OPTPROFILE=ON' 
su - db2inst1 -c 'db2start' 
sleep 1
su - db2inst1 -c 'db2 create db GCDDB AUTOMATIC STORAGE YES ON "/db/DB" DBPATH ON "/db/DB" USING CODESET UTF-8 TERRITORY RU COLLATE USING SYSTEM PAGESIZE 32768'
su - db2inst1 -c 'db2 create db OSDB  AUTOMATIC STORAGE YES ON "/db/DB" DBPATH ON "/db/DB" USING CODESET UTF-8 TERRITORY RU COLLATE USING SYSTEM PAGESIZE 32768'
su - db2inst1 -c 'db2 create db REFDB AUTOMATIC STORAGE YES ON "/db/DB" DBPATH ON "/db/DB" USING CODESET UTF-8 TERRITORY RU COLLATE USING SYSTEM PAGESIZE 32768'
sudo -u db2inst1 echo 'drop tablespace userspace1
CREATE LARGE TABLESPACE GCD_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE USER TEMPORARY TABLESPACE USER_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 8 OVERHEAD 10.5 PREFETCHSIZE 8 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
GRANT CONNECT ON DATABASE TO USER cpeuser
GRANT CREATETAB ON DATABASE TO USER cpeuser
GRANT USE OF TABLESPACE GCD_TS TO USER cpeuser
GRANT USE OF TABLESPACE USER_TS TO USER cpeuser
GRANT SELECT on SYSIBM.SYSVERSIONS TO USER cpeuser
GRANT SELECT on SYSCAT.DATATYPES TO USER cpeuser
GRANT SELECT on SYSCAT.INDEXES TO USER cpeuser
GRANT SELECT on SYSIBM.SYSDUMMY1 TO USER cpeuser
GRANT USAGE on workload SYSDEFAULTUSERWORKLOAD TO USER cpeuser
GRANT IMPLICIT_SCHEMA on DATABASE TO USER cpeuser'>"/run/GCDDB.db2"
su - db2inst1 -c 'db2 connect to GCDDB; db2 -f "/run/GCDDB.db2"; db2 update db cfg using cur_commit on; db2 update db cfg using  APPLHEAPSZ 2560' 
sudo -u db2inst1 echo 'drop tablespace userspace1
CREATE LARGE TABLESPACE SYOS_DATA01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE SYOS_INDEX01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE SYOS_BLOB01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_DATA01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_INDEX01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_BLOB01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_WFDATA01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_WFINDEX01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_WFBLOB01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_R1DATA01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_R1INDEX01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE LARGE TABLESPACE ENTOS_R1BLOB01_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE USER TEMPORARY TABLESPACE USER_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 8 OVERHEAD 10.5 PREFETCHSIZE 8 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE SYSTEM TEMPORARY TABLESPACE TSYS_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 8 OVERHEAD 10.5 PREFETCHSIZE 8 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
GRANT CONNECT ON DATABASE TO USER os0user
GRANT CONNECT ON DATABASE TO USER os1user
GRANT USE OF TABLESPACE SYOS_DATA01_TS TO USER os0user
GRANT USE OF TABLESPACE SYOS_INDEX01_TS TO USER os0user
GRANT USE OF TABLESPACE SYOS_BLOB01_TS TO USER os0user
GRANT USE OF TABLESPACE USER_TS TO USER os0user
GRANT USE OF TABLESPACE ENTOS_DATA01_TS TO USER os1user
GRANT USE OF TABLESPACE ENTOS_INDEX01_TS TO USER os1user
GRANT USE OF TABLESPACE ENTOS_BLOB01_TS TO USER os1user
GRANT USE OF TABLESPACE ENTOS_WFDATA01_TS TO USER os1user
GRANT USE OF TABLESPACE ENTOS_WFINDEX01_TS TO USER os1user
GRANT USE OF TABLESPACE ENTOS_WFBLOB01_TS TO USER os1user
GRANT USE OF TABLESPACE ENTOS_R1DATA01_TS TO USER os1user
GRANT USE OF TABLESPACE ENTOS_R1INDEX01_TS TO USER os1user
GRANT USE OF TABLESPACE ENTOS_R1BLOB01_TS TO USER os1user
GRANT USE OF TABLESPACE USER_TS TO USER os1user
GRANT SELECT on SYSIBM.SYSVERSIONS TO USER os0user
GRANT SELECT on SYSIBM.SYSVERSIONS TO USER os1user
GRANT SELECT on SYSCAT.DATATYPES TO USER os0user
GRANT SELECT on SYSCAT.DATATYPES TO USER os1user
GRANT SELECT on SYSCAT.INDEXES TO USER os0user
GRANT SELECT on SYSCAT.INDEXES TO USER os1user
GRANT SELECT on SYSIBM.SYSDUMMY1 TO USER os0user
GRANT SELECT on SYSIBM.SYSDUMMY1 TO USER os1user
GRANT USAGE on workload SYSDEFAULTUSERWORKLOAD TO USER os0user
GRANT USAGE on workload SYSDEFAULTUSERWORKLOAD TO USER os1user
GRANT IMPLICIT_SCHEMA on DATABASE TO USER os0user
GRANT IMPLICIT_SCHEMA on DATABASE TO USER os1user'>"/run/OSDB.db2"
su - db2inst1 -c 'db2 connect to OSDB; db2 -f "/run/OSDB.db2"; db2 update db cfg using cur_commit on; db2 update db cfg using APPLHEAPSZ 2560' 
sudo -u db2inst1 echo 'drop tablespace userspace1
CREATE LARGE TABLESPACE REF_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 16 OVERHEAD 10.5 PREFETCHSIZE 16 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
CREATE USER TEMPORARY TABLESPACE USER_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE EXTENTSIZE 8 OVERHEAD 10.5 PREFETCHSIZE 8 TRANSFERRATE 0.14 BUFFERPOOL IBMDEFAULTBP
GRANT CONNECT ON DATABASE TO USER refuser
GRANT CREATETAB ON DATABASE TO USER refuser
GRANT USE OF TABLESPACE REF_TS TO USER refuser
GRANT USE OF TABLESPACE USER_TS TO USER refuser
GRANT SELECT on SYSIBM.SYSVERSIONS TO USER refuser
GRANT SELECT on SYSCAT.DATATYPES TO USER refuser
GRANT SELECT on SYSCAT.INDEXES TO USER refuser
GRANT SELECT on SYSIBM.SYSDUMMY1 TO USER refuser
GRANT USAGE on workload SYSDEFAULTUSERWORKLOAD TO USER refuser
GRANT IMPLICIT_SCHEMA on DATABASE TO USER refuser'>"/run/REFDB.db2"
su - db2inst1 -c 'db2 connect to REFDB; db2 -f "/run/REFDB.db2"; db2 update db cfg using cur_commit on; db2 update db cfg using APPLHEAPSZ 2560' 
su - db2inst1 -c 'db2 update db cfg for GCDDB using NEWLOGPATH /db/alog/db2inst1/GCDDB; db2 connect to GCDDB; db2 terminate; db2 deactivate db GCDDB; db2 activate db GCDDB; db2 update db cfg for GCDDB using MIRRORLOGPATH /db/mlog/db2inst1/GCDDB; db2 connect to GCDDB; db2 terminate; db2 deactivate db GCDDB; db2 activate db GCDDB'
su - db2inst1 -c 'db2 update db cfg for OSDB using NEWLOGPATH /db/alog/db2inst1/OSDB; db2 connect to OSDB; db2 terminate; db2 deactivate db OSDB; db2 activate db OSDB; db2 update db cfg for OSDB using MIRRORLOGPATH /db/mlog/db2inst1/OSDB; db2 connect to OSDB; db2 terminate; db2 deactivate db OSDB; db2 activate db OSDB'
su - db2inst1 -c 'db2 update db cfg for REFDB using NEWLOGPATH /db/alog/db2inst1/REFDB; db2 connect to REFDB; db2 terminate; db2 deactivate db REFDB; db2 activate db REFDB; db2 update db cfg for REFDB using MIRRORLOGPATH /db/mlog/db2inst1/REFDB; db2 connect to REFDB; db2 terminate; db2 deactivate db REFDB; db2 activate db REFDB; db2 force applications all; db2stop; db2start'
