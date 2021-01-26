#!/usr/bin/bash

##################################################################################################################
#title           :mq_install_ssl_port_in_use4.sh                                                                 #
#description     :The purpose of this testcase is to test that RabbitMQ                                          #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if UseSSL=yes, and TcpPort is 15672.                                                           #
#author		     :Zihao Yan                                                                                       #
#date            :20190411                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./mq_install_ssl_port_in_use4.sh                                                               #
#actual results  :Testcase mq_install_ssl_port_in_use4.sh passed!                                                #
#expected results:Testcase mq_install_ssl_port_in_use4.sh passed!                                                #
##################################################################################################################

conf_path=`ls config/setup.conf`                                                                                 #the RabbitMQ config file name
Port="`grep "^TcpPort" $conf_path|tr "=" " "|awk '{print $2}'`"                                                  #the default TcpPort
Port_line_number=`grep -n "^TcpPort" $conf_path|cut -f 1 -d":"`                                                  #get TcpPort config line number
New_Port="15672"                                                                                                 #the new TcpPort which is 15672
sed -i "${Port_line_number}s/$Port/$New_Port/" $conf_path                                                        #modify the RabbitMQ conf file, change default TcpPort
UseSSL="`grep "^UseSSL" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #the default UseSSL
UseSSL_line_number=`grep -n "^UseSSL" $conf_path|cut -f 1 -d":"`                                                 #get UseSSL config line number
New_UseSSL="yes"                                                                                                 #the new UseSSL which is yes
sed -i "${UseSSL_line_number}s/$UseSSL/$New_UseSSL/" $conf_path                                                  #modify the RabbitMQ conf file, change default UseSSL
CERT="/etc/ssl/cert.pem"                                                                                         #certificate path
KEY="/etc/ssl/key.pem"                                                                                           #certificate key path
Certificate="`grep "^Certificate" $conf_path|tr "=" " "|awk '{print $2}'`"                                       #the default Certificate
Certificate_line_number=`grep -n "^Certificate" $conf_path|cut -f 1 -d":"`                                       #get Certificate config line number
sed -i "${Certificate_line_number}s~$Certificate~$CERT~" $conf_path                                              #modify the RabbitMQ conf file, change default Certificate
PrivateKey="`grep "^PrivateKey" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default PrivateKey
PrivateKey_line_number=`grep -n "^PrivateKey" $conf_path|cut -f 1 -d":"`                                         #get PrivateKey config line number
sed -i "${PrivateKey_line_number}s~$PrivateKey~$KEY~" $conf_path                                                 #modify the RabbitMQ conf file, change default PrivateKey
log="MQ.log"                                                                                                     #installation log generated in the current directory
log_fail="MQ_fail.log"                                                                                           #generate logs only if the testcase failed
msg_error="The port cannot be the following numbers which is reserved by RabbitMQ: 4369, 15672, 25672. \
The installation aborted"                                                                                        #message for a sign of bad port which is reserved
nc -lp $Port&                                                                                                    #occupy the port the RabbitMQ use
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
sh -c "ps -ef |grep 'nc -lp'|awk '{print $2}'|xargs kill -9 >/dev/null 2>&1"                                     #kill the process of nc