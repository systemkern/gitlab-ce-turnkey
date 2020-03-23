MLReef-CE AIO (All in One)
====================

Running the MLReef AIO
--------------------

Execute following commands in sequence:
```bash
docker build --tag mlreef-ce:latest .

docker run --detach --hostname gitlab.example.com --publish 443:443 --publish 80:80 --publish 2222:22 --publish 127.0.0.1:5432:5432 --name gitlab --restart always mlreef-ce:latest

docker ps -a #to verify container status, it takes some time to come in helthy state
```


$ sudo docker ps -a
CONTAINER ID        IMAGE                COMMAND             CREATED             STATUS                   PORTS                                                                                      NAMES
bc4c269b8041        omnibus-pg1:latest   "/assets/wrapper"   15 minutes ago      Up 5 minutes (healthy)   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 127.0.0.1:5432->5432/tcp, 0.0.0.0:2222->22/tcp   gitlab

### Verify Db connection from outside of container
```
$ psql -p 5432 -h localhost -U gitlab-psql postgres
psql (11.7 (Ubuntu 11.7-2.pgdg16.04+1), server 10.12)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.
postgres=# \l
                                         List of databases
        Name         |    Owner    | Encoding | Collate |  Ctype  |        Access privileges        
---------------------+-------------+----------+---------+---------+---------------------------------
 gitlabhq_production | gitlab      | UTF8     | C.UTF-8 | C.UTF-8 | 
 postgres            | gitlab-psql | UTF8     | C.UTF-8 | C.UTF-8 | 
 template0           | gitlab-psql | UTF8     | C.UTF-8 | C.UTF-8 | =c/"gitlab-psql"               +
                     |             |          |         |         | "gitlab-psql"=CTc/"gitlab-psql"
 template1           | gitlab-psql | UTF8     | C.UTF-8 | C.UTF-8 | =c/"gitlab-psql"               +
                     |             |          |         |         | "gitlab-psql"=CTc/"gitlab-psql"
(4 rows)

postgres=# show data_directory;
         data_directory          
---------------------------------
 /var/opt/gitlab/postgresql/data
(1 row)

postgres=# select version();
                                                     version                                                      
------------------------------------------------------------------------------------------------------------------
 PostgreSQL 10.12 on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 5.4.0-6ubuntu1~16.04.12) 5.4.0 20160609, 64-bit
(1 row)

postgres=# 
```


### Verify the application

in you browser navigate to http://localhost/




