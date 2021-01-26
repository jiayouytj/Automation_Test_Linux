#!/usr/bin/bash

##################################################################################################################
#title           :mq_install_bad_clusterid3.sh                                                                   #
#description     :The purpose of this testcase is to test that RabbitMQ                                          #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if Mode is mirror, and ClusterId is missing.                                                   #
#author		     :Zihao Yan                                                                                       #
#date            :20190218                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./mq_install_bad_clusterid3.sh                                                                 #
#actual results  :Testcase mq_install_bad_clusterid3.sh passed!                                                  #
#expected results:Testcase mq_install_bad_clusterid3.sh passed!                                                  #
##################################################################################################################

conf_path=`ls config/setup.conf`                                                                                 #the RabbitMQ config file name
Mode="`grep "^Mode" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Mode
Mode_line_number=`grep -n "^Mode" $conf_path|cut -f 1 -d":"`                                                     #get Mode config line number
New_Mode="mirror"                                                                                                #the new Mode which is mirror
sed -i "${Mode_line_number}s/$Mode/$New_Mode/" $conf_path                                                        #modify the RabbitMQ conf file, change default Mode
sed -i '/^ClusterId/d' $conf_path                                                                                #delete the line containing ClusterId
log="MQ.log"                                                                                                     #installation log generated in the current directory
log_fail="MQ_fail.log"                                                                                           #generate logs only if the testcase failed
msg_error="ClusterId is empty. The installation aborted"                                                         #message for a sign of bad ClusterId which is a space
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh >$log 2>&1                                                                              #execute RabbitMQ installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if grep -q "$msg_error" $log;then                                                                                #determine if RabbitMQ installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo -e "The following wording information was not found in $log: $msg_error. This is the reason why \
testcase $BASH_SOURCE failed.">$log_fail                                                                         #if the testcase fails, generate the reasons for the failure
echo "Testcase $BASH_SOURCE failed!"
fi
