#!/usr/bin/bash

##################################################################################################################
#title           :aa_install_reboot2.sh                                                                          #
#description     :The purpose of this testcase is to test that Ansible Agent                                     #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 and after rebooting the system, the ansible agent service is still running, the port is still  #
#                 listening, which means that install.sh is correctly invoked and executed.                      #
#author		     :Zihao Yan                                                                                       #
#date            :20190213                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./aa_install_reboot2.sh                                                                        #
#actual results  :Testcase aa_install_reboot2.sh passed!                                                         #
#expected results:Testcase aa_install_reboot2.sh passed!                                                         #
##################################################################################################################

cleanup()
{
echo "y"|$UninstallPath/uninstall.sh >/dev/null 2>&1                                                             #uninstall Ansible Agent using uninstall.sh
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall Ansible Agent using uninstall.sh
rpm -qa|grep -E "^netbrainansibleagent"|xargs rpm -e >/dev/null 2>&1                                             #uninstall all Ansible Agent related rpms if they have been installed
}
conf_path=`ls config/setup.conf`                                                                                 #the Ansible Agent config file name
servicename="netbrainansibleagent"                                                                               #Ansible Agent service name
log="AA.log"                                                                                                     #installation log generated in the current directory
log_fail="AA_fail.log"                                                                                           #generate logs only if the testcase failed
Port="`grep "^Port" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Port
rm -rf $log $log_fail                                                                                            #remove logs for conflict
touch $log                                                                                                       #create the log file

if ! lsof -i:$Port|grep LISTEN >/dev/null 2>&1;then                                                              #if the testcase fails, generate the reasons for the failure
echo -e "The port $Port is not listening. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1;then                       #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename service is not in running state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& lsof -i:$Port|grep LISTEN >/dev/null 2>&1;then                                                                #determine if Ansible Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all Ansible Agent related stuffs
