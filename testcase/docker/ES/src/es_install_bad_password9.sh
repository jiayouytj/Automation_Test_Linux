#!/usr/bin/bash

##################################################################################################################
#title           :es_install_bad_password9.sh                                                                    #
#description     :The purpose of this testcase is to test that Elasticsearch                                     #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if the Password starts with !.                                                                 #
#author		     :Zihao Yan                                                                                       #
#date            :20190305                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./es_install_bad_password9.sh                                                                  #
#actual results  :Testcase es_install_bad_password9.sh passed!                                                   #
#expected results:Testcase es_install_bad_password9.sh passed!                                                   #
##################################################################################################################

conf_path=`ls config/setup.conf`                                                                                 #the Elasticsearch config file name
Password="`grep "^Password" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default Password
Password_line_number=`grep -n "^Password" $conf_path|cut -f 1 -d":"`                                             #get Password config line number
New_Password="!admin"                                                                                            #the new Password which starts with !
sed -i "${Password_line_number}s/$Password/$New_Password/" $conf_path                                            #modify the Elasticsearch conf file, change default password
MemoryLimit="`grep "^MemoryLimit" $conf_path|tr "=" " "|awk '{print $2}'`"                                       #the default MemoryLimit
MemoryLimit_line_number=`grep -n "^MemoryLimit" $conf_path|cut -f 1 -d":"`                                       #get MemoryLimit config line number
New_MemoryLimit="1%"                                                                                             #the new MemoryLimit which is 1%
sed -i "${MemoryLimit_line_number}s/$MemoryLimit/$New_MemoryLimit/" $conf_path                                   #modify the Elasticsearch conf file, change default MemoryLimit
log="ES.log"                                                                                                     #installation log generated in the current directory
log_fail="ES_fail.log"                                                                                           #generate logs only if the testcase failed
msg_error="The first character of Password cannot be ! or #"                                                     #message for a sign of bad Password which contains invalid characters
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
