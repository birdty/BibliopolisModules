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

  my @request_parts;

  my $id;

  my @canidate_parts = split(/\//, $request);

  foreach my $part ( @canidate_parts )
  {
      if ( $part !~ /^([0-9]+)$/ )
      {
	push(@request_parts, $part);
      }
      else
      {
	my $parameters = $self->parameters();
	$parameters->{'id'} = $1;
	$self->parameters($parameters);
      }
  }

  my $action;

  my $base_controller_class_name = 'Bibliopolis::Site::Administrative::Control';

  my $remaining_class_name = join('::', map { ucfirst($_) } @request_parts);
  
  my $controller_class_name = $base_controller_class_name . '::' . $remaining_class_name;

  my $loaded = eval("require $controller_class_name;");
  
  # algorithm here finds
  # the action for the url

  if ( $loaded )
  {
      # if url == full controller name then we accept the action as the default.
      $action = 'default';
  }
  else
  {
      # if url cannot be loaded we accept the action as the last part of the url.
      $action = pop(@request_parts);
  }

  # if parts in the url or if no action from url
  # we set action to default.

  if ( @request_parts == 0 && ! $action )
  {
      $action = 'default';
  }
  
 
  if ( $action )
  {
    $controller_class_name = $base_controller_class_name;

    if ( scalar(@request_parts) == 0 ) 
    {
      $controller_class_name .= '::Index';
    }
    else
    {
	$controller_class_name .=  '::' . join('::', map { ucfirst($_) } @request_parts);
    }

  #  print("[" . $controller_class_name . "]\n");
 #   print("[" . $action . "]\n");
  
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

      my %cookies = CGI::Cookie->fetch;

      foreach my $name ( keys %cookies )
      {
	      my $cgi_cookie = $cookies{$name};
	      my $cookie = Bibliopolis::Site::Cookie->new({'name' => $name, 'value' => $cgi_cookie->value()});
	      $cookies_href->{$name} = $cookie;
      }

      if (
	$remaining_class_name !~ /^Login$/  &&
	! $cookies_href->{'login'} 
      )
      {
	$controller_class_name = 'Bibliopolis::Site::Administrative::Control::Login';
	eval("require $controller_class_name;");
	$action = 'login_form';
      }

      $controller = $controller_class_name->new({
	'parameters'	=> $self->parameters(),
	'console'	=> $self->console(),
	'view_type' 	=> $self->{'view_type'},
	'cookies_href'	=> $cookies_href
      });

      use strict 'refs';

      require Bibliopolis::Site::Administrative::Control::Shell;

      my $shell_controller = Bibliopolis::Admininstrative::Control::Shell->new({
	'parameters'	=> $self->parameters(),
	'console'	=> $self->console(),
	'view_type' 	=> $self->{'view_type'},
	'cookies_href'	=> $cookies_href
      });

      $controller->shell_controller($shell_controller);

      $controller->execute($action);
    }
    catch Error with 
    {
	my $error = shift;

	use Data::Dumper;
      
	my $view;

	if ( $controller )
	{
	    $view = $controller->view();
	}

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
