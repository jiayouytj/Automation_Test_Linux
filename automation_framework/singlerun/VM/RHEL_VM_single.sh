#!/usr/bin/bash

#################################################################################################################
#title           :RHEL_VM_single.sh                                                                             #
#description     :This script will kick of a single testrun of NetBrain Linux Component under RHEL VM           #
#author		     :Zihao Yan                                                                                      #
#date            :20190223                                                                                      #
#version         :1.0                                                                                           #
#usage		     :./RHEL_VM_single.sh [es|la|db|sm|mq|re|fs|aa|all]_*.sh                                        #
#details         :es: Elasticsearch la: License Agent db: MongoDB sm: Service Monitor Agent                     #
#                 mq: RabbitMQ re: Redis fs: Front Server aa: Ansible Agent all: ALL-LINUX                      #
#notes           :Install git.                                                                                  #
#################################################################################################################

#################################################################################################################
# This shell script is for Netbrain internal only                                                               #
#################################################################################################################    
	
	
#################################################################################################################
# Usage: RHEL_VM_single.sh [es|la|db|sm|mq|re|te|fs|aa|all]_*.sh. the first parameter must be a .sh             #
# file with the name beginning with either es, la, db, sm, mq, re, te, fs, aa, and all lowercase                #
# Usage example: 1: ./RHEL_VM_single.sh db_install.sh                                                           #
#                2: ./RHEL_VM_single.sh es_install.sh                                                           #
#                3: ./RHEL_VM_single.sh la_install.sh                                                           #
#                4: ./RHEL_VM_single.sh sm_install.sh                                                           #
#                5: ./RHEL_VM_single.sh mq_install.sh                                                           #
#                6: ./RHEL_VM_single.sh re_install.sh                                                           #
#                7: ./RHEL_VM_single.sh fs_install.sh                                                           #
#                8: ./RHEL_VM_single.sh aa_install.sh                                                           #
#                9: ./RHEL_VM_single.sh all_install.sh                                                          #
#################################################################################################################	

#################################################################################################################
# The following function is for running a testcase in VM                                                        #
#################################################################################################################

mount -t cifs //192.168.33.101/US_Package  /mnt -o username=admin,password=NB@Dev101 >/dev/null 2>&1             #mount installation package
ls /mnt >/dev/null 2>&1                                                                                          #list /mnt to pretend resource unavailable
release=`cat /etc/redhat-release`                                                                                #RHEL release version
summary="testrun.summary"                                                                                        #testrun summary file
results="results"                                                                                                #the location of testcase results in the host
CentOS75=`cat /etc/redhat-release|grep "CentOS"|grep "7.5"`                                                      #CentOS 7.5 release version
CentOS76=`cat /etc/redhat-release|grep "CentOS"|grep "7.6"`                                                      #CentOS 7.6 release version
RedHat75=`cat /etc/redhat-release|grep "Red Hat"|grep "7.5"`                                                     #Red Hat 7.5 release version
RedHat76=`cat /etc/redhat-release|grep "Red Hat"|grep "7.6"`                                                     #Red Hat 7.6 release version
case $release in $CentOS75)
OS_Version="CentOS7.5"
  ;;
  
$CentOS76)
OS_Version="CentOS7.6"
  ;;
  
$RedHat75)
OS_Version="RedHat7.5"
  ;;
  
$RedHat76)
OS_Version="RedHat7.6"
  ;;  
*)
  echo "Unsupported OS version. The testrun aborted."
  exit 1 
esac   
testcase_DIR="`pwd`/testcase"                                                                                    #the testcase directory pulled from GitHub
cert_DIR="`pwd`/certificate"                                                                                     #the certificate directory pulled from GitHub
package_DIR="`pwd`/package"                                                                                      #the installation package directory from 192.168.33.101
certificate_DIR="/etc/ssl"                                                                                       #the location of certificate directory
installation_DIR="/opt/temp/$version"                                                                            #the location of installation directory
result=test_result_$OS_Version.list                                                                              #test result file name  
cert='cert.pem'                                                                                                  #certificate
key='key.pem'                                                                                                    #private key    
ca='ca.pem'                                                                                                      #CA
version=8.0_stable                                                                                               #The package version
Installation_Package="/mnt/$version/`ls /mnt/$version|tail -1`/DEV"                                              #The installation package location on the server 192.168.33.101
run_testcase()
{
  sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                    #release cache/buffer
  testcase=`find $testcase_DIR/VM -name $file`                                                                  #get testcase name  
  cp $package_DIR/$package_name $installation_DIR                                                               #copy the installation package to installation directory
  cp $cert_DIR/$cert $certificate_DIR                                                                           #copy the certificate to the certificate directory 
  cp $cert_DIR/$key $certificate_DIR                                                                            #copy the private key to the certificate directory 
  cp $cert_DIR/$ca $certificate_DIR                                                                             #copy the CA to the certificate directory 
  tar -xf $installation_DIR/$package_name -C $installation_DIR >/dev/null 2>&1                                  #execute the installation package extraction
  if [[ `basename $package` == "netbrain-all-in-two-linux-8.0" ]];then                                          #determine if the package is netbrain-all-in-two-linux-8.0
  sed -i 's/rabbitmq_status_reset $/#&/g' $package/rabbitmq/others/uninstall.sh                                 #remove rabbitmq_status_reset function in RabbitMQ uninstallation script
  fi 
  cp $testcase $package                                                                                         #copy the testcase to the installation directory
  echo "$file is running..."                                                                                    #display the running testcase on the screen
  bash -c "cd $package;./${file} >$package/$result"                                                             #run the testcase and generate a report
  cp $package/$result $PWD/$results/$rand$result                                                                #copy the testrun result from the installation directory to the current directory, and rename by prepending a random string
  cp $package/$log_name $PWD/$log/$OS_Version$name.log                                                          #copy the log from the installation directory to the current directory, and rename the log
  bash -c "if [ ! -f $package/$log_fail_name ]; then exit 1; else exit 0; fi;"                                  #determine if failed testcase log exists
  if [ $? -eq 0 ];then                                                                                          #only copy the failed testcase log the installation directory to the current directory, and rename the log 
  cp $package/$log_fail_name $PWD/$log_fail/$OS_Version$name.log
  fi
  cat $PWD/$results/$rand$result |tee -a $PWD/$results/$result                                                  #merge the testrun results in the results directory
  rm -rf $PWD/$results/$rand$result                                                                             #remove the temporary test results
}
if test $# -ne 1; then                                                                                          #only one argument is allowed
    echo "You have to pass only ONE argument to the command. The testrun aborted."
    exit 1
fi

file=$1	

if [ "${file##*.}"x != "sh"x ];then                                                                             #the argument must be a .sh file
    echo "The specified testcase is invalid: the specified paramater\
	was not a shell script. The testrun aborted."
	exit 1
fi

if [[ ! -n $(find $testcase_DIR/VM -name $file) ]]                                                              #find the testcase in testcase directory
        then
        echo "The specified testcase was not in the testcase directory. The testrun aborted."
        exit 1
fi
if [  -f "$certificate_DIR" ]; then                                                                             #if file exists, then delete it
  rm -rf "$certificate_DIR"
fi
if [ ! -d "$certificate_DIR" ]; then                                                                            #if directory does not exist, then create it
  mkdir -p $certificate_DIR
fi
if [  -f "$installation_DIR" ]; then                                                                            #if file exists, then delete it
  rm -rf "$installation_DIR"
fi
if [ ! -d "$installation_DIR" ]; then                                                                           #if directory does not exist, then create it
  mkdir -p $installation_DIR
fi
log="logs"                                                                                                      #the location of testcase logs in the host
if [  -f "$PWD/$log" ]; then                                                                                    #if file named "logs" exists, then delete it
  rm -rf "$PWD/$log"
fi
if [ ! -d "$PWD/$log" ]; then                                                                                   #if directory "logs" does not exist, then create it
  mkdir -p $PWD/$log
fi
log_fail="logs_fail"                                                                                            #the location of failed testcase logs in the host
if [  -f "$PWD/$log_fail" ]; then                                                                               #if file named "logs_fail" exists, then delete it
  rm -rf "$PWD/$log_fail"
fi
if [ ! -d "$PWD/$log_fail" ]; then                                                                              #if directory "logs_fail" does not exist, then create it
  mkdir -p $PWD/$log_fail
fi
results="results"                                                                                               #the location of testcase results in the host
if [  -f "$PWD/$results" ]; then                                                                                #if a file named "results" exists, then delete it
  rm -rf "$PWD/$results"
fi
if [ ! -d "$PWD/$results" ]; then                                                                               #if the directory does not exist, then create it
  mkdir -p $PWD/$results
fi
success="success_$OS_Version.list"
if [  -d "$PWD/$results/$success" ]; then                                                                       #if the directory exists, then delete it
  rm -rf "$PWD/$results/$success"
fi
newfail="newfail_$OS_Version.list"
if [  -d "$PWD/$results/$newfail" ]; then                                                                       #if the directory exists, then delete it
  rm -rf "$PWD/$results/$newfail"
fi
timeout="timeout_$OS_Version.list"
if [  -d "$PWD/$results/$timeout" ]; then                                                                       #if the directory exists, then delete it
  rm -rf "$PWD/$results/$timeout"
fi
DB=`basename $(ls $Installation_Package/MongoRpm/*.gz)`                                                         #MongoDB installation package name
ES=`basename $(ls $Installation_Package/Elasticsearch/*.gz)`                                                    #Elasticsearch installation package name
LA=`basename $(ls $Installation_Package/LicenseAgent/*.gz)`                                                     #License Agent installation package name
SM=`basename $(ls $Installation_Package/MONITOR/*.gz)`                                                          #Service Monitor Agent installation package name
AA=`basename $(ls $Installation_Package/AnsibleAgent/*.gz)`                                                     #Ansible Agent installation package name
MQ=`basename $(ls $Installation_Package/RABBITMQ/*.gz)`                                                         #RABBITMQ installation package name
RE=`basename $(ls $Installation_Package/REDIS/*.gz)`                                                            #Redis installation package name
FS=`basename $(ls $Installation_Package/FS/*.gz)`                                                               #Front Server installation package name
ALL=`basename $(ls $Installation_Package/ALL-LINUX/*.gz)`                                                       #ALL-LINUX installation package name
DB_path=`ls $Installation_Package/MongoRpm/*.gz`                                                                #MongoDB installation package path
ES_path=`ls $Installation_Package/Elasticsearch/*.gz`                                                           #Elasticsearch installation package path
LA_path=`ls $Installation_Package/LicenseAgent/*.gz`                                                            #License Agent installation package path
SM_path=`ls $Installation_Package/MONITOR/*.gz`                                                                 #Service Monitor Agent installation package path
AA_path=`ls $Installation_Package/AnsibleAgent/*.gz`                                                            #Ansible Agent installation package path
MQ_path=`ls $Installation_Package/RABBITMQ/*.gz`                                                                #RabbitMQ installation package path
RE_path=`ls $Installation_Package/REDIS/*.gz`                                                                   #Redis installation package path
FS_path=`ls $Installation_Package/FS/*.gz`                                                                      #Front Server installation package path
ALL_path=`ls $Installation_Package/ALL-LINUX/*.gz`                                                              #ALL-LINUX installation package path
rand=`openssl rand -hex 10`                                                                                     #generate a random string
OS=$file$rand                                                                                                   #the testrun name ending with random strings
name=$file$rand                                                                                                 #the testrun name ending with random strings
prefix=`echo $file|cut -f 1 -d'_'`                                                                              #the prefix of the testcase name: can only be the following lowercase: db, es, la, sm, aa, mq, re, te, fs, and all                                      

#################################################################################################################
# These commands are configurations for different components, such as MongoDB, ES, LA, SM, RabbitMQ, and Redis  #
#################################################################################################################
case $prefix in es)
if [ ! -f $package_DIR/$ES ];then                                                                               #determine if Elasticsearch installation package exists
echo "The Elasticsearch installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="Elasticsearch"                                                                                        #the unzipped installation package name for Elasticsearch
package="$installation_DIR/$DIR_name"                                                                           #the Elasticsearch installation package in testrun
package_name=$ES                                                                                                #the installation package name
log_name="ES.log"                                                                                               #log name generated in Elasticsearch testrun
log_fail_name="ES_fail.log"                                                                                     #log name generated in Elasticsearch testrun if a testcase failed
run_testcase                                                                                                    #invoke run_testcase funtion to run an Elasticsearch testcase
  ;;
la)
if [ ! -f $package_DIR/$LA ];then                                                                               #determine if License Agent installation package exists
echo "The License Agent installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="License"                                                                                              #the unzipped installation package name for License Agent
package="$installation_DIR/$DIR_name"                                                                           #the License Agent installation package in testrun
package_name=$LA                                                                                                #the installation package name
log_name="LA.log"                                                                                               #log name generated in License Agent testrun
log_fail_name="LA_fail.log"                                                                                     #log name generated in License Agent testrun if a testcase failed
run_testcase                                                                                                    #invoke run_testcase funtion to run a License Agent testcase
  ;;
db)
if [ ! -f $package_DIR/$DB ];then                                                                               #determine if MongoDB installation package exists
echo "The MongoDB installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="MongoDB"                                                                                              #the unzipped installation package name for MongoDB
package="$installation_DIR/$DIR_name"                                                                           #the MongoDB installation package in testrun
package_name=$DB                                                                                                #the installation package name
log_name="DB.log"                                                                                               #log name generated in MongoDB testrun
log_fail_name="DB_fail.log"                                                                                     #log name generated in MongoDB testrun if a testcase failed
run_testcase                                                                                                    #invoke run_testcase funtion to run a MongoDB testcase
  ;;
sm)
if [ ! -f $package_DIR/$SM ];then                                                                               #determine if Service Monitor Agent installation package exists
echo "The Service Monitor Agent installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="ServiceMonitorAgent"                                                                                  #the unzipped installation package name for Service Monitor Agent
package="$installation_DIR/$DIR_name"                                                                           #the Service Monitor Agent installation package in testrun
package_name=$SM                                                                                                #the installation package name
log_name="SM.log"                                                                                               #log name generated in Service Monitor Agent testrun
log_fail_name="SM_fail.log"                                                                                     #log name generated in Service Monitor Agent testrun if a testcase failed
run_testcase                                                                                                    #invoke run_testcase funtion to run a Service Monitor Agent testcase
  ;;
aa)
if [ ! -f $package_DIR/$AA ];then                                                                               #determine if Ansible Agent installation package exists
echo "The Ansible Agent installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="netbrain-ansibleagent"                                                                                #the unzipped installation package name for Ansible Agent
package="$installation_DIR/$DIR_name"                                                                           #the Ansible Agent installation package in testrun
package_name=$AA                                                                                                #the installation package name
log_name="AA.log"                                                                                               #log name generated in Ansible Agent testrun
log_fail_name="AA_fail.log"                                                                                     #log name generated in Ansible Agent testrun if a testcase failed
run_testcase                                                                                                    #invoke run_testcase funtion to run an Ansible Agent testcase
  ;;
all)
if [ ! -f $package_DIR/$ALL ];then                                                                              #determine if ALL-LINUX installation package exists
echo "The ALL-LINUX installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="netbrain-all-in-two-linux-8.0"                                                                        #the unzipped installation package name for ALL-LINUX
package="$installation_DIR/$DIR_name"                                                                           #the ALL-LINUX installation package in testrun
package_name=$ALL                                                                                               #the installation package name
log_name="ALL.log"                                                                                              #log name generated in ALL-LINUX testrun
log_fail_name="ALL_fail.log"                                                                                    #log name generated in ALL-LINUX testrun if a testcase failed
run_testcase                                                                                                    #invoke run_testcase funtion to run a ALL-LINUX testcase
  ;;
mq)
if [ ! -f $package_DIR/$MQ ];then                                                                               #determine if RabbitMQ installation package exists
echo "The RabbitMQ installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="rabbitmq"                                                                                             #the unzipped installation package name for RabbitMQ
package="$installation_DIR/$DIR_name"                                                                           #the RabbitMQ installation package in testrun
package_name=$MQ                                                                                                #the installation package name
log_name="MQ.log"                                                                                               #log name generated in RabbitMQ testrun
log_fail_name="MQ_fail.log"                                                                                     #log name generated in RabbitMQ testrun if a testcase failed
run_testcase                                                                                                    #invoke run_testcase funtion to run a RabbitMQ testcase
  ;;
re)
if [ ! -f $package_DIR/$RE ];then                                                                               #determine if Redis installation package exists
echo "The Redis installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="redis"                                                                                                #the unzipped installation package name for Redis
package="$installation_DIR/$DIR_name"                                                                           #the Redis installation package in testrun
package_name=$RE                                                                                                #the installation package name
log_fail_name="RE_fail.log"                                                                                     #log name generated in Redis testrun if a testcase failed
log_name="RE.log"                                                                                               #log name generated in Redis testrun
run_testcase                                                                                                    #invoke run_testcase funtion to run a Redis testcase
  ;; 
fs)
if [ ! -f $package_DIR/$FS ];then                                                                               #determine if Front Server installation package exists
echo "The Front Server installation package was not found. The testrun aborted."
exit 1
fi
DIR_name="FrontServer"                                                                                          #the unzipped installation package name for Front Server
package="$installation_DIR/$DIR_name"                                                                           #the Front Server installation package in testrun
package_name=$FS                                                                                                #the installation package name
log_fail_name="FS_fail.log"                                                                                     #log name generated in Front Server testrun if a testcase failed
log_name="FS.log"                                                                                               #log name generated in Front Server testrun
run_testcase                                                                                                    #invoke run_testcase funtion to run a Front Server testcase
  ;;   
 *)
  echo "The specified testcase is invalid. Make sure that the specified testcase name begins \
  with [db|es|la|sm|mq|re|fs|aa|all] lowercase. The testrun aborted."
  exit 1 
esac 

grep "passed" $PWD/$results/$result >$PWD/$results/$success                                                     #split the testrun results to success.list
grep "failed" $PWD/$results/$result >$PWD/$results/$newfail                                                     #split the testrun results to newfail.list
grep "timeout" $PWD/$results/$result >$PWD/$results/$timeout                                                    #split the testrun results to timeout.list
rm -rf $installation_DIR $certificate_DIR/$cert $certificate_DIR/$key $certificate_DIR/$ca                      #clean up
sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                      #release cache/buffer
echo -e "Elapsed time: $SECONDS seconds"                                                                        #display the testrun execution time on the screen
exit 0

