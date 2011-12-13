#!/usr/bin/env bash

# Author: Zhang Huangbin <zhb(at)iredmail.org>

# -------------------------------------------------
# phpMyAdmin.
# -------------------------------------------------
phpmyadmin_install()
{
    ECHO_INFO "Configure phpMyAdmin (web-based MySQL management tool)." 

    if [ X"${PHPMYADMIN_USE_SOURCE}" == X"YES" ]; then
        cd ${MISC_DIR}

        extract_pkg ${PHPMYADMIN_TARBALL} ${HTTPD_SERVERROOT}

        ECHO_DEBUG "Set file permission for phpMyAdmin: ${PHPMYADMIN_HTTPD_ROOT}."
        chown -R ${SYS_ROOT_USER}:${SYS_ROOT_GROUP} ${PHPMYADMIN_HTTPD_ROOT}
        chmod -R 0755 ${PHPMYADMIN_HTTPD_ROOT}

        # Create symbol link, so that we don't need to modify apache
        # conf.d/phpmyadmin.conf file after upgrade this component.
        ln -s ${PHPMYADMIN_HTTPD_ROOT} ${PHPMYADMIN_HTTPD_ROOT_SYMBOL_LINK} >/dev/null
    fi

    ECHO_DEBUG "Create directory alias for phpMyAdmin in Apache: ${HTTPD_CONF_DIR}/phpmyadmin.conf."
    cat > ${HTTPD_CONF_DIR}/phpmyadmin.conf <<EOF
${CONF_MSG}
# Note: Please refer to ${HTTPD_SSL_CONF} for SSL/TLS setting.
#Alias /phpmyadmin "${PHPMYADMIN_HTTPD_ROOT_SYMBOL_LINK}"
<Directory "${PHPMYADMIN_HTTPD_ROOT_SYMBOL_LINK}/">
    Options -Indexes
</Directory>
EOF

    # Make phpMyAdmin can be accessed via HTTPS only.
    perl -pi -e 's#(</VirtualHost>)#Alias /phpmyadmin "$ENV{PHPMYADMIN_HTTPD_ROOT_SYMBOL_LINK}/"\n${1}#' ${HTTPD_SSL_CONF}

    ECHO_DEBUG "Config phpMyAdmin: ${PHPMYADMIN_CONFIG_FILE}."
    cd ${PHPMYADMIN_HTTPD_ROOT} && cp config.sample.inc.php ${PHPMYADMIN_CONFIG_FILE}

    export COOKIE_STRING="$(${RANDOM_STRING})"
    perl -pi -e 's#(.*blowfish_secret.*= )(.*)#${1}"$ENV{'COOKIE_STRING'}"; //${2}#' ${PHPMYADMIN_CONFIG_FILE}
    perl -pi -e 's#(.*Servers.*host.*=.*)localhost(.*)#${1}$ENV{'MYSQL_SERVER'}${2}#' ${PHPMYADMIN_CONFIG_FILE}

    if [ X"${MYSQL_SERVER}" == X"localhost" ]; then
        # Use unix socket.
        perl -pi -e 's#(.*Servers.*connect_type.*=).*#${1}"socket";#' ${PHPMYADMIN_CONFIG_FILE}
    else
        # Use TCP/IP.
        perl -pi -e 's#(.*Servers.*connect_type.*=).*#${1}"tcp";#' ${PHPMYADMIN_CONFIG_FILE}
    fi

    cat >> ${TIP_FILE} <<EOF
phpMyAdmin:
    * Configuration files:
        - ${PHPMYADMIN_HTTPD_ROOT}
        - ${PHPMYADMIN_CONFIG_FILE}
    * Login account:
        - Username: ${MYSQL_ROOT_USER}, password: ${MYSQL_ROOT_PASSWD}
        - Username: ${MYSQL_ADMIN_USER}, password: ${MYSQL_ADMIN_PW}
        - Username (read-only): ${MYSQL_BIND_USER}, password: ${MYSQL_BIND_PW}
    * URL:
        - https://${HOSTNAME}/phpmyadmin
    * See also:
        - ${HTTPD_CONF_DIR}/phpmyadmin.conf

EOF

    echo 'export status_phpmyadmin_install="DONE"' >> ${STATUS_FILE}
}
