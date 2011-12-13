#!/usr/bin/env bash

# Author: Zhang Huangbin <zhb(at)iredmail.org>

# -------------------------------------------
# Install all optional components.
# -------------------------------------------
optional_components()
{
    # Roundcubemail.
    [ X"${USE_RCM}" == X"YES" ] && \
        check_status_before_run rcm_install && \
        check_status_before_run rcm_config_httpd && \
        check_status_before_run rcm_import_sql && \
        check_status_before_run rcm_config && \
        check_status_before_run rcm_plugin_managesieve && \
        check_status_before_run rcm_plugin_password

    # phpLDAPadmin.
    [ X"${USE_PHPLDAPADMIN}" == X"YES" ] && \
        check_status_before_run pla_install

    # phpMyAdmin
    [ X"${USE_PHPMYADMIN}" == X"YES" ] && \
        check_status_before_run phpmyadmin_install

    # Awstats.
    [ X"${USE_AWSTATS}" == X"YES" ] && \
        check_status_before_run awstats_config_basic && \
        check_status_before_run awstats_config_weblog && \
        check_status_before_run awstats_config_maillog && \
        check_status_before_run awstats_config_crontab

    # iRedAdmin.
    [ X"${USE_IREDADMIN}" == X"YES" ] && \
        check_status_before_run iredadmin_config

    # iRedAPD.
    [ X"${USE_IREDAPD}" == X"YES" ] && \
        check_status_before_run iredapd_config

    # Fail2ban.
    [ X"${USE_FAIL2BAN}" == X"YES" -a X"${DISTRO}" != X"FREEBSD" ] && \
        check_status_before_run fail2ban_config

}
