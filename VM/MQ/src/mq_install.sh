#!/usr/bin/bash

##################################################################################################################
#title           :mq_install.sh                                                                                  #
#description     :The purpose of this testcase is to test that RabbitMQ                                          #
#                 can be successfully installed in VM by invoking the original install.sh script,                #
#                 which means that install.sh is correctly invoked and executed                                  #
#author		     :Derek Li                                                                                       #
#date            :20190225                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./mq_install.sh                                                                                #
#actual results  :Testcase mq_install.sh passed!                                                                 #
#expected results:Testcase mq_install.sh passed!                                                                 #
##################################################################################################################

##################################################################################################################
# The following function is for cleaning up before and after installation                                        #
##################################################################################################################
cleanup()
{
user="rabbitmq"                                                                                                  #rabbitmq user
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain/"                                                                        #unified UninstallPath
UnifiedConfigPath="/etc/rabbitmq/"                                                                               #unified ConfigPath
UninstallPath="/usr/lib/netbrain/installer/rabbitmq"                                                             #uninstall.sh copied to the UninstallPath
rpm -qa|grep -E "rabbitmq|erlang"|xargs rpm -e >/dev/null 2>&1                                                   #uninstall all RabbitMQ related rpms if they have been installed
ps -ef |grep "erlang"|awk '{print $2}'|xargs kill -9 >/dev/null 2>&1                                             #kill erlang process
rm -rf $InstallPath $LogPath $ErlangPath $UnifiedConfigPath $UnifiedLogPath $UnifiedUninstallPath                #remove all RabbitMQ files and paths
userdel -r $user >/dev/null 2>&1                                                                                 #remove rabbitmq user cleanly
service firewalld start >/dev/null 2>&1                                                                          #start the firewalld service
i=0 
for line in `firewall-cmd --list-ports`                                                                          #list all ports in the firewall
do
    name[${i}]=$line
    firewall-cmd --remove-port=${name[$i]} --permanent >/dev/null 2>&1                                           #remove all ports from the firewall
    let i=${i}+1
done
firewall-cmd --reload >/dev/null 2>&1                                                                            #reload the firewall
service firewalld stop >/dev/null 2>&1                                                                           #stop the firewalld service
}
cleanup                                                                                                          #invoke cleanup funtion to purge all RabbitMQ related stuffs
conf_path=`ls config/setup.conf`                                                                                 #the RabbitMQ config file name
UserName="`grep "^UserName" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default UserName
Password="`grep "^Password" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default Password
IP=`hostname -I|awk '{print $1}'`                                                                                #the IP address of this machine
Port="15672"                                                                                                     #the Port number used by RabbitMQ
TcpPort="`grep "^TcpPort" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default TcpPort
InstallPath="/usr/lib/rabbitmq"                                                                                  #the Installation Path
ConfigPath="/etc/rabbitmq"                                                                                       #the config Path
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
ErlangPath="/usr/lib64/erlang"                                                                                   #Erlang Path
servicename="rabbitmq-server"                                                                                    #RabbitMQ service name
log="MQ.log"                                                                                                     #installation log generated in the current directory
log_fail="MQ_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed RabbitMQ"                                                                    #message for a sign of successfully installing the RabbitMQ
rm -rf $log $log_fail                                                                                            #remove logs for conflict
service firewalld stop >/dev/null 2>&1                                                                           #stop firewalld service
timeout 600 ./install.sh >$log 2>&1                                                                              #execute RabbitMQ installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all RabbitMQ related stuffs
	exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $InstallPath ];then                                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The Installation Path $InstallPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $ConfigPath ];then                                                                                     #if the testcase fails, generate the reasons for the failure
echo -e "The Config Path $ConfigPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $LogPath ];then                                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The Log Path $LogPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `curl --tlsv1.2 -i -s -XGET -u $UserName:$Password http://$IP:$Port/api/vhosts |grep running` ]];then    #if the testcase fails, generate the reasons for the failure                                                                             #if the testcase fails, generate the reasons for the failure
echo -e "The RabbitMQ Web management interface cannot be accessed. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                       #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service firewalld status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                            #if the testcase fails, generate the reasons for the failure
echo -e "The firewalld service is still in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& ! sh -c "service firewalld status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& grep -q "$msg_install" $log && [ -d $InstallPath ] && [ -d $ConfigPath ] && [ -d $LogPath ] \
&& [[ `curl --tlsv1.2 -i -s -XGET -u $UserName:$Password http://$IP:$Port/api/vhosts |grep running` ]];then      #determine if RabbitMQ installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall RabbitMQ using uninstall.sh
cleanup                                                                                                          #invoke cleanup funtion to purge all RabbitMQ related stuffs
