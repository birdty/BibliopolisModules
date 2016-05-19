package Bibliopolis::Site::Administrative::View;

sub new
{
  my($class, $args_href) = @_;

  my $object;

  if ( $args_href )
  {
      $object = $args_href;
  }
  else 
  {
      $object = {};
  }

  return bless $object, $class;
}

sub console
{
  my $self = shift;
  return @_ ? $self->{'console'} = shift : $self->{'console'};
}

sub error_encountered
{
  my $self = shift;
  return @_ ? $self->{'error_encountered'} = shift : $self->{'error_encountered'};
}

sub render
{
  my($self, $args_href) = @_;

  no strict 'refs';

  my $method = $args_href->{'method'};

  if ( $self->can($method) )
  {
    if ( $args_href )
    {
      return $self->$method($args_href);
    }
    else
    {
      return $self->$method;
    }
  }

  use strict 'refs';
}

sub find_shell
{
  my ($self, %args) = @_;

  if ( $self->{'shell'} )
  {
      return $self->{'shell'};
  }
  else
  {
    require Bibliopolis::Site::Administrative::Shell;
 
	my $name;

	if ( $args{'name'} ) {
		$name = $args{'name'};
	}
	else
	{
		$name = 'index';
	}
   
    $self->{'shell'} = Bibliopolis::Site::Administrative::Shell->new({
	'name' => $name,
	'type' => $args{'type'}
    });
    
    return $self->{'shell'};
  }
}

sub read_template
{
  my ($self, $filename) = @_;

  my $full_filename_path = "templates/" . $filename;

  if ( ! -e $full_filename_path )
  {
    $self->console->send_message("Cannot find template for file: " . $filename);
    $self->error_encountered(1);
    return;
  }

  my $contents;

  my $fh = IO::File->new($full_filename_path, "r");
  
  my @lines = <$fh>;

  # space added to make contents defined to caller.
  $contents = ' ' . join('', @lines);

  return $contents;
}

1;
