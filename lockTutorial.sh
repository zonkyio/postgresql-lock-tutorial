#!/bin/bash

docker ps -a 1>/dev/null 2>&1
if [ $? != 0 ]; then 
 echo "Sorry, but i need Docker installed. :( "
fi

docker stop -t 2 psqlLock 1>/dev/null 2>&1
export DockerID=$(docker run --rm --name psqlLock -d postgres:9.6.8)

echo "Waiting 20s for PostgresqDocker startup";
sleep 20s;

docker exec psqlLock /usr/bin/psql -U postgres -d postgres \
 -c """
 CREATE TABLE weather (
     city            varchar(80),
     temp_lo         int,           -- low temperature
     temp_hi         int,           -- high temperature
     prcp            real,          -- precipitation
     date            date
);

CREATE TABLE cities ( name varchar(80), location point);

INSERT INTO weather VALUES ('San Francisco', 46, 50, 0.25, '1994-11-27');
INSERT INTO cities VALUES ('San Francisco', '(-194.0, 53.0)');
INSERT INTO weather (date, city, temp_hi, temp_lo) VALUES ('1994-11-29', 'Hayward', 54, 37);
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date) VALUES ('San Francisco', 43, 57, 0.0, '1994-11-29');
""" 1>/dev/null 2>&1

echo " WRONG TRANSACTION: BEGIN; select * from weather; SELECT * FROM cities; SELECT pg_sleep(600);"
# Transaction with sleep 600 s. Don't bloc any SELECT,INSERT,UPDATE or DELETE action
docker exec psqlLock /usr/bin/psql -U postgres -d postgres \
 -c "BEGIN; select * from weather; SELECT * FROM cities; SELECT pg_sleep(600); END;" 1>/dev/null 2>&1  &

sleep 2s;

# Need to create Exclusive Lock, so waiting to all easy locks to end
docker exec psqlLock /usr/bin/psql -U postgres -d postgres \
 -c "ALTER TABLE cities ADD quality int;" 1>/dev/null 2>&1 &

sleep 2s;

for I in $(seq 1 10); do 
 # SELECT waiting to done ALTER
 docker exec psqlLock /usr/bin/psql -U postgres -d postgres \
  -c "select * from cities LIMIT ${I};" 1>/dev/null 2>&1 &
done

sleep 1s;
echo "      -------- Locks ----------------"
docker exec psqlLock /usr/bin/psql -U postgres -d postgres \
 -c """
select pid,
       usename,
       pg_blocking_pids(pid) as blocked_by,
       query as blocked_query
from pg_stat_activity
where cardinality(pg_blocking_pids(pid)) > 0;
"""

echo """

        Try to find which PID is problem.

 ---- This show you locks:
 SELECT pid,usename,pg_blocking_pids(pid) as blocked_by,query as blocked_query
  FROM pg_stat_activity WHERE cardinality(pg_blocking_pids(pid)) > 0;

 ---- This show concrete PID info:
 SELECT backend_start,query,state FROM pg_stat_activity WHERE pid = ___PID___;


 ---- cancels the running query by PID
 SELECT pg_cancel_backend(_____PID____);

 ---- IF cancels is NOT enough, then
 ---- terminates the entire process and thus the database connection
 SELECT pg_terminate_backend( _____PID____ );

 ----- This is your command line:
"""

docker exec -it psqlLock /usr/bin/psql -U postgres -d postgres

docker stop -t 2 psqlLock
echo "Clear docker: .. done"
