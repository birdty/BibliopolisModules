#----------------------------------------------------------------------------
# Author: Tyler J. Bird
# Usage: use Epromo::Utility::Operators qw(instanceof) 
#----------------------------------------------------------------------------

package Epromo::Utility::Operators;

require Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw(instanceof contains require_dynamic is_numeric); 
use warnings;
use strict;
use Class::ISA;

sub instanceof
{
	my($class_name_to_match, $object) = @_;
	
	my $object_class_name = ref($object);

	if ( $class_name_to_match eq $object_class_name ) {
		return 1;
	}
	else {
	
		my @inheritence_heirarchy_class_names = Class::ISA::super_path($object_class_name);
	
		foreach my $class_name ( @inheritence_heirarchy_class_names ) {
			if ( $class_name_to_match eq $class_name ) {
				return 1;
			}
		}
	
		return 0;
	}
}

sub contains
{
	my ($object, @array) = @_;

	foreach my $object_in_array (@array) {
		
		if (ref $object_in_array &&
			$object_in_array->can('equals')) {
			
			return 1 if ($object_in_array->equals($object));	
		} else {
			return 1 if ($object_in_array eq $object);
		}
		
	}
	
	return 0;
}

sub require_dynamic
{
	my ($class_name, $extension) = @_;
	
	my $class_filename = $class_name;
		
	$class_filename =~ s/::/\//g;
	
	$extension = '.' . ($extension ? $extension : 'pm');
	
	$class_filename .= $extension;
	
	require $class_filename;
}

sub is_numeric
{
	my($scalar) = @_;
	
	if ( $scalar =~ /^[0-9]+/ ) {
		return 1;
	}
	else {
		return 0;
	}
}
