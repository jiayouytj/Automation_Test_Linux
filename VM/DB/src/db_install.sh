#!/usr/bin/bash

##################################################################################################################
#title           :db_install.sh                                                                                  #
#description     :The purpose of this testcase is to test that MongoDB                                           #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author          :Zihao Yan                                                                                       #
#date            :20190401                                                                                       #
#version         :1.0                                                                                            #
#usage           :./db_install.sh                                                                                #
#actual results  :Testcase db_install.sh passed!                                                                 #
#expected results:Testcase db_install.sh passed!                                                                 #
##################################################################################################################
cleanup()
{
user="netbrain"                                                                                                  #MongoDB user
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain/"                                                                        #unified UninstallPath
UnifiedConfigPath="/etc/mongodb/"                                                                                #unified ConfigPath
UninstallPath="/usr/lib/netbrain/installer/mongodb"                                                              #uninstall.sh copied to the UninstallPath
echo "y"|$UninstallPath/uninstall.sh >/dev/null 2>&1                                                             #uninstall MongoDB using uninstall.sh
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall MongoDB using uninstall.sh
rpm -qa|grep -E "mongod"|xargs rpm -e >/dev/null 2>&1                                                            #uninstall all MongoDB related rpms if they have been installed
rm -rf  $DataPath $LogPath $UnifiedConfigPath $UnifiedLogPath $UnifiedUninstallPath /etc/*.js                    #remove all MongoDB files and paths
userdel -r -f $user >/dev/null 2>&1                                                                              #remove MongoDB user and group
groupdel $user >/dev/null 2>&1                                                                                   #remove MongoDB group
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
cleanup                                                                                                          #invoke cleanup funtion to purge all MongoDB related stuffs
conf_path=`ls config/setup.conf`                                                                                 #the MongoDB config file name
servicename="mongod"                                                                                             #MongoDB service name
log="DB.log"                                                                                                     #installation log generated in the current directory
log_fail="DB_fail.log"                                                                                           #generate logs only if the testcase failed
BindIp="`grep "^BindIp" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #the default BindIp
BindIp_line_number=`grep -n "^BindIp" $conf_path|cut -f 1 -d":"`                                                 #get BindIp config line number
New_BindIp="`hostname -I|awk '{print $1}'`"                                                                      #the new BindIp which is the current IP address
sed -i "${BindIp_line_number}s/$BindIp/$New_BindIp/" $conf_path                                                  #modify the MongoDB conf file, change default BindIp
ReplicaSetMembers="`grep "^ReplicaSetMembers" $conf_path|tr "=" " "|awk '{print $2}'`"                           #the default ReplicaSetMembers
ReplicaSetMembers_line_number=`grep -n "^ReplicaSetMembers" $conf_path|cut -f 1 -d":"`                           #get ReplicaSetMembers config line number
New_ReplicaSetMembers="`hostname -I|awk '{print $1}'`"                                                           #the new ReplicaSetMembers which is the current IP address
sed -i "${ReplicaSetMembers_line_number}s/$ReplicaSetMembers/$New_ReplicaSetMembers/" $conf_path                 #modify the MongoDB conf file, change default ReplicaSetMembers
msg_install='Successfully installed MongoDB'                                                                     #message for a sign of successfully installing the MongoDB
msg_install_login='Successfully logged in MongoDB with username'                                                 #message for a sign of successfully logging in MongoDB
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
crontab="\*/10 \* \* \* \* /usr/sbin/logrotate -v '/etc/logrotate.d/mongod.conf' >/dev/null 2>&1"                #cron job for log rotate
rm -rf $log $log_fail                                                                                            #remove logs for conflict
service firewalld stop >/dev/null 2>&1                                                                           #stop firewalld service
timeout 600 ./install.sh >$log 2>&1                                                                              #execute MongoDB installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_install_login" $log;then                                                                      #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install_login. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! [[ $(crontab -l|grep "$crontab") ]];then                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "There is no cron job for log rotate, or the cron job is incorrect. This may indicate \
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
&& grep -q "$msg_install" $log && grep -q "$msg_install_login" $log \
&& [[ $(crontab -l|grep "$crontab") ]] && [ -d $DataPath ] && [ -d $LogPath ];then                               #determine if MongoDB installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all MongoDB related stuffs
