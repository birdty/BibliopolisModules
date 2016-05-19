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

sub addform
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
      'method' => 'addform',
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

sub allowed_actions
{
  return {'addform' => 1, 'add' => 1};
}

1;
