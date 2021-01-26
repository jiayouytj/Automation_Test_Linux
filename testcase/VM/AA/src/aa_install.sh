#!/usr/bin/bash

##################################################################################################################
#title           :aa_install.sh                                                                                  #
#description     :The purpose of this testcase is to test that Ansible Agent                                     #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 which means that install.sh is correctly invoked and executed                                  #
#author		     :Zihao Yan                                                                                       #
#date            :20190213                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./aa_install.sh                                                                                #
#actual results  :Testcase aa_install.sh passed!                                                                 #
#expected results:Testcase aa_install.sh passed!                                                                 #
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
log_fail="AA_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed Ansible Agent"                                                               #message for a sign of successfully installing the Ansible Agent
AnsibleKey="`grep "^AnsibleKey" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default AnsibleKey
AnsibleKey_line_number=`grep -n "^AnsibleKey" $conf_path|cut -f 1 -d":"`                                         #get AnsibleKey config line number
New_AnsibleKey="ABCDEFGHabcdefgh1234567890"                                                                      #the new AnsibleKey
sed -i "${AnsibleKey_line_number}s/$AnsibleKey/$New_AnsibleKey/" $conf_path                                      #modify the Ansible Agent conf file, change default AnsibleKey
InstallPath="/usr/lib/netbrain/ansibleagent"                                                                     #the default Installation Path
Port="`grep "^Port" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Port
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
logfile="$LogPath/log/services.log"                                                                              #an important log for verification
AA_systemd="/usr/lib/systemd/system/netbrainansibleagent.service"                                                #Ansible Agent systemd file
rm -rf $log $log_fail                                                                                            #remove logs for conflict
service firewalld stop >/dev/null 2>&1                                                                           #stop firewalld service
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Ansible Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all Ansible Agent related stuffs
	exit 0
fi
sleep 5                                                                                                          #sleep 5 seconds

if [[ `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_AnsibleKey" --binary-files=without-match` ]];then                                            #if the testcase fails, generate the reasons for the failure
echo -e "The AnsibleKey $New_AnsibleKey was not encrypted in some of the files generated. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! lsof -i:$Port|grep LISTEN >/dev/null 2>&1;then                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The port $Port is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "port : $Port" $logfile;then                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The Port information was not found in $logfile. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "is ssl : False" $logfile;then                                                                      #if the testcase fails, generate the reasons for the failure
echo -e "The SSL information was not found or incorrect in $logfile. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "Go to Create gRpc" $logfile;then                                                                   #if the testcase fails, generate the reasons for the failure
echo -e "The gRpc information was not found in $logfile. This may indicate \
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

if ! grep -q "Restart=on-failure" "$AA_systemd";then                                                             #if the testcase fails, generate the reasons for the failure
echo -e "The restarting rule is not on-failure defined in Ansible Agent systemd. This may indicate \
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
&& [[ ! `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_AnsibleKey" --binary-files=without-match` ]] \
&& grep -q "Restart=on-failure" "$AA_systemd" \
&& ! sh -c "service firewalld status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& lsof -i:$Port|grep LISTEN >/dev/null 2>&1 && grep -q "port : $Port" $logfile \
&& grep -q "is ssl : False" $logfile && grep -q "Go to Create gRpc" $logfile \
&& grep -q "$msg_install" $log && [ -d $InstallPath ] && [ -d $LogPath ];then                                    #determine if Ansible Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all Ansible Agent related stuffs
