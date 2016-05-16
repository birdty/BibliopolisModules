package Epromo::Buffer;

use strict;

use warnings;

our $VERSION = '0.1';

use overload ( '""' => 'as_string', );

#
#% Creates a new buffer.
#
#* Input values are passed directly to append() on the newly created
#* object. The following two examples result in the same exact state
#* of the Epromo::Buffer object once completed.
#*
#*   my $buffer_a = Epromo::Buffer->new(
#*     "Hello World!\n",
#*     "How are you?\n",
#*   );
#*
#*   my $buffer_b = Epromo::Buffer->new();
#*   $buffer_b->append( "Hello world!\n", 'How are you?\n", );
#
#> @strings { Concatenate the strings passed to start the buffer. }
#
#< $Epromo::Buffer=OBJECT { Buffer object. }
#
#\option constructor
#\see method append
#


sub new {

	my $proto = shift;
	my $class = ref $proto ? ref($proto) : $proto;

	my $self = {};

	# Bless early so we can use methods.
	bless $self, $class;

	# Blank our buffer.
	$self->buffer('');

	# Set our name if passed.
	if ( @_ ) { $self->append(@_); }

	# Pass ourself back.
	return $self;
	
}

#
#% Access to the actual string value.
#
#> $string { New string value. }
#
#< $string { String value. }
#
#\option method
#

sub buffer {

	my $self = shift;

	return @_ ?  $self->{$self->_buffer_key()} = shift : $self->{$self->_buffer_key()};
}

#
#% Returns the key used to contain the string buffer.
#
#\option method
#

sub _buffer_key { return '__bibliopolis_buffer__buffer'; }

#
#% Appends string(s) onto a buffer.
#
#* The input value(s) will be concatenated onto the end of the existing
#* buffer.
#*
#* The input value(s) can either be strings or can be any object that
#* has an as_string() method. The values are appended onto the buffer.
#*
#* Undefined values are handled gracefully (ignored) so no defined checking
#* needs to happen in the outside world.
#
#> @strings { Concatenate the strings passed to start the buffer. }
#
#\option method
#

sub append {

	my $self = shift;
		
	# All input we've read.
	my $input_all = '';

	for my $input ( @_ ) 
	{
		if ( defined $input ) 
		{
			if (
				ref $input and
				ref($input) =~ /::/ and
				$input->can('as_string')
			)
			{
				# Use as_string method to get the string value for
				# this reference.
				$input_all .= $input->as_string();
			}
			else 
			{
				$input_all .= $input;
			}
		}
	}

	if ( length($input_all) ) 
	{						
		if ( $self->buffer() )
		{
			$self->buffer($self->buffer() . $input_all);
		}
		else
		{
			$self->buffer($input_all);
		}
		
	}
}


#
#% Returns the string the buffer represents.
#
#* Read-only version of buffer().
#
#< $string
#
#\option method
#

	sub as_string {
		my $self = shift;
		return $self->buffer();
	}



#
#% Flushes the buffer.
#
#\option method
#

sub flush {
	my $self = shift;
	$self->buffer('');
}


1;

__END__

=head1 NAME

Epromo::Buffer - Buffer module.

=head1 SYNOPSIS

	use Epromo::Buffer;

=head1 DESCRIPTION

Library.

=head1 AUTHOR

Tyler Bird, E<lt>birdty@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bibliopolis

=cut
