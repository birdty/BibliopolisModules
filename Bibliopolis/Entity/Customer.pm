package Bibiliopolis::Entity::Customer;

use base qw(Bibliopolis::Entity);

sub _db_name { return 'bibliopolis'; }

sub _db_table_name { return 'customer'; }

sub _db_table_id_column { return 'id'; }

sub _db_table_columns
{
  return qw(
    id      
    account_id
    first_name          
    last_name           
    email_address       
    billing_address1    
    billing_address2    
    billing_city        
    billing_state       
    billing_postal_code 
    billing_phone       
  );
}

sub has_field_disabled { return 0; }

1;