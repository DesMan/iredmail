#!/usr/bin/env bash

# Author:   Zhang Huangbin <zhb(at)iredmail.org>

#---------------------------------------------------------------------
# This file is part of iRedMail, which is an open source mail server
# solution for Red Hat(R) Enterprise Linux, CentOS, Debian and Ubuntu.
#
# iRedMail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iRedMail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iRedMail.  If not, see <http://www.gnu.org/licenses/>.
#---------------------------------------------------------------------

# First domain name.
while : ; do
    ${DIALOG} \
    --title "Your first virtual domain name" \
    --inputbox "\
Please specify your first virtual domain name.

EXAMPLE:

    * example.com

WARNING:

    * It cannot be the same as server hostname: ${HOSTNAME}.
" 20 76 2>/tmp/first_domain

    FIRST_DOMAIN="$(cat /tmp/first_domain)"

    echo "${FIRST_DOMAIN}" | grep '\.' &>/dev/null
    [ X"$?" == X"0" ] && break
done

echo "export FIRST_DOMAIN='${FIRST_DOMAIN}'" >> ${CONFIG_FILE}
rm -f /tmp/first_domain

#DOMAIN_ADMIN_NAME
export DOMAIN_ADMIN_NAME='postmaster'
export SITE_ADMIN_NAME="${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}"
echo "export DOMAIN_ADMIN_NAME='${DOMAIN_ADMIN_NAME}'" >>${CONFIG_FILE}
echo "export SITE_ADMIN_NAME='${SITE_ADMIN_NAME}'" >>${CONFIG_FILE}

# DOMAIN_ADMIN_PASSWD
while : ; do
    ${DIALOG} \
    --title "Password for the administrator of your domain" \
    ${PASSWORDBOX} "\
Please specify password for the administrator user:

    * ${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}

Note:

    * You can login iRedAdmin with this account.

WARNING:

    * EMPTY password is *NOT* permitted.

" 20 76 2>/tmp/first_domain_admin_passwd

    DOMAIN_ADMIN_PASSWD="$(cat /tmp/first_domain_admin_passwd)"

    [ X"${DOMAIN_ADMIN_PASSWD}" != X"" ] && break
done

export DOMAIN_ADMIN_PASSWD_PLAIN="${DOMAIN_ADMIN_PASSWD}"
export SITE_ADMIN_PASSWD="${DOMAIN_ADMIN_PASSWD_PLAIN}"
echo "export DOMAIN_ADMIN_PASSWD_PLAIN='${DOMAIN_ADMIN_PASSWD}'" >> ${CONFIG_FILE}
echo "export DOMAIN_ADMIN_PASSWD='${DOMAIN_ADMIN_PASSWD}'" >> ${CONFIG_FILE}
echo "export SITE_ADMIN_PASSWD='${SITE_ADMIN_PASSWD}'" >> ${CONFIG_FILE}
rm -f /tmp/first_domain_admin_passwd

#FIRST_USER
export FIRST_USER='www'
echo "export FIRST_USER='${FIRST_USER}'" >>${CONFIG_FILE}

# FIRST_USER_PASSWD
while : ; do
    ${DIALOG} \
    --title "Password for your first user" \
    ${PASSWORDBOX} "\
Please specify password for your first user:

    * ${FIRST_USER}@${FIRST_DOMAIN}

Note:

    * You can login webmail with this account.

WARNING:

    * EMPTY password is *NOT* permitted.

" 20 76 2>/tmp/first_user_passwd

    FIRST_USER_PASSWD="$(cat /tmp/first_user_passwd)"
    [ X"${FIRST_USER_PASSWD}" != X"" ] && break
done

export FIRST_USER_PASSWD_PLAIN="${FIRST_USER_PASSWD}"
echo "export FIRST_USER_PASSWD='${FIRST_USER_PASSWD}'" >>${CONFIG_FILE}
echo "export FIRST_USER_PASSWD_PLAIN='${FIRST_USER_PASSWD_PLAIN}'" >>${CONFIG_FILE}
rm -f /tmp/first_user_passwd

#
# Set first mail user as alias for root.
#
export MAIL_ALIAS_ROOT="${FIRST_USER}@${FIRST_DOMAIN}"
echo "export MAIL_ALIAS_ROOT='${MAIL_ALIAS_ROOT}'" >> ${CONFIG_FILE}

cat >> ${TIP_FILE} <<EOF
Admin of domain ${FIRST_DOMAIN}:
    * Account: ${DOMAIN_ADMIN_NAME}@${FIRST_DOMAIN}
    * Password: ${DOMAIN_ADMIN_PASSWD_PLAIN}

    Note:
        - This account is used for system administrations, not a mail user.
        - You can login iRedAdmin with this account, login name
          is full email address.

First mail user:
    * Username: ${FIRST_USER}@${FIRST_DOMAIN}
    * Password: ${FIRST_USER_PASSWD}
    * SMTP/IMAP auth type: login
    * Connection security: STARTTLS or SSL/TLS

    Note:
        - This account is a normal mail user.
        - You can login webmail with this account, login name is full email address.

Alias for root user:
    * Alias address: ${MAIL_ALIAS_ROOT}
    * You can change it in file 'aliases' under postfix root directory. It should be:
        + /etc/postfix/aliases (Linux)
        + /usr/local/etc/postfix/aliases (FreeBSD)

EOF
