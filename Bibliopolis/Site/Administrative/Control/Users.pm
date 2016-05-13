package Bibliopolis::Site::Administrative::Control::Users;

use base qw(Bibliopolis::Site::Administrative);

sub default
{
  my $self = shift;

  $self->view(
    $self->find_view({
	    'name' =>  'Users',
	    'type' => $self->view_type(),
	    'bar' => '1'
      }
    )
  );

  $self->view->render({'method' => 'default'});
}

1;
