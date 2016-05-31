package Bibliopolis::Site::Administrative::Shell;

use overload ('""' => 'render');

use IO::File;

sub new
{
  my($class, $args_href) = @_;

  my $object;

  if ( $args_href )
  {
      $object = $args_href;

      if ( $object->{'type'} eq 'html' )
      {
	my $filename = $args_href->{'name'} . ".shell";
	my $fh = IO::File->new($filename, "r");
	my $shell = join("", <$fh>);
	undef $fh;

	$object->{'title'} = 'Bibliopolis Administrative Site';
	$object->{'shell'} = $shell;

	return bless $object, $class;
      }
      elsif ( $object->{'type'} eq 'xml' )
      {
	  # instantiate specialized xml shell object.
      }
  }
  else
  {
      $object = {};
      return 
  }
}

sub render
{
  my $self = shift;
  
  $self->{'shell'} =~ s{<<title>>}{$self->{'title'}}g;

  if ( $self->{'type'} eq 'html' )
  {
    use MIME::Types;
    my $mime_types = MIME::Types->new();

    my $html_type = $mime_types->type('text/html');
    print("Content-type: " . $html_type . "\n\n");
  }

  my $shell_controller = $self->shell_controller();

  if ( $shell_controller )
  {
    my $params_href = $shell_controller->default();
  
    foreach my $param ( keys %$params_href )
    {
	my $value = $params_href->{$param};
	$self->{'shell'} =~ s{<<$param>>}{$value}g;
    }
  }

  return $self->{'shell'};
}

sub merge
{

  my($self, $args_href) = @_;
  
  foreach my $key ( keys %$args_href )
  {
      my $value = $args_href->{$key};
      $self->{'shell'} =~ s{<<$key>>}{$value}eg;
  }

}

1;
