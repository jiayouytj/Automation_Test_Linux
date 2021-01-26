#!/usr/bin/bash

###########################################################################################################################
#title           :all_install_bad_port1.sh                                                                                #
#description     :The purpose of this testcase is to test that netbrain-all-in-two-linux                                  #
#                 can be successfully installed in docker by invoking the original install.sh script,                     #
#                 while specifying the bad ports for all the components, the errors are given,                            #
#                 which means that install.sh is correctly invoked and executed.                                          #
#author          :Zihao Yan                                                                                                #
#date            :20190501                                                                                                #
#version         :1.0                                                                                                     #
#usage           :./all_install_bad_port1.sh                                                                              #
#actual results  :Testcase all_install_bad_port1.sh passed!                                                               #
#expected results:Testcase all_install_bad_port1.sh passed!                                                               #
###########################################################################################################################

UnifiedLogPath="/var/log/netbrain"                                                                                        #unified LogPath
UnifiedDataPath="/var/lib/netbrain"                                                                                       #unified DataPath
UnifiedUninstallPath="/usr/lib/netbrain"                                                                                  #unified UninstallPath
UnifiedConfigPath="/etc/netbrain"                                                                                         #unified ConfigPath
UninstallPath="$UnifiedUninstallPath/installer/all"                                                                       #uninstall.sh copied to the UninstallPath
UnifiedSSLPath="/etc/ssl"                                                                                                 #unified SSLPath
DB_DataPath="$UnifiedDataPath/mongodb"                                                                                    #the default MongoDB DataPath
DB_LogPath="$UnifiedLogPath/mongodb"                                                                                      #the default MongoDB LogPath
ES_DataPath="$UnifiedDataPath/elasticsearch"                                                                              #the default Elasticsearch DataPath
ES_LogPath="$UnifiedLogPath/elasticsearch"                                                                                #the default Elasticsearch LogPath
LA_LogPath="$UnifiedLogPath/licenseagent"                                                                                 #the default License Agent LogPath
MQ_LogPath="$UnifiedLogPath/rabbitmq"                                                                                     #the default RabbitMQ LogPath
RE_DataPath="$UnifiedDataPath/redis"                                                                                      #the default Redis DataPath
RE_LogPath="$UnifiedLogPath/redis"                                                                                        #the default Redis LogPath
SM_LogPath="$UnifiedLogPath/servicemonitoragent"                                                                          #the default Service Monitor Agent LogPath
DB_ConfigPath="/etc/mongodb"                                                                                              #MongoDB Config Path
ES_ConfigPath="/etc/elasticsearch"                                                                                        #Elasticsearch Config Path
LA_ConfigPath="/etc/netbrainlicense"                                                                                      #License Agent Config Path
MQ_ConfigPath="/etc/rabbitmq"                                                                                             #RabbitMQ Config Path
RE_ConfigPath="/etc/redis"                                                                                                #Redis Config Path
SM_ConfigPath="$UnifiedConfigPath"                                                                                        #Service Monitor Config Path
MQ_DataPath="/var/lib/rabbitmq"                                                                                           #the default RabbitMQ DataPath
MQ_ErlangPath="/usr/lib64/erlang"                                                                                         #Erlang Path
cleanup()
{
user1="netbrain"                                                                                                          #NetBrain Database user
user2="elasticsearch"                                                                                                     #Elasticsearch user
user3="rabbitmq"                                                                                                          #RabbitMQ user
user4="redis"                                                                                                             #Redis user
output="output.file"                                                                                                      #input file for uninstall.sh
rm -rf $output                                                                                                            #remove output.file
echo -e "y" >$output                                                                                                      #type y to remove all data when uninstalling License Agent
echo -e "y" >>$output                                                                                                     #type y to remove all data when uninstalling Elasticsearch
echo -e "y" >>$output                                                                                                     #type y to remove all data when uninstalling RabbitMQ
echo -e "y" >>$output                                                                                                     #type y to remove all data when uninstalling Redis
echo -e "y" >>$output                                                                                                     #type y to remove all data when uninstalling Service Monitor Agent
$UninstallPath/uninstall.sh <$output >/dev/null 2>&1                                                                      #uninstall netbrain-all-in-two-linux using uninstall.sh
./others/uninstall.sh <$output >/dev/null 2>&1                                                                            #uninstall netbrain-all-in-two-linux using uninstall.sh
echo "y"|./mongodb/others/uninstall.sh >/dev/null 2>&1                                                                    #uninstall MongoDB
echo "y"|./elasticsearch/others/uninstall.sh >/dev/null 2>&1                                                              #uninstall Elasticsearch
echo "y"|./licenseagent/others/uninstall.sh >/dev/null 2>&1                                                               #uninstall License Agent
echo "y"|./rabbitmq/others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall RabbitMQ
echo "y"|./redis/others/uninstall.sh >/dev/null 2>&1                                                                      #uninstall Redis
echo "y"|./servicemonitoragent/others/uninstall.sh >/dev/null 2>&1                                                        #uninstall Service Monitor Agent
rpm -qa|grep -E "^mongo|^elasticsearch|^netbrainlicense|^redis|^rabbitmq"|xargs rpm -e >/dev/null 2>&1                    #uninstall all netbrain-all-in-two-linux related rpms if they have been installed
ps -ef |grep "erlang"|awk '{print $2}'|xargs kill -9 >/dev/null 2>&1                                                      #kill erlang process
rm -rf "$UnifiedDataPath" "$UnifiedConfigPath" "$UnifiedLogPath" "$UnifiedUninstallPath" "$DB_DataPath" "$DB_LogPath" \
"$ES_DataPath" "$ES_LogPath" "$LA_LogPath" "$MQ_LogPath" "$RE_DataPath" "$RE_LogPath" "$SM_LogPath" "$MQ_ErlangPath" \
"$DB_ConfigPath" "$ES_ConfigPath" "$LA_ConfigPath" "$MQ_ConfigPath" "$RE_ConfigPath" "$SM_ConfigPath" "$MQ_DataPath" \
"$UnifiedSSLPath"/mongodb /etc/stunnel "$UnifiedSSLPath"/rabbitmq \
"$UnifiedSSLPath"/netbrainlicense "$UnifiedSSLPath"/netbrain /etc/*.js                                                    #remove all netbrain-all-in-two-linux files and paths
userdel -r -f $user1 >/dev/null 2>&1                                                                                      #remove NetBrain Database user and group
groupdel $user1 >/dev/null 2>&1                                                                                           #remove NetBrain Database group
userdel -r -f $user2 >/dev/null 2>&1                                                                                      #remove Elasticsearch user and group
groupdel $user2 >/dev/null 2>&1                                                                                           #remove Elasticsearch group
userdel -r -f $user3 >/dev/null 2>&1                                                                                      #remove RabbitMQ user and group
groupdel $user3 >/dev/null 2>&1                                                                                           #remove RabbitMQ group
userdel -r -f $user4 >/dev/null 2>&1                                                                                      #remove Redis user and group
groupdel $user4 >/dev/null 2>&1                                                                                           #remove Redis group
service firewalld start >/dev/null 2>&1                                                                                   #start the firewalld service
i=0 
for line in `firewall-cmd --list-ports`                                                                                   #list all ports in the firewall
do
    name[${i}]=$line
    firewall-cmd --remove-port=${name[$i]} --permanent >/dev/null 2>&1                                                    #remove all ports from the firewall
    let i=${i}+1
done
firewall-cmd --reload >/dev/null 2>&1                                                                                     #reload the firewall
service firewalld stop >/dev/null 2>&1                                                                                    #stop the firewalld service
sed -i "/logrotate/d" /var/spool/cron/root >/dev/null 2>&1                                                                #delete all log rotate related cron job                   
}

cleanup                                                                                                                   #invoke cleanup funtion to purge all netbrain-all-in-two-linux related stuffs
input="input.file"                                                                                                        #input file for install.sh
Password="admin"                                                                                                          #NetBrain service password
rm -rf $input                                                                                                             #remove input file for conflict
echo -e "YES" >$input                                                                                                     #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                               #echo I ACCEPT to accept the terms in the subscription EULA
echo -e "" >>$input                                                                                                       #use the default Data Path for NetBrain
echo -e "" >>$input                                                                                                       #use the default Log Path for NetBrain
echo -e "" >>$input                                                                                                       #use the default IP address of this machine
echo -e "" >>$input                                                                                                       #use the default NetBrain service username
echo -e "$Password" >>$input                                                                                              #set the NetBrain service password
echo -e "$Password" >>$input                                                                                              #repeat the NetBrain service password
echo -e "" >>$input                                                                                                       #do not enable SSL on NetBrain Database Server
echo -e "yes" >>$input                                                                                                      #use the customized server ports
echo -e "0" >>$input                                                                                                      #use bad port for MongoDB
echo -e "1" >>$input                                                                                                      #use bad port for MongoDB
echo -e "1024" >>$input                                                                                                   #use bad port for MongoDB
echo -e "65536" >>$input                                                                                                  #use bad port for MongoDB
echo -e "1 2" >>$input                                                                                                    #use bad port for MongoDB
echo -e "abc" >>$input                                                                                                    #use bad port for MongoDB
echo -e "ABC" >>$input                                                                                                    #use bad port for MongoDB
echo -e "@#$" >>$input                                                                                                    #use bad port for MongoDB
echo -e "" >>$input                                                                                                       #use default port for MongoDB
echo -e "0" >>$input                                                                                                      #use bad port for License Agent
echo -e "1" >>$input                                                                                                      #use bad port for License Agent
echo -e "1024" >>$input                                                                                                   #use bad port for License Agent
echo -e "65536" >>$input                                                                                                  #use bad port for License Agent
echo -e "1 2" >>$input                                                                                                    #use bad port for License Agent
echo -e "abc" >>$input                                                                                                    #use bad port for License Agent
echo -e "ABC" >>$input                                                                                                    #use bad port for License Agent
echo -e "@#$" >>$input                                                                                                    #use bad port for License Agent
echo -e "" >>$input                                                                                                       #use default port for License Agent
echo -e "0" >>$input                                                                                                      #use bad port for Elasticsearch
echo -e "1" >>$input                                                                                                      #use bad port for Elasticsearch
echo -e "1024" >>$input                                                                                                   #use bad port for Elasticsearch
echo -e "65536" >>$input                                                                                                  #use bad port for Elasticsearch
echo -e "1 2" >>$input                                                                                                    #use bad port for Elasticsearch
echo -e "abc" >>$input                                                                                                    #use bad port for Elasticsearch
echo -e "ABC" >>$input                                                                                                    #use bad port for Elasticsearch
echo -e "@#$" >>$input                                                                                                    #use bad port for Elasticsearch
echo -e "" >>$input                                                                                                       #use default port for Elasticsearch
echo -e "0" >>$input                                                                                                      #use bad port for RabbitMQ
echo -e "1" >>$input                                                                                                      #use bad port for RabbitMQ
echo -e "1024" >>$input                                                                                                   #use bad port for RabbitMQ
echo -e "65536" >>$input                                                                                                  #use bad port for RabbitMQ
echo -e "1 2" >>$input                                                                                                    #use bad port for RabbitMQ
echo -e "abc" >>$input                                                                                                    #use bad port for RabbitMQ
echo -e "ABC" >>$input                                                                                                    #use bad port for RabbitMQ
echo -e "@#$" >>$input                                                                                                    #use bad port for RabbitMQ
echo -e "" >>$input                                                                                                       #use default port for RabbitMQ
echo -e "0" >>$input                                                                                                      #use bad port for Redis
echo -e "1" >>$input                                                                                                      #use bad port for Redis
echo -e "1024" >>$input                                                                                                   #use bad port for Redis
echo -e "65536" >>$input                                                                                                  #use bad port for Redis
echo -e "1 2" >>$input                                                                                                    #use bad port for Redis
echo -e "abc" >>$input                                                                                                    #use bad port for Redis
echo -e "ABC" >>$input                                                                                                    #use bad port for Redis
echo -e "@#$" >>$input                                                                                                    #use bad port for Redis
echo -e "" >>$input                                                                                                       #use default port for Redis
echo -e "http://172.17.0.3/" >>$input                                                                                     #URL of NetBrain Web API service
echo -e "" >>$input                                                                                                       #make sure that all the previous parameters are in effect
log="ALL.log"                                                                                                             #installation log generated in the current directory
log_fail="ALL_fail.log"                                                                                                   #generate logs only if the testcase failed
msg_db_install1="Successfully installed MongoDB"                                                                          #message for a sign of successfully installing the MongoDB
msg_db_install2="Successfully logged in MongoDB with username"                                                            #message for a sign of successfully logging in MongoDB
msg_db_install3="Please restart the operating system to make kernel settings of MongoDB to take effect"                   #message for a sign of reboot prompt after MongoDB installation
msg_es_install1="Successfully installed Elasticsearch"                                                                    #message for a sign of successfully installing the Elasticsearch
msg_es_install2="initialized the username and password in the Elasticsearch"                                              #message for a sign of successfully initializing the username and password in the Elasticsearch
msg_es_install3="connected to the Elasticsearch"                                                                          #message for a sign of successfully connecting to the Elasticsearch
msg_es_install4="The setup is complete"                                                                                   #message for a sign of successfully completing the installation
msg_la_install1="Successfully installed License Agent"                                                                    #message for a sign of successfully installing the License Agent
msg_mq_install1="Successfully installed RabbitMQ"                                                                         #message for a sign of successfully installing the RabbitMQ
msg_re_install1="Successfully installed Redis"                                                                            #message for a sign of successfully installing the Redis
msg_sm_install1="Successfully installed Service Monitor Agent"                                                            #message for a sign of successfully installing the Service Monitor Agent
msg_error="The Port must be between 1025 and 65535"                                                                       #message for a sign of invalid port
DB_Port="`grep "^Port" mongodb/config/setup.conf|tr "=" " "|awk '{print $2}'`"                                            #default MongoDB Port
ES_Port="`grep "^Port" elasticsearch/config/setup.conf|tr "=" " "|awk '{print $2}'`"                                      #default Elasticsearch Port
ES_Port2="9300"                                                                                                           #default Elasticsearch Port
LA_Port="`grep "^Port" licenseagent/config/setup.conf|tr "=" " "|awk '{print $2}'`"                                       #default License Agent Port
MQ_Port="`grep "^TcpPort" rabbitmq/config/setup.conf|tr "=" " "|awk '{print $2}'`"                                        #default RabbitMQ Port
MQ_Port2="4369"                                                                                                           #default RabbitMQ Port
MQ_Port3="15672"                                                                                                          #default RabbitMQ Port
MQ_Port4="25672"                                                                                                          #default RabbitMQ Port
RE_Port="`grep "^Port" redis/config/setup.conf|tr "=" " "|awk '{print $2}'`"                                              #default Redis Port
SM_Port="17123"                                                                                                           #default Service Monitor Agent Port
DB_servicename="mongod"                                                                                                   #MongoDB service name
LA_servicename="netbrainlicense"                                                                                          #License Agent service name
ES_servicename="elasticsearch"                                                                                            #Elasticsearch service name
MQ_servicename="rabbitmq-server"                                                                                          #RabbitMQ service name
RE_servicename="redis"                                                                                                    #Redis service name
SM_servicename="netbrainagent"                                                                                            #Service Monitor Agent service name
DB_crontab="\*/10 \* \* \* \* /usr/sbin/logrotate -v '/etc/logrotate.d/mongod.conf' >/dev/null 2>&1"                      #cron job for MongoDB log rotate
RE_crontab="\*/30 \* \* \* \* /usr/sbin/logrotate -v '/etc/logrotate.d/redis.conf' >/dev/null 2>&1"                       #cron job for Redis log rotate
rm -rf $log $log_fail                                                                                                     #delete logs for conflict
path_before=`pwd`                                                                                                         #the current path before installation
timeout 1200 bash install.sh <$input >$log 2>&1                                                                           #execute netbrain-all-in-two-linux installation script and save the log
if [ $? -eq 124 ];then                                                                                                    #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                               #invoke cleanup funtion to purge all netbrain-all-in-two-linux related stuffs
	exit 0
fi
path_after=`pwd`                                                                                                          #the current path after installation

if [ ! $path_before == $path_after ];then                                                                                 #if the testcase fails, generate the reasons for the failure
echo -e "The current paths before and after installation are not the same. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! [[ `grep "$msg_error" "$log"|wc -l` == 40 ]];then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The number of bad port output are not 40. This may indicate \
that the all-in-two-linux installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_db_install11" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_db_install1". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_db_install12" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_db_install2". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_db_install13" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_db_install3". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_es_install11" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_es_install1". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_es_install12" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_es_install2". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_es_install13" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_es_install3". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_es_install14" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_es_install4". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_la_install11" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_la_install1". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_mq_install11" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_mq_install1". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_re_install11" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_re_install1". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_sm_install11" "$log";then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in "$log": "$msg_sm_install1". This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$DB_DataPath" ];then                                                                                           #if the testcase fails, generate the reasons for the failure
echo -e "The MongoDB Data Path "$DB_DataPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$ES_DataPath" ];then                                                                                           #if the testcase fails, generate the reasons for the failure
echo -e "The Elasticsearch Data Path "$ES_DataPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$RE_DataPath" ];then                                                                                           #if the testcase fails, generate the reasons for the failure
echo -e "The Redis Data Path "$RE_DataPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$DB_LogPath" ];then                                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The MongoDB Log Path "$DB_LogPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$ES_LogPath" ];then                                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The Elasticsearch Log Path "$ES_LogPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$LA_LogPath" ];then                                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The License Agent Log Path "$LA_LogPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$MQ_LogPath" ];then                                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The RabbitMQ Log Path "$MQ_LogPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$RE_LogPath" ];then                                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The Redis Log Path "$RE_LogPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$SM_LogPath" ];then                                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The Service Monitor Agent Log Path "$SM_LogPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$DB_ConfigPath" ];then                                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The MongoDB Config Path "$DB_ConfigPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$ES_ConfigPath" ];then                                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The Elasticsearch Config Path "$ES_ConfigPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$LA_ConfigPath" ];then                                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The License Agent Config Path "$LA_ConfigPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$MQ_ConfigPath" ];then                                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The RabbitMQ Config Path "$MQ_ConfigPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$RE_ConfigPath" ];then                                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The Redis Config Path "$RE_ConfigPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d "$SM_ConfigPath" ];then                                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The Service Monitor Agent Config Path "$SM_ConfigPath" was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$DB_Port|grep LISTEN >/dev/null 2>&1;then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The port $DB_Port for MongoDB is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$ES_Port|grep LISTEN >/dev/null 2>&1;then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The port $ES_Port for Elasticsearch is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$ES_Port2|grep LISTEN >/dev/null 2>&1;then                                                                   #if the testcase fails, generate the reasons for the failure
echo -e "The port $ES_Port2 for Elasticsearch is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$LA_Port|grep LISTEN >/dev/null 2>&1;then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The port $LA_Port for License Agent is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$MQ_Port|grep LISTEN >/dev/null 2>&1;then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The port $MQ_Port for RabbitMQ is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$MQ_Port2|grep LISTEN >/dev/null 2>&1;then                                                                   #if the testcase fails, generate the reasons for the failure
echo -e "The port $MQ_Port2 for RabbitMQ is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$MQ_Port3|grep LISTEN >/dev/null 2>&1;then                                                                   #if the testcase fails, generate the reasons for the failure
echo -e "The port $MQ_Port3 for RabbitMQ is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$MQ_Port4|grep LISTEN >/dev/null 2>&1;then                                                                   #if the testcase fails, generate the reasons for the failure
echo -e "The port $MQ_Port4 for RabbitMQ is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$RE_Port|grep LISTEN >/dev/null 2>&1;then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The port $RE_Port for Redis is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$SM_Port|grep LISTEN >/dev/null 2>&1;then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The port $SM_Port for Service Monitor Agent is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! [[ $(crontab -l|grep "$DB_crontab") ]];then                                                                          #if the testcase fails, generate the reasons for the failure
echo -e "There is no cron job for MongoDB log rotate, or the cron job is incorrect. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! [[ $(crontab -l|grep "$RE_crontab") ]];then                                                                          #if the testcase fails, generate the reasons for the failure
echo -e "There is no cron job for Redis log rotate, or the cron job is incorrect. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $DB_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                             #if the testcase fails, generate the reasons for the failure
echo -e "The $DB_servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $ES_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                             #if the testcase fails, generate the reasons for the failure
echo -e "The $ES_servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $LA_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                             #if the testcase fails, generate the reasons for the failure
echo -e "The $LA_servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $MQ_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                             #if the testcase fails, generate the reasons for the failure
echo -e "The $MQ_servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $RE_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                             #if the testcase fails, generate the reasons for the failure
echo -e "The $RE_servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $SM_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                             #if the testcase fails, generate the reasons for the failure
echo -e "The $SM_servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if grep -q "$msg_db_install11" "$log" && grep -q "$msg_db_install12" "$log" && grep -q "$msg_db_install13" "$log" \
&& grep -q "$msg_es_install11" "$log" && grep -q "$msg_es_install12" "$log" && grep -q "$msg_es_install13" "$log" \
&& grep -q "$msg_es_install14" "$log" && grep -q "$msg_la_install11" "$log" && grep -q "$msg_mq_install11" "$log" \
&& grep -q "$msg_re_install11" "$log" && grep -q "$msg_sm_install11" "$log" \
&& [ -d "$DB_DataPath" ] && [ -d "$ES_DataPath" ] && [ -d "$RE_DataPath" ] \
&& [ -d "$DB_LogPath" ] && [ -d "$ES_LogPath" ] && [ -d "$LA_LogPath" ] && [ $path_before == $path_after ] \
&& [ -d "$MQ_LogPath" ] && [ -d "$RE_LogPath" ] && [ -d "$SM_LogPath" ] && [[ `grep "$msg_error" "$log"|wc -l` == 40 ]] \
&& [ -d "$DB_ConfigPath" ] && [ -d "$ES_ConfigPath" ] && [ -d "$LA_ConfigPath" ] \
&& [ -d "$MQ_ConfigPath" ] && [ -d "$RE_ConfigPath" ] && [ -d "$SM_ConfigPath" ] \
&& lsof -i:$DB_Port|grep LISTEN >/dev/null 2>&1 && lsof -i:$ES_Port|grep LISTEN >/dev/null 2>&1 \
&& lsof -i:$ES_Port2|grep LISTEN >/dev/null 2>&1 && lsof -i:$LA_Port|grep LISTEN >/dev/null 2>&1 \
&& lsof -i:$MQ_Port|grep LISTEN >/dev/null 2>&1 && lsof -i:$MQ_Port2|grep LISTEN >/dev/null 2>&1 \
&& lsof -i:$MQ_Port3|grep LISTEN >/dev/null 2>&1 && lsof -i:$MQ_Port4|grep LISTEN >/dev/null 2>&1 \
&& lsof -i:$RE_Port|grep LISTEN >/dev/null 2>&1 && lsof -i:$SM_Port|grep LISTEN >/dev/null 2>&1 \
&& [[ $(crontab -l|grep "$DB_crontab") ]] && [[ $(crontab -l|grep "$RE_crontab") ]] \
&& sh -c "service $DB_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service $LA_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service $ES_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service $MQ_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service $RE_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service $SM_servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                               #determine if netbrain-all-in-two-linux installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                                   #invoke cleanup funtion to purge all netbrain-all-in-two-linux related stuffs
