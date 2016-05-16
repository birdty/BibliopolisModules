package Epromo::Date;

use strict;
use warnings;

use DateTime;

use Error qw(:try);


our $VERSION = '0.01';

{
  my ($l_min, $l_hour, $l_year, $l_yday) = (localtime $^T)[1, 2, 5, 7];
  my ($g_min, $g_hour, $g_year, $g_yday) = (   gmtime $^T)[1, 2, 5, 7];


  my $tzval = ($l_min - $g_min)/60 + $l_hour - $g_hour +
    24 * ($l_year - $g_year || $l_yday - $g_yday);

	sub gmt_offset { return $tzval; }
	
	sub cst_offset {
		my $self = shift;
			
		my $cst_datetime = DateTime->now();			
		$cst_datetime->set_time_zone('America/Chicago');

		return $cst_datetime->hour() - $l_hour;				
	}

	sub est_offset {
		my $self = shift;
			
		my $cst_datetime = DateTime->now();			
		$cst_datetime->set_time_zone('America/New_York');

		return $cst_datetime->hour() - $l_hour;						
	}	
}

#
## functions
#

# ($datestring) <$Epromo::Date::Class>
sub create {
  if ( @_ and $_[0] and $_[0] eq __PACKAGE__ ) { shift; }

  if ( ! @_ ) { throw Error("Date parameter missing from constructor."); }
  
  require Bibliopolis::Date::Class;
  return Bibliopolis::Date::Class->new(@_);
}

sub parse_date {
  my $str = shift;
  for my $test ( _date_regex_list() ) {
    my ($key, $REGEX) = @{ $test };
    my @t = $str =~ $REGEX;
    if ( @t ) {
      return _resort_date_info($key, @t);
    }
  }
  return ();
}

sub parse_datetime {
  my $str = shift;
  for my $test ( _datetime_regex_list(), _datetime_ampm_regex_list() ) {
    my ($key, $REGEX) = @{ $test };
    my @t = $str =~ $REGEX;
    if ( @t ) {
      while ( scalar @t < 7 ) { push @t, 0; }
      for my $_dt ( qw(h M s) ) { $key .= $_dt unless $key =~ /$_dt/; }
      return _resort_date_info($key, map { defined $_ ? $_ : '00' } @t);
    }
  }
  return ();
}

sub valid_date {

  # Try to gather month information.
  my ($year, $month, $day) = @_ > 1 ? @_ : parse_date(@_);

  unless ( defined $year and defined $month and defined $day ) {
    # If we don't have all three of these, then there was a problem.
    return (0, "Year, month and/or date were not specified");
  }

  # Remove leading zeros.
  for ( $year, $month, $day ) { $_ =~ s/^0+//g }

  if ( $month !~ /^\d+$/ ) {
    return (0, "Invalid month specified ($month)");
  }
  elsif ( $month < 1 ) {
    return (0, "There are no months before January.");
  }
  elsif ( $month > 12 ) {
    return (0, "There is no month $month!");
  }
  elsif ( $day !~ /^\d+$/ ) {
    return (0, "Invalid day specified");
  }
  elsif ( $day < 1 ) {
    return (0, "There are no days before the first of the month.");
  }

  if ( ! days_in($year, $month) or $day > days_in($year, $month) ) {
    return (0, "Too many days [$day] specified for $month/$year. (max of " . days_in($year, $month) . " days)");
  }

  return 1;

}

sub today_or_later {
  my $test_seed = shift;
  my @test = parse_date($test_seed);
  my @today = parse_date(get_today());
  for ( @test, @today ) { $_ = sprintf("%05d", $_); }
  my $test_value = join('', @test);
  my $today_value = join('', @today);
  return ( $test_value >= $today_value ) ?  1 : 0;
}

# ($datetime or $Epromo::Date::Class) <$bool>
sub now_or_later {
  my $test_seed = shift;

  require Halogen::Base;
  my $test_date = Halogen::Base::value_get_date_object($test_seed);
  my $today = create('now');

  return ( $test_date->mktime >= $today->mktime ) ? 1 : 0;
}

sub get_today_datetime {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
  $year += 1900;
  $mon++;
  for ( $mon, $mday, $sec, $min, $hour ) { if ( length $_ < 2 ) { $_ = '0' . $_; } }
  return $year . $mon . $mday . $hour . $min . $sec;
}

sub get_today_formatted_datetime {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
  $year += 1900;
  $mon++;
  for ( $mon, $mday, $sec, $min, $hour ) { if ( length $_ < 2 ) { $_ = '0' . $_; } }
  return "$year-$mon-$mday $hour:$min:$sec";
}

sub get_today {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
  return join('-', (1900 + $year), $mon + 1, $mday);
}

sub get_current_year {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
  return (1900 + $year);
}

sub get_next_months_from_today {
  my $num = shift;
  $num ||= 5;
  my ($year, $month) = parse_date(get_today());
  return get_next_months($num, $year, $month);
}


sub get_next_months {
  my ($num, $year, $month) = @_;
  for ($year, $month) { s/^0+// };
  my @months = (join('-', $year, $month));
  my $count = 0;
  while ( ++$count < $num ) {
    if ( ++$month > 12 ) { $month = 1; $year++; }
    push @months, join('-', $year, $month);
  }
  return @months;
}

sub _date_regex_list {

  return (
    # These are the regex that should match date (year, month, day)
    # for date strings.
    ['ymd', '^([\d]{2,4})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{1,2})$',],
    ['mdy', '^([\d]{1,2})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{2,4})$',],
    ['ymd', '^([\d]{4})([\d]{2})([\d]{2})$',],
    ['mdy', '^([\d]{1,2})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{2,4})$',],
    _date_regex_list_datetime(),
  );

}
sub _date_regex_list_datetime {
  # These are the regex that should match date (year, month, day)
  # for full datetime strings.
  return (
    ['ymdhMs', '^([\d]{4})([\d]{2})([\d]{2})[\d]{6}$',],
    ['ymdhMs', '^([\d]{2,4})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{1,2})\s+(?:\d{1,2})\s*:\s*(?:\d{1,2})\s*:\s*(?:\d{1,2})$',],
    ['mdyhMs', '^([\d]{1,2})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{2,4})\s+(?:\d{1,2})\s*:\s*(?:\d{1,2})\s*:\s*(?:\d{1,2})$',],
  );
}

sub _datetime_regex_list {
  # These are the regex that should match full datetime (year,
  # month, day, hour, minute, second). We will also match any
  # pure dates as well (done by including _date_regex_list as
  # well).
  return (
    ['ymdhMs', '^([\d]{2,4})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{1,2})\s+(\d{1,2})\s*:\s*(\d{1,2})\s*:\s*(\d{1,2})$',],
    ['mdyhMs', '^([\d]{1,2})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{2,4})\s+(\d{1,2})\s*:\s*(\d{1,2})\s*:\s*(\d{1,2})$',],
    ['ymdhMs', '^([\d]{4})([\d]{2})([\d]{2})([\d]{2})([\d]{2})([\d]{2})$',],
    _date_regex_list(),
  );
}


sub _datetime_ampm_regex_list {
  # These are the regex that should match full datetime (year,
  # month, day, hour, minute, second). We will also match any
  # pure dates as well (done by including _date_regex_list as
  # well).
  return (
    ['ymdhMsN', '^([\d]{2,4})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{1,2})\s+(\d{1,2})\s*:\s*(\d{1,2})\s*:\s*(\d{1,2})\s*(AM|PM)$',],
    ['mdyhMsN', '^([\d]{1,2})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{2,4})\s+(\d{1,2})\s*:\s*(\d{1,2})\s*:\s*(\d{1,2})\s*(AM|PM)$',],
    ['ymdhMsN', '^([\d]{4})([\d]{2})([\d]{2})([\d]{2})([\d]{2})([\d]{2})\s*(AM|PM)$',],
    ['ymdhMN', '^([\d]{2,4})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{1,2})\s+(\d{1,2})\s*:\s*(\d{1,2})\s*(AM|PM)$',],	
    ['mdyhMN', '^([\d]{1,2})\s*[\-\/]\s*([\d]{1,2})\s*[\-\/]?\s*([\d]{2,4})\s+(\d{1,2})\s*:\s*(\d{1,2})\s*(AM|PM)$',],
  );
}

sub _resort_date_info {

  my ($key, @date_info) = @_;

  my %hash = ();

  while ( $key =~ s/^([\w])// ) {
    # We want the date info associated with this key.
    $hash{$1} = shift @date_info;
  }

  my @response = ();
  
  if ( exists $hash{'N'} and $hash{'N'} =~ /pm/i )
  {
  	if ( ! exists $hash{'h'} ) { $hash{'h'} = 0; }
  	$hash{'h'} += 12;
  }

  for my $_dt ( qw(y m d h M s) ) {
    if ( exists $hash{$_dt} and defined $hash{$_dt} ) {
      push @response, $hash{$_dt};
    }
  }

  return @response;

}

## NOTE: Most of the rest of this logic was taken almost directly from the
## Date::Manip module (see CPAN if you must). While Date::Manip is far too
## much to pack for our uses, this logic is quite valuable to be able to
## retrieve. I thank the authors for this fine bit code. =)

{

  my %mltable = qw(
    1 31
    3 31
    4 30
    5 31
    6 30
    7 31
    8 31
    9 30
    10 31
    11 30
    12 31
  );

  sub days_in {
    # Month is 1..12
    my ($year, $month) = @_;
    return 0 if $month > 12;
    return 0 if $month < 1;
    return $mltable{$month+0} unless $month == 2;
    return 28 unless is_leap($year);
    return 29;
  }

  my %wordtable = qw(
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

	sub month_name {
		my $month = shift;
		return $wordtable{$month};
	}

	sub month_digit {

		my ($class, $month_name) = @_;

		my %month_name_hash = reverse %wordtable;	

		my $digit = $month_name_hash{$month_name};
		
		if ( $digit < 10 ) { $digit = "0" . $digit; }
		
		return $digit;
	}

  sub months_in_year
  {
  		return %wordtable;
  }

}

#
# Returns a list of months in the year.
#

sub year_months
{
	my($class) = @_;
	
	require Bibliopolis::Date::Month;
	
	my @months = ();	
	my %months_in_year = Epromo::Date::months_in_year();
				
	foreach my $month_number ( sort { $a <=> $b } keys %months_in_year ) {
		my $month_name = $months_in_year{$month_number};
	
		if ( $month_number < 10 ) { $month_number = "0" . $month_number; }		
		
		my $month = Epromo::Date::Month->new($month_number, $month_name);
		push(@months, $month);
	} 
	
	return @months;
}

sub years {

	my($class_name, $start_year_number, $end_year_number) = @_;
	
	require Bibliopolis::Date::Year;
	
	my @years = ();	

	foreach my $year_number ( $start_year_number .. $end_year_number ) {
		my $year = Epromo::Date::Year->new($year_number);
		push(@years, $year);
	}

	return @years;
}

sub is_leap {
  my ($year) = @_;
  return 0 unless $year % 4 == 0;
  return 1 unless $year % 100 == 0;
  return 0 unless $year % 400 == 0;
  return 1;
}

sub day_of_week {

  my($y, $m, $d) = @_;
  my $dayofweek = day_of_week_index($y, $m, $d);
  $dayofweek=7  if ($dayofweek==0);
  return $dayofweek;

}

sub day_of_week_index {

  my($y, $m, $d) = @_;

  my($dayofweek,$dec31)=();

  $dec31=5; # Dec 31, 1BC was Friday
  $dayofweek=(days_since_1_bc($y,$m,$d)+$dec31) % 7;

  return $dayofweek;

}

sub days_since_1_bc {

  my ($y, $m, $d) = @_;

  my($Ny,$N4,$N100,$N400,$dayofyear,$days)=();

  my ($cc, $yy) = $y=~ /(\d{2})(\d{2})/;

  # Number of full years since Dec 31, 1BC (counting the year 0000).
  $Ny=$y;

  # Number of full 4th years (incl. 0000) since Dec 31, 1BC
  $N4=($Ny-1)/4 + 1;
  $N4=0         if ($y==0);

  # Number of full 100th years (incl. 0000)
  $N100=$cc + 1;
  $N100--       if ($yy==0);
  $N100=0       if ($y==0);

  # Number of full 400th years (incl. 0000)
  $N400=($N100-1)/4 + 1;
  $N400=0       if ($y==0);

  $dayofyear=day_of_year($y, $m,$d);
  $days= $Ny*365 + $N4 - $N100 + $N400 + $dayofyear;

  return $days;

}




sub day_of_year {

  my ($y, $m, $d) = @_;

  # DinM    = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  my(@days) = ( 0, 31, 59, 90,120,151,181,212,243,273,304,334,365);
  my($ly)=0;

  $ly=1  if ($m>2 && is_leap($y));

  return ($days[$m-1]+$d+$ly);

}

# ($Epromo::Date::Class, $Epromo::Date::Class) <$integer>
sub days_between {
  my ($date1, $date2) = @_;
  return abs( days_since_1_bc( $date1->year, $date1->month, $date1->day ) -
              days_since_1_bc( $date2->year, $date2->month, $date2->day )
             );
}

# ($Epromo::Date::Class, $Epromo::Date::Class) <$integer>
sub months_between {
	my ($date1, $date2) = @_;
	return abs ( $date1->months_since_0_ad() - $date2->months_since_0_ad() );
}	


# ($Epromo::Date::Class, $Epromo::Date::Class) <$bool>
sub newer_than {
  my ($date_new, $date_old) = @_;
	 
  return ( $date_new->mktime > $date_old->mktime ) ? 1 : 0;
}

# ($Epromo::Date::Class, $Epromo::Date::Class) <$bool>
sub older_than {
  my ($date_old, $date_new) = @_;
  return newer_than( $date_new, $date_old );
}

# ($Epromo::Date::Class, $Epromo::Date::Class, $bool) <$bool>

sub date_eq {

	my($date_1, $date_2) = @_;

	my $equal = $date_1->mktime() == $date_2->mktime();
	
	return $equal;
}


1;

=head1 NAME

Halogen::Date - Halogen::Date

=head1 SYNOPSIS

  use Halogen::Date;

=head1 DESCRIPTION

Function library for dealing with Halogen dates.

=head2 FUNCTIONS

The following functions are available to the Halogen::Date package.

=over 4

=item create

Creates a Halogen Date object corresponding to the date passed.
$datestring must be in a "raw" timestamp format or one of the
following special names that are synonyms for the current time
and date:

  current, now, today


The "raw" timestamp format is as follows:

  YYYYMMDDHHMMSS


Accepts: $datestring

Returns: $Epromo::Date::Class

=item parse_date

Readable, sane datetime parts for the $datestring passed.

Accepts: $datestring

Returns: $year, $month, $day, $hour, $minute, $second

=item parse_datetime

Readable, sane datetime parts for the $datetimestring passed.

Accepts: $datetimestring

Returns: $year, $month, $day, $hour, $minute, $second

=item valid_date

Determines whether the passed $datestring or date part values
represent a valid date.

If $bool is true, $error_string should contain descriptive
text as to what was wrong with the date.

Accepts: $datestring | $year, $month, $day

Returns: $bool, $error_string

=item is_leap

Determines whether the specified $year is a leap year or not.

Accepts: $year

Returns: $bool

=item today_or_later

Determines whether the specified $datestring is on today or later.

Accepts: $datestring

Returns: $bool

=item now_or_later

Determines whether the specified $datestring is on now or later. Like today_or_later, but also compares hours/mins/sec.

Accepts: $datestring or $Epromo::Date::Class

Returns: $bool

=item get_today_datetime

The current date and time.

Returns: $datetimestring

=item get_today

The current date in YYYY-MM-DD format.

Returns: $datestring

=item get_next_months_from_today

$num months in the format of YYYY-MM from today.

Returns: @monthlist

=item get_next_months

Accepts: $num, $year, $month

Returns: @monthlist

=item day_of_week

The numeric day of the week for $month/$day/$year.

Accepts: $year, $month, $day

Returns: $dayofweek

=item days_since_1_bc

Number of days since 1 BC.

Accepts: $year, $month, $day

Returns: $number_of_days

=item day_of_year

What day in the year is it?

Accepts: $year, $month, $day

Returns: $day_number

=item days_in

Number of days in the specified $month for the specified $year.

Accepts: $year, $month

Returns: $number_of_days

=item month_name

Long name for the month specified by $month_number.

Accepts: $month_number

Returns: $month_name

=item days_between

Returns the number of days between the 2 given dates. Note that this does include one of the boundry dates, so asking
for the days between the 5th and the 10th will return 5, not 4.

Accepts: $Epromo::Date::Class, $Epromo::Date::Class

Returns: $integer

=item newer_than

Returns true if the first date is more recent than the second date. Ie, 2004-01-01 is newer than a 1997-01-01.

Accepts: $Epromo::Date::Class[new], $Epromo::Date::Class[old]

Returns: $bool

=item older_than

Returns true if the first date is older than the second date. Ie, 1492-01-01 is older than a 1997-01-01.
Uses newer_than.

Accepts: $Epromo::Date::Class[old], $Epromo::Date::Class[new]

Returns: $bool

=back

=head1 AUTHOR

Tyler Bird, E<lt>birdty@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bibliopolis

=cut
