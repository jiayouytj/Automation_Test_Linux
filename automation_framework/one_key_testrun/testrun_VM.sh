#!/usr/bin/bash

##################################################################################################################
#title           :testrun_VM.sh                                                                                  #
#description     :This script will copy installation packages and certificates, and pull all testcases and       #
#                 automation framework from GitHub, then kick of testruns of all NetBrain Linux .                #
#                 Component under CentOS or Red Hat VM.                                                          #
#author		     :Zihao Yan                                                                                       #
#date            :20190528                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./testrun_VM.sh                                                                                #
#notes           :Install git.                                                                                   #
##################################################################################################################

##################################################################################################################
# This shell script is for Netbrain internal only                                                                #
##################################################################################################################
	
##################################################################################################################
# Usage: ./testrun_VM.sh.   This shell script will automatically copy installation packages, certificates,       #
#                           and pull all testcases and automation framework from GitHub, then run a bunch of     #
#                           testcases located within the testcase directory. The summary of testrun results      #
#                           will be generated in the same directory as this shell script located. In order to    #
#                           easily investigating any failures, the succeeded logs and failed logs are            #
#                           both generated.                                                                      #
#                                                                                                                #
#                                                                                                                #
#                                                                                                                #
#                                                                                                                #
#                                                                                                                #
##################################################################################################################

##################################################################################################################
# The following function is for running a testcase in VM                                                         #
##################################################################################################################

run_testcase()
{
  sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                     #release cache/buffer
  rand=`openssl rand -hex 10`                                                                                    #generate a random string
  OS=`basename ${array[i]}`$rand                                                                                 #the testcase name ending with random strings
  name=`basename ${array[i]}`$rand                                                                               #the testcase name sending with random strings
  testcase=`find $testcase_DIR/VM -name $(basename ${array[i]})`                                                 #get testcase name
  if [  -f "$certificate_DIR" ]; then                                                                            #if file exists, then delete it
  rm -rf "$certificate_DIR"
  fi
  if [ ! -d "$certificate_DIR" ]; then                                                                           #if directory does not exist, then create it
  mkdir -p $certificate_DIR
  fi
  if [  -f "$installation_DIR" ]; then                                                                           #if file exists, then delete it
  rm -rf "$installation_DIR"
  fi
  if [ ! -d "$installation_DIR" ]; then                                                                          #if directory does not exist, then create it
  mkdir -p $installation_DIR
  fi
  if [ ! -d "$package" ];then                                                                                    #determine if the package already exists in the installation directory
  cp $package_DIR/$package_name $installation_DIR                                                                #copy the installation package to installation directory
  tar -xf $installation_DIR/$package_name -C $installation_DIR >/dev/null 2>&1                                   #execute the installation package extraction
  if [[ `basename $package` == "netbrain-all-in-two-linux-8.0" ]];then                                           #determine if the package is netbrain-all-in-two-linux-8.0
  sed -i 's/rabbitmq_status_reset $/#&/g' $package/rabbitmq/others/uninstall.sh                                  #remove rabbitmq_status_reset function in RabbitMQ uninstallation script
  fi 
  cp -R $package $package.bak                                                                                    #back up installation package
  fi
  cp $cert_DIR/$cert $certificate_DIR                                                                            #copy the certificate to the certificate directory 
  cp $cert_DIR/$key $certificate_DIR                                                                             #copy the private key to the certificate directory 
  cp $cert_DIR/$ca $certificate_DIR                                                                              #copy the CA to the certificate directory 
  cp $testcase $package                                                                                          #copy the testcase to the installation directory
  echo "${array[i]} is running..."                                                                               #display the running testcase on the screen
  ps -ef|grep -E "mongo|elastic|license|redis|rabbitmq|erlang|netbrain"|\
  awk '{print $2}'|xargs kill -9 >/dev/null 2>&1                                                                 #kill all netbrain-all-in-two-linux related processes
  bash -c "cd $package;./${array[i]} >$package/$result"                                                          #run the testcase and generate a report
  cp $package/$result $PWD/$results/$rand$result                                                                 #copy the testrun result from the installation directory to the current directory, and rename by prepending a random string
  cp $package/$log_name $PWD/$log/$OS_Version$name.log                                                           #copy the log from the installation directory to the current directory, and rename the log
  bash -c "if [ ! -f $package/$log_fail_name ]; then exit 1; else exit 0; fi;"                                   #determine if failed testcase log exists
  if [ $? -eq 0 ];then                                                                                           #only copy the failed testcase log the installation directory to the current directory, and rename the log 
  cp $package/$log_fail_name $PWD/$log_fail/$OS_Version$name.log
  fi
  cat $PWD/$results/$rand$result |tee -a $PWD/$results/$result                                                   #merge the testrun results in the results directory
  rm -rf $PWD/$results/$rand$result                                                                              #remove the temporary test results
  rm -rf $package                                                                                                #remove used installation package
  cp -R $package.bak $package                                                                                    #restore installation package
  chmod -R 777 $package                                                                                          #grant full permission of installation package
  }

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
current_dir=`pwd`                                                                                                #get current directory
certificate_DIR="/etc/ssl"                                                                                       #the location of certificate directory
installation_DIR="/opt/temp/$version"                                                                            #the location of installation directory
result=test_result_$OS_Version.list                                                                              #test result file name  
cert='cert.pem'                                                                                                  #certificate
key='key.pem'                                                                                                    #private key    
ca='ca.pem'                                                                                                      #CA
version=8.0_stable                                                                                               #The package version
Installation_Package="/mnt/$version/`ls /mnt/$version|tail -1`/DEV"                                              #The installation package location on the server 192.168.33.101
AA_package="$Installation_Package/AnsibleAgent/*.gz"                                                             #The Ansible Agent installation package location on the server 192.168.33.101
ES_package="$Installation_Package/Elasticsearch/*.gz"                                                            #The Elasticsearch installation package location on the server 192.168.33.101
LA_package="$Installation_Package/LicenseAgent/*.gz"                                                             #The License Agent installation package location on the server 192.168.33.101
DB_package="$Installation_Package/MongoRpm/*.gz"                                                                 #The MongoDB installation package location on the server 192.168.33.101
SM_package="$Installation_Package/MONITOR/*.gz"                                                                  #The Service Monitor Agent installation package location on the server 192.168.33.101
MQ_package="$Installation_Package/RABBITMQ/*.gz"                                                                 #The RabbitMQ installation package location on the server 192.168.33.101
RE_package="$Installation_Package/REDIS/*.gz"                                                                    #The Redis installation package location on the server 192.168.33.101
FS_package="$Installation_Package/FS/*.gz"                                                                       #The Front Server installation package location on the server 192.168.33.101
ALL_package="$Installation_Package/ALL-LINUX/*.gz"                                                               #The all-in-two-linux installation package location on the server 192.168.33.101
echo "This testrun is on package `ls /mnt/$version|tail -1`"                                                     #echo which package will be used for this testrun
echo "Copying installation packages. Please wait..."
rm -rf $package_DIR                                                                                              #remove package directory for conflict
mkdir -p $package_DIR                                                                                            #create package directory
cp -R $AA_package $ES_package $LA_package \
$DB_package $SM_package $MQ_package $RE_package $FS_package $ALL_package $package_DIR                            #copy all installation packages to the testcase directory
AA_testcase_dir=$testcase_DIR/VM/AA/src                                                                          #Ansible Agent testcase directory
DB_testcase_dir=$testcase_DIR/VM/DB/src                                                                          #MongoDB testcase directory
ES_testcase_dir=$testcase_DIR/VM/ES/src                                                                          #Elasticsearch testcase directory
LA_testcase_dir=$testcase_DIR/VM/LA/src                                                                          #License Agent testcase directory
RE_testcase_dir=$testcase_DIR/VM/RE/src                                                                          #Redis testcase directory
MQ_testcase_dir=$testcase_DIR/VM/MQ/src                                                                          #RabbitMQ testcase directory
SM_testcase_dir=$testcase_DIR/VM/SM/src                                                                          #Service Monitor Agent testcase directory
FS_testcase_dir=$testcase_DIR/VM/FS/src                                                                          #Front Server testcase directory
ALL_testcase_dir=$testcase_DIR/VM/ALL/src                                                                        #all-in-two-linux testcase directory
cd $AA_testcase_dir;ls *.sh >../aa.list                                                                          #generate Ansible Agent testlist
cd $DB_testcase_dir;ls *.sh >../db.list                                                                          #generate MongoDB testlist
cd $ES_testcase_dir;ls *.sh >../es.list                                                                          #generate Elasticsearch testlist
cd $LA_testcase_dir;ls *.sh >../la.list                                                                          #generate License Agent testlist
cd $RE_testcase_dir;ls *.sh >../re.list                                                                          #generate Redis testlist
cd $MQ_testcase_dir;ls *.sh >../mq.list                                                                          #generate RabbitMQ testlist
cd $SM_testcase_dir;ls *.sh >../sm.list                                                                          #generate Service Monitor Agent testlist
cd $FS_testcase_dir;ls *.sh >../fs.list                                                                          #generate Front Server testlist
cd $ALL_testcase_dir;ls *.sh >../all.list                                                                        #generate all-in-two-linux testlist
echo "All installation packages have been copied from the server to the local machine."
cd "$current_dir"                                                                                                #go back to the directory where the shell locates
log="logs"                                                                                                       #the location of testcase logs in the host
if [  -f "$PWD/$log" ]; then                                                                                     #if file named "logs" exists, then delete it
rm -rf "$PWD/$log"
fi
if [ ! -d "$PWD/$log" ]; then                                                                                    #if directory "logs" does not exist, then create it
mkdir -p $PWD/$log
fi

log_fail="logs_fail"                                                                                             #the location of failed testcase logs in the host
if [  -f "$PWD/$log_fail" ]; then                                                                                #if file named "logs_fail" exists, then delete it
rm -rf "$PWD/$log_fail"
fi
if [ ! -d "$PWD/$log_fail" ]; then                                                                               #if directory "logs_fail" does not exist, then create it
mkdir -p $PWD/$log_fail
fi

if [  -f "$PWD/$results" ]; then                                                                                 #if a file named "results" exists, then delete it
rm -rf "$PWD/$results"
fi
if [ ! -d "$PWD/$results" ]; then                                                                                #if the directory does not exist, then create it
mkdir -p $PWD/$results
fi

success="success_$OS_Version.list"                                                                               #the location of succeeded testcase results in the host                                                             
if [  -d "$PWD/$results/$success" ]; then                                                                        #if the directory exists, then delete it
rm -rf "$PWD/$results/$success"
fi

newfail="newfail_$OS_Version.list"                                                                               #the location of failed testcase results in the host
if [  -d "$PWD/$results/$newfail" ]; then                                                                        #if the directory exists, then delete it
rm -rf "$PWD/$results/$newfail"
fi

timeout="timeout_$OS_Version.list"                                                                               #the location of timeout testcase results in the host
if [  -d "$PWD/$results/$timeout" ]; then                                                                        #if the directory exists, then delete it
rm -rf "$PWD/$results/$timeout"
fi

notfound="notfound_$OS_Version.list"                                                                             #the location of notfound testcase results in the host
if [  -d "$PWD/$results/$notfound" ]; then                                                                       #if the directory exists, then delete it
rm -rf "$PWD/$results/$notfound"
fi
DB=`basename $(ls $Installation_Package/MongoRpm/*.gz)`                                                          #MongoDB installation package name
ES=`basename $(ls $Installation_Package/Elasticsearch/*.gz)`                                                     #Elasticsearch installation package name
LA=`basename $(ls $Installation_Package/LicenseAgent/*.gz)`                                                      #License Agent installation package name
SM=`basename $(ls $Installation_Package/MONITOR/*.gz)`                                                           #Service Monitor Agent installation package name
AA=`basename $(ls $Installation_Package/AnsibleAgent/*.gz)`                                                      #Ansible Agent installation package name
MQ=`basename $(ls $Installation_Package/RABBITMQ/*.gz)`                                                          #RABBITMQ installation package name
RE=`basename $(ls $Installation_Package/REDIS/*.gz)`                                                             #Redis installation package name
FS=`basename $(ls $Installation_Package/FS/*.gz)`                                                                #Front Server installation package name
ALL=`basename $(ls $Installation_Package/ALL-LINUX/*.gz)`                                                        #ALL-LINUX installation package name
DB_path=`ls $Installation_Package/MongoRpm/*.gz`                                                                 #MongoDB installation package path
ES_path=`ls $Installation_Package/Elasticsearch/*.gz`                                                            #Elasticsearch installation package path
LA_path=`ls $Installation_Package/LicenseAgent/*.gz`                                                             #License Agent installation package path
SM_path=`ls $Installation_Package/MONITOR/*.gz`                                                                  #Service Monitor Agent installation package path
AA_path=`ls $Installation_Package/AnsibleAgent/*.gz`                                                             #Ansible Agent installation package path
MQ_path=`ls $Installation_Package/RABBITMQ/*.gz`                                                                 #RabbitMQ installation package path
RE_path=`ls $Installation_Package/REDIS/*.gz`                                                                    #Redis installation package path
FS_path=`ls $Installation_Package/FS/*.gz`                                                                       #Front Server installation package path
ALL_path=`ls $Installation_Package/ALL-LINUX/*.gz`                                                               #ALL-LINUX installation package path

##################################################################################################################
# These commands are for determining if the installation package and the testlists exist                         #
##################################################################################################################
if [[ ! -f $package_DIR/$DB ]] || [[ ! -f $package_DIR/$ES ]] || [[ ! -f $package_DIR/$LA ]] \
|| [[ ! -f $package_DIR/$SM ]] || [[ ! -f $package_DIR/$AA ]] || [[ ! -f $package_DIR/$MQ ]] \
|| [[ ! -f $package_DIR/$RE ]] || [[ ! -f $package_DIR/$FS ]] || [[ ! -f $package_DIR/$ALL ]];then               #determine if the installation packages exist
echo "One or more installation package were not found. The testrun aborted."|tee -a $PWD/$results/$result        #echo testcase not found and save it in the test result log
exit 1
fi

if [[ ! -n `find $testcase_DIR/VM -name "*.list"` ]];then                                                        #determine if the testcase in the testlist is in the testcase directory
echo "No testlist has been found. The testrun aborted."|tee -a $PWD/$results/$result                             #echo testcase not found and save it in the test result log
exit 1
fi

##################################################################################################################
# These commands are for storing all testcase shell script to an array                                           #
##################################################################################################################
if [[ ! -n `find $testcase_DIR/VM -name "*.list"` ]];then                                                        #determine if the testcase in the testlist is in the testcase directory
echo "No testlist has been found. The testrun aborted."|tee -a $PWD/$results/$result                             #echo testcase not found and save it in the test result log
exit 0
fi

c=0
for file in `cat $(find $testcase_DIR/VM/ -name "*.list")`                                                       #find the matched testcases in testlist 
do
  array[$c]=$file
  ((c++))
done
num=${#array[@]}                                                                                                 #the number of the testcases in total
##################################################################################################################
# These commands are for running testcases sequentically                                                         #
##################################################################################################################

echo "Kicking off the testrun..."                                                                                #echo kicking off the testrun 
for ((i=0;i<num;i++))
do
{
if [[ ! -n `find $testcase_DIR/VM -name "${array[i]}"` ]];then                                                   #determine if the testcase in the testlist is in the testcase directory
echo "Testcase ${array[i]} not found!"|tee -a $PWD/$results/$result                                              #echo testcase not found and save it in the test result log
else
prefix=`basename ${array[i]}|cut -f 1 -d'_'`                                                                     #the prefix of the testcase name: can only be the following lowercase: db, es, la, sm, aa, mq, re, te, fs, and all                                
##################################################################################################################
# These commands are configurations for different components, such as DB, ES, LA, SM, MQ, RE, FS, ALL, and AA    #
##################################################################################################################

case $prefix in es)
  DIR_name="Elasticsearch"                                                                                       #the unzipped installation package name for Elasticsearch
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$ES                                                                                               #the installation package name
  log_name="ES.log"                                                                                              #log name generated in Elasticsearch testrun
  log_fail_name="ES_fail.log"                                                                                    #log name generated in Elasticsearch testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testrun funtion to run a Elasticsearch testcase
 ;;
la)
  DIR_name="License"                                                                                             #the unzipped installation package name for License Agent
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$LA                                                                                               #the installation package name
  log_name="LA.log"                                                                                              #log name generated in License Agent testrun
  log_fail_name="LA_fail.log"                                                                                    #log name generated in License Agent testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testrun funtion to run a License Agent testcase
  ;;
db)
  DIR_name="MongoDB"                                                                                             #the unzipped installation package name for MongoDB
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$DB                                                                                               #the installation package name
  log_name="DB.log"                                                                                              #log name generated in MongoDB testrun
  log_fail_name="DB_fail.log"                                                                                    #log name generated in MongoDB testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testrun funtion to run a MongoDB testcase
  ;;
sm)
  DIR_name="ServiceMonitorAgent"                                                                                 #the unzipped installation package name for Service Monitor Agent
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$SM                                                                                               #the installation package name
  log_name="SM.log"                                                                                              #log name generated in Service Monitor Agent testrun
  log_fail_name="SM_fail.log"                                                                                    #log name generated in Service Monitor Agent testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testcase funtion to run a Service Monitor Agent testcase
  ;;
aa)
  DIR_name="netbrain-ansibleagent"                                                                               #the unzipped installation package name for Ansible Agent
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$AA                                                                                               #the installation package name
  log_name="AA.log"                                                                                              #log name generated in Ansible Agent testrun
  log_fail_name="AA_fail.log"                                                                                    #log name generated in Ansible Agent testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testrun funtion to run an Ansible Agent testcase
  ;;
all)
  DIR_name="netbrain-all-in-two-linux-8.0"                                                                       #the unzipped installation package name for ALL-LINUX
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$ALL                                                                                              #the installation package name
  log_name="ALL.log"                                                                                             #log name generated in ALL-LINUX testrun
  log_fail_name="ALL_fail.log"                                                                                   #log name generated in ALL-LINUX testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testrun funtion to run a ALL-LINUX testcase
  ;;
mq)
  DIR_name="rabbitmq"                                                                                            #the unzipped installation package name for RabbitMQ
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$MQ                                                                                               #the installation package name
  log_name="MQ.log"                                                                                              #log name generated in RabbitMQ testrun
  log_fail_name="MQ_fail.log"                                                                                    #log name generated in RabbitMQ testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testrun funtion to run a RabbitMQ testcase
  ;;
re)
  DIR_name="redis"                                                                                               #the unzipped installation package name for Redis
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$RE                                                                                               #the installation package name
  log_name="RE.log"                                                                                              #log name generated in Redis testrun
  log_fail_name="RE_fail.log"                                                                                    #log name generated in Redis testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testrun funtion to run a Redis testcase
  ;; 
fs)
  DIR_name="FrontServer"                                                                                         #the unzipped installation package name for Front Server
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$FS                                                                                               #the installation package name
  log_name="FS.log"                                                                                              #log name generated in Front Server testrun
  log_fail_name="FS_fail.log"                                                                                    #log name generated in Front Server testrun if a testcase failed
  run_testcase                                                                                                   #invoke run_testrun funtion to run a Front Server testcase
  ;;   
 *)
  echo "No testcase is available in the testcase directory. The testrun aborted."
  exit 1
esac 
fi
}
done

grep "passed" $PWD/$results/$result >$PWD/$results/$success                                                      #split the testrun results to success.list and newfail.list
grep "failed" $PWD/$results/$result >$PWD/$results/$newfail                                                      #split the testrun results to success.list and newfail.list
grep "timeout" $PWD/$results/$result >$PWD/$results/$timeout                                                     #split the testrun results to timeout.list
grep "not found" $PWD/$results/$result >$PWD/$results/$notfound                                                  #split the testrun results to notfound.list
echo "This testrun is on package `ls /mnt/$version|tail -1`" >>$PWD/$results/$summary                            #echo which package will be used for this testrun

if hostname -I|grep "192.168.30.191" >/dev/null 2>&1;then                                                        #Red Hat 7.5 Minimal Version is used for the testrun summary
echo "This is the testrun summary on a Red Hat 7.5 Minimal Version." >>$PWD/$results/$summary
fi
if hostname -I|grep "192.168.30.192" >/dev/null 2>&1;then                                                        #Red Hat 7.6 Minimal Version is used for the testrun summary
echo "This is the testrun summary on a Red Hat 7.6 Minimal Version." >>$PWD/$results/$summary
fi
if hostname -I|grep "192.168.30.186" >/dev/null 2>&1;then                                                        #CentOS 7.5 Minimal Version is used for the testrun summary
echo "This is the testrun summary on a CentOS 7.5 Minimal Version." >>$PWD/$results/$summary
fi
if hostname -I|grep "192.168.30.187" >/dev/null 2>&1;then                                                        #CentOS 7.5 Development Version is used for the testrun summary
echo "This is the testrun summary on a CentOS 7.5 Development Version." >>$PWD/$results/$summary
fi
if hostname -I|grep "192.168.30.188" >/dev/null 2>&1;then                                                        #CentOS 7.6 Minimal Version is used for the testrun summary 
echo "This is the testrun summary on a CentOS 7.6 Minimal Version." >>$PWD/$results/$summary
fi
if hostname -I|grep "192.168.30.189" >/dev/null 2>&1;then                                                        #CentOS 7.6 Development Version is used for the testrun summary
echo "This is the testrun summary on a CentOS 7.6 Development Version." >>$PWD/$results/$summary
fi

ARR=(es la db sm aa mq re fs all)                                                                                #list all possible prefix for all testcases
for prefix in ${ARR[*]}
do
case $prefix in es)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed Elasticsearch testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of Elasticsearch testcases
   if [ $total -eq 0 ];then                                                                                      #no Elasticsearch testcases
   echo "The total number of Elasticsearch testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Elasticsearch testcases: $passed_count" >>$PWD/$results/$summary
   echo "Elasticsearch testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the Elasticsearch testcases' successful rate
   echo "The total number of Elasticsearch testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Elasticsearch testcases: $passed_count" >>$PWD/$results/$summary
   echo "Elasticsearch testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
la)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed License Agent testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of License Agent testcases
   if [ $total -eq 0 ];then                                                                                      #no License Agent testcases
   echo "The total number of License Agent testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of License Agent testcases: $passed_count" >>$PWD/$results/$summary
   echo "License Agent testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the License Agent testcases' successful rate
   echo "The total number of License Agent testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of License Agent testcases: $passed_count" >>$PWD/$results/$summary
   echo "License Agent testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
db)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed MongoDB testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of MongoDB testcases
   if [ $total -eq 0 ];then                                                                                      #no MongoDB testcases
   echo "The total number of MongoDB testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of MongoDB testcases: $passed_count" >>$PWD/$results/$summary
   echo "MongoDB testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the MongoDB testcases' successful rate
   echo "The total number of MongoDB testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of MongoDB testcases: $passed_count" >>$PWD/$results/$summary
   echo "MongoDB testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
sm)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed Service Monitor Agent testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of Service Monitor Agent testcases
   if [ $total -eq 0 ];then                                                                                      #no Service Monitor Agent testcases
   echo "The total number of Service Monitor Agent testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Service Monitor Agent testcases: $passed_count" >>$PWD/$results/$summary
   echo "Service Monitor Agent testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the Service Monitor Agent testcases' successful rate
   echo "The total number of Service Monitor Agent testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Service Monitor Agent testcases: $passed_count" >>$PWD/$results/$summary
   echo "Service Monitor Agent testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
mq)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed RabbitMQ testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of RabbitMQ testcases
   if [ $total -eq 0 ];then                                                                                      #no RabbitMQ testcases
   echo "The total number of RabbitMQ testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of RabbitMQ testcases: $passed_count" >>$PWD/$results/$summary
   echo "RabbitMQ testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the RabbitMQ testcases' successful rate
   echo "The total number of RabbitMQ testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of RabbitMQ testcases: $passed_count" >>$PWD/$results/$summary
   echo "RabbitMQ testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
re)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed Redis testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of Redis testcases
   if [ $total -eq 0 ];then                                                                                      #no Redis testcases
   echo "The total number of Redis testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Redis testcases: $passed_count" >>$PWD/$results/$summary
   echo "Redis testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the Redis testcases' successful rate
   echo "The total number of Redis testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Redis testcases: $passed_count" >>$PWD/$results/$summary
   echo "Redis testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
aa)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed Ansible Agent testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of Ansible Agent testcases
   if [ $total -eq 0 ];then                                                                                      #no Ansible Agent testcases
   echo "The total number of Ansible Agent testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Ansible Agent testcases: $passed_count" >>$PWD/$results/$summary
   echo "Ansible Agent testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the Ansible Agent testcases' successful rate
   echo "The total number of Ansible Agent testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Ansible Agent testcases: $passed_count" >>$PWD/$results/$summary
   echo "Ansible Agent testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
all)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed all-in-two-linux testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of all-in-two-linux testcases
   if [ $total -eq 0 ];then                                                                                      #no all-in-two-linux testcases
   echo "The total number of all-in-two-linux testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of all-in-two-linux testcases: $passed_count" >>$PWD/$results/$summary
   echo "all-in-two-linux testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the all-in-two-linux testcases' successful rate
   echo "The total number of all-in-two-linux testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of all-in-two-linux testcases: $passed_count" >>$PWD/$results/$summary
   echo "all-in-two-linux testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
fs)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed"|wc -l`                                #the number of passed Front Server testcases 
   total=`cat $PWD/$results/$result|grep ./"$prefix"_|wc -l`                                                     #the total number of Front Server testcases
   if [ $total -eq 0 ];then                                                                                      #no Front Server testcases
   echo "The total number of Front Server testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Front Server testcases: $passed_count" >>$PWD/$results/$summary
   echo "Front Server testcases' successful rate: N/A" >>$PWD/$results/$summary
   else
   percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                       #calculate the Front Server testcases' successful rate
   echo "The total number of Front Server testcases: $total" >>$PWD/$results/$summary
   echo "The successful number of Front Server testcases: $passed_count" >>$PWD/$results/$summary
   echo "Front Server testcases' successful rate: $percent" >>$PWD/$results/$summary
   fi
   ;;
  *)
   echo "Unknown testcases in the testrun results." >>$PWD/$results/$summary
   ;;
esac 
done
passed_count=`cat $PWD/$results/$result|grep "passed"|wc -l`                                                     #the number of overall passed testcases 
total=`cat $PWD/$results/$result|grep "Testcase"|wc -l`                                                          #the total number of overall testcases
if [ $total -eq 0 ];then                                                                                         #no testcases
echo "The total number of overall testcases: $total" >>$PWD/$results/$summary
echo "The successful number of overall testcases: $passed_count" >>$PWD/$results/$summary
echo "Overall testcases' successful rate: N/A" >>$PWD/$results/$summary
else
percent=`awk 'BEGIN{printf "%.1f%%\n",('$passed_count'/'$total')*100}'`                                          #calculate the overall testcases' successful rate
echo "The total number of overall testcases: $total" >>$PWD/$results/$summary
echo "The successful number of overall testcases: $passed_count" >>$PWD/$results/$summary
echo "Overall testcases' successful rate: $percent" >>$PWD/$results/$summary
fi
sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                       #release cache/buffer
rm -rf $installation_DIR $certificate_DIR/$cert $certificate_DIR/$key $certificate_DIR/$ca                       #clean up
echo -e "Elapsed time: $SECONDS seconds"                                                                         #display the testrun execution time on the screen
exit 0

