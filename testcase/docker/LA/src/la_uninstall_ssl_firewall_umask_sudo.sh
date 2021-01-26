#!/usr/bin/bash

##################################################################################################################
#title           :la_uninstall_ssl_firewall_umask_sudo.sh                                                        #
#description     :The purpose of this testcase is to test that License Agent                                     #
#                 can be successfully uninstalled in docker by invoking the original uninstall.sh script in      #
#                 source directory located within the installation directory, if SSL is enabled,                 #
#                 and firewall service has been started, and umask is 077, and sudo will be used                 #
#                 on a non-root user, which means that uninstall.sh is correctly invoked and executed            #
#author		     :Zihao Yan                                                                                       #
#date            :20190226                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./la_uninstall_ssl_firewall_umask_sudo.sh                                                      #
#actual results  :Testcase la_uninstall_ssl_firewall_umask_sudo.sh passed!                                       #
#expected results:Testcase la_uninstall_ssl_firewall_umask_sudo.sh passed!                                       #
##################################################################################################################

input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the License Agent config file name
servicename="netbrainlicense"                                                                                    #License Agent service name
log="LA.log"                                                                                                     #installation log generated in the current directory
log2="LA_uninstall.log"                                                                                          #uninstallation log generated in the current directory
log_fail="LA_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed License Agent"                                                               #message for a sign of successfully installing the License Agent
msg_uninstall="NetBrain License Agent has been successfully uninstalled"                                         #message for a sign of successfully uninstalling the License Agent
Port="`grep "^Port" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Port
UseSSL="`grep "^UseSSL" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #default SSL disabled
UseSSL_line_number=`grep -n "^UseSSL" $conf_path |cut -f 1 -d":"`                                                #get SSL line number
New_UseSSL="yes"                                                                                                 #enable SSL 
sed -i "${UseSSL_line_number}s/$UseSSL/$New_UseSSL/" $conf_path                                                  #modify the License Agent conf file, enable SSL
CERT="/etc/ssl/cert.pem"                                                                                         #certificate path
KEY="/etc/ssl/key.pem"                                                                                           #certificate key path
Certificate="`grep "^Certificate" $conf_path|tr "=" " "|awk '{print $2}'`"                                       #the default Certificate
Certificate_line_number=`grep -n "^Certificate" $conf_path|cut -f 1 -d":"`                                       #get Certificate config line number
sed -i "${Certificate_line_number}s~$Certificate~$CERT~" $conf_path                                              #modify the License Agent conf file, change default Certificate
PrivateKey="`grep "^PrivateKey" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default PrivateKey
PrivateKey_line_number=`grep -n "^PrivateKey" $conf_path|cut -f 1 -d":"`                                         #get PrivateKey config line number
sed -i "${PrivateKey_line_number}s~$PrivateKey~$KEY~" $conf_path                                                 #modify the License Agent conf file, change default PrivateKey
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
UninstallPath="/usr/lib/netbrain/installer/licenseagent"                                                         #uninstall.sh copied to the UninstallPath
service="/usr/lib/systemd/system/$servicename.service"                                                           #License Agent systemd service file
rm -rf $log $log2 $log_fail                                                                                      #remove logs for conflict
service firewalld start >/dev/null 2>&1                                                                          #start firewalld service
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute License Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
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

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& grep -q "$msg_install" $log && [ -d $LogPath ];then                                                           #determine if License Agent installation is successfully completed
profile="/etc/profile"                                                                                           #profile where umask can be changed
old_umask=`grep "umask" $profile|tail -1`                                                                        #old default umask
new_umask="umask 077"                                                                                            #new umask
sed -i "s/$old_umask/    $new_umask/g" $profile                                                                  #change the current umask in /etc/profile
source $profile                                                                                                  #take the new umask in effect in /etc/profile
echo $new_umask >>$HOME/.bash_profile                                                                            #add the new umask in /etc/profile
source $HOME/.bash_profile                                                                                       #take the new umask in effect in .bash_profile
umask_before=`umask`                                                                                             #the umask value before uninstallation
newuser="derek"                                                                                                  #new user
sudoers="/etc/sudoers"                                                                                           #sudoers location
chmod u+w $sudoers                                                                                               #give write permission for /etc/sudoers 
newper="$newuser ALL=(ALL) NOPASSWD:ALL"                                                                         #set permission for sudo for the new user
root_line_number=`grep -n "^root" $sudoers|cut -f 1 -d":"`                                                       #get root sudoers config line number
sed -i "$root_line_number a$newper" $sudoers                                                                     #add new user permission for sudo in /etc/sudoers
adduser $newuser                                                                                                 #add a new user
timeout 600 su $newuser --session-command "timeout 600 echo "y"|sudo $UninstallPath/uninstall.sh" >$log2 2>&1    #execute License Agent uninstallation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cat $log2 >>$log                                                                                             #merge two logs
    exit 0
fi
umask_after=`umask`                                                                                              #the umask value after uninstallation

	if ! grep -q "$msg_uninstall" $log2;then                                                                     #if the testcase fails, generate the reasons for the failure
    echo -e "The following wording information was not found in $log2: $msg_uninstall. This may indicate \
    that the uninstallation was not successful. This is the reason why the testcase failed.">>$log_fail
    fi

    if [ -d $LogPath ];then                                                                                      #if the testcase fails, generate the reasons for the failure
    echo -e "The Log Path $LogPath still existed after uninstallation, which is not an expected behavior. \
	This may indicate that the uninstallation was not successful. \
	This is the reason why the testcase failed.">>$log_fail
    fi
	
	if [ -f $service ];then                                                                                      #if the testcase fails, generate the reasons for the failure
    echo -e "The systemd service $service still existed after uninstallation, which is not an expected behavior. \
	This may indicate that the uninstallation was not successful. \
	This is the reason why the testcase failed.">>$log_fail
    fi
	
	if ! sh -c "service firewalld status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                      #if the testcase fails, generate the reasons for the failure
    echo -e "The firewalld service is not in running state. This may indicate \
    that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
    fi
	
	if [ ! $umask_before == $umask_after ];then
    echo -e "The umask after uninstallation was not $umask_before. This may indicate \
    that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
    fi
	
	if grep -q "$msg_uninstall" $log2 && [ $umask_before == $umask_after ] \
	&& sh -c "service firewalld status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
	&& [ ! -d $LogPath ] && [ ! -f $service ];then                                                               #determine if License Agent uninstallation is successfully completed
    echo "Testcase $BASH_SOURCE passed!"
	else
	echo "Testcase $BASH_SOURCE failed!"
	fi
else
echo "Testcase $BASH_SOURCE failed!"
fi

if [ -f $log2 ];then
cat $log2 >>$log                                                                                                 #merge two logs
fi












