MLReef-CE AIO (All in One)
====================

Running the MLReef AIO
--------------------

To build the image execute: 
```bash
docker build --tag registry.gitlab.com/systemkern/gitlab-ce-preconfigured:latest .
```

To run the image locally execute:
```bash
docker run --detach --rm --name gitlab  \
    --hostname gitlab.example.com       \
    --publish 80:80                     \
    --publish 443:443                   \
    --publish 2222:22                   \
    --publish 127.0.0.1:5432:5432       \
    -e GITLAB_ROOT_PASSWORD=password    \
    -e DB_NAME="db_name"                \
    -e DB_USER="db_user"                \
    -e DB_PASS="db_password"            \
    registry.gitlab.com/systemkern/gitlab-ce-preconfigured:latest
```

To verify container status, it takes some time to come in healthy state
```bash
$ sudo docker ps -a
CONTAINER ID        IMAGE                COMMAND             CREATED             STATUS                   PORTS                                                                                      NAMES
bc4c269b8041        omnibus-pg1:latest   "/wrapper_script.sh"   15 minutes ago      Up 5 minutes (healthy)   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 127.0.0.1:5432->5432/tcp, 0.0.0.0:2222->22/tcp   gitlab
```

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
 db_name             | gitlab-psql | UTF8     | C.UTF-8 | C.UTF-8 | =Tc/"gitlab-psql"              +
                     |             |          |         |         | "gitlab-psql"=CTc/"gitlab-psql"+
                     |             |          |         |         | test_user=CTc/"gitlab-psql"
(5 rows)

postgres=# \du+
                                              List of roles
     Role name     |                         Attributes                         | Member of | Description
-------------------+------------------------------------------------------------+-----------+-------------
 gitlab            |                                                            | {}        |
 gitlab-psql       | Superuser, Create role, Create DB, Replication, Bypass RLS | {}        |
 gitlab_replicator | Replication                                                | {}        |
 db_user           | Create DB                                                  | {}        |


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


