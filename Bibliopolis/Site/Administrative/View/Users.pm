package Bibliopolis::Site::Administrative::View::Users;

use base qw(Bibliopolis::Site::Administrative::View);

sub default
{
    my ($self, $args_href) = @_;

    my $shell = $self->find_shell('type' => 'html');

    # shell view should get data from
    # shell controller.
    
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
	$row =~ s{<<id>>}{$user->id()}eg;

	$rows .= $row;
    }

    $contents =~ s{<<rows>>}{$rows}g;

    if ( $contents )
    {	
      $shell->merge(
	  {
	    'contents'	=> $contents
	  }
      );
      return $shell;
    }
}

sub add_form
{
  my ($self, $args_href) = @_;

  my $shell = $self->find_shell('type' => 'html');

  my $contents = $self->read_template('users/add.tpl');

  if ( $contents )
  {	
    $shell->merge({'contents' => $contents});
    return $shell;
  }

}

sub edit_form
{
  my ($self, $args_href) = @_;

  my $shell = $self->find_shell('type' => 'html');

  my $contents = $self->read_template('users/edit.tpl');

  my $user = $args_href->{'user'};

  $self->merge_entity_attributes($user, \$contents);

  if ( $contents )
  {	
    $shell->merge({'contents' => $contents});
    return $shell;
  }
}

sub add
{
  my ($self, $args_href) = @_;

  require Bibliopolis::Utility::JSON;

  my $user = $args_href->{'user'};

  my $row_template = $self->read_template('users/row.tpl');
  
  my $row = $row_template;

  $row =~ s{<<id>>}{$user->id()}eg;
  $row =~ s{<<first_name>>}{$user->first_name()}eg;
  $row =~ s{<<last_name>>}{$user->last_name()}eg;
  $row =~ s{<<username>>}{$user->username()}eg;

  my $json = Bibliopolis::Utility::JSON->render(
      {
	'success' 	=> $args_href->{'success'},
	'user_id' 	=> $user->id(),
	'first_name'	=> $user->first_name(),
	'last_name'	=> $user->last_name(),
	'username'	=> $user->username(),
	'row'		=> $row
      }
  );

  return $json;
}

sub delete
{
  my ($self, $args_href) = @_;

  require Bibliopolis::Utility::JSON;

  my $json = Bibliopolis::Utility::JSON->render(
      {
	'success' => $args_href->{'success'},
      }
  );

  return $json;
}

1;