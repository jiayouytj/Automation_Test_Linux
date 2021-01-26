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

conf_path=`ls config/setup.conf`                                                                                 #the MongoDB config file name
servicename="mongod"                                                                                             #MongoDB service name
log="DB.log"                                                                                                     #installation log generated in the current directory
log_fail="DB_fail.log"                                                                                           #generate logs only if the testcase failed
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

if ! sh -c "service firewalld status |grep dead >/dev/null 2>&1">/dev/null 2>&1;then                             #if the testcase fails, generate the reasons for the failure
echo -e "The firewalld service is not in dead state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service firewalld status |grep dead >/dev/null 2>&1">/dev/null 2>&1 \
&& grep -q "$msg_install" $log && grep -q "$msg_install_login" $log \
&& [[ $(crontab -l|grep "$crontab") ]] && [ -d $DataPath ] && [ -d $LogPath ];then                               #determine if MongoDB installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
