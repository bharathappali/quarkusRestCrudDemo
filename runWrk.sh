#!/usr/bin/env bash

exec > vmrunc.txt

for USERS in 1 5 10 15 20 25 30 35 40
do
  echo "Runnning with $USERS users"
	for run in {1..2}
   do
		wrk --threads=$USERS --connections=$USERS -d60s http://192.168.122.36:8080/fruits;
	done
done
