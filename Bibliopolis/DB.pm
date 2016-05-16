package Bibliopolis::DB;

use strict;
use warnings;

require Bibliopolis::DB::Factory;

our $VERSION = '0.1';

sub new {

	my $proto = shift;
	my $class = ref $proto ? ref($proto) : $proto;

	my $self = {
		'db_reconnect' => [],
	};

	# Bless early so we can use methods.
	bless $self, $class;

	# Set our name if passed.
	if ( @_ ) { $self->name(shift); }
	else { $self->name('vdb'); }

	# Pass ourself back.
	return $self;	
}

sub db_reconnect {
	my $self = shift;
	if ( @_ ) { push @{ $self->{'db_reconnect'} }, @_; }
	return @{ $self->{'db_reconnect'} };
}

sub name {
	my $self = shift;
	return @_ ? $self->{'name'} = shift : $self->{'name'};
}

sub prepare {
	my $self = shift;
	return $self->_dbh->prepare(@_);
}

sub do
{
	my $self = shift;

	my $dbh = $self->_dbh();

	my $retval =  $dbh->do(@_);

	return $retval;
}

sub last_insertid {
	my $self = shift;
	return $self->_dbh->{'mysql_insertid'};
}

# Pass through stuff to the real database handler.
sub errstr { my $self = shift; return $self->_dbh->errstr(@_); }
sub disconnect { my $self = shift; return $self->_dbh->disconnect(@_); }
sub ping { my $self = shift; return $self->_dbh->ping(); }

sub _dbh {

	my $self = shift;

	# Get the dbh.
	return Bibliopolis::DB::Factory::get_connection(
		$self->name(), $self->db_reconnect()
	);

}

1;
__END__

=head1 NAME

Bibliopolis::DB - Database module.

=head1 SYNOPSIS

	use Bibliopolis::Database;

=head1 DESCRIPTION

Library.

=head1 AUTHOR

Tyler Bird, E<lt>birdty@epromo.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bibliopolis

=cut
