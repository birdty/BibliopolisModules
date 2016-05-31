package Bibliopolis::Site::Administrative::Control::Index;

use base qw(Bibliopolis::Site::Administrative);

sub allowed_actions
{
  return {'login' => 1, 'logout' => 1};
}

sub default
{
  my $self = shift;

  $self->view(
      $self->find_view({
	 'name' => 'Index',
	 'type' => $self->view_type(),
    })
  );

  print $self->view->render({
	'method' => 'default',
      }
  );
}

sub logout
{
  my $self = shift;

  $self->remove_cookie('name' => 'login');

  print("Status: 302 Redirect\nLocation: /\n\n");

  return;
}

1;