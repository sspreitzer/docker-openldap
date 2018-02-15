#!/bin/bash

set -x
set -e

if [ ! -f /var/lib/ldap/.done ]; then
echo "### Creating base configuration ###"
mkdir -p /var/lib/ldap/{conf,db/system}

CONF=/var/lib/ldap/conf/cn\=config
FRONTEND=olcDatabase\=\{-1\}frontend.ldif
CONFIG=olcDatabase\=\{0\}config.ldif
MONITOR=olcDatabase\=\{1\}monitor.ldif
HDB=olcDatabase\=\{2\}hdb.ldif

cp -r /etc/openldap/slapd.d/* /var/lib/ldap/conf/

sed -i "s|^olcDbDirectory: /var/lib/ldap$|olcDbDirectory: /var/lib/ldap/db/system|g" $CONF/$HDB
sed -i "s|^olcSuffix: .*|olcSuffix: dc=system|g" $CONF/$HDB
sed -i "s|^olcRootDN: .*|olcRootDN: cn=Manager,dc=system|g" $CONF/$HDB
echo "olcRootPW: ${ROOTDN_PASSWORD}" >> $CONF/$HDB

sed -i "s|^olcAccess: .*||g" $CONF/$CONFIG $CONF/$MONITOR $CONF/$HDB
sed -i "s|^ .*||g" $CONF/$CONFIG $CONF/$MONITOR $CONF/$HDB
sed -i '/^$/d' $CONF/$CONFIG $CONF/$MONITOR $CONF/$HDB
sed -i '/^\s*$/d' $CONF/$CONFIG $CONF/$MONITOR $CONF/$HDB

echo -e "olcAccess: {0}to * by dn.base=\"cn=Manager,dc=system\" manage by * none" >> $CONF/$CONFIG

echo -e "olcAccess: {0}to * by dn.base=\"cn=Manager,dc=system\" read by * none" >> $CONF/$MONITOR

echo -e "olcAccess: {0}to attrs=userPassword by dn.base=\"cn=Manager,dc=system\" manage by self write by users none by * auth" >> $CONF/$HDB
echo -e "olcAccess: {1}to * by dn.base="cn=Manager,dc=system" manage by users read by * auth" >> $CONF/$HDB


find /etc/openldap/schema -iname '*.ldif' -exec slapadd -F /var/lib/ldap/conf -d none -b cn=config -l {} 2>/dev/null \;

echo "### Creating additional rootdse ###"
if [ "$ROOTDSE" != "" ]; then
  /usr/sbin/slapd -h ldap://127.0.0.1:5000 -d none -F /var/lib/ldap/conf &
  sleep 3

  for i in $ROOTDSE; do
    mkdir -p /var/lib/ldap/db/${i}

    ldapadd -x -D cn=Manager,dc=system -w "$ROOTDN_PASSWORD" -H ldap://127.0.0.1:5000 <<_EOF_
dn: olcDatabase=hdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: hdb
olcDbDirectory: /var/lib/ldap/db/${i}
olcSuffix: ${i}
olcDbIndex: objectClass eq,pres
olcDbIndex: ou,cn,mail,surname,givenname eq,pres,sub
olcAccess: {0}to attrs=userPassword by dn.base="cn=Manager,dc=system" manage by self write by users none by * auth
olcAccess: {1}to * by dn.base=cn=Manager,dc=system manage by users read by * auth


_EOF_
  done

  kill %1
  sleep 1
fi

touch /var/lib/ldap/.done
fi

echo "### Starting up ###"
exec $*
