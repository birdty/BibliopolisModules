package Bibliopolis::Site::Administrative::View;

sub new
{
  my($class, $args_href) = @_;

  my $object;

  if ( $args_href )
  {
      $object = $args_href;
  }
  else 
  {
      $object = {};
  }

  return bless $object, $class;
}

sub render
{
  my($self, $args_href) = @_;

  no strict 'refs';

  my $method = $args_href->{'method'};

  if ( $self->can($method) )
  {
    $self->$method;
  }

  use strict 'refs';
}

sub find_shell
{
  my ($self, %args) = @_;

  if ( $self->{'shell'} )
  {
      return $self->{'shell'};
  }
  else
  {
    require Bibliopolis::Site::Administrative::Shell;
    
    $self->{'shell'} = Bibliopolis::Site::Administrative::Shell->new({
	'name' => 'index',
	'type' => $args{'type'}
    });
    
    return $self->{'shell'};
  }
}


1;
