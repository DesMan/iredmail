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

# ----------------------------------------
# Optional components for special backend.
# ----------------------------------------
export tmp_config_optional_components="${ROOTDIR}/.optional_components"

if [ X"${BACKEND}" == X"OpenLDAP" ]; then
    ${DIALOG} \
    --title "Optional Components for ${BACKEND} backend" \
    --checklist "\
Note:
    * DKIM is recommended.
    * SPF validation (Sender Policy Framework) is enabled by default.
    * DNS records (TXT type) are required for both SPF and DKIM.
    * Refer to file for more detail after installation:
      ${TIP_FILE}
" 20 76 8 \
    "DKIM signing/verification" "DomainKeys Identified Mail" "on" \
    "iRedAdmin" "Official web-based Admin Panel" "on" \
    "Roundcubemail" "WebMail program (PHP, AJAX)" "on" \
    "phpLDAPadmin" "Web-based OpenLDAP management tool" "on" \
    "phpMyAdmin" "Web-based MySQL management tool" "on" \
    "Awstats" "Advanced web and mail log analyzer" "on" \
    "Fail2ban" "Ban IP with too many password failures" "on" \
    2>${tmp_config_optional_components}

elif [ X"${BACKEND}" == X"MySQL" ]; then
    ${DIALOG} \
    --title "Optional Components for ${BACKEND} backend" \
    --checklist "\
Note:
    * DKIM is recommended.
    * SPF validation (Sender Policy Framework) is enabled by default.
    * DNS record (TXT type) are required for both SPF and DKIM.
    * Please refer to file for more detail after installation:
      ${TIP_FILE}
" 20 76 8 \
    "DKIM signing/verification" "DomainKeys Identified Mail" "on" \
    "Roundcubemail" "WebMail program (PHP, AJAX)" "on" \
    "phpMyAdmin" "Web-based MySQL management tool" "on" \
    "iRedAdmin" "Official web-based Admin Panel" "on" \
    "Awstats" "Advanced web and mail log analyzer" "on" \
    "Fail2ban" "Ban IP with too many password failures" "on" \
    2>${tmp_config_optional_components}
else
    # No hook for other backend yet.
    :
fi

OPTIONAL_COMPONENTS="$(cat ${tmp_config_optional_components})"
rm -f ${tmp_config_optional_components}

echo ${OPTIONAL_COMPONENTS} | grep -i '\<SPF\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && export ENABLE_SPF='YES' && echo "export ENABLE_SPF='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i '\<DKIM\>' >/dev/null 2>&1
[ X"$?" == X"0" ] && export ENABLE_DKIM='YES' && echo "export ENABLE_DKIM='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'iredadmin' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_IREDADMIN='YES' && export USE_IREDADMIN='YES' && echo "export USE_IREDADMIN='YES'" >> ${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'roundcubemail' >/dev/null 2>&1
if [ X"$?" == X"0" ]; then
    export USE_WEBMAIL='YES'
    export USE_RCM='YES'
    echo "export USE_WEBMAIL='YES'" >> ${CONFIG_FILE}
    echo "export USE_RCM='YES'" >> ${CONFIG_FILE}
    echo "export REQUIRE_PHP='YES'" >> ${CONFIG_FILE}
fi

echo ${OPTIONAL_COMPONENTS} | grep -i 'phpldapadmin' >/dev/null 2>&1
if [ X"$?" == X"0" ]; then
    export USE_PHPLDAPADMIN='YES'
    echo "export USE_PHPLDAPADMIN='YES'" >>${CONFIG_FILE}
    echo "export REQUIRE_PHP='YES'" >> ${CONFIG_FILE}
fi

echo ${OPTIONAL_COMPONENTS} | grep -i 'phpmyadmin' >/dev/null 2>&1
if [ X"$?" == X"0" ]; then
    export USE_PHPMYADMIN='YES'
    echo "export USE_PHPMYADMIN='YES'" >>${CONFIG_FILE}
    echo "export REQUIRE_PHP='YES'" >> ${CONFIG_FILE}
fi

echo ${OPTIONAL_COMPONENTS} | grep -i 'awstats' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_AWSTATS='YES' && echo "export USE_AWSTATS='YES'" >>${CONFIG_FILE}

echo ${OPTIONAL_COMPONENTS} | grep -i 'fail2ban' >/dev/null 2>&1
[ X"$?" == X"0" ] && export USE_FAIL2BAN='YES' && echo "export USE_FAIL2BAN='YES'" >>${CONFIG_FILE}

# ----------------------------------------------------------------
# Promot to choose the prefer language for webmail.
[ X"${USE_WEBMAIL}" == X"YES" ] && . ${DIALOG_DIR}/default_language.sh

# Used when you use awstats.
[ X"${USE_AWSTATS}" == X"YES" ] && . ${DIALOG_DIR}/awstats_config.sh
