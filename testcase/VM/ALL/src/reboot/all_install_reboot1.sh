#!/usr/bin/bash

###########################################################################################################################
#title           :all_install_reboot1.sh                                                                                  #
#description     :The purpose of this testcase is to test that netbrain-all-in-two-linux                                  #
#                 can be successfully installed in docker by invoking the original install.sh script,                     #
#                 which means that install.sh is correctly invoked and executed.                                          #
#author          :Zihao Yan                                                                                                #
#date            :20190501                                                                                                #
#version         :1.0                                                                                                     #
#usage           :./all_install_reboot1.sh                                                                                #
#actual results  :Testcase all_install_reboot1.sh passed!                                                                 #
#expected results:Testcase all_install_reboot1.sh passed!                                                                 #
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
userdel -r -f $user2 >/dev/null 2>&1                                                                                      #remove Elasticsearch user and group
groupdel $user2 >/dev/null 2>&1                                                                                           #remove Elasticsearch group
userdel -r -f $user3 >/dev/null 2>&1                                                                                      #remove RabbitMQ user and group
groupdel $user3 >/dev/null 2>&1                                                                                           #remove RabbitMQ group
userdel -r -f $user4 >/dev/null 2>&1                                                                                      #remove Redis user and group
groupdel $user4 >/dev/null 2>&1                                                                                           #remove Redis group
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
echo -e "" >>$input                                                                                                       #do not use the customized server ports
echo -e "http://172.17.0.3/" >>$input                                                                                     #URL of NetBrain Web API service
echo -e "" >>$input                                                                                                       #make sure that all the previous parameters are in effect
log="ALL.log"                                                                                                             #installation log generated in the current directory
rm -rf $log                                                                                                               #delete logs for conflict
timeout 1200 ./install.sh <$input >$log 2>&1                                                                              #execute netbrain-all-in-two-linux installation script and save the log
if [ $? -eq 124 ];then                                                                                                    #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
	exit 0
fi
reboot                                                                                                                    #reboot the system