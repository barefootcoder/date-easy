use Test::Most 0.25;

use Date::Easy;
use Time::Piece;


my $t;
lives_ok { $t = Date::Easy::Datetime->new } "basic ctor call";
isa_ok $t, 'Date::Easy::Datetime', 'ctor with no args';
isa_ok $t, 'Time::Piece', 'inheritance test';

# this is mostly unnecessary, because it tests Time::Piece moreso than Date::Easy::Datetime
# but at least it guarantees that we don't bork anything that's already working
my @tvals = localtime $t->epoch;
is $t->sec,   $tvals[Time::Piece::c_sec],         "default ::Datetime has today's seconds";
is $t->min,   $tvals[Time::Piece::c_min],         "default ::Datetime has today's minutes";
is $t->hour,  $tvals[Time::Piece::c_hour],        "default ::Datetime has today's hour";
is $t->mday,  $tvals[Time::Piece::c_mday],        "default ::Datetime has today's day";
is $t->_mon,  $tvals[Time::Piece::c_mon],         "default ::Datetime has today's month";
is $t->year,  $tvals[Time::Piece::c_year] + 1900, "default ::Datetime has today's year";
is $t->_wday, $tvals[Time::Piece::c_wday],        "default ::Datetime has today's weekday";
is $t->yday,  $tvals[Time::Piece::c_yday],        "default ::Datetime has today's day of year";
is $t->isdst, $tvals[Time::Piece::c_isdst],       "default ::Datetime has today's DST flag";

# We'd like to test equivalence between the following 3 things.
# Unfortunately, we have no way to guarantee that the clock doesn't rollover to a new second in
# between assigning two of them.  So we're going to try up to, say, 10 times.  It's probably safe to
# say after that many attempts any continued discrepancy is not due to random chance.
my ($now_ctor, $now_func, $now_time);
my $success = 0;
for (1..10)
{
	$now_ctor = Date::Easy::Datetime->new;
	$now_func = now;
	$now_time = time;
	if ($now_ctor->epoch == $now_func->epoch && $now_func->epoch == $now_time)
	{
		$success = 1;
		last;
	}
}
is $success, 1, "now function matches default ctor matches return from time()"
	or diag("ctor: ", $now_ctor->epoch, " func: ", $now_func->epoch, " time: ", $now_time);


# with 6 args, ctor should just build that date

my $FMT = '%Y%m%d%H%M%S';
my @SEXTUPLE_ARGS = qw< 19940203103223 20010905134816 19980908170139 19691231235959 20520229000000 >;
foreach (@SEXTUPLE_ARGS)
{
	my @args = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;
	s/^0// foreach @args;							# more natural, and avoids any chance of octal number errors
	$t = Date::Easy::Datetime->new(@args);
	is $t->strftime($FMT), $_, "successfully constructed (6args): $_";
}


# 1 arg should be treated as epoch seconds

foreach ("12/31/2009", "2/29/2000 2:28:09PM",
		"10/14/1066 09:00:00 GMT", "10/26/1881 15:00:00 MST", "3/31/1918 03:00:00 EDT")
{
	use Time::ParseDate;
	my $t = parsedate($_);
	isnt $t, undef, "sanity check: can parse $_";

	my $dt = Date::Easy::Datetime->new($t);
	is $dt->epoch, $t, "successfully constructed (1arg): $t";
}


# other numbers of args should be errors

foreach (2,3,4,5,7)
{
	my @args = (1) x $_;
	throws_ok { Date::Easy::Datetime->new(@args) } qr/Illegal number of arguments/, "proper failure on $_ args";
}


# make sure we return a proper object even in list context
my @t = Date::Easy::Datetime->new;
is scalar @t, 1, 'ctor not returning multiple values in list context';
isa_ok $t[0], 'Date::Easy::Datetime', 'ctor in list context';


done_testing;
