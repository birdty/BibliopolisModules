package Bibliopolis::Lang;

use strict;
use warnings;

our $VERSION = '0.1';

#
#% Create a new Language object.
#
#< $Epromo::Lang=OBJECT { New language object. }
#
#\option method
#

sub new
{

	my $proto = shift;
	my $class = ref $proto ? ref($proto) : $proto;

	my $self = {};

	bless $self, $class;

	return $self;

}


#
#% Localize a value.
#
#* Examines $value to locate the appropriate string for the specified
#* language codes. Can be used on a scalar and will return the scalar
#* value (simple pass-thru).
#*
#* This method will append the defualt language code ( ->LANG() )
#* onto the end of the language list specified.
#
#> $value { Value to localize. }
#> @lang { Array of languages to use. }
#
#< $string { Localized string. }
#
#\option method
#

sub localize
{
	my ($self, $value, @lang) = @_;
	return $self->localize_pure($value, @lang, $self->LANG(), 'en_US');
}


#
#% Localize a value (pure).
#
#* Same as localize() except it does not append 'en_US' onto the
#* language codes list.
#
#> $value { Value to localize. }
#> @lang { Array of languages to use. }
#
#< $string { Localized string. }
#
#\option method
#

sub localize_pure
{

	my ($self, $value, @lang) = @_;

	# Escape early.
	return undef() unless defined $value;

	# In this case we are apparently not actually a hash.
	if ( ! ref $value ) { return $value; }

	# We must need to look for language strings.
	my $value_lang = undef();

	for my $lang ( @lang )
	{
		
		if ( defined $lang )
		{

			# Try to get the $lang value (override).
			$value_lang = $self->_localize(
				$value,
				$lang,
			);

			# Break now.
			return $value_lang if defined $value_lang;

		}

	}

	return undef();

}


#
#% Localize a string.
#
#* Wrapped method that handles breaking apart and actually testing
#* for values at given language codes.
#*
#* If language code 'en_US' is specified, the first key searched
#* for is 'en_US', and if not found, 'en' is searched for.
#
#\option method
#

sub _localize
{

	my ($self, $value, $lang) = @_;

	if ( exists $value->{$lang} ) { return $value->{$lang}; }

	my ($lang_prefix) = $lang =~ /^(\w+)_/;

	if ( defined $lang_prefix and exists $value->{$lang_prefix} )
	{
		return $value->{$lang_prefix};
	}

	return undef();

}

{

	my $LANG = undef();

	#
	#% What is our default entity language?
	#
	#> [$lang] { New language code. }
	#
	#< $lang { Current language code. }
	#
	#\option method
	sub LANG
	{

		my $class = shift;

		if ( @_ )
		{

			$LANG = shift;

		}

		if ( ! defined $LANG )
		{

			if ( exists $ENV{'LANG'} )
			{
				$LANG = $ENV{'LANG'};
			}
			else
			{
				$LANG = 'en_US';
			}

		}

		return $LANG;

	}

}

1;
__END__

=head1 NAME

Epromo::Lang - Lang module.

=head1 SYNOPSIS

	use Epromo::Lang;

=head1 DESCRIPTION

Library.

=head1 AUTHOR

Tyler Bird, E<lt>birdty@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bibliopolis

=cut
