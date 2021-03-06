#!/usr/bin/bash

##################################################################################################################
#title           :sm_install_firewall_umask_sudo.sh                                                              #
#description     :The purpose of this testcase is to test that Service Monitor Agent                             #
#                 can be successfully installed in docker by invoking the original install.sh script, if         #
#                 firewall service has been started, and umask is 077,                                           #
#                 and sudo will be used on a non-root user,                                                      #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author		     :Derek Li                                                                                       #
#date            :20190319                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./sm_install_firewall_umask_sudo.sh                                                            #
#actual results  :Testcase sm_install_firewall_umask_sudo.sh passed!                                             #
#expected results:Testcase sm_install_firewall_umask_sudo.sh passed!                                             #
##################################################################################################################

profile="/etc/profile"                                                                                           #profile where umask can be changed
profile_affix=`basename $profile`                                                                                #get profile command name
rm -rf $profile_affix                                                                                            #remove profile conflict
cp $profile ./                                                                                                   #make a copy of /etc/profile to the installation directory before installation
newuser="derek"                                                                                                  #new user
sudoers="/etc/sudoers"                                                                                           #sudoers location
sudoers_affix=`basename $sudoers`                                                                                #get sudoers command name
newper="$newuser ALL=(ALL) NOPASSWD:ALL"                                                                         #set permission for sudo for the new user
rm -rf $sudoers_affix                                                                                            #remove sudoers for conflict
cp $sudoers ./                                                                                                   #make a copy of /etc/sudoers to the installation directory before installation
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
cp $profile_affix $profile                                                                                       #restore /etc/profile
source $profile                                                                                                  #take the new umask in effect in /etc/profile
sed -i '/^umask/d' $HOME/.bash_profile                                                                           #delete the line containing umask
source $HOME/.bash_profile                                                                                       #take the new umask in effect in .bash_profile
userdel -r -f $user >/dev/null 2>&1                                                                              #remove Service Monitor Agent user and group
groupdel $user >/dev/null 2>&1                                                                                   #remove Service Monitor Agent group
userdel -r -f $newuser >/dev/null 2>&1                                                                           #remove Service Monitor Agent user cleanly
groupdel $newuser >/dev/null 2>&1                                                                                #remove Service Monitor Agent group cleanly
cp $sudoers_affix $sudoers                                                                                       #restore /etc/sudoers
chmod u-w $sudoers                                                                                               #remove write permission for /etc/sudoers 
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
old_umask=`grep "umask" $profile|tail -1`                                                                        #old default umask
new_umask="umask 077"                                                                                            #new umask
sed -i "s/$old_umask/    $new_umask/g" $profile                                                                  #change the current umask in /etc/profile
source $profile                                                                                                  #take the new umask in effect in /etc/profile
echo $new_umask >>$HOME/.bash_profile                                                                            #add the new umask in /etc/profile
source $HOME/.bash_profile                                                                                       #take the new umask in effect in .bash_profile
umask_before=`umask`                                                                                             #the umask value before installation
chmod u+w $sudoers                                                                                               #give write permission for /etc/sudoers 
root_line_number=`grep -n "^root" $sudoers|cut -f 1 -d":"`                                                       #get root sudoers config line number
sed -i "$root_line_number a$newper" $sudoers                                                                     #add new user permission for sudo in /etc/sudoers
input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the Service Monitor Agent config file name
Port="17123"                                                                                                     #The port used by Service Monitor Agent
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
service firewalld start >/dev/null 2>&1                                                                          #start firewalld service
rm -rf $log $log_fail                                                                                            #remove logs for conflict
adduser $newuser                                                                                                 #add a new user
chown $newuser:$newuser $input                                                                                   #change the user and group of input.file to newuser
timeout 600 su $newuser --session-command "sudo ./install.sh <$input" >$log 2>&1                                 #execute Service Monitor Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all Service Monitor Agent related stuffs
    exit 0
fi
umask_after=`umask`                                                                                              #the umask value after installation
chown root:root $input                                                                                           #change the user and group of input.file to root
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

if ! sh -c "service firewalld status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                          #if the testcase fails, generate the reasons for the failure
echo -e "The firewalld service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                       #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "firewall-cmd --list-ports |grep $Port >/dev/null 2>&1">/dev/null 2>&1;then                           #if the testcase fails, generate the reasons for the failure
echo -e "The port $Port was not adding to the firewall list. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! $umask_before == $umask_after ];then                                                                      #if the testcase fails, generate the reasons for the failure
echo -e "The umask after installation was not $umask_before. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service firewalld status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& grep -q "$msg_install" $log && [ -d $InstallPath ] \
&& sh -c "firewall-cmd --list-ports |grep $Port >/dev/null 2>&1">/dev/null 2>&1 \
&& [ -d $LogPath ] && [ $umask_before == $umask_after ];then                                                     #determine if Service Monitor Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all Service Monitor Agent related stuffs
