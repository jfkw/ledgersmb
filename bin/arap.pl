#=====================================================================
# LedgerSMB Small Medium Business Accounting
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
# Copyright (c) 2003
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
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
#======================================================================
#
# common routines for gl, ar, ap, is, ir, oe
#

use LedgerSMB::AA;

# any custom scripts for this one
if ( -f "bin/custom/arap.pl" ) {
    eval { require "bin/custom/arap.pl"; };
}
if ( -f "bin/custom/$form->{login}_arap.pl" ) {
    eval { require "bin/custom/$form->{login}_arap.pl"; };
}

1;

# end of main

sub check_name {
    my ($name) = @_;

    my ( $new_name, $new_id ) = split /--/, $form->{$name};
    my $rv = 0;

    # if we use a selection
    if ( $form->{"select$name"} ) {
        if ( $form->{"old$name"} ne $form->{$name} ) {

            # this is needed for is, ir and oe
            for ( split / /, $form->{taxaccounts} ) {
                delete $form->{"${_}_rate"};
            }

            # for credit calculations
            $form->{oldinvtotal}  = 0;
            $form->{oldtotalpaid} = 0;
            $form->{calctax}      = 1;

            $form->{"${name}_id"} = $new_id;
            AA->get_name( \%myconfig, \%$form );

            $form->{$name} = $form->{"old$name"} = "$new_name--$new_id";
            $form->{currency} =~ s/ //g;

            # put employee together if there is a new employee_id
            $form->{employee} = "$form->{employee}--$form->{employee_id}"
              if $form->{employee_id};

            $rv = 1;
        }
    }
    else {

        # check name, combine name and id
        if ( $form->{"old$name"} ne qq|$form->{$name}--$form->{"${name}_id"}| )
        {

            # this is needed for is, ir and oe
            for ( split / /, $form->{taxaccounts} ) {
                delete $form->{"${_}_rate"};
            }

            # for credit calculations
            $form->{oldinvtotal}  = 0;
            $form->{oldtotalpaid} = 0;
            $form->{calctax}      = 1;

            # return one name or a list of names in $form->{name_list}
            if (
                (
                    $rv =
                    $form->get_name( \%myconfig, $name, $form->{transdate} )
                ) > 1
              )
            {
                &select_name($name);
                exit;
            }

            if ( $rv == 1 ) {

                # we got one name
                $form->{"${name}_id"} = $form->{name_list}[0]->{id};
                $form->{$name} = $form->{name_list}[0]->{name};
                $form->{"old$name"} = qq|$form->{$name}--$form->{"${name}_id"}|;

                AA->get_name( \%myconfig, \%$form );

                $form->{currency} =~ s/ //g;

                # put employee together if there is a new employee_id
                $form->{employee} = "$form->{employee}--$form->{employee_id}"
                  if $form->{employee_id};

            }
            else {

                # name is not on file
                $msg = ucfirst $name . " not on file!";
                $form->error( $locale->text($msg) );
            }
        }
    }

    $rv;

}

# $locale->text('Customer not on file!')
# $locale->text('Vendor not on file!')

sub select_name {
    my ($table) = @_;

    @column_index = qw(ndx name address);

    $label = ucfirst $table;
    $column_data{ndx} = qq|<th>&nbsp;</th>|;
    $column_data{name} =
      qq|<th class=listheading>| . $locale->text($label) . qq|</th>|;
    $column_data{address} =
        qq|<th class=listheading colspan=5>|
      . $locale->text('Address')
      . qq|</th>|;

    # list items with radio button on a form
    $form->header;

    $title = $locale->text('Select from one of the names below');

    print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
	</tr>
|;

    @column_index = qw(ndx name address city state zipcode country);

    my $i = 0;
    foreach $ref ( @{ $form->{name_list} } ) {
        $checked = ( $i++ ) ? "" : "checked";

        $ref->{name} = $form->quote( $ref->{name} );

        $column_data{ndx} =
qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
        $column_data{name} =
qq|<td><input name="new_name_$i" type=hidden value="$ref->{name}">$ref->{name}</td>|;
        $column_data{address} = qq|<td>$ref->{address1} $ref->{address2}</td>|;
        for (qw(city state zipcode country)) {
            $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>|;
        }

        $j++;
        $j %= 2;
        print qq|
	<tr class=listrow$j>|;

        for (@column_index) { print "\n$column_data{$_}" }

        print qq|
	</tr>

<input name="new_id_$i" type=hidden value=$ref->{id}>

|;

    }

    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=lastndx type=hidden value=$i>

|;

    # delete variables
    for (qw(nextsub name_list)) { delete $form->{$_} }

    $form->{action} = "name_selected";

    $form->hide_form;

    print qq|
<input type=hidden name=nextsub value=name_selected>
<input type=hidden name=vc value="$table">
<br>
<button class="submit" type="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub name_selected {

    # replace the variable with the one checked

    # index for new item
    $i = $form->{ndx};

    $form->{ $form->{vc} } = $form->{"new_name_$i"};
    $form->{"$form->{vc}_id"} = $form->{"new_id_$i"};
    $form->{"old$form->{vc}"} =
      qq|$form->{$form->{vc}}--$form->{"$form->{vc}_id"}|;

    # delete all the new_ variables
    for $i ( 1 .. $form->{lastndx} ) {
        for (qw(id, name)) { delete $form->{"new_${_}_$i"} }
    }

    for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

    AA->get_name( \%myconfig, \%$form );

    # put employee together if there is a new employee_id
    $form->{employee} = "$form->{employee}--$form->{employee_id}"
      if $form->{employee_id};

    &update(1);

}

sub rebuild_vc {
    my ( $vc, $ARAP, $transdate, $job ) = @_;

    ( $null, $form->{employee_id} ) = split /--/, $form->{employee};
    $form->all_vc( \%myconfig, $vc, $ARAP, undef, $transdate, $job );
    $form->{"select$vc"} = "";
    for ( @{ $form->{"all_$vc"} } ) {
        $form->{"select$vc"} .=
          qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
    }

    $form->{selectprojectnumber} = "";
    if ( @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option>\n";
        for ( @{ $form->{all_project} } ) {
            $form->{selectprojectnumber} .=
qq|<option value="$_->{projectnumber}--$_->{id}">$_->{projectnumber}\n|;
        }
    }

    1;
}

sub add_transaction {
    my ($module) = @_;

    delete $form->{script};
    $form->{action} = "add";
    $form->{type} = "invoice" if $module =~ /(is|ir)/;

    $form->{callback} = $form->escape( $form->{callback}, 1 );
    $argv = "";
    for ( keys %$form ) { $argv .= "$_=$form->{$_}&" if $_ ne 'dbh' }

    $form->{callback} = "$module.pl?$argv";

    $form->redirect;

}

sub check_project {

    for $i ( 1 .. $form->{rowcount} ) {
        $form->{"project_id_$i"} = "" unless $form->{"projectnumber_$i"};
        if ( $form->{"projectnumber_$i"} ne $form->{"oldprojectnumber_$i"} ) {
            if ( $form->{"projectnumber_$i"} ) {

                # get new project
                $form->{projectnumber} = $form->{"projectnumber_$i"};
                if ( ( $rows = PE->projects( \%myconfig, $form ) ) > 1 ) {

                    # check form->{project_list} how many there are
                    $form->{rownumber} = $i;
                    &select_project;
                    exit;
                }

                if ( $rows == 1 ) {
                    $form->{"project_id_$i"} = $form->{project_list}->[0]->{id};
                    $form->{"projectnumber_$i"} =
                      $form->{project_list}->[0]->{projectnumber};
                    $form->{"oldprojectnumber_$i"} =
                      $form->{project_list}->[0]->{projectnumber};
                }
                else {

                    # not on file
                    $form->error( $locale->text('Project not on file!') );
                }
            }
            else {
                $form->{"oldprojectnumber_$i"} = "";
            }
        }
    }

}

sub select_project {

    @column_index = qw(ndx projectnumber description);

    $column_data{ndx} = qq|<th>&nbsp;</th>|;
    $column_data{projectnumber} =
      qq|<th>| . $locale->text('Number') . qq|</th>|;
    $column_data{description} =
      qq|<th>| . $locale->text('Description') . qq|</th>|;

    # list items with radio button on a form
    $form->header;

    $title = $locale->text('Select from one of the projects below');

    print qq|
<body>

<form method=post action=$form->{script}>

<input type=hidden name=rownumber value=$form->{rownumber}>

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

    for (@column_index) { print "\n$column_data{$_}" }

    print qq|
        </tr>
|;

    my $i = 0;
    foreach $ref ( @{ $form->{project_list} } ) {
        $checked = ( $i++ ) ? "" : "checked";

        $ref->{name} = $form->quote( $ref->{name} );

        $column_data{ndx} =
qq|<td><input name=ndx class=radio type=radio value=$i $checked></td>|;
        $column_data{projectnumber} =
qq|<td><input name="new_projectnumber_$i" type=hidden value="$ref->{projectnumber}">$ref->{projectnumber}</td>|;
        $column_data{description} = qq|<td>$ref->{description}</td>|;

        $j++;
        $j %= 2;
        print qq|
        <tr class=listrow$j>|;

        for (@column_index) { print "\n$column_data{$_}" }

        print qq|
        </tr>

<input name="new_id_$i" type=hidden value=$ref->{id}>

|;

    }

    print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input name=lastndx type=hidden value=$i>

|;

    # delete list variable
    for (qw(nextsub project_list)) { delete $form->{$_} }

    $form->{action} = "project_selected";

    $form->hide_form;

    print qq|
<input type=hidden name=nextsub value=project_selected>
<br>
<button class="submit" type="submit" name="action" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub project_selected {

    # replace the variable with the one checked

    # index for new item
    $i = $form->{ndx};

    $form->{"projectnumber_$form->{rownumber}"} =
      $form->{"new_projectnumber_$i"};
    $form->{"oldprojectnumber_$form->{rownumber}"} =
      $form->{"new_projectnumber_$i"};
    $form->{"project_id_$form->{rownumber}"} = $form->{"new_id_$i"};

    # delete all the new_ variables
    for $i ( 1 .. $form->{lastndx} ) {
        for (qw(id projectnumber description)) { delete $form->{"new_${_}_$i"} }
    }

    for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

    if ( $form->{update} ) {
        &{ $form->{update} };
    }
    else {
        &update;
    }

}

sub post_as_new {

    for (qw(id printed emailed queued)) { delete $form->{$_} }
    &post;

}

sub print_and_post_as_new {

    for (qw(id printed emailed queued)) { delete $form->{$_} }
    &print_and_post;

}

sub repost {

    if ( $form->{type} =~ /_order/ ) {
        if ( $form->{print_and_save} ) {
            $form->{nextsub} = "print_and_save";
            $msg =
              $locale->text('You are printing and saving an existing order');
        }
        else {
            $form->{nextsub} = "save";
            $msg = $locale->text('You are saving an existing order');
        }
    }
    elsif ( $form->{type} =~ /_quotation/ ) {
        if ( $form->{print_and_save} ) {
            $form->{nextsub} = "print_and_save";
            $msg =
              $locale->text(
                'You are printing and saving an existing quotation');
        }
        else {
            $form->{nextsub} = "save";
            $msg = $locale->text('You are saving an existing quotation');
        }
    }
    else {
        if ( $form->{print_and_post} ) {
            $form->{nextsub} = "print_and_post";
            $msg =
              $locale->text(
                'You are printing and posting an existing transaction!');
        }
        else {
            $form->{nextsub} = "post";
            $msg = $locale->text('You are posting an existing transaction!');
        }
    }

    delete $form->{action};
    $form->{repost} = 1;

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>
|;

    $form->hide_form;

    print qq|
<h2 class=confirm>| . $locale->text('Warning!') . qq|</h2>

<h4>$msg</h4>

<button name="action" class="submit" type="submit" value="continue">|
      . $locale->text('Continue')
      . qq|</button>
</form>

</body>
</html>
|;

}

sub schedule {

    (
        $form->{recurringreference}, $form->{recurringstartdate},
        $form->{recurringrepeat},    $form->{recurringunit},
        $form->{recurringhowmany},   $form->{recurringpayment},
        $form->{recurringprint},     $form->{recurringemail},
        $form->{recurringmessage}
    ) = split /,/, $form->{recurring};

    $form->{recurringreference} =
      $form->quote( $form->unescape( $form->{recurringreference} ) );
    $form->{recurringmessage} =
      $form->quote( $form->unescape( $form->{recurringmessage} ) );

    $form->{recurringstartdate} ||= $form->{transdate};
    $recurringpayment = "checked" if $form->{recurringpayment};

    if ( $form->{paidaccounts} ) {
        $postpayment = qq|
 	<tr>
	  <th align=right nowrap>| . $locale->text('Include Payment') . qq|</th>
	  <td><input name=recurringpayment type=checkbox class=checkbox value=1 $recurringpayment></td>
	</tr>
|;
    }

    if ( $form->{recurringnextdate} ) {
        $nextdate = qq|
	      <tr>
		<th align=right nowrap>| . $locale->text('Next Date') . qq|</th>
		<td><input name=recurringnextdate size=11 title="($myconfig{'dateformat'})" value=$form->{recurringnextdate}></td>
	      </tr>
|;
    }

    @a = split /<option/, $form->unescape( $form->{selectformname} );
    %formname = ();

    for ( $i = 1 ; $i <= $#a ; $i++ ) {
        $a[$i] =~ /"(.*)"/;
        $v = $1;
        $a[$i] =~ />(.*)/;
        $formname{$v} = $1;
    }
    for (qw(check receipt)) { delete $formname{$_} }

    $selectformat = $form->unescape( $form->{selectformat} );

    if ( $form->{type} !~ /transaction/ && %formname ) {
        $email = qq|
	<table>
	  <tr>
	    <th colspan=2 class=listheading>| . $locale->text('E-mail') . qq|</th>
	  </tr>
	  
	  <tr>
	    <td>
	      <table>
|;

        # formname:format
        @p = split /:/, $form->{recurringemail};
        %p = ();
        for ( $i = 0 ; $i <= $#p ; $i += 2 ) {
            $p{ $p[$i] }{format} = $p[ $i + 1 ];
        }

        foreach $item ( keys %formname ) {

            $checked = ( $p{$item}{format} ) ? "checked" : "";
            $selectformat =~ s/ selected//;
            $p{$item}{format} ||= "pdf";
            $selectformat =~
              s/(<option value="\Q$p{$item}{format}\E")/$1 selected/;

            $email .= qq|
		<tr>
		  <td><input name="email$item" type=checkbox class=checkbox value=1 $checked></td>
		  <th align=left>$formname{$item}</th>
		  <td><select name="emailformat$item">$selectformat</select></td>
		</tr>
|;
        }

        $email .= qq|
	      </table>
	    </td>
	  </tr>
	</table>
|;

        $message = qq|
	<table>
	  <tr>
	    <th class=listheading>| . $locale->text('E-mail message') . qq|</th>
	  </tr>

	  <tr>
	    <td><textarea name="recurringmessage" rows=10 cols=60 wrap=soft>$form->{recurringmessage}</textarea></td>
	  </tr>
	</table>
|;

    }

    if (   %{LedgerSMB::Sysconfig::printer}
        && ${LedgerSMB::Sysconfig::latex}
        && %formname )
    {
        $selectprinter = qq|<option>\n|;
        for ( sort keys %{LedgerSMB::Sysconfig::printer} ) {
            $selectprinter .= qq|<option value="$_">$_\n|;
        }

        # formname:format:printer
        @p = split /:/, $form->{recurringprint};

        %p = ();
        for ( $i = 0 ; $i <= $#p ; $i += 3 ) {
            $p{ $p[$i] }{formname} = $p[$i];
            $p{ $p[$i] }{format}   = $p[ $i + 1 ];
            $p{ $p[$i] }{printer}  = $p[ $i + 2 ];
        }

        $print = qq|
	<table>
	  <tr>
	    <th colspan=2 class=listheading>| . $locale->text('Print') . qq|</th>
	  </tr>

	  <tr>
	    <td>
	      <table>
|;

        $selectformat =~ s/<option.*html//;
        foreach $item ( keys %formname ) {

            $selectprinter =~ s/ selected//;
            $selectprinter =~
              s/(<option value="\Q$p{$item}{printer}\E")/$1 selected/;

            $checked = ( $p{$item}{formname} ) ? "checked" : "";

            $selectformat =~ s/ selected//;
            $p{$item}{format} ||= "postscript";
            $selectformat =~
              s/(<option value="\Q$p{$item}{format}\E")/$1 selected/;

            $print .= qq|
		<tr>
		  <td><input name="print$item" type=checkbox class=checkbox value=1 $checked></td>
		  <th align=left>$formname{$item}</th>
		  <td><select name="printprinter$item">$selectprinter</select></td>
		  <td><select name="printformat$item">$selectformat</select></td>
		</tr>
|;
        }

        $print .= qq|
	      </table>
	    </td>
	  </tr>
	</table>
|;

    }

    $selectrepeat = "";
    for ( 1 .. 31 ) { $selectrepeat .= qq|<option value="$_">$_\n| }
    $selectrepeat =~ s/(<option value="$form->{recurringrepeat}")/$1 selected/;

    $selectunit = qq|<option value="days">| . $locale->text('Day(s)') . qq|
  <option value="weeks">| . $locale->text('Week(s)') . qq|
  <option value="months">| . $locale->text('Month(s)') . qq|
  <option value="years">| . $locale->text('Year(s)');

    if ( $form->{recurringunit} ) {
        $selectunit =~ s/(<option value="$form->{recurringunit}")/$1 selected/;
    }

    if ( $form->{ $form->{vc} } ) {
        $description = $form->{ $form->{vc} };
    }
    else {
        $description = $form->{description};
    }

    $repeat = qq|
	    <table>
	      <tr>
		<th colspan=3  class=listheading>| . $locale->text('Repeat') . qq|</th>
	      </tr>

	      <tr>
		<th align=right nowrap>| . $locale->text('Every') . qq|</th>
		<td><select name=recurringrepeat>$selectrepeat</td>
		<td><select name=recurringunit>$selectunit</td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('For') . qq|</th>
		<td><input name=recurringhowmany size=3 value=$form->{recurringhowmany}></td>
		<th align=left nowrap>| . $locale->text('time(s)') . qq|</th>
	      </tr>
	    </table>
|;

    $title = $locale->text( 'Recurring Transaction for [_1]', $description );

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$title</th>
  </tr>
  <tr space=5></tr>
  <tr>
    <td>
      <table>
        <tr>
	  <td>
	    <table>
	      <tr>
		<th align=right nowrap>| . $locale->text('Reference') . qq|</th>
		<td><input name=recurringreference size=20 value="$form->{recurringreference}"></td>
	      </tr>
	      <tr>
		<th align=right nowrap>| . $locale->text('Startdate') . qq|</th>
		<td><input name=recurringstartdate size=11 title="($myconfig{'dateformat'})" value=$form->{recurringstartdate}></td>
	      </tr>
	      $nextdate
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>
      <table>
	$postpayment
      </table>
    </td>
  </tr>
	
  <tr>
    <td>
      <table>
	<tr valign=top>
	  <td>$repeat</td>
	  <td>$print</td>
	</tr>
	<tr valign=top>  
	  <td>$email</td>
	  <td>$message</td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
|;

    # type=submit $locale->text('Save Schedule')
    # type=submit $locale->text('Delete Schedule')

    %button = (
        'save_schedule' =>
          { ndx => 1, key => 'S', value => $locale->text('Save Schedule') },
        'delete_schedule' =>
          { ndx => 16, key => 'D', value => $locale->text('Delete Schedule') },
    );

    $form->print_button( \%button, 'save_schedule' );

    if ( $form->{recurring} ) {
        $form->print_button( \%button, 'delete_schedule' );
    }

    # delete variables
    for (qw(action recurring)) { delete $form->{$_} }
    for (
        qw(reference startdate nextdate enddate repeat unit howmany payment print email message)
      )
    {
        delete $form->{"recurring$_"};
    }

    $form->hide_form;

    print qq|

</form>

</body>
</html>
|;

}

sub save_schedule {

    $form->{recurring} = "";

    $form->{recurringreference} =
      $form->escape( $form->{recurringreference}, 1 );
    $form->{recurringmessage} = $form->escape( $form->{recurringmessage}, 1 );
    if ( $form->{recurringstartdate} ) {
        for (qw(reference startdate repeat unit howmany payment)) {
            $form->{recurring} .= qq|$form->{"recurring$_"},|;
        }
    }

    @a = split /<option/, $form->unescape( $form->{selectformname} );
    @p = ();

    for ( $i = 1 ; $i <= $#a ; $i++ ) {
        $a[$i] =~ /"(.*)"/;
        push @p, $1;
    }

    $recurringemail = "";
    for (@p) {
        $recurringemail .= qq|$_:$form->{"emailformat$_"}:|
          if $form->{"email$_"};
    }
    chop $recurringemail;

    $recurringprint = "";
    for (@p) {
        $recurringprint .=
          qq|$_:$form->{"printformat$_"}:$form->{"printprinter$_"}:|
          if $form->{"print$_"};
    }
    chop $recurringprint;

    $form->{recurring} .=
      qq|$recurringprint,$recurringemail,$form->{recurringmessage}|
      if $recurringemail || $recurringprint;

    $form->save_recurring( undef, \%myconfig ) if $form->{id};

    if ( $form->{recurringid} ) {
        $form->redirect;
    }
    else {
        &update;
    }

}

sub delete_schedule {

    $form->{recurring} = "";

    $form->save_recurring( undef, \%myconfig ) if $form->{id};

    if ( $form->{recurringid} ) {
        $form->redirect;
    }
    else {
        &update;
    }

}

sub reprint {

    $myconfig{vclimit} = 0;
    $pf = "print_form";

    for (qw(format formname media message)) { $temp{$_} = $form->{$_} }

    if ( $form->{module} eq 'oe' ) {
        &order_links;
        &prepare_order;
        delete $form->{order_details};
        for ( keys %$form ) { $form->{$_} = $form->unquote( $form->{$_} ) }
    }
    else {
        if ( $form->{type} eq 'invoice' ) {
            &invoice_links;
            &prepare_invoice;
            for ( keys %$form ) { $form->{$_} = $form->unquote( $form->{$_} ) }
        }
        else {
            &create_links;
            $form->{rowcount}--;
            for ( 1 .. $form->{rowcount} ) {
                $form->{"amount_$_"} =
                  $form->format_amount( \%myconfig, $form->{"amount_$_"}, 2 );
            }
            for ( split / /, $form->{taxaccounts} ) {
                $form->{"tax_$_"} =
                  $form->format_amount( \%myconfig, $form->{"tax_$_"}, 2 );
            }
            $pf = "print_transaction";
        }
        for (qw(acc_trans invoice_details)) { delete $form->{$_} }
    }

    for (qw(department employee language month partsgroup project years)) {
        delete $form->{"all_$_"};
    }

    for ( keys %temp ) { $form->{$_} = $temp{$_} }

    $form->{rowcount}++;
    $form->{paidaccounts}++;

    delete $form->{paid};

    for ( 1 .. $form->{paidaccounts} ) {
        $form->{"paid_$_"} =
          $form->format_amount( \%myconfig, $form->{"paid_$_"}, 2 );
    }

    $form->{copies} = 1;

    &$pf;

    if ( $form->{media} eq 'email' ) {

        # add email message
        $now = scalar localtime;
        $cc  = $locale->text( 'Cc: [_1]', $form->{cc} ) . qq|\n| if $form->{cc};
        $bcc = $locale->text( 'Bcc: [_1]', $form->{bcc} ) . qq|\n|
          if $form->{bcc};

        $form->{intnotes} .= qq|\n\n| if $form->{intnotes};
        $form->{intnotes} .=
            qq|[email]\n|
          . $locale->text( 'Date: [_1]', $now ) . qq|\n|
          . $locale->text( 'To: [_1]',   $form->{email} )
          . qq|\n${cc}${bcc}|
          . $locale->text( 'Subject: [_1]', $form->{subject} )
          . qq|\n\n|
          . $locale->text('Message: ');

        $form->{intnotes} .=
          ( $form->{message} ) ? $form->{message} : $locale->text('sent');

        $form->save_intnotes( \%myconfig, $form->{module} );
    }

}

sub continue        { &{ $form->{nextsub} } }
sub gl_transaction  { &add }
sub ar_transaction  { &add_transaction(ar) }
sub ap_transaction  { &add_transaction(ap) }
sub sales_invoice_  { &add_transaction(is) }
sub vendor_invoice_ { &add_transaction(ir) }

