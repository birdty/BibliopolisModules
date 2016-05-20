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

sub properties
{
  my $self = shift;
  return @_ ? $self->{'properties'} = shift : $self->{'properties'};
}

sub get_property
{
  my ($self, $name) = @_;
  
  my $properties;

  $properties = $self->properties();

  if ( ! $properties )
  {
    my $value = $self->value();

    my $delimeter = $self->delimeter();

    my @pairs = split(/$delimeter/, $value);

    foreach my $pair ( @pairs )
    {
	my($name, $value) = split(/=/, $pair);
	$properties->{$name} = $value;
    }

    $self->properties($properties);
  }

  return $properties->{$name};
}

sub delimeter
{
  return '%bibliopolis33%';
}

1;