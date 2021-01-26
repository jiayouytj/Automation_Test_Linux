#!/usr/bin/bash

##################################################################################################################
#title           :re_install.sh                                                                                  #
#description     :The purpose of this testcase is to test that Redis                                             #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author		     :Zihao Yan                                                                                       #
#date            :20190303                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./re_install.sh                                                                                #
#actual results  :Testcase re_install.sh passed!                                                                 #
#expected results:Testcase re_install.sh passed!                                                                 #
##################################################################################################################

cleanup()
{
user="redis"                                                                                                     #Redis user
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain/"                                                                        #unified UninstallPath
UnifiedConfigPath="/etc/redis/"                                                                                  #unified ConfigPath
UninstallPath="/usr/lib/netbrain/installer/redis"                                                                #uninstall.sh copied to the UninstallPath
echo "y"|$UninstallPath/uninstall.sh >/dev/null 2>&1                                                             #uninstall Redis using uninstall.sh
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall Redis using uninstall.sh
rpm -qa|grep -E "redis"|xargs rpm -e >/dev/null 2>&1                                                             #uninstall all Redis related rpms if they have been installed
rm -rf  $DataPath $LogPath $UnifiedConfigPath $UnifiedLogPath $UnifiedUninstallPath                              #remove all Redis files and paths
userdel -r -f $user >/dev/null 2>&1                                                                              #remove Redis user and group
groupdel $user >/dev/null 2>&1                                                                                   #remove Redis group
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
sed -i "/logrotate/d" /var/spool/cron/root                                                                       #delete all log rotate related cron job                   
}
cleanup                                                                                                          #invoke cleanup funtion to purge all Redis related stuffs
conf_path=`ls config/setup.conf`                                                                                 #the Redis config file name
IP="`hostname -I|awk '{print $1}'`"                                                                              #the current IP address
Password="`grep "^Password" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default Password
Port="`grep "^Port" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Port
servicename="redis"                                                                                              #Redis service name
log="RE.log"                                                                                                     #installation log generated in the current directory
log_fail="RE_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed Redis"                                                                       #message for a sign of successfully installing the Redis
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
crontab="\*/30 \* \* \* \* /usr/sbin/logrotate -v '/etc/logrotate.d/redis.conf' >/dev/null 2>&1"                 #cron job for log rotate
rm -rf $log $log_fail                                                                                            #remove logs for conflict
service firewalld stop >/dev/null 2>&1                                                                           #stop firewalld service
timeout 600 ./install.sh >$log 2>&1                                                                              #execute Redis installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
   cleanup                                                                                                       #invoke cleanup funtion to purge all Redis related stuffs
    exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $DataPath ];then                                                                                       #if the testcase fails, generate the reasons for the failure
echo -e "The Data Path $DataPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $LogPath ];then                                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The Log Path $LogPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "redis-cli -h $IP -p $Port -a $Password --no-auth-warning PING \
|grep PONG>/dev/null 2>&1">/dev/null 2>&1;then                                                                   #if the testcase fails, generate the reasons for the failure                                                                             #if the testcase fails, generate the reasons for the failure
echo -e "The Redis command line interface is not available. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! [[ $(crontab -l|grep "$crontab") ]];then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "There is no cron job for log rotate, or the cron job is incorrect. This may indicate \
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
&& grep -q "$msg_install" $log && [ -d $DataPath ] && [ -d $LogPath ] \
&& sh -c "redis-cli -h $IP -p $Port -a $Password --no-auth-warning PING \
|grep PONG>/dev/null 2>&1">/dev/null 2>&1 && [[ $(crontab -l|grep "$crontab") ]];then                            #determine if Redis installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all Redis related stuffs
