#!/usr/bin/bash

##################################################################################################################
#title           :fs_install_again.sh                                                                            #
#description     :The purpose of this testcase is to test that Front Server                                      #
#                 can NOT be successfully installed in docker if it has been already installed,                  #
#author		     :Zihao Yan                                                                                       #
#date            :20190409                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./fs_install_again.sh                                                                          #
#actual results  :Testcase fs_install_again.sh passed!                                                           #
#expected results:Testcase fs_install_again.sh passed!                                                           #
##################################################################################################################

input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
servicename="netbrainfrontserver"                                                                                #Front Server service name
log="FS.log"                                                                                                     #installation log generated in the current directory
log2="FS_installed.log"                                                                                          #installation log if installing Front Server again
log_fail="FS_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed Front Server"                                                                #message for a sign of successfully installing the Front Server
msg_again="Front Server has already been installed on this machine. The installation aborted"                    #message for a sign of Front Server already installed
msg_installed="If you believe that Front Server has not been installed, \
please uninstall the service netbrainfrontserver"                                                                #message for a sign of Front Server already installed
InstallPath="/usr/lib/netbrain/frontserver"                                                                      #the default Installation Path
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Front Server installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $log: $msg_install. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $InstallPath ];then                                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The Installation Path $InstallPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $servicename status |grep dead >/dev/null 2>&1">/dev/null 2>&1;then                          #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename service is not in dead state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep dead >/dev/null 2>&1">/dev/null 2>&1 \
&& grep -q "$msg_install" $log && [ -d $InstallPath ];then                                                       #determine if Front Server installation is successfully completed
timeout 600 ./install.sh <$input >$log2 2>&1                                                                     #execute Front Server installation script again and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cat $log2 >>$log                                                                                             #merge two logs
    exit 0
fi     
   if ! grep -q "$msg_again" $log2;then                                                                          #if the testcase fails, generate the reasons for the failure
   echo -e "The following wording information was not found in $log2: $msg_again. \
   This is the reason why the testcase failed.">>$log_fail
   fi
   
   if ! grep -q "$msg_installed" $log2;then                                                                      #if the testcase fails, generate the reasons for the failure
   echo -e "The following wording information was not found in $log2: $msg_installed. \
   This is the reason why the testcase failed.">>$log_fail
   fi
   
   if grep -q "$msg_again" $log2 && grep -q "$msg_installed" $log2;then                                          #determine if Front Server installation is successfully completed
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