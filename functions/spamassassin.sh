#!/usr/bin/env bash

# Author: Zhang Huangbin <zhb(at)iredmail.org>

# ---------------------------------------------------------
# SpamAssassin.
# ---------------------------------------------------------
sa_config()
{
    ECHO_INFO "Configure SpamAssassin (content-based spam filter)."

    backup_file ${SA_LOCAL_CF}

    ECHO_DEBUG "Generate new configuration file: ${SA_LOCAL_CF}."
    cp -f ${SAMPLE_DIR}/sa.local.cf ${SA_LOCAL_CF}

    #ECHO_DEBUG "Disable plugin: URIDNSBL."
    #perl -pi -e 's/(^loadplugin.*Mail.*SpamAssassin.*Plugin.*URIDNSBL.*)/#${1}/' ${SA_INIT_PRE}

    ECHO_DEBUG "Enable crontabs for SpamAssassin update."
    if [ X"${DISTRO}" == X"RHEL" ]; then
        chmod 0644 /etc/cron.d/sa-update
        perl -pi -e 's/#(10.*)/${1}/' /etc/cron.d/sa-update
    elif [ X"${DISTRO}" == X"UBUNTU" -o X"${DISTRO}" == X"DEBIAN" ]; then
        perl -pi -e 's#^(CRON=)0#${1}1#' /etc/cron.daily/spamassassin
    else
        :
    fi

    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        ECHO_DEBUG "Compile SpamAssassin ruleset into native code."
        sa-compile >/dev/null 2>&1
    fi

    cat >> ${TIP_FILE} <<EOF
SpamAssassin:
    * Configuration files and rules:
        - ${SA_CONF_DIR}
        - ${SA_CONF_DIR}/local.cf

EOF

    echo 'export status_sa_config="DONE"' >> ${STATUS_FILE}
}
