package Bibliopolis::Site::Administrative::Control::Index;

use base qw(Bibliopolis::Site::Administrative);

sub allowed_actions
{
  return {'login' => 1};
}

sub default
{
  my $self = shift;

  my $view = $self->find_view({
	 'name' => 'Index',
	 'type' => $self->view_type(),
	 'bar' => '1'
  });

  $view->render({'method' => 'default'});
}

1;