#!/usr/bin/bash

##################################################################################################################
#title           :mq_install_bad_cpu_limit4.sh                                                                   #
#description     :The purpose of this testcase is to test that RabbitMQ                                          #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if CPULimit is a negative percentage number.                                                   #
#author		     :Zihao Yan                                                                                       #
#date            :20190225                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./mq_install_bad_cpu_limit4.sh                                                                 #
#actual results  :Testcase mq_install_bad_cpu_limit4.sh passed!                                                  #
#expected results:Testcase mq_install_bad_cpu_limit4.sh passed!                                                  #
##################################################################################################################

conf_path=`ls config/setup.conf`                                                                                 #the RabbitMQ config file name
ResourceLimit="`grep "^ResourceLimit" $conf_path|tr "=" " "|awk '{print $2}'`"                                   #the default ResourceLimit
ResourceLimit_line_number=`grep -n "^ResourceLimit" $conf_path|cut -f 1 -d":"`                                   #get ResourceLimit config line number
New_ResourceLimit="yes"                                                                                          #the new ResourceLimit which yes
sed -i "${ResourceLimit_line_number}s/$ResourceLimit/$New_ResourceLimit/" $conf_path                             #modify the Redis conf file, change default ResourceLimit
CPULimit="`grep "^CPULimit" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default CPULimit
CPULimit_line_number=`grep -n "^CPULimit" $conf_path|cut -f 1 -d":"`                                             #get CPULimit config line number
New_CPULimit="-10%"                                                                                              #the new CPULimit which is a negative percentage number
sed -i "${CPULimit_line_number}s/$CPULimit/$New_CPULimit/" $conf_path                                            #modify the RabbitMQ conf file, change default CPULimit
log="MQ.log"                                                                                                     #installation log generated in the current directory
log_fail="MQ_fail.log"                                                                                           #generate logs only if the testcase failed
msg_error="Current component’s CPU limitation value ($New_CPULimit) is not a valid value \[range(1%-100%)\]. \
The installation aborted"                                                                                        #message for a sign of bad CPULimit
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
