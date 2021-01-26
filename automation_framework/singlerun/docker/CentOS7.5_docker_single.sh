#!/usr/bin/bash

#################################################################################################################
#title           :CentOS7.5_docker_single.sh                                                                    #
#description     :This script will kick of a single testrun of NetBrain Linux Component under CentOS 7.5 docker #
#author		     :Zihao Yan                                                                                      #
#date            :20190605                                                                                      #
#version         :1.0                                                                                           #
#usage		     :./CentOS7.5_docker_single.sh [es|la|db|sm|mq|re|te|fs|aa|all]_*.sh                            #
#details         :es: Elasticsearch la: License Agent db: MongoDB sm: Service Monitor Agent                     #
#                 mq: RabbitMQ re: Redis te: Task Engine fs: Front Server aa: Ansible Agent                     #
#notes           :Install git and docker, and the docker service is running.                                    #
#################################################################################################################

#################################################################################################################
# This shell script is for Netbrain internal only                                                               #
#################################################################################################################    
	
	
#################################################################################################################
# Usage: CentOS7.5_docker_single.sh [es|la|db|sm|mq|re|te|fs|aa|all]_*.sh. the first parameter must be a .sh    #
# file with the name beginning with either es, la, db, sm, mq, re, te, fs, aa, and all lowercase                #
# Usage example: 1: ./CentOS7.5_docker_single.sh db_install.sh                                                  #
#                2: ./CentOS7.5_docker_single.sh es_install.sh                                                  #
#                3: ./CentOS7.5_docker_single.sh la_install.sh                                                  #
#                4: ./CentOS7.5_docker_single.sh sm_install.sh                                                  #
#                5: ./CentOS7.5_docker_single.sh mq_install.sh                                                  #
#                6: ./CentOS7.5_docker_single.sh re_install.sh                                                  #
#                7: ./CentOS7.5_docker_single.sh te_install.sh                                                  #
#                8: ./CentOS7.5_docker_single.sh fs_install.sh                                                  #
#                9: ./CentOS7.5_docker_single.sh aa_install.sh                                                  #
#                10: ./CentOS7.5_docker_single.sh all_install.sh                                                #
#################################################################################################################	

#################################################################################################################
# The following function is for creating a Dockerfile                                                           #
#################################################################################################################

mount -t cifs //192.168.33.101/US_Package  /mnt -o username=admin,password=NB@Dev101 >/dev/null 2>&1             #mount installation package
ls /mnt >/dev/null 2>&1                                                                                          #list /mnt to pretend resource unavailable
OS_Version="CentOS7.5"                                                                                           #This Linux OS version is CentOS 7.5
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
service docker restart >/dev/null 2>&1                                                                           #restart the docker service to make it available all the time
Linux="centos:7.5.1804"                                                                                          #This Linux OS version is CentOS 7.5 for docker
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
  echo "    && yum install -y xz-devel \\" >> $Dockerfile
  echo "    && yum install -y tk-devel \\" >> $Dockerfile
  echo "    && yum install -y libffi-devel \\" >> $Dockerfile
  echo "    && mkdir -p $package" >> $Dockerfile
  echo "WORKDIR $package">> $Dockerfile
  chmod 755 $Dockerfile
}


#################################################################################################################
# The following function is for running a testcase in docker                                                    #
#################################################################################################################
run_Docker()
{
  sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                    #release cache/buffer
  testcase=`find $testcase_DIR/docker -name $file`                                                              #get testcase name
  docker build -f $Dockerfile -t $OS . >/dev/null 2>&1                                                          #build the docker based on the generated Dockerfile
  docker run -tdi --name="$name" --privileged $OS init >/dev/null 2>&1                                          #initialize the docker with privilege
  docker cp $package_DIR/$package_name $name:$installation_DIR                                                  #copy the installation package from the host to docker
  docker cp $cert_DIR/$cert $name:$certificate_DIR                                                              #copy the certificate from the host to docker 
  docker cp $cert_DIR/$key $name:$certificate_DIR                                                               #copy the private key from the host to docker 
  docker cp $cert_DIR/$ca $name:$certificate_DIR                                                                #copy the CA from the host to docker 
  docker cp $dependencies_DIR/$rpm1 $name:$package                                                              #copy openssl rpm from the host to docker 
  docker cp $dependencies_DIR/$rpm2 $name:$package                                                              #copy openssl-devel from the host to docker 
  docker cp $dependencies_DIR/$rpm3 $name:$package                                                              #copy openssl-libs from the host to docker 
  docker exec -i $name tar -xvf $installation_DIR/$package_name -C $installation_DIR >/dev/null 2>&1            #execute the installation package extraction in docker
  docker cp $testcase $name:$package                                                                            #copy the testcase from the host to the docker
  echo "$file is running ..."                                                                                   #display the running testcase on the screen
  docker exec -i $name bash -c "systemctl stop firewalld.service;systemctl stop getty@tty1.service;\
  systemctl mask getty@tty1.service >/dev/null 2>&1" >/dev/null 2>&1                                            #stop firewall and getty service in docker
  docker exec -i $name bash -c "rpm -Uvh $package/$rpm1 --nodeps --force >/dev/null 2>&1;\
  rpm -Uvh $package/$rpm2 --nodeps --force >/dev/null 2>&1;\
  rpm -Uvh $package/$rpm3 --nodeps --force >/dev/null 2>&1 >/dev/null 2>&1" >/dev/null 2>&1                     #install openssl, openssl-devel, and openssl-libs 
  docker exec -i $name bash -c "find $package -name 'install.sh'|xargs sed -i '/add_port_to_firewall/'d"        #do not execute add_port_to_firewall function in docker
  docker exec -i $name bash -c "find $package -name 'install.sh'|xargs sed -i '/add_portlist_to_firewall/'d"    #do not execute add_portlist_to_firewall function in docker
  docker exec -i $name bash -c "find $package -name 'uninstall.sh'|xargs sed -i '/remove_all_port$/d'"          #do not execute remove_all_port function in docker
  docker exec -i $name bash -c "find $package -name 'uninstall.sh'|xargs sed -i '/remove_port$/d'"              #do not execute remove_port function in docker
  docker exec -i $name bash -c "find $package -name 'uninstall.sh'|xargs sed -i '/remove_port [PORT]*/d'"       #do not execute remove_port function in docker
  docker exec -i $name bash -c "cd $package;./${file} >$package/$result"                                        #run the testcase in docker and generate a report
  docker cp $name:$package/$result $PWD/$results/$rand$result                                                   #copy the testrun result from the docker to the host, and rename by prepending a random string
  docker cp $name:$package/$log_name $PWD/$log/$OS_Version$name.log                                             #copy the log from the docker to the host, and rename the log
  docker exec -t $name bash -c "if [ ! -f $log_fail_name ]; then exit 1; else exit 0; fi;"                      #determine if failed testcase log exists
  if [ $? -eq 0 ];then                                                                                          #only copy the failed testcase log from the docker to the host, and rename the log 
  docker cp $name:$package/$log_fail_name $PWD/$log_fail/$OS_Version$name.log
  fi
  cat $PWD/$results/$rand$result |tee -a $PWD/$results/$result                                                  #merge the testrun results in the results directory
  docker kill $name >/dev/null 2>&1                                                                             #stop the docker container  
  rm -rf $PWD/$results/$rand$result  $Dockerfile                                                                #remove the temporary test results
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

if [[ ! -n $(find $testcase_DIR/docker -name $file) ]]                                                          #find the testcase in testcase directory
        then
        echo "The specified testcase was not in the testcase directory. The testrun aborted."
        exit 1
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
rm -rf *_Dockerfile                                                                                             #remove all previous Dockerfile
rand=`openssl rand -hex 10`                                                                                     #generate a random string
OS=$file$rand                                                                                                   #the docker image name
name=$file$rand                                                                                                 #the docker name
prefix=`echo $file|cut -f 1 -d'_'`                                                                              #the prefix of the testcase name: can only be the following lowercase: db, es, la, sm                                      

#################################################################################################################
# These commands are configurations for different components, such as DB, ES, LA, SM, MQ, RE, and FS            #
#################################################################################################################
case $prefix in es)
if [ ! -f $package_DIR/$ES ];then                                                                               #determine if Elasticsearch installation package exists
echo "The Elasticsearch installation package was not found. The testrun aborted."
exit 1
fi
Dockerfile="ES_"$OS_Version"_Dockerfile"                                                                        #specify the Dockerfile for Elasticsearch
DIR_name=`gzip -dc $ES_path| tar tvf -|head -1|awk '{print $6}'|sed 's/.$//'`                                   #the unzipped installation package name for Elasticsearch
package="$installation_DIR/$DIR_name"                                                                           #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                               #invoke the create_Dockerfile function to create a Dockerfile for Elasticsearch
package_name=$ES                                                                                                #the installation package name
log_name="ES.log"                                                                                               #log name generated in Elasticsearch docker
log_fail_name="ES_fail.log"                                                                                     #log name generated in Elasticsearch docker if a testcase failed
run_Docker                                                                                                      #invoke run_Docker funtion to run an Elasticsearch testcase in docker
  ;;
la)
if [ ! -f $package_DIR/$LA ];then                                                                               #determine if License Agent installation package exists
echo "The License Agent installation package was not found. The testrun aborted."
exit 1
fi
Dockerfile="LA_"$OS_Version"_Dockerfile"                                                                        #specify the Dockerfile name for License Agent
DIR_name=`gzip -dc $LA_path| tar tvf -|head -1|awk '{print $6}'|sed 's/.$//'`                                   #the unzipped installation package name for License Agent
package="$installation_DIR/$DIR_name"                                                                           #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                               #invoke create_Dockerfile function to create a Dockerfile for License Agent
package_name=$LA                                                                                                #the installation package name
log_name="LA.log"                                                                                               #log name generated in License Agent docker
log_fail_name="LA_fail.log"                                                                                     #log name generated in License Agent docker if a testcase failed
run_Docker                                                                                                      #invoke run_Docker funtion to run a License Agent testcase in docker
  ;;
db)
if [ ! -f $package_DIR/$DB ];then                                                                               #determine if MongoDB installation package exists
echo "The MongoDB installation package was not found. The testrun aborted."
exit 1
fi
Dockerfile="DB_"$OS_Version"_Dockerfile"                                                                        #specify the Dockerfile name for MongoDB
DIR_name=`gzip -dc $DB_path| tar tvf -|head -1|awk '{print $6}'|sed 's/.$//'`                                   #the unzipped installation package name for MongoDB
package="$installation_DIR/$DIR_name"                                                                           #the installation package directory after unzipping the tar.gz file
create_Dockerfile                                                                                               #invoke the create_Dockerfile function to create a Dockerfile for MongoDB
package_name=$DB                                                                                                #the installation package name
log_name="DB.log"                                                                                               #log name generated in MongoDB docker
log_fail_name="DB_fail.log"                                                                                     #log name generated in MongoDB docker if a testcase failed
run_Docker                                                                                                      #invoke run_Docker funtion to run a MongoDB testcase in docker
  ;;
sm)
if [ ! -f $package_DIR/$SM ];then                                                                               #determine if Service Monitor Agent installation package exists
echo "The Service Monitor Agent installation package was not found. The testrun aborted."
exit 1
fi
Dockerfile="SM_"$OS_Version"_Dockerfile"                                                                        #specify the Dockerfile name for Service Monitor Agent
DIR_name=`gzip -dc $SM_path| tar tvf -|head -1|awk '{print $6}'|sed 's/.$//'`                                   #the unzipped installation package name for Service Monitor Agent
package="$installation_DIR/$DIR_name"                                                                           #the Service Monitor Agent installation package in docker
create_Dockerfile                                                                                               #invoke the create_Dockerfile function to create a Dockerfile for Service Monitor Agent 
package_name=$SM                                                                                                #the installation package name
log_name="SM.log"                                                                                               #log name generated in Service Monitor Agent docker
log_fail_name="SM_fail.log"                                                                                     #log name generated in Service Monitor Agent docker if a testcase failed
run_Docker                                                                                                      #invoke run_Docker funtion to run a Service Monitor Agent testcase in docker
  ;;
aa)
if [ ! -f $package_DIR/$AA ];then                                                                               #determine if Ansible Agent installation package exists
echo "The Ansible Agent installation package was not found. The testrun aborted."
exit 1
fi
Dockerfile="AA_"$OS_Version"_Dockerfile"                                                                        #specify the Dockerfile name for Ansible Agent
DIR_name=`gzip -dc $AA_path| tar tvf -|head -1|awk '{print $6}'|sed 's/.$//'`                                   #the unzipped installation package name for Ansible Agent
package="$installation_DIR/$DIR_name"                                                                           #the Ansible Agent installation package in docker
create_Dockerfile                                                                                               #invoke the create_Dockerfile function to create a Dockerfile for Ansible Agent
package_name=$AA                                                                                                #the installation package name
log_name="AA.log"                                                                                               #log name generated in Ansible Agent docker
log_fail_name="AA_fail.log"                                                                                     #log name generated in Ansible Agent docker if a testcase failed
run_Docker                                                                                                      #invoke run_Docker funtion to run an Ansible Agent testcase in docker
  ;;
mq)
if [ ! -f $package_DIR/$MQ ];then                                                                               #determine if RabbitMQ installation package exists
echo "The RabbitMQ installation package was not found. The testrun aborted."
exit 1
fi
Dockerfile="MQ_"$OS_Version"_Dockerfile"                                                                        #specify the Dockerfile name for RabbitMQ
DIR_name=`gzip -dc $MQ_path| tar tvf -|head -1|awk '{print $6}'|sed 's/.$//'`                                   #the unzipped installation package name for RabbitMQ
package="$installation_DIR/$DIR_name"                                                                           #the RabbitMQ installation package in docker
create_Dockerfile                                                                                               #invoke the create_Dockerfile function to create a Dockerfile for RabbitMQ
package_name=$MQ                                                                                                #the installation package name
log_name="MQ.log"                                                                                               #log name generated in RabbitMQ docker
log_fail_name="MQ_fail.log"                                                                                     #log name generated in RabbitMQ docker if a testcase failed
run_Docker                                                                                                      #invoke run_Docker funtion to run a RabbitMQ testcase in docker
  ;;
re)
if [ ! -f $package_DIR/$RE ];then                                                                               #determine if Redis installation package exists
echo "The Redis installation package was not found. The testrun aborted."
exit 1
fi
Dockerfile="RE_"$OS_Version"_Dockerfile"                                                                        #specify the Dockerfile name for Redis
DIR_name=`gzip -dc $RE_path| tar tvf -|head -1|awk '{print $6}'|sed 's/.$//'`                                   #the unzipped installation package name for Redis
package="$installation_DIR/$DIR_name"                                                                           #the Redis installation package in docker
create_Dockerfile                                                                                               #invoke the create_Dockerfile function to create a Dockerfile for Redis
package_name=$RE                                                                                                #the installation package name
log_fail_name="RE_fail.log"                                                                                     #log name generated in License Agent docker if a testcase failed
log_name="RE.log"                                                                                               #log name generated in Redis docker
run_Docker                                                                                                      #invoke run_Docker funtion to run a Redis testcase in docker
  ;; 
te)
  echo "This is reserved for Task Engine"
  ;; 
fs)
if [ ! -f $package_DIR/$FS ];then                                                                               #determine if Front Server installation package exists
echo "The Front Server installation package was not found. The testrun aborted."
exit 1
fi
Dockerfile="FS_"$OS_Version"_Dockerfile"                                                                        #specify the Dockerfile name for Front Server
DIR_name=`gzip -dc $FS_path| tar tvf -|head -1|awk '{print $6}'|sed 's/.$//'`                                   #the unzipped installation package name for Front Server
package="$installation_DIR/$DIR_name"                                                                           #the Front Server installation package in docker
create_Dockerfile                                                                                               #invoke the create_Dockerfile function to create a Dockerfile for Front Server
package_name=$FS                                                                                                #the installation package name
log_fail_name="FS_fail.log"                                                                                     #log name generated in Front Server docker if a testcase failed
log_name="FS.log"                                                                                               #log name generated in Front Server docker
run_Docker                                                                                                      #invoke run_Docker funtion to run a Front Server testcase in docker
  ;;   
 *)
  echo "The specified testcase is invalid. Make sure that the specified testcase name begins \
  with [db|es|la|sm|mq|re|te|fs|aa] lowercase. The testrun aborted."
  exit 1 
esac 

#################################################################################################################
# This command is for stopping docker image                                                                     #
#################################################################################################################
rm -rf $file                                                                                                    #remove temporary files
grep "passed" $PWD/$results/$result|sort -n|uniq>>$PWD/$results/$success                                        #split the testrun results to success.list
grep "failed" $PWD/$results/$result|sort -n|uniq>>$PWD/$results/$newfail                                        #split the testrun results to newfail.list
grep "timeout" $PWD/$results/$result|sort -n|uniq>>$PWD/$results/$timeout                                       #split the testrun results to timeout.list
sysctl -w vm.drop_caches=3 >/dev/null 2>&1                                                                      #release cache/buffer
echo -e "Elapsed time: $SECONDS seconds"                                                                        #display the testrun execution time on the screen
exit 0

