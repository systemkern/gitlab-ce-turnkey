# https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/docker
FROM gitlab/gitlab-ce:latest
MAINTAINER Systemkern

ENV PGCONF_TEMP /opt/gitlab/embedded/cookbooks/postgresql/templates/default/postgresql.conf.erb
ENV PGCONF /opt/gitlab/etc/gitlab.rb.template

###
### GITLAB RUNNER
###
# Install Gitlab Runner in Docker container
# https://docs.gitlab.com/runner/install/linux-manually.html
RUN apt-get update                          && \
    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | bash  && \
    apt-get install --yes gitlab-runner     && \
    apt-get clean                           && \
    gitlab-runner --version
ADD assets/ /assets/
RUN chmod +x /assets/turnkey-wrapper.sh


# Volumes defined by parent image:
# VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# Wrapper to handle additional script to run after default gitlab image's /assets/wrapper
CMD ["/assets/turnkey-wrapper.sh"]