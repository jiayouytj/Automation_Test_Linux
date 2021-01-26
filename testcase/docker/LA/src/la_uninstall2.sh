#!/usr/bin/bash

##################################################################################################################
#title           :la_uninstall2.sh                                                                               #
#description     :The purpose of this testcase is to test that License Agent                                     #
#                 can be successfully uninstalled in docker by invoking the original uninstall.sh script in      #
#                 others directory after unzipping the installation package,                                     #
#                 which means that uninstall.sh is correctly invoked and executed                                #
#author		     :Zihao Yan                                                                                       #
#date            :20190329                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./la_uninstall2.sh                                                                             #
#actual results  :Testcase la_uninstall2.sh passed!                                                              #
#expected results:Testcase la_uninstall2.sh passed!                                                              #
##################################################################################################################

input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
conf_path=`ls config/setup.conf`                                                                                 #the License Agent config file name
servicename="netbrainlicense"                                                                                    #License Agent service name
log="LA.log"                                                                                                     #installation log generated in the current directory
log2="LA_uninstall.log"                                                                                          #uninstallation log generated in the current directory
log_fail="LA_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed License Agent"                                                               #message for a sign of successfully installing the License Agent
msg_uninstall="NetBrain License Agent has been successfully uninstalled"                                         #message for a sign of successfully uninstalling the License Agent
msg_bad="Failed to install"                                                                                      #message for a sign of failing to install the dependencies
LogPath="`grep "^LogPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                               #the default LogPath
service="/usr/lib/systemd/system/$servicename.service"                                                           #License Agent systemd service file
rm -rf $log $log2 $log_fail                                                                                      #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute License Agent installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
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
timeout 600 echo "yes"|./others/uninstall.sh >$log2 2>&1                                                         #execute License Agent uninstallation script and save the log    
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cat $log2 >>$log                                                                                             #merge two logs
    exit 0
fi
	if ! grep -q "$msg_uninstall" $log2;then                                                                     #if the testcase fails, generate the reasons for the failure
    echo -e "The following wording information was not found in $log2: $msg_uninstall. This may indicate \
    that the uninstallation was not successful. This is the reason why the testcase failed.">>$log_fail
    fi


    if [ -d $LogPath ];then                                                                                      #if the testcase fails, generate the reasons for the failure
    echo -e "The Log Path $LogPath still existed after uninstallation, which is not an expected behavior. \
	This may indicate that the uninstallation was not successful. \
	This is the reason why the testcase failed.">>$log_fail
    fi
	
	if [ -f $service ];then                                                                                      #if the testcase fails, generate the reasons for the failure
    echo -e "The systemd service $service still existed after uninstallation, which is not an expected behavior. \
	This may indicate that the uninstallation was not successful. \
	This is the reason why the testcase failed.">>$log_fail
    fi
	
	if grep -q "$msg_uninstall" $log2 && [ ! -d $LogPath ] && [ ! -f $service ];then                             #determine if License Agent uninstallation is successfully completed
    echo "Testcase $BASH_SOURCE passed!"
	else
	echo "Testcase $BASH_SOURCE failed!"
	fi
else
echo "Testcase $BASH_SOURCE failed!"
fi

if [ -f $log2 ];then
cat $log2 >>$log                                                                                                 #merge two logs
fi








