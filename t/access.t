use Test::Most 0.25;

use Date::Easy 'GMT';								# makes the epoch predictable


# test datetime: 3 Feb 2001, 04:05:06
my $dt = Date::Easy::Datetime->new(2001, 2, 3, 4, 5, 6);
# epoch works out to:
my $epoch = 981173106;

# basic accessors
is $dt->year,     2001,    "year accessor is correct for datetime";
is $dt->month,       2,   "month accessor is correct for datetime";
is $dt->day,         3,     "day accessor is correct for datetime";
is $dt->hour,        4,    "hour accessor is correct for datetime";
is $dt->minute,      5,  "minute accessor is correct for datetime";
is $dt->second,      6,  "second accessor is correct for datetime";
is $dt->epoch,  $epoch,   "epoch accessor is correct for datetime";

# try every day of the week, to insure we're getting the proper range
# start with the first Monday in 2000 (Jan 3rd)
for (1..7)
{
	$dt = Date::Easy::Datetime->new(2000, 1, $_ + 2, 0, 0, 0);
	is $dt->day_of_week, $_, "dow accessor is correct for datetime on " . $dt->strftime('%a');
}

# make sure we try the full range of quarters as well
# in this case, we'll just try every month
my %MONTH_TO_QUARTER =
(
	 1	=>	1,		 2	=>	1,		 3	=>	1,
	 4	=>	2,		 5	=>	2,		 6	=>	2,
	 7	=>	3,		 8	=>	3,		 9	=>	3,
	10	=>	4,		11	=>	4,		12	=>	4,
);

for (sort { $a <=> $b } keys %MONTH_TO_QUARTER)
{
	$dt = Date::Easy::Datetime->new(2000, $_, 1, 0, 0, 0);
	is $dt->quarter, $MONTH_TO_QUARTER{$_}, "quarter accessor is correct for datetime in " . $dt->strftime('%b');
}


done_testing;
