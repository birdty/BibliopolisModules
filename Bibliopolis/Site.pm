package Bibliopolis::Site;

sub new
{
  my($class, $args_href) = @_;

  my $object = bless {
      'parameters'	=> $args_href->{'parameters'},
      'console' 	=> $args_href->{'console'},
      'view_type'	=> $args_href->{'view_type'},
      'cookies'		=> $args_href->{'cookies_href'}
  }, $class;

  return $object;
}

sub cookies
{
  my $self = shift;
  return @_ ? $self->{'cookies'} = shift : $self->{'cookies'};
}

sub get_cookie
{
  my($self, $name) = @_;

  my $cookies = $self->cookies();

  if ( $cookies ) {

      require Bibliopolis::Site::Cookie;

      my $cookie_href = $cookies->{$name};

      my $cookie = Bibliopolis::Site::Cookie->new({'name' => $cookie_href->{'name'}, 'value' => $cookie_href->{'value'}});

      return $cookie;
  }
}

sub parameters
{
  my $self = shift;
  return @_ ? $self->{'parameters'} = shift : $self->{'parameters'};
}

sub console
{
  my $self = shift;
  return @_ ? $self->{'console'} = shift : $self->{'console'};
}

sub view_type
{
  my $self = shift;
  return @_ ? $self->{'view_type'} = shift : $self->{'view_type'};
}

sub error_encountered
{
  my $self = shift;
  return @_ ? $self->{'error_encountered'} = shift : $self->{'error_encountered'};
}

sub view
{
  my $self = shift;
  return @_ ? $self->{'view'} = shift : $self->{'view'};
}

sub parameter
{
  my ($self, $name) = @_;
  
  my $parameters = $self->parameters();

  if ( $parameters )
  {
    return $parameters->{$name};
  }

}

sub execute
{
    my ($self, $action) = @_;

    if ( $self->can($action) && $self->available($action) )
    {
      no strict 'refs';

      $self->$action;

      no strict 'refs';
    }
    else
    {
	$self->console->send_message("Request Denied");
    }
}

sub available
{
    return 0;
}

sub create_cookie
{
  my($self, %args) = @_;

  require Bibliopolis::Site::Cookie;

  # remove previous cookie if it exists and set new one.

  # todo: add expiration argument if needed by app requirements.
  # todo: add entity
  
  my $value;

  my $entity;

  my $delimeter = Bibliopolis::Site::Cookie->delimeter();

  if ( $args{'entity'} )
  {
      $entity = $args{'entity'};

      no strict 'refs';

      $value = join($delimeter, map { $_ . '=' . $entity->$_ } $entity->id_fields() );

      use strict 'refs';
  }
  else
  {
      $value = $args{'value'};
  }

  use CGI::Cookie;

  my $cookie;

  $cookie = CGI::Cookie->new(
	  -name   => $args{'name'},
	  -value  => ' ',
	  -expires => '-1M'
  );

  print("Set-Cookie: " . $cookie->as_string() . "\n");

  $cookie = CGI::Cookie->new(
    -name => $args{'name'},
    -value => $value,
    -expires => '+1M'
  );

  print("Set-Cookie: " . $cookie->as_string() . "\n");
}

sub send_content_type
{
  my($self, $ct) = @_;

  my $content_type;
  
  $content_type = $ct;

  if ( ! $content_type )
  {
      $content_type = 'text/html';
  }

  print("Content-type: $content_type\n\n");

}

1;