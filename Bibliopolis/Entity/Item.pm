package Bibliopolis::Entity::Item;

use base qw(Bibliopolis::Entity);

sub _db_name { return 'bibliopolis'; }

sub _db_table_name { return 'item'; }

sub _db_table_id_column { return 'id'; }

sub _db_table_columns
{
  return qw(
    id                  
    account_id
    name
  );
}

sub has_field_disabled { return 0; }

1;