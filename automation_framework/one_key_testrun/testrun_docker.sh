#!/usr/bin/bash

##################################################################################################################
#title           :testrun_docker.sh                                                                              #
#description     :This script will copy all testcases, frameworks, installation packages, certificates, and ,    #
#                 dependencies then kick of testruns of all NetBrain Linux Component under CentOS 7.6 docker.    #
#author		     :Zihao Yan                                                                                       #
#date            :20190528                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./testrun_docker.sh                                                                            #
#notes           :Install git and docker, and the docker service is running.                                     #
##################################################################################################################

##################################################################################################################
# This shell script is for Netbrain internal only                                                                #
##################################################################################################################
	
##################################################################################################################
# Usage: ./testrun_docker.sh. This shell script will automatically copy installation packages, and pull all      #
#                             testcases, automation framework, certificates, and dependencies from GitHub,       #
#                             then run a bunch of testcases located within the testcase directory. The summary   #
#                             of testrun results will be generated in the same directory as this shell script    # 
#                             located. The Dockerfiles are also generated on the fly, and will be deleted after  #
#                             the testrun. All the docker containers are deleted as well.                        #
#                                                                                                                #
#                                                                                                                #
#                                                                                                                #
#                                                                                                                #
#                                                                                                                #
#                                                                                                                #
##################################################################################################################

##################################################################################################################
# The following function is for creating a Dockerfile                                                            #
##################################################################################################################

current_dir=`pwd`                                                                                                #get current directory
mount -t cifs //192.168.33.101/US_Package  /mnt -o username=admin,password=NB@Dev101 >/dev/null 2>&1             #mount installation package
ls /mnt >/dev/null 2>&1                                                                                          #list /mnt to pretend resource unavailable
OS_Version="CentOS7.6"                                                                                           #This Linux OS version is CentOS 7.6
testcase_DIR="`pwd`/testcase"                                                                                    #the testcase directory pulled from GitHub
cert_DIR="`pwd`/certificate"                                                                                     #the certificate directory pulled from GitHub
dependencies_DIR="`pwd`/dependencies"                                                                            #the dependencies directory pulled from GitHub
package_DIR="`pwd`/package"                                                                                      #the installation package directory from 192.168.33.101
result=test_result_$OS_Version.list                                                                              #test result file name  
summary="testrun.summary"                                                                                        #testrun summary file
version=8.0_stable                                                                                               #The package version
Installation_Package="/mnt/$version/`ls /mnt/$version|tail -1`/DEV"                                              #the latest installation package from the server
installation_DIR=/opt/temp/$version                                                                              #the installation directory in docker
certificate_DIR=/etc/ssl                                                                                         #the location of certificate storing certificate, private key, and CA
cert='cert.pem'                                                                                                  #certificate
key='key.pem'                                                                                                    #private key    
ca='ca.pem'                                                                                                      #CA
rpm1="openssl-1.0.2p-16.el7.centos.x86_64.rpm"                                                                   #openssl rpm
rpm2="openssl-devel-1.0.2p-16.el7.centos.x86_64.rpm"                                                             #openssl-devel rpm
rpm3="openssl-libs-1.0.2p-16.el7.centos.x86_64.rpm"                                                              #openssl-libs rpm
AA_package="$Installation_Package/AnsibleAgent/*.gz"                                                             #The Ansible Agent installation package location on the server 192.168.33.101
ES_package="$Installation_Package/Elasticsearch/*.gz"                                                            #The Elasticsearch installation package location on the server 192.168.33.101
LA_package="$Installation_Package/LicenseAgent/*.gz"                                                             #The License Agent installation package location on the server 192.168.33.101
DB_package="$Installation_Package/MongoRpm/*.gz"                                                                 #The MongoDB installation package location on the server 192.168.33.101
SM_package="$Installation_Package/MONITOR/*.gz"                                                                  #The Service Monitor Agent installation package location on the server 192.168.33.101
MQ_package="$Installation_Package/RABBITMQ/*.gz"                                                                 #The RabbitMQ installation package location on the server 192.168.33.101
RE_package="$Installation_Package/REDIS/*.gz"                                                                    #The Redis installation package location on the server 192.168.33.101
FS_package="$Installation_Package/FS/*.gz"                                                                       #The Front Server installation package location on the server 192.168.33.101
echo "This testrun is on package `ls /mnt/$version|tail -1`"                                                     #echo which package will be used for this testrun
echo "Copying installation packages. Please wait..."
rm -rf $package_DIR                                                                                              #remove package directory for conflict
mkdir -p $package_DIR                                                                                            #create package directory
cp -R $AA_package $ES_package $LA_package \
$DB_package $SM_package $MQ_package $RE_package $FS_package $package_DIR                                         #copy all installation packages to the package directory
AA_testcase_dir=$testcase_DIR/docker/AA/src                                                                      #Ansible Agent testcase directory
DB_testcase_dir=$testcase_DIR/docker/DB/src                                                                      #MongoDB testcase directory
ES_testcase_dir=$testcase_DIR/docker/ES/src                                                                      #Elasticsearch testcase directory
LA_testcase_dir=$testcase_DIR/docker/LA/src                                                                      #License Agent testcase directory
RE_testcase_dir=$testcase_DIR/docker/RE/src                                                                      #Redis testcase directory
MQ_testcase_dir=$testcase_DIR/docker/MQ/src                                                                      #RabbitMQ testcase directory
SM_testcase_dir=$testcase_DIR/docker/SM/src                                                                      #Service Monitor Agent testcase directory
FS_testcase_dir=$testcase_DIR/docker/FS/src                                                                      #Front Server testcase directory
cd $AA_testcase_dir;ls *.sh >../aa.list                                                                          #generate Ansible Agent testlist
cd $DB_testcase_dir;ls *.sh >../db.list                                                                          #generate MongoDB testlist
cd $ES_testcase_dir;ls *.sh >../es.list                                                                          #generate Elasticsearch testlist
cd $LA_testcase_dir;ls *.sh >../la.list                                                                          #generate License Agent testlist
cd $RE_testcase_dir;ls *.sh >../re.list                                                                          #generate Redis testlist
cd $MQ_testcase_dir;ls *.sh >../mq.list                                                                          #generate RabbitMQ testlist
cd $SM_testcase_dir;ls *.sh >../sm.list                                                                          #generate Service Monitor Agent testlist
cd $FS_testcase_dir;ls *.sh >../fs.list                                                                          #generate Front Server testlist
echo "All installation packages have been copied from the server to the local machine."
cd "$current_dir"                                                                                                #go back to the directory where the shell locates
service docker restart >/dev/null 2>&1                                                                           #restart the docker service to make it available all the time
Linux="centos:7.6.1810"                                                                                          #This Linux OS version is CentOS 7.6 for docker
create_Dockerfile()
{
  echo "FROM $Linux" >> $Dockerfile
  echo "RUN yum install -y deltarpm \\" >> $Dockerfile
  echo "    && yum install -y e2fsprogs \\" >> $Dockerfile
  echo "    && yum install -y iproute \\" >> $Dockerfile
  echo "    && yum install -y tuned \\" >> $Dockerfile
  echo "    && yum install -y cronie \\" >> $Dockerfile
  echo "    && yum install -y initscripts \\" >> $Dockerfile
  echo "    && yum install -y vsftpd \\" >> $Dockerfile
  echo "    && yum install -y firewalld \\" >> $Dockerfile
  echo "    && yum install -y net-tools \\" >> $Dockerfile
  echo "    && yum install -y make \\" >> $Dockerfile
  echo "    && yum install -y lsof \\" >> $Dockerfile
  echo "    && yum install -y socat \\" >> $Dockerfile
  echo "    && yum install -y sudo \\" >> $Dockerfile
  echo "    && yum install -y nmap-ncat \\" >> $Dockerfile
  echo "    && yum install -y epel-release \\" >> $Dockerfile
  echo "    && yum install -y git \\" >> $Dockerfile
  echo "    && yum install -y ansible \\" >> $Dockerfile
  echo "    && yum install -y file \\" >> $Dockerfile
  echo "    && yum install -y zlib-devel \\" >> $Dockerfile
  echo "    && yum install -y readline-devel \\" >> $Dockerfile
  echo "    && yum install -y bzip2-devel \\" >> $Dockerfile
  echo "    && yum install -y ncurses-devel \\" >> $Dockerfile
  echo "    && yum install -y gdbm-devel \\" >> $Dockerfile
  echo "    && yum install -y tk-devel \\" >> $Dockerfile
  echo "    && yum install -y xz-devel \\" >> $Dockerfile
  echo "    && yum install -y libffi-devel \\" >> $Dockerfile
  echo "    && mkdir -p $package" >> $Dockerfile
  echo "WORKDIR $package">> $Dockerfile
  chmod 755 $Dockerfile
}

##################################################################################################################
# The following function is for running a testcase in docker                                                     #
##################################################################################################################
run_Docker()
{
  sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                     #release cache/buffer
  rand=`openssl rand -hex 10`                                                                                    #generate a random string
  OS=`basename ${array[i]}`$rand                                                                                 #the docker image name starting with testcase name
  name=`basename ${array[i]}`$rand                                                                               #the docker name starting with testcase name
  testcase=`find $testcase_DIR/docker -name $(basename ${array[i]})`                                             #get testcase name
  docker build -f $Dockerfile -t $OS . >/dev/null 2>&1                                                           #build the docker based on the generated Dockerfile
  docker run -tdi --name="$name" --privileged $OS init >/dev/null 2>&1                                           #initialize the docker with privilege
  docker cp $package_DIR/$package_name $name:$installation_DIR                                                   #copy the installation package from the host to docker 
  docker cp $cert_DIR/$cert $name:$certificate_DIR                                                               #copy the certificate from the host to docker 
  docker cp $cert_DIR/$key $name:$certificate_DIR                                                                #copy the private key from the host to docker 
  docker cp $cert_DIR/$ca $name:$certificate_DIR                                                                 #copy the CA from the host to docker 
  docker cp $dependencies_DIR/$rpm1 $name:$package                                                               #copy openssl rpm from the host to docker 
  docker cp $dependencies_DIR/$rpm2 $name:$package                                                               #copy openssl-devel from the host to docker 
  docker cp $dependencies_DIR/$rpm3 $name:$package                                                               #copy openssl-libs from the host to docker 
  docker exec -i $name tar -xf $installation_DIR/$package_name -C $installation_DIR >/dev/null 2>&1              #execute the installation package extraction in docker
  docker cp $testcase $name:$package                                                                             #copy the testcase from the host to the docker
  echo "${array[i]} is running..."                                                                               #display the running testcase on the screen
  docker exec -i $name bash -c "systemctl stop firewalld.service;systemctl stop getty@tty1.service;\
  systemctl mask getty@tty1.service >/dev/null 2>&1" >/dev/null 2>&1                                             #stop firewall and getty service in docker
  docker exec -i $name bash -c "rpm -Uvh $package/$rpm1 --nodeps --force >/dev/null 2>&1;\
  rpm -Uvh $package/$rpm2 --nodeps --force >/dev/null 2>&1;\
  rpm -Uvh $package/$rpm3 --nodeps --force >/dev/null 2>&1 >/dev/null 2>&1" >/dev/null 2>&1                      #install openssl, openssl-devel, and openssl-libs 
  docker exec -i $name bash -c "find $package -name 'install.sh'|xargs sed -i '/add_port_to_firewall/'d"         #do not execute add_port_to_firewall function in docker
  docker exec -i $name bash -c "find $package -name 'install.sh'|xargs sed -i '/add_portlist_to_firewall/'d"     #do not execute add_portlist_to_firewall function in docker
  docker exec -i $name bash -c "find $package -name 'uninstall.sh'|xargs sed -i '/remove_all_port$/d'"           #do not execute remove_all_port function in docker
  docker exec -i $name bash -c "find $package -name 'uninstall.sh'|xargs sed -i '/remove_port$/d'"               #do not execute remove_port function in docker
  docker exec -i $name bash -c "find $package -name 'uninstall.sh'|xargs sed -i '/remove_port [PORT]*/d'"        #do not execute remove_port function in docker
  docker exec -i $name bash -c "cd $package;./${array[i]##*/} >$package/$result"                                 #run the testcase in docker and generate a report
  docker cp $name:$package/$result $PWD/$results/$rand$result                                                    #copy the testrun result from the docker to the host, and rename by prepending a random string
  docker cp $name:$package/$log_name $PWD/$log/$OS_Version$name.log                                              #copy the log from the docker to the host, and rename the log
  docker exec -t $name bash -c "if [ ! -f $log_fail_name ]; then exit 1; else exit 0; fi;"                       #determine if failed testcase log exists
  if [ $? -eq 0 ];then                                                                                           #only copy the failed testcase log from the docker to the host, and rename the log 
  docker cp $name:$package/$log_fail_name $PWD/$log_fail/$OS_Version$name.log
  fi
  cat $PWD/$results/$rand$result |tee -a $PWD/$results/$result                                                   #merge the testrun results in the results directory
  docker rm -f $name >/dev/null 2>&1                                                                             #remove all docker containers
  rm -rf $PWD/$results/$rand$result                                                                              #remove the temporary test results
}

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
results="results"                                                                                                #the location of testcase results in the host
if [  -f "$PWD/$results" ]; then                                                                                 #if a file named "results" exists, then delete it
  rm -rf "$PWD/$results"
fi
if [ ! -d "$PWD/$results" ]; then                                                                                #if the directory does not exist, then create it
  mkdir -p $PWD/$results
fi
success="success_$OS_Version.list"
if [  -d "$PWD/$results/$success" ]; then                                                                        #if the directory exists, then delete it
  rm -rf "$PWD/$results/$success"
fi
newfail="newfail_$OS_Version.list"
if [  -d "$PWD/$results/$newfail" ]; then                                                                        #if the directory exists, then delete it
  rm -rf "$PWD/$results/$newfail"
fi
timeout="timeout_$OS_Version.list"
if [  -d "$PWD/$results/$timeout" ]; then                                                                        #if the directory exists, then delete it
  rm -rf "$PWD/$results/$timeout"
fi
notfound="notfound_$OS_Version.list"
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
rm -rf *_Dockerfile                                                                                              #remove all previous Dockerfile

##################################################################################################################
# These commands are for determining if the installation package and the testlists exist                         #
##################################################################################################################
if [[ ! -f $package_DIR/$DB ]] || [[ ! -f $package_DIR/$ES ]] || [[ ! -f $package_DIR/$LA ]] \
|| [[ ! -f $package_DIR/$SM ]] || [[ ! -f $package_DIR/$AA ]] || [[ ! -f $package_DIR/$MQ ]] \
|| [[ ! -f $package_DIR/$RE ]] || [[ ! -f $package_DIR/$FS ]];then                                               #determine if the installation packages exist
echo "One or more installation package were not found. The testrun aborted."|tee -a $PWD/$results/$result        #echo testcase not found and save it in the test result log
exit 1
fi

##################################################################################################################
# These commands are for determining if the testlists exist                                                      #
##################################################################################################################
if [[ ! -n `find $testcase_DIR/docker -name "*.list"` ]];then                                                    #determine if the testlists exist
echo "No testlist has been found. The testrun aborted."|tee -a $PWD/$results/$result                             #echo testcase not found and save it in the test result log
sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                       #release cache/buffer
exit 0
fi

##################################################################################################################
# These commands are for creating Dockerfile for License Agent: LA_Dockerfile                                    #
##################################################################################################################

Dockerfile="LA_"$OS_Version"_Dockerfile"                                                                         #specify the Dockerfile name for License Agent
DIR_name="License"                                                                                               #the unzipped installation package name for License Agent
package="$installation_DIR/$DIR_name"                                                                            #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                                #invoke create_Dockerfile function to create a Dockerfile for License Agent

##################################################################################################################
# These commands are for creating Dockerfile for MongoDB: DB_Dockerfile                                          #
##################################################################################################################

Dockerfile="DB_"$OS_Version"_Dockerfile"                                                                         #specify the Dockerfile name for MongoDB
DIR_name="MongoDB"                                                                                               #the unzipped installation package name for MongoDB
package="$installation_DIR/$DIR_name"                                                                            #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                                #invoke create_Dockerfile function to create a Dockerfile for MongoDB

##################################################################################################################
# These commands are for creating Dockerfile for Elasticsearch: ES_Dockerfile                                    #
##################################################################################################################

Dockerfile="ES_"$OS_Version"_Dockerfile"                                                                         #specify the Dockerfile for Elasticsearch
DIR_name="Elasticsearch"                                                                                         #the unzipped installation package name for Elasticsearch
package="$installation_DIR/$DIR_name"                                                                            #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                                #invoke create_Dockerfile function to create a Dockerfile for Elasticsearch

##################################################################################################################
# These commands are for creating Dockerfile for Service Monitor Agent: SM_Dockerfile                            #
##################################################################################################################

Dockerfile="SM_"$OS_Version"_Dockerfile"                                                                         #specify the Dockerfile name for Service Monitor Agent
DIR_name="ServiceMonitorAgent"                                                                                   #the unzipped installation package name for Service Monitor Agent
package="$installation_DIR/$DIR_name"                                                                            #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                                #invoke create_Dockerfile function to create a Dockerfile for Service Monitor Agent

##################################################################################################################
# These commands are for creating Dockerfile for Ansible Agent: AA_Dockerfile                                    #
##################################################################################################################

Dockerfile="AA_"$OS_Version"_Dockerfile"                                                                         #specify the Dockerfile name for Ansible Agent
DIR_name="netbrain-ansibleagent"                                                                                 #the unzipped installation package name for Ansible Agent
package="$installation_DIR/$DIR_name"                                                                            #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                                #invoke create_Dockerfile function to create a Dockerfile for Ansible Agent

##################################################################################################################
# These commands are for creating Dockerfile for RabbitMQ: MQ_Dockerfile                                         #
##################################################################################################################

Dockerfile="MQ_"$OS_Version"_Dockerfile"                                                                         #specify the Dockerfile name for RabbitMQ
DIR_name="rabbitmq"                                                                                              #the unzipped installation package name for RabbitMQ
package="$installation_DIR/$DIR_name"                                                                            #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                                #invoke create_Dockerfile function to create a Dockerfile for RabbitMQ

##################################################################################################################
# These commands are for creating Dockerfile for Redis: RE_Dockerfile                                            #
##################################################################################################################

Dockerfile="RE_"$OS_Version"_Dockerfile"                                                                         #specify the Dockerfile name for Redis
DIR_name="redis"                                                                                                 #the unzipped installation package name for Redis
package="$installation_DIR/$DIR_name"                                                                            #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                                #invoke create_Dockerfile function to create a Dockerfile for Redis

##################################################################################################################
# These commands are for creating Dockerfile for Front Server: FS_Dockerfile                                     #
##################################################################################################################

Dockerfile="FS_"$OS_Version"_Dockerfile"                                                                         #specify the Dockerfile name for Front Server
DIR_name="FrontServer"                                                                                           #the unzipped installation package name for Front Server
package="$installation_DIR/$DIR_name"                                                                            #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                                #invoke create_Dockerfile function to create a Dockerfile for Front Server


testrun()
{
c=0
unset array                                                                                                      #clear array
for file in `cat $(find $testcase_DIR/docker -name "*.list")`                                                    #find the matched testcases in testlist 
do
  array[$c]=$file
  ((c++))
done
num=${#array[@]}                                                                                                 #the number of the testcases in total
[ -e ./fd1 ] || mkfifo ./fd1                                                                                     #create FIFO
exec 3<> ./fd1                                                                                                   #create file descriptor  
rm -rf ./fd1                                                                                                     #remove the FIFO because file descriptor is enough
threshold=40                                                                                                     #the maximum number of concurrency
for j in `seq 1 $threshold`;                                                                                     #create the token
do
    echo >&3                                                                                                     #echo a token
done

for ((i=0;i<num;i++))
do
{
if [[ ! -n `find $testcase_DIR/docker -name "${array[i]}"` ]];then                                               #determine if the testcase in the testlist is in the testcase directory
echo "Testcase ${array[i]} not found!"|tee -a $PWD/$results/$result                                              #echo testcase not found and save it in the test result log
else
read -u3                                                                                                         #read a token
prefix=`basename ${array[i]}|cut -f 1 -d'_'`                                                                     #the prefix of the testcase name: can only be the following: DB, ES, LA, SM                                      
case $prefix in es)
  Dockerfile="ES_"$OS_Version"_Dockerfile"                                                                       #specify the Dockerfile for Elasticsearch
  DIR_name="Elasticsearch"                                                                                       #the unzipped installation package name for Elasticsearch
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$ES                                                                                               #the installation package name
  log_name="ES.log"                                                                                              #log name generated in Elasticsearch docker
  log_fail_name="ES_fail.log"                                                                                    #log name generated in Elasticsearch docker if a testcase failed
  run_Docker                                                                                                     #invoke run_Docker funtion to run a Elasticsearch testcase in docker
  ;;
la)
  Dockerfile="LA_"$OS_Version"_Dockerfile"                                                                       #specify the Dockerfile name for License Agent
  DIR_name="License"                                                                                             #the unzipped installation package name for License Agent
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$LA                                                                                               #the installation package name
  log_name="LA.log"                                                                                              #log name generated in License Agent docker
  log_fail_name="LA_fail.log"                                                                                    #log name generated in License Agent docker if a testcase failed
  run_Docker                                                                                                     #invoke run_Docker funtion to run a License Agent testcase in docker
  ;;
db)
  Dockerfile="DB_"$OS_Version"_Dockerfile"                                                                       #specify the Dockerfile name for MongoDB
  DIR_name="MongoDB"                                                                                             #the unzipped installation package name for MongoDB Agent
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$DB                                                                                               #the installation package name
  log_name="DB.log"                                                                                              #log name generated in MongoDB docker
  log_fail_name="DB_fail.log"                                                                                    #log name generated in MongoDB docker if a testcase failed
  run_Docker                                                                                                     #invoke run_Docker funtion to run a MongoDB testcase in docker
  ;;
sm)
  Dockerfile="SM_"$OS_Version"_Dockerfile"                                                                       #specify the Dockerfile name for Service Monitor Agent
  DIR_name="ServiceMonitorAgent"                                                                                 #the unzipped installation package name for License Agent
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$SM                                                                                               #the installation package name
  log_name="SM.log"                                                                                              #log name generated in Service Monitor Agent docker
  log_fail_name="SM_fail.log"                                                                                    #log name generated in Service Monitor Agent docker if a testcase failed
  run_Docker                                                                                                     #invoke run_Docker funtion to run a Service Monitor Agent testcase in docker
  ;;
aa)
  Dockerfile="AA_"$OS_Version"_Dockerfile"                                                                       #specify the Dockerfile name for Ansible Agent
  DIR_name="netbrain-ansibleagent"                                                                               #the unzipped installation package name for Ansible Agent
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$AA                                                                                               #the installation package name
  log_name="AA.log"                                                                                              #log name generated in Ansible Agent docker
  log_fail_name="AA_fail.log"                                                                                    #log name generated in Ansible Agent docker if a testcase failed
  run_Docker                                                                                                     #invoke run_Docker funtion to run an Ansible Agent testcase in docker
  ;;
mq)
  Dockerfile="MQ_"$OS_Version"_Dockerfile"                                                                       #specify the Dockerfile name for RabbitMQ
  DIR_name="rabbitmq"                                                                                            #the unzipped installation package name for RabbitMQ
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$MQ                                                                                               #the installation package name
  log_name="MQ.log"                                                                                              #log name generated in RabbitMQ docker
  log_fail_name="MQ_fail.log"                                                                                    #log name generated in RabbitMQ docker if a testcase failed
  run_Docker                                                                                                     #invoke run_Docker funtion to run a RabbitMQ testcase in docker
  ;;
re)
  Dockerfile="RE_"$OS_Version"_Dockerfile"                                                                       #specify the Dockerfile name for Redis
  DIR_name="redis"                                                                                               #the unzipped installation package name for Redis
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$RE                                                                                               #the installation package name
  log_name="RE.log"                                                                                              #log name generated in Redis docker
  log_fail_name="RE_fail.log"                                                                                    #log name generated in Redis docker if a testcase failed
  run_Docker                                                                                                     #invoke run_Docker funtion to run a Redis testcase in docker
  ;; 
fs)
  Dockerfile="FS_"$OS_Version"_Dockerfile"                                                                       #specify the Dockerfile name for Front Server
  DIR_name="FrontServer"                                                                                         #the unzipped installation package name for Front Server
  package="$installation_DIR/$DIR_name"                                                                          #the installation package directory after unzipping the tar.gz file
  package_name=$FS                                                                                               #the installation package name
  log_name="FS.log"                                                                                              #log name generated in Front Server docker
  log_fail_name="FS_fail.log"                                                                                    #log name generated in Front Server docker if a testcase failed
  run_Docker                                                                                                     #invoke run_Docker funtion to run a Front Server testcase in docker
  ;;   
 *)
  echo "No testcase is available in the testcase directory. The testrun aborted."
  exit 1
  ;;
esac 
echo >&3                                                                                                         #put the token back to FIFO once one shell command has been completed
fi
}&
done
wait
}
echo "Kicking off the testrun..."
testrun                                                                                                          #kick off the testrun for the first time
if [ `grep "failed\!$" $PWD/$results/$result|wc -l` == 0 ];then                                                  #determine if no failed testcases in the first testrun
echo "There is no failed testcase, thus skip the re-spin."
else
find $testcase_DIR -name "*.list"|xargs rename .list .list.bak >/dev/null 2>&1                                   #temporarily rename all .list file to .list.bak
rm -rf $testcase_DIR/docker/fail.list                                                                            #remove failed testlist for conflict
rm -rf $PWD/logs_fail/*                                                                                          #remove previously failed testcsae logs
grep "failed\!$" $PWD/$results/$result|awk '{print $(NF-1)}'|sed 's/\.\///g' >>$testcase_DIR/docker/fail.list    #generate failed testlist
sed -i "/failed\!$/"d $PWD/$results/$result >/dev/null 2>&1                                                      #delete all failed testcase record from the results
echo "Re-kicking off the testrun on failed testcases only... "
testrun                                                                                                          #testrun re-spin 
find $testcase_DIR -name "*.list.bak"|xargs rename .list.bak .list >/dev/null 2>&1                               #rename all .list.bak file to .list
rm -rf $testcase_DIR/docker/fail.list                                                                            #remove failed testlist after re-spin
fi

grep "passed\!$" $PWD/$results/$result >$PWD/$results/$success                                                   #split the testrun results to success.list and newfail.list
grep "failed\!$" $PWD/$results/$result >$PWD/$results/$newfail                                                   #split the testrun results to success.list and newfail.list
grep "timeout\!$" $PWD/$results/$result >$PWD/$results/$timeout                                                  #split the testrun results to timeout.list
grep "not found" $PWD/$results/$result >$PWD/$results/$notfound                                                  #split the testrun results to notfound.list
echo "This testrun is on package `ls /mnt/$version|tail -1`" >>$PWD/$results/$summary                            #echo which package will be used for this testrun
echo "This is the testrun summary on a CentOS 7.6 docker" >>$PWD/$results/$summary                               #CentOS 7.6 docker is used for this testrun
ARR=(es la db sm aa mq re fs)                                                                                    #list all possible prefix for all testcases
for prefix in ${ARR[*]}
do
case $prefix in es)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed\!$"|wc -l`                             #the number of passed Elasticsearch testcases 
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
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed\!$"|wc -l`                             #the number of passed License Agent testcases 
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
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed\!$"|wc -l`                             #the number of passed MongoDB testcases 
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
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed\!$"|wc -l`                             #the number of passed Service Monitor Agent testcases 
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
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed\!$"|wc -l`                             #the number of passed RabbitMQ testcases 
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
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed\!$"|wc -l`                             #the number of passed Redis testcases 
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
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed\!$"|wc -l`                             #the number of passed Ansible Agent testcases 
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
fs)
   passed_count=`cat $PWD/$results/$result|grep ./"$prefix"_|grep "passed\!$"|wc -l`                             #the number of passed Front Server testcases 
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
passed_count=`cat $PWD/$results/$result|grep "passed\!$"|wc -l`                                                  #the number of overall passed testcases 
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
rm -rf *_Dockerfile                                                                                              #remove all Dockerfiles
sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                       #release cache/buffer
echo -e "Elapsed time: $SECONDS seconds"                                                                         #display the testrun execution time on the screen
exec 3<&-                                                                                                        #close the reading of file descriptor
exec 3>&-                                                                                                        #close the writing of file descriptor
exit 0

