#!/usr/bin/bash

##################################################################################################################
#title           :la_install_logpath_immutable.sh                                                                #
#description     :The purpose of this testcase is to test that License Agent                                     #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if the LogPath is immutable.                                                                   #
#author		     :Zihao Yan                                                                                       #
#date            :20190329                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./la_install_logpath_immutable.sh                                                              #
#actual results  :Testcase la_install_logpath_immutable.sh passed!                                               #
#expected results:Testcase la_install_logpath_immutable.sh passed!                                               #
##################################################################################################################


##################################################################################################################
# The following function is for cleaning up before and after installation                                        #
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
log="LA.log"                                                                                                     #installation log generated in the current directory
log_fail="LA_fail.log"                                                                                           #generate logs only if the testcase failed
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
rm -rf $LogPath                                                                                                  #remove LogPath for conflict
mkdir -p $LogPath                                                                                                #create LogPath
chattr +i $LogPath                                                                                               #make LogPath immutable
msg_error="The directory $LogPath is immutable. The installation aborted"                                        #message for a sign of LogPath which is immutable          
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute License Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
	chattr -i $LogPath                                                                                           #make LogPath mutable
    cleanup                                                                                                      #invoke cleanup funtion to purge all License Agent related stuffs
    exit 0
fi
chattr -i $LogPath                                                                                               #make LogPath mutable
if grep -q "$msg_error" $log;then                                                                                #determine if License Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo -e "The following wording information was not found in $log: $msg_error. This is the reason why \
testcase $BASH_SOURCE failed.">$log_fail                                                                         #if the testcase fails, generate the reasons for the failure
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all License Agent related stuffs
