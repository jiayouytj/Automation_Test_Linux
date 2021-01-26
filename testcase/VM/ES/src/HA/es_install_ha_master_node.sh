#!/usr/bin/bash

##################################################################################################################
#title           :es_install_ha_master_node.sh                                                                   #
#description     :The purpose of this testcase is to test that Elasticsearch                                     #
#                 can be successfully installed in docker by invoking the original install.sh script,            #
#                 The installation is on the master node for Elasticsearch cluster,                              #
#                 which means that install.sh is correctly invoked and executed.                                 #
#author		     :Derek Li                                                                                       #
#date            :20190613                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./es_install_ha_master_node.sh                                                                 #
#actual results  :Testcase es_install_ha_master_node.sh passed!                                                  #
#expected results:Testcase es_install_ha_master_node.sh passed!                                                  #
##################################################################################################################

conf_path=`ls config/setup.conf`                                                                                 #the Elasticsearch config file name
Password="`grep "^Password" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default Password
Password_line_number=`grep -n "^Password" $conf_path|cut -f 1 -d":"`                                             #get Password config line number
New_Password="ABCDEFGHI0123456789"                                                                               #the new Password
sed -i "${Password_line_number}s/$Password/$New_Password/" $conf_path                                            #modify the Elasticsearch conf file, change default Password
servicename="elasticsearch"                                                                                      #Elasticsearch service name
log="ES.log"                                                                                                     #installation log generated in the current directory
log_fail="ES_fail.log"                                                                                           #generate logs only if the testcase failed
SingleNode="`grep "^SingleNode" $conf_path|tr "=" " "|awk '{print $2}'`"                                         #the default SingleNode
SingleNode_line_number=`grep -n "^SingleNode" $conf_path|cut -f 1 -d":"`                                         #get SingleNode config line number
New_SingleNode="no"                                                                                              #the new SingleNode which is no
sed -i "${SingleNode_line_number}s/$SingleNode/$New_SingleNode/" $conf_path                                      #modify the Elasticsearch conf file, change default SingleNode
ClusterMembers="`grep "^ClusterMembers" $conf_path|tr "=" " "|awk '{print $2}'`"                                 #default ClusterMembers
ClusterMembers_line_number=`grep -n "^ClusterMembers" $conf_path|cut -f 1 -d":"`                                 #get ClusterMembers config line number
New_ClusterMembers="192.168.30.187,192.168.30.188,192.168.30.189"                                                #the new ClusterMembers which is 192.168.30.187,192.168.30.188,192.168.30.189
sed -i "${ClusterMembers_line_number}s/$ClusterMembers/$New_ClusterMembers/" $conf_path                          #modify the Elasticsearch conf file, change default ClusterMembers
msg_install='Successfully installed Elasticsearch'                                                               #message for a sign of successfully installing the elasticsearch
msg_init='initialized the username and password in the Elasticsearch'                                            #message for a sign of successfully initializing the username and password in the elasticsearch
msg_connect='connected to the Elasticsearch'                                                                     #message for a sign of successfully connecting to the elasticsearch
msg_execution='The setup is complete'                                                                            #message for a sign of successfully completing the installation
InstallPath="/usr/share/elasticsearch"                                                                           #the default InstallPath
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #the default DataPath
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh >$log 2>&1                                                                              #execute Elasticsearch installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cleanup                                                                                                      #invoke cleanup funtion to purge all Elasticsearch related stuffs
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

if ! grep -q "$msg_init" $log;then                                                                               #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_init. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_connect" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_connect. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$msg_execution" $log;then                                                                          #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_execution. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $InstallPath ];then                                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The Installation Path $InstallPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $DataPath ];then                                                                                       #if the testcase fails, generate the reasons for the failure
echo -e "The Data Path $DataPath was not created. This may indicate \
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
&& grep -q "$msg_install" $log && grep -q "$msg_init" $log && grep -q "$msg_connect" $log \
&& grep -q "$msg_execution" $log && [ -d $DataPath ] && [ -d $LogPath ] && [ -d $InstallPath ];then              #determine if Elasticsearch installation is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
