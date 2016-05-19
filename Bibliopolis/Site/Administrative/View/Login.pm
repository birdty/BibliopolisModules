package Bibliopolis::Site::Administrative::View::Login;

use base qw(Bibliopolis::Site::Administrative::View);

sub login_form
{
    my ($self, $args_href) = @_;

    my $shell = $self->find_shell(
	'type' => 'html',
	'name' => 'login'
    );

    my $contents = $self->read_template('login_form.tpl');

    if ( $contents )
    {	
      $shell->merge({'contents' => $contents});
      return $shell;
    }
}


1;