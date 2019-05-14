# PostgreSQL lock tutorial 
Show example how to resolve PostgreSQL lock issue
 * requirements: docker, Unix(Linux or Mac), bash

Start: Download file and run.



# How to find who on local system take lock
```postgres=# SELECT client_addr,client_port FROM pg_stat_activity WHERE pid = 5232;
 client_addr | client_port
-------------+-------------
 127.0.0.1   |       56586


root@db01 ~ # netstat -ntp | grep 56586
tcp        0      0 127.0.0.1:5432          127.0.0.1:56586         ESTABLISHED 5232/postgres: postgres postgres 1
tcp        0      0 127.0.0.1:56586         127.0.0.1:5432          ESTABLISHED 37244/1

root@db0 ~ # cat /proc/37244/cmdline
sshd: ondrej.prochazka@pts/1
```
