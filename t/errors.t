use Test::Most 0.25;

use Date::Easy;


# invalid dates

my %BAD_DATES =
(
	28999999		=>	qr/Illegal date/,			# looks like a datestring, but not valid date
	10000000		=>	qr/Illegal date/,			# looks like a datestring, but not valid date
	'06:43am'		=>	qr/Illegal date/,			# only a time
	bmoogle			=>	qr/Illegal date/,			# just completely bogus
);

my $t;
foreach (keys %BAD_DATES)
{
	throws_ok { $t = date($_) } $BAD_DATES{$_}, "found date error: $_" or diag("got date: $t");
}


# invalid datetimes

foreach (qw<
				bmoogle
		>)
{
	throws_ok { $t = datetime($_) } qr/Illegal datetime/, "found datetime error: $_" or diag("got datetime: $t");
}


# bad number of args when constructing a datetime

foreach (3,4,5,8,9)
{
	my @args = (1) x $_;
	throws_ok { Date::Easy::Datetime->new(@args) } qr/Illegal number of arguments/,
			"proper datetime ctor failure on $_ args";
}


# bad zone specifier when constructing a datetime

throws_ok { Date::Easy::Datetime->new(bmoogle => 0) } qr/Unrecognized timezone specifier/,
		"proper failure for bogus zonespec";


done_testing;
