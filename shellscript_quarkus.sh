#!/bin/sh

#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------Shell script to run quarkusRestcrud-------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------

#file to store first response time for both runc and kata
LOG_FILE='first_response.txt'

#function to run WRK benchmark
run_benchmark() {

for USERS in 1 5 10 15 20 25 30 35 40
do
  echo "Runnning with $USERS users"
	for run in {1..2}
   do
		wrk --threads=$USERS --connections=$USERS -d60s http://localhost:8080/fruits 2>&1 | tee -a ./$1
	done
done

}

#function to run DB container
run_DB_container() {

docker run --runtime=runc --ulimit memlock=-1:-1 -d -it --rm=true --memory-swappiness=0 --name postgres-quarkus-rest-http-crud -e POSTGRES_USER=restcrud -e POSTGRES_PASSWORD=restcrud -e POSTGRES_DB=rest-crud -p 5432:5432 postgres:10.5

}


#function to check the status code of localhost/fruits
check_status_200() {

bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:8080/fruits)" != "200" ]]; do sleep .001; done' &

}


#function to run App Container using runc
run_App_Container_runc() {

echo "------------------------------runc first response-----------------------------------------" >> ${LOG_FILE}

(date +"%T.%3N" && docker run --rm -d --runtime=runc --name=runc_quarkus -p 8080:8080 --network host rest-crud-quarkus-jvm) >> ${LOG_FILE}

sleep 30s

docker logs runc_quarkus >> ${LOG_FILE}

#calling to record runc performance
run_benchmark "runc_benchmark_results.log"

docker stop runc_quarkus

}


#function to run App Container using kata-runtime
run_App_Container_kata() {

echo "------------------------------kata-runtime first response-----------------------------------------" >> ${LOG_FILE}

(date +"%T.%3N" && docker run --rm -d --runtime=kata-runtime --name kata_quarkus -p 8080:8080 rest-crud-quarkus-jvm) >> ${LOG_FILE}

sleep 1m

docker logs kata_quarkus >> ${LOG_FILE}

#calling to record kata performance
run_benchmark "kata_benchmark_results.log"

docker stop kata_quarkus

}

#cloning git repository
git clone https://github.com/Ashwinira/quarkusRestCrudDemo.git

cd quarkusRestCrudDemo/quarkus

#building jar file and then docker image
mvn clean package -Dno-native && docker build -f Dockerfile-quarkus-jvm -t rest-crud-quarkus-jvm .

cd -
#calling funtion to run DB container
run_DB_container

sleep 1m

#checking status using curl
check_status_200

#calling function to run App container using runc runtime
run_App_Container_runc


check_status_200

#calling function to run App container using kata-runtime
run_App_Container_kata

#stopping the DB container
docker stop postgres-quarkus-rest-http-crud
