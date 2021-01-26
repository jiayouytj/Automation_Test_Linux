#!/usr/bin/bash

##################################################################################################################
#title           :es_install.sh                                                                                  #
#description     :The purpose of this testcase is to test that Elasticsearch                                     #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author		     :Zihao Yan                                                                                       #
#date            :20190305                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./es_install.sh                                                                                #
#actual results  :Testcase es_install.sh passed!                                                                 #
#expected results:Testcase es_install.sh passed!                                                                 #
##################################################################################################################

cleanup()
{
user="elasticsearch"                                                                                             #Elasticsearch user
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain/"                                                                        #unified UninstallPath
UnifiedConfigPath="/etc/elasticsearch/"                                                                          #unified ConfigPath
UninstallPath="/usr/lib/netbrain/installer/elasticsearch"                                                        #uninstall.sh copied to UninstallPath
echo "y"|$UninstallPath/uninstall.sh >/dev/null 2>&1                                                             #uninstall Elasticsearch
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall Elasticsearch
rpm -qa|grep -E "elasticsearch"|xargs rpm -e >/dev/null 2>&1                                                     #uninstall all Elasticsearch related rpms if they have been installed
rm -rf $DataPath $LogPath $UnifiedConfigPath $UnifiedLogPath $UnifiedUninstallPath                               #remove all Elasticsearch files and paths
userdel -r -f $user >/dev/null 2>&1                                                                              #remove Elasticsearch user and group
groupdel $user >/dev/null 2>&1                                                                                   #remove Elasticsearch group
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
cleanup                                                                                                          #invoke cleanup funtion to purge all Elasticsearch related stuffs
conf_path=`ls config/setup.conf`                                                                                 #the Elasticsearch config file name
servicename="elasticsearch"                                                                                      #Elasticsearch service name
log="ES.log"                                                                                                     #installation log generated in the current directory
log_fail="ES_fail.log"                                                                                           #generate logs only if the testcase failed
MemoryLimit="`grep "^MemoryLimit" $conf_path|tr "=" " "|awk '{print $2}'`"                                       #the default MemoryLimit
MemoryLimit_line_number=`grep -n "^MemoryLimit" $conf_path|cut -f 1 -d":"`                                       #get MemoryLimit config line number
New_MemoryLimit="1%"                                                                                             #the new MemoryLimit which is 1%
sed -i "${MemoryLimit_line_number}s/$MemoryLimit/$New_MemoryLimit/" $conf_path                                   #modify the Elasticsearch conf file, change default MemoryLimit
msg_install='Successfully installed Elasticsearch'                                                               #message for a sign of successfully installing the elasticsearch
msg_init='initialized the username and password in the Elasticsearch'                                            #message for a sign of successfully initializing the username and password in the elasticsearch
msg_connect='connected to the Elasticsearch'                                                                     #message for a sign of successfully connecting to the elasticsearch
msg_execution='The setup is complete'                                                                            #message for a sign of successfully completing the installation
InstallPath="/usr/share/elasticsearch"                                                                           #the default InstallPath
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
rm -rf $log $log_fail                                                                                            #remove logs for conflict
service firewalld stop >/dev/null 2>&1                                                                           #stop firewalld service
timeout 600 ./install.sh >$log 2>&1                                                                              #execute Elasticsearch installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all Elasticsearch related stuffs
    exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_init" $log;then                                                                               #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_init. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_connect" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_connect. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_execution" $log;then                                                                          #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_execution. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $InstallPath ];then                                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The Installation Path $InstallPath was not created. This may indicate \
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
&& grep -q "$msg_install" $log && grep -q "$msg_init" $log && grep -q "$msg_connect" $log \
&& grep -q "$msg_execution" $log && [ -d $DataPath ] && [ -d $LogPath ] && [ -d $InstallPath ];then              #determine if Elasticsearch installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all Elasticsearch related stuffs
