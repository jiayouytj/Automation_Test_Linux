#!/usr/bin/bash

##################################################################################################################
#title           :mq_install_ha_slave.sh                                                                         #
#description     :The purpose of this testcase is to test that RabbitMQ                                          #
#                 can be successfully installed in VM by invoking the original install.sh script.                #
#                 The installation is on slave for RabbitMQ cluster.                                             #
#                 which means that install.sh is correctly invoked and executed                                  #
#author		     :Derek Li                                                                                       #
#date            :20190613                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./mq_install_ha_slave.sh                                                                       #
#actual results  :Testcase mq_install_ha_slave.sh passed!                                                        #
#expected results:Testcase mq_install_ha_slave.sh passed!                                                        #
##################################################################################################################

##################################################################################################################
# The following function is for cleaning up before and after installation                                        #
##################################################################################################################
conf_path=`ls config/setup.conf`                                                                                 #the RabbitMQ config file name
Password="`grep "^Password" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default Password
Password_line_number=`grep -n "^Password" $conf_path|cut -f 1 -d":"`                                             #get Password config line number
New_Password="ABCDEFGHI0123456789"                                                                               #the new Password
sed -i "${Password_line_number}s/$Password/$New_Password/" $conf_path                                            #modify the RabbitMQ conf file, change default Password
Mode="`grep "^Mode" $conf_path|tr "=" " "|awk '{print $2}'`"                                                     #the default Mode
Mode_line_number=`grep -n "^Mode" $conf_path|cut -f 1 -d":"`                                                     #get Mode config line number
New_Mode="mirror"                                                                                                #the new Mode which is mirror
sed -i "${Mode_line_number}s/$Mode/$New_Mode/" $conf_path                                                        #modify the RabbitMQ conf file, change default Mode
NodeRole="`grep "^NodeRole" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default NodeRole
NodeRole_line_number=`grep -n "^NodeRole" $conf_path|cut -f 1 -d":"`                                             #get NodeRole config line number
New_NodeRole="slave"                                                                                             #the new NodeRole which is slave
sed -i "${NodeRole_line_number}s/$NodeRole/$New_NodeRole/" $conf_path                                            #modify the RabbitMQ conf file, change default NodeRole
MasterNode="`grep "^MasterNode" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default MasterNode
MasterNode_line_number=`grep -n "^MasterNode" $conf_path|cut -f 1 -d":"`                                         #get MasterNode config line number
New_MasterNode="derek1"                                                                                          #the new MasterNode which is the hostname if Master Node
sed -i "${MasterNode_line_number}s/$MasterNode/$New_MasterNode/" $conf_path                                      #modify the RabbitMQ conf file, change default MasterNode
InstallPath="/usr/lib/rabbitmq"                                                                                  #the Installation Path
ConfigPath="/etc/rabbitmq"                                                                                       #the config Path
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
ErlangPath="/usr/lib64/erlang"                                                                                   #Erlang Path
servicename="rabbitmq-server"                                                                                    #RabbitMQ service name
log="MQ.log"                                                                                                     #installation log generated in the current directory
log_fail="MQ_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed RabbitMQ"                                                                    #message for a sign of successfully installing the RabbitMQ
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh >$log 2>&1                                                                              #execute RabbitMQ installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all RabbitMQ related stuffs
	exit 0
fi

if [[ `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_Password" --binary-files=without-match` ]];then                                              #if the testcase fails, generate the reasons for the failure
echo -e "The Password $New_Password was not encrypted in some of the files generated. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $InstallPath ];then                                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The Installation Path $InstallPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $ConfigPath ];then                                                                                     #if the testcase fails, generate the reasons for the failure
echo -e "The Config Path $ConfigPath was not created. This may indicate \
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
&& [[ ! `find /var /etc /usr /home -mmin -$(expr $SECONDS / 60 + 1)|\
xargs grep -s "$New_Password" --binary-files=without-match` ]] \
&& grep -q "$msg_install" $log && [ -d $InstallPath ] && [ -d $ConfigPath ] && [ -d $LogPath ];then              #determine if RabbitMQ installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
