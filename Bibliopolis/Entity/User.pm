package Bibliopolis::Entity::User;

use base qw(Bibliopolis::Entity);

sub _db_name { return 'bibliopolis'; }

sub _db_table_name { return 'user'; }

sub _db_table_id_column { return 'id'; }

sub _db_table_columns
{
  return qw(
    id                  
    account_id
    first_name          
    last_name
    email_address
    username
    password
  );
}

sub id_fields
{
    return qw(
      username
      account_id
    );
}

sub name
{
  my $self = shift;
  return $self->first_name() . " " . $self->last_name();
}

sub has_field_disabled { return 0; }

sub create
{
  my($class, $href) = @_;

  no strict 'refs';

  my $obj = $class->new();

  foreach my $attrib_name ( keys %$href )
  {
      my $value = $href->{$attrib_name};

      if ( $obj->attribute_exists($attrib_name) )
      {
	  $obj->$attrib_name($value);
      }
  }

  $obj->save();

  use strict 'refs';

  return $obj;
}



1;