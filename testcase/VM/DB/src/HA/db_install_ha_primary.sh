#!/usr/bin/bash

##################################################################################################################
#title           :db_install_ha_primary.sh                                                                       #
#description     :The purpose of this testcase is to test that MongoDB                                           #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 The installation is for MongoDB replica for primary,                                           #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author          :Zihao Yan                                                                                       #
#date            :20190613                                                                                       #
#version         :1.0                                                                                            #
#usage           :./db_install_ha_primary.sh                                                                     #
#actual results  :Testcase db_install_ha_primary.sh passed!                                                      #
#expected results:Testcase db_install_ha_primary.sh passed!                                                      #
##################################################################################################################
conf_path=`ls config/setup.conf`                                                                                 #the MongoDB config file name
Password="`grep "^Password" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default Password
Password_line_number=`grep -n "^Password" $conf_path|cut -f 1 -d":"`                                             #get Password config line number
New_Password="ABCDEFGHI0123456789"                                                                               #the new Password
sed -i "${Password_line_number}s/$Password/$New_Password/" $conf_path                                            #modify the MongoDB conf file, change default Password
servicename="mongod"                                                                                             #MongoDB service name
log="DB.log"                                                                                                     #installation log generated in the current directory
log_fail="DB_fail.log"                                                                                           #generate logs only if the testcase failed
BindIp="`grep "^BindIp" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #the default BindIp
BindIp_line_number=`grep -n "^BindIp" $conf_path|cut -f 1 -d":"`                                                 #get BindIp config line number
New_BindIp="`hostname -I|awk '{print $1}'`"                                                                      #the new BindIp which is the current IP address
sed -i "${BindIp_line_number}s/$BindIp/$New_BindIp/" $conf_path                                                  #modify the MongoDB conf file, change default BindIp
ReplicaSetMembers="`grep "^ReplicaSetMembers" $conf_path|tr "=" " "|awk '{print $2}'`"                           #the default ReplicaSetMembers
ReplicaSetMembers_line_number=`grep -n "^ReplicaSetMembers" $conf_path|cut -f 1 -d":"`                           #get ReplicaSetMembers config line number
New_ReplicaSetMembers="192.168.30.187 192.168.30.188 192.168.30.189"                                             #the new ReplicaSetMembers which are MongoDB replica
sed -i "${ReplicaSetMembers_line_number}s/$ReplicaSetMembers/$New_ReplicaSetMembers/" $conf_path                 #modify the MongoDB conf file, change default ReplicaSetMembers
msg_install='Successfully installed MongoDB'                                                                     #message for a sign of successfully installing the MongoDB
msg_install_login='Successfully logged in MongoDB with username'                                                 #message for a sign of successfully logging in MongoDB
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
crontab="\*/10 \* \* \* \* /usr/sbin/logrotate -v '/etc/logrotate.d/mongod.conf' >/dev/null 2>&1"                #cron job for log rotate
rm -rf $log $log_fail                                                                                            #remove logs for conflict
cd replica                                                                                                       #go into replica directory
timeout 600 ./install_primary.sh >../$log 2>&1                                                                   #execute MongoDB installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cd ..                                                                                                        #back to the upper directory
	exit 0
fi
cd ..                                                                                                            #back to the upper directory
if [[ `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_Password" --binary-files=without-match` ]];then                                              #if the testcase fails, generate the reasons for the failure
echo -e "The Password $New_Password was not encrypted in some of the files generated. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
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

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& [[ ! `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_Password" --binary-files=without-match` ]] \
&& grep -q "$msg_install" $log && grep -q "$msg_install_login" $log \
&& [[ $(crontab -l|grep "$crontab") ]] && [ -d $DataPath ] && [ -d $LogPath ];then                               #determine if MongoDB installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
