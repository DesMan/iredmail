#!/usr/bin/env bash

# Author: Zhang Huangbin <zhb(at)iredmail.org>

# -----------------------
# Roundcube.
# -----------------------
rcm_install()
{
    ECHO_INFO "Configure Roundcube webmail."

    # FreeBSD: install via ports tree.
    if [ X"${DISTRO}" != X"FREEBSD" ]; then
        cd ${MISC_DIR}

        # Extract source tarball.
        extract_pkg ${RCM_TARBALL} ${HTTPD_SERVERROOT}

        # Create symbol link, so that we don't need to modify apache
        # conf.d/roundcubemail.conf file after upgrade this component.
        ln -s ${RCM_HTTPD_ROOT} ${RCM_HTTPD_ROOT_SYMBOL_LINK} 2>/dev/null

        ECHO_DEBUG "Set correct permission for Roundcubemail: ${RCM_HTTPD_ROOT}."
        chown -R ${SYS_ROOT_USER}:${SYS_ROOT_GROUP} ${RCM_HTTPD_ROOT}
        chown -R ${HTTPD_USER}:${HTTPD_GROUP} ${RCM_HTTPD_ROOT}/{temp,logs}
        chmod 0000 ${RCM_HTTPD_ROOT}/{CHANGELOG,INSTALL,LICENSE,README,UPGRADING,installer,SQL}
    fi

    cd ${RCM_HTTPD_ROOT}/config/
    cp -f db.inc.php.dist db.inc.php
    cp -f main.inc.php.dist main.inc.php
    chown ${HTTPD_USER}:${HTTPD_GROUP} db.inc.php main.inc.php
    chmod 0640 db.inc.php main.inc.php

    echo 'export status_rcm_install="DONE"' >> ${STATUS_FILE}
}

rcm_config_httpd()
{
    ECHO_DEBUG "Create directory alias for Roundcubemail."
    cat > ${HTTPD_CONF_DIR}/roundcubemail.conf <<EOF
${CONF_MSG}
# Note: Please refer to ${HTTPD_SSL_CONF} for SSL/TLS setting.
Alias /mail "${RCM_HTTPD_ROOT_SYMBOL_LINK}/"
Alias /webmail "${RCM_HTTPD_ROOT_SYMBOL_LINK}/"
Alias /roundcube "${RCM_HTTPD_ROOT_SYMBOL_LINK}/"
<Directory "${RCM_HTTPD_ROOT_SYMBOL_LINK}/">
    Options -Indexes
</Directory>
EOF

    # Make Roundcube can be accessed via HTTPS.
    perl -pi -e 's#(</VirtualHost>)#Alias /mail "$ENV{RCM_HTTPD_ROOT_SYMBOL_LINK}/"\n${1}#' ${HTTPD_SSL_CONF}
    perl -pi -e 's#(</VirtualHost>)#Alias /webmail "$ENV{RCM_HTTPD_ROOT_SYMBOL_LINK}/"\n${1}#' ${HTTPD_SSL_CONF}
    perl -pi -e 's#(</VirtualHost>)#Alias /roundcube "$ENV{RCM_HTTPD_ROOT_SYMBOL_LINK}/"\n${1}#' ${HTTPD_SSL_CONF}

    echo 'export status_rcm_config_httpd="DONE"' >> ${STATUS_FILE}
}

rcm_import_sql()
{
    ECHO_DEBUG "Import MySQL database and privileges for Roundcubemail."

    mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
/* Create database and grant privileges. */
CREATE DATABASE ${RCM_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT SELECT,INSERT,UPDATE,DELETE ON ${RCM_DB}.* TO "${RCM_DB_USER}"@localhost IDENTIFIED BY '${RCM_DB_PASSWD}';

/* Import Roundcubemail SQL template. */
USE ${RCM_DB};
SOURCE ${RCM_HTTPD_ROOT}/SQL/mysql.initial.sql;

FLUSH PRIVILEGES;
EOF

    # Do not grant privileges while backend is not MySQL.
    if [ X"${BACKEND}" == X"MySQL" ]; then
        mysql -h${MYSQL_SERVER} -P${MYSQL_PORT} -u${MYSQL_ROOT_USER} -p"${MYSQL_ROOT_PASSWD}" <<EOF
-- Grant privileges for Roundcubemail, so that user can change
-- their own password and setting mail forwarding.
GRANT UPDATE,SELECT ON ${VMAIL_DB}.mailbox TO "${RCM_DB_USER}"@localhost;
-- GRANT INSERT,UPDATE,SELECT ON ${VMAIL_DB}.alias TO "${RCM_DB_USER}"@localhost;

FLUSH PRIVILEGES;
EOF
    else
        :
    fi

    echo 'export status_rcm_import_sql="DONE"' >> ${STATUS_FILE}
}

rcm_config()
{
    ECHO_DEBUG "Configure database for Roundcubemail: ${RCM_HTTPD_ROOT}/config/*."

    cd ${RCM_HTTPD_ROOT}/config/

    export RCM_DB_USER RCM_DB_PASSWD RCMD_DB MYSQL_SERVER FIRST_DOMAIN

    perl -pi -e 's#(.*db_dsnw.*= )(.*)#${1}"$ENV{'PHP_CONN_TYPE'}://$ENV{'RCM_DB_USER'}:$ENV{'RCM_DB_PASSWD'}\@$ENV{'MYSQL_SERVER'}/$ENV{'RCM_DB'}";#' db.inc.php

    # ----------------------------------
    # LOGGING/DEBUGGING
    # ----------------------------------
    # Logging
    perl -pi -e 's#(.*log_driver.*=).*#${1} "syslog";#' main.inc.php
    perl -pi -e 's#(.*syslog_id.*=).*#${1} "roundcube";#' main.inc.php
    # syslog_facility should be a constant, not string. (Do *NOT* use quote.)
    perl -pi -e 's#(.*syslog_facility.*=).*#${1} LOG_MAIL;#' main.inc.php

    # Debugging
    perl -pi -e 's#(.*sql_debug.*=).*#${1} false;#' main.inc.php
    perl -pi -e 's#(.*imap_debug.*=).*#${1} false;#' main.inc.php
    perl -pi -e 's#(.*ldap_debug.*=).*#${1} false;#' main.inc.php
    perl -pi -e 's#(.*smtp_debug.*=).*#${1} false;#' main.inc.php

    # ----------------------------------
    # IMAP
    # ----------------------------------
    perl -pi -e 's#(.*default_host.*=).*#${1} "$ENV{'IMAP_SERVER'}";#' main.inc.php
    #perl -pi -e 's#(.*default_port.*=).*#${1} 143;#' main.inc.php
    perl -pi -e 's#(.*imap_auth_type.*=).*#${1} "";#' main.inc.php

    # IMAP share folder.
    perl -pi -e 's#(.*imap_delimiter.*=).*#${1} "/";#' main.inc.php
    perl -pi -e 's#(.*imap_ns_personal.*=).*#${1} null;#' main.inc.php
    perl -pi -e 's#(.*imap_ns_other.*=).*#${1} null;#' main.inc.php
    perl -pi -e 's#(.*imap_ns_shared.*=).*#${1} null;#' main.inc.php

    # ----------------------------------
    # SMTP
    # ----------------------------------
    perl -pi -e 's#(.*smtp_server.*= )(.*)#${1}"$ENV{'SMTP_SERVER'}";#' main.inc.php
    #perl -pi -e 's#(.*smtp_port.*= )(.*)#${1} 25;#' main.inc.php
    perl -pi -e 's#(.*smtp_user.*= )(.*)#${1}"%u";#' main.inc.php
    perl -pi -e 's#(.*smtp_pass.*= )(.*)#${1}"%p";#' main.inc.php

    # smtp_auth_type: empty to use best server supported one)
    perl -pi -e 's#(.*smtp_auth_type.*= )(.*)#${1}"";#' main.inc.php

    # ----------------------------------
    # SYSTEM
    # ----------------------------------
    # Disable installer.
    perl -pi -e 's#(.*enable_installer.*=).*#${1} false;#' main.inc.php

    # enable caching of messages and mailbox data in the local database.
    # recommended if the IMAP server does not run on the same machine
    #perl -pi -e 's#(.*enable_caching.*= )(.*)#${1}FALSE;#' main.inc.php

    # Allow browser-autocompletion on login form.
    # 0 - disabled, 1 - username and host only, 2 - username, host, password
    perl -pi -e 's#(.*login_autocomplete.*=)(.*)#${1} 2;#' main.inc.php

    # Automatically create a new ROUNDCUBE USER when log-in the first time.
    perl -pi -e 's#(.*auto_create_user.*=)(.*)#${1} true;#' main.inc.php

    perl -pi -e 's#(.*des_key.*= )(.*)#${1}"$ENV{'RCM_DES_KEY'}";#' main.inc.php

    # Set useragent, hide version number.
    perl -pi -e 's#(.*useragent.*=).*#${1} "RoundCube WebMail";#' main.inc.php

    # Set defeault domain.
    perl -pi -e 's#(.*username_domain.*=)(.*)#${1} "$ENV{'FIRST_DOMAIN'}";#' main.inc.php

    # Disable multiple identities.
    # 0 - many identities with possibility to edit all params
    # 1 - many identities with possibility to edit all params but not email address
    # 2 - one identity with possibility to edit all params
    # 3 - one identity with possibility to edit all params but not email address
    perl -pi -e 's#(.*identities_level.*=).*#${1} 3;#' main.inc.php

    # Spellcheck.
    perl -pi -e 's#(.*enable_spellcheck.*=).*#${1} FALSE;#' main.inc.php

    # ----------------------------------
    # PLUGINS
    # ----------------------------------

    # ----------------------------------
    # USER INTERFACE
    # ----------------------------------
    # Set default language and charset..
    perl -pi -e 's#(.*language.*= )(.*)#${1}"$ENV{'DEFAULT_LANG'}";#' main.inc.php

    # Automatic create and protect default IMAP folders.
    perl -pi -e 's#(.*create_default_folders.*=)(.*)#${1} true;#' main.inc.php
    perl -pi -e 's#(.*protect_default_folders.*=)(.*)#${1} true;#' main.inc.php

    # Quota zero as unlimited.
    perl -pi -e 's#(.*quota_zero_as_unlimited.*=).*#${1} true;#' main.inc.php

    # ----------------------------------
    # USER PREFERENCES
    # ----------------------------------
    perl -pi -e 's#(.*default_charset.*=).*#${1} "UTF-8";#' main.inc.php

    # Set timezone for Chinese users. UTC +8
    [ X"${DEFAULT_LANG}" == X"zh_CN" -o X"${DEFAULT_LANG}" == X"zh_TW" ] && \
        perl -pi -e 's#(.*timezone.*=).*#${1} 8;#' main.inc.php

    # display remote inline images
    # 0 - Never, always ask
    # 1 - Ask if sender is not in address book
    # 2 - Always show inline images
    perl -pi -e 's#(.*show_images.*=).*#${1} 1;#' main.inc.php

    # save compose message every 60 seconds (1 minute)
    perl -pi -e 's#(.*draft_autosave.*=).*#${1} 60;#' main.inc.php

    # Enable preview pane by default.
    perl -pi -e 's#(.*preview_pane.*=).*#${1} true;#' main.inc.php

    # Mark as read when viewed in preview pane (delay in seconds)
    # Set to -1 if messages in preview pane should not be marked as read
    perl -pi -e 's#(.*preview_pane_mark_read.*=).*#${1} 0;#' main.inc.php

    # Encoding of long/non-ascii attachment names:
    # 0 - Full RFC 2231 compatible
    # 1 - RFC 2047 for 'name' and RFC 2231 for 'filename' parameter (Thunderbird's default)
    # 2 - Full 2047 compatible
    perl -pi -e 's#(.*mime_param_folding.*=).*#${1} 1;#' main.inc.php

    # Auto expand threads.
    # 0 - Do not expand threads
    # 1 - Expand all threads automatically
    # 2 - Expand only threads with unread messages
    perl -pi -e 's#(.*autoexpand_threads.*=).*#${1} 2;#' main.inc.php

    # Set true if deleted messages should not be displayed
    # This will make the application run slower
    #perl -pi -e 's#(.*skip_deleted.*=).*#${1} true;#' main.inc.php

    # Check all folders for recent messages.
    perl -pi -e 's#(.*check_all_folders.*=)(.*)#${1} true;#' main.inc.php

    # after message delete/move, the next message will be displayed
    perl -pi -e 's#(.*display_next.*=).*#${1} true;#' main.inc.php

    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        export LDAP_SERVER_HOST LDAP_SERVER_PORT LDAP_BIND_VERSION LDAP_BASEDN LDAP_ATTR_DOMAIN_RDN LDAP_ATTR_USER_RDN
        cd ${RCM_HTTPD_ROOT}/config/
        ECHO_DEBUG "Setting global LDAP address book in Roundcube."

        # Remove PHP end of file mark first.
        cd ${RCM_HTTPD_ROOT}/config/ && perl -pi -e 's#\?\>##' main.inc.php

        cat >> main.inc.php <<EOF
// ----------------------------------
// ADDRESSBOOK SETTINGS
// ----------------------------------
// Global LDAP address book.
\$rcmail_config['ldap_public']["ldap_global"] = array(
    'name'          => 'Global LDAP Address Book',
    'hosts'         => array('${LDAP_SERVER_HOST}'),
    'port'          => ${LDAP_SERVER_PORT},
    'use_tls'       => false,

    // Search accounts in the same domain.
    'user_specific' => true, // If true the base_dn, bind_dn and bind_pass default to the user's IMAP login.
    'base_dn'       => '${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}',
    'bind_dn'       => '${LDAP_ATTR_USER_RDN}=%u@%d,${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}',

    'writable'      => false,
    'ldap_version'  => '${LDAP_BIND_VERSION}',
    'search_fields' => array('mail', 'cn', 'givenName', 'sn'),
    'name_field'    => 'cn',
    'email_field'   => 'mail',
    'surname_field' => 'sn',
    'firstname_field' => 'givenName',
    'sort'          => 'cn',
    'scope'         => 'sub',
    'filter'        => '(&(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_MAIL})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_DELIVER})(${LDAP_ENABLED_SERVICE}=${LDAP_SERVICE_DISPLAYED_IN_ADDRBOOK})(|(objectClass=${LDAP_OBJECTCLASS_MAILGROUP})(objectClass=${LDAP_OBJECTCLASS_MAILALIAS})(objectClass=${LDAP_OBJECTCLASS_MAILUSER})))',
    'fuzzy_search'  => true);

// Personal LDAP address book.
\$rcmail_config['ldap_public']["ldap_personal"] = array(
    'name'          => 'Personal LDAP Address Book',
    'hosts'         => array('${LDAP_SERVER_HOST}'),
    'port'          => ${LDAP_SERVER_PORT},
    'use_tls'       => false,
    'user_specific' => true,
    'base_dn'       => '${LDAP_ATTR_USER_RDN}=%u@%d,${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}',
    'bind_dn'       => '${LDAP_ATTR_USER_RDN}=%u@%d,${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=%d,${LDAP_BASEDN}',
    'writable'      => true,
    'LDAP_Object_Classes' => array('top', 'inetOrgPerson'),
    'required_fields'     => array('cn', 'mail'),
    'LDAP_rdn'      => 'cn',
    'ldap_version'  => '${LDAP_BIND_VERSION}',
    'search_fields' => array('mail', 'cn', 'givenName', 'sn'),
    'name_field'    => 'cn',
    'email_field'   => 'mail',
    'surname_field' => 'sn',
    'firstname_field' => 'givenName',
    'sort'          => 'cn',
    'scope'         => 'list',
    'filter'        => '(objectClass=inetOrgPerson)',
    'fuzzy_search'  => true);

// end of config file
?>
EOF

        # Store contacts in personal ldap address book.
        #perl -pi -e 's#(.*address_book_type.*=)(.*)#${1} "ldap";#' main.inc.php

        # Enable autocomplete for all address books.
        perl -pi -e 's#(.*autocomplete_addressbooks.*=)(.*)#${1} array("sql", "ldap_global");#' main.inc.php

    #elif [ X"${BACKEND}" == X"MySQL" ]; then
        # Set correct username, password and database name.
    #    perl -pi -e 's#(.*db_dsnw.*= )(.*)#${1}"$ENV{'PHP_CONN_TYPE'}://$ENV{'RCM_DB_USER'}:$ENV{'RCM_DB_PASSWD'}\@$ENV{'MYSQL_SERVER'}/$ENV{'VMAIL_DB'}";#' plugins/changepasswd/config.inc.php
    else
        :
    fi

    # Attachment size.
    perl -pi -e 's#(.*upload_max_filesize.*)5M#${1}10M#' ${RCM_HTTPD_ROOT}/.htaccess
    perl -pi -e 's#(.*post_max_size.*)6M#${1}12M#' ${RCM_HTTPD_ROOT}/.htaccess

    ECHO_DEBUG "Patch: Display Username."
    perl -pi -e 's#(.*id="taskbar">)#${1}\n<span style="padding-right: 3px;"><roundcube:object name="username" /></span>#' ${RCM_HTTPD_ROOT}/skins/default/includes/taskbar.html

    cat >> ${TIP_FILE} <<EOF
Roundcube webmail:
    * Configuration files:
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/
        - ${HTTPD_SERVERROOT}/roundcubemail-${RCM_VERSION}/config/
    * URL:
        - http://${HOSTNAME}/mail/
        - https://${HOSTNAME}/mail/ (Over SSL/TLS)
        - http://${HOSTNAME}/webmail/
        - https://${HOSTNAME}/webmail/ (Over SSL/TLS)
    * Login account:
        - Username: ${FIRST_USER}@${FIRST_DOMAIN}, password: ${FIRST_USER_PASSWD_PLAIN}
    * See also:
        - ${HTTPD_CONF_DIR}/roundcubemail.conf

EOF

    echo 'export status_rcm_config="DONE"' >> ${STATUS_FILE}
}

rcm_plugin_managesieve()
{
    ECHO_DEBUG "Enable and config plugin: managesieve."
    cd ${RCM_HTTPD_ROOT}/config/ && \
    perl -pi -e 's#(.*rcmail_config.*plugins.*=.*array\()(.*)#${1}"managesieve",${2}#' main.inc.php

    export MANAGESIEVE_BINDADDR MANAGESIEVE_PORT DOVECOT_GLOBAL_SIEVE_FILE_SYMBOL
    cd ${RCM_HTTPD_ROOT}/plugins/managesieve/ && \
    cp config.inc.php.dist config.inc.php && \
    perl -pi -e 's#(.*managesieve_port.*=).*#${1} $ENV{'MANAGESIEVE_PORT'};#' config.inc.php
    perl -pi -e 's#(.*managesieve_host.*=).*#${1} "$ENV{'MANAGESIEVE_BINDADDR'}";#' config.inc.php
    perl -pi -e 's#(.*managesieve_usetls.*=).*#${1} false;#' config.inc.php
    perl -pi -e 's#(.*managesieve_default.*=).*#${1} "$ENV{DOVECOT_GLOBAL_SIEVE_FILE_SYMBOL}";#' config.inc.php

    echo 'export status_rcm_plugin_managesieve="DONE"' >> ${STATUS_FILE}
}

rcm_plugin_password()
{
    ECHO_DEBUG "Enable and config plugin: password."
    cd ${RCM_HTTPD_ROOT}/config/ && \
    perl -pi -e 's#(.*rcmail_config.*plugins.*=.*array\()(.*\).*)#${1}"password",${2}#' main.inc.php

    cd ${RCM_HTTPD_ROOT}/plugins/password/ && \
    cp config.inc.php.dist config.inc.php

    perl -pi -e 's#(.*password_confirm_current.*=).*#${1} true;#' config.inc.php
    perl -pi -e 's#(.*password_minimum_length.*=).*#${1} 6;#' config.inc.php
    perl -pi -e 's#(.*password_require_nonalpha.*=).*#${1} false;#' config.inc.php

    if [ X"${BACKEND}" == X"MySQL" ]; then
        perl -pi -e 's#(.*password_driver.*=).*#${1} "sql";#' config.inc.php
        perl -pi -e 's#(.*password_db_dsn.*= )(.*)#${1}"$ENV{'PHP_CONN_TYPE'}://$ENV{'RCM_DB_USER'}:$ENV{'RCM_DB_PASSWD'}\@$ENV{'MYSQL_SERVER'}/$ENV{'VMAIL_DB'}";#' config.inc.php
        perl -pi -e 's#(.*password_query.*=).*#${1} "UPDATE $ENV{'VMAIL_DB'}.mailbox SET password=%c,passwordlastchange=NOW() WHERE username=%u LIMIT 1";#' config.inc.php
        perl -pi -e 's#(.*password_hash_algorithm.*=).*#${1} "md5crypt";#' config.inc.php
        perl -pi -e 's#(.*password_hash_base64.*=).*#${1} false;#' config.inc.php

    elif [ X"${BACKEND}" == X"OpenLDAP" ]; then
        # LDAP backend. Driver: ldap_simple.
        perl -pi -e 's#(.*password_driver.*=).*#${1} "ldap_simple";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_host.*=).*#${1} "$ENV{LDAP_SERVER_HOST}";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_port.*=).*#${1} "$ENV{LDAP_SERVER_PORT}";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_starttls.*=).*#${1} false;#' config.inc.php
        perl -pi -e 's#(.*password_ldap_version.*=).*#${1} "3";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_basedn...=).*#${1} "$ENV{LDAP_BASEDN}";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_method.*=).*#${1} "user";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_adminDN.*=).*#${1} "null";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_adminPW.*=).*#${1} "null";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_userDN_mask...=).*#${1} "$ENV{LDAP_ATTR_USER_RDN}=%login,$ENV{LDAP_ATTR_GROUP_RDN}=$ENV{LDAP_ATTR_GROUP_USERS},$ENV{LDAP_ATTR_DOMAIN_RDN}=%domain,$ENV{LDAP_BASEDN}";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_encodage.*=).*#${1} "ssha";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_pwattr.*=).*#${1} "userPassword";#' config.inc.php
        perl -pi -e 's#(.*password_ldap_force_replace.*=).*#${1} false;#' config.inc.php
        perl -pi -e 's#(.*password_ldap_lchattr.*=).*#${1} "shadowLastChange";#' config.inc.php
    else
        :
    fi

    echo 'export status_rcm_plugin_password="DONE"' >> ${STATUS_FILE}
}
