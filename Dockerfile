# https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/docker
FROM gitlab/gitlab-ce:12.7.0-ce.0
MAINTAINER Systemkern

ENV PGCONF_TEMP /opt/gitlab/embedded/cookbooks/postgresql/templates/default/postgresql.conf.erb
ENV PGCONF /opt/gitlab/etc/gitlab.rb.template

ADD configuration-wrapper.sh configure.sh /
RUN chmod +x /configuration-wrapper.sh /configure.sh

# Provide executable permission to script files
# Edit the Postgres configuration to be able external access to the Database
# The original line in PGCONF_TEMP is
#     listen_addresses = '<%= @listen_address %>'    # what IP address(es) to listen on;
# The original line in PGCONF is
RUN sed -i  "s/<%= @listen_address %>/*/g" ${PGCONF_TEMP}      && \
    sed -i "s/#.*postgresql.*trust_auth_cidr_addresses.*/postgresql\['trust_auth_cidr_addresses'\] = \[\"0\.0\.0\.0\/0\"\]/g" ${PGCONF}

# Expose postgres
EXPOSE 5432


# Wrapper to handle additional script to run after default gitlab image's /assets/wrapper
CMD ["/configuration-wrapper.sh"]

