#!/usr/bin/bash

##################################################################################################################
#title           :re_install_again.sh                                                                            #
#description     :The purpose of this testcase is to test that Redis                                             #
#                 can NOT be successfully installed in docker if it has been already installed,                  #
#author		     :Zihao Yan                                                                                       #
#date            :20190303                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./re_install_again.sh                                                                          #
#actual results  :Testcase re_install_again.sh passed!                                                           #
#expected results:Testcase re_install_again.sh passed!                                                           #
##################################################################################################################

conf_path=`ls config/setup.conf`                                                                                 #the Redis config file name
Port="`grep "^Port" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Port
servicename="redis"                                                                                              #Redis service name
log="RE.log"                                                                                                     #installation log generated in the current directory
log2="RE_installed.log"                                                                                          #installation log if installing Redis again
log_fail="RE_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed Redis"                                                                       #message for a sign of successfully installing the Redis
msg_again="Redis has already been installed on this machine. The installation aborted"                           #message for a sign of Redis already installed
msg_installed="If you believe that Redis has not been installed, \
please uninstall the rpm package redis"                                                                          #message for a sign of Redis already installed
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh >$log 2>&1                                                                              #execute Redis installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
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

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& grep -q "$msg_install" $log && [ -d $DataPath ] && [ -d $LogPath ];then                                       #determine if Redis installation is successfully completed
timeout 600 ./install.sh >$log2 2>&1                                                                             #execute Redis installation script again and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cat $log2 >>$log                                                                                             #merge two logs
    exit 0
fi     
   if ! grep -q "$msg_again" $log2;then                                                                          #if the testcase fails, generate the reasons for the failure
   echo -e "The following wording information was not found in $log2: $msg_again. \
   This is the reason why the testcase failed.">>$log_fail
   fi
   
   if ! grep -q "$msg_installed" $log2;then                                                                      #if the testcase fails, generate the reasons for the failure
   echo -e "The following wording information was not found in $log2: $msg_installed. \
   This is the reason why the testcase failed.">>$log_fail
   fi
   
   if grep -q "$msg_again" $log2 && grep -q "$msg_installed" $log2;then                                          #determine if Redis installation is successfully completed
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