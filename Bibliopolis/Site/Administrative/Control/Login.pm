package Bibliopolis::Site::Administrative::Control::Login;

use base qw(Bibliopolis::Site::Administrative);

sub login_form
{
  my $self = shift;

  $self->view(
    $self->find_view({
	'name' =>  'Login',
	'type' => $self->view_type(),
      }
    )
  );

  print $self->view->render(
    {
      'method' => 'login_form',
    }
  );
}

sub default
{
  my $self = shift;

  require Bibliopolis::Entity::User;

  my $user;

  $user = Bibliopolis::Entity::User->find_by(
    'username' => $self->parameters->{'username'},
    'password' => $self->parameters->{'password'}
  );

  if ( $user )
  {
    $self->create_cookie('name' => 'login', 'entity' => $user );
    print("Status: 302 Redirect\nLocation: /\n\n");
  }
  else
  {
    print("Status: 302 Redirect\nLocation: /\n\n");
  }

}

sub allowed_actions
{
  return {'login_form' => 1};
}

1;