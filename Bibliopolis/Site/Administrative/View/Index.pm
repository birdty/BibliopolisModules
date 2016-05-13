package Bibliopolis::Site::Administrative::View::Index;

use base qw(Bibliopolis::Site::Administrative::View);

sub default
{
    my $self = shift;

    use MIME::Types;

    my $mime_types = MIME::Types->new();
    my $html_type = $mime_types->type('text/html');

    print("Content-type: " . $html_type . "\n\n");

    my $shell = $self->find_shell('type' => 'html');

    my $contents = $self->read_template('index.tpl');

    $shell->merge({'contents' => $contents});

    print $shell;
}

1;
