package Bibliopolis::Site::Administrative::View::Index;

use base qw(Bibliopolis::Site::Administrative::View);

sub default
{
    my $self = shift;

    my $shell = $self->find_shell('type' => 'html');

    my $contents = $self->read_template('index.tpl');

    if ( $contents )
    {	
      $shell->merge({'contents' => $contents});
      return $shell;
    }
}

1;
