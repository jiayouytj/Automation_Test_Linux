#!/usr/bin/bash

##################################################################################################################
#title           :aa_check_version.sh                                                                            #
#description     :The purpose of this testcase is to test that Ansible Agent                                     #
#                 installation script, and uninstallation script contain IEVersion.                              #
#author		     :Zihao Yan                                                                                       #
#date            :20190404                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./aa_check_version.sh                                                                          #
#actual results  :Testcase aa_check_version.sh passed!                                                           #
#expected results:Testcase aa_check_version.sh passed!                                                           #
##################################################################################################################

install="install.sh"                                                                                             #installation script
uninstall="others/uninstall.sh"                                                                                  #uninstallation script
IEVersion="IEVersion: 8.0.0"                                                                                     #IE version
log="AA.log"                                                                                                     #installation log generated in the current directory
log_fail="AA_fail.log"                                                                                           #generate logs only if the testcase failed
Windows="with CRLF line terminators"                                                                             #Windows format file                                          
touch $log                                                                                                       #create log
if file $install|grep -q "$Windows";then                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The $install is not Linux format. This is the reason why the testcase failed.">>$log_fail
fi

if file $uninstall|grep -q "$Windows";then                                                                       #if the testcase fails, generate the reasons for the failure
echo -e "The $uninstall is not Linux format. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$IEVersion" $install;then                                                                          #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $install: $IEVersion. \
This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$IEVersion" $uninstall;then                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $uninstall: $IEVersion. \
This is the reason why the testcase failed.">>$log_fail
fi

if grep -q "$IEVersion" $install && grep -q "$IEVersion" $uninstall \
&& ! file $install|grep -q "$Windows" && ! file $uninstall|grep -q "$Windows";then                               #determine if Ansible Agent version checking is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
