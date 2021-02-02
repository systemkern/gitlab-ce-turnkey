# https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/docker
FROM gitlab/gitlab-ce:latest
MAINTAINER Systemkern

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


###
### Modify Gitlab Omnibus wrapper script
###
# Insert the prepare-env script before Gitlab's omnibus wrapper
# Insert the register-runner before the "deamonizing" in the
# original wrapper
ADD assets/ /assets/
RUN mv /assets/wrapper /assets/omnibus-wrapper              && \
    cat > /assets/wrapper < /assets/prepare-env             && \
    head -n -6 /assets/omnibus-wrapper >> /assets/wrapper   && \
    cat >> /assets/wrapper < /assets/register-runner        && \
    tail -n -6 /assets/omnibus-wrapper >> /assets/wrapper
RUN chmod +x /assets/wrapper
RUN cat /assets/wrapper


# Volumes defined by parent image:
# VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]
# Expose the Gitlab runners' configuration
VOLUME ["/etc/gitlab-runner/"]

# Wrapper to handle additional script to run after default gitlab image's /assets/wrapper
CMD ["/assets/wrapper"]
