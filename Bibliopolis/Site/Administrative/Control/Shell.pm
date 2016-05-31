package Bibliopolis::Site::Administrative::Control::Shell;

use base qw(Bibliopolis::Site::Administrative);

sub default
{
    my $self = shift;

    require Bibliopolis::Entity::User;

    my $login_cookie = $self->get_cookie('login');

    my $user = Bibliopolis::Entity::User->find_by(
      'username' => $login_cookie->get_property('username'),
      'account_id' => $login_cookie->get_property('account_id')
    );

    return {'name' => $user->name()};
}


1;
