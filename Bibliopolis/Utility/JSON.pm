package Bibliopolis::Utility::JSON;

sub render
{
	my ($class, $scalar) = @_;

	use JSON;
	print("Content-type: application/json\n\n");
	my $json = JSON->new->allow_nonref;
	my $json_text = $json->encode($scalar);
	return $json_text;
}

1;
