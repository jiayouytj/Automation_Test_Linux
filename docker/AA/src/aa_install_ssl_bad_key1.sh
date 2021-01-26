#!/usr/bin/bash

##################################################################################################################
#title           :aa_install_ssl_bad_key1.sh                                                                     #
#description     :The purpose of this testcase is to test that Ansible Agent                                     #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if UseSSL=yes, but PrivateKey is empty.                                                        #
#author		     :Zihao Yan                                                                                       #
#date            :20190306                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./aa_install_ssl_bad_key1.sh                                                                   #
#actual results  :Testcase aa_install_ssl_bad_key1.sh passed!                                                    #
#expected results:Testcase aa_install_ssl_bad_key1.sh passed!                                                    #
##################################################################################################################

input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the Ansible Agent config file name
UseSSL="`grep "^UseSSL" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #the default UseSSL
UseSSL_line_number=`grep -n "^UseSSL" $conf_path|cut -f 1 -d":"`                                                 #get UseSSL config line number
New_UseSSL="yes"                                                                                                 #the new UseSSL which is yes
sed -i "${UseSSL_line_number}s/$UseSSL/$New_UseSSL/" $conf_path                                                  #modify the Ansible Agent conf file, change default UseSSL
CERT="/etc/ssl/cert.pem"                                                                                         #certificate path
Certificate="`grep "^Certificate" $conf_path|tr "=" " "|awk '{print $2}'`"                                       #the default Certificate
Certificate_line_number=`grep -n "^Certificate" $conf_path|cut -f 1 -d":"`                                       #get Certificate config line number
sed -i "${Certificate_line_number}s~$Certificate~$CERT~" $conf_path                                              #modify the MongoDB conf file, change default Certificate
PrivateKey="`grep "^PrivateKey" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default PrivateKey
PrivateKey_line_number=`grep -n "^PrivateKey" $conf_path|cut -f 1 -d":"`                                         #get PrivateKey config line number
New_PrivateKey=""                                                                                                #the new PrivateKey which is empty
sed -i "${PrivateKey_line_number}s~$PrivateKey~$New_PrivateKey~" $conf_path                                      #modify the Ansible Agent conf file, change default PrivateKey
log="AA.log"                                                                                                     #installation log generated in the current directory
log_fail="AA_fail.log"                                                                                           #generate logs only if the testcase failed
msg_error="The certificate key file parameter is empty. The installation aborted"                                #message for a sign of bad PrivateKey
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Ansible Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if grep -q "$msg_error" $log;then                                                                                #determine if Ansible Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo -e "The following wording information was not found in $log: $msg_error. This is the reason why \
testcase $BASH_SOURCE failed.">$log_fail                                                                         #if the testcase fails, generate the reasons for the failure
echo "Testcase $BASH_SOURCE failed!"
fi
