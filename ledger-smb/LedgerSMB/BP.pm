#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
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
#  Copyright (C) 2003
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#  Contributors: 

# This file has undergone whitespace cleanup.
#
#======================================================================
#
# Batch printing module backend routines
#
#======================================================================

package BP;


sub get_vc {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my %arap = ( invoice => ['ar'],
				 packing_list => ['oe', 'ar'],
				 sales_order => ['oe'],
				 work_order => ['oe'],
				 pick_list => ['oe', 'ar'],
				 purchase_order => ['oe'],
				 bin_list => ['oe'],
				 sales_quotation => ['oe'],
				 request_quotation => ['oe'],
				 timecard => ['jcitems'],
				 check => ['ap'],
		);

	my $query = "";
	my $sth;
	my $n;
	my $count;
	my $item;

	foreach $item (@{ $arap{$form->{type}} }) {
		$query = qq|SELECT count(*)
					  FROM (SELECT DISTINCT vc.id
									   FROM $form->{vc} vc, $item a, status s
									  WHERE a.$form->{vc}_id = vc.id
										AND s.trans_id = a.id
										AND s.formname = '$form->{type}'
										AND s.spoolfile IS NOT NULL) AS total|;

		($n) = $dbh->selectrow_array($query);
		$count += $n;
	}

	# build selection list
	my $union = "";
	$query = "";

	if ($count < $myconfig->{vclimit}) {

		foreach $item (@{ $arap{$form->{type}} }) {
			$query .= qq| $union
						 SELECT DISTINCT vc.id, vc.name
									FROM $item a
									JOIN $form->{vc} vc ON (a.$form->{vc}_id = vc.id)
									JOIN status s ON (s.trans_id = a.id)
								   WHERE s.formname = '$form->{type}'
									 AND s.spoolfile IS NOT NULL|;
			$union = "UNION";
		}

		$sth = $dbh->prepare($query);
		$sth->execute || $form->dberror($query);

		while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
			push @{ $form->{"all_$form->{vc}"} }, $ref;
		}

		$sth->finish;
	}

	$form->all_years($myconfig, $dbh);
	$dbh->disconnect;

}


sub get_spoolfiles {

	my ($self, $myconfig, $form) = @_;

	# connect to database
	my $dbh = $form->dbconnect($myconfig);

	my $query;
	my $invnumber = "invnumber";
	my $item;

	my %arap = ( invoice => ['ar'],
				 packing_list => ['oe', 'ar'],
				 sales_order => ['oe'],
				 work_order => ['oe'],
				 pick_list => ['oe', 'ar'],
				 purchase_order => ['oe'],
				 bin_list => ['oe'],
				 sales_quotation => ['oe'],
				 request_quotation => ['oe'],
				 timecard => ['jc'],
				 check => ['ap'],
		);

	($form->{transdatefrom}, $form->{transdateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};

	if ($form->{type} eq 'timecard') {
		my $dateformat = $myconfig->{dateformat};
		$dateformat =~ s/yy/yyyy/;
		$dateformat =~ s/yyyyyy/yyyy/;

		$invnumber = 'id';

		$query = qq|SELECT j.id, e.name, j.id AS invnumber,
						   to_char(j.checkedin, '$dateformat') AS transdate,
						   '' AS ordnumber, '' AS quonumber, '0' AS invoice,
						   '$arap{$form->{type}}[0]' AS module, s.spoolfile
					  FROM jcitems j
					  JOIN employee e ON (e.id = j.employee_id)
					  JOIN status s ON (s.trans_id = j.id)
					 WHERE s.formname = '$form->{type}'
					   AND s.spoolfile IS NOT NULL|;

		if ($form->{"$form->{vc}_id"}) {
			$query .= qq| AND j.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
		} else {

			if ($form->{$form->{vc}}) {
				$item = $form->like(lc $form->{$form->{vc}});
				$query .= " AND lower(e.name) LIKE '$item'";
			}
		}

		$query .= " AND j.checkedin >= '$form->{transdatefrom}'" if $form->{transdatefrom};
		$query .= " AND j.checkedin <= '$form->{transdateto}'" if $form->{transdateto};

	} else {

		foreach $item (@{ $arap{$form->{type}} }) {

			$invoice = "a.invoice";
			$invnumber = "invnumber";

			if ($item eq 'oe') {
				$invnumber = "ordnumber";
				$invoice = "'0'"; 
			}

			$query .= qq| $union
						  SELECT a.id, vc.name, a.$invnumber AS invnumber, a.transdate,
								 a.ordnumber, a.quonumber, $invoice AS invoice,
								 '$item' AS module, s.spoolfile
							FROM $item a, $form->{vc} vc, status s
						   WHERE s.trans_id = a.id
							 AND s.spoolfile IS NOT NULL
							 AND s.formname = '$form->{type}'
							 AND a.$form->{vc}_id = vc.id|;

			if ($form->{"$form->{vc}_id"}) {
				$query .= qq| AND a.$form->{vc}_id = $form->{"$form->{vc}_id"}|;
			} else {

				if ($form->{$form->{vc}} ne "") {
					$item = $form->like(lc $form->{$form->{vc}});
					$query .= " AND lower(vc.name) LIKE '$item'";
				}
			}

			if ($form->{invnumber} ne "") {
				$item = $form->like(lc $form->{invnumber});
				$query .= " AND lower(a.invnumber) LIKE '$item'";
			}

			if ($form->{ordnumber} ne "") {
				$item = $form->like(lc $form->{ordnumber});
				$query .= " AND lower(a.ordnumber) LIKE '$item'";
			}

			if ($form->{quonumber} ne "") {
				$item = $form->like(lc $form->{quonumber});
				$query .= " AND lower(a.quonumber) LIKE '$item'";
			}

			$query .= " AND a.transdate >= '$form->{transdatefrom}'" if $form->{transdatefrom};
			$query .= " AND a.transdate <= '$form->{transdateto}'" if $form->{transdateto};

			$union = "UNION";

		}
	}

	my %ordinal = ( 'name' => 2,
					'invnumber' => 3,
					'transdate' => 4,
					'ordnumber' => 5,
					'quonumber' => 6,);

	my @a = ();
	push @a, ("transdate", "$invnumber", "name");
	my $sortorder = $form->sort_order(\@a, \%ordinal);
	$query .= " ORDER by $sortorder";

	my $sth = $dbh->prepare($query);
	$sth->execute || $form->dberror($query);

	while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
		push @{ $form->{SPOOL} }, $ref;
	}

	$sth->finish;
	$dbh->disconnect;

}


sub delete_spool {

	my ($self, $myconfig, $form, $spool) = @_;

	# connect to database, turn AutoCommit off
	my $dbh = $form->dbconnect_noauto($myconfig);

	my $query;
	my %audittrail;

	$query = qq|UPDATE status 
				   SET spoolfile = NULL
				 WHERE spoolfile = ?|;

	my $sth = $dbh->prepare($query) || $form->dberror($query);

	foreach my $i (1 .. $form->{rowcount}) {

		if ($form->{"checked_$i"}) {
			$sth->execute($form->{"spoolfile_$i"}) || $form->dberror($query);
			$sth->finish;

			%audittrail = ( tablename  => $form->{module},
							reference  => $form->{"reference_$i"},
							formname   => $form->{type},
							action     => 'dequeued',
							id         => $form->{"id_$i"} );

			$form->audittrail($dbh, "", \%audittrail);
		}
	}

	# commit
	my $rc = $dbh->commit;
	$dbh->disconnect;

	if ($rc) {
		foreach my $i (1 .. $form->{rowcount}) {
			$_ = qq|$spool/$form->{"spoolfile_$i"}|;
			if ($form->{"checked_$i"}) {
				unlink;
			}
		}
	}

	$rc;
}


sub print_spool {

	my ($self, $myconfig, $form, $spool) = @_;

	# connect to database
	my $dbh = $form->dbconnect_noauto($myconfig);

	my %audittrail;

	my $query = qq|UPDATE status 
					  SET printed = '1'
					WHERE spoolfile = ?|;

	my $sth = $dbh->prepare($query) || $form->dberror($query);

	foreach my $i (1 .. $form->{rowcount}) {

		if ($form->{"checked_$i"}) {
			open(OUT, $form->{OUT}) or $form->error("$form->{OUT} : $!");
			binmode(OUT);

			$spoolfile = qq|$spool/$form->{"spoolfile_$i"}|;

			# send file to printer
			open(IN, $spoolfile) or $form->error("$spoolfile : $!");
			binmode(IN);

			while (<IN>) {
				print OUT $_;
			}

			close(IN);
			close(OUT);

			$sth->execute($form->{"spoolfile_$i"}) || $form->dberror($query);
			$sth->finish;

			%audittrail = ( tablename  => $form->{module},
							reference  => $form->{"reference_$i"},
							formname   => $form->{type},
							action     => 'printed',
							id         => $form->{"id_$i"} );

			$form->audittrail($dbh, "", \%audittrail);

			$dbh->commit;
		}
	}

	$dbh->disconnect;

}


1;

