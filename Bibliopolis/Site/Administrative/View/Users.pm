package Bibliopolis::Site::Administrative::View::Users;

use base qw(Bibliopolis::Site::Administrative::View);

sub default
{
    my ($self, $args_href) = @_;

    my $shell = $self->find_shell('type' => 'html');

    my $contents = $self->read_template('users.tpl');

    my $row_template = $self->read_template('users/row.tpl');
  
    my $row;

    my $rows;

    foreach my $user ( @{$args_href->{'users_aref'}} )
    {
	my $row = $row_template;
      
	$row =~ s{<<first_name>>}{$user->first_name()}eg;
	$row =~ s{<<last_name>>}{$user->last_name()}eg;
	$row =~ s{<<username>>}{$user->username()}eg;

	$rows .= $row;
    }

    $contents =~ s{<<rows>>}{$rows}g;

    if ( $contents )
    {	
      $shell->merge({'contents' => $contents});
      return $shell;
    }
}

1;
