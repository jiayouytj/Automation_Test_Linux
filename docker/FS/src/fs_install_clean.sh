#!/usr/bin/bash

##################################################################################################################
#title           :fs_install_clean.sh                                                                            #
#description     :The purpose of this testcase is to test that Front Server                                      #
#                 can be successfully installed in docker by invoking the original install.sh script with,       #
#                 strong verification, which means that install.sh is correctly invoked and executed.            #
#author		     :Zihao Yan                                                                                       #
#date            :20190409                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./fs_install_clean.sh                                                                          #
#actual results  :Testcase fs_install_clean.sh passed!                                                           #
#expected results:Testcase fs_install_clean.sh passed!                                                           #
##################################################################################################################

input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
version="fix_releaseinfo.json"                                                                                   #a JSON file containing release info under the installation directory
servicename="netbrainfrontserver"                                                                                #Front Server service name
log="FS.log"                                                                                                     #installation log generated in the current directory
log_fail="FS_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed Front Server"                                                                #message for a sign of successfully installing the Front Server
InstallPath="/usr/lib/netbrain/frontserver"                                                                      #the default Installation Path
logfile="/var/log/netbrain/installationlog/frontserver/install.log"                                              #Front Server installation log
service="/usr/lib/systemd/system/$servicename.service"                                                           #Front Server systemd service file
wants="Wants=network-online.target"                                                                              #systemd unit target
after="After=network-online.target"                                                                              #systemd unit target
uninstall="/usr/lib/netbrain/installer/frontserver/uninstall.sh"                                                 #uninstall.sh copied to the installation path
user="netbrain"                                                                                                  #the user to be used by Front Server
root_user="root"                                                                                                 #root user
permission_755="rwxr-xr-x"                                                                                       #the permission for 755
permission_644="rw-r--r--"                                                                                       #the permission for 644
version_before=`cat /etc/redhat-release`                                                                         #the Linux version before installation
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Front Server installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi
version_after=`cat /etc/redhat-release`                                                                          #the Linux version after installation

if [[ ! $version_before == $version_after ]];then                                                                #if the testcase fails, generate the reasons for the failure
echo -e "The Linux version was changed after installation. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! systemctl is-enabled $servicename |grep -q enabled;then                                                     #if the testcase fails, generate the reasons for the failure
echo -e "The service $servicename was not enabled when starting the operating system. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $service|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]];then                #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $service was not 644. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $InstallPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_755 ]];then             #if the testcase fails, generate the reasons for the failure
echo -e "The permission of $InstallPath was not 755. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [[ ! `ls -ld $InstallPath|grep -o "$root_user"|wc -l` -eq 3 ]];then                                           #if the testcase fails, generate the reasons for the failure
echo -e "The user or group was not $root_user for $InstallPath. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$wants" $service;then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The systemd did not configure the correct target unit for Wants. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$after" $service;then                                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The systemd did not configure the correct target unit for After. This may indicate \
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

if [ ! -f $logfile ];then                                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The Log File $logfile was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -f $version ];then                                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The $version was not found under installation directory. This is the reason \
why the testcase failed.">>$log_fail
fi

if [ ! -f $uninstall ];then                                                                                      #if the testcase fails, generate the reasons for the failure
echo -e "uninstall.sh was not copied to $InstallPath. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $servicename status |grep dead >/dev/null 2>&1">/dev/null 2>&1;then                          #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename service is not in dead state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep dead >/dev/null 2>&1">/dev/null 2>&1 \
&& systemctl is-enabled $servicename |grep -q enabled && [ -f $logfile ] && [ -f $uninstall ] \
&& grep -q "$msg_install" $log && [ -d $InstallPath ] && [ -f $version ] \
&& grep -q "$wants" $service && grep -q "$after" $service \
&& [[ `ls -ld $service|awk '{print $1}'|sed "s/^-//g"|sed "s/\.//g"` == $permission_644 ]] \
&& [[ `ls -ld $InstallPath|awk '{print $1}'|sed "s/d//g"|sed "s/\.//g"` == $permission_755 ]] \
&& [[ `ls -ld $InstallPath|grep -o "$user"|wc -l` -eq 3 ]];then                                                  #determine if Front Server installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
