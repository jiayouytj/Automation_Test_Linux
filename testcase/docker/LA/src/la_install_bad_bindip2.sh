#!/usr/bin/bash

##################################################################################################################
#title           :aa_install_bad_bindip2.sh                                                                      #
#description     :The purpose of this testcase is to test that License Agent                                     #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if the BindIp is 192.168.137.111.                                                              #
#author		     :Zihao Yan                                                                                       #
#date            :20190329                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./aa_install_bad_bindip2.sh                                                                    #
#actual results  :Testcase aa_install_bad_bindip2.sh passed!                                                     #
#expected results:Testcase aa_install_bad_bindip2.sh passed!                                                     #
##################################################################################################################

input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the License Agent config file name
log="LA.log"                                                                                                     #installation log generated in the current directory
log_fail="LA_fail.log"                                                                                           #generate logs only if the testcase failed
BindIp="`grep "^BindIp" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #the default BindIp
BindIp_line_number=`grep -n "^BindIp" $conf_path|cut -f 1 -d":"`                                                 #get BindIp config line number
New_BindIp="192.168.137.111"                                                                                     #the new BindIp which is 192.168.137.111
sed -i "${BindIp_line_number}s/$BindIp/$New_BindIp/" $conf_path                                                  #modify the License Agent conf file, change default BindIp
msg_error="Please fill out the actual IP address in ./config/setup.conf"                                         #message for a sign of bad BindIp          
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute License Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if grep -q "$msg_error" $log;then                                                                                #determine if License Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo -e "The following wording information was not found in $log: $msg_error. This is the reason why \
testcase $BASH_SOURCE failed.">$log_fail                                                                         #if the testcase fails, generate the reasons for the failure
echo "Testcase $BASH_SOURCE failed!"
fi