# https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/docker
FROM gitlab/gitlab-ce:latest
MAINTAINER Systemkern


###
### Modify Gitlab Omnibus script
###
RUN mv /assets/wrapper /assets/gitlab-wrapper
# Remove the wait for sigterm from the gitlab wrapper script to make it "interactive"
# The our own wrapper will handle starting and stopping of services
RUN sed -i "/# Tail all logs/d" /assets/gitlab-wrapper
RUN sed -i "/# gitlab-ctl tail &/d" /assets/gitlab-wrapper
RUN sed -i "/# Wait for SIGTERM/d" /assets/gitlab-wrapper
RUN sed -i "/wait/d" /assets/gitlab-wrapper


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

# Volumes defined by parent image:
# VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# Wrapper to handle additional script to run after default gitlab image's /assets/wrapper
CMD ["/assets/turnkey-wrapper.sh"]
