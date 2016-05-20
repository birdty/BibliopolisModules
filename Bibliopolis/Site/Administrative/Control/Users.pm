package Bibliopolis::Site::Administrative::Control::Users;

use base qw(Bibliopolis::Site::Administrative);

sub default
{
  my $self = shift;

  require Bibliopolis::Entity::User;

  my $login_cookie = $self->get_cookie('login');

  my @users = Bibliopolis::Entity::User->find_by(
     'account_id' => $login_cookie->get_property('account_id')
  );

  my $user = Bibliopolis::Entity::User->find_by(
    'username' => $login_cookie->get_property('username'),
    'account_id' => $login_cookie->get_property('account_id')
  );

  $self->view(
    $self->find_view(
      {
	'name' =>  'Users',
	'type' => $self->view_type(),
      }
    )
  );

  print $self->view->render({
      'method' => 'default',
      'users_aref' => \@users,
      'user' => $user
    }
  );
}

sub add_form
{
  my $self = shift;

  $self->view(
    $self->find_view({
	'name' =>  'Users',
	'type' => $self->view_type(),
      }
    )
  );

  print $self->view->render(
    {
      'method' => 'add_form',
    }
  );  

}

sub add
{
  my $self = shift;

  require Bibliopolis::Entity::User;

  Bibliopolis::Entity::User->create($self->parameters);

  print("Status: 302 Redirect\nLocation: /users\n\n");
}

sub edit_form
{
  my $self = shift;

  require Bibliopolis::Entity::User;

  if ( ! $self->parameters->{'id'} ) {
      $self->console->send_message("Invalid user");
      return;
  }

  my $user = Bibliopolis::Entity::User->find_by_id($self->parameters->{'id'});

  if ( ! $user )  {
    $self->console->send_message("Invalid User");
    return;
  }

  $self->view(
    $self->find_view({
	'name' =>  'Users',
	'type' => $self->view_type(),
      }
    )
  );

  print $self->view->render(
    {
      'method' => 'edit_form',
      'user' => $user
    }
  );  
}

sub save
{
  my $self = shift;

  require Bibliopolis::Entity::User;

  if ( ! $self->parameters->{'id'} )
  {
      $self->console->send_message("Invalid User");
      return;
  }

  my $user = Bibliopolis::Entity::User->find_by_id($self->parameters->{'id'});
  $user->set_non_id_properties_from_href($self->parameters);
  $user->save();

  print("Status: 302 Redirect\nLocation: /users\n\n");
}

sub allowed_actions
{
  return {'add_form' => 1, 'add' => 1, 'edit_form' => 1, 'save' => 1};
}

1;
