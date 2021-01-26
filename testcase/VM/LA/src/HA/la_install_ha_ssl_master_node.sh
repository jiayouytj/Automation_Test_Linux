#!/usr/bin/bash

##################################################################################################################
#title           :la_install_ha_ssl_master_node.sh                                                               #
#description     :The purpose of this testcase is to test that License Agent                                     #
#                 can be successfully installed in docker by invoking the original install.sh script, when SSL   #
#                 is enabled. The installation is on master nodes for License Agent Cluster.                     #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author          :Derek Li                                                                                       #
#date            :20190613                                                                                       #
#version         :1.0                                                                                            #
#usage           :./la_install_ha_ssl_master_node.sh                                                             #
#actual results  :Testcase la_install_ha_ssl_master_node.sh passed!                                              #
#expected results:Testcase la_install_ha_ssl_master_node.sh passed!                                              #
##################################################################################################################

input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the License Agent config file name
UseSSL="`grep "^UseSSL" $conf_path|tr "=" " "|awk '{print $2}'`"                                                 #default SSL disabled
UseSSL_line_number=`grep -n "^UseSSL" $conf_path |cut -f 1 -d":"`                                                #get SSL line number
New_UseSSL="yes"                                                                                                 #enable SSL 
sed -i "${UseSSL_line_number}s/$UseSSL/$New_UseSSL/" $conf_path                                                  #modify the License Agent conf file, enable SSL
CERT="/etc/ssl/cert.pem"                                                                                         #certificate path
KEY="/etc/ssl/key.pem"                                                                                           #certificate key path
Certificate="`grep "^Certificate" $conf_path|tr "=" " "|awk '{print $2}'`"                                       #the default Certificate
Certificate_line_number=`grep -n "^Certificate" $conf_path|cut -f 1 -d":"`                                       #get Certificate config line number
sed -i "${Certificate_line_number}s~$Certificate~$CERT~" $conf_path                                              #modify the License Agent conf file, change default Certificate
PrivateKey="`grep "^PrivateKey" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default PrivateKey
PrivateKey_line_number=`grep -n "^PrivateKey" $conf_path|cut -f 1 -d":"`                                         #get PrivateKey config line number
sed -i "${PrivateKey_line_number}s~$PrivateKey~$KEY~" $conf_path                                                 #modify the License Agent conf file, change default PrivateKey
servicename="netbrainlicense"                                                                                    #License Agent service name
log="LA.log"                                                                                                     #installation log generated in the current directory
log_fail="LA_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed License Agent"                                                               #message for a sign of successfully installing the License Agent
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute License Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all License Agent related stuffs
    exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
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
&& grep -q "$msg_install" $log && [ -d $LogPath ];then                                                           #determine if License Agent installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
