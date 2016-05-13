package Bibliopolis::Site::Administrative::View::Users;

use base qw(Bibliopolis::Site::Administrative::View);

sub default
{
    my $self = shift;

    my $shell = $self->find_shell('type' => 'html');

    my $contents = $self->read_template('users.tpl');

    if ( $contents )
    {	
      $shell->merge({'contents' => $contents});
      print $shell;
    }
}


1;
