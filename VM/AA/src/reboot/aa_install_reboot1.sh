#!/usr/bin/bash

##################################################################################################################
#title           :aa_install_reboot1.sh                                                                          #
#description     :The purpose of this testcase is to test that Ansible Agent                                     #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author		     :Zihao Yan                                                                                       #
#date            :20190213                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./aa_install_reboot1.sh                                                                        #
#actual results  :Testcase aa_install_reboot1.sh passed!                                                         #
#expected results:Testcase aa_install_reboot1.sh passed!                                                         #
##################################################################################################################

cleanup()
{
user="netbrain"                                                                                                  #Ansible Agent user
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain/"                                                                        #unified UninstallPath
UnifiedConfigPath="/etc/netbrain/"                                                                               #unified ConfigPath
UninstallPath="/usr/lib/netbrain/installer/ansibleagent"                                                         #uninstall.sh copied to the UninstallPath
echo "y"|$UninstallPath/uninstall.sh >/dev/null 2>&1                                                             #uninstall Ansible Agent using uninstall.sh
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall Ansible Agent using uninstall.sh
rpm -qa|grep -E "^netbrainansibleagent"|xargs rpm -e >/dev/null 2>&1                                             #uninstall all Ansible Agent related rpms if they have been installed
rm -rf $InstallPath $LogPath $UnifiedConfigPath $UnifiedLogPath $UnifiedUninstallPath                            #remove all Ansible Agent files and paths
userdel -r -f $user >/dev/null 2>&1                                                                              #remove Ansible Agent user and group
groupdel $user >/dev/null 2>&1                                                                                   #remove Ansible Agent group
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
cleanup                                                                                                          #invoke cleanup funtion to purge all Ansible Agent related stuffs
input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the Ansible Agent config file name
servicename="netbrainansibleagent"                                                                               #Ansible Agent service name
log="AA.log"                                                                                                     #installation log generated in the current directory
msg_install="Successfully installed Ansible Agent"                                                               #message for a sign of successfully installing the Ansible Agent
InstallPath="/usr/lib/netbrain/ansibleagent"                                                                     #the default Installation Path
AnsibleKey="`grep "^AnsibleKey" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #default AnsibleKey
Port="`grep "^Port" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Port
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
logfile="$LogPath/log/services.log"                                                                              #an important log for verification
rm -rf $log                                                                                                      #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Ansible Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    cleanup                                                                                                      #invoke cleanup funtion to purge all Ansible Agent related stuffs
	exit 0
fi