#!/usr/bin/perl
#
######################################################################
# LedgerSMB Accounting and ERP

# http://www.ledgersmb.org/
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (C) 2001
#
#  Author: Dieter Simader
#   Email: dsimader@sql-ledger.org
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#######################################################################
#
# this script is the frontend called from bin/$terminal/$script
# all the accounting modules are linked to this script which in
# turn execute the same script in bin/$terminal/
#
#######################################################################

use LedgerSMB::Sysconfig;
use Digest::MD5;

$| = 1;

use LedgerSMB::User;
use LedgerSMB::Form;
use LedgerSMB::Locale;
use LedgerSMB::Session;
use Data::Dumper;
require "common.pl";

# for custom preprocessing logic
eval { require "custom.pl"; };

$form = new Form;

# name of this script
$0 =~ tr/\\/\//;
$pos = rindex $0, '/';
$script = substr( $0, $pos + 1 );

$locale = LedgerSMB::Locale->get_handle( ${LedgerSMB::Sysconfig::language} )
  or $form->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );

# we use $script for the language module
$form->{script} = $script;

# strip .pl for translation files
$script =~ s/\.pl//;

# pull in DBI
use DBI qw(:sql_types);

# send warnings to browser
$SIG{__WARN__} = sub { $form->info( $_[0] ) };

# send errors to browser
$SIG{__DIE__} =
  sub { $form->error( __FILE__ . ':' . __LINE__ . ': ' . $_[0] ) };

## did sysadmin lock us out
#if (-f "${LedgerSMB::Sysconfig::userspath}/nologin") {
#	$locale = LedgerSMB::Locale->get_handle(${LedgerSMB::Sysconfig::language}) or
#		$form->error(__FILE__.':'.__LINE__.": Locale not loaded: $!\n");
#	$form->{charset} = 'UTF-8';
#	$locale->encoding('UTF-8');
#
#	$form->{callback} = "";
#	$form->error(__FILE__.':'.__LINE__.': '.$locale->text('System currently down for maintenance!'));
#}

&check_password;

# grab user config. This is ugly and unecessary if/when
# we get rid of myconfig and use User as a real object
%myconfig = %{ LedgerSMB::User->fetch_config( $form->{login} ) };
$locale   = LedgerSMB::Locale->get_handle( $myconfig{countrycode} )
  or $form->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );

# locale messages
#$form->{charset} = $locale->encoding;
$form->{charset} = 'UTF-8';
$locale->encoding('UTF-8');

if ($@) {
    $form->{callback} = "";
    $msg1             = $locale->text('You are logged out!');
    $msg2             = $locale->text('Login');
    $form->redirect(
        "$msg1 <p><a href=\"login.pl\" target=\"_top\">$msg2</a></p>");
}

map { $form->{$_} = $myconfig{$_} } qw(stylesheet timeout)
  unless ( $form->{type} eq 'preferences' );

$form->db_init( \%myconfig );

# pull in the main code
require "bin/$form->{script}";

# customized scripts
if ( -f "bin/custom/$form->{script}" ) {
    eval { require "bin/custom/$form->{script}"; };
}

# customized scripts for login
if ( -f "bin/custom/$form->{login}_$form->{script}" ) {
    eval { require "bin/custom/$form->{login}_$form->{script}"; };
}

if ( $form->{action} ) {

    # window title bar, user info
    $form->{titlebar} =
        "LedgerSMB "
      . $locale->text('Version')
      . " $form->{version} - $myconfig{name} - $myconfig{dbname}";

    &{ $form->{action} };

}
else {
    $form->error( __FILE__ . ':' . __LINE__ . ': '
          . $locale->text('action= not defined!') );
}

1;

# end

sub check_password {

    require "bin/pw.pl";

    if ( $form->{password} ) {
        if (
            !Session::password_check(
                $form, $form->{login}, $form->{password}
            )
          )
        {
            if ( $ENV{GATEWAY_INTERFACE} ) {
                &getpassword;
            }
            else {
                $form->error( __FILE__ . ':' . __LINE__ . ': '
                      . $locale->text('Access Denied!') );
            }
            exit;
        }
        else {
            Session::session_create($form);
        }

    }
    else {
        if ( $ENV{GATEWAY_INTERFACE} ) {
            $ENV{HTTP_COOKIE} =~ s/;\s*/;/g;
            @cookies = split /;/, $ENV{HTTP_COOKIE};
            foreach (@cookies) {
                ( $name, $value ) = split /=/, $_, 2;
                $cookie{$name} = $value;
            }

            #check for valid session
            if ( !Session::session_check( $cookie{"LedgerSMB"}, $form ) ) {
                &getpassword(1);
                exit;
            }
        }
        else {
            exit;
        }
    }
}

