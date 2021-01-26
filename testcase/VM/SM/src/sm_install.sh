#!/usr/bin/bash

##################################################################################################################
#title           :sm_install.sh                                                                                  #
#description     :The purpose of this testcase is to test that Service Monitor Agent                             #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author		     :Derek Li                                                                                       #
#date            :20190319                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./sm_install.sh                                                                                #
#actual results  :Testcase sm_install.sh passed!                                                                 #
#expected results:Testcase sm_install.sh passed!                                                                 #
##################################################################################################################

cleanup()
{
user="netbrain"                                                                                                  #Service Monitor Agent user
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain/"                                                                        #unified UninstallPath
UnifiedConfigPath="/etc/netbrain/"                                                                               #unified ConfigPath
UninstallPath="/usr/lib/netbrain/installer/servicemonitoragent"                                                  #uninstall.sh copied to the UninstallPath
echo "y"|$UninstallPath/uninstall.sh >/dev/null 2>&1                                                             #uninstall Service Monitor Agent using uninstall.sh
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall Service Monitor Agent
rm -rf  $InstallPath $LogPath $ UnifiedConfigPath $UnifiedLogPath $UnifiedUninstallPath                          #remove all Service Monitor Agent files and paths
userdel -r -f $user >/dev/null 2>&1                                                                              #remove Service Monitor Agent user and group
groupdel $user >/dev/null 2>&1                                                                                   #remove Service Monitor Agent group
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
cleanup                                                                                                          #invoke cleanup funtion to purge all Service Monitor Agent related stuffs
input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the Service Monitor Agent config file name
servicename="netbrainagent"                                                                                      #Service Monitor Agent service name
log="SM.log"                                                                                                     #installation log generated in the current directory
log_fail="SM_fail.log"                                                                                           #generate logs only if the testcase failed
Server_Url="`grep "^Server_Url" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default Server_Url
Server_Url_line_number=`grep -n "^Server_Url" $conf_path|cut -f 1 -d":"`                                         #get Server_Url config line number
New_Server_Url="http://ite.netbrain.com/ServerAPI"                                                               #the new Server_Url which is a valid value
sed -i "${Server_Url_line_number}s~$Server_Url~$New_Server_Url~" $conf_path                                      #modify the Service Monitor conf file, change default Server_Key
msg_install="Successfully installed Service Monitor Agent"                                                       #message for a sign of successfully installing the Service Monitor Agent
InstallPath="/usr/share/nbagent"                                                                                 #the default Installation Path
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
Server_Key="`grep "^Server_Key" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default Server_Key
Server_Key_line_number=`grep -n "^Server_Key" $conf_path|cut -f 1 -d":"`                                         #get Server_Key config line number
New_Server_Key="abcdefgh1234567890"                                                                              #the new Server_Key
sed -i "${Server_Key_line_number}s/$Server_Key/$New_Server_Key/" $conf_path                                      #modify the Service Monitor conf file, change default Server_Key
rm -rf $log $log_fail                                                                                            #remove logs for conflict
service firewalld stop >/dev/null 2>&1                                                                           #stop firewalld service
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Service Monitor Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
   cleanup                                                                                                       #invoke cleanup funtion to purge all Service Monitor Agent related stuffs
    exit 0
fi

if [[ `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_Server_Key" --binary-files=without-match` ]];then                                            #if the testcase fails, generate the reasons for the failure
echo -e "The Server_Key $New_Server_Key was not encrypted in some of the files generated. This may indicate \
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
&& [[ ! `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_Server_Key" --binary-files=without-match` ]] \
&& grep -q "$msg_install" $log && [ -d $InstallPath ] && [ -d $LogPath ];then                                    #determine if Service Monitor Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all Service Monitor Agent related stuffs
