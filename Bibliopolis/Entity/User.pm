package Bibiliopolis::Entity::User;

sub _db_name { return 'bibliopolis'; }

sub _db_table_name { return 'customer'; }

sub _db_table_id_column { return 'id'; }

sub _db_table_columns
{
  return qw(
    id                  
    first_name          
    last_name           
    username
    password
  );
}

sub has_field_disabled { return 0; }

1;