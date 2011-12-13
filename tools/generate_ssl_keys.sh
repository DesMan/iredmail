#!/usr/bin/env bash

# Author:   Zhang Huangbin (zhb(at)iredmail.org)
# Purpose:  Create new SSL keys.
# Project:  iRedMail (http://www.iredmail.org/)

# USAGE:
# 1) Edit variables which starts with TLS_ below, then save file.
# 2) Execute shell command:
#
#       # bash generate_ssl_keys.sh
#
#    It will create two new files under CURRENT directory:
#
#       - certs/iRedMail_CA.pem: Used to replace file on iRedMail server:
#           + on RHEL/CentOS/Scientific Linux: /etc/pki/tls/certs/iRedMail_CA.pem
#           + on Debian/Ubuntu/openSUSE: /etc/ssl/certs/iRedMail_CA.pem
#           + on FreeBSD: /etc/ssl/certs/iRedMail_CA.pem
#       - private/iRedMail.key: Used to replace file on iRedMail server:
#           + on RHEL/CentOS/Scientific Linux: /etc/pki/tls/private/iRedMail.key
#           + on Debian/Ubuntu/openSUSE: /etc/ssl/private/iRedMail.key
#           + on FreeBSD: /etc/ssl/private/iRedMail.key
#
# 3) Grant read access to all users. e.g. on RHEL/CentOS/Scientific Linux:
#
#   # chmod +r /etc/ssl/certs/iRedMail_CA.pem
#   # chmod +r /etc/ssl/private/iRedMail.key
#
#   If you need more restrict file permission, please use file system ACL instead.
#   Refer to command 'setfacl' and 'getfacl' for more detail.
#
# 4) Restart all services which provides SSL secure connection. e.g. http,
#    dovecot, postfix, etc. A system reboot should be easier if possible.
#

export HOSTNAME="$(hostname -f)"

# SSL key related settings.
# Country.
export TLS_COUNTRY='CN'

# State.
export TLS_STATE='GuangDong'

# City.
export TLS_CITY='ShenZhen'

# Company name here, e.g. Apple Inc.
export TLS_COMPANY="${HOSTNAME}"

# Department name.
export TLS_DEPARTMENT='IT'

# Hostname of your mail server.
export TLS_HOSTNAME="${HOSTNAME}"

# Server admininistrator's email address.
export TLS_ADMIN="root@${HOSTNAME}"

# Do not edit below lines.
export ROOTDIR="$(pwd)"
export SSL_CERT_FILE="${ROOTDIR}/certs/iRedMail_CA.pem"
export SSL_KEY_FILE="${ROOTDIR}/private/iRedMail.key"

# Create SSL certs/private files.
gen_pem_key()
{
    # Create necessary directories.
    mkdir -p {certs,private} 2>/dev/null

    openssl req \
        -x509 -nodes -days 3650 -newkey rsa:2048 \
        -subj "/C=${TLS_COUNTRY}/ST=${TLS_STATE}/L=${TLS_CITY}/O=${TLS_COMPANY}/OU=${TLS_DEPARTMENT}/CN=${TLS_HOSTNAME}/emailAddress=${TLS_ADMIN}/" \
        -out ${SSL_CERT_FILE} -keyout ${SSL_KEY_FILE} >/dev/null 2>&1

    # Set correct file permission.
    chmod 0444 ${SSL_CERT_FILE}
    chmod 0444 ${SSL_KEY_FILE}
}

gen_pem_key && cat <<EOF
SSL keys were generated:
    - ${SSL_CERT_FILE}
    - ${SSL_KEY_FILE}
EOF
