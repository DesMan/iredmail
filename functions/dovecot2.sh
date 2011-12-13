#!/usr/bin/env bash

# Author:   Zhang Huangbin (zhb(at)iredmail.org)

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

# -------------------------------------------------------
# Dovecot & dovecot-sieve.
# -------------------------------------------------------

dovecot2_config()
{
    ECHO_INFO "Configure Dovecot (pop3/imap server)."

    [ X"${ENABLE_DOVECOT}" == X"YES" ] && \
        backup_file ${DOVECOT_CONF} && \
        chmod 0664 ${DOVECOT_CONF} && \
        ECHO_DEBUG "Configure dovecot: ${DOVECOT_CONF}."

        cat > ${DOVECOT_CONF} <<EOF
${CONF_MSG}
EOF

    cat ${SAMPLE_DIR}/conf/dovecot2.conf >> ${DOVECOT_CONF}

    # Base directory.
    perl -pi -e 's#PH_BASE_DIR#$ENV{DOVECOT_BASE_DIR}#' ${DOVECOT_CONF}

    # Provided services.
    export DOVECOT_PROTOCOLS
    perl -pi -e 's#PH_PROTOCOLS#$ENV{DOVECOT_PROTOCOLS}#' ${DOVECOT_CONF}

    # Set correct uid/gid.
    perl -pi -e 's#PH_MAIL_UID#$ENV{VMAIL_USER_UID}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_MAIL_GID#$ENV{VMAIL_USER_GID}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_FIRST_VALID_UID#$ENV{VMAIL_USER_UID}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_LAST_VALID_UID#$ENV{VMAIL_USER_UID}#' ${DOVECOT_CONF}

    # Log file.
    perl -pi -e 's#PH_LOG_PATH#$ENV{DOVECOT_LOG_FILE}#' ${DOVECOT_CONF}

    # Authentication related settings.
    # Append this domain name if client gives empty realm.
    perl -pi -e 's#PH_AUTH_DEFAULT_REALM#$ENV{FIRST_DOMAIN}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_AUTH_MECHANISMS#PLAIN LOGIN#' ${DOVECOT_CONF}

    # service auth {}
    perl -pi -e 's#PH_DOVECOT_AUTH_USER#$ENV{POSTFIX_DAEMON_USER}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_DOVECOT_AUTH_GROUP#$ENV{POSTFIX_DAEMON_GROUP}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_AUTH_MASTER_USER#$ENV{VMAIL_USER_NAME}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_AUTH_MASTER_GROUP#$ENV{VMAIL_GROUP_NAME}#' ${DOVECOT_CONF}

    # Virtual mail accounts.
    # Reference: http://wiki2.dovecot.org/AuthDatabase/LDAP
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        perl -pi -e 's#PH_USERDB_ARGS#$ENV{DOVECOT_LDAP_CONF}#' ${DOVECOT_CONF}
        perl -pi -e 's#PH_USERDB_DRIVER#ldap#' ${DOVECOT_CONF}
        perl -pi -e 's#PH_PASSDB_ARGS#$ENV{DOVECOT_LDAP_CONF}#' ${DOVECOT_CONF}
        perl -pi -e 's#PH_PASSDB_DRIVER#ldap#' ${DOVECOT_CONF}
    else
        # MySQL.
        perl -pi -e 's#PH_USERDB_ARGS#$ENV{DOVECOT_MYSQL_CONF}#' ${DOVECOT_CONF}
        perl -pi -e 's#PH_USERDB_DRIVER#sql#' ${DOVECOT_CONF}
        perl -pi -e 's#PH_PASSDB_ARGS#$ENV{DOVECOT_MYSQL_CONF}#' ${DOVECOT_CONF}
        perl -pi -e 's#PH_PASSDB_DRIVER#sql#' ${DOVECOT_CONF}
    fi

    perl -pi -e 's#PH_AUTH_SOCKET_PATH#$ENV{DOVECOT_AUTH_SOCKET_PATH}#' ${DOVECOT_CONF}

    # Quota.
    perl -pi -e 's#PH_QUOTA_TYPE#$ENV{DOVECOT_QUOTA_TYPE}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_QUOTA_WARNING_SCRIPT#$ENV{DOVECOT_QUOTA_WARNING_SCRIPT}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_QUOTA_WARNING_USER#$ENV{VMAIL_USER_NAME}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_QUOTA_WARNING_GROUP#$ENV{VMAIL_GROUP_NAME}#' ${DOVECOT_CONF}

    # Quota dict.
    perl -pi -e 's#PH_SERVICE_DICT_USER#$ENV{VMAIL_USER_NAME}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_SERVICE_DICT_GROUP#$ENV{VMAIL_GROUP_NAME}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_DOVECOT_REALTIME_QUOTA_SQLTYPE#$ENV{DOVECOT_REALTIME_QUOTA_SQLTYPE}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_DOVECOT_REALTIME_QUOTA_CONF#$ENV{DOVECOT_REALTIME_QUOTA_CONF}#' ${DOVECOT_CONF}

    # Sieve.
    perl -pi -e 's#PH_SIEVE_DIR#$ENV{SIEVE_DIR}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_SIEVE_RULE_FILENAME#$ENV{SIEVE_RULE_FILENAME}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_GLOBAL_SIEVE_FILE#$ENV{GLOBAL_SIEVE_FILE}#' ${DOVECOT_CONF}

    # SSL.
    perl -pi -e 's#PH_ENABLE_SSL#yes#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_SSL_CERT#<$ENV{SSL_CERT_FILE}#' ${DOVECOT_CONF}
    perl -pi -e 's#PH_SSL_KEY#<$ENV{SSL_KEY_FILE}#' ${DOVECOT_CONF}

    # Generate dovecot quota warning script.
    mkdir -p $(dirname ${DOVECOT_QUOTA_WARNING_SCRIPT}) 2>/dev/null

    backup_file ${DOVECOT_QUOTA_WARNING_SCRIPT}
    rm -f ${DOVECOT_QUOTA_WARNING_SCRIPT} 2>/dev/null
    cp -f ${SAMPLE_DIR}/conf/dovecot2-quota-warning.sh ${DOVECOT_QUOTA_WARNING_SCRIPT}

    export DOVECOT_DELIVER HOSTNAME
    perl -pi -e 's#PH_DOVECOT_DELIVER#$ENV{DOVECOT_DELIVER}#' ${DOVECOT_QUOTA_WARNING_SCRIPT}
    perl -pi -e 's#PH_HOSTNAME#$ENV{HOSTNAME}#' ${DOVECOT_QUOTA_WARNING_SCRIPT}

    chown root ${DOVECOT_QUOTA_WARNING_SCRIPT}
    chmod 0755 ${DOVECOT_QUOTA_WARNING_SCRIPT}

    # Use '/usr/local/bin/bash' as shabang line, otherwise quota waning will be failed.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        perl -pi -e 's#(.*)/usr/bin/env bash.*#${1}/usr/local/bin/bash#' ${DOVECOT_QUOTA_WARNING_SCRIPT}
    fi

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        backup_file ${DOVECOT_LDAP_CONF}
        cat > ${DOVECOT_LDAP_CONF} <<EOF
${CONF_MSG}
hosts           = ${LDAP_SERVER_HOST}:${LDAP_SERVER_PORT}
ldap_version    = 3
auth_bind       = yes
dn              = ${LDAP_BINDDN}
dnpass          = ${LDAP_BINDPW}
base            = ${LDAP_BASEDN}
scope           = subtree
deref           = never
user_filter     = (&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=%Ls%Lc)(|(${LDAP_ATTR_USER_RDN}=%u)(&(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_SHADOW_ADDRESS})(${LDAP_ATTR_USER_SHADOW_ADDRESS}=%u))))
user_attrs      = mail=user,${LDAP_ATTR_USER_HOME_DIRECTORY}=home,mailMessageStore=mail=maildir:${STORAGE_BASE_DIR}/%\$/Maildir/,${LDAP_ATTR_USER_QUOTA}=quota_rule=*:bytes=%\$
pass_filter     = (&(objectClass=${LDAP_OBJECTCLASS_MAILUSER})(${LDAP_ATTR_ACCOUNT_STATUS}=${LDAP_STATUS_ACTIVE})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=%Ls%Lc)(|(${LDAP_ATTR_USER_RDN}=%u)(&(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_SHADOW_ADDRESS})(${LDAP_ATTR_USER_SHADOW_ADDRESS}=%u))))
pass_attrs      = mail=user,${LDAP_ATTR_USER_PASSWD}=password
default_pass_scheme = CRYPT
EOF

        # Set file permission.
        chmod 0500 ${DOVECOT_LDAP_CONF}

    else

        backup_file ${DOVECOT_MYSQL_CONF}
        cat > ${DOVECOT_MYSQL_CONF} <<EOF
driver = mysql
default_pass_scheme = CRYPT
connect = host=${MYSQL_SERVER} dbname=${VMAIL_DB} user=${MYSQL_BIND_USER} password=${MYSQL_BIND_PW}
password_query = SELECT password FROM mailbox WHERE username='%u' AND active='1'
user_query = SELECT \
CONCAT(mailbox.storagebasedirectory, '/', mailbox.storagenode, '/', mailbox.maildir) AS home, \
CONCAT('*:bytes=', mailbox.quota*1048576) AS quota_rule \
FROM mailbox,domain \
WHERE mailbox.username='%u' \
AND mailbox.domain='%d' \
AND mailbox.enable%Ls%Lc=1 \
AND mailbox.domain=domain.domain \
AND domain.backupmx=0 \
AND domain.active=1 \
AND mailbox.active=1
EOF

        # Set file permission.
        chmod 0550 ${DOVECOT_MYSQL_CONF}
    fi


        if [ X"${BACKEND}" == X"OpenLDAP" ]; then
            realtime_quota_db_name="${IREDADMIN_DB_NAME}"
            realtime_quota_db_table="used_quota"
            realtime_quota_db_user="${IREDADMIN_DB_USER}"
            realtime_quota_db_passwd="${IREDADMIN_DB_PASSWD}"
        else
            realtime_quota_db_name="${VMAIL_DB}"
            realtime_quota_db_table="mailbox"
            realtime_quota_db_user="${MYSQL_ADMIN_USER}"
            realtime_quota_db_passwd="${MYSQL_ADMIN_PW}"
        fi

        cat > ${DOVECOT_REALTIME_QUOTA_CONF} <<EOF
${CONF_MSG}
connect = host=${MYSQL_SERVER} dbname=${realtime_quota_db_name} user=${realtime_quota_db_user} password=${realtime_quota_db_passwd}
map {
    pattern = priv/quota/storage
    table = ${realtime_quota_db_table}
    username_field = username
    value_field = bytes
}
map {
    pattern = priv/quota/messages
    table = ${realtime_quota_db_table}
    username_field = username
    value_field = messages
}
EOF

        # Create MySQL database ${IREDADMIN_DB_USER} and table 'used_quota'
        # which used to store realtime quota.
        if [ X"${BACKEND}" == X"OpenLDAP" -a X"${USE_IREDADMIN}" != X"YES" ]; then
            # If iRedAdmin is not used, create database and import table here.
            mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
# Create databases.
CREATE DATABASE IF NOT EXISTS ${IREDADMIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

# Import SQL template.
USE ${IREDADMIN_DB_NAME};
SOURCE ${SAMPLE_DIR}/used_quota.sql;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${IREDADMIN_DB_NAME}.* TO "${IREDADMIN_DB_USER}"@localhost IDENTIFIED BY "${IREDADMIN_DB_PASSWD}";

FLUSH PRIVILEGES;
EOF

        fi
    # ---- real time dict quota ----

    # ---- IMAP shared folder ----
    if [ X"${DOVECOT_VERSION}" == X"1.2" ]; then
        backup_file ${DOVECOT_SHARE_FOLDER_CONF}

        if [ X"${BACKEND}" == X"OpenLDAP" ]; then
            share_folder_db_name="${IREDADMIN_DB_NAME}"
            share_folder_db_table="share_folder"
            share_folder_db_user="${IREDADMIN_DB_USER}"
            share_folder_db_passwd="${IREDADMIN_DB_PASSWD}"
        else
            share_folder_db_name="${VMAIL_DB}"
            share_folder_db_table="share_folder"
            share_folder_db_user="${MYSQL_ADMIN_USER}"
            share_folder_db_passwd="${MYSQL_ADMIN_PW}"
        fi

        # Enable dict quota in dovecot.
        cat >> ${DOVECOT_CONF} <<EOF
namespace private {
    separator = /
    prefix =
    #location defaults to mail_location.
    inbox = yes
}

namespace shared {
    separator = /
    prefix = Shared/%%u/
    location = maildir:/%%Lh/Maildir/:INDEX=/%%Lh/Maildir/Shared/%%u
    # this namespace should handle its own subscriptions or not.
    subscriptions = yes
    list = children
}

plugin {
    acl = vfile
    acl_shared_dict = proxy::acl
}
dict {
    acl = ${DOVECOT_SHARE_FOLDER_SQLTYPE}:${DOVECOT_SHARE_FOLDER_CONF}
}
EOF

        # SQL lookup for share folder.
        cat > ${DOVECOT_SHARE_FOLDER_CONF} <<EOF
${CONF_MSG}
connect = host=${MYSQL_SERVER} dbname=${share_folder_db_name} user=${share_folder_db_user} password=${share_folder_db_passwd}
map {
    pattern = shared/shared-boxes/user/\$to/\$from
    table = share_folder
    value_field = dummy

    fields {
        from_user = \$from
        to_user = \$to
    }
}
EOF

        # Create MySQL database ${IREDADMIN_DB_USER} and table 'share_folder'
        # which used to store realtime quota.
        if [ X"${BACKEND}" == X"OpenLDAP" -a X"${USE_IREDADMIN}" != X"YES" ]; then
            # If iRedAdmin is not used, create database and import table here.
            mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
# Create databases.
CREATE DATABASE IF NOT EXISTS ${IREDADMIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

# Import SQL template.
USE ${IREDADMIN_DB_NAME};
SOURCE ${SAMPLE_DIR}/imap_share_folder.sql;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${IREDADMIN_DB_NAME}.* TO "${IREDADMIN_DB_USER}"@localhost IDENTIFIED BY "${IREDADMIN_DB_PASSWD}";

FLUSH PRIVILEGES;
EOF
        fi

    fi
    # ---- IMAP shared folder ----

    ECHO_DEBUG "Copy sample sieve global filter rule file: ${GLOBAL_SIEVE_FILE}.sample."
    cp -f ${SAMPLE_DIR}/dovecot.sieve ${GLOBAL_SIEVE_FILE}.sample
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${GLOBAL_SIEVE_FILE}.sample
    chmod 0500 ${GLOBAL_SIEVE_FILE}.sample

    ECHO_DEBUG "Create dovecot log file: ${DOVECOT_LOG_FILE}, ${SIEVE_LOG_FILE}."
    touch ${DOVECOT_LOG_FILE} ${SIEVE_LOG_FILE}
    chown ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${DOVECOT_LOG_FILE} ${SIEVE_LOG_FILE}
    chmod 0600 ${DOVECOT_LOG_FILE}

    # Sieve log file must be world-writable.
    chmod 0666 ${SIEVE_LOG_FILE}

    ECHO_DEBUG "Enable dovecot SASL support in postfix: ${POSTFIX_FILE_MAIN_CF}."
    postconf -e mailbox_command="${DOVECOT_DELIVER}"
    [ X"${DISTRO}" == X"SUSE" ] && \
        perl -pi -e 's#^(POSTFIX_MDA=).*#${1}"dovecot"#' ${POSTFIX_SYSCONFIG_CONF}
    postconf -e virtual_transport="${TRANSPORT}"
    postconf -e dovecot_destination_recipient_limit='1'

    postconf -e smtpd_sasl_type='dovecot'
    # It's '/var/spool/postfix/dovecot-auth'.
    # Prepend './' to make postfix recognize it as socket path.
    postconf -e smtpd_sasl_path='./dovecot-auth'

    ECHO_DEBUG "Create directory for Dovecot plugin: Expire."
    dovecot_expire_dict_dir="$(dirname ${DOVECOT_EXPIRE_DICT_BDB})"
    mkdir -p ${dovecot_expire_dict_dir} && \
    chown -R ${DOVECOT_USER}:${DOVECOT_GROUP} ${dovecot_expire_dict_dir} && \
    chmod -R 0750 ${dovecot_expire_dict_dir}

    if [ X"${DISTRO}" == X"RHEL" ]; then
        ECHO_DEBUG "Setting cronjob for Dovecot plugin: Expire."
        cat >> ${CRON_SPOOL_DIR}/root <<EOF
${CONF_MSG}
#1   5   *   *   *   ${DOVECOT_BIN} --exec-mail ext $(eval ${LIST_FILES_IN_PKG} dovecot | grep 'expire-tool$')
EOF
    fi

    cat >> ${POSTFIX_FILE_MASTER_CF} <<EOF
# Use dovecot deliver program as LDA.
dovecot unix    -       n       n       -       -      pipe
    flags=DRhu user=${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} argv=${DOVECOT_DELIVER} -f \${sender} -d \${user}@\${domain}
EOF

    if [ X"${KERNEL_NAME}" == X"Linux" ]; then
        ECHO_DEBUG "Setting logrotate for dovecot log file."
        cat > ${DOVECOT_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${DOVECOT_LOG_FILE} {
    compress
    weekly
    rotate 10
    create 0600 ${VMAIL_USER_NAME} ${VMAIL_GROUP_NAME}
    missingok

    # Use bzip2 for compress.
    compresscmd $(which bzip2)
    uncompresscmd $(which bunzip2)
    compressoptions -9
    compressext .bz2

    postrotate
        ${SYSLOG_POSTROTATE_CMD}
    endscript
}
EOF

    cat > ${SIEVE_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${SIEVE_LOG_FILE} {
    compress
    weekly
    rotate 10
    create 0666 ${VMAIL_USER_NAME} ${VMAIL_GROUP_NAME}
    missingok
    postrotate
        ${SYSLOG_POSTROTATE_CMD}
    endscript
}
EOF
    else
        :
    fi

    cat >> ${TIP_FILE} <<EOF
Dovecot:
    * Configuration files:
        - ${DOVECOT_CONF}
        - ${DOVECOT_LDAP_CONF} (For OpenLDAP backend)
        - ${DOVECOT_MYSQL_CONF} (For MySQL backend)
        - ${DOVECOT_REALTIME_QUOTA_CONF}
        - ${DOVECOT_SHARE_FOLDER_CONF} (share folder)
    * RC script: ${DIR_RC_SCRIPTS}/dovecot
    * Log files:
        - ${DOVECOT_LOGROTATE_FILE}
        - ${DOVECOT_LOG_FILE}
        - ${SIEVE_LOG_FILE}
    * See also:
        - ${GLOBAL_SIEVE_FILE}

EOF

    echo 'export status_dovecot2_config="DONE"' >> ${STATUS_FILE}
}

enable_dovecot2()
{
    if [ X"${ENABLE_DOVECOT}" == X"YES" ]; then
        check_status_before_run dovecot2_config
    fi

    echo 'export status_enable_dovecot2="DONE"' >> ${STATUS_FILE}
}
