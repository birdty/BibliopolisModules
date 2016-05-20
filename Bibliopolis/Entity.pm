package Bibliopolis::Entity;

use strict;
use warnings;

our $VERSION = '0.1';

require Bibliopolis::DB::StatementCache;
require Bibliopolis::Buffer;

use Error qw(:try);
use Bibliopolis::Utility::Operators qw(contains);

our $AUTOLOAD;

#
#% Default Constructor.
#
#* Accepts a hash argument consisting of the actual database
#* column names as specified by _db_table_columns().
#*
#* Can be called with no arguments at all for clean and safe
#* usage of any derived subclass of Epromo::Entity.
#*
#* Smart enough to accept 'id' key and determine the best thing
#* to do there -- otherwise, will accept the actual database ID
#* keys for all keys.
#
#> %args { Stuff and things. }
#
#\option constructor
#

sub new 
{
	my $proto = shift;

	my $class = ref $proto ? ref($proto) : $proto;

	my $self = {};
	
	bless $self, $class;

	my $first_param = $_[0];

	my %args;

	if ( $first_param )
	{
		%args = @_;
	}

	for my $key ( keys %args )
	{
		# Don't bother with undefined arguments.
		next unless defined $args{$key};

		if ( $key eq 'id' )
		{
			# Get all of the ID columns.
			my @key = $self->_db_table_id_column();

			# Get the values passed to us.
			my @value = ();
			
			if ( $self->multiple_field_primary_key() )
			{
				unless ( ref($args{$key}) eq 'ARRAY' )
				{
					# If we do not have an array ref here, then we are
					# probably doing something very wrong.
					throw Epromo::Entity::Exception -object => $self, -code => 'MULTIPLE_FIELD_PRIMARY_KEY';	
				}

				# Add all values to our values.
				push @value, @{ $args{$key} };
			}
			else {
				# Add the one value to our values.
				push @value, $args{$key};
			}
			
			while ( my $key_id = shift @key )
			{				
				# At this point, our keys and values should be in sync.
				# For each key, get a value and pass it through value_get_id().
				
				my $value = $self->value_get_id(shift @value);				
				$self->{$key_id} =  $value;
			}
		}
		else
		{
			# All other cases are handled pretty simply.
			# Pass the value through value_get_id().			
			$self->{$key} = $self->value_get_id($args{$key});
		}		
	}

	# Set the package name
	$self->entity_package_name($class);

	# have our specific database object initalize itself
	$self->initalize();
		
	# load our full entity
	$self->_db_data();
	
	return $self;
	
}

sub new_by_href
{
	my($class, $href) = @_;
	my $object = $class->new();
	$object->db_data_inject($href);
	return $object;
}

sub create_by_href
{
	my($class, $href) = @_;

	my $object = $class->new();
		
	foreach my $column_name ( $class->_db_table_columns() ) 
	{
		if ( $object->multiple_field_primary_key() || $object->non_incremental_primary_key() ) {
			$object->_access($column_name, $href->{$column_name});
		}
		else {
			if ( $column_name ne $class->_db_table_id_column() )
			{
				$object->_access($column_name, $href->{$column_name});
			}
		}
	}

	$object->save();

	return $object;
}

sub update_by_href
{
  my($class, $href) = @_;

  my $obj = $class->new();
  $obj->db_data_inject($href);
  $obj->save();
}

sub addslashes {
	my ($class, $text) = @_;

	$text =~ s/\\/\\\\/g;
	$text =~ s/'/\\'/g;
	$text =~ s/"/\\"/g;
	$text =~ s/\\0/\\\\0/g;
	$text =~ s/\\b/\\\\b/g;
	$text =~ s/\\n/\\\\n/g;
	$text =~ s/\\r/\\\\r/g;
	$text =~ s/\\t/\\\\t/g;
	$text =~ s/\\Z/\\\\Z/g;
	
	return $text;	
}


sub find_by_ids($$)
{
	my ($class, $ids_aref) = @_;

	my $ids = join(',', @{$ids_aref});

	my $sql_statement = "
		SELECT
			*
		FROM
			" . $class->_db_table_name() . "
		WHERE
			" . $class->_db_table_id_column() .  " IN ( $ids )
	";

	my $sth = $class->statement_cache->statement($sql_statement);

	$sth->execute();

	my @objects = ();

	while ( my $href = $sth->fetchrow_hashref ) {
		my $object = $class->new();
		$object->db_data_inject($href);
		push(@objects, $object);
	}

	return @objects;
}

#
#% Find entity by database ID.
#
#* Accepts a database ID to find an object that represents a database record.
#
#> $id_part_1, $id_part_2, etc { Database ID of record the object is to represent. comma seperate id if your id is a composite key e.g 1,2 }
#< $Epromo::Entity=OBJECT
#
#\option constructor
#

sub find_by_id
{
	my $class = shift;
	my @search_column_value_ids = @_;
	
	my @id_column_names = $class->_db_table_id_column();

	my %search_hash = ();

	for ( my $i = 0; $i < @id_column_names; $i++ ) {

		my $id_column_name 	= $id_column_names[$i];
		my $search_column_value = $search_column_value_ids[$i];

		$search_hash{$id_column_name} = $search_column_value;
	}

	my @search_array = %search_hash;

	return $class->new_by_search(@search_array);	
}

#
#% Constructor by database ID.
#
#* Accepts a database ID to make an object that represents a database
#* record.
#
#> $id { Database ID of record the object is to represent. }
#
#< $Epromo::Entity=OBJECT
#
#\option constructor
#

sub new_by_id 
{
	my $class = shift;
	return undef() unless @_;
	return $class->new( 'id' => shift, );
}

#
#% used to retrieve an extended entity
#* that is an entity joined with other columns in other tables
#
#

sub new_by_id_extended
{
	my $class = shift;
	return undef unless @_;
}

#
# purpose: provide a more meaningful method name on top of self.new_by_search()
#

sub find_by
{
	my $class = shift;
	return $class->new_by_search(@_);
}

#
# purpose: find by regular expression
# pass in column_names with regular expressions
# like so:
# 'column_name' => '.*?'
#

sub find_by_regex
{
	my $class = shift;
	
	my %columns = @_;
	
	foreach my $key (keys %columns) {
		
		$columns{$key} = 'REGEXP:' . $columns{$key};
	}
	
	return $class->new_by_search(%columns);
}

sub find_by_regexp
{
	my $class = shift;
	
	return $class->find_by_regex(@_);
}

#
#% Constructor by database search.
#
#* Accepts a hash argument consisting of the actual database
#* columns with match values. Returns a list of objects that
#* represent the rows matched by the search.
#
#> %args { Key/value pairs representing database columns and their associated values. }
#
#< @Epromo::Entity=OBJECT { Entities matching search criteria. }
#> %args { 'limit'=> Represents SQL LIMIT }
#> %args { 'offset'=> Represents SQL OFFSET }
#> %args { 'order_by'=> Represents SQL ORDER BY }
#> %args { 'desc'=> Represents SQL ORDER BY DESC }
#> %args { 'decrypt' => Represents field to decrypt (anonymous array) or single value }
#> %args { 'group_by' => Represents field to group_by (anonymous array) or single value }
#\option constructor
#

sub new_by_search
{
	my $class = shift;
	return $class->_by_search('new', @_);
}

#
#% checks the database for duplicate entries
#
#> %args { Key/value pairs representing the database columns and their associated values. }
#

sub exists
{
	my $class = shift;
	return $class->_by_search('count', @_);
}

#
#% finds all entities for a given entity
#

sub find_all
{
	my($class) = @_;
	return $class->new_by_search();
}

#
#% Constructor by database search.
#
#* Accepts a hash argument consisting of the actual database
#* columns with match values. Returns a list of objects that
#* represent the rows matched by the search.
#
#> %args { Key/value pairs representing database columns and their associated values. }
#
#< @Epromo::Entity=OBJECT { Entities matching search criteria. }
#
#\option constructor
#

sub count_by_search 
{
	my $class = shift;
	return $class->_by_search('count', @_);
}


sub _create_sql_equality
{
	my ($class, $column_name, $value, $should_encrypt) = @_;
	
	my $bind_var = "?";
	
	if ($should_encrypt) {
		$bind_var = $class->encrypt("?");
	}
	
	my $sql_equality = "";
	
	if ( ! $value ) {
		$sql_equality = " $column_name = $bind_var ";				
	} elsif ( $value =~ /^LIKE:/ ) {
		$sql_equality = " $column_name LIKE $bind_var ";
	} elsif ( $value =~ /^NOT:/ ) {
		$sql_equality = " $column_name != $bind_var ";
	} elsif ( $value =~ /^NOT LIKE:/ ) {
		$sql_equality = " $column_name NOT LIKE $bind_var ";
	} elsif ( $value =~ /^GTE:/ ) {
		$sql_equality = " $column_name >= $bind_var ";
	} elsif ( $value =~ /^GT:/ ) {
		$sql_equality = " $column_name > $bind_var ";
	} elsif ( $value =~ /^LTE:/ ) {
		$sql_equality = " $column_name <= $bind_var ";
	} elsif ( $value =~ /^LT:/ ) {
		$sql_equality = " $column_name < $bind_var ";
	} elsif ( $value =~ /^REGEXP:/ ) {
		$sql_equality = " $column_name REGEXP $bind_var";
	} else {
		$sql_equality = " $column_name = $bind_var ";				
	}
}

#
#% Constructor by database search.
#
#* Accepts a hash argument consisting of the actual database
#* columns with match values. Returns a list of objects that
#* represent the rows matched by the search.
#
#> %args { Key/value pairs representing database columns and their associated values. }
#
#< @Epromo::Entity=OBJECT { Entities matching search criteria. }
#
#\option constructor
#

sub _by_search 
{
	my ($class, $which, %args) = @_;
	
	my %column = ();
	
	for my $column ( $class->_db_table_columns() ) {
		
		next if ( $column =~ /^(created|created_by_user_id|updated|updated_by_user_id)$/ );
		
		if ( exists $args{$column} ) {
			$column{$column} = $args{$column};
		}
		
	}
	
	my @columns_to_decrypt = ();
	
	if ( defined $args{'decrypt'} ) {
		@columns_to_decrypt = ref $args{'decrypt'} eq 'ARRAY' ? 
			@{ $args{'decrypt'} } : ($args{'decrypt'});
	}
	
	my @columns_to_group_by = ();
	
	if ( defined $args{'group_by'} ) {
		@columns_to_group_by = ref $args{'group_by'} eq 'ARRAY' ? 
			@{ $args{'group_by'} } : ($args{'group_by'});
	}
	
	my %decrypted_columns;
	
	%decrypted_columns = map {$_ => '1'} @columns_to_decrypt;
	
	my $where = '';

	if ( keys %column ) {
		if ( $where ) { $where .= ' AND '; }
		
		my @values = ();
		
		foreach my $key ( sort { $a cmp $b } keys %column ) {
			my $should_encrypt = defined $decrypted_columns{$key};
			
			if ( ref $column{$key} eq 'ARRAY' ) {
				foreach my $key_value ( sort { $a cmp $b } @{$column{$key}} ) {
					push(@values, $class->_create_sql_equality($key, $key_value, $should_encrypt));
				}
			} else {
				push(@values, $class->_create_sql_equality($key, $column{$key}, $should_encrypt));
			}
		}
		
		$where .= join (' AND ', @values);
	}
	
	if ( ! $args{'include_disabled'} and $class->has_field_disabled() ) {
		if ( $where ) { $where .= ' AND '; }
		$where .= 'disabled = 0';
	}
	
	if ( defined $args{'where'} ) {
		$where = $args{'where'} . ( $where ? ' AND ' . $where : '' );
	}
	
	if ( $where ) { $where = ' WHERE ' . $where; }
	
	my $limiting_condition = '';
	
	if ( defined $args{'limit'} ) {
		$limiting_condition = " LIMIT " . $args{'limit'};
	}
	
	if ( defined $args{'limit'} and defined $args{'offset'} ) {
		$limiting_condition = " LIMIT $args{offset}, $args{limit}";
	}
	
	my $items;
	
	if ( $which eq 'count' ) {
		$items = " count(*) ";
	} else {
		# Removed lazy loading..
		#$items = join(', ', $class->_db_table_id_column());	
		
		# Added normal loading.
		# Reasoning: We only load at most 25 entities
		# at a time. Thus we won't crowd memory, and reduce 
		# network traffic due to setup time for 25 different queries.
		
		my @item_columns;

		@item_columns = $class->_db_table_columns();
		
		@item_columns = map(($decrypted_columns{$_} ? $class->decrypt($_) : $_), @item_columns);
		
		$items = join(', ', @item_columns);
	}
	
	my $ordering_condition = '';
	
	if ( exists $args{'order_by'} ) {
		$ordering_condition = "
			ORDER BY $args{order_by}
		";
		
		if ( exists $args{'desc'} ) {
			$ordering_condition .= ' DESC';
		}
	}
	
	my $group_by_condition = '';
	
	if (@columns_to_group_by) {
		$group_by_condition = '
			GROUP BY ' . join(', ', @columns_to_group_by) . '
		';
	}
	
	my $escaped_table_name = "`" . $class->_db_table_name() . "`";
	
	my $sql = Epromo::Buffer->new(
		'SELECT ', 
		$items,
		' FROM ',
		$class->_db_table_name(),
		$where,
		$group_by_condition,
		$ordering_condition,
		$limiting_condition,
	);

	# Get our prepared statement handler for this query.
	my $sth = $class->statement_cache->statement($sql);
	
	my @bind_vars = ();
	
	foreach my $key (sort { $a cmp $b } keys %column) {
		if (ref $column{$key} eq "ARRAY") {
			foreach my $key_value ( sort { $a cmp $b } @{$column{$key}} ) {
				$key_value =~ s/^LIKE://g;
				$key_value =~ s/^NOT://g;
				$key_value =~ s/^NOT LIKE://g;
				$key_value =~ s/^GTE://g;
				$key_value =~ s/^GT://g;
				$key_value =~ s/^LTE://g;
				$key_value =~ s/^LT://g;
				$key_value =~ s/^REGEXP://g;
				push(@bind_vars, $key_value);
			}
		} else {
			if ($column{$key}) {
				$column{$key} =~ s/^LIKE://g;
				$column{$key} =~ s/^NOT://g;
				$column{$key} =~ s/^NOT LIKE://g;
				$column{$key} =~ s/^GTE://g;
				$column{$key} =~ s/^GT://g;
				$column{$key} =~ s/^LTE://g;
				$column{$key} =~ s/^LT://g;
				$column{$key} =~ s/^REGEXP://g;
			}
			push(@bind_vars, $column{$key});
		}
	}

	# Execute
	my $rv = $sth->execute(@bind_vars) or throw Error("class; $class  $DBI::errstr $sql "); 
	
	my @result = ();
	
	# this is for the counting entities and pagination
	if ( $which eq 'count' ) {
		my ($count) = $sth->fetchrow();
		return $count;
	}
	
	while ( my $row_data = $sth->fetchrow_hashref() ) {
		

		my $entity = $class->new();
		
		# Put a list of all RESERVED words that need
		# to be escaped here.
		
		# You will also need to make sure that
		# your individual entity will have the column esacped
		# in the method _db_table_columns
		# with a function for the field. 
		
		# example ( place in your entity file )
		#
		#  sub _db_table_columns (
		# 	...
		# `interval`
		#
		# )
		
		#	sub interval
		#	{
		#		my $self = shift;
		#		return $self->_access('`interval`', @_);
		#	} 
		$row_data->{'`interval`'} = $row_data->{'interval'};	
		$row_data->{'`option`'} = $row_data->{'option'};
		$row_data->{'`from`'} = $row_data->{'from'};

		$entity->db_data_inject($row_data);
		
		push(@result, $entity);
		
		# Get a new object for each of these IDs.
		#push @result, $class->new_by_id( @id > 1 ? \@id : $id[0], );
	}
	
	return wantarray ? @result : $result[0];
}

#
#% Create a new database record.
#
#* Creates a new object and calls commit.
#*
#* On success, an object representing the new database record is returned.
#
#> @args { Arguments passed to new before commit. }
#
#< $object { Object representing the new database record. }
#
#\option constructor
#

sub create {
	my ($class, @args) = @_;
	my $record = $class->new(@args);
	if ( $record->commit(@args) ) { return $record; }
	else { return undef(); }
}


#
#% Disable a database record.
#
#* Disables entity in the database (disabled = 1) and cascades to
#* disable all entities that should be disabled when this particular
#* type of entity is disabled.
#
#> %args
#> $args{'force'} { Forces disable to happen and ignores checks if true. }
#
#\option method
#

sub disable
{
	my ($self, %args) = @_;

	if ( $args{'force'} or $self->disable_check(%args) ) 
	{
		# We want a clone so we don't mess up ourself.
		my $clone = $self->new_by_id($self->id());

		# Disable and commit the clone.
		$clone->disabled(1);
		$clone->commit(%args);

		# We are now disabled.
		$self->disabled(1);
	}
}

sub disable_check
{

	my ($self, %args) = @_;
	
	return 1;

}


#
#% Delete a database record.
#
#* Deletes entity in the database (DELETE FROM) and cascades to
#* delete all entities that should be deleted when this particular
#* type of entity is deleted.
#
#> %args
#> $args{'force'} { Forces delete to happen and ignores checks if true. }
#
#\option method
#

sub delete
{

	my ($self, %args) = @_;

	if ( $args{'force'} or $self->delete_check(%args) ) {

		my $sql = Epromo::Buffer->new(
			'DELETE FROM ',
			$self->_db_table_name(),
			' WHERE ',
			join(' AND ', map { $_ . ' = ?' } $self->_db_table_id_column()),
		);

		my $sth = $self->statement_cache->statement($sql);

		my $rv = $sth->execute(
			$self->multiple_field_primary_key() ?
				@{ $self->id() } :
				$self->id()
		) or warn(ref $self);

		return $rv;
	}

}

#
#% delete check
#
#* used to delete all child or related entities to this particular entity
#* return true and the framework will delete the parent entity, return
#* false and the parent entity will not be deleted
#

sub delete_check
{

	my ($self, %args) = @_;

	return 1;

}

# Name of the database to connect to.
#\option method
sub _db_name { return ''; }

# Name of the database table.
#\option method
sub _db_table_name { return ''; }

# Name of the table's ID column.
#\option method
sub _db_table_id_column { return ''; }

# Name of all columns in table.
#\option method
sub _db_table_columns { return ''; }

# Name of all optional field names obtained with joins
# on other tables for efficency
sub _db_table_joined_columns { return (); }

# Flush the data read from the database.
#\option method

sub _db_data_flush 
{
	my $self = shift;

	delete $self->{'_db_data_retrieved'};
	delete $self->{'_db_data'};
	delete $self->{'_db_data_found'};
	
}


# initalization
sub initalize {
	my $self = shift;
	
	# detect if multiple field primary key.
	my @id_columns = $self->_db_table_id_column();	
	my $number_id_columns = scalar(@id_columns);				
	if ( $number_id_columns > 1 ) { $self->multiple_field_primary_key(1); }
	else { $self->multiple_field_primary_key(0); }
	
}

#
#% Which class should represent our user?
#
#* Used for things like updated_by_user and created_by_user.
#
#< $class_name { Class name for "users." }
#

sub _user_class { return 'Epromo::Entity::User'; }


#
#% Get database data if needed.
#
#* Gets data from the database if data has not already been
#* retrieved from the database and we have an ID.
#
#\option method
#

sub _db_data {

	my $self = shift;
	
	if ( ! $self->{'_db_data_retrieved'} ) {
		
		# So we do not come here again.
		$self->{'_db_data_retrieved'} = 1;

		##
		## Only do the rest if we have no ID.
		##

		if ( $self->id() ) {
		
			$self->_load_db_data();
			
		}
		
	}
	
}


sub _load_db_data
{
	my($self) = @_;
		
	# Execute with our ID.
	my $db_data_sth = $self->_db_data_sth();
	
	my $rv = $db_data_sth->execute(
		$self->multiple_field_primary_key() ?
			@{ $self->id() } :
			$self->id()
	) or $self->entity_error("executing query failed: $!");
	
	# Get our row.
	my $row = $db_data_sth->fetchrow_hashref();										
	$self->db_data_inject($row);
	
}


#
#% Inject data into an entity.
#
#> $hashref { Data. }
#
#\option method
#

sub db_data_inject
{
	my ($self, $row) = @_;

	if ( $row ) 
	{
		# Remember the whole row.
		$self->{'_db_data'} = $row;

		# Remove our table ID.
		# TODO: I am not convinced this needs to be done.
		# delete $self->{$self->_db_table_id_column()};

		for my $key ( $self->_db_table_columns() ) 
		{			
			# Copy the database information into ourself unless
			# we already have something set for this value.
			$self->{$key} = $row->{$key} unless exists $self->{$key};
		}

		$self->{'_db_data_found'} = 1;
		
		# Database data is retrieved
		$self->_db_data_retrieved(1);
	}
	else {
		$self->{'_db_data_found'} = 0;
	}
}

#
#% Inject data into an entity object.
#
#* this will allow room for very fast joins
#* to restrict injecting to only columns that are 
#* actually in the corresponding table see $self->db_data_inject
#
#> $hashref { Data. }
#
#\option method
#

sub data_inject
{
	my ($self, $row) = @_;

	
	if ( $row ) 
	{
		# Remember the whole row.
		$self->{'_db_data'} = $row;

		# Remove our table ID.
		# TODO: I am not convinced this needs to be done.
		# delete $self->{$self->_db_table_id_column()};

		for my $key ( $self->_db_table_columns ) 
		{
			# Copy the database information into ourself unless
			# we already have something set for this value.
			$self->{$key} = $row->{$key} unless exists $self->{$key};
		}

		for my $key ( $self->_db_table_joined_columns )
		{
			# Copy the joined tables database information into ourself unless
			# we already have something set for this value.
			$self->{$key} = $row->{$key} unless exists $self->{$key};
		}

		$self->{'_db_data_found'} = 1;
	}
	else {
		$self->{'_db_data_found'} = 0;
	}
}

sub inject
{
	my($self, $href) = @_;

	my $id_column = $self->_db_table_id_column();

	foreach my $key ( keys %$href )
	{
		if ( $key ne $id_column ) 
		{
			$self->{$key} = $href->{$key};
		}
	}
}


#
#% Gets the ID based on input.
#
#* Gets the ID for the argument passed. If argument is a reference
#* that inherits from our package, it returns the value of the id()
#* method. Otherwise it returns the argument back unchanged assuming
#* that it must have been passed as an ID already.
#
#> $value { Either an object or an ID. }
#
#< $id { The ID associated with the input $value. }
#
#\option method
#

sub value_get_id {
	my ($class, @args) = @_;
	return
		( ref $args[0] and UNIVERSAL::isa($args[0], __PACKAGE__) ) ?
			$args[0]->id() : $args[0];
}


#
#% Gets an object for requested class based on input.
#
#* Gets an object for the requested class based on the 
#* class and argument passed. If argument is already an object
#* it will be returned directly. Otherwise it is assumed that
#* an ID was passed and new_by_id is called on the class with
#* the argument passed as the first argument.
#*
#* Uses UNIVERSAL::isa($args[0], __PACKAGE__) to determine if
#* the value passed ($args[0]) isa __PACKAGE__ (resolves to
#* the package of this file).
#
#> $requested_class { Class expected returned. }
#> $value { Either an object or an ID. }
#
#< $object { $object of class $requested_class }
#
#\option method
#

sub value_get_ref {
	my ($class, $requested_class, @args) = @_;
	if ( ref $args[0] and UNIVERSAL::isa($args[0], __PACKAGE__) ) {
		return $args[0];
	}
	$class->require_package($requested_class);
	return $requested_class->new_by_id($args[0]);
}


#
#% Generic accessor to encapsulate get/set for database column methods.
#
#* Wrapped code to set local values and retrieve data from the
#* database via _db_data() if it has not already been retrieved
#* (lazy loading).
#*
#* Uses value_get_id() on all sets so that in all cases, the value
#* input will be reduced to its ID if it is possible to reduce to
#* an ID.
#
#> $key { The database column being accessed. }
#> [$value] { If passed, the new value to be set for the specified $key. }
#
#< $value { The value associated with the specified $key. }
#

sub _access {
	my ($self, $key, @args) = @_;

	
	if ( @args ) {
		$self->{$key} = $self->value_get_id(@args);
	}
	else {
		$self->_db_data();		
	}	

 	return $self->{$key};
}

sub _get_virtual_field_key
{
	my $self = shift;
	
	my $key = shift;
	
	return "_virtual_field_" . $key;
}

sub _access_virtual_field {
	my $self = shift;
	
	my $key = shift;

	return @_ ? $self->{$self->_get_virtual_field_key($key)} = shift : $self->{$self->_get_virtual_field_key($key)};
}

sub virtual_property_exists
{
	my ($self, $property_name) = @_;

	return defined $self->{$self->_get_virtual_field_key($property_name)};
}

sub property_exists
{
	my($self, $property_name) = @_;

	if ( $property_name eq "DESTROY" ) {
		return 1;
	}

	my @db_table_column_names = $self->_db_table_columns();
	
	foreach my $db_table_column_name ( @db_table_column_names ) {
			
		if ( $db_table_column_name eq $property_name ) {
			return 1;
		}
	}

	return 0;	
}


#
#% Generic accessor to encapsulate get/set for database date 
#  datatype column methods.
#
#* Wrapped code to set local values and retrieve data from the
#* database via _db_data() if it has not already been retrieved
#* (lazy loading).
#*
#* Uses value_get_id() on all sets so that in all cases, the value
#* input will be reduced to its ID if it is possible to reduce to
#* an ID.
#
#> $key { The database column being accessed. }
#> [$value] { If passed, the new value to be set for the specified $key. }
#
#< $value { The value associated with the specified $key. }
#

sub _access_date 
{
	my ($self, $key, @args) = @_;

	my ($date) = @_;
		
	if ( @args ) { $self->{$key} = $self->value_get_id(@args); }
	else { $self->_db_data(); }
		
	# Process To/From Mysql Date Field
	require Bibliopolis::Date;

	if ( @args )
	{
		# Human Readable mm/dd/yy to SQL Date Type Conversion
		my $date = Epromo::Date->create($self->value_get_id(@args));
		my $machine_date = $date->formatted_date();
		$self->{$key} = $machine_date;		
	}	
	else
	{	
		if ( $self->{$key} )
		{	
			# SQL Date Type to Human Readable mm/dd/yy Conversion
			my $machine_date = $self->{$key};	
			
			if ( $machine_date eq '0000-00-00' )
			{
				$machine_date = 'now';				
			}
			
			my $date = Epromo::Date->create($machine_date);	
			my $human_date = $date->formatted_date_human();			
			return $human_date;
		}
		else
		{
			return undef();
		}
	}	
}

#
#% Generic accessor to encapsulate get/set for database datetime 
#  datatype column methods.
#
#* Wrapped code to set local values and retrieve data from the
#* database via _db_data() if it has not already been retrieved
#* (lazy loading).
#*
#* Uses value_get_id() on all sets so that in all cases, the value
#* input will be reduced to its ID if it is possible to reduce to
#* an ID.
#
#> $key { The database column being accessed. }
#> [$value] { If passed, the new value to be set for the specified $key. }
#
#< $value { The value associated with the specified $key. }
#

sub _access_datetime 
{
	my ($self, $key, @args) = @_;
			
	# Process To/From Mysql Date Field
	require Bibliopolis::Date;

	my $datetime = join(' ', @args);

	if ( @args )
	{
		# Human Readable mm/dd/yy to SQL Date Type Conversion
		my $date = Epromo::Date->create($datetime);
		my $machine_date = $date->formatted_datetime();				
		$self->{$key} = $machine_date;		
	}	
	else
	{	
	
		$self->_db_data();

		if ( $self->{$key} )
		{	
			# SQL Date Type to Human Readable mm/dd/yy Conversion
			my $machine_date = $self->{$key};				
			my $date = Epromo::Date->create($machine_date);	
			
			my $human_date = $date->formatted_datetime_human();									
			return $human_date;
		}
		else
		{
			return undef();
		}
	}	
}


#
#% Easy access to a Statement Cache object.
#
#* Returns an Epromo::DB::StatementCache object either for the database
#* local to the entity via _db_name() or for the database specified
#* as $name in the arguments.
#
#> [$name] { If passed, the database name. }
#
#< $Epromo::DB::StatementCache
#
#\option method
#

sub statement_cache 
{
	my $self = shift;
	return Bibliopolis::DB::StatementCache->new(@_ ? shift : $self->_db_name());
}


#
#% Access to the ID (primary key) that an object is identified by.
#
#* Access to the generic concept of the primary key for the data an
#* object represents.
#*
#* Every entity class has an id() method, even though the database
#* column for the ID may be called something else. Also, multiple
#* field primary key's are handled using the id() but are stored
#* as an array ref for simplicity.
#*
#*   $multi_field_pk_object->id([5, 3]);
#*   $single_field_pk_object->id(9);
#*
#*   $array_ref = $multi_field_pk_object->id();
#*   $string = $single_field_pk_object->id();
#
#> [$string|$array_ref] { New "ID". }
#
#< $string|$array_ref { Current "ID". }
#
#\option method
#

sub id {

	my $self = shift;

	if ( @_ ) 
	{
		my $value = shift;

		$self->_db_data_flush();

		if ( $self->multiple_field_primary_key() )
		{

			unless ( ref($value) eq 'ARRAY' )
			{
				# If we do not have an array ref here, then we are
				# probably doing something very wrong.
				throw Epromo::Entity::Exception
					-object => $self,
					-code => 'MULTIPLE_FIELD_PRIMARY_KEY';
			}


			for my $column ( $self->_db_table_id_column() )
			{
				$self->{$column} = shift @{ $value };
			}

		}
		else
		{
			$self->{$self->_db_table_id_column()} = $value;
		}
	}

	return $self->multiple_field_primary_key() ?
		[ map { $self->{'_db_data'}->{$_} } $self->_db_table_id_column() ] :
		$self->{$self->_db_table_id_column()};
		
}

sub disabled {
	my $self = shift;
	return $self->_access('disabled', @_);
}

sub created {
	my $self = shift;
	return $self->_access('created', @_);
}

sub created_by_user_id {
	my $self = shift;
	return $self->_access('created_by_user_id', @_);
}

sub created_by_user {
	my $self = shift;
  my $user_class = $self->_user_class();
  $self->require_package($user_class);
	return $user_class->new_by_id($self->created_by_user_id(@_));
}

sub updated {
	my $self = shift;
	return $self->_access('updated', @_);
}

sub updated_by_user_id {
	my $self = shift;
	return $self->_access('updated_by_user_id', @_);
}

sub updated_by_user {
	my $self = shift;
  my $user_class = $self->_user_class();
  $self->require_package($user_class);
	return $user_class->new_by_id($self->updated_by_user_id(@_));
}

sub flush {

	my $self = shift;

	$self->_db_data_flush();

	my $id = [$self->_db_table_id_column()];

	for my $column ( $self->_db_table_columns() )
	{

		delete $self->{$column}
			unless grep { $column eq $_ } @{ $id };

	}

}

# Called before any comitting is actually done.
sub commit_sanity_any {
	my ($self, $columns_to_update, %args) = @_;
	return 1;
}

# Called before committing an update.
sub commit_sanity_update {
	my ($self, $columns_to_update, %args) = @_;
	return 1;
}

# Called before committing an insert.
sub commit_sanity_insert {
	my ($self, $columns_to_update, %args) = @_;
	return 1;
}

# Called after any comitting is done.
sub commit_post_any {
	my ($self, $columns_to_update, %args) = @_;
	return 1;
}

# Called after an update.
sub commit_post_update {
	my ($self, $columns_to_update, %args) = @_;
	return 1;
}

# Called after an insert.
sub commit_post_insert {
	my ($self, $columns_to_update, %args) = @_;
	return 1;
}


#
#% Commit entity to the database.
#
#* Commit changes to the database for the record that the object
#* represents. If no ID is set, it is assumed that this object
#* represents a record that needs to be created in the database.
#
#< $updated { flag that says a the corresponding database record was updated }
#
#> %args { 'encrypt' => Represents field to encrypt (anonymous array) }
sub commit 
{
	my ($self, %args) = @_;

	# If we have an ID we are not creating a new record.
	my $creating_new_record = $self->id() ? 0 : 1;

	# Get our information from the database.
	$self->_db_data();
	
	if (
		! $self->{'_db_data_found'} and
		( $self->multiple_field_primary_key() )
	)
	{
		# We are going to go out on a limb here and assume that
		# we are a multiple field primary key class that has
		# an object that needs to be created.
		# TODO: This is very dirty. Fix it? Leave it? Document it?
		$creating_new_record = 1;
	}
	elsif ( 
		! $self->{'_db_data_found'} and
		( $self->non_incremental_primary_key() )
	)
	{
		# We are assuming that the entity has a primary key, but it
		# does not auto increment
	
		$creating_new_record = 1;
	}
	
	
	# Which columns have we requested be updated? If 'columns'
	# was passed as an arg, the caller has specified specific
	# columns to be updated. Otherwise they requested no columns.
	my @columns_requested = exists $args{'columns'} ?  @{ $args{'columns'} } : ();

	# A good place to store the columns that look to have been
	# changed and are in need of an update.
	my @columns_to_update;

	# If anything was requested from the caller, we should only
	# check the those columns to see if they should be updated.
	# Otherwise, we should get the keys from our entire table.
	my @columns_to_check =
		@columns_requested ?
			@columns_requested :
			$self->_db_table_columns();

	for my $column ( sort { $a cmp $b } @columns_to_check ) 
	{
		unless ( $self->multiple_field_primary_key() or $self->non_incremental_primary_key() )
		{
			# We do not want to update the column ID(s) unless we are
			# a field that has multiple primary keys.or a non incremental
			# primary key
			next if grep { $column eq $_ } $self->_db_table_id_column();
		}

		# We do not want to update the "usually always there" columns ever.
		if (
			$column =~
				/^(created|created_by_user_id|updated|updated_by_user_id)$/
		) { next; }

		unless (

                        (
                                # Both are set and they are the same.
                                $self->{$column} and
                                $self->{'_db_data'}->{$column} and
                                $self->{$column} eq $self->{'_db_data'}->{$column}

                        ) or (

                                # Neither are set.
                                ! $self->{$column} and ! $self->{'_db_data'}->{$column}
                        )
		

		)
		 {

			# This column should be updated.
			push @columns_to_update, $column;
		}
	}
	

	if ( @columns_to_update or $creating_new_record )
	{
		# Get the values for this record.
		my @values = map { $self->{$_} } @columns_to_update;
		
		my $c = 0;
		foreach (@values) {
			if ($_ =~ /^SQL:(.*)$/) {
				push @columns_to_update, 'NOBIND:' . $columns_to_update[$c] . ':' . $1;
				splice @values, $c, 1;
				splice @columns_to_update, $c, 1;
			}
			$c++;
		}
		
		if ( $creating_new_record ) 
		{
			if ( $args{'au'} ) 
			{
				if ( grep { $_ eq 'created_by_user_id' } $self->_db_table_columns() ) 
				{
					push @values, $args{'au'};
					push @columns_to_update, 'created_by_user_id';
				}
			}

			if ( grep { $_ eq 'created' } $self->_db_table_columns() ) 
			{
				push @columns_to_update, 'NOBIND:created:NOW()';
			}
		}

		if ( grep { $_ eq 'updated_by_user_id' } $self->_db_table_columns() ) 
		{
			if ( $args{'au'} ) 
			{
				push @values, $args{'au'};
				push @columns_to_update, 'updated_by_user_id';
			}
		}

		# The statement is dynamic.
		my $sth = undef();

		{

			# Do sanity checks on our data for any actions (insert or update).
			my $rv = $self->commit_sanity_any(\@columns_to_update, %args);

			# Back out now if we are not considered sane.
			return $rv unless $rv;

		}
		
		if ( $creating_new_record ) 
		{

			# Do sanity checks on our data for insert.
			my $rv = $self->commit_sanity_insert(\@columns_to_update, %args);

			# Back out now if we are not considered sane.
			return $rv unless $rv;

		}
		else 
		{

			# Do sanity checks on our data for update.
			my $rv = $self->commit_sanity_update(\@columns_to_update, %args);

			# Back out now if we are not considered sane.
			return $rv unless $rv;

		}
		
		my @columns_to_encrypt = @{ $args{'encrypt'} } if ($args{'encrypt'});

		if ( $creating_new_record ) 
		{
			# Get a statement for an insert with these columns.
			$sth = $self->_commit_insert_sth(\@columns_to_encrypt, @columns_to_update);
			
			# Execute our statement.
			my $rv = $sth->execute( @values ) or die(" error in insert: " . $self->entity_error("error in insert $DBI::errstr") );



		}
		else 
		{
			# Get a statement for an update with these columns.
			$sth = $self->_commit_update_sth(\@columns_to_encrypt, @columns_to_update);

			# Update needs to know our ID.

			if ( $self->non_incremental_primary_key() && $self->{'_db_data'}->{$self->_db_table_id_column} )
			{
				push(@values, $self->{'_db_data'}->{$self->_db_table_id_column()});
			}
			else
			{
				push @values,
					$self->multiple_field_primary_key() ?
						@{ $self->id() } :
						$self->id();
			}

			# Execute our statement.
			my $rv = $sth->execute( @values ) or die("error in update: " . $self->entity_error("error in update"));
		}

		if ( $creating_new_record ) 
		{ 
			if ( ! $self->multiple_field_primary_key() && ! $self->non_incremental_primary_key())
			{
				# If we created a new record, we should set our ID to the
				# ID of the last row inserted.
				$self->id($self->_commit_last_insertid());
			}
			elsif ( $self->multiple_field_primary_key() && $self->_has_auto_increment_key() )
			{
				# If the table has a auto increment key field and
				# this table is a multiple field primary key
				
				# intialize the part of the primary key that is auto_increment
				# with the value returned from the database
				my $auto_increment_key = $self->_auto_increment_key();
				
				$self->{$auto_increment_key} = $self->_commit_last_insertid();
			}

			$self->{'_db_data_found'} = 1;
		}

		for my $column (

			# Standard columns to update.
			@columns_to_update,

			# If we created a new record, we also want to include
			# our table ID.
			$creating_new_record ? $self->_db_table_id_column() : ()
		)
		{

			# Force the db info to look like the value's we just
			# set so we do not need to do another update.
			$self->{'_db_data'}->{$column} = $self->{$column};

		}

		{
			# Do post routines for any action.
			my $rv = $self->commit_post_any(\@columns_to_update, %args);

			if ( $creating_new_record ) 
			{
				# Do post routines for insert action.
				$rv = $self->commit_post_insert(\@columns_to_update, %args);
			}
			else 
			{
				# Do post routines for update action.
				$rv = $self->commit_post_update(\@columns_to_update, %args);
			}
			
			return $rv;
		}
		
	}
	elsif ( $creating_new_record ) 
	{
		# TODO: Exceptions.
		return undef();
	}

	return 0;
}

sub save {
	my $self = shift;
	return $self->commit(@_);
}

sub _commit_prep {

	my ($self, $action, $encrypt_col_aref, @columns) = @_;
	

	my @columns_to_encrypt = @$encrypt_col_aref;
	
	my %encrypted_columns = map {$_ => 1} @columns_to_encrypt;

	# Create a new buffer for our SQL.
	my $sql = Epromo::Buffer->new();

	# Start out the statement.
	if ( $action eq 'update' ) 
	{
		$sql->append('UPDATE ');
	}
	else
	{
    	my @insert = ();
    
    	push @insert, 'INSERT';
    
    	if ( $self->_insert_ignore() )
    	{
    	  # We do not want errors.
    	  push @insert, 'IGNORE';
    	}
    
    	push @insert, 'INTO', '';

    	$sql->append( join(' ', @insert) );
  	}

	# Include the table name.	
	$sql->append( $self->_db_table_name(), ' ' );
	
	if ( @columns ) 
	{
		# If we have columns (we should always have columns for update)
		# we should include the set = ? for each column.
		$sql->append(
			'SET ',
			join(
				', ',
				map
				{
					( $_ =~ /^NOBIND:(.+?):(.+?)$/ ) ?
					( $encrypted_columns{$_} ? $1 . ' = ' . $self->encrypt($2) : $1 . ' = ' . $2 ) :
					( $encrypted_columns{$_} ? $_ . ' = ' . $self->encrypt('?') : $_ . ' = ? ' )
				}
				@columns
			),			' ',
		);
	}
	else 
	{
		# Probably an insert with now values.
		$sql->append('VALUES () ');
	}

	if ( $action eq 'update' ) {
		$sql->append(
			'WHERE ',
			join(' AND ', map { $_ . ' = ?' } $self->_db_table_id_column()),
		);
	}
	
	my $sth = undef();
	
	try 
	{
		# Create the statement handler for our newly generated SQL.
		$sth = $self->statement_cache->statement($sql->buffer());
	}
	catch Error with {
		my $e = shift;
		throw Epromo::Entity::Exception
			-object => $self,
			-code => 'DATABASE_COMMIT';
	};

	return $sth;

}

# Wrapper to _commit_prep.
sub _commit_update_sth {
	my ($self, $encrypt_col_aref, @columns) = @_;
	return $self->_commit_prep('update', $encrypt_col_aref, @columns);
}

# Wrapper to _commit_prep.
sub _commit_insert_sth {
	my ($self, $encrypt_col_aref, @columns) = @_;
	return $self->_commit_prep('insert', $encrypt_col_aref, @columns);
}

sub _commit_last_insertid {

	my $self = shift;

	# Get the last insertid for our cache's database.
	return $self->statement_cache->last_insertid();

}

sub _db_data_sth {

	my $self = shift;

	my %encrypted_columns = $self->_db_column_encrypted();
		
	my $sql = join(
		' ',
		'SELECT ' ,
		join(', ', map { $encrypted_columns{$_} ? $self->decrypt($_) : $_ } $self->_db_table_columns() ),
		' FROM ',
		$self->_db_table_name(),
		'WHERE',
		join(' AND ', map { $_ . ' = ?' } $self->_db_table_id_column()),
	);
		
	my $sth = undef();

	try {

		# Create the statement associated with this key.
		$sth = $self->statement_cache->statement($sql);

	}
	catch Error with 
	{
		my $e = shift;
		
		$self->entity_error("This is my SQL: $sql ... this was the caught exception: $e ...");
		
		#throw Epromo::Entity::Exception
		#	-object => $self,
		#	-code => 'DATABASE_DATA';
			
	};
				
	return $sth;
}

#
#% ID list for child entities.
#
#* ID list for children entities who refer to the entity that we
#* represent.
#
#> $child_class { Class name of children. }
#> [%args] { Optional arguments. }
#> $args{'parent_table_id_column'} { ID column for parent table. }
#> $args{'parent_table_id_method'} { Method called to return ID for parent. }
#> $args{'child_table_id_column'} { ID column for child table. }
#> $args{'child_table_name'} { Name of child table. }
#
#< @id { Children entity IDs. }
#
#\option method
#

sub children_id
{
	my ($self, $child_class, %args) = @_;

	my $sth = $self->_children($child_class, %args);

	my @child_id = ();

	while ( my (@id) = $sth->fetchrow() ) {
		push @child_id, @id > 1 ? \@id : @id;
	}

	return wantarray ? @child_id : $child_id[0];
}

#
#% Object list for child entities.
#
#* Wrapper to map { $child_class->new_by_id($_) } over children_id()
#* results.
#
#> $child_class { Class name of children. }
#> [%args] { Optional arguments. See children_id() for argument options. }
#
#< @Epromo::Entity=OBJECT { Children entity objects. }
#
#\option method
#

sub children
{
	my ($self, $child_class, %args) = @_;

	my $sth = $self->_children($child_class, %args);

	my @children = ();

	while ( my $row = $sth->fetchrow_hashref() ) {
		my $entity = $child_class->new();
		$entity->db_data_inject($row);
		push(@children, $entity);
	}

	return wantarray ? @children : $children[0];

}


#
#% _children
#
#* a generic method called by self->children_id and $self->children()
#* this allows both of the mentioned methods to deliever entity id's
#* in an array or entity objects
#
#< $sth { statment handle }
#
#\option private
#

sub _children
{
	my ($self, $child_class, %args) = @_;

	$self->require_package($child_class);

	# Because this would not get us very far otherwise.
	return () unless $child_class;

	# If we are looking for children, then we must be the parent.
	# Force the results into an anonymous array reference.
	$args{'parent_table_id_column'} = [$self->_db_table_id_column()]
		unless exists $args{'parent_table_id_column'};

	# Provide override support for the parent's ID method (just in case).
	my $parent_table_id_method =
		exists $args{'parent_table_id_method'} ?
			$args{'parent_table_id_method'} :
			'id';

	# Provide override support for the child's ID column (just in case).
	# Force the results into an anonymous array reference.
	$args{'child_table_id_column'} = [$child_class->_db_table_id_column()]
		unless exists $args{'child_table_id_column'};

	# Provide override support for the child's table name (just in case).
	$args{'child_table_name'} = $child_class->_db_table_name()
		unless exists $args{'child_table_name'};

	for my $arg ( qw(parent_table_id_column child_table_id_column) )
	{
		# Make these keys array refs if they are not already array
		# refs.
		$args{$arg} = [$args{$arg}]
			unless ref $args{$arg};
	}

	my $sql = Epromo::Buffer->new(
		'SELECT * ',
		' FROM ',
		$args{'child_table_name'},
		' WHERE ',
		join(' AND ', map { $_ . ' = ?' } @{ $args{'parent_table_id_column'} }),
	);


	if ( ! $args{'include_disabled'} and $child_class->has_field_disabled() ) {
		$sql->append(
			' AND ',
			join('.', $args{'child_table_name'}, 'disabled'),
			' = 0 ',
		);
	}
		
	# Join conditionally onto the child entities
	my %child_join_conditions = $args{'child_join_conditions'} if $args{'child_join_conditions'};
		
	if ( %child_join_conditions )
	{
		foreach my $child_join_condition ( keys %child_join_conditions )
		{
			$sql->append(
				' AND ',
				join (' = ', $child_join_condition, ' ? ' ) 
			);
		}
	}
		
	# Get a prepared statement handler for this SQL.
	my $sth = $self->statement_cache($child_class->_db_name())->statement($sql);
	
	# Build our child join condition values
	my @bind_parameter_values = ();
	
	# put in values for our parent table id column
	push @bind_parameter_values, 
			$self->multiple_field_primary_key() ? 
				@{ $self->$parent_table_id_method() } : $self->$parent_table_id_method();
	
	# Now put in values for our child table
	if ( %child_join_conditions )
	{
		foreach my $child_join_condition_value ( values %child_join_conditions )
		{
			push( @bind_parameter_values, $child_join_condition_value );	
		}
	}
	
	# Execute our query using our parent table ID	
	my $rv = $sth->execute(@bind_parameter_values);
	
	return $sth;
}

#
#% Pass through method to catch usage on legacy methods.
#
#* Useful for testing if a legacy method is being used. It returns
#* the reference to self so methods can be chained.
#*
#*   sub legacy_method
#*   {
#*     my $self = shift;
#*     $self->legacy->new_method( @_, );
#*   }
#*
#* Provided legacy_warn() returns true, any time that the
#* deprecated legacy_method() is called, a warning would be thrown
#* and the actual new_method() would be called.
#
#< $self { Object the method was called on. }
#
#\option method
#

sub legacy {
	my ($self) = @_;
	if ( $self->legacy_warn() ) {
#		warn($self->_warn_message('legacy', caller(1)));
	}
	return $self;
}


#
#% Is legacy warning enabled for this class?
#
#< $bool { Enabled? }
#
#\option method
#

sub legacy_warn { return 0; }


#
#% Pass through method to catch usage on methods.
#
#* Useful for testing if a method is being used. It returns
#* the reference to self so methods can be chained.
#*
#*   sub deprecated_method
#*   {
#*     my $self = shift;
#*     $self->usage_check->new_method( @_, );
#*   }
#*
#* Provided usage_check_warn() returns true, any time
#* that deprecated_method() is called, a warning would
#* be thrown and the actual new_method() would be called.
#
#< $self { Object the method was called on. }
#
#\option method
#

sub usage_check {
	my ($self) = @_;
	if ( $self->usage_check_warn() ) {
	#	warn($self->_warn_message('usage_check', caller(1)));
	}
	return $self;
}


#
#% Is usage check enabled for this class?
#
#< $bool { Enabled? }
#
#\option method
#

sub usage_check_warn { return 0; }

sub _warn_message {
	my $self = shift;
	my ($type, $package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = @_;
	return "$type: $subroutine was called in $filename:$package at line $line\n";
}


#
#% Dynamically requires a package.
#
#* Encapsulate the process of doing a quick eval on a package
#* by filename.
#
#> $class { Class whose package needs to be loaded. }
#

sub require_package
{
	my ($self, $class) = @_;
	my $package_filename =
		join('.', join('/', (split /::/, $class)), 'pm');
	eval { require $package_filename; };
}


#
#% Do we have a multiple field primary key?
#
#* Return true if a specific entity has a mutiple field
#* primary key.
#
#< $bool { Multiple field primary key? }
#
#\option method
#

sub multiple_field_primary_key { 
	my $self = shift;	
	return @_ ? $self->{'_multiple_field_primary_key'} = shift : $self->{'_multiple_field_primary_key'};
}

#
#% Do we have a auto incrementing key on a multple field primary key table
#
#
#< $bool { Auto increment field on multiple field primary key table ? }
#

sub _has_auto_increment_key { return 0; }

#
#% Auto incrementing key on a multiple field primary key table
#
#
#< $field { Auto incrementing key on a multiple field primary key table }
#

sub _auto_increment_key { }

#
#% Do we have a non incrmental primary field primary key?
#
#* Return true if a specific entity has a non incremental primary key field
#
#< $bool { Multiple field primary key? }
#
#\option method
#

sub non_incremental_primary_key { return 0; }


#
#% Do we have a disabled field?
#
#< $bool { Do we have a disabled field? }
#
#\option method
#

sub has_field_disabled { return 1; }


#
#% Do we have a created field?
#
#< $bool { Do we have a created field? }
#
#\option method
#

sub has_field_created { return 1; }


#
#% Do we have a created by user ID field?
#
#< $bool { Do we have a created by user ID field? }
#
#\option method
#

sub has_field_created_by_user_id { return 1; }


#
#% Do we have an updated field?
#
#< $bool { Do we have an updated field? }
#
#\option method
#

sub has_field_updated { return 1; }


#
#% Do we have an updated by user ID field?
#
#< $bool { Do we have an updated by user ID field? }
#
#\option method
#

sub has_field_updated_by_user_id { return 1; }


#
#% Ignore errors on insert?
#
#* For lazy/sloppy programming. Way faster than actually
#* doing the check using the software. Just insert and
#* hope for the best...
#
#< $bool { Ignore errors on insert? }
#

sub _insert_ignore { return 0; }


#
#% Define methods.
#
#< %hash { Method definitions. }
#
#\option method
#

sub _method_definitions { return {}; }


#
#% Inspect an entity.
#
#* Recursive search through method definitions to locate information
#* about an entity.
#*
#*   $required = $object->entity_inspect('username', 'required');
#*
#*   $required = $method_definitions{'username'}->{'required'};
#*
#* Will go as deep as needed.
#
#> @keys { Key path to inspect. }
#
#\option method
#

sub entity_inspect
{

	my ($self, $method, @what) = @_;

	my $info = $self->_method_definitions();

	my $final = $info->{$method};

	while ( my $key = shift @what )
	{
		# Dig deeper.
		$final = $final->{$key};
	}

	return $final;

}


#
#% Inspect an entity for its name.
#
#* Returns the localized name for an entity's method.
#
#> $method { Method to inspect. }
#> [$lang] { Specific language to find. }
#
#\option method
#

sub entity_inspect_name
{
	my ($self, $method, $lang) = @_;

	my $value = $self->entity_inspect_lang(
		$self->entity_inspect($method, 'name'),
		$lang,
	);

	return defined $value ? $value : $method;
}


#
#% Inspect an entity for its description.
#
#* Returns the localized description for an entity's method.
#
#> $method { Method to inspect. }
#> [$lang] { Specific language to find. }
#
#\option method
#

sub entity_inspect_description
{
	my ($self, $method, $lang) = @_;
	return $self->entity_inspect_lang(
		$self->entity_inspect($method, 'description'),
		$lang,
	);
}


#
#% Examines input and returns a localized string.
#
#* Looks at value to determine if it is a plain string or if
#* it is a hashref that (hopefully) contains 'lang' => 'string'
#* pairs. If the hashref contains something like the $lang
#* specified, the proper string value will be returned.
#
#> $value { Value to examine. }
#> [$lang] { Specific language to find. }
#
#\option method
#

sub entity_inspect_lang
{
	my ($self, $value, $lang) = @_;

	return undef() unless defined $value;

	my $value_lang = undef();
	
	if ( defined $lang )
	{
		# Try to get the $lang value (override).
		$value_lang = $self->_entity_inspect_lang(
			$value,
			$lang,
		);
	}

	if ( ! defined $value_lang )
	{
		# Try to get the ->entity_lang() value (override).
		$value_lang = $self->_entity_inspect_lang(
			$value,
			$self->entity_lang(),
		);
	}

	if (
		! defined $value_lang and
		( ! defined $lang or $lang ne 'en_US' ) and
		( $self->entity_lang() ne 'en_US' )
	)
	{
		# Try to get the en_US value (default).
		$value_lang = $self->_entity_inspect_lang($value, 'en_US');
	}

	# Pass back whatever we have at this point.
	return $value_lang;

}


#
#% Find localized string from value.
#
#* Examines $value to determine if some variation of $lang
#* exists. If so, returns the localized string.
#
#> $lang { Language code. }
#> $value { Value to check. }
#
#\option method
#

sub _entity_inspect_lang
{

	my ($self, $value, $lang) = @_;

	# We are a pretty weak wrapper.
	return $self->_lang->localize_pure($value, $lang);

}

#
#% Cached Language object.
#
#< $Epromo::Lang=OBJECT { Language object. }
#
#\option method
#

sub _lang
{
	my $self = shift;

	if ( ! exists $self->{'_lang'} )
	{
		require Bibliopolis::Lang;
		$self->{'_lang'} = Epromo::Lang->new();
	}

	return $self->{'_lang'};
}


#
#% Gets the entitie's default language.
#
#> [$lang] { New language. }
#
#< $lang { Current language. }
#
#\option method
#

sub entity_lang
{

	my $self = shift;

	if ( @_ )
	{
		$self->{'lang'} = shift;
	}

	if ( ! defined $self->{'lang'} )
	{

		$self->{'lang'} = $self->_lang->LANG();

	}

	return $self->{'lang'};
}

#
#% encrypts a value for an encrypted column
#
#> $value { value to be encrypted }
#
#< $value { encrypted value sql string }
#

sub encrypt
{
	my $self = shift;
	
	my ($value) = @_;
	
	$value = " AES_ENCRYPT($value, '".$self->encryption_key()."') ";	
	
	return $value;
}

#
#% decrypts a value for an encrypted column
#
#> $column_name { name of column to be decrypted }
#
#< $value { a string to be inserted into the query to descrypt the individual column $column_name
#

sub decrypt
{
	my $self = shift;
	
	my ($value) = @_;
	
	$value = " AES_DECRYPT($value, '".$self->encryption_key()."') as $value";	
	
	return $value;
}


#
#% list of column names that are encrypted for this entity
#
#< %columns { a hash of columns to be encrypted in the form name => 1 }
#
# 

sub _db_column_encrypted {
	
	my %columns = ();
	
	return %columns;	
}

#
#% the encryption key for columns
#
#< $key { and encryption key }
#

sub encryption_key
{
	return 'T0e/dCC#sf0rESlc';
}

#
#% entity error reporting function
#
#> $message { error message }
#

sub entity_error
{
	my $self = shift;

	my($message) = @_;
		
	use English;
	
	if ( $message )
	{
		my $entity = ref($self);

		# $! is like unix errno

		throw Error::Simple($message . " in entity " . $entity . " " . $DBI::errstr);
	}
	else
	{
		# Then treat method is a class method
		my $message = $self;
				
		throw Error::Simple($message);
	}
}

#
#% bulk_update
#
#* update entities in bulk
#
#> $fields_to_update { hash of fields and corresponding values to update }
#> $fields_to_narrow_update { limiting conditions on the fields to update ( i.e. fields in the sql where clause ) }
#
#< $rv { successful return value from perl DBI ( database interface )
#

sub bulk_update
{
	my($class, $fields_to_update, $fields_to_narrow_update) = @_;
	
	my $sql = Epromo::Buffer->new();
	
	my $db_table_name = $class->_db_table_name();

	$sql->append(
		"UPDATE $db_table_name SET "
	);
		
	# Fields to Update
	$sql->append(
		join(
			", ", 
			map { "$_ = ?" } keys %$fields_to_update
		)
	);
	
	# Limiting conditions
	
	if ( $fields_to_narrow_update )
	{
		$sql->append(" WHERE ");

		$sql->append(
			join(
				" AND ", 
				map { "$_ = ?" } keys %$fields_to_narrow_update
			)
		);
	}
	
	# Get our prepared statement handler for this query.
	my $sth = $class->statement_cache->statement($sql);

	# Collect our values into 1 array
	my @values = map { $_ } ( values(%$fields_to_update), values(%$fields_to_narrow_update) );
	
	# Execute
	my $rv = $sth->execute(
		# Get the values for each column in %column.
		map { $_ } @values
	) or die( entity_error($sql) );

	return $rv;
}

#
#% _db_data_retrieved
#
#* used interally to implement lazy loading
#* lazy loading has been removed though.
#

sub _db_data_retrieved
{
	my $self = shift;	
	return @_ ? $self->{'_db_data_retrieved'} = shift : $self->{'_db_data_retrieved'};
}

#
#% clone
#
#* clones an entity
#

sub clone
{

	my $self = shift;
	
	my $clone = $self->new();
	
	foreach my $column ( $self->_db_table_columns() )
	{
		if ( $column eq $self->_db_table_id_column() )
		{
			$clone->id( $self->id() );
		}
		else
		{
			$clone->$column( $self->$column() ); 
		}
	}
	
	return $clone;	
}

#
#% entity package name
#* stores the entities package name
#

sub entity_package_name
{
	my $self = shift;
	return @_ ? $self->{'package_name'} = shift : $self->{'package_name'};	
}

#
# access any random unspecified value
#

sub AUTOLOAD
{
	my $self = shift;

	my @parts = split(/::/, $AUTOLOAD);

	my $method_name = pop(@parts);

	if (@_) {
		if ( $self->property_exists($method_name) ) {
			return $self->_access($method_name, @_);
		} else {
			return $self->_access_virtual_field($method_name, @_);
		}
	} else {

		if ( $self->virtual_property_exists($method_name) ){
			return $self->_access_virtual_field($method_name, @_);
		} elsif ( $self->property_exists($method_name) ) {
			return $self->_access($method_name, @_);
		}
	
		throw Error("Property \"$method_name\" does not exist for " . ref $self);	
	}	
}

#
# access any random unspecified value
#

sub getHash
{
	my $self = shift;
	my $hash_ref = {};
	
	foreach my $method_name ( $self->_db_table_columns() ) {
		$hash_ref->{$method_name} = $self->$method_name();
	}

	return $hash_ref;	
}

sub getHref
{
	my $self = shift;
	return $self->getHash(@_);
}

sub getNonIDHref
{
	my $self = shift;

	my $hash_ref = $self->getHref(@_);

	my @columns = $self->_db_table_id_column();

	foreach my $column ( @columns )
	{
		delete $hash_ref->{$column};
	}

	return $hash_ref;
}	

sub get_attribute_names {
	my $self = shift;
	return $self->_db_table_columns();
}

sub setAllPropertiesFrom
{
	my($self, $hashref) = @_;

	foreach my $columnName ( $self->_db_table_columns() ) {
		
		if ( ! $self->_is_db_table_id_column($columnName) ) {
		
			my $value = $hashref->{$columnName};
			

			$self->$columnName( $value );

		}
	}
}

sub _is_db_table_id_column
{
	my ($self, $columnName) = @_;
	return contains($columnName, $self->_db_table_id_column());	
}

sub set_all_fields_from_hash_ref
{
	my ($self, $hash_ref) = @_;

	no strict 'refs';
	
	foreach my $property_name ( $self->_db_table_columns() ) {
		if ( exists $hash_ref->{$property_name} ) {
					
			$self->$property_name($hash_ref->{$property_name});
		}
	}
	
	use strict 'refs';
}

sub column_names
{
	my $class = shift;
	return $class->_db_table_columns();
}

sub attributes {
        my $self = shift;
        return $self->column_names();
}

sub attribute_exists
{
    my ($self, $new_attribute) = @_;

    my %exists;

    foreach my $attribute ( $self->_db_table_columns() )
    {
	$exists{$attribute} = 1;
    }

    return $exists{$new_attribute};
}

sub id_fields
{
    my $self = shift;

}

sub set_non_id_properties_from_href
{
  my ($self, $href) = @_;

  my @ids = $self->_db_table_id_colum();

  my %ids = map { $_ => 1 } @ids;

  no strict 'refs';

  foreach my $attribute_name ( $self->attributes() )
  {
    my $value = $href->{$attribute_name};

    if ( ! $ids{$attribute_name} )
    {
      $self->$attribute_name($value);
    }
  }

  use strict 'refs';

}

1;
