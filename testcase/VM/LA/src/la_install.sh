#!/usr/bin/bash

##################################################################################################################
#title           :la_install.sh                                                                                  #
#description     :The purpose of this testcase is to test that License Agent                                     #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author          :Zihao Yan                                                                                       #
#date            :20190329                                                                                       #
#version         :1.0                                                                                            #
#usage           :./la_install.sh                                                                                #
#actual results  :Testcase la_install.sh passed!                                                                 #
#expected results:Testcase la_install.sh passed!                                                                 #
##################################################################################################################

cleanup()
{
user="netbrain"                                                                                                  #License Agent user
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain/"                                                                        #unified UninstallPath
UnifiedConfigPath="/etc/netbrainlicense/"                                                                        #unified ConfigPath
UninstallPath="/usr/lib/netbrain/installer/licenseagent"                                                         #uninstall.sh copied to the UninstallPath
echo "y"|$UninstallPath/uninstall.sh >/dev/null 2>&1                                                             #uninstall License Agent using uninstall.sh
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall Front Server using uninstall.sh
rpm -qa|grep -E "netbrainlicense"|xargs rpm -e >/dev/null 2>&1                                                   #uninstall all License Agent related rpms if they have been installed
rm -rf $LogPath $UnifiedConfigPath $UnifiedLogPath $UnifiedUninstallPath                                         #remove all License Agent files and paths
userdel -r -f $user >/dev/null 2>&1                                                                              #remove License Agent user and group
groupdel $user >/dev/null 2>&1                                                                                   #remove License Agent group
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
cleanup                                                                                                          #invoke cleanup funtion to purge all License Agent related stuffs
input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the License Agent config file name
servicename="netbrainlicense"                                                                                    #License Agent service name
log="LA.log"                                                                                                     #installation log generated in the current directory
log_fail="LA_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed License Agent"                                                               #message for a sign of successfully installing the License Agent
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
rm -rf $log $log_fail                                                                                            #remove logs for conflict
service firewalld stop >/dev/null 2>&1                                                                           #stop firewalld service
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute License Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all License Agent related stuffs
    exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
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
&& grep -q "$msg_install" $log && [ -d $LogPath ];then                                                           #determine if License Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all License Agent related stuffs
