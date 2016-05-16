package Bibliopolis::DB::StatementCache;

use strict;
use warnings;

our $VERSION = '0.1';

require Bibliopolis::DB;

{

	my %cache = ();

	sub new {

		my $proto = shift;
		my $class = ref $proto ? ref($proto) : $proto;

		my $input = shift;
		my $db = undef();

		if ( $input ) {
			# Our input was either an object or it was text. Our
			# db will be an object when we are done here, one way
			# or another.
			$db = ref $input ? $input : Bibliopolis::DB->new($input);
		}
		else {
			# Use the Bibliopolis::DB defaults.
			$db = Bibliopolis::DB->new();
		}

		return $cache{$db->name()}
			if exists $cache{$db->name()};

		my $self = {
			'db' => $db,
			'sth' => {},
		};

		bless $self, $class;

		# Register ourself with this databases reconnect handler.
		$db->db_reconnect(['method', join('::', $class, 'db_reconnect'), $self]);

		return $cache{$db->name()} = $self;

	}

}

# Access to the database this cache of statements is associated with.
sub db { my $self = shift; return $self->{'db'}; }

sub db_reconnect {
	my $self = shift;
	$self->flush();
}

sub flush {
	my $self = shift;
	$self->{'sth'} = {};
}

sub statement {

	my ($self, $sql) = @_;

	unless (
		exists $self->{'sth'}->{$sql} and
		$self->ping() and
		$self->{'sth'}->{$sql}
	) {

		# We do this if the sth is not already prepared.
		$self->{'sth'}->{$sql} = $self->db->prepare($sql);

	}

	return $self->{'sth'}->{$sql};

}

sub statement_sth_flush {
	my ($self, $key) = @_;
	delete $self->{'sth'}->{$key};
}

sub last_insertid {
	my $self = shift;
	return $self->db->last_insertid();
}

sub ping {
	my $self = shift;
	# TODO: This might not be the cleanest way to do this.
	return $self->db->_dbh();
}

1;

__END__

=head1 NAME

Bibliopolis::DB::StatementCache - Caches database statements.

=head1 SYNOPSIS

	use Bibliopolis::DB::StatementCache;

=head1 AUTHOR

Tyler Bird, E<lt>birdty@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bibliopolis

=cut