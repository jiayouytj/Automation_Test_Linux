#!/usr/bin/bash

##################################################################################################################
#title           :sm_install_bad_ca_verify5.sh                                                                   #
#description     :The purpose of this testcase is to test that Service Monitor Agent                             #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if the CA_Verify is not yes or no.                                                             #
#author		     :Zihao Yan                                                                                       #
#date            :20190319                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./sm_install_bad_ca_verify5.sh                                                                 #
#actual results  :Testcase sm_install_bad_ca_verify5.sh passed!                                                  #
#expected results:Testcase sm_install_bad_ca_verify5.sh passed!                                                  #
##################################################################################################################

input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the Service Monitor Agent config file name
log="SM.log"                                                                                                     #installation log generated in the current directory
log_fail="SM_fail.log"                                                                                           #generate logs only if the testcase failed
Server_Url="`grep "^Server_Url" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default Server_Url
Server_Url_line_number=`grep -n "^Server_Url" $conf_path|cut -f 1 -d":"`                                         #get Server_Url config line number
New_Server_Url="http://ite.netbrain.com/ServerAPI"                                                               #the new Server_Url which is a valid value
sed -i "${Server_Url_line_number}s~$Server_Url~$New_Server_Url~" $conf_path                                      #modify the Service Monitor conf file, change default Server_Key
CA_Verify="`grep "^CA_Verify" $conf_path|tr "=" " "|awk '{print $2}'`"                                           #the default CA_Verify
CA_Verify_line_number=`grep -n "^CA_Verify" $conf_path|cut -f 1 -d":"`                                           #get CA_Verify config line number
New_CA_Verify="1234567890"                                                                                       #the new CA_Verify which is not yes or no
sed -i "${CA_Verify_line_number}s/$CA_Verify/$New_CA_Verify/" $conf_path                                         #modify the Service Monitor Agent conf file, change default CA_Verify
msg_error="The CA_Verify parameter is invalid, it can be only 'yes' or 'no'. The installation aborted"           #message for a sign of bad CA_Verify which is not yes or no
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Service Monitor Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if grep -q "$msg_error" $log;then                                                                                #determine if Service Monitor Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo -e "The following wording information was not found in $log: $msg_error. This is the reason why \
testcase $BASH_SOURCE failed.">$log_fail                                                                         #if the testcase fails, generate the reasons for the failure
echo "Testcase $BASH_SOURCE failed!"
fi
