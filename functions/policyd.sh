#!/usr/bin/env bash

# Author:   Zhang Huangbin (zhb@iredmail.org)

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

# ---------------------------------------------
# Policyd.
# ---------------------------------------------
policyd_user()
{
    ECHO_DEBUG "Add user and group for policyd: ${POLICYD_USER}:${POLICYD_GROUP}."
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        pw useradd -n ${POLICYD_USER} -s ${SHELL_NOLOGIN} -d ${POLICYD_USER_HOME} -m
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        # Not need to add user/group.
        :
    else
        groupadd ${POLICYD_GROUP}
        useradd -m -d ${POLICYD_USER_HOME} -s ${SHELL_NOLOGIN} -g ${POLICYD_GROUP} ${POLICYD_USER}
    fi

    echo 'export status_policyd_user="DONE"' >> ${STATUS_FILE}
}

policyd_config()
{
    ECHO_DEBUG "Initialize MySQL database of policyd."

    # Get SQL structure template file.
    tmp_sql="/tmp/policyd_config_tmp.${RANDOM}${RANDOM}"
    if [ X"${DISTRO}" == X"RHEL" -o X"${DISTRO}" == X"SUSE" ]; then
        cat > ${tmp_sql} <<EOF
# Import SQL structure template.
SOURCE $(eval ${LIST_FILES_IN_PKG} ${PKG_POLICYD} | grep '/DATABASE.mysql$');

# Grant privileges.
GRANT SELECT,INSERT,UPDATE,DELETE ON ${POLICYD_DB_NAME}.* TO "${POLICYD_DB_USER}"@localhost IDENTIFIED BY "${POLICYD_DB_PASSWD}";
FLUSH PRIVILEGES;
EOF

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        # dbconfig-common will initialize policyd database, grant privileges.
        cat > ${tmp_sql} <<EOF
# Reset password.
USE mysql;
UPDATE user SET Password=password("${POLICYD_DB_PASSWD}") WHERE User="${POLICYD_DB_USER}";
FLUSH PRIVILEGES;
EOF

        # Debian 5, Ubuntu 8.04, 9.04: Import missing table: postfixpolicyd.blacklist_dnsname.
        if [ X"${DISTRO}" == X"DEBIAN" -o \
            X"${DISTRO_CODENAME}" == X"hardy" -o \
            X"${DISTRO_CODENAME}" == X"jaunty" ]; then
            cat >> ${tmp_sql} <<EOF
USE ${POLICYD_DB_NAME};
SOURCE /usr/share/dbconfig-common/data/postfix-policyd/upgrade/mysql/1.73-1;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${POLICYD_DB_NAME}.* TO "${POLICYD_DB_USER}"@localhost;
EOF
        fi

    elif [ X"${DISTRO}" == X"FREEBSD" ]; then
        # Template file will create database: policyd.
        cat > ${tmp_sql} <<EOF
# Import SQL structure template.
SOURCE $(eval ${LIST_FILES_IN_PKG} "${PKG_POLICYD}*" | grep '/DATABASE.mysql$');

# Grant privileges.
GRANT SELECT,INSERT,UPDATE,DELETE ON ${POLICYD_DB_NAME}.* TO "${POLICYD_DB_USER}"@localhost IDENTIFIED BY "${POLICYD_DB_PASSWD}";
FLUSH PRIVILEGES;
EOF

    else
        :
    fi

    cat >> ${tmp_sql} <<EOF
USE ${POLICYD_DB_NAME};
SOURCE ${SAMPLE_DIR}/policyd_blacklist_helo.sql;
EOF

    # Import whitelist/blacklist shipped in policyd and provided by iRedMail.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        cat >> ${tmp_sql} <<EOF
SOURCE $(eval ${LIST_FILES_IN_PKG} ${PKG_POLICYD} | grep 'whitelist.sql');
SOURCE $(eval ${LIST_FILES_IN_PKG} ${PKG_POLICYD} | grep 'blacklist_helo.sql');
EOF

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        # Create a temp directory.
        tmp_dir="/tmp/$(${RANDOM_STRING})" && mkdir -p ${tmp_dir}

        for i in $( eval ${LIST_FILES_IN_PKG} postfix-policyd | grep 'sql.gz$'); do
            cp $i ${tmp_dir}
            gunzip ${tmp_dir}/$(basename $i)

            cat >> ${tmp_sql} <<EOF
SOURCE ${tmp_dir}/$(basename $i | awk -F'.gz' '{print $1}');
EOF
        done
    elif [ X"${DISTRO}" == X"FREEBSD" ]; then
        cat >> ${tmp_sql} <<EOF
SOURCE $(eval ${LIST_FILES_IN_PKG} "${PKG_POLICYD}*" | grep 'whitelist.sql');
SOURCE $(eval ${LIST_FILES_IN_PKG} "${PKG_POLICYD}*" | grep 'blacklist_helo.sql');
EOF
    else
        :
    fi

    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
$(cat ${tmp_sql})
USE ${POLICYD_DB_NAME};
ALTER TABLE blacklist MODIFY COLUMN _description CHAR(60) CHARACTER SET utf8;
ALTER TABLE blacklist_sender MODIFY COLUMN _description CHAR(60) CHARACTER SET utf8;
ALTER TABLE whitelist MODIFY COLUMN _description CHAR(60) CHARACTER SET utf8;
ALTER TABLE whitelist_dnsname MODIFY COLUMN _description CHAR(60) CHARACTER SET utf8;
ALTER TABLE whitelist_sender MODIFY COLUMN _description CHAR(60) CHARACTER SET utf8;
EOF

    rm -rf ${tmp_sql} ${tmp_dir} 2>/dev/null
    unset tmp_sql tmp_dir

    # Configure policyd.
    ECHO_DEBUG "Configure policyd: ${POLICYD_CONF}."

    # FreeBSD: Copy sample config file.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        cp /usr/local/etc/postfix-policyd-sf.conf.sample ${POLICYD_CONF}
    fi

    # We will use another policyd instance for recipient throttle
    # feature, it's used in 'smtpd_end_of_data_restrictions'.
    cp -f ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}

    # Patch init script on RHEL/CentOS.
    [ X"${DISTRO}" == X"RHEL" ] && patch -p0 < ${PATCH_DIR}/policyd/policyd_init.patch >/dev/null

    # Set correct permission.
    chown ${POLICYD_USER}:${POLICYD_GROUP} ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}
    chmod 0700 ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}

    # Setup postfix for recipient throttle.
    cat >> ${POSTFIX_FILE_MAIN_CF} <<EOF
#
# Uncomment the following line to enable policyd sender throttle.
#
#smtpd_end_of_data_restrictions = check_policy_service inet:${POLICYD_THROTTLE_BINDHOST}:${POLICYD_THROTTLE_BINDPORT}
EOF

    # -------------------------------------------------------------
    # Policyd config for normal feature exclude recipient throttle.
    # -------------------------------------------------------------
    # ---- DATABASE CONFIG ----

    # Policyd doesn't work while mysql server is 'localhost', should be
    # changed to '127.0.0.1'.

    perl -pi -e 's#^(MYSQLHOST=)(.*)#${1}"$ENV{mysql_server}"#' ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(MYSQLDBASE=)(.*)#${1}"$ENV{POLICYD_DB_NAME}"#' ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(MYSQLUSER=)(.*)#${1}"$ENV{POLICYD_DB_USER}"#' ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(MYSQLPASS=)(.*)#${1}"$ENV{POLICYD_DB_PASSWD}"#' ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(FAILSAFE=)(.*)#${1}1#' ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}

    # ---- DAEMON CONFIG ----
    perl -pi -e 's#^(DEBUG=)(.*)#${1}0#' ${POLICYD_CONF}
    perl -pi -e 's#^(DAEMON=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(BINDHOST=)(.*)#${1}"$ENV{POLICYD_BINDHOST}"#' ${POLICYD_CONF}
    perl -pi -e 's#^(BINDPORT=)(.*)#${1}"$ENV{POLICYD_BINDPORT}"#' ${POLICYD_CONF}

    # ---- CHROOT ----
    export policyd_user_id="$(id -u ${POLICYD_USER})"
    export policyd_group_id="$(id -g ${POLICYD_USER})"
    perl -pi -e 's#^(CHROOT=)(.*)#${1}$ENV{POLICYD_USER_HOME}#' ${POLICYD_CONF}
    perl -pi -e 's#^(UID=)(.*)#${1}$ENV{policyd_user_id}#' ${POLICYD_CONF}
    perl -pi -e 's#^(GID=)(.*)#${1}$ENV{policyd_group_id}#' ${POLICYD_CONF}

    # ---- WHITELISTING ----
    perl -pi -e 's#^(WHITELISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(WHITELISTNULL=)(.*)#${1}0#' ${POLICYD_CONF}
    perl -pi -e 's#^(WHITELISTSENDER=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(AUTO_WHITE_LISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(AUTO_WHITELIST_NUMBER=)(.*)#${1}10#' ${POLICYD_CONF}

    # ---- BLACKLISTING ----
    perl -pi -e 's#^(BLACKLISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(BLACKLIST_TEMP_REJECT=)(.*)#${1}0#' ${POLICYD_CONF}
    perl -pi -e 's#^(AUTO_BLACK_LISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(AUTO_WHITELIST_NUMBER=)(.*)#${1}10#' ${POLICYD_CONF}

    # ---- BLACKLISTING HELO ----
    perl -pi -e 's#^(BLACKLIST_HELO=)(.*)#${1}0#' ${POLICYD_CONF}
    # ---- BLACKLIST SENDER ----
    perl -pi -e 's#^(BLACKLISTSENDER=)(.*)#${1}1#' ${POLICYD_CONF}

    # ---- HELO_CHECK ----
    perl -pi -e 's#^(HELO_CHECK=)(.*)#${1}1#' ${POLICYD_CONF}

    # ---- SPAMTRAP ----
    perl -pi -e 's#^(SPAMTRAPPING=)(.*)#${1}1#' ${POLICYD_CONF}

    # ---- GREYLISTING ----
    perl -pi -e 's#^(GREYLISTING=)(.*)#${1}1#' ${POLICYD_CONF}
    perl -pi -e 's#^(TRAINING_MODE=)(.*)#${1}0#' ${POLICYD_CONF}
    perl -pi -e 's#^(TRIPLET_TIME=)(.*)#${1}5m#' ${POLICYD_CONF}
    perl -pi -e 's#^(TRIPLET_AUTH_TIMEOUT=)(.*)#${1}7d#' ${POLICYD_CONF}
    perl -pi -e 's#^(TRIPLET_UNAUTH_TIMEOUT=)(.*)#${1}2d#' ${POLICYD_CONF}
    #perl -pi -e 's#^(OPTINOUT=)(.*)#${1}1#' ${POLICYD_CONF}

    # Disable sender throttling here, it should be invoked in postfix
    # 'smtpd_end_of_data_restrictions'.
    # ---- SENDER THROTTLE ----
    perl -pi -e 's#^(SENDERTHROTTLE=)(.*)#${1}0#' ${POLICYD_CONF}
    # ---- RECIPIENT THROTTLE ----
    perl -pi -e 's#^(RECIPIENTTHROTTLE=)(.*)#${1}0#' ${POLICYD_CONF}

    # ---- RCPT ACL ----
    if [ X"${DISTRO}" == X"RHEL" ]; then
        perl -pi -e 's#^(RCPT_ACL=)(.*)#${1}1#' ${POLICYD_CONF}
    else
        :
    fi

    # -------------------------------------------------------------
    # Policyd config for recipient throttle only.
    # -------------------------------------------------------------

    # ---- DAEMON CONFIG ----
    perl -pi -e 's#^(DEBUG=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(DAEMON=)(.*)#${1}1#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(BINDHOST=)(.*)#${1}"$ENV{POLICYD_THROTTLE_BINDHOST}"#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(BINDPORT=)(.*)#${1}"$ENV{POLICYD_THROTTLE_BINDPORT}"#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(PIDFILE=)(.*)#${1}"$ENV{POLICYD_THROTTLE_PIDFILE}"#' ${POLICYD_THROTTLE_CONF}

    # ---- CHROOT ----
    perl -pi -e 's#^(CHROOT=)(.*)#${1}$ENV{POLICYD_USER_HOME}#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(UID=)(.*)#${1}$ENV{policyd_user_id}#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(GID=)(.*)#${1}$ENV{policyd_group_id}#' ${POLICYD_THROTTLE_CONF}

    # ---- RECIPIENT THROTTLE ----
    perl -pi -e 's#^(RECIPIENTTHROTTLE=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}

    # ------------------ DISABLE ALL OTHER FEATURES -----------------
    # ---- WHITELISTING ----
    perl -pi -e 's#^(WHITELISTING=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}

    # ---- BLACKLISTING ----
    perl -pi -e 's#^(BLACKLISTING=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}

    # ---- BLACKLISTING HELO ----
    perl -pi -e 's#^(BLACKLIST_HELO=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}

    # ---- BLACKLIST SENDER ----
    perl -pi -e 's#^(BLACKLISTSENDER=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}

    # ---- HELO_CHECK ----
    perl -pi -e 's#^(HELO_CHECK=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}

    # ---- SPAMTRAP ----
    perl -pi -e 's#^(SPAMTRAPPING=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}

    # ---- GREYLISTING ----
    perl -pi -e 's#^(GREYLISTING=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}

    # ---- SENDER THROTTLE ----
    # We need only this feature in this policyd instance.
    perl -pi -e 's#^(SENDERTHROTTLE=)(.*)#${1}1#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(SENDER_THROTTLE_SASL=)(.*)#${1}1#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(SENDER_THROTTLE_HOST=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(QUOTA_EXCEEDED_TEMP_REJECT=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}
    perl -pi -e 's#^(SENDERMSGSIZE=)(.*)#${1}$ENV{'MESSAGE_SIZE_LIMIT'}#' ${POLICYD_THROTTLE_CONF}

    # ---- RCPT ACL ----
    if [ X"${DISTRO}" == X"RHEL" ]; then
        perl -pi -e 's#^(RCPT_ACL=)(.*)#${1}0#' ${POLICYD_THROTTLE_CONF}
    else
        :
    fi

    # -----------------
    # Syslog Setting
    # -----------------
    perl -pi -e 's#^(SYSLOG_FACILITY=)(.*)#${1}"$ENV{POLICYD_SYSLOG_FACILITY}"#' ${POLICYD_CONF} ${POLICYD_THROTTLE_CONF}

    if [ X"${POLICYD_SEPERATE_LOG}" == X"YES" ]; then
        echo -e "local1.*\t\t\t\t\t\t-${POLICYD_LOGFILE}" >> ${SYSLOG_CONF}
        cat > ${POLICYD_LOGROTATE_FILE} <<EOF
${CONF_MSG}
${AMAVISD_LOGFILE} {
    compress
    weekly
    rotate 10
    create 0600 amavis amavis
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
    else
        :
    fi

    # Setup crontab.
    ECHO_DEBUG "Setting cron job for policyd user: ${POLICYD_USER}."
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        cat > ${CRON_SPOOL_DIR}/${POLICYD_USER} <<EOF
${CONF_MSG}
1    */2    *    *    *    ${POLICYD_CLEANUP_BIN} -c ${POLICYD_CONF}
1    */2    *    *    *    ${POLICYD_CLEANUP_BIN} -c ${POLICYD_THROTTLE_CONF}
EOF
    else
        cat > ${CRON_SPOOL_DIR}/${POLICYD_USER} <<EOF
${CONF_MSG}
1    */2    *    *    *    ${POLICYD_CLEANUP_BIN} -c ${POLICYD_CONF}
1    */2    *    *    *    ${POLICYD_CLEANUP_BIN} -c ${POLICYD_THROTTLE_CONF}
EOF
    fi

    # Set cron file permission: root:root, 0600.
    chmod 0600 ${CRON_SPOOL_DIR}/${POLICYD_USER}

    # Add postfix alias.
    if [ ! -z ${MAIL_ALIAS_ROOT} ]; then
        echo "policyd: ${MAIL_ALIAS_ROOT}" >> ${POSTFIX_FILE_ALIASES}
        postalias hash:${POSTFIX_FILE_ALIASES} 2>/dev/null
    else
        :
    fi

    # Tips.
    cat >> ${TIP_FILE} <<EOF
Policyd:
    * Configuration files:
        - ${POLICYD_CONF}
    * RC script:
        - ${DIR_RC_SCRIPTS}/policyd
    * Misc:
        - /etc/cron.daily/policyd-cleanup
        - crontab -l -u ${POLICYD_USER}
EOF

    if [ X"${POLICYD_SEPERATE_LOG}" == X"YES" ]; then
        cat >> ${TIP_FILE} <<EOF
    * Log file:
        - ${SYSLOG_CONF}
        - ${POLICYD_LOGFILE}

EOF
    else
        echo -e '\n' >> ${TIP_FILE}
    fi

    echo 'export status_policyd_config="DONE"' >> ${STATUS_FILE}
}
