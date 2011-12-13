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

#
# Based on original postfixadmin template.
# http://postfixadmin.sf.net
#

#
# Table structure for table admin
#
CREATE TABLE IF NOT EXISTS admin (
    username VARCHAR(255) NOT NULL DEFAULT '',
    password VARCHAR(255) NOT NULL DEFAULT '',
    name VARCHAR(255) NOT NULL DEFAULT '',
    language VARCHAR(5) NOT NULL DEFAULT 'en_US',
    passwordlastchange DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (username),
    INDEX (passwordlastchange),
    INDEX (expired),
    INDEX (active)
) ENGINE=MyISAM;

#
# Table structure for table alias
#
CREATE TABLE IF NOT EXISTS alias (
    address VARCHAR(255) NOT NULL DEFAULT '',
    goto TEXT NOT NULL DEFAULT '',
    name VARCHAR(255) NOT NULL DEFAULT '',
    moderators TEXT NOT NULL DEFAULT '',
    accesspolicy VARCHAR(30) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (address),
    INDEX (domain),
    INDEX (expired),
    INDEX (active)
) ENGINE=MyISAM;

#
# Table structure for table domain
#
CREATE TABLE IF NOT EXISTS domain (
    -- mail domain name. e.g. iredmail.org.
    domain VARCHAR(255) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    -- Disclaimer text. Used by Amavisd + AlterMIME.
    disclaimer TEXT NOT NULL DEFAULT '',
    -- Max alias accounts in this domain. e.g. 10.
    aliases INT(10) NOT NULL DEFAULT 0,
    -- Max mail accounts in this domain. e.g. 100.
    mailboxes INT(10) NOT NULL DEFAULT 0,
    -- Max mailbox quota in this domain. e.g. 1073741824 (1GB).
    maxquota BIGINT(20) NOT NULL DEFAULT 0,
    quota BIGINT(20) NOT NULL DEFAULT 0,
    -- Per-domain transport. e.g. dovecot, smtp:[192.168.1.1]:25
    transport VARCHAR(255) NOT NULL DEFAULT 'dovecot',
    backupmx TINYINT(1) NOT NULL DEFAULT 0,
    -- Default quota size for newly created mail account.
    defaultuserquota BIGINT(20) NOT NULL DEFAULT '1024',
    -- List of mail alias addresses, Newly created user will be
    -- assigned to them.
    defaultuseraliases TEXT NOT NULL DEFAULT '',
    -- Default password scheme. e.g. md5, plain.
    defaultpasswordscheme VARCHAR(10) NOT NULL DEFAULT '',
    -- Minimal password length, per-domain setting.
    minpasswordlength INT(10) NOT NULL DEFAULT 0,
    -- Max password length, per-domain setting.
    maxpasswordlength INT(10) NOT NULL DEFAULT 0,
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (domain),
    INDEX (backupmx),
    INDEX (expired),
    INDEX (active)
) ENGINE=MyISAM;

CREATE TABLE IF NOT EXISTS `alias_domain` (
    alias_domain VARCHAR(255) NOT NULL,
    target_domain VARCHAR(255) NOT NULL,
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (alias_domain),
    INDEX (target_domain),
    INDEX (active)
) ENGINE=MyISAM;

#
# Table structure for table domain_admins
#
CREATE TABLE IF NOT EXISTS domain_admins (
    username VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    domain VARCHAR(255) CHARACTER SET ascii NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (username,domain),
    INDEX (username),
    INDEX (domain),
    INDEX (active)
) ENGINE=MyISAM;

#
# Table structure for table mailbox
#
CREATE TABLE IF NOT EXISTS mailbox (
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL DEFAULT '',
    name VARCHAR(255) NOT NULL DEFAULT '',
    storagebasedirectory VARCHAR(255) NOT NULL DEFAULT '',
    storagenode VARCHAR(255) NOT NULL DEFAULT '',
    maildir VARCHAR(255) NOT NULL DEFAULT '',
    quota BIGINT(20) NOT NULL DEFAULT 0, -- Total mail quota size
    bytes BIGINT(20) NOT NULL DEFAULT 0, -- Number of used quota size
    messages BIGINT(20) NOT NULL DEFAULT 0, -- Number of current messages
    domain VARCHAR(255) NOT NULL DEFAULT '',
    transport VARCHAR(255) NOT NULL DEFAULT '',
    department VARCHAR(255) NOT NULL DEFAULT '',
    rank VARCHAR(255) NOT NULL DEFAULT 'normal',
    employeeid VARCHAR(255) DEFAULT '',
    enablesmtp TINYINT(1) NOT NULL DEFAULT 1,
    enablesmtpsecured TINYINT(1) NOT NULL DEFAULT 1,
    enablepop3 TINYINT(1) NOT NULL DEFAULT 1,
    enablepop3secured TINYINT(1) NOT NULL DEFAULT 1,
    enableimap TINYINT(1) NOT NULL DEFAULT 1,
    enableimapsecured TINYINT(1) NOT NULL DEFAULT 1,
    enabledeliver TINYINT(1) NOT NULL DEFAULT 1,
    enablelda TINYINT(1) NOT NULL DEFAULT 1,
    enablemanagesieve TINYINT(1) NOT NULL DEFAULT 1,
    enablemanagesievesecured TINYINT(1) NOT NULL DEFAULT 1,
    enablesieve TINYINT(1) NOT NULL DEFAULT 1,
    enablesievesecured TINYINT(1) NOT NULL DEFAULT 1,
    enableinternal TINYINT(1) NOT NULL DEFAULT 1,
    lastlogindate DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    lastloginipv4 INT(4) UNSIGNED NOT NULL DEFAULT 0,
    lastloginprotocol CHAR(255) NOT NULL DEFAULT '',
    disclaimer TEXT NOT NULL DEFAULT '',
    passwordlastchange DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    local_part VARCHAR(255) NOT NULL DEFAULT '', -- Required by PostfixAdmin
    PRIMARY KEY (username),
    INDEX (domain),
    INDEX (department),
    INDEX (employeeid),
    INDEX (enablesmtp),
    INDEX (enablesmtpsecured),
    INDEX (enablepop3),
    INDEX (enablepop3secured),
    INDEX (enableimap),
    INDEX (enableimapsecured),
    INDEX (enabledeliver),
    INDEX (enablelda),
    INDEX (enablemanagesieve),
    INDEX (enablemanagesievesecured),
    INDEX (enablesieve),
    INDEX (enablesievesecured),
    INDEX (enableinternal),
    INDEX (passwordlastchange),
    INDEX (expired),
    INDEX (active)
) ENGINE=MyISAM;

#
# Table structure for table sender_bcc_domain
#
CREATE TABLE IF NOT EXISTS sender_bcc_domain (
    domain VARCHAR(255) NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (domain),
    INDEX (bcc_address),
    INDEX (expired),
    INDEX (active)
) ENGINE=MyISAM;

#
# Table structure for table sender_bcc_user
#
CREATE TABLE IF NOT EXISTS sender_bcc_user (
    username VARCHAR(255) NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (username),
    INDEX (bcc_address),
    INDEX (domain),
    INDEX (expired),
    INDEX (active)
) ENGINE=MyISAM;

#
# Table structure for table recipient_bcc_domain
#
CREATE TABLE IF NOT EXISTS recipient_bcc_domain (
    domain VARCHAR(255) NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (domain),
    INDEX (bcc_address),
    INDEX (expired),
    INDEX (active)
) ENGINE=MyISAM;

#
# Table structure for table recipient_bcc_user
#
CREATE TABLE IF NOT EXISTS recipient_bcc_user (
    username VARCHAR(255) NOT NULL DEFAULT '',
    bcc_address VARCHAR(255) NOT NULL DEFAULT '',
    domain VARCHAR(255) NOT NULL DEFAULT '',
    created DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    expired DATETIME NOT NULL DEFAULT '9999-12-31 00:00:00',
    active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (username),
    INDEX (bcc_address),
    INDEX (expired),
    INDEX (active)
) ENGINE=MyISAM;

#
# IMAP shared folders. User 'from_user' shares folders to user 'to_user'.
# WARNING: Works only with Dovecot 1.2+.
#
CREATE TABLE IF NOT EXISTS share_folder (
    from_user VARCHAR(255) CHARACTER SET ascii NOT NULL,
    to_user VARCHAR(255) CHARACTER SET ascii NOT NULL,
    dummy CHAR(1),
    PRIMARY KEY (from_user, to_user),
    INDEX (from_user),
    INDEX (to_user)
);
