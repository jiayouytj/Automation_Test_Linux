#!/usr/bin/bash

###########################################################################################################################
#title           :all_install_reboot2.sh                                                                                  #
#description     :The purpose of this testcase is to test that netbrain-all-in-two-linux                                  #
#                 can be successfully installed in docker by invoking the original install.sh script, and after rebooting #
#                 the system, all services are in running state, and all Ports are listening,                             #
#                 which means that install.sh is correctly invoked and executed.                                          #
#author          :Zihao Yan                                                                                                #
#date            :20190501                                                                                                #
#version         :1.0                                                                                                     #
#usage           :./all_install_reboot2.sh                                                                                #
#actual results  :Testcase all_install_reboot2.sh passed!                                                                 #
#expected results:Testcase all_install_reboot2.sh passed!                                                                 #
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

log="ALL.log"                                                                                                             #installation log generated in the current directory
log_fail="ALL_fail.log"                                                                                                   #generate logs only if the testcase failed
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
rm -rf $log $log_fail                                                                                                     #delete logs for conflict
touch $log                                                                                                                #create the log file

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

if lsof -i:$DB_Port|grep LISTEN >/dev/null 2>&1 && lsof -i:$ES_Port|grep LISTEN >/dev/null 2>&1 \
&& lsof -i:$ES_Port2|grep LISTEN >/dev/null 2>&1 && lsof -i:$LA_Port|grep LISTEN >/dev/null 2>&1 \
&& lsof -i:$MQ_Port|grep LISTEN >/dev/null 2>&1 && lsof -i:$MQ_Port2|grep LISTEN >/dev/null 2>&1 \
&& lsof -i:$MQ_Port3|grep LISTEN >/dev/null 2>&1 && lsof -i:$MQ_Port4|grep LISTEN >/dev/null 2>&1 \
&& lsof -i:$RE_Port|grep LISTEN >/dev/null 2>&1 && lsof -i:$SM_Port|grep LISTEN >/dev/null 2>&1 \
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
