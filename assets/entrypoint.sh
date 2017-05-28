#!/bin/bash

set -e

if [ ! -f /var/lib/ldap/.done ]; then
mkdir -p /var/lib/ldap/{conf,system}

CONF=/etc/openldap/slapd.d/cn\=config
FRONTEND=olcDatabase\=\{-1\}frontend.ldif
CONFIG=olcDatabase\=\{0\}config.ldif
MONITOR=olcDatabase\=\{1\}monitor.ldif
HDB=olcDatabase\=\{2\}hdb.ldif

sed -i "s|^olcDbDirectory: /var/lib/ldap$|olcDbDirectory: /var/lib/ldap/system|g" $CONF/$HDB
sed -i "s|^olcSuffix: .*|olcSuffix: dc=system|g" $CONF/$HDB
sed -i "s|^olcRootDN: .*|olcRootDN: cn=Manager,dc=system|g" $CONF/$HDB
echo "olcRootPW: ${ROOTDN_PASSWORD}" >> $CONF/$HDB

sed -i "s|^olcAccess: .*||g" $CONF/$CONFIG $CONF/$MONITOR $CONF/$HDB
sed -i "s|^ .*||g" $CONF/$CONFIG $CONF/$MONITOR $CONF/$HDB
sed -i '/^$/d' $CONF/$CONFIG $CONF/$MONITOR $CONF/$HDB
sed -i '/^\s*$/d' $CONF/$CONFIG $CONF/$MONITOR $CONF/$HDB

echo -e "olcAccess: {0}to * by dn.base=\"cn=Manager,dc=system\" manage by * none" >> $CONF/$CONFIG
echo -e "olcAccess: {0}to * by dn.base=\"cn=Manager,dc=system\" read by * none" >> $CONF/$MONITOR

echo -e "olcAccess: {0}to * by dn.base=\"cn=Manager,dc=system\" manage" >> $CONF/$HDB
echo -e "olcAccess: {1}to attrs=userPassword by self write by users none by * auth" >> $CONF/$HDB
echo -e "olcAccess: {2}to * by users read" >> $CONF/$HDB
echo -e "olcAccess: {3}to * by * auth" >> $CONF/$HDB

cp -r /etc/openldap/slapd.d/* /var/lib/ldap/conf/

slapadd -F /var/lib/ldap/conf -l /etc/openldap/systemdse.ldif
find /etc/openldap/schema -iname '*.ldif' -exec slapadd -F /var/lib/ldap/conf -n 0 -l {} \;

touch /var/lib/ldap/.done
fi

exec $*
