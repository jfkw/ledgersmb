#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
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
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors:
#
# 
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# AR/AP backend routines
# common routines
#
#======================================================================

package AA;


sub post_transaction {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect_noauto($myconfig);

	my $query;
	my $sth;

	my $null;
	($null, $form->{department_id}) = split(/--/, $form->{department});
	$form->{department_id} *= 1;

	my $ml = 1;
	my $table = 'ar';
	my $buysell = 'buy';
	my $ARAP = 'AR';
	my $invnumber = "sinumber";
	my $keepcleared;

	if ($form->{vc} eq 'vendor') {
		$table = 'ap';
		$buysell = 'sell';
		$ARAP = 'AP';
		$ml = -1;
		$invnumber = "vinumber";
	}

	if ($form->{currency} eq $form->{defaultcurrency}) {
		$form->{exchangerate} = 1;
	} else {
		$exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{transdate}, $buysell);

		$form->{exchangerate} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{exchangerate}); 
	}

	my @taxaccounts = split / /, $form->{taxaccounts};
	my $tax = 0;
	my $fxtax = 0;
	my $amount;
	my $diff;

	my %tax = ();
	my $accno;

	# add taxes
	foreach $accno (@taxaccounts) {
		$fxtax += $tax{fxamount}{$accno} = $form->parse_amount($myconfig, $form->{"tax_$accno"});
		$tax += $tax{fxamount}{$accno};

		push @{ $form->{acc_trans}{taxes} }, {
			accno => $accno,
			amount => $tax{fxamount}{$accno},
			project_id => 'NULL',
			fx_transaction => 0 };

		$amount = $tax{fxamount}{$accno} * $form->{exchangerate};
		$tax{amount}{$accno} = $form->round_amount($amount - $diff, 2);
		$diff = $tax{amount}{$accno} - ($amount - $diff);
		$amount = $tax{amount}{$accno} - $tax{fxamount}{$accno};
		$tax += $amount;

		if ($form->{currency} ne $form->{defaultcurrency}) {
			push @{ $form->{acc_trans}{taxes} }, {
				accno => $accno,
				amount => $amount,
				project_id => 'NULL',
				fx_transaction => 1 };
		}

	}

	my %amount = ();
	my $fxinvamount = 0;
	for (1 .. $form->{rowcount}) { 
		$fxinvamount += $amount{fxamount}{$_} = $form->parse_amount($myconfig, $form->{"amount_$_"}) 
	}

	$form->{taxincluded} *= 1;

	my $i;
	my $project_id;
	my $cleared = 0;

	$diff = 0;
	# deduct tax from amounts if tax included
	for $i (1 .. $form->{rowcount}) {

		if ($amount{fxamount}{$i}) {

			if ($form->{taxincluded}) {
				$amount = ($fxinvamount) ? $fxtax * $amount{fxamount}{$i} / $fxinvamount : 0;
				$amount{fxamount}{$i} -= $amount;
			}

			# multiply by exchangerate
			$amount = $amount{fxamount}{$i} * $form->{exchangerate};
			$amount{amount}{$i} = $form->round_amount($amount - $diff, 2);
			$diff = $amount{amount}{$i} - ($amount - $diff);

			($null, $project_id) = split /--/, $form->{"projectnumber_$i"};
			$project_id ||= 'NULL';
			($accno) = split /--/, $form->{"${ARAP}_amount_$i"};

			if ($keepcleared) {
				$cleared = ($form->{"cleared_$i"}) ? 1 : 0;
			}

			push @{ $form->{acc_trans}{lineitems} }, {
				accno => $accno,
				amount => $amount{fxamount}{$i},
				project_id => $project_id,
				description => $form->{"description_$i"},
				cleared => $cleared,
				fx_transaction => 0 };

			if ($form->{currency} ne $form->{defaultcurrency}) {
				$amount = $amount{amount}{$i} - $amount{fxamount}{$i};
				push @{ $form->{acc_trans}{lineitems} }, {
					accno => $accno,
					amount => $amount,
					project_id => $project_id,
					description => $form->{"description_$i"},
					cleared => $cleared,
					fx_transaction => 1 };
			}
		}
	}


	my $invnetamount = 0;
	for (@{ $form->{acc_trans}{lineitems} }) { $invnetamount += $_->{amount} }
	my $invamount = $invnetamount + $tax;

	# adjust paidaccounts if there is no date in the last row
	$form->{paidaccounts}-- unless ($form->{"datepaid_$form->{paidaccounts}"});

	my $paid = 0;
	my $fxamount;

	$diff = 0;
	# add payments
	for $i (1 .. $form->{paidaccounts}) {	
		$fxamount = $form->parse_amount($myconfig, $form->{"paid_$i"});

		if ($fxamount) {
			$paid += $fxamount;

			$paidamount = $fxamount * $form->{exchangerate};

			$amount = $form->round_amount($paidamount - $diff, 2);
			$diff = $amount - ($paidamount - $diff);

			$form->{datepaid} = $form->{"datepaid_$i"};

			$paid{fxamount}{$i} = $fxamount;
			$paid{amount}{$i} = $amount;
		}
	}

	$fxinvamount += $fxtax unless $form->{taxincluded};
	$fxinvamount = $form->round_amount($fxinvamount, 2);
	$invamount = $form->round_amount($invamount, 2);
	$paid = $form->round_amount($paid, 2);

	$paid = ($fxinvamount == $paid) ? $invamount : $form->round_amount($paid * $form->{exchangerate}, 2);

	$query = q|SELECT fxgain_accno_id, fxloss_accno_id
			  	 FROM defaults|;

	my ($fxgain_accno_id, $fxloss_accno_id) = $dbh->selectrow_array($query);

	($null, $form->{employee_id}) = split /--/, $form->{employee};
	unless ($form->{employee_id}) {
		($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh); 
	}

	# check if id really exists
	if ($form->{id}) {
		$keepcleared = 1;
		$query = qq|SELECT id FROM $table
					 WHERE id = $form->{id}|;

		if ($dbh->selectrow_array($query)) {
			# delete detail records
			$query = qq|DELETE FROM acc_trans
						 WHERE trans_id = $form->{id}|;

			$dbh->do($query) || $form->dberror($query);
		}
	} else {

		my $uid = localtime;
		$uid .= "$$";

		$query = qq|INSERT INTO $table (invnumber)
					VALUES ('$uid')|;

		$dbh->do($query) || $form->dberror($query);

		$query = qq|SELECT id FROM $table
					 WHERE invnumber = '$uid'|;

		($form->{id}) = $dbh->selectrow_array($query);
	}


	# record last payment date in ar/ap table
	$form->{datepaid} = $form->{transdate} unless $form->{datepaid};
	my $datepaid = ($paid) ? qq|'$form->{datepaid}'| : 'NULL';

	$form->{invnumber} = $form->update_defaults($myconfig, $invnumber) unless $form->{invnumber};

	$query = qq|UPDATE $table SET invnumber = |.$dbh->quote($form->{invnumber}).qq|,
								  ordnumber = |.$dbh->quote($form->{ordnumber}).qq|,
								  transdate = '$form->{transdate}',
								  $form->{vc}_id = $form->{"$form->{vc}_id"},
								  taxincluded = '$form->{taxincluded}',
								  amount = $invamount,
								  duedate = '$form->{duedate}',
								  paid = $paid,
								  datepaid = $datepaid,
								  netamount = $invnetamount,
								  curr = '$form->{currency}',
								  notes = |.$dbh->quote($form->{notes}).qq|,
								  department_id = $form->{department_id},
								  employee_id = $form->{employee_id},
								  ponumber = |.$dbh->quote($form->{ponumber}).qq|
							WHERE id = $form->{id}|;

	$dbh->do($query) || $form->dberror($query);

	# update exchangerate
	my $buy = $form->{exchangerate};
	my $sell = 0;
		if ($form->{vc} eq 'vendor') {
		$buy = 0;
		$sell = $form->{exchangerate};
	}

	if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
		$form->update_exchangerate($dbh, $form->{currency}, $form->{transdate}, $buy, $sell);
	}

	my $ref;

	# add individual transactions
	foreach $ref (@{ $form->{acc_trans}{lineitems} }) {

		# insert detail records in acc_trans
		if ($ref->{amount}) {
			$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
									project_id, memo, fx_transaction, cleared)
							 VALUES ($form->{id}, (SELECT id FROM chart
													WHERE accno = '$ref->{accno}'),
									 $ref->{amount} * $ml, '$form->{transdate}',
									 $ref->{project_id}, |.$dbh->quote($ref->{description}).qq|,
									 '$ref->{fx_transaction}', '$ref->{cleared}')|;

			$dbh->do($query) || $form->dberror($query);
		}
	}

	# save taxes
	foreach $ref (@{ $form->{acc_trans}{taxes} }) {
		if ($ref->{amount}) {
			$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
									transdate, fx_transaction)
							  VALUES ($form->{id},
									(SELECT id FROM chart
									  WHERE accno = '$ref->{accno}'),
									$ref->{amount} * $ml, '$form->{transdate}',
									'$ref->{fx_transaction}')|;

			$dbh->do($query) || $form->dberror($query);
		}
	}


	my $arap;

	# record ar/ap
	if (($arap = $invamount)) {
		($accno) = split /--/, $form->{$ARAP};

		$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate)
						 VALUES ($form->{id},
								(SELECT id FROM chart
								  WHERE accno = '$accno'),
								$invamount * -1 * $ml, '$form->{transdate}')|;

		$dbh->do($query) || $form->dberror($query);
	}

	# if there is no amount force ar/ap
	if ($fxinvamount == 0) {
		$arap = 1;
	}


	my $exchangerate;

	# add paid transactions
	for $i (1 .. $form->{paidaccounts}) {

		if ($paid{fxamount}{$i}) {

			($accno) = split(/--/, $form->{"${ARAP}_paid_$i"});
			$form->{"datepaid_$i"} = $form->{transdate} unless ($form->{"datepaid_$i"});

			$exchangerate = 0;

			if ($form->{currency} eq $form->{defaultcurrency}) {
				$form->{"exchangerate_$i"} = 1;
			} else {
				$exchangerate = $form->check_exchangerate($myconfig, $form->{currency}, $form->{"datepaid_$i"}, $buysell);

				$form->{"exchangerate_$i"} = ($exchangerate) ? $exchangerate : $form->parse_amount($myconfig, $form->{"exchangerate_$i"}); 
			}

			# if there is no amount
			if ($fxinvamount == 0) {
				$form->{exchangerate} = $form->{"exchangerate_$i"};
			}

			# ar/ap amount
				if ($arap) {
				($accno) = split /--/, $form->{$ARAP};

				# add ar/ap
				$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,transdate)
								 VALUES ($form->{id}, (SELECT id FROM chart
														WHERE accno = '$accno'),
										$paid{amount}{$i} * $ml, '$form->{"datepaid_$i"}')|;

				$dbh->do($query) || $form->dberror($query);
			}

			$arap = $paid{amount}{$i};


			# add payment
			if ($paid{fxamount}{$i}) {

				($accno) = split /--/, $form->{"${ARAP}_paid_$i"};

				my $cleared = ($form->{"cleared_$i"}) ? 1 : 0;

				$amount = $paid{fxamount}{$i};
				$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
												   transdate, source, memo, cleared)
								 VALUES ($form->{id}, (SELECT id FROM chart
														WHERE accno = '$accno'),
										$amount * -1 * $ml, '$form->{"datepaid_$i"}', |
										.$dbh->quote($form->{"source_$i"}).qq|, |
										.$dbh->quote($form->{"memo_$i"}).qq|, '$cleared')|;

				$dbh->do($query) || $form->dberror($query);

				if ($form->{currency} ne $form->{defaultcurrency}) {

					# exchangerate gain/loss
					$amount = ($form->round_amount($paid{fxamount}{$i} * $form->{exchangerate},2) - $form->round_amount($paid{fxamount}{$i} * $form->{"exchangerate_$i"},2)) * -1;

					if ($amount) {

						my $accno_id = (($amount * $ml) > 0) ? $fxgain_accno_id : $fxloss_accno_id;

						$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
												transdate, fx_transaction, cleared)
										 VALUES ($form->{id}, $accno_id,
												$amount * $ml, '$form->{"datepaid_$i"}', '1',
												'$cleared')|;

						$dbh->do($query) || $form->dberror($query);
					}

					# exchangerate difference
					$amount = $paid{amount}{$i} - $paid{fxamount}{$i} + $amount;

					$query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount,
														transdate, fx_transaction, cleared, source)
									VALUES ($form->{id}, (SELECT id FROM chart
														   WHERE accno = '$accno'),
											$amount * -1 * $ml, '$form->{"datepaid_$i"}', '1',
											'$cleared', |
											.$dbh->quote($form->{"source_$i"}).qq|)|;

					$dbh->do($query) || $form->dberror($query);

				}

				# update exchangerate record
				$buy = $form->{"exchangerate_$i"};
				$sell = 0;

				if ($form->{vc} eq 'vendor') {
					$buy = 0;
					$sell = $form->{"exchangerate_$i"};
				}

				if (($form->{currency} ne $form->{defaultcurrency}) && !$exchangerate) {
					$form->update_exchangerate($dbh, $form->{currency}, $form->{"datepaid_$i"}, $buy, $sell);
				}
			}
		}
	}

	# save printed and queued
	$form->save_status($dbh);

	my %audittrail = ( tablename  => $table,
					   reference  => $form->{invnumber},
					   formname   => 'transaction',
					   action     => 'posted',
					   id         => $form->{id} );

	$form->audittrail($dbh, "", \%audittrail);

	$form->save_recurring($dbh, $myconfig);

	my $rc = $dbh->commit;

	$dbh->disconnect;

	$rc;

}


sub delete_transaction {
	my ($self, $myconfig, $form) = @_;

	# connect to database, turn AutoCommit off
	my $dbh = $form->dbconnect_noauto($myconfig);

	my $table = ($form->{vc} eq 'customer') ? 'ar' : 'ap';

	my %audittrail = ( tablename  => $table,
					   reference  => $form->{invnumber},
					   formname   => 'transaction',
					   action     => 'deleted',
					   id         => $form->{id} );

	$form->audittrail($dbh, "", \%audittrail);

	my $query = qq|DELETE FROM $table WHERE id = $form->{id}|;
	$dbh->do($query) || $form->dberror($query);

	$query = qq|DELETE FROM acc_trans WHERE trans_id = $form->{id}|;
	$dbh->do($query) || $form->dberror($query);

	# get spool files
	$query = qq|SELECT spoolfile 
				  FROM status
				 WHERE trans_id = $form->{id}
				   AND spoolfile IS NOT NULL|;

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my $spoolfile;
	my @spoolfiles = ();

	while (($spoolfile) = $sth->fetchrow_array) {
		push @spoolfiles, $spoolfile;
	}
 
	$sth->finish;

	$query = qq|DELETE FROM status WHERE trans_id = $form->{id}|;
	$dbh->do($query) || $form->dberror($query);

	# commit
	my $rc = $dbh->commit;
	$dbh->disconnect;

	if ($rc) {
		foreach $spoolfile (@spoolfiles) {
			unlink "$spool/$spoolfile" if $spoolfile;
		}
	}

	$rc;
}



sub transactions {
	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);
	my $null;
	my $var;
	my $paid = "a.paid";
	my $ml = 1;
	my $ARAP = 'AR';
	my $table = 'ar';
	my $buysell = 'buy';
	my $acc_trans_join;
	my $acc_trans_flds;

	if ($form->{vc} eq 'vendor') {
		$ml = -1;
		$ARAP = 'AP';
		$table = 'ap';
		$buysell = 'sell';
	}

	($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};

	if ($form->{outstanding}) {
		$paid = qq|SELECT SUM(ac.amount) * -1 * $ml
					 FROM acc_trans ac
					 JOIN chart c ON (c.id = ac.chart_id)
					WHERE ac.trans_id = a.id
					  AND (c.link LIKE '%${ARAP}_paid%' OR c.link = '')|;
		$paid .= qq|
					  AND ac.transdate <= '$form->{transdateto}'| if $form->{transdateto};
		$form->{summary} = 1;
	}


	if (!$form->{summary}) {
		$acc_trans_flds = qq|, c.accno, ac.source,
							   pr.projectnumber, ac.memo AS description,
							   ac.amount AS linetotal,
							   i.description AS linedescription|;

		$acc_trans_join = qq| JOIN acc_trans ac ON (a.id = ac.trans_id)
							  JOIN chart c ON (c.id = ac.chart_id)
						      LEFT JOIN project pr ON (pr.id = ac.project_id)
							  LEFT JOIN invoice i ON (i.id = ac.invoice_id)|;
	}

	my $query = qq|SELECT a.id, a.invnumber, a.ordnumber, a.transdate,
						  a.duedate, a.netamount, a.amount, ($paid) AS paid,
						  a.invoice, a.datepaid, a.terms, a.notes,
						  a.shipvia, a.shippingpoint, e.name AS employee, vc.name,
						  a.$form->{vc}_id, a.till, m.name AS manager, a.curr,
						  ex.$buysell AS exchangerate, d.description AS department,
						  a.ponumber $acc_trans_flds
					 FROM $table a
					 JOIN $form->{vc} vc ON (a.$form->{vc}_id = vc.id)
				LEFT JOIN employee e ON (a.employee_id = e.id)
				LEFT JOIN employee m ON (e.managerid = m.id)
				LEFT JOIN exchangerate ex ON (ex.curr = a.curr
											  AND ex.transdate = a.transdate)
				LEFT JOIN department d ON (a.department_id = d.id) 
				$acc_trans_join|;

	my %ordinal = ( id => 1,
					invnumber => 2,
					ordnumber => 3,
					transdate => 4,
					duedate => 5,
					datepaid => 10,
					shipvia => 13,
					shippingpoint => 14,
					employee => 15,
					name => 16,
					manager => 19,
					curr => 20,
					department => 22,
					ponumber => 23,
					accno => 24,
					source => 25,
					project => 26,
					description => 27);


	my @a = (transdate, invnumber, name);
	push @a, "employee" if $form->{l_employee};
	push @a, "manager" if $form->{l_manager};
	my $sortorder = $form->sort_order(\@a, \%ordinal);

	my $where = "1 = 1";
	if ($form->{"$form->{vc}_id"}) {
		$where .= qq| AND a.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
	} else {
		if ($form->{$form->{vc}}) {
			$var = $form->like(lc $form->{$form->{vc}});
			$where .= " AND lower(vc.name) LIKE '$var'";
		}
	}

	for (qw(department employee)) {
		if ($form->{$_}) {
			($null, $var) = split /--/, $form->{$_};
			$where .= " AND a.${_}_id = $var";
		}
	}

	for (qw(invnumber ordnumber)) {
		if ($form->{$_}) {
			$var = $form->like(lc $form->{$_});
			$where .= " AND lower(a.$_) LIKE '$var'";
			$form->{open} = $form->{closed} = 0;
		}
	}
        if ($form->{partsid}){
		$where .= " AND a.id IN (select trans_id FROM invoice
			WHERE parts_id = $form->{partsid})";
	}

	for (qw(ponumber shipvia notes)) {
		if ($form->{$_}) {
			$var = $form->like(lc $form->{$_});
			$where .= " AND lower(a.$_) LIKE '$var'";
		}
	}

	if ($form->{description}) {
		if ($acc_trans_flds) {
			$var = $form->like(lc $form->{description});
			$where .= " AND lower(ac.memo) LIKE '$var'
			OR lower(i.description) LIKE '$var'";
		} else {
			$where .= " AND a.id = 0";
		}
	}

	if ($form->{source}) {
		if ($acc_trans_flds) {
			$var = $form->like(lc $form->{source});
			$where .= " AND lower(ac.source) LIKE '$var'";
		} else {
			$where .= " AND a.id = 0";
		}
	}


	$where .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
	$where .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};
	
	if ($form->{open} || $form->{closed}) {
		unless ($form->{open} && $form->{closed}) {
			$where .= " AND a.amount != a.paid" if ($form->{open});
			$where .= " AND a.amount = a.paid" if ($form->{closed});
		}
	}

	if ($form->{till} ne "") {
		$where .= " AND a.invoice = '1'
					AND a.till IS NOT NULL";

		if ($myconfig->{role} eq 'user') {
			$where .= " AND e.login = '$form->{login}'";
		}
	}

	if ($form->{$ARAP}) {
		my ($accno) = split /--/, $form->{$ARAP};

		$where .= qq|AND a.id IN (SELECT ac.trans_id
					FROM acc_trans ac
					JOIN chart c ON (c.id = ac.chart_id)
				   WHERE a.id = ac.trans_id
					 AND c.accno = '$accno')|;
	}

	if ($form->{description}) {
		$var = $form->like(lc $form->{description});
		$where .= qq| AND (a.id IN (SELECT DISTINCT trans_id
					 FROM acc_trans
					WHERE lower(memo) LIKE '$var')
					   OR a.id IN (SELECT DISTINCT trans_id
									 FROM invoice
									WHERE lower(description) LIKE '$var'))|;
	}

	$query .= "WHERE $where
			ORDER BY $sortorder";

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		$ref->{exchangerate} = 1 unless $ref->{exchangerate};

		if ($ref->{linetotal} <= 0) {
			$ref->{debit} = $ref->{linetotal} * -1;
			$ref->{credit} = 0;
		} else {
			$ref->{debit} = 0;
			$ref->{credit} = $ref->{linetotal};
		}

		if ($ref->{invoice}) {
			$ref->{description} ||= $ref->{linedescription};
		}

		if ($form->{outstanding}) {
			next if $form->round_amount($ref->{amount}, 2) == $form->round_amount($ref->{paid}, 2);
		}

		push @{ $form->{transactions} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;
}


# this is used in IS, IR to retrieve the name
sub get_name {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $dateformat = $myconfig->{dateformat};

	if ($myconfig->{dateformat} !~ /^y/) {
		my @a = split /\W/, $form->{transdate};
		$dateformat .= "yy" if (length $a[2] > 2);
	}

	if ($form->{transdate} !~ /\W/) {
		$dateformat = 'yyyymmdd';
	}

	my $duedate;

	if ($myconfig->{dbdriver} eq 'DB2') {
		$duedate = ($form->{transdate}) ? "date('$form->{transdate}') + c.terms DAYS" : "current_date + c.terms DAYS";
	} else {
		$duedate = ($form->{transdate}) ? "to_date('$form->{transdate}', '$dateformat') + c.terms" : "current_date + c.terms";
	}

	$form->{"$form->{vc}_id"} *= 1;
	# get customer/vendor
	my $query = qq|SELECT c.name AS $form->{vc}, c.discount, c.creditlimit, c.terms,
						  c.email, c.cc, c.bcc, c.taxincluded,
						  c.address1, c.address2, c.city, c.state,
						  c.zipcode, c.country, c.curr AS currency, c.language_code,
						  $duedate AS duedate, c.notes AS intnotes,
						  b.discount AS tradediscount, b.description AS business,
						  e.name AS employee, e.id AS employee_id
					FROM $form->{vc} c
			   LEFT JOIN business b ON (b.id = c.business_id)
			   LEFT JOIN employee e ON (e.id = c.employee_id)
				   WHERE c.id = $form->{"$form->{vc}_id"}|;

	my $sth = $dbh->prepare($query);

	$sth->execute || $form->dberror($query);

	$ref = $sth->fetchrow_hashref(NAME_lc);

	if ($form->{id}) {
		for (qw(currency employee employee_id intnotes)) { delete $ref->{$_} }
	}

	for (keys %$ref) { $form->{$_} = $ref->{$_} }
	$sth->finish;

	my $buysell = ($form->{vc} eq 'customer') ? "buy" : "sell";

	# if no currency use defaultcurrency
	$form->{currency} = ($form->{currency}) ? $form->{currency} : $form->{defaultcurrency}; 
	$form->{exchangerate} = 0 if $form->{currency} eq $form->{defaultcurrency};

	if ($form->{transdate} && ($form->{currency} ne $form->{defaultcurrency})) {
		$form->{exchangerate} = $form->get_exchangerate($dbh, $form->{currency}, $form->{transdate}, $buysell);
	}

	$form->{forex} = $form->{exchangerate};

	# if no employee, default to login
	($form->{employee}, $form->{employee_id}) = $form->get_employee($dbh) unless $form->{employee_id};

	my $arap = ($form->{vc} eq 'customer') ? 'ar' : 'ap';
	my $ARAP = uc $arap;

	$form->{creditremaining} = $form->{creditlimit};
	$query = qq|SELECT SUM(amount - paid)
				  FROM $arap
				 WHERE $form->{vc}_id = $form->{"$form->{vc}_id"}|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	($form->{creditremaining}) -= $sth->fetchrow_array;

	$sth->finish;

	$query = qq|SELECT o.amount, (SELECT e.$buysell FROM exchangerate e
								   WHERE e.curr = o.curr
									 AND e.transdate = o.transdate)
				  FROM oe o
				 WHERE o.$form->{vc}_id = $form->{"$form->{vc}_id"}
				   AND o.quotation = '0'
				   AND o.closed = '0'|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my ($amount, $exch) = $sth->fetchrow_array) {
		$exch = 1 unless $exch;
		$form->{creditremaining} -= $amount * $exch;
	}

	$sth->finish;


	# get shipto if we did not converted an order or invoice
	if (!$form->{shipto}) {

		for (qw(shiptoname shiptoaddress1 shiptoaddress2 shiptocity 
				shiptostate shiptozipcode shiptocountry shiptocontact 
				shiptophone shiptofax shiptoemail)) { 
			delete $form->{$_} 
		}

		## needs fixing (SELECT *)
		$query = qq|SELECT * 
					  FROM shipto
					 WHERE trans_id = $form->{"$form->{vc}_id"}|;

		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		$ref = $sth->fetchrow_hashref(NAME_lc);
		for (keys %$ref) { $form->{$_} = $ref->{$_} }
		$sth->finish;
	}

	# get taxes
	$query = qq|SELECT c.accno
				  FROM chart c
				  JOIN $form->{vc}tax ct ON (ct.chart_id = c.id)
				 WHERE ct.$form->{vc}_id = $form->{"$form->{vc}_id"}|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	my %tax;

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
		$tax{$ref->{accno}} = 1;
	}

	$sth->finish;

	my $where = qq|AND (t.validto >= '$form->{transdate}' OR t.validto IS NULL)| if $form->{transdate};

	# get tax rates and description
	$query = qq|SELECT c.accno, c.description, t.rate, t.taxnumber
				  FROM chart c
				  JOIN tax t ON (c.id = t.chart_id)
				 WHERE c.link LIKE '%${ARAP}_tax%'
					  $where
			  ORDER BY accno, validto|;

	$sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	$form->{taxaccounts} = "";
	my %a = ();

	while ($ref = $sth->fetchrow_hashref(NAME_lc)) {

		if ($tax{$ref->{accno}}) {
			if (not exists $a{$ref->{accno}}) {
				for (qw(rate description taxnumber)) { $form->{"$ref->{accno}_$_"} = $ref->{$_} }
				$form->{taxaccounts} .= "$ref->{accno} ";
				$a{$ref->{accno}} = 1;
			}
		}
	}

	$sth->finish;
	chop $form->{taxaccounts};

	# setup last accounts used for this customer/vendor
	if (!$form->{id} && $form->{type} !~ /_(order|quotation)/) {

		$query = qq|SELECT c.accno, c.description, c.link, c.category,
						   ac.project_id, p.projectnumber, a.department_id,
						   d.description AS department
					  FROM chart c
					  JOIN acc_trans ac ON (ac.chart_id = c.id)
					  JOIN $arap a ON (a.id = ac.trans_id)
				 LEFT JOIN project p ON (ac.project_id = p.id)
				 LEFT JOIN department d ON (d.id = a.department_id)
					 WHERE a.$form->{vc}_id = $form->{"$form->{vc}_id"}
					   AND a.id IN (SELECT max(id) 
									  FROM $arap
									 WHERE $form->{vc}_id = $form->{"$form->{vc}_id"})|;

		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		my $i = 0;

		while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
			$form->{department} = $ref->{department};
			$form->{department_id} = $ref->{department_id};

			if ($ref->{link} =~ /_amount/) {
				$i++;
				$form->{"$form->{ARAP}_amount_$i"} = "$ref->{accno}--$ref->{description}" if $ref->{accno};
				$form->{"projectnumber_$i"} = "$ref->{projectnumber}--$ref->{project_id}" if $ref->{project_id};
			}

			if ($ref->{link} eq $form->{ARAP}) {
				$form->{$form->{ARAP}} = $form->{"$form->{ARAP}_1"} = "$ref->{accno}--$ref->{description}" if $ref->{accno};
			}
		}

		$sth->finish;
		$form->{rowcount} = $i if ($i && !$form->{type});
	}

	$dbh->disconnect;
}

1;
