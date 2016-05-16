package Bibliopolis::DB::Factory;

use strict;
use warnings;

our $VERSION = '0.1';

require DBI;

{
	my %database = ();
	my %name = ();

	# We have not read the config yet.
	my $_read_config = undef();

	sub _read_config {

		unless ( $_read_config ) {

			# We are going to read a config file.
			require IO::File;

			# Default filename.
			my $filename = '/usr/local/epromo/etc/database';

			
			if (
				exists $ENV{'BIBLIOPOLIS_DB_CONFIG_FILENAME'} and
				-e $ENV{'BIBLIOPOLIS_DB_CONFIG_FILENAME'}
			) {

				# If the environment has a configuration filename
				# specified, use that instead of our default if
				# the file actually exists.
				$filename = $ENV{'BIBLIOPOLIS_DB_CONFIG_FILENAME'};

			}
			
			# Because someone has done something very wrong in the past,
			# we should make sure we cannot be hurt by it again.
			local $/ = "\n";

			# Open our database configuration file.
			my $file = IO::File->new($filename);

			while (my $line = <$file>) {

				# Only concerned about files that look like that are database
				# or alias configuration lines.
				next unless my ($type) = $line =~ /^\s*(database|alias)\s+/i;

				# Get rid of newlines.
				chomp($line);

				# Get rid of comments.
				$line =~ s/#.*$//m;

				if ( $type =~ /database/ ) {

					# Our database configuration line will consist of one or more
					# of the following values, in this order.
					my ($name, $host, $user, $pass) = $line =~
						/database\s+"(\S+)"(?:\s+"(\S*)"(?:\s+"(\S*)"(?:\s+"(\S*)"|)|)|)/i;

					if ( $name ) {

						# If we at least have a name, we know that this is a valid
						# database configuration line.

						my @entry = ($name);

						# Push each of these onto the stack if they are found.
						push @entry, $host if defined $host;
						push @entry, $user if defined $user;
						push @entry, $pass if defined $pass;

						# Store our database information with this name.
						$database{$name} = [@entry];

						# Store our name with our name.
						$name{$name} = $name;

					}

				}
				elsif ( $type =~ /alias/ ) {

					# Our database configuration line will consist of exactly
					# two values, in this order.
					my ($name, $actual) = $line =~ /alias\s+"(\S+)"\s+"(\S+)"/i; 

					if ( $name and $actual ) {

						# Store our name with our name.
						$name{$name} = $actual;

					}

				}

			}

			# We have now read the config file.
			$_read_config = 1;
		}
	}

	sub _get_connection_info {

		my $name = shift;

		# Bleh. What are they trying to pull?
		return undef() unless $name;

		# Read the config file if we have not already.
		_read_config();

		# Bleh. This name is not a valid name as far as our
		# configuration file is concerned.
		return undef() unless exists $name{$name};

		# Pass back the info for the actual database that our
		# name refers to.
		return $database{$name{$name}};		
	}

	sub get_hostname_from_connection {
		my $name = shift;

		_read_config();		
		my $hostname = $database{$name}[1];
		return $hostname;
	}
}

{
	# Cache of database handlers.
	my %dbh = ();

	sub get_connection {

		my $name = shift;
		
		if ( my $info = _get_connection_info($name) ) {


			# Our name should be the first element.
			my $name = $info->[0];

			if ( exists $dbh{$name} and $dbh{$name} and ! $dbh{$name}->ping() ) {

				my @commands = @_;

				# Call each command.
				for my $command_array ( @commands ) {

					my ($handler_type, $reconnect_handler, @args) = @{ $command_array };

					if ( $handler_type eq 'method' ) {

						# Best style.
						my $object = shift @args;
						$object->$reconnect_handler(@args);

					}
					elsif ( $handler_type eq 'function' ) {

						# Not a super good way to do this?
						no strict qw(refs);
						&$reconnect_handler(@args);
						use strict qw(refs);

					}

				}

				# Remove from the cache.
				delete $dbh{$name};

			}

			unless (
				# We should do this unless we have an existing database
				# connection with this name.
				exists $dbh{$name} and $dbh{$name}
			) {
				# Connect (or reconnect) if this name is not already cached.
				$dbh{$name} = _connect($info);
			}

			# Pass back the existing database handler.
			return $dbh{$name};
		}
	}
}

sub _connect {

	my $info = shift;

	# Break up our database info.
	my ($name, $host, $user, $pass) = @{ $info };

	# Start our our DSN.
	my $dsn = 'DBI:mysql';

	# The DSN should include a database name if we had a name passed.
	$dsn = join(':', $dsn, join('=', 'database', $name)) if $name;

	# The DSN should include a host if we had a host passed.
	$dsn = join(':', $dsn, join('=', 'host', $host)) if $host;

	# Pass back a database handler.
	my $dbh = DBI->connect($dsn, $user, $pass);

	# Pass back our database handler.
	return $dbh;
}

1;

__END__

=head1 NAME

Bibliopolis::DB::Factory - Database Connection Factory

=head1 SYNOPSIS

	use Bibliopolis::DB::Factory;

=head1 DESCRIPTION

Library.

=head1 AUTHOR

Tyler Bird, E<lt>birdty@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bibliopolis

=cut
