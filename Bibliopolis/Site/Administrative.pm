package Bibliopolis::Site::Administrative;

use strict;
use warnings;

use base qw(Bibliopolis::Site);

sub find_view
{
  my($self, $args_href) = @_;

  my $view_module_name = 'Bibliopolis::Site::Administrative::View::';

  $view_module_name .= $args_href->{'name'};

  my $retval = eval("require $view_module_name;");

  if ( $retval )
  {
      no strict 'refs';
      my $view = $view_module_name->new();
      use strict 'refs';

      return $view;
  }
  else
  {
     $self->console->send_message("Page template not found", "View Template not found: " . $view_module_name . $@);
     $self->error_encountered(1);
  }
}

sub available
{
  my ($self, $action) = @_;

  my $allowed_actions;

  if ( $self->can('allowed_actions') )
  {
    $allowed_actions = $self->allowed_actions();
  }

  $allowed_actions->{'default'} = 1;
  
  if ( $allowed_actions->{$action} )
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

1;
