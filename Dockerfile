FROM ${IMAGE}

RUN yum install -y openldap-servers openldap-clients && \
    yum clean all

ADD assets/entrypoint.sh /entrypoint.sh

LABEL io.openshift.tags=ldap,openldap \
      io.k8s.description="OpenLdap directory server" \
      io.openshift.expose-services="5000:ldap"

ENV ROOTDN_PASSWORD=secret \
    ROOTDSE=""

USER ldap
EXPOSE 5000
VOLUME /var/lib/ldap
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/slapd", "-h", "ldap://0.0.0.0:5000", "-d", "none", "-F", "/var/lib/ldap/conf"]
