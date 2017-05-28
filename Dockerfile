FROM centos:7

RUN yum install -y openldap-servers && \
    yum clean all

ADD assets/systemdse.ldif /etc/openldap/systemdse.ldif
ADD assets/entrypoint.sh /entrypoint.sh

LABEL io.openshift.tags=ldap,openldap \
      io.k8s.description="OpenLdap directory server" \
      io.openshift.expose-services="5000:ldap"

ENV ROOTDN_PASSWORD=secret

USER ldap
EXPOSE 5000
VOLUME /var/lib/ldap
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/slapd", "-h", "ldap://0.0.0.0:5000", "-d", "none", "-F", "/var/lib/ldap/conf"]
