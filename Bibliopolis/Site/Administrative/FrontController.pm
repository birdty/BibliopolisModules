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

  @parts = split(/\//, $request);

  my $action;

  if ( scalar(@parts) <= 1 )
  {
      $action = 'default';
  }
  else
  {
      $action = pop(@parts);
  }
 
  if ( $action )
  {
    my $prefix = 'Bibliopolis::Site::Administrative::Control::';

    my $controller_class_name = $prefix;

    if ( scalar(@parts) == 0 ) 
    {
      $controller_class_name .= 'Index';
    }
    else
    {
	$controller_class_name .= join('::', map { ucfirst($_) } @parts);
    }

    no strict 'refs';

    my $loaded = eval("require $controller_class_name;");

    if ( ! $loaded )
    {
	$self->console->send_message("Page Not Found or error in page.", $@);
	return;
    }	
 
    my $controller;

    try
    {
      $controller = $controller_class_name->new({
	'parameters'	=> $self->parameters(),
	'console'	=> $self->console(),
	'view_type' 	=> $self->{'view_type'}
      });

      use strict 'refs';

      $controller->execute($action);

    }
    catch Error with 
    {

	my $error = shift;

	use Data::Dumper;
      
	if ( $controller && ! $controller->error_encountered() && ! $controller->view->error_encountered()  )
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
