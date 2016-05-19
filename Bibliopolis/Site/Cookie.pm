package Bibliopolis::Site::Cookie;

sub new
{
  my($class, $args_href) = @_;

  no strict 'refs';

  my $self = bless {}, $class;

  foreach my $property ( keys %$args_href )
  {
      my $value = $args_href->{$property};

      if ( $self->can($property) )
      {
	  $self->$property($value);
      }
  }

  use strict 'refs';

  return $self;

}

sub name
{
  my $self = shift;
  return @_ ? $self->{'name'} = shift : $self->{'name'};
}


sub value
{
  my $self = shift;
  return @_ ? $self->{'value'} = shift : $self->{'value'};
}

sub delimeter
{
  return '[%%]';
}

1;