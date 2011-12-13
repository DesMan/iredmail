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
# ------------- Install and config backend. -------------
# -------------------------------------------------------
backend_install()
{
    if [ X"${BACKEND}" == X"OpenLDAP" ]; then
        # Install, config and initialize OpenLDAP.
        check_status_before_run openldap_config && \
        check_status_before_run openldap_data_initialize

        # Initialize MySQL database server.
        check_status_before_run mysql_initialize
    elif [ X"${BACKEND}" == X"MySQL" ]; then
        # Initialize MySQL.
        check_status_before_run mysql_initialize
        check_status_before_run mysql_import_vmail_users
    else
        :
    fi
}
