package Bibliopolis::Date::Class;

use strict;
use warnings;

# We're deffinitely going to be needing the help
# of our main date package.
require Bibliopolis::Date;

our $VERSION = '0.01';

use overload qw('""' => 'as_string');

##
## constructor
##

# ($datestring) <$Bibliopolis::Date::Class>

sub new 
{

  my $proto = shift;
  my $class = ref $proto ? ref($proto) : $proto;

  # This should be text.
  my $date = shift;

  if ( defined $date ) {

    # If the date was specified as a text-string of something
    # we know to calculate on our own, trap it here.
    if ( $date =~ /^(current|now|today)$/i ) {
      $date = Bibliopolis::Date::get_today_datetime();
    }

    # Get the parts!
    my ($year, $month, $day, $hour, $minute, $second) = Bibliopolis::Date::parse_datetime($date);
	
	# 25th hour ( 0 based index ) doesn't exist
	if ( $hour >= 24 ) { $hour = 0; };
	
    # Make sure our "raw" date looks somewhat nice.    
    $date = join
      ('',
      sprintf("%04d", defined $year ? $year : 0 ),
      map { sprintf("%02d", defined $_ ? $_ : 0) } ($month, $day, $hour, $minute, $second)
    );

  }

  # We are a bouncing baby ARRAY reference.
  my $self = [$date];

  # Bless us!
  bless $self, $class;

  if ( $self->raw ) {

    ##
    ## Do this if we were actually given raw input.
    ##

    # Make sure we are valid.
    my ($is_valid_date, $error) = $self->validate();

    unless ( $is_valid_date ) {
      # If we weren't a valid date, then we want to set the
      # error so we can find it later.
      $self->set_error($error);
    }

  }
  else {
    # Well, how about that?
    $self->set_error('No date was defined');
  }

  # Pass ourself back.
  return $self;

}

sub months_since_0_ad
{
	my $self = shift;
	
	my $year 	= $self->year();
	my $month	= $self->month();
				
	return ($year * 12) + $month;
}


##
## methods
##

sub validate 
{
  my $self = shift;

  return Bibliopolis::Date::valid_date(
    $self->year,
    $self->month,
    $self->day
  );

}


# Standard accessors.
sub year 
{ 
	if ( length $_[0]->[0] < 4 ) 
	{
		return 0;
	};
	
	return substr($_[0]->[0],  0, 4);
}


sub month
{
	if ( length $_[0]->[0] < 6 ) { return 0; }
	return $_[0]->_remove_leading_zeros(substr($_[0]->[0],  4, 2));
}

sub raw_month_digits
{
        if ( length $_[0]->[0] < 6 ) { return 0; }
        return substr($_[0]->[0],  4, 2);
}

sub day 
{ 
	if ( length $_[0]->[0] < 8 ) { return 0; }; 
	return $_[0]->_remove_leading_zeros(substr($_[0]->[0],  6, 2));
}

sub raw_day_digits
{
   if ( length $_[0]->[0] < 8 ) { return 0; };
   return substr($_[0]->[0],  6, 2);
}

sub hour   { if ( length $_[0]->[0] < 10 ) { return 0; }; return substr($_[0]->[0],  8, 2); }

sub minute { if ( length $_[0]->[0] < 12 ) { return 0; }; return substr($_[0]->[0], 10, 2); }

sub second { if ( length $_[0]->[0] < 14 ) { return 0; }; return substr($_[0]->[0], 12, 2); }

sub day_of_year { my $self = shift; return Bibliopolis::Date::day_of_year($self->year, $self->month, $self->day); }

# Standard set methods.
sub set_year { my ($d, @input) = @_; $d->_validate_set('year', @input); }
sub set_month { my ($d, @input) = @_; $d->_validate_set('month', @input); }
sub set_day { my ($d, @input) = @_; $d->_validate_set('day', @input); }
sub set_hour { my ($d, @input) = @_; $d->_validate_set('hour', @input); }
sub set_minute { my ($d, @input) = @_; $d->_validate_set('minute', @input); }
sub set_second { my ($d, @input) = @_; $d->_validate_set('second', @input); }

sub _validate_set {

  # Ignore anything already set as an error. We should
  # have checked for it by now....
  $_[0]->clear_error;

  # Get the input.
  my ($d, $ident, $input, $should_validate) = @_;

  # New date is pretty ... empty.
  my $new_date = '';

  # We should know what we're doing before we turn this off!
  $should_validate = 1 unless defined $should_validate;

  for (
    ['year', $d->year],
    ['month', $d->month],
    ['day', $d->day],
    ['hour', $d->hour],
    ['minute', $d->minute],
    ['second', $d->second],
  ) {
    if ( $ident eq $_->[0] ) { $new_date .= $d->_zero_pad($input); }
    else { $new_date .= $d->_zero_pad($_->[1]); }
  }

  return $d->set_raw($new_date, $should_validate);

}

sub calc {

  my ($self, $string) = @_;

  # Create a temporary object to do calculations on.
  my $temp = $self->new($self->raw);

  my $which = substr($string, 0, 1);
  my $args = substr($string, 1);

  if ( defined $which ) {

    $string =~ s/^[$which]//;

    if ( $which eq '+' ) {

      # If we are going to be adding onto our date...

      for my $type (qw(s M h d m y)) {

        # What number is before each type? i.e., 5d, 1y, etc.
        my ($num) = $args =~ /(\d+)$type/;

        if ( $num ) {

          # If we found a number before this $type, we want to
          # add $num of $type to our temporary object.

          if ( $type eq 's' ) { $temp->add_second($num); }
          elsif ( $type eq 'M' ) { $temp->add_minute($num); }
          elsif ( $type eq 'h' ) { $temp->add_hour($num); }
          elsif ( $type eq 'd' ) { $temp->add_day($num); }
          elsif ( $type eq 'm' ) { $temp->add_month($num); }
          elsif ( $type eq 'y' ) { $temp->add_year($num); }

        }

      };

    }
    elsif ( $which eq '-' ) {

      # WARNING: Not implemented yet! Or maybe just not tested...
      #          Use at our own risk, if you use at all...
      for my $type (qw(s M h d m y)) {
        my ($num) = $args =~ /(\d+)$type/;
        if ( $num ) {
          if ( $type eq 's' ) { $temp->remove_second($num); }
          elsif ( $type eq 'M' ) { $temp->remove_minute($num); }
          elsif ( $type eq 'h' ) { $temp->remove_hour($num); }
          elsif ( $type eq 'd' ) { $temp->remove_day($num); }
          elsif ( $type eq 'm' ) { $temp->remove_month($num); }
          elsif ( $type eq 'y' ) { $temp->remove_year($num); }
        }
      };

    }

  }
  else { die "Could not parse: $string"; }

  return $temp;

}

# Begin the add chain at the lowest possible level. =)

sub add_second {
    my ($self, $num) = @_;
    my $total_second = $self->second + $num;
    my $set_second = $total_second % 60;
    $self->set_second($set_second);
    if ( $total_second >= 60 ) {
        $self->add_minute( ( $total_second - $set_second ) / 60);
    }
}

sub add_minute {
    my ($self, $num) = @_;
    my $total_minute = $self->minute + $num;
    my $set_minute = $total_minute % 60;
    $self->set_minute($set_minute);
    if ( $total_minute >= 60 ) {
        $self->add_hour( ( $total_minute - $set_minute ) / 60);
    }
}

sub add_hour {
    my ($self, $num) = @_;
    my $total_hour = $self->hour + $num;
    my $set_hour = $total_hour % 24;
    $self->set_hour($set_hour);
    if ( $total_hour >= 24 ) {
        $self->add_day( ( $total_hour - $set_hour ) / 24);
    }
}

sub add_day {

    my ($self, $num) = @_;

    my $days_in_current_month = Bibliopolis::Date::days_in($self->year, $self->month);

    my ($final_year, $final_month, $final_day);

    if ( ( $self->day + $num ) > $days_in_current_month ) {

        my $new_num = $num - ( $days_in_current_month - $self->day );

        my ($start_year, $start_month);

        if ( $self->month == 12 ) {
            $start_year = $self->year + 1;
            $start_month = 1;
        }
        else {
            $start_year = $self->year;
            $start_month = $self->month + 1;
        }

        ($final_year, $final_month, $final_day) = $self->_add_day($new_num, $start_year, $start_month);


    }
    else {
        $final_year = $self->year;
        $final_month = $self->month;
        $final_day = $self->day + $num;
    }

    eval {

        $self->set_year($final_year, 0) unless $final_year == $self->year;
        $self->set_month($final_month, 0) unless $final_month == $self->month;
        $self->set_day($final_day, 0) unless $final_day == $self->day;

    };

    my ($is_valid_date, $error) = $self->validate;

    if ( $is_valid_date ) { return 1; }
    else {
        $_[0]->set_error($error);
        return 0;
    }

}

sub _add_day {

    # A nice little recursive call. =)

    my ($self, $num, $year, $month) = @_;

    my $days_in_month = Bibliopolis::Date::days_in($year, $month);

    if ( $days_in_month < $num ) {
        my ($new_month, $new_year);
        if ( $month == 12 ) {
            $new_month = 1;
            $new_year = $year + 1;
        }
        else {
            $new_month = $month + 1;
            $new_year = $year;
        }
        return $self->_add_day(($num - $days_in_month), $new_year, $new_month);
    }

    return ($year, $month, $num);

}

sub add_month {

    my ($self, $num) = @_;

    my $total_month = $self->month + $num;
    #my $set_month = $total_month % 12;
    my $set_month = ( ( $total_month -1 ) % 12 ) +  1;

    eval {
        $self->set_month($set_month, 0);
        if ( $total_month > 12 ) {
            $self->add_year( int( ( $total_month - $set_month ) / 12 ), 0);
        }
    };

    my $max_days_in_new_object = Bibliopolis::Date::days_in($self->year, $self->month);

    if ( $self->day > $max_days_in_new_object ) {
        $self->set_day($max_days_in_new_object);
    }

    my ($is_valid_date, $error) = $self->validate;

    if ( $is_valid_date ) {
        return 1;
    }
    else {
        $_[0]->set_error($error);
        return 0;
    }

}

sub add_year {
    my ($self, $num, $should_validate) = @_;
    $should_validate = 1 unless defined $should_validate;
    $self->set_year($self->year + $num, $should_validate);
}

sub remove_second {
    my ($self, $num) = @_;
    my $total_second = $self->second - $num;
    my $set_second = $total_second % 60;
    $self->set_second($set_second);
    if ( $total_second <= 60 ) {
        $self->remove_minute( -1 * (( $total_second - $set_second ) / 60) );
    }
}

sub remove_minute {
    my ($self, $num) = @_;
    my $total_minute = $self->minute - $num;
    my $set_minute = $total_minute % 60;
    $self->set_minute($set_minute);
    if ( $total_minute <= 60 ) {
        $self->remove_hour( -1 * (( $total_minute - $set_minute ) / 60) );
    }
}

sub remove_hour {
    my ($self, $num) = @_;
    my $total_hour = $self->hour - $num;
    my $set_hour = $total_hour % 24;
    $self->set_hour($set_hour);
    if ( $total_hour <= 24 ) {
        $self->remove_day( -1 * (( $total_hour - $set_hour ) / 24) );
    }
}


sub remove_day {

    my ($self, $num) = @_;

    my ($final_year, $final_month, $final_day);

    if ( ( $self->day - $num ) < 1 ) {

        my $new_num = $num - $self->day;

        my ($start_year, $start_month);

        if ( $self->month == 1 ) {
            $start_year = $self->year - 1;
            $start_month = 12;
        }
        else {
            $start_year = $self->year;
            $start_month = $self->month - 1;
        }

        ($final_year, $final_month, $final_day) = $self->_remove_day($new_num, $start_year, $start_month);


    }
    else {
        $final_year = $self->year;
        $final_month = $self->month;
        $final_day = $self->day - $num;
    }

    eval {

        $self->set_year($final_year, 0) unless $final_year == $self->year;
        $self->set_month($final_month, 0) unless $final_month == $self->month;
        $self->set_day($final_day, 0) unless $final_day == $self->day;

    };

    my ($is_valid_date, $error) = $self->validate;

    if ( $is_valid_date ) { return 1; }
    else {
        $_[0]->set_error($error);
        return 0;
    }

}

sub _remove_day {

    # A nice little recursive call. =)

    my ($self, $num, $year, $month) = @_;

    my $days_in_month = Bibliopolis::Date::days_in($year, $month);

    if ( $num and ( $days_in_month - $num  < 1 ) ) {
        my ($new_month, $new_year);
        if ( $month == 1 ) {
            $new_month = 12;
            $new_year = $year - 1;
        }
        else {
            $new_month = $month - 1;
            $new_year = $year;
        }
        return $self->_remove_day(($num - $days_in_month), $new_year, $new_month);
    }

    return ($year, $month, $days_in_month - $num);

}


sub remove_month {

    my ($self, $num) = @_;

    my $set_month = ( 12 - ( $num - $self->month ) % 12);

    eval {
        if ( $self->month - $num <= 0 ) {
            my $extra_months = $num - $self->month;
            my $month_modifier = $extra_months % 12;
            $self->remove_year( ( ( $extra_months - $month_modifier ) / 12 ) + 1, 0);
        }
        $self->set_month($set_month, 0);
    };

    my $max_days_in_new_object = Bibliopolis::Date::days_in($self->year, $self->month);

    if ( $self->day > $max_days_in_new_object ) {
        $self->set_day($max_days_in_new_object);
    }

    my ($is_valid_date, $error) = $self->validate;

    if ( $is_valid_date ) {
        return 1;
    }
    else {
        $_[0]->set_error($error);
        return 0;
    }

}


sub remove_year {
    my ($self, $num, $should_validate) = @_;
    $should_validate = 1 unless defined $should_validate;
    $self->set_year($self->year - $num, $should_validate);
}

sub adjust {

    # Adjust just calls calc and sets the raw value of ourself
    # to the raw value of the calculated object.

    my ($self, $string) = @_;
    my $new_time_object = $self->calc($string);

    if ( $new_time_object->has_error ) {
        $self->set_error($new_time_object->get_error);
        return 0;
    }
    else {
        $self->set_raw($new_time_object->raw);
        return 1;
    }

}

sub raw { return $_[0]->[0] }


sub set_raw {
    $_[0]->clear_error;
    if ( $_[2] ) {
        my ($is_valid_date, $error) = Bibliopolis::Date::valid_date(
            $_[1] =~ /^([\d]{4})([\d]{2})([\d]{2})[\d]{6}/
        );
        unless ( $is_valid_date ) {
            $_[0]->set_error($error);
            return 0;
        }
    }
    $_[0]->[0] = $_[1];
    return 1;
}


sub formatted_datetime {
  return sprintf("%04d-%02d-%02d", $_[0]->year(), $_[0]->month(), $_[0]->day()) . ' ' . sprintf("%02d:%02d:%02d", $_[0]->hour(), $_[0]->minute(), $_[0]->second());
}

sub formatted_datetime_human {
  return formatted_date_human(@_) .' '. formatted_time_human(@_);
}

sub formatted_date_human {
  return join('/', $_[0]->month(), $_[0]->day(), $_[0]->year());
}

sub formatted_date_usa {
  return join('/', $_[0]->month(), $_[0]->day(), ($_[0]->year() - 2000));
}

sub formatted_date_long {
  return $_[0]->weekday_name_full($_[0]->day_of_week()) . ', ' . $_[0]->month_name_full($_[0]->month()) . ' ' . $_[0]->day() . ', ' . $_[0]->year();
}

sub formatted_date_custom
{
	my($self, $str) = @_;
	
	$str =~ s/YYYY/$self->year()/egs;
	$str =~ s/YY/substr($self->year(), 2)/egs;
	$str =~ s/yy/$self->year() - 2000/egs;
	$str =~ s/MMMM/$self->month_name_full($self->month())/egs;
	$str =~ s/MMM/$self->month_name($self->month())/egs;
	$str =~ s/MM/sprintf("%02d", $self->month())/egs;
	$str =~ s/mm/$self->month()/egs;
	$str =~ s/DD/sprintf("%02d", $self->day())/egs;
	$str =~ s/dd/$self->day()/egs;
	$str =~ s/WDY/$self->weekday_name_full($self->day_of_week())/egs;
	$str =~ s/wdy/$self->week_day_name($self->day_of_week())/egs;
	
	return $str;
}

sub formatted_date {
  #return join('-', $_[0]->year(), $_[0]->month(), $_[0]->day());
  return formatted_date_full(@_);
}

sub formatted_date_full
{
	my $date = sprintf("%04d-%02d-%02d", $_[0]->year(), $_[0]->month(), $_[0]->day());
	return $date;
}

sub raw_date {
	my $self = shift;
	
	my $year = $self->year();
	my $month = $self->month();
	my $day = $self->day();
	
	# Add a leading 0
	$month =~ s/^([0-9])$/0$1/g;
	$day =~ s/^([0-9])$/0$1/g;
		
	my $raw_date = $year . '-' . $month . '-' . $day; 
	
	return $raw_date;
}



sub formatted_time {
  return $_[0]->hour() .':'. $_[0]->minute() .':'. $_[0]->second();
}

sub formatted_time_human {
  return (($_[0]->hour() % 12) || 12) .':'. $_[0]->minute() .' '. ($_[0]->hour() >= 12 ? 'PM' : 'AM');
}

# todo: document header in perldoc
sub months_in_year {

	my $self = shift;
	
	my %months_in_year = Bibliopolis::Date::months_in_year();	
	
	my @sorted_month_names = sort { $a <=> $b } keys %months_in_year;
		
	my %months_in_year_sorted = map { $_ => $months_in_year{$_} } @sorted_month_names;	
	
	return \%months_in_year_sorted;
}

# todo: document header in perldoc
sub years_from_now {

	my ($self, $years_from_now) = @_;
	
	my $year = year($self);
	
	my $years_from_now_aref = [];
	
	for ( my $i = 0; $i < $years_from_now; $i++, $year++)
	{
		push(@$years_from_now_aref, $year);
	}
	
	return $years_from_now_aref;
}

sub day_of_week {
  return Bibliopolis::Date::day_of_week($_[0]->year(), $_[0]->month(), $_[0]->day());
}

sub day_of_week_index {
  return Bibliopolis::Date::day_of_week_index($_[0]->year(), $_[0]->month(), $_[0]->day());
}

{

  my @daymap = qw(Mon Tue Wed Thu Fri Sat Sun);

  sub formatted_datetime_http_header {

    my $self = shift;

    # HTTP headers want us to be using GMT
    my $cst = $self->cst();

    return
      $daymap[$cst->day_of_week()-1] . ', ' .
      join(' ',
        sprintf("%02d", $cst->day()),
        substr(Bibliopolis::Date::month_name($cst->month()), 0, 3),
        $cst->year(),
        join(':',
          sprintf("%02d", $cst->hour()),
          sprintf("%02d", $cst->minute()),
          sprintf("%02d", $cst->second()),
        ),
        'CST'
      );
  }
}

# () <$javascript_date_string> - Returns the date the way Javascript Date object can read it
sub formatted_datetime_javascript {
  my $self = shift;

  return join(' ',
              Bibliopolis::Date::month_name($self->month()),
              sprintf("%02d", $self->day()) . ',',
              $self->year(),
              join(':',
                   sprintf("%02d", $self->hour()),
                   sprintf("%02d", $self->minute()),
                   sprintf("%02d", $self->second()),
                   ),
              );
}


sub _remove_leading_zeros {
    my ($self, $value) = @_;
    $value =~ s/^0+//;
    return $value;
}

sub _zero_pad {
    my ($self, $value) = @_;
    return length $value < 2 ? '0' . $value : $value;
}

sub gmt {
  my $self = shift;
  return $self->to_gmt(@_);
}

sub to_gmt {
  my $self = shift;
  my $gmt_offset = Bibliopolis::Date::gmt_offset();
  return $self->calc('+' . ( $gmt_offset * -1 ) . 'h');
}

sub cst {
	my $self = shift;
	$self->to_cst(@_);
}

sub to_cst {
	my $self = shift;	
	my $cst_offset = Bibliopolis::Date::cst_offset();
	return $self->calc('+' . $cst_offset . 'h');	
}

sub est
{
	my $self = shift;
	$self->to_cst(@_);
}

sub to_est
{
	my $self = shift;
	my $est_offset = Bibliopolis::Date::est_offset();
	return $self->calc('+' . $est_offset . 'h');
}

sub month_name_to_digit
{
	my ($self, $monthName) = @_;

	my $month_hash = {
		'January'       => '01',
		'February'      => '02',
		'March'         => '03',
		'April'         => '04',
		'May'           => '05',
		'June'          => '06',
		'July'          => '07',
		'August'        => '08',
		'September'     => '09',
		'October'       => '10',
		'November'      => '11',
		'December'      => '12'
	};

	return $month_hash->{$monthName};
}

sub from_gmt {
  my $self = shift;
  my $gmt_offset = Bibliopolis::Date::gmt_offset();
  return $self->calc('-' . ( $gmt_offset * -1 ) . 'h');
}

sub mktime {
  my $self = shift;
  require POSIX;
  # Use mktime to build this for us.
  return POSIX::mktime(
    0,
    $self->minute(),
    $self->hour(),
    $self->day(),
    $self->month() - 1,
    $self->year() - 1900,
    0,
    0,
    -1
  );
}

sub has_error { $_[0]->[1] ? 1 : 0; }
sub get_error { $_[0]->[1]; }
sub error { my $self = shift; return @_ ? $self->set_error(@_) : $self->get_error(); }
sub set_error { $_[0]->[1] = $_[1]; }
sub clear_error { $_[0]->[1] = undef(); }


##
## Comparison
##

# ($Bibliopolis::Date::Class) <$bool>
sub newer_than {
  my ($self, $date_old) = @_;
  return Bibliopolis::Date::newer_than($self, $date_old);
}

# ($Bibliopolis::Date::Class) <$bool>
sub older_than {
  my ($self, $date_new) = @_;
  return Bibliopolis::Date::older_than($self, $date_new);
}


sub as_string {

  my($self) = @_;

  my $dateString = Bibliopolis::Date::month_name($self->month());
  $dateString .= " " . $self->day() . ", " . $self->year();

  return $dateString;

}

sub gmtRawDateTimeString {
	my $self = shift;
		
	my $date = $self->to_gmt();        
        
	my $year        = $date->year();
	my $month       = $date->month();
	my $day         = $date->day();

	my $hour        = $date->hour();
	my $minute      = $date->minute();
	my $second      = $date->second();
               
	if ( $hour < 10 ) { $hour = "0" . $hour; }
	if ( $day < 10 ) { $day = "0" . $day; }
	if ( $month < 10 ) { $month = "0" . $month; };
	if ( $minute < 10 ) { $minute = "0" . $minute; };
	if ( $second < 10 ) { $second = "0" . $second; };

	return $year . $month . $day . $hour . $minute . $second;
}

sub raw_date_string {
	my $self = shift;

	my $leading_zeros_month = sprintf("%02d", $self->month());
	my $leading_zeros_day	= sprintf("%02d", $self->day());

	return $self->year() . $leading_zeros_month . $leading_zeros_day;
}

sub formatted_gmt
{
	my $self = shift;

	my $month = $self->month();
	my $day = $self->day();
	my $year = $self->year();

	my $date = $self->week_day_name() . ", " . $day . "-" . $self->month_name($month) . "-" . $year . " " . $self->year() .  " GMT";

	return $date;
}

sub week_day_name
{
	my ($self) = @_;

	use Date::Calc qw(Day_of_Week_Abbreviation);

	return Day_of_Week_Abbreviation($self->day_of_week());

}

sub weekday_name_full
{
	my($self, $day) = @_;
	
	my %weekdays = qw(
		1 Monday
		2 Tuesday
		3 Wednesday
		4 Thursday
		5 Friday
		6 Saturday
		7 Sunday
	);
	
	return $weekdays{$day};
}

sub month_name
{
	my($self, $month) = @_;
	
	my %months = qw(
		1 Jan
		2 Feb
		3 Mar
		4 Apr
		5 May
		6 Jun
		7 Jul
		8 Aug
		9 Sep
		10 Oct
		11 Nov
		12 Dec
	);
	
	return $months{$month};
}

sub month_name_full
{
	my($self, $month) = @_;
	
	my %months = qw(
		1 January
		2 February
		3 March
		4 April
		5 May
		6 June
		7 July
		8 August
		9 September
		10 October
		11 November
		12 December
	);
	
	return $months{$month};
}

sub is_leap_year
{
	my $self = shift;
	my $year = $self->year();
	if( 0 == $year % 4 and 0 != $year % 100 or 0 == $year % 400 ){
		return 1; 
	} else {	
		return 0;
	}
}

sub days_since_1_bc
{
	my $self = shift;

	my $year = $self->year();
	my $month = $self->month();
	my $day = $self->day();

	return Bibliopolis::Date::days_since_1_bc($year, $month, $day);
}

1;

=head1 NAME

Bibliopolis::Date::Class - Bibliopolis::Date::Class

=head1 SYNOPSIS

  use Bibliopolis::Date::Class;

=head1 DESCRIPTION

Class for Halogen dates.

=head2 CONSTRUCTOR

Constructors are used to create instances of the Bibliopolis::Date::Class class.

=over 4

=item new

Creates a new Halogen date object based on the date information passed.

Accepts: $datestring

Returns: $Bibliopolis::Date::Class

=back

=head2 METHODS

The following methods are available to the Bibliopolis::Date::Class class.

=over 4

=item validate

Determines whether the current value for the object represents
a valid date.

If $bool is true, $error_string should contain descriptive
text as to what was wrong with the date.

Returns: $bool, $error_string

=item year

=item month

=item day

=item hour

=item minute

=item second

The datetime parts of the object.

Returns: $value

=item day_of_year

The number of days since the beginning of the year.

Returns: $int

=item set_year

=item set_month

=item set_day

=item set_hour

=item set_minute

=item set_second

Sets the datetime parts of the object. If $should_validate
is set to off, no validation will be done to ensure that
the object has a valid date.

If $bool is true, $error_string should contain descriptive
text as to what was wrong with the date.

Accepts: $new_value, $should_validate

Returns: $bool, $error_string

=item calc

An object representing a calculation based on our existing object.

$modifier_string starts with either a + (add) or a - (subtract)
character. Following that are value/type pairs, with no spaces.
The value/type pairs represent the number of units and the unit
type.

Unit types are defined as follows:

 s Seconds
 M Minutes
 h Hours
 d Days
 m Month
 y Year

Examples:

  +5y     Add 5 years
  -3d4h   Subtract 3 days and 4 hours
  +1M     Add 1 minute
  -1m     Subtract 1 month


Accepts: $modifier_string

Returns: $Bibliopolis::Date::Class

=item add_second

=item add_minute

=item add_hour

=item add_day

=item add_month

=item add_year

Adds the specified number of units to the objects current value.
There is currently no support for doing this without validating.
Mainly because that wouldn't make much sense. =)

If $bool is true, $error_string should contain descriptive
text as to what was wrong with the date.

Accepts: $value

Returns: $bool, $error_string

=item remove_second

=item remove_minute

=item remove_hour

=item remove_day

=item remove_month

=item remove_year

Removes the specified number of units from the objects current value.
There is currently no support for doing this without validating.
Mainly because that wouldn't make much sense. =)

If $bool is true, $error_string should contain descriptive
text as to what was wrong with the date.

Accepts: $value

Returns: $bool, $error_string

=item adjust

Adjusts the objects current datetime. Follows the same rules as
calc(), only instead of returning a new date object, on success
it sets adjusts the value of the existing date object to the
calculated value.

=item raw

Raw datetime value for the object.

Returns: $datetimestring

=item set_raw

The raw datetimestring can be set to whatever we like. If
$should_validate is passed as false, we won't even bother
to report if it is a bogus datetime.

If $bool is true, $error_string should contain descriptive
text as to what was wrong with the date.

Accepts: $datetimestring, $should_validate

Returns: $bool, $error_string

=item gmt

Returns a date object that represents the GMT time of the
date object passed.

Returns: $Bibliopolis::Date::Class

=item to_gmt

Returns a date object that represents the GMT time of the
date object passed.

Returns: $Bibliopolis::Date::Class

=item from_gmt

Returns a date object that represents the local time based
on the (assumed) GMT date object passed.

Returns: $Bibliopolis::Date::Class

=item mktime

Returns seconds based on POSIX::mktime().

Returns: $seconds

=item has_error

Whether or not our object has an error

Returns: $bool

=item get_error

The current error string for the object.

Returns: $error_string

=item set_error

Set the error string.

Accepts: $error_string

=item clear_error

Clears the error string.

=item newer_than

Returns true if this date object is more recent than the passed one. Uses Bibliopolis::Date::newer_than.

Accepts: $Bibliopolis::Date::Class

Returns: $bool

=item older_than

Returns true if this date object is older than the passed one. Uses Bibliopolis::Date::older_than.

Accepts: $Bibliopolis::Date::Class

Returns: $bool

=back

=item days_since_1_bc
Returns number of days since 1 bc
=back

=head1 AUTHOR

Tyler Bird, E<lt>birdty@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bibliopolis

=cut
