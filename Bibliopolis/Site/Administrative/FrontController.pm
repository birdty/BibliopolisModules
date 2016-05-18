package Bibliopolis::Site::Administrative::FrontController;

use Error qw(:try);

sub new
{
   my ($class, $args_href) = @_;
   return bless $args_href, $class;
}

sub request
{
  my $self = shift;
  return @_ ? $self->{'parameters'}->{'request'} = shift : $self->{'parameters'}->{'request'};
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

sub process_request
{
  my $self = shift;

  my $request = $self->request();
  
  $request =~ s/^\///g;

  my @parts;

  my $id;

  my @canidate_parts = split(/\//, $request);

  foreach my $part ( @canidate_parts )
  {
      if ( $part !~ /^([0-9]+)$/ )
      {
	  push(@parts, $part);
      }
      else
      {
	my $parameters = $self->parameters();
	$parameters->{'id'} = $1;
	$self->parameters($parameters);
      }
  }

  my $action;

  my $prefix = 'Bibliopolis::Site::Administrative::Control::';

  my $controller_class_name;

  $controller_class_name = $prefix . join('::', map { ucfirst($_) } @parts);

  my $loaded = eval("require $controller_class_name;");
  
  if ( $loaded )
  {
      $action = 'default';
  }
  elsif ( scalar(@parts) <= 1 )
  {
      $action = 'default';
  }
  else
  {
      $action = pop(@parts);
  }
 
  if ( $action )
  {
    $controller_class_name = $prefix;

    if ( scalar(@parts) == 0 ) 
    {
      $controller_class_name .= 'Index';
    }
    else
    {
	$controller_class_name .= join('::', map { ucfirst($_) } @parts);
    }
  
    no strict 'refs';

    $loaded = eval("require $controller_class_name;");

    if ( ! $loaded )
    {
	$self->console->send_message("Page Not Found or error in page.", $@);
	return;
    }	
 
    my $controller;

    try
    {

	require Bibliopolis::Site::Cookie;

	my $cookies_href;

	foreach my $cookie_string ( split(/; /, $ENV{HTTP_COOKIE} ) )
	{
		my ($key, $val) = split(/=/,$cookie_string);
		my $cookie = Bibliopolis::Site::Cookie->new({'name' => $key, 'value' => $value});
		$cookies_href->{$key} = $cookie;
	}

	if ( ! $cookies_href->{'login'} ) {
	  $self->console->send_message("You are not logged in.", $@);
	  return;  
	}

      $controller = $controller_class_name->new({
	'parameters'	=> $self->parameters(),
	'console'	=> $self->console(),
	'view_type' 	=> $self->{'view_type'},
	'cookies_href'	=> $cookies_href
      });

      use strict 'refs';

      $controller->execute($action);

    }
    catch Error with 
    {

	my $error = shift;

	use Data::Dumper;
      
	my $view = $controller->view();

	if (
		(
			$controller && 
			! $controller->error_encountered()
		) 
		||
		(
			$view && 
			! $view->error_encountered()
		)
	)
	{
		
	  $self->console->send_message("Error loading page " . $self->console(), Dumper(\$error));
	}
	elsif ( ! $controller )
	{
	  $self->console->send_message("Error in software system setup.", Dumper(\$error));
	}
    };

  }

}

1;
