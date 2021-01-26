#!/usr/bin/bash

##################################################################################################################
#title           :db_install_ha_ssl_fqdn_secondary.sh                                                            #
#description     :The purpose of this testcase is to test that MongoDB                                           #
#                 can be successfully installed in docker by invoking the original install.sh script, when SSL   #
#                 is enabled. The installation is for MongoDB replica for secondary using FQDN,                  #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author          :Zihao Yan                                                                                       #
#date            :20190613                                                                                       #
#version         :1.0                                                                                            #
#usage           :./db_install_ha_ssl_fqdn_secondary.sh                                                          #
#actual results  :Testcase db_install_ha_ssl_fqdn_secondary.sh passed!                                           #
#expected results:Testcase db_install_ha_ssl_fqdn_secondary.sh passed!                                           #
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
New_BindIp="0.0.0.0"                                                                                             #the new BindIp which is 0.0.0.0
sed -i "${BindIp_line_number}s/$BindIp/$New_BindIp/" $conf_path                                                  #modify the MongoDB conf file, change default BindIp
ReplicaSetMembers="`grep "^ReplicaSetMembers" $conf_path|tr "=" " "|awk '{print $2}'`"                           #the default ReplicaSetMembers
ReplicaSetMembers_line_number=`grep -n "^ReplicaSetMembers" $conf_path|cut -f 1 -d":"`                           #get ReplicaSetMembers config line number
New_ReplicaSetMembers="derek1 derek2 derek3"                                                                     #the new ReplicaSetMembers which are MongoDB replica FQDN
sed -i "${ReplicaSetMembers_line_number}s/$ReplicaSetMembers/$New_ReplicaSetMembers/" $conf_path                 #modify the MongoDB conf file, change default ReplicaSetMembers
UseSSL="`grep "^UseSSL" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #the default UseSSL
UseSSL_line_number=`grep -n "^UseSSL" $conf_path|cut -f 1 -d":"`                                                 #get UseSSL config line number
New_UseSSL="yes"                                                                                                 #the new UseSSL which is yes
sed -i "${UseSSL_line_number}s/$UseSSL/$New_UseSSL/" $conf_path                                                  #modify the MongoDB conf file, change default UseSSL
CERT="/etc/ssl/cert.pem"                                                                                         #certificate path
KEY="/etc/ssl/key.pem"                                                                                           #certificate key path
Certificate="`grep "^Certificate" $conf_path|tr "=" " "|awk '{print $2}'`"                                       #the default Certificate
Certificate_line_number=`grep -n "^Certificate" $conf_path|cut -f 1 -d":"`                                       #get Certificate config line number
sed -i "${Certificate_line_number}s~$Certificate~$CERT~" $conf_path                                              #modify the MongoDB conf file, change default Certificate
PrivateKey="`grep "^PrivateKey" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default PrivateKey
PrivateKey_line_number=`grep -n "^PrivateKey" $conf_path|cut -f 1 -d":"`                                         #get PrivateKey config line number
sed -i "${PrivateKey_line_number}s~$PrivateKey~$KEY~" $conf_path                                                 #modify the MongoDB conf file, change default PrivateKey
msg_install='Successfully installed MongoDB'                                                                     #message for a sign of successfully installing the MongoDB
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
crontab="\*/10 \* \* \* \* /usr/sbin/logrotate -v '/etc/logrotate.d/mongod.conf' >/dev/null 2>&1"                #cron job for log rotate
rm -rf $log $log_fail                                                                                            #remove logs for conflict
cd replica                                                                                                       #go into replica directory
timeout 600 ./install_secondary.sh >../$log 2>&1                                                                 #execute MongoDB installation script and save the log
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
&& grep -q "$msg_install" $log \
&& [[ $(crontab -l|grep "$crontab") ]] && [ -d $DataPath ] && [ -d $LogPath ];then                               #determine if MongoDB installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
