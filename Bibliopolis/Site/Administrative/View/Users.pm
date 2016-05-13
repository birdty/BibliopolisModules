package Bibliopolis::Site::Administrative::View::Users;

use base qw(Bibliopolis::Site::Administrative::View);

sub default
{
    my $self = shift;

    use MIME::Types;

    my $mime_types = MIME::Types->new();
    my $html_type = $mime_types->type('text/html');

    print("Content-type: " . $html_type . "\n\n");

    my $shell = $self->find_shell('type' => 'html');

    $content = "hello";

    $shell->merge({'contents' => $content});

    print $shell;
}


1;
