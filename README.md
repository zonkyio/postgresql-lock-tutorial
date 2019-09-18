# PostgreSQL lock simulator
Create environment where everyone can test how to resolve PostgreSQL lock issue.
 * requirements: docker, Unix(Linux or Mac), bash

Start: Download file and run.



# How to find who on local system take lock
```
postgres=# SELECT client_addr,client_port FROM pg_stat_activity WHERE pid = 5232;
 client_addr | client_port
-------------+-------------
 127.0.0.1   |       56586


root@db01 ~ # netstat -ntp | grep 56586
tcp        0      0 127.0.0.1:5432          127.0.0.1:56586         ESTABLISHED 5232/postgres: postgres postgres 1
tcp        0      0 127.0.0.1:56586         127.0.0.1:5432          ESTABLISHED 37244/1

root@db0 ~ # cat /proc/37244/cmdline
sshd: ondrej.prochazka@pts/1
```

# How to stop query and release locks

We’ll use the pids we found from the earlier queries:

```
design_system=> SELECT pg_cancel_backend(11929);
 pg_cancel_backend
-------------------
 t
(1 row)
```

This feedback, unfortunately neither accurately indicates success or failure. Instead, you’ll likely have to check locks by previous queries to determine if the process is still active.

That was the nice way to ask (ie, pg_cancel_backend). The more forceful method is:

```
design_system=> SELECT pg_terminate_backend(11929);
 pg_terminate_backend
----------------------
 t
(1 row)
```
!!! Warning: pg_terminate_backend will stop all postgres process and be reason for recovery mode with rollback to last savepoint. 
