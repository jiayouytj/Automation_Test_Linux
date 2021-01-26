#!/usr/bin/bash

##################################################################################################################
#title           :re_install_ha_ssl_fqdn_slave.sh                                                                #
#description     :The purpose of this testcase is to test that Redis                                             #
#                 can be successfully installed in docker by invoking the original install.sh script, when SSL   #
#                 is enabled. The installation is on slave for Redis cluster using FQDN on MasterNode.           #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author		     :Zihao Yan                                                                                       #
#date            :20190613                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./re_install_ha_ssl_fqdn_slave.sh                                                              #
#actual results  :Testcase re_install_ha_ssl_fqdn_slave.sh passed!                                               #
#expected results:Testcase re_install_ha_ssl_fqdn_slave.sh passed!                                               #
##################################################################################################################

conf_path=`ls config/setup.conf`                                                                                 #the Redis config file name
Password="`grep "^Password" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default Password
Password_line_number=`grep -n "^Password" $conf_path|cut -f 1 -d":"`                                             #get Password config line number
New_Password="ABCDEFGHI0123456789"                                                                               #the new Password
sed -i "${Password_line_number}s/$Password/$New_Password/" $conf_path                                            #modify the Redis conf file, change default Password
Mode="`grep "^Mode" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Mode
Mode_line_number=`grep -n "^Mode" $conf_path|cut -f 1 -d":"`                                                     #get Mode config line number
New_Mode="cluster"                                                                                               #the new Mode which is cluster
sed -i "${Mode_line_number}s/$Mode/$New_Mode/" $conf_path                                                        #modify the RabbitMQ conf file, change default Mode
NodeRole="`grep "^NodeRole" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default NodeRole
NodeRole_line_number=`grep -n "^NodeRole" $conf_path|cut -f 1 -d":"`                                             #get NodeRole config line number
New_NodeRole="slave"                                                                                             #the new NodeRole which is slave
sed -i "${NodeRole_line_number}s/$NodeRole/$New_NodeRole/" $conf_path                                            #modify the RabbitMQ conf file, change default NodeRole
MasterNode="`grep "^MasterNode" $conf_path`"                                                                     #the default MasterNode
MasterNode_line_number=`grep -n "^MasterNode" $conf_path|cut -f 1 -d":"`                                         #get MasterNode config line number
New_MasterNode="MasterNode=192.168.30.187"                                                                       #the new MasterNode which is the IP if Master Node
sed -i "${MasterNode_line_number}s/$MasterNode/$New_MasterNode/" $conf_path                                      #modify the RabbitMQ conf file, change default MasterNode
UseSSL="`grep "^UseSSL" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #the default UseSSL
UseSSL_line_number=`grep -n "^UseSSL" $conf_path|cut -f 1 -d":"`                                                 #get UseSSL config line number
New_UseSSL="yes"                                                                                                 #the new UseSSL which is yes
sed -i "${UseSSL_line_number}s/$UseSSL/$New_UseSSL/" $conf_path                                                  #modify the Redis conf file, change default UseSSL
CERT="/etc/ssl/cert.pem"                                                                                         #certificate path
KEY="/etc/ssl/key.pem"                                                                                           #certificate key path
Certificate="`grep "^Certificate" $conf_path|tr "=" " "|awk '{print $2}'`"                                       #the default Certificate
Certificate_line_number=`grep -n "^Certificate" $conf_path|cut -f 1 -d":"`                                       #get Certificate config line number
sed -i "${Certificate_line_number}s~$Certificate~$CERT~" $conf_path                                              #modify the Redis conf file, change default Certificate
PrivateKey="`grep "^PrivateKey" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default PrivateKey
PrivateKey_line_number=`grep -n "^PrivateKey" $conf_path|cut -f 1 -d":"`                                         #get PrivateKey config line number
sed -i "${PrivateKey_line_number}s~$PrivateKey~$KEY~" $conf_path                                                 #modify the Redis conf file, change default PrivateKey
servicename="redis-slave"                                                                                        #Redis slave service name
servicename_sentinel="redis-sentinel"                                                                            #Redis sentinel service name
servicename_ssl="stunnel"                                                                                        #stunnel service name if SSL is enabled
RE_slave_systemd="/usr/lib/systemd/system/redis-slave.service"                                                   #Redis slave systemd file             
RE_sentinel_systemd="/usr/lib/systemd/system/redis-sentinel.service"                                             #Redis sentinel systemd file
RE_ssl_systemd="/usr/lib/systemd/system/stunnel.service"                                                         #Stunnel systemd file
log="RE.log"                                                                                                     #installation log generated in the current directory
log_fail="RE_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed Redis"                                                                       #message for a sign of successfully installing the Redis
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
crontab="\*/30 \* \* \* \* /usr/sbin/logrotate -v '/etc/logrotate.d/redis.conf' >/dev/null 2>&1"                 #cron job for log rotate
permission_644="rw-r--r--"                                                                                       #the permission for 644
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh >$log 2>&1                                                                              #execute Redis installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
   cleanup                                                                                                       #invoke cleanup funtion to purge all Redis related stuffs
    exit 0
fi

if [[ `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_Password" --binary-files=without-match` ]];then                                              #if the testcase fails, generate the reasons for the failure
echo -e "The Password $New_Password was not encrypted in some of the files generated. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $RE_slave_systemd|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]];then       #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $RE_slave_systemd was not 644. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $RE_sentinel_systemd|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]];then    #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $RE_sentinel_systemd was not 644. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $RE_ssl_systemd|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]];then         #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $RE_ssl_systemd was not 644. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
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

if ! grep -q "Restart=on-failure" "$RE_slave_systemd";then                                                       #if the testcase fails, generate the reasons for the failure
echo -e "The restarting rule is not on-failure defined in redis-slave systemd. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "Restart=on-failure" "$RE_sentinel_systemd";then                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The restarting rule is not on-failure defined in redis-sentinel systemd. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "Restart=on-failure" "$RE_ssl_systemd";then                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The restarting rule is not on-failure defined in Stunnel systemd. This may indicate \
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

if ! sh -c "service $servicename_sentinel status |grep running >/dev/null 2>&1">/dev/null 2>&1;then              #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename_sentinel service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $servicename_ssl status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                   #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename_ssl service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service $servicename_sentinel status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service $servicename_ssl status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& [[ `ls -ld $RE_slave_systemd|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]] \
&& [[ `ls -ld $RE_sentinel_systemd|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]] \
&& [[ `ls -ld $RE_ssl_systemd|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]] \
&& grep -q "$msg_install" $log && [ -d $DataPath ] && [ -d $LogPath ] \
&& grep -q "Restart=on-failure" "$RE_slave_systemd" && grep -q "Restart=on-failure" "$RE_sentinel_systemd" \
&& grep -q "Restart=on-failure" "$RE_ssl_systemd" && [[ $(crontab -l|grep "$crontab") ]];then                    #determine if Redis installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
