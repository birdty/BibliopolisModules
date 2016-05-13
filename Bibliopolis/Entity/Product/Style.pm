package Bibiliopolis::Entity::Product::Style;

use base qw(Bibliopolis::Entity);

sub _db_name { return 'bibliopolis'; }

sub _db_table_name { return 'product_style'; }

sub _db_table_id_column { return 'id'; }

sub _db_table_columns
{
  return qw(
    id                  
    product_id
  );
}

sub has_field_disabled { return 0; }

1;