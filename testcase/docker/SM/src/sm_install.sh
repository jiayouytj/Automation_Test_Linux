#!/usr/bin/bash

##################################################################################################################
#title           :sm_install.sh                                                                                  #
#description     :The purpose of this testcase is to test that Service Monitor Agent                             #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author		     :Zihao Yan                                                                                       #
#date            :20190319                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./sm_install.sh                                                                                #
#actual results  :Testcase sm_install.sh passed!                                                                 #
#expected results:Testcase sm_install.sh passed!                                                                 #
##################################################################################################################

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
rm -rf $log $log_fail                                                                                            #remove logs for conflict
service firewalld stop >/dev/null 2>&1                                                                           #stop firewalld service
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Service Monitor Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
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

if ! sh -c "service firewalld status |grep dead >/dev/null 2>&1">/dev/null 2>&1;then                             #if the testcase fails, generate the reasons for the failure
echo -e "The firewalld service is not in dead state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep running >/dev/null 2>&1">/dev/null 2>&1 \
&& sh -c "service firewalld status |grep dead >/dev/null 2>&1">/dev/null 2>&1 \
&& grep -q "$msg_install" $log && [ -d $InstallPath ] && [ -d $LogPath ];then                                    #determine if Service Monitor Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
