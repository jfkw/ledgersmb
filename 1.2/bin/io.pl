######################################################################
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
# Copyright (c) 2002
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
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
# common routines used in is, ir, oe
#
#######################################################################

use LedgerSMB::Tax;
use LedgerSMB::Sysconfig;

# any custom scripts for this one
if (-f "bin/custom/io.pl") {
  eval { require "bin/custom/io.pl"; };
}
if (-f "bin/custom/$form->{login}_io.pl") {
  eval { require "bin/custom/$form->{login}_io.pl"; };
}


1;
# end of main


# this is for our long dates
# $locale->text('January')
# $locale->text('February')
# $locale->text('March')
# $locale->text('April')
# $locale->text('May ')
# $locale->text('June')
# $locale->text('July')
# $locale->text('August')
# $locale->text('September')
# $locale->text('October')
# $locale->text('November')
# $locale->text('December')

# this is for our short month
# $locale->text('Jan')
# $locale->text('Feb')
# $locale->text('Mar')
# $locale->text('Apr')
# $locale->text('May')
# $locale->text('Jun')
# $locale->text('Jul')
# $locale->text('Aug')
# $locale->text('Sep')
# $locale->text('Oct')
# $locale->text('Nov')
# $locale->text('Dec')


sub display_row {
  my $numrows = shift;

  @column_index = qw(runningnumber partnumber description qty);

  if ($form->{type} eq "sales_order") {
    push @column_index, "ship";
    $column_data{ship} = qq|<th class=listheading align=center width="auto">|.$locale->text('Ship').qq|</th>|;
  }
  if ($form->{type} eq "purchase_order") {
    push @column_index, "ship";
    $column_data{ship} = qq|<th class=listheading align=center width="auto">|.$locale->text('Recd').qq|</th>|;
  }

  for (qw(projectnumber partsgroup)) {
    $form->{"select$_"} = $form->unescape($form->{"select$_"}) if $form->{"select$_"};
  }
      
  if ($form->{language_code} ne $form->{oldlanguage_code}) {
    # rebuild partsgroup
    $l{language_code} = $form->{language_code};
    $l{searchitems} = 'nolabor' if $form->{vc} eq 'customer';
    
    $form->get_partsgroup(\%myconfig, \%l);
    if (@ { $form->{all_partsgroup} }) {
      $form->{selectpartsgroup} = "<option>\n";
      foreach $ref (@ { $form->{all_partsgroup} }) {
	if ($ref->{translation}) {
	  $form->{selectpartsgroup} .= qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{translation}\n|;
	} else {
	  $form->{selectpartsgroup} .= qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{partsgroup}\n|;
	}
      }
    }
    $form->{oldlanguage_code} = $form->{language_code};
  }
      

  push @column_index, @{LedgerSMB::Sysconfig::io_lineitem_columns};

  my $colspan = $#column_index + 1;

  $form->{invsubtotal} = 0;
  for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0 }
  
  $column_data{runningnumber} = qq|<th class=listheading nowrap>|.$locale->text('Item').qq|</th>|;
  $column_data{partnumber} = qq|<th class=listheading nowrap>|.$locale->text('Number').qq|</th>|;
  $column_data{description} = qq|<th class=listheading nowrap>|.$locale->text('Description').qq|</th>|;
  $column_data{qty} = qq|<th class=listheading nowrap>|.$locale->text('Qty').qq|</th>|;
  $column_data{unit} = qq|<th class=listheading nowrap>|.$locale->text('Unit').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading nowrap>|.$locale->text('Price').qq|</th>|;
  $column_data{discount} = qq|<th class=listheading>%</th>|;
  $column_data{linetotal} = qq|<th class=listheading nowrap>|.$locale->text('Extended').qq|</th>|;
  $column_data{bin} = qq|<th class=listheading nowrap>|.$locale->text('Bin').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading nowrap>|.$locale->text('OH').qq|</th>|;
  
  print qq|
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
        </tr>
|;


  $deliverydate = $locale->text('Delivery Date');
  $serialnumber = $locale->text('Serial No.');
  $projectnumber = $locale->text('Project');
  $group = $locale->text('Group');
  $sku = $locale->text('SKU');

  $delvar = 'deliverydate';
  
  if ($form->{type} =~ /_(order|quotation)$/) {
    $reqdate = $locale->text('Required by');
    $delvar = 'reqdate';
  }

  $exchangerate = $form->parse_amount(\%myconfig, $form->{exchangerate});
  $exchangerate = ($exchangerate) ? $exchangerate : 1;

  $spc = substr($myconfig{numberformat},-3,1);
  for $i (1 .. $numrows) {
    if ($spc eq '.') {
      ($null, $dec) = split /\./, $form->{"sellprice_$i"};
    } else {
      ($null, $dec) = split /,/, $form->{"sellprice_$i"};
    }
    $dec = length $dec;
    $decimalplaces = ($dec > 2) ? $dec : 2;

    # undo formatting
    for (qw(qty oldqty ship discount sellprice)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    
    if ($form->{"qty_$i"} != $form->{"oldqty_$i"}) {
      # check pricematrix
      @a = split / /, $form->{"pricematrix_$i"};
      if (scalar @a > 2) {
	foreach $item (@a) {
	  ($q, $p) = split /:/, $item;
	  if (($p * 1) && ($form->{"qty_$i"} >= ($q * 1))) {
	    ($dec) = ($p =~ /\.(\d+)/);
	    $dec = length $dec;
	    $decimalplaces = ($dec > 2) ? $dec : 2;
	    $form->{"sellprice_$i"} = $form->round_amount($p / $exchangerate, $decimalplaces);
	  }
	}
      }
    }
    
    $discount = $form->round_amount($form->{"sellprice_$i"} * $form->{"discount_$i"}/100, $decimalplaces);
    $linetotal = $form->round_amount($form->{"sellprice_$i"} - $discount, $decimalplaces);
    $linetotal = $form->round_amount($linetotal * $form->{"qty_$i"}, 2);

    
    if (($rows = $form->numtextrows($form->{"description_$i"}, 46, 6)) > 1) {
      $form->{"description_$i"} = $form->quote($form->{"description_$i"});
      $column_data{description} = qq|<td><textarea name="description_$i" rows=$rows cols=46 wrap=soft>$form->{"description_$i"}</textarea></td>|;
    } else {
      $form->{"description_$i"} = $form->quote($form->{"description_$i"});
      $column_data{description} = qq|<td><input name="description_$i" size=48 value="$form->{"description_$i"}"></td>|;
    }

    for (qw(partnumber sku unit)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }
    
    $skunumber = qq|
                <p><b>$sku</b> $form->{"sku_$i"}| if ($form->{vc} eq 'vendor' && $form->{"sku_$i"});

    
    if ($form->{selectpartsgroup}) {
      if ($i < $numrows) {
	$partsgroup = qq|
	      <b>$group</b>
	      <input type=hidden name="partsgroup_$i" value="$form->{"partsgroup_$i"}">|;
	($form->{"partsgroup_$i"}) = split /--/, $form->{"partsgroup_$i"};
	$partsgroup .= $form->{"partsgroup_$i"};
	$partsgroup = "" unless $form->{"partsgroup_$i"};
      }
    }
    
    $delivery = qq|
          <td colspan=2 nowrap>
	  <b>${$delvar}</b>
	  <input name="${delvar}_$i" size=11 title="$myconfig{dateformat}" value="$form->{"${delvar}_$i"}"></td>
|;

    $column_data{runningnumber} = qq|<td><input name="runningnumber_$i" size=3 value=$i></td>|;
    $column_data{partnumber} = qq|<td><input name="partnumber_$i" size=15 value="$form->{"partnumber_$i"}" accesskey="$i" title="[Alt-$i]">$skunumber</td>|;
    $column_data{qty} = qq|<td align=right><input name="qty_$i" title="$form->{"onhand_$i"}" size=5 value=|.$form->format_amount(\%myconfig, $form->{"qty_$i"}).qq|></td>|;
    $column_data{ship} = qq|<td align=right><input name="ship_$i" size=5 value=|.$form->format_amount(\%myconfig, $form->{"ship_$i"}).qq|></td>|;
    $column_data{unit} = qq|<td><input name="unit_$i" size=5 value="$form->{"unit_$i"}"></td>|;
    $column_data{sellprice} = qq|<td align=right><input name="sellprice_$i" size=9 value=|.$form->format_amount(\%myconfig, $form->{"sellprice_$i"}, $decimalplaces).qq|></td>|;
    $column_data{discount} = qq|<td align=right><input name="discount_$i" size=3 value=|.$form->format_amount(\%myconfig, $form->{"discount_$i"}).qq|></td>|;
    $column_data{linetotal} = qq|<td align=right>|.$form->format_amount(\%myconfig, $linetotal, 2).qq|</td>|;
    $column_data{bin} = qq|<td>$form->{"bin_$i"}</td>|;
    $column_data{onhand} = qq|<td>$form->{"onhand_$i"}</td>|;
    
    print qq|
        <tr valign=top>|;

    for (@column_index) {
      print "\n$column_data{$_}";
    }
  
    print qq|
        </tr>
<input type=hidden name="oldqty_$i" value="$form->{"qty_$i"}">
|;

    for (qw(orderitems_id id bin weight listprice lastcost taxaccounts pricematrix sku onhand assembly inventory_accno_id income_accno_id expense_accno_id)) {
      $form->hide_form("${_}_$i");
    }
  
    $form->{selectprojectnumber} =~ s/ selected//;
    $form->{selectprojectnumber} =~ s/(<option value="\Q$form->{"projectnumber_$i"}\E")/$1 selected/;

    $project = qq|
                <b>$projectnumber</b>
		<select name="projectnumber_$i">$form->{selectprojectnumber}</select>
| if $form->{selectprojectnumber};


    if (($rows = $form->numtextrows($form->{"notes_$i"}, 46, 6)) > 1) {
      $form->{"notes_$i"} = $form->quote($form->{"notes_$i"});
      $notes = qq|<td><textarea name="notes_$i" rows=$rows cols=46 wrap=soft>$form->{"notes_$i"}</textarea></td>|;
    } else {
      $form->{"notes_$i"} = $form->quote($form->{"notes_$i"});
      $notes = qq|<td><input name="notes_$i" size=48 value="$form->{"notes_$i"}"></td>|;
    }
	
    $serial = qq|
                <td colspan=6 nowrap><b>$serialnumber</b> <input name="serialnumber_$i" value="$form->{"serialnumber_$i"}"></td>| if $form->{type} !~ /_quotation/;
		
    if ($i == $numrows) {
      $partsgroup = "";
      if ($form->{selectpartsgroup}) {
	$partsgroup = qq|
	        <b>$group</b>
		<select name="partsgroup_$i">$form->{selectpartsgroup}</select>
|;
      }

      $serial = "";
      $project = "";
      $delivery = "";
      $notes = "";
    }

	
    # print second and third row
    print qq|
        <tr valign=top>
	  $delivery
	  $notes
	  $serial
	</tr>
        <tr valign=top>
	  <td colspan=$colspan>
	  $project
	  $partsgroup
	  </td>
	</tr>
	<tr>
	  <td colspan=$colspan><hr size=1 noshade></td>
	</tr>
|;

    $skunumber = "";
    
    for (split / /, $form->{"taxaccounts_$i"}) {
      $form->{"${_}_base"} += $linetotal;
    }
  
    $form->{invsubtotal} += $linetotal;
  }

  print qq|
      </table>
    </td>
  </tr>
|;

  $form->hide_form(qw(audittrail));
  
  print qq|

<input type=hidden name=oldcurrency value=$form->{currency}>

<input type=hidden name=selectpartsgroup value="|.$form->escape($form->{selectpartsgroup},1).qq|">
<input type=hidden name=selectprojectnumber value="|.$form->escape($form->{selectprojectnumber},1).qq|">

|;
 
}


sub select_item {

  if ($form->{vc} eq "vendor") {
    @column_index = qw(ndx partnumber sku description partsgroup onhand sellprice);
  } else {
    @column_index = qw(ndx partnumber description partsgroup onhand sellprice);
  }

  $column_data{ndx} = qq|<th>&nbsp;</th>|;
  $column_data{partnumber} = qq|<th class=listheading>|.$locale->text('Number').qq|</th>|;
  $column_data{sku} = qq|<th class=listheading>|.$locale->text('SKU').qq|</th>|;
  $column_data{description} = qq|<th class=listheading>|.$locale->text('Description').qq|</th>|;
  $column_data{partsgroup} = qq|<th class=listheading>|.$locale->text('Group').qq|</th>|;
  $column_data{sellprice} = qq|<th class=listheading>|.$locale->text('Price').qq|</th>|;
  $column_data{onhand} = qq|<th class=listheading>|.$locale->text('Qty').qq|</th>|;
  
  $exchangerate = ($form->{exchangerate}) ? $form->{exchangerate} : 1;

  # list items with radio button on a form
  $form->header;

  $title = $locale->text('Select items');

  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr>
    <th class=listtop>$title</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
        <tr class=listheading>|;

  for (@column_index) { print "\n$column_data{$_}" }
  
  print qq|
        </tr>
|;

  my $i = 0;
  foreach $ref (@{ $form->{item_list} }) {
    $i++;

    for (qw(sku partnumber description unit notes partsgroup)) {
      $ref->{$_} = $form->quote($ref->{$_});
    }

    $column_data{ndx} = qq|<td><input name="ndx_$i" class=checkbox type=checkbox value=$i></td>|;
    
    for (qw(partnumber sku description partsgroup)) { $column_data{$_} = qq|<td>$ref->{$_}&nbsp;</td>| }
    
    $column_data{sellprice} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{sellprice} / $exchangerate, 2, "&nbsp;").qq|</td>|;
    $column_data{onhand} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{onhand}, '', "&nbsp;").qq|</td>|;
    
    $j++; $j %= 2;
    print qq|
        <tr class=listrow$j>|;

    for (@column_index) {
      print "\n$column_data{$_}";
    }

    print qq|
        </tr>
|;

    for (qw(partnumber sku description partsgroup partsgroup_id bin weight sellprice listprice lastcost onhand unit assembly taxaccounts inventory_accno_id income_accno_id expense_accno_id pricematrix id notes)) {
      print qq|<input type=hidden name="new_${_}_$i" value="$ref->{$_}">\n|;
    }
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
  for (qw(nextsub item_list)) { delete $form->{$_} }

  $form->{action} = "item_selected";
  
  $form->hide_form;
  
  print qq|
<input type="hidden" name="nextsub" value="item_selected">

<br>
<button class="submit" type="submit" name="action" value="continue">|.$locale->text('Continue').qq|</button>
</form>

</body>
</html>
|;

}



sub item_selected {

  $i = $form->{rowcount} - 1;
  $i = $form->{assembly_rows} - 1 if ($form->{item} eq 'assembly');
  $qty = ($form->{"qty_$form->{rowcount}"}) ? $form->{"qty_$form->{rowcount}"} : 1;

  for $j (1 .. $form->{lastndx}) {
    
    if ($form->{"ndx_$j"}) {

      $i++;
  
      $form->{"qty_$i"} = $qty;
      $form->{"discount_$i"} = $form->{discount} * 100;
      $form->{"reqdate_$i"} = $form->{reqdate} if $form->{type} !~ /_quotation/;

      for (qw(id partnumber sku description listprice lastcost bin unit weight assembly taxaccounts pricematrix onhand notes inventory_accno_id income_accno_id expense_accno_id)) {
	$form->{"${_}_$i"} = $form->{"new_${_}_$j"};
      }
      $form->{"sellprice_$i"} = $form->{"new_sellprice_$j"} if not $form->{"sellprice_$i"};

      $form->{"partsgroup_$i"} = qq|$form->{"new_partsgroup_$j"}--$form->{"new_partsgroup_id_$j"}|;

      ($dec) = ($form->{"sellprice_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces1 = ($dec > 2) ? $dec : 2;
      
      ($dec) = ($form->{"lastcost_$i"} =~ /\.(\d+)/);
      $dec = length $dec;
      $decimalplaces2 = ($dec > 2) ? $dec : 2;

      # if there is an exchange rate adjust sellprice
      if (($form->{exchangerate} * 1)) {
	for (qw(sellprice listprice lastcost)) { $form->{"${_}_$i"} /= $form->{exchangerate} }
        # don't format list and cost
	$form->{"sellprice_$i"} = $form->round_amount($form->{"sellprice_$i"}, $decimalplaces1);
      }

      # this is for the assembly
      if ($form->{item} eq 'assembly') {
	$form->{"adj_$i"} = 1;
	
	for (qw(sellprice listprice weight)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }

	$form->{sellprice} += ($form->{"sellprice_$i"} * $form->{"qty_$i"});
	$form->{weight} += ($form->{"weight_$i"} * $form->{"qty_$i"});
      }

      $amount = $form->{"sellprice_$i"} * (1 - $form->{"discount_$i"} / 100) * $form->{"qty_$i"};
      for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $amount }
      if (!$form->{taxincluded}) {
        my @taxlist= Tax::init_taxes($form, $form->{"taxaccounts_$i"});
	$amount += Tax::calculate_taxes(\@taxlist, $form, $amount, 0);
      }

      $form->{creditremaining} -= $amount;

      $form->{"runningnumber_$i"} = $i;
  
      # format amounts
      if ($form->{item} ne 'assembly') {
	for (qw(sellprice listprice)) { $form->{"${_}_$i"} = $form->format_amount(\%myconfig, $form->{"${_}_$i"}, $decimalplaces1) }
	$form->{"lastcost_$i"} = $form->format_amount(\%myconfig, $form->{"lastcost_$i"}, $decimalplaces2);
      }
      $form->{"discount_$i"} = $form->format_amount(\%myconfig, $form->{"discount_$i"});

    }
  }

  $form->{rowcount} = $i;
  $form->{assembly_rows} = $i if ($form->{item} eq 'assembly');
  
  $form->{focus} = "description_$i";

  # delete all the new_ variables
  for $i (1 .. $form->{lastndx}) {
    for (qw(id partnumber sku description sellprice listprice lastcost bin unit weight assembly taxaccounts pricematrix onhand notes inventory_accno_id income_accno_id expense_accno_id)) {
      delete $form->{"new_${_}_$i"};
    }
  }
  
  for (qw(ndx lastndx nextsub)) { delete $form->{$_} }

  &display_form;

}


sub new_item {

  if ($form->{language_code} && $form->{"description_$form->{rowcount}"}) {
    $form->error($locale->text('Translation not on file!'));
  }
  
  # change callback
  $form->{old_callback} = $form->escape($form->{callback},1);
  $form->{callback} = $form->escape("$form->{script}?action=display_form",1);

  # delete action
  delete $form->{action};

  # save all other form variables in a previousform variable
  if (!$form->{previousform}) {
    foreach $key (keys %$form) {
      # escape ampersands
      $form->{$key} =~ s/&/%26/g;
      $form->{previousform} .= qq|$key=$form->{$key}&|;
    }
    chop $form->{previousform};
    $form->{previousform} = $form->escape($form->{previousform}, 1);
  }

  $i = $form->{rowcount};
  for (qw(partnumber description)) { $form->{"${_}_$i"} = $form->quote($form->{"${_}_$i"}) }

  $form->header;

  print qq|
<body>

<h4 class=error>|.$locale->text('Item not on file!').qq|</h4>|;

  if ($myconfig{acs} !~ /(Goods \& Services--Add Part|Goods \& Services--Add Service)/) {

    print qq|
<h4>|.$locale->text('What type of item is this?').qq|</h4>

<form method=post action=ic.pl>

<p>

  <input class=radio type=radio name=item value=part checked>&nbsp;|.$locale->text('Part')
.qq|<br>
  <input class=radio type=radio name=item value=service>&nbsp;|.$locale->text('Service')

.qq|
<input type=hidden name=partnumber value="$form->{"partnumber_$i"}">
<input type=hidden name=description value="$form->{"description_$i"}">
<input type=hidden name=nextsub value=add>
<input type=hidden name=action value=add>
|;

  $form->hide_form(qw(previousform rowcount path login sessionid));

  print qq|
<p>
<button class="submit" type="submit" name="action" value="continue">|.$locale->text('Continue').qq|</button>
</form>
|;
  }

  print qq|
</body>
</html>
|;

}



sub display_form {

  # if we have a display_form
  if ($form->{display_form}) {
    &{ "$form->{display_form}" };
    exit;
  }
  
  &form_header;

  $numrows = ++$form->{rowcount};
  $subroutine = "display_row";

  if ($form->{item} eq 'part') {
    # create makemodel rows
    &makemodel_row(++$form->{makemodel_rows});

    &vendor_row(++$form->{vendor_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }
  if ($form->{item} eq 'assembly') {
    # create makemodel rows
    &makemodel_row(++$form->{makemodel_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }
  if ($form->{item} eq 'service') {
    &vendor_row(++$form->{vendor_rows});
    
    $numrows = ++$form->{customer_rows};
    $subroutine = "customer_row";
  }
  if ($form->{item} eq 'labor') {
    $numrows = 0;
  }

  # create rows
  &{ $subroutine }($numrows) if $numrows;

  &form_footer;

}



sub check_form {
  
  my @a = ();
  my $count = 0;
  my $i;
  my $j;
  my @flds = qw(id runningnumber partnumber description partsgroup qty ship unit sellprice discount oldqty orderitems_id bin weight listprice lastcost taxaccounts pricematrix sku onhand assembly inventory_accno_id income_accno_id expense_accno_id notes reqdate deliverydate serialnumber projectnumber);

  # remove any makes or model rows
  if ($form->{item} eq 'part') {
    for (qw(listprice sellprice lastcost avgcost weight rop markup)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
    
    &calc_markup;
    
    @flds = qw(make model);
    $count = 0;
    @a = ();
    for $i (1 .. $form->{makemodel_rows}) {
      if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
	push @a, {};
	$j = $#a;

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@a, $count, $form->{makemodel_rows});
    $form->{makemodel_rows} = $count;

    &check_vendor;
    &check_customer;
    
  }
  
  if ($form->{item} eq 'service') {
    
    for (qw(sellprice listprice lastcost avgcost markup)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
    
    &calc_markup;
    &check_vendor;
    &check_customer;
    
  }
  
  if ($form->{item} eq 'assembly') {

    if (!$form->{project_id}) {
      $form->{sellprice} = 0;
      $form->{listprice} = 0;
      $form->{lastcost} = 0;
      $form->{weight} = 0;
    }
    
    for (qw(rop stock markup)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
   
    @flds = qw(id qty unit bom adj partnumber description sellprice listprice lastcost weight assembly runningnumber partsgroup);
    $count = 0;
    @a = ();
    
    for $i (1 .. ($form->{assembly_rows} - 1)) {
      if ($form->{"qty_$i"}) {
	push @a, {};
	my $j = $#a;

        $form->{"qty_$i"} = $form->parse_amount(\%myconfig, $form->{"qty_$i"});

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }

        if (! $form->{project_id}) {
	  for (qw(sellprice listprice weight lastcost)) { $form->{$_} += ($form->{"${_}_$i"} * $form->{"qty_$i"}) }
	}
	
	$count++;
      }
    }

    if ($form->{markup} && $form->{markup} != $form->{oldmarkup}) {
      $form->{sellprice} = 0;
      &calc_markup;
    }
 
    for (qw(sellprice lastcost listprice)) { $form->{$_} = $form->round_amount($form->{$_}, 2) }
    
    $form->redo_rows(\@flds, \@a, $count, $form->{assembly_rows});
    $form->{assembly_rows} = $count;
    
    $count = 0;
    @flds = qw(make model);
    @a = ();
    
    for $i (1 .. ($form->{makemodel_rows})) {
      if (($form->{"make_$i"} ne "") || ($form->{"model_$i"} ne "")) {
	push @a, {};
	my $j = $#a;

	for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	$count++;
      }
    }

    $form->redo_rows(\@flds, \@a, $count, $form->{makemodel_rows});
    $form->{makemodel_rows} = $count;

    &check_customer;
  
  }
  
  if ($form->{type}) {

    # this section applies to invoices and orders
    # remove any empty numbers
    
    $count = 0;
    @a = ();
    if ($form->{rowcount}) {
      for $i (1 .. $form->{rowcount} - 1) {
	if ($form->{"partnumber_$i"}) {
	  push @a, {};
	  my $j = $#a;

	  for (@flds) { $a[$j]->{$_} = $form->{"${_}_$i"} }
	  $count++;
	}
      }
      
      $form->redo_rows(\@flds, \@a, $count, $form->{rowcount});
      $form->{rowcount} = $count;

      $form->{creditremaining} -= &invoicetotal;
      
    }
  }

  &display_form;

}


sub calc_markup {

  if ($form->{markup}) {
    if ($form->{markup} != $form->{oldmarkup}) {
      if ($form->{lastcost}) {
	$form->{sellprice} = $form->{lastcost} * (1 + $form->{markup}/100);
	$form->{sellprice} = $form->round_amount($form->{sellprice}, 2);
      } else {
	$form->{lastcost} = $form->{sellprice} / (1 + $form->{markup}/100);
	$form->{lastcost} = $form->round_amount($form->{lastcost}, 2);
      }
    }
  } else {
    if ($form->{lastcost}) {
      $form->{markup} = $form->round_amount(((1 - $form->{sellprice} / $form->{lastcost}) * 100), 1);
    }
    $form->{markup} = "" if $form->{markup} == 0;
  }

}


sub invoicetotal {

  $form->{oldinvtotal} = 0;
  # add all parts and deduct paid
  for (split / /, $form->{taxaccounts}) { $form->{"${_}_base"} = 0 }

  my ($amount, $sellprice, $discount, $qty);
  
  for $i (1 .. $form->{rowcount}) {
    $sellprice = $form->parse_amount(\%myconfig, $form->{"sellprice_$i"});
    $discount = $form->parse_amount(\%myconfig, $form->{"discount_$i"});
    $qty = $form->parse_amount(\%myconfig, $form->{"qty_$i"});

    $amount = $sellprice * (1 - $discount / 100) * $qty;
    for (split / /, $form->{"taxaccounts_$i"}) { $form->{"${_}_base"} += $amount }
    $form->{oldinvtotal} += $amount;
  }

  if (!$form->{taxincluded}) {
        my @taxlist= Tax::init_taxes($form, $form->{taxaccounts});
        $form->{oldinvtotal} += Tax::calculate_taxes(\@taxlist, $form, 
	  $amount, 0);
  }
  
  $form->{oldtotalpaid} = 0;
  for $i (1 .. $form->{paidaccounts}) {
    $form->{oldtotalpaid} += $form->{"paid_$i"};
  }
  
  # return total
  ($form->{oldinvtotal} - $form->{oldtotalpaid});

}


sub validate_items {
  
  # check if items are valid
  if ($form->{rowcount} == 1) {
    &update;
    exit;
  }
    
  for $i (1 .. $form->{rowcount} - 1) {
    $form->isblank("partnumber_$i", $locale->text('Number missing in Row [_1]', $i));
  }

}



sub purchase_order {
  
  $form->{title} = $locale->text('Add Purchase Order');
  $form->{vc} = 'vendor';
  $form->{type} = 'purchase_order';
  $buysell = 'sell';

  &create_form;

}

 
sub sales_order {

  $form->{title} = $locale->text('Add Sales Order');
  $form->{vc} = 'customer';
  $form->{type} = 'sales_order';
  $buysell = 'buy';

  &create_form;

}


sub rfq {
  
  $form->{title} = $locale->text('Add Request for Quotation');
  $form->{vc} = 'vendor';
  $form->{type} = 'request_quotation';
  $buysell = 'sell';
 
  &create_form;
  
}


sub quotation {

  $form->{title} = $locale->text('Add Quotation');
  $form->{vc} = 'customer';
  $form->{type} = 'sales_quotation';
  $buysell = 'buy';

  &create_form;

}


sub create_form {

  for (qw(id printed emailed queued)) { delete $form->{$_} }
 
  $form->{script} = 'oe.pl';

  $form->{shipto} = 1;

  $form->{rowcount}-- if $form->{rowcount};
  $form->{rowcount} = 0 if ! $form->{"$form->{vc}_id"};

  do "bin/$form->{script}";

  for ("$form->{vc}", "currency") { $form->{"select$_"} = "" }
  
  for (qw(currency employee department intnotes notes language_code taxincluded)) { $temp{$_} = $form->{$_} }

  &order_links;

  for (keys %temp) { $form->{$_} = $temp{$_} if $temp{$_} }

  $form->{exchangerate} = "";
  $form->{forex} = "";
  if ($form->{currency} ne $form->{defaultcurrency}) {
    $form->{exchangerate} = $exchangerate if ($form->{forex} = ($exchangerate = $form->check_exchangerate(\%myconfig, $form->{currency}, $form->{transdate}, $buysell)));
  }

  &prepare_order;

  &display_form;

}



sub e_mail {

  $bcc = qq|<input type=hidden name=bcc value="$form->{bcc}">|;
  if ($myconfig{role} =~ /(admin|manager)/) {
    $bcc = qq|
 	  <th align=right nowrap=true>|.$locale->text('Bcc').qq|</th>
	  <td><input name=bcc size=30 value="$form->{bcc}"></td>
|;
  }

  if ($form->{formname} =~ /(pick|packing|bin)_list/) {
    $form->{email} = $form->{shiptoemail} if $form->{shiptoemail};
  }

  $name = $form->{$form->{vc}};
  $name =~ s/--.*//g;
  $title = $locale->text('E-mail')." $name";
  
  $form->header;

  print qq|
<body>

<form method=post action="$form->{script}">

<table width=100%>
  <tr class=listtop>
    <th class=listtop>$title</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
	  <td><input name=email size=30 value="$form->{email}"></td>
	  <th align=right nowrap>|.$locale->text('Cc').qq|</th>
	  <td><input name=cc size=30 value="$form->{cc}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Subject').qq|</th>
	  <td><input name=subject size=30 value="$form->{subject}"></td>
	  $bcc
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr>
	  <th align=left nowrap>|.$locale->text('Message').qq|</th>
	</tr>
	<tr>
	  <td><textarea name=message rows=15 cols=60 wrap=soft>$form->{message}</textarea></td>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
|;

  $form->{oldmedia} = $form->{media};
  $form->{media} = "email";
  $form->{format} = "pdf";
  
  &print_options;
  
  for (qw(email cc bcc subject message formname sendmode format language_code action nextsub)) { delete $form->{$_} }
  
  $form->hide_form;

  print qq|
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type="hidden" name="nextsub" value="send_email">

<br>
<button name="action" class="submit" type="submit" value="continue">|.$locale->text('Continue').qq|</button>
</form>

</body>
</html>
|;

}


sub send_email {

  $old_form = new Form;
  
  for (keys %$form) { $old_form->{$_} = $form->{$_} }
  $old_form->{media} = $old_form->{oldmedia};
  
  &print_form($old_form);
  
}
  

 
sub print_options {

  $form->{sendmode} = "attachment";
  $form->{copies} = 1 unless $form->{copies};
  
  $form->{SM}{$form->{sendmode}} = "selected";
  
  if ($form->{selectlanguage}) {
    $form->{"selectlanguage"} = $form->unescape($form->{"selectlanguage"});
    $form->{"selectlanguage"} =~ s/ selected//;
    $form->{"selectlanguage"} =~ s/(<option value="\Q$form->{language_code}\E")/$1 selected/;

    $lang = qq|<select name=language_code>$form->{selectlanguage}</select>
    <input type=hidden name=oldlanguage_code value=$form->{oldlanguage_code}>
    <input type=hidden name=selectlanguage value="|.$form->escape($form->{selectlanguage},1).qq|">|;
  }

  $form->{selectformname} = $form->unescape($form->{selectformname});
  $form->{selectformname} =~ s/ selected//;
  $form->{selectformname} =~ s/(<option value="\Q$form->{formname}\E")/$1 selected/;

  $type = qq|<select name=formname>$form->{selectformname}</select>
  <input type=hidden name=selectformname value="|.$form->escape($form->{selectformname},1).qq|">|;

  
  if ($form->{media} eq 'email') {
    $media = qq|<select name=sendmode>
	    <option value=attachment $form->{SM}{attachment}>|.$locale->text('Attachment').qq|
	    <option value=inline $form->{SM}{inline}>|.$locale->text('In-line').qq|</select>|;
  } else {
    $media = qq|<select name=media>
	    <option value="screen">|.$locale->text('Screen');
 
    if (%{LedgerSMB::Sysconfig::printer} && ${LedgerSMB::Sysconfig::latex}) {
      for (sort keys %{LedgerSMB::Sysconfig::printer}) { $media .= qq|
            <option value="$_">$_| }
    }
    if (${LedgerSMB::Sysconfig::latex}) {
      $media .= qq|
            <option value="queue">|.$locale->text('Queue');
    }
    $media .= qq|</select>|;

    # set option selected
    $media =~ s/(<option value="\Q$form->{media}\E")/$1 selected/;
 
  }


  $form->{selectformat} = qq|<option value="html">html\n|;
#	    <option value="txt">|.$locale->text('Text');

  if (${LedgerSMB::Sysconfig::latex}) {
    $form->{selectformat} .= qq|
            <option value="postscript">|.$locale->text('Postscript').qq|
	    <option value="pdf">|.$locale->text('PDF');
  }
	
  $format = qq|<select name=format>$form->{selectformat}</select>|;
  $format =~ s/(<option value="\Q$form->{format}\E")/$1 selected/;
  $format .= qq|
  <input type=hidden name=selectformat value="|.$form->escape($form->{selectformat},1).qq|">|;
  
  print qq|
<table width=100%>
  <tr>
    <td>$type</td>
    <td>$lang</td>
    <td>$format</td>
    <td>$media</td>
|;

  if (%{LedgerSMB::Sysconfig::printer} && ${LedgerSMB::Sysconfig::latex} && $form->{media} ne 'email') {
    print qq|
    <td nowrap>|.$locale->text('Copies').qq|
    <input name=copies size=2 value=$form->{copies}></td>
|;
  }

# $locale->text('Printed')
# $locale->text('E-mailed')
# $locale->text('Queued')
# $locale->text('Scheduled')

  %status = ( printed => 'Printed',
              emailed => 'E-mailed',
	      queued  => 'Queued',
	      recurring => 'Scheduled' );

  print qq|<td align=right width=90%>|;

  for (qw(printed emailed queued recurring)) {
    if ($form->{$_} =~ /$form->{formname}/) {
      print $locale->text($status{$_}).qq|<br>|;
    }
  }

  print qq|
    </td>
  </tr>
|;

  $form->{groupprojectnumber} = "checked" if $form->{groupprojectnumber};
  $form->{grouppartsgroup} = "checked" if $form->{grouppartsgroup};

  for (qw(runningnumber partnumber description bin)) { $sortby{$_} = "checked" if $form->{sortby} eq $_ }
  
  print qq|
  <tr>
    <td colspan=6>|.$locale->text('Group by').qq| ->
    <input name=groupprojectnumber type=checkbox class=checkbox $form->{groupprojectnumber}>
    |.$locale->text('Project').qq|
    <input name=grouppartsgroup type=checkbox class=checkbox $form->{grouppartsgroup}>
    |.$locale->text('Group').qq|
    </td>
  </tr>

  <tr>
    <td colspan=6>|.$locale->text('Sort by').qq| ->
    <input name=sortby type=radio class=radio value=runningnumber $sortby{runningnumber}>
    |.$locale->text('Item').qq|
    <input name=sortby type=radio class=radio value=partnumber $sortby{partnumber}>
    |.$locale->text('Number').qq|
    <input name=sortby type=radio class=radio value=description $sortby{description}>
    |.$locale->text('Description').qq|
    <input name=sortby type=radio class=radio value=bin $sortby{bin}>
    |.$locale->text('Bin').qq|
    </td>
    
  </tr>
</table>
|;

}



sub print {

  # if this goes to the printer pass through
  if ($form->{media} !~ /(screen|email)/) {
    $form->error($locale->text('Select txt, postscript or PDF!')) if ($form->{format} !~ /(txt|postscript|pdf)/);

    $old_form = new Form;
    for (keys %$form) { $old_form->{$_} = $form->{$_} }
    
  }
   
  &print_form($old_form);

}


sub print_form {
  my ($old_form) = @_;

  $inv = "inv";
  $due = "due";

  $numberfld = "sinumber";

  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";

  if ($form->{formname} eq "invoice") {
    $form->{label} = $locale->text('Invoice');
  }
  if ($form->{formname} eq 'sales_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Sales Order');
    $numberfld = "sonumber";
    $order = 1;
  }
  if ($form->{formname} eq 'work_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Work Order');
    $numberfld = "sonumber";
    $order = 1;
  }
  if ($form->{formname} eq 'packing_list') {
    # we use the same packing list as from an invoice
    $form->{label} = $locale->text('Packing List');

    if ($form->{type} ne 'invoice') {
      $inv = "ord";
      $due = "req";
      $numberfld = "sonumber";
      $order = 1;

      $filled = 0;
      for ($i = 1; $i < $form->{rowcount}; $i++) {
	if ($form->{"ship_$i"}) {
	  $filled = 1;
	  last;
	}
      }
      if (!$filled) {
	for (1 .. $form->{rowcount}) { $form->{"ship_$_"} = $form->{"qty_$_"} }
      }
    }
  }
  if ($form->{formname} eq 'pick_list') {
    $form->{label} = $locale->text('Pick List');
    if ($form->{type} ne 'invoice') {
      $inv = "ord";
      $due = "req";
      $order = 1;
      $numberfld = "sonumber";
    }
  }
  if ($form->{formname} eq 'purchase_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Purchase Order');
    $numberfld = "ponumber";
    $order = 1;
  }
  if ($form->{formname} eq 'bin_list') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Bin List');
    $numberfld = "ponumber";
    $order = 1;
  }
  if ($form->{formname} eq 'sales_quotation') {
    $inv = "quo";
    $due = "req";
    $form->{label} = $locale->text('Quotation');
    $numberfld = "sqnumber";
    $order = 1;
  }
  if ($form->{formname} eq 'request_quotation') {
    $inv = "quo";
    $due = "req";
    $form->{label} = $locale->text('Quotation');
    $numberfld = "rfqnumber";
    $order = 1;
  }

  &validate_items;
 
  $form->{"${inv}date"} = $form->{transdate};

  $form->isblank("email", $locale->text('E-mail address missing!')) if ($form->{media} eq 'email');
  $form->isblank("${inv}date", $locale->text($form->{label} .' Date missing!'));

  # get next number
  if (! $form->{"${inv}number"}) {
    $form->{"${inv}number"} = $form->update_defaults(\%myconfig, $numberfld);
    if ($form->{media} eq 'screen') {
      &update;
      exit;
    }
  }


# $locale->text('Invoice Number missing!')
# $locale->text('Invoice Date missing!')
# $locale->text('Packing List Number missing!')
# $locale->text('Packing List Date missing!')
# $locale->text('Order Number missing!')
# $locale->text('Order Date missing!')
# $locale->text('Quotation Number missing!')
# $locale->text('Quotation Date missing!')

  &{ "$form->{vc}_details" };

  @a = ();
  foreach $i (1 .. $form->{rowcount}) {
    push @a, ("partnumber_$i", "description_$i", "projectnumber_$i", "partsgroup_$i", "serialnumber_$i", "bin_$i", "unit_$i", "notes_$i");
  }
  for (split / /, $form->{taxaccounts}) { push @a, "${_}_description" }

  $ARAP = ($form->{vc} eq 'customer') ? "AR" : "AP";
  push @a, $ARAP;
  
  # format payment dates
  for $i (1 .. $form->{paidaccounts} - 1) {
    if (exists $form->{longformat}) {
      $form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"}, $form->{longformat});
    }
    
    push @a, "${ARAP}_paid_$i", "source_$i", "memo_$i";
  }
  
  $form->format_string(@a);
  
  ($form->{employee}) = split /--/, $form->{employee};
  ($form->{warehouse}, $form->{warehouse_id}) = split /--/, $form->{warehouse};
  
  # this is a label for the subtotals
  $form->{groupsubtotaldescription} = $locale->text('Subtotal') if not exists $form->{groupsubtotaldescription};
  delete $form->{groupsubtotaldescription} if $form->{deletegroupsubtotal};

  $duedate = $form->{"${due}date"};
  
  # create the form variables
  if ($order) {
    OE->order_details(\%myconfig, \%$form);
  } else {
    IS->invoice_details(\%myconfig, \%$form);
  }

  if (exists $form->{longformat}) {
    $form->{"${due}date"} = $duedate;
    for ("${inv}date", "${due}date", "shippingdate", "transdate") { $form->{$_} = $locale->date(\%myconfig, $form->{$_}, $form->{longformat}) }
  }
  
  @a = qw(name address1 address2 city state zipcode country contact phone fax email);
 
  $shipto = 1;
  # if there is no shipto fill it in from billto
  foreach $item (@a) {
    if ($form->{"shipto$item"}) {
      $shipto = 0;
      last;
    }
  }

  if ($shipto) {
    if ($form->{formname} eq 'purchase_order' || $form->{formname} eq 'request_quotation') {
	$form->{shiptoname} = $myconfig{company};
	$form->{shiptoaddress1} = $myconfig{address};
	$form->{shiptoaddress1} =~ s/\\n/\n/g;
    } else {
      if ($form->{formname} !~ /bin_list/) {
	for (@a) { $form->{"shipto$_"} = $form->{$_} }
      }
    }
  }

  # some of the stuff could have umlauts so we translate them
  push @a, qw(contact shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptoemail shippingpoint shipvia notes intnotes employee warehouse);

  push @a, ("${inv}number", "${inv}date", "${due}date");
  
  for (qw(company address tel fax businessnumber)) { $form->{$_} = $myconfig{$_} }
  $form->{address} =~ s/\\n/\n/g;

  for (qw(name email)) { $form->{"user$_"} = $myconfig{$_} }

  push @a, qw(company address tel fax businessnumber username useremail);

  for (qw(notes intnotes)) { $form->{$_} =~ s/^\s+//g }
  
  # before we format replace <%var%>
  for (qw(notes intnotes message)) { $form->{$_} =~ s/<%(.*?)%>/$form->{$1}/g }

  $form->format_string(@a);


  $form->{templates} = "$myconfig{templates}";
  $form->{IN} = "$form->{formname}.$form->{format}";

  if ($form->{format} =~ /(postscript|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }


  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

  if ($form->{media} !~ /(screen|queue|email)/) {
    $form->{OUT} = ${LedgerSMB::Sysconfig::printer}{$form->{media}};
    $form->{printmode} = '|-';
    $form->{OUT} =~ s/<%(fax)%>/<%$form->{vc}$1%>/;
    $form->{OUT} =~ s/<%(.*?)%>/$form->{$1}/g;

    if ($form->{printed} !~ /$form->{formname}/) {
    
      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->update_status(\%myconfig);
    }

    $old_form->{printed} = $form->{printed} if defined %$old_form;

    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'printed',
		    id		=> $form->{id} );
 
    $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail) if defined %$old_form;
    
  }


  if ($form->{media} eq 'email') {
    $form->{subject} = qq|$form->{label} $form->{"${inv}number"}| unless $form->{subject};

    $form->{plainpaper} = 1;
    $form->{OUT} = "${LedgerSMB::Sysconfig::sendmail}";
    $form->{printmode} = '|-';

    if ($form->{emailed} !~ /$form->{formname}/) {
      $form->{emailed} .= " $form->{formname}";
      $form->{emailed} =~ s/^ //;

      # save status
      $form->update_status(\%myconfig);
    }

    $now = scalar localtime;
    $cc = $locale->text('Cc: [_1]', $form->{cc}).qq|\n| if $form->{cc};
    $bcc = $locale->text('Bcc: [_1]', $form->{bcc}).qq|\n| if $form->{bcc};
    
    if (defined %$old_form) {
      $old_form->{intnotes} = qq|$old_form->{intnotes}\n\n| if $old_form->{intnotes};
      $old_form->{intnotes} .= qq|[email]\n|
      .$locale->text('Date: [_1]', $now).qq|\n|
      .$locale->text('To: [_1]', $form->{email}).qq|\n${cc}${bcc}|
      .$locale->text('Subject: [_1]', $form->{subject}).qq|\n|;

      $old_form->{intnotes} .= qq|\n|.$locale->text('Message').qq|: |;
      $old_form->{intnotes} .= ($form->{message}) ? $form->{message} : $locale->text('sent');

      $old_form->{message} = $form->{message};
      $old_form->{emailed} = $form->{emailed};

      $old_form->{format} = "postscript" if $myconfig{printer};
      $old_form->{media} = $myconfig{printer};

      $old_form->save_intnotes(\%myconfig, ($order) ? 'oe' : lc $ARAP);
    }
    
    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'emailed',
		    id		=> $form->{id} );
 
    $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail) if defined %$old_form;
  }


  if ($form->{media} eq 'queue') {
    %queued = split / /, $form->{queued};

    if ($filename = $queued{$form->{formname}}) {
      $form->{queued} =~ s/$form->{formname} $filename//;
      unlink "${LedgerSMB::Sysconfig::spool}/$filename";
      $filename =~ s/\..*$//g;
    } else {
      $filename = time;
      $filename .= $$;
    }

    $filename .= ($form->{format} eq 'postscript') ? '.ps' : '.pdf';
    $form->{OUT} = "${LedgerSMB::Sysconfig::spool}/$filename";
    $form->{printmode} = '>';


    $form->{queued} .= " $form->{formname} $filename";
    $form->{queued} =~ s/^ //;

    # save status
    $form->update_status(\%myconfig);

    $old_form->{queued} = $form->{queued};

    %audittrail = ( tablename   => ($order) ? 'oe' : lc $ARAP,
                    reference   => $form->{"${inv}number"},
		    formname    => $form->{formname},
		    action      => 'queued',
		    id          => $form->{id} );

    $old_form->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);

  }


  $form->format_string("email", "cc", "bcc");
 
  $form->{fileid} = $form->{"${inv}number"};
  $form->{fileid} =~ s/(\s|\W)+//g;
  
  $form->parse_template(\%myconfig, ${LedgerSMB::Sysconfig::userspath});

  # if we got back here restore the previous form
  if (defined %$old_form) {
    
    $old_form->{"${inv}number"} = $form->{"${inv}number"};
    
    # restore and display form
    for (keys %$old_form) { $form->{$_} = $old_form->{$_} }
    delete $form->{pre};
    
    $form->{rowcount}--;

    for (qw(exchangerate creditlimit creditremaining)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
    
    for $i (1 .. $form->{paidaccounts}) {
      for (qw(paid exchangerate)) { $form->{"${_}_$i"} = $form->parse_amount(\%myconfig, $form->{"${_}_$i"}) }
    }

    &{ "$display_form" };

  }

}


sub customer_details {

  IS->customer_details(\%myconfig, \%$form);

}


sub vendor_details {

  IR->vendor_details(\%myconfig, \%$form);

}


sub ship_to {

  $title = $form->{title};
  $form->{title} = $locale->text('Ship to');

  for (qw(exchangerate creditlimit creditremaining)) { $form->{$_} = $form->parse_amount(\%myconfig, $form->{$_}) }
  for (1 .. $form->{paidaccounts}) { $form->{"paid_$_"} = $form->parse_amount(\%myconfig, $form->{"paid_$_"}) }

  # get details for name
  &{ "$form->{vc}_details" };

  $number = ($form->{vc} eq 'customer') ? $locale->text('Customer Number') : $locale->text('Vendor Number');

  $nextsub = ($form->{display_form}) ? $form->{display_form} : "display_form";

  $form->{rowcount}--;

  $form->header;

  print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr>
    <td>
      <table>
	<tr class=listheading>
	  <th class=listheading colspan=2 width=50%>|.$locale->text('Billing Address').qq|</th>
	  <th class=listheading width=50%>|.$locale->text('Shipping Address').qq|</th>
	</tr>
	<tr height="5"></tr>
	<tr>
	  <th align=right nowrap>$number</th>
	  <td>$form->{"$form->{vc}number"}</td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Company Name').qq|</th>
	  <td>$form->{name}</td>
	  <td><input name=shiptoname size=35 maxlength=64 value="$form->{shiptoname}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Address').qq|</th>
	  <td>$form->{address1}</td>
	  <td><input name=shiptoaddress1 size=35 maxlength=32 value="$form->{shiptoaddress1}"></td>
	</tr>
	<tr>
	  <th></th>
	  <td>$form->{address2}</td>
	  <td><input name=shiptoaddress2 size=35 maxlength=32 value="$form->{shiptoaddress2}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('City').qq|</th>
	  <td>$form->{city}</td>
	  <td><input name=shiptocity size=35 maxlength=32 value="$form->{shiptocity}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('State/Province').qq|</th>
	  <td>$form->{state}</td>
	  <td><input name=shiptostate size=35 maxlength=32 value="$form->{shiptostate}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Zip/Postal Code').qq|</th>
	  <td>$form->{zipcode}</td>
	  <td><input name=shiptozipcode size=10 maxlength=10 value="$form->{shiptozipcode}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Country').qq|</th>
	  <td>$form->{country}</td>
	  <td><input name=shiptocountry size=35 maxlength=32 value="$form->{shiptocountry}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Contact').qq|</th>
	  <td>$form->{contact}</td>
	  <td><input name=shiptocontact size=35 maxlength=64 value="$form->{shiptocontact}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Phone').qq|</th>
	  <td>$form->{"$form->{vc}phone"}</td>
	  <td><input name=shiptophone size=20 value="$form->{shiptophone}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('Fax').qq|</th>
	  <td>$form->{"$form->{vc}fax"}</td>
	  <td><input name=shiptofax size=20 value="$form->{shiptofax}"></td>
	</tr>
	<tr>
	  <th align=right nowrap>|.$locale->text('E-mail').qq|</th>
	  <td>$form->{email}</td>
	  <td><input name=shiptoemail size=35 value="$form->{shiptoemail}"></td>
	</tr>
      </table>
    </td>
  </tr>
</table>

<input type=hidden name=nextsub value=$nextsub>
|;

  # delete shipto
  for (qw(action nextsub)) { delete $form->{$_} }
  for (qw(name address1 address2 city state zipcode country contact phone fax email)) { delete $form->{"shipto$_"} }
  $form->{title} = $title;
  
  $form->hide_form;

  print qq|

<hr size=3 noshade>

<br>
<button class="submit" type="submit" name="action" value="continue">|.$locale->text('Continue').qq|</button>
</form>

</body>
</html>
|;

}


