#!/usr/bin/bash

##################################################################################################################
#title           :db_check_version.sh                                                                            #
#description     :The purpose of this testcase is to test that MongoDB                                           #
#                 installation script, upgrade script, and uninstallation script contain Version and IEVersion.  #
#author		     :Zihao Yan                                                                                       #
#date            :20190404                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./db_check_version.sh                                                                          #
#actual results  :Testcase db_check_version.sh passed!                                                           #
#expected results:Testcase db_check_version.sh passed!                                                           #
##################################################################################################################

install="install.sh"                                                                                             #installation script
upgrade="upgrade/upgrade_single_node/upgrade.sh"                                                                 #upgrade script for single node
uninstall="others/uninstall.sh"                                                                                  #uninstallation script
Version="Version: 4.0.6"                                                                                         #MongoDB version
IEVersion="IEVersion: 8.0.0"                                                                                     #IE version
log="DB.log"                                                                                                     #installation log generated in the current directory
log_fail="DB_fail.log"                                                                                           #generate logs only if the testcase failed
Windows="with CRLF line terminators"                                                                             #Windows format file                                          
touch $log                                                                                                       #create log
if file $install|grep -q "$Windows";then                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The $install is not Linux format. This is the reason why the testcase failed.">>$log_fail
fi

if file $uninstall|grep -q "$Windows";then                                                                       #if the testcase fails, generate the reasons for the failure
echo -e "The $uninstall is not Linux format. This is the reason why the testcase failed.">>$log_fail
fi

if file $upgrade|grep -q "$Windows";then                                                                         #if the testcase fails, generate the reasons for the failure
echo -e "The $upgrade is not Linux format. This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$Version" $install;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $install: $Version. \
This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$IEVersion" $install;then                                                                          #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $install: $IEVersion. \
This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$Version" $upgrade;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $upgrade: $Version. \
This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$IEVersion" $upgrade;then                                                                          #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $upgrade: $IEVersion. \
This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$Version" $uninstall;then                                                                          #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $uninstall: $Version. \
This is the reason why the testcase failed.">>$log_fail
fi

if ! grep -q "$IEVersion" $uninstall;then                                                                        #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was not found in $uninstall: $IEVersion. \
This is the reason why the testcase failed.">>$log_fail
fi

if grep -q "$Version" $install && grep -q "$IEVersion" $install && grep -q "$Version" $upgrade \
&& grep -q "$IEVersion" $upgrade && grep -q "$Version" $uninstall && grep -q "$IEVersion" $uninstall \
&& ! file $install|grep -q "$Windows" && ! file $uninstall|grep -q "$Windows" \
&& ! file $upgrade|grep -q "$Windows";then                                                                      #determine if MongoDB version checking is successfully completed#determine if MongoDB version checking is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo "Testcase $BASH_SOURCE failed!"
fi
