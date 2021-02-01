Gitlab CE Turnkey Edition 🗝
====================

![Logo](public/logo/gitlab-turnkey-logo.png)

This Project helps in building a gitlab installation which is already preconfigured out of the box.

This is achieved by allowing access to the postgres database, as well as by creating users and ci-runner registration tokens

Further information can be found in the [official Gitlab documentation](https://docs.gitlab.com/omnibus/maintenance/)


**Canonical source:**
This project's canonical source where all development takes place is hosted on [gitLab.com/systemkern/gitlab-ce-turnkey](https://gitlab.com/systemkern/gitlab-ce-turnkey).

**Contribution:**
Contributions in the form of bug reports, feature requests, and merge requests are welcome.


Getting started
--------------------
To run the latest image from the registry:
```bash
docker run --rm -it --name gitlab-turnkey               \
    --network  bridge                                   \
    --hostname gitlab.example.com                       \
    --publish "80:80"                                   \
    --publish "443:443"                                 \
    --publish "2222:22"                                 \
    --publish "127.0.0.1:5432:5432"                     \
    --volume /var/run/docker.sock:/var/run/docker.sock  \
    --volume gitlab-opt:/var/opt                        \
    --env GITLAB_ROOT_PASSWORD=password                 \
    --env POSTGRES_SERVICE_HOST_NAME=localhost          \
    --env DB_NAME="gitlabhq_production"                 \
    --env DB_USER="gitlab"                              \
    --env POSTGRES_USER="gitlab-psql"                   \
    --env POSTGRES_PASSWORD="securesqlpassword"         \
    --env GITLAB_ADMIN_TOKEN="test-admin-token"         \
    --env GITLAB_SECRETS_DB_KEY_BASE="secret11111111112222222222333333333344444444445555555555666666666612345" \
  gitlab-ce-turnkey:latest
```

### Verify the application

In you browser navigate to http://localhost/



### Environment

To verify container status, it takes some time to come in healthy state
```bash
$ sudo docker ps -a
CONTAINER ID        IMAGE                      COMMAND             CREATED             STATUS                   PORTS                                                                                      NAMES
bc4c269b8041        gitlab-ce-turnkey:latest   "/wrapper_script.sh"   15 minutes ago      Up 5 minutes (healthy)   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 127.0.0.1:5432->5432/tcp, 0.0.0.0:2222->22/tcp   gitlab
```



Building the Image
--------------------
To build and run the image locally execute: `bin/build-run`


Why
--------------------
[Read here](https://about.gitlab.com/why/)


Is it any good?
--------------------
[Yes](https://news.ycombinator.com/item?id=3067434)
