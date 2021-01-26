#!/usr/bin/bash

##################################################################################################################
#title           :mq_install_clean.sh                                                                            #
#description     :The purpose of this testcase is to test that RabbitMQ                                          #
#                 can be successfully installed in VM by invoking the original install.sh script with strong     #
#                 verification, which means that install.sh is correctly invoked and executed.                   #
#author		     :Derek Li                                                                                       #
#date            :20190301                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./mq_install_clean.sh                                                                          #
#actual results  :Testcase mq_install_clean.sh passed!                                                           #
#expected results:Testcase mq_install_clean.sh passed!                                                           #
##################################################################################################################

##################################################################################################################
# The following function is for cleaning up before and after installation                                        #
##################################################################################################################
user="rabbitmq"                                                                                                  #the user to be used by RabbitMQ
cleanup()
{
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain"                                                                         #unified UninstallPath
UnifiedConfigPath="/etc/rabbitmq"                                                                                #unified ConfigPath
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
version="fix_releaseinfo.json"                                                                                   #a JSON file containing release info under the installation directory
UserName="`grep "^UserName" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default UserName
Password="`grep "^Password" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default Password
IP=`hostname -I|awk '{print $1}'`                                                                                #the IP address of this machine
Port1="4369"                                                                                                     #the Port number for RabbitMQ
Port2="15672"                                                                                                    #the Port number for RabbitMQ
Port3="25672"                                                                                                    #the Port number for RabbitMQ
TcpPort="`grep "^TcpPort" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default TcpPort
InstallPath="/usr/lib/rabbitmq"                                                                                  #the Installation Path
ConfigPath="/etc/rabbitmq"                                                                                       #the config Path
DataPath="/var/lib/rabbitmq"                                                                                     #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
ErlangPath="/usr/lib64/erlang"                                                                                   #Erlang Path
servicename="rabbitmq-server"                                                                                    #RabbitMQ service name
log="MQ.log"                                                                                                     #installation log generated in the current directory
log_fail="MQ_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed RabbitMQ"                                                                    #message for a sign of successfully installing the RabbitMQ
logfile="/var/log/netbrain/installationlog/rabbitmq/install.log"                                                 #RabbitMQ installation log
etcfile="$UnifiedConfigPath/rabbitmq.config"                                                                     #RabbitMQ config file
service="/usr/lib/systemd/system/$servicename.service"                                                           #RabbitMQ systemd service file
uninstall="$UninstallPath/uninstall.sh"                                                                          #uninstall.sh copied to the UnifiedUninstallPath
root_user="root"                                                                                                 #root user
permission_755="rwxr-xr-x"                                                                                       #the permission for 755
permission_644="rw-r--r--"                                                                                       #the permission for 644
permission_SUID_755="rwxr-sr-x"                                                                                  #the permission for SUID 755
version_before=`cat /etc/redhat-release`                                                                         #the Linux version before installation
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh >$log 2>&1                                                                              #execute RabbitMQ installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all RabbitMQ related stuffs
	exit 0
fi
version_after=`cat /etc/redhat-release`                                                                          #the Linux version after installation

if [[ $version_before != $version_after ]];then                                                                  #if the testcase fails, generate the reasons for the failure
echo -e "The Linux version was changed after installation. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! systemctl is-enabled $servicename |grep -q enabled;then                                                     #if the testcase fails, generate the reasons for the failure
echo -e "The service $servicename was not enabled when starting the operating system. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $service|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]];then                #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $service was not 644. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $InstallPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_755 ]];then             #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $InstallPath was not 755. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $DataPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_755 ]];then                #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $DataPath was not 755. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $LogPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_755 ]];then                 #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $LogPath was not 755. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $ConfigPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_SUID_755 ]];then         #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $ConfigPath was not 755. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $InstallPath|grep -o "$root_user"|wc -l` -eq 2 ]];then                                           #if the testcase fails, generate the reasons for the failure
echo -e "The user or group was not $root_user for $InstallPath. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $DataPath|grep -o "$user"|wc -l` -eq 3 ]];then                                                   #if the testcase fails, generate the reasons for the failure
echo -e "The user or group was not $user for $DataPath. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $LogPath|grep -o "$user"|wc -l` -eq 3 ]];then                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The user or group was not $user for $LogPath. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $ConfigPath|awk '{print $3}'|grep -o "$root_user"|wc -l` -eq 1 ]];then                           #if the testcase fails, generate the reasons for the failure
echo -e "The user was not $root_user for $ConfigPath. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $ConfigPath|awk '{print $4}'|grep -o "$user"|wc -l` -eq 1 ]];then                                #if the testcase fails, generate the reasons for the failure
echo -e "The user was not $user for $ConfigPath. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$Port1|grep LISTEN >/dev/null 2>&1;then                                                             #if the testcase fails, generate the reasons for the failure
echo -e "The Port $Port1 is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$Port2|grep LISTEN >/dev/null 2>&1;then                                                             #if the testcase fails, generate the reasons for the failure
echo -e "The Port $Port2 is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$Port3|grep LISTEN >/dev/null 2>&1;then                                                             #if the testcase fails, generate the reasons for the failure
echo -e "The Port $Port3 is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$TcpPort|grep LISTEN >/dev/null 2>&1;then                                                           #if the testcase fails, generate the reasons for the failure
echo -e "The Port $TcpPort is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
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

if [ ! -f $logfile ];then                                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The Log File $logfile was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -f $etcfile ];then                                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The Config File $etcfile was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -f $version ];then                                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The $version was not found under installation directory. This is the reason \
why the testcase failed.">>$log_fail
fi

if [ ! -f $uninstall ];then                                                                                      #if the testcase fails, generate the reasons for the failure
echo -e "uninstall.sh was not copied to $UninstallPath. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `curl --tlsv1.2 -i -s -XGET -u $UserName:$Password http://$IP:$Port2/api/vhosts |grep running` ]];then   #if the testcase fails, generate the reasons for the failure                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The RabbitMQ Web management interface cannot be accessed. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                       #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 && [ -f $uninstall ] \
&& grep -q "$msg_install" $log && [ -d $InstallPath ] && [[ $version_before == $version_after ]] \
&& systemctl is-enabled $servicename |grep -q enabled && lsof -i:$TcpPort|grep LISTEN >/dev/null 2>&1\
&& [ -d $ConfigPath ] && [ -f $etcfile ] && [ -f $logfile ] && [ -d $LogPath ] && [ -f $version ] \
&& [[ `ls -ld $service|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]] \
&& [[ `ls -ld $InstallPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_755 ]] \
&& [[ `ls -ld $DataPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_755 ]] \
&& [[ `ls -ld $LogPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_755 ]] \
&& [[ `ls -ld $ConfigPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_SUID_755 ]] \
&& [[ `ls -ld $InstallPath|grep -o "$root_user"|wc -l` -eq 2 ]] && lsof -i:$Port1|grep LISTEN >/dev/null 2>&1 \
&& [[ `ls -ld $DataPath|grep -o "$user"|wc -l` -eq 3 ]] && lsof -i:$Port2|grep LISTEN >/dev/null 2>&1 \
&& [[ `ls -ld $LogPath|grep -o "$user"|wc -l` -eq 3 ]] && lsof -i:$Port3|grep LISTEN >/dev/null 2>&1 \
&& [[ `ls -ld $ConfigPath|awk '{print $3}'|grep -o "$root_user"|wc -l` -eq 1 ]] \
&& [[ `ls -ld $ConfigPath|awk '{print $4}'|grep -o "$user"|wc -l` -eq 1 ]] \
&& [[ `curl --tlsv1.2 -i -s -XGET -u $UserName:$Password http://$IP:$Port2/api/vhosts |grep running` ]];then     #determine if RabbitMQ installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall RabbitMQ using uninstall.sh
cleanup                                                                                                          #invoke cleanup funtion to purge all RabbitMQ related stuffs
