#!/usr/bin/bash

##################################################################################################################
#title           :es_install_bad_port2.sh                                                                        #
#description     :The purpose of this testcase is to test that Elasticsearch                                     #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if the Port is more than 65535.                                                                #
#author		     :Zihao Yan                                                                                       #
#date            :20190404                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./es_install_bad_port2.sh                                                                      #
#actual results  :Testcase es_install_bad_port2.sh passed!                                                       #
#expected results:Testcase es_install_bad_port2.sh passed!                                                       #
##################################################################################################################

conf_path=`ls config/setup.conf`                                                                                 #the Elasticsearch config file name
log="ES.log"                                                                                                     #installation log generated in the current directory
log_fail="ES_fail.log"                                                                                           #generate logs only if the testcase failed
Port="`grep "^Port" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Port
Port_line_number=`grep -n "^Port" $conf_path|cut -f 1 -d":"`                                                     #get Port config line number
New_Port="65536"                                                                                                 #the new Port which is more than 65535
sed -i "${Port_line_number}s/$Port/$New_Port/" $conf_path                                                        #modify the Elasticsearch conf file, change default Port
msg_error="The Port must be between 1025 and 65535. The installation aborted"                                    #message for a sign of bad port          
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh >$log 2>&1                                                                              #execute Elasticsearch installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if grep -q "$msg_error" $log;then                                                                                #determine if Elasticsearch installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo -e "The following wording information was not found in $log: $msg_error. This is the reason why \
testcase $BASH_SOURCE failed.">$log_fail                                                                         #if the testcase fails, generate the reasons for the failure
echo "Testcase $BASH_SOURCE failed!"
fi