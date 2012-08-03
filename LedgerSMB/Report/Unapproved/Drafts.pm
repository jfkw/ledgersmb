=head1 NAME

LedgerSMB::Report::Unapproved::Drafts - Unapproved Drafts (single 
transactions) in LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Unapproved::Drafts->new(%$request);
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This provides an ability to search for (and approve or delete) pending
transactions.  

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

package LedgerSMB::Report::Unapproved::Drafts;
use Moose;
extends 'LedgerSMB::Report';

use LedgerSMB::DBObject::Business_Unit_Class;
use LedgerSMB::DBObject::Business_Unit;

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=item select

Select boxes for selecting the returned items.

=item id

ID of transaction

=item transdate

Post date of transaction

=item reference text

Invoice number or GL reference

=item description

Description of transaction

=item amount

Amount

=back

=cut

sub columns {
    return [
    {col_id => 'select',
       name => '',
       type => 'checkbox' },

    {col_id => 'id',
       name => text('ID'),
       type => 'text',
     pwidth => 1, },

    {col_id => 'transdate',
       name => text('Date'),
       type => 'text',
     pwidth => '4', },

    {col_id => 'reference',
       name => text('Reference'),
       type => 'href',
  href_base => '',
     pwidth => '3', },

    {col_id => 'description',
       name => text('Description'),
       type => 'text',
     pwidth => '6', },

    {col_id => 'amount',
       name => text('AR/AP/GL Amount'),
       type => 'text',
     pwidth => '2', },
    ];
    # TODO:  business_units int[]
}


=item name

Returns the localized template name

=cut

sub name {
    return text('Draft Search');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    return [{name => 'type',
             text => text('Draft Type')},
            {name => 'reference',
             text => text('Reference')},
            {name => 'amount_gt',
             text => text('Amount Greater Than')},
            {name => 'amount_lt',
             text => text('Amount Less Than')}, ]
}

=item subtotal_cols

Returns list of columns for subtotals

=cut

sub subtotal_cols {
    return [];
}

=back

=head2 Criteria Properties

Note that in all cases, undef matches everything.

=over

=item reference (text)

Exact match on reference or invoice number.

=cut

has 'reference' => (is => 'rw', isa => 'Maybe[Str]');

=item type

ar for AR drafts, ap for AP drafts, gl for GL ones.

=cut

has 'type' => (is => 'rw', isa => 'Maybe[Str]');

=item amount_gt

The amount of the draft must be greater than this for it to show up.

=cut

has 'amount_gt' => (is => 'rw', coerce => 1, isa =>'LedgerSMB::Moose::Number');

=item amount_lt

The amount of the draft must be less than this for it to show up.

=cut

has 'amount_lt' => (is => 'rw', coerce => 1, isa =>'LedgerSMB::Moose::Number'););

=back

=head1 METHODS

=over

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->exec_method({funcname => 'draft__search'});
    for my $ref (@rows){
        my $script = $self->type;
        if ($ref->{invoice}){
            $script = 'is' if $self->type eq 'ar';
            $script = 'ir' if $self->type eq 'ap';
        }
        $ref->{reference_href_suffix} = "$script.pl?action=edit&id=$ref->{id}";
    }
    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;
return 1;
