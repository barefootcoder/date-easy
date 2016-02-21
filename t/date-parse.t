use Test::Most 0.25;

use Date::Easy;

use Time::Local;
use Date::Parse;
use Time::ParseDate;

use List::Util 1.29 qw< pairs >;					# minimum version for pairs

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateParseTests qw< %DATE_PARSE_TESTS _date_parse_remove_timezone >;
use TimeParseDateTests qw< @TIME_PARSE_DATE_TESTS >;


my $FMT = '%Y-%m-%d';


# first go through stuff we handle specially: integers which may or not be interprested as epoch
# seconds, or else might be a datestring (that is, YYYYMMDD).

my %TEST_DATES =
(
	1426446360		=>	'2015-03-15',				# simple epoch
	20120930		=>	'2012-09-30',				# simple datestring
	29000000		=>	'1970-12-02',				# epoch (too big to be a datestring)
	28991231		=>	'2899-12-31',				# datestring (upper bound)
	10000101		=>	'1000-01-01',				# datestring (lower bound)
	9999999			=>	'1970-04-26',				# epoch (too small to be a datestring)
	-99590400		=>	'1966-11-05',				# epoch (negative)
);

my $t;
foreach (keys %TEST_DATES)
{
	lives_ok { $t = date($_) } "parse survival: $_";
	is $t->strftime($FMT), $TEST_DATES{$_}, "successful parse: $_";
}


# now things which should throw errors

my %BAD_DATES =
(
	28999999		=>	qr/Illegal date/,			# looks like a datestring, but not valid date
	10000000		=>	qr/Illegal date/,			# looks like a datestring, but not valid date
);

foreach (keys %BAD_DATES)
{
	throws_ok { date($_) } $BAD_DATES{$_}, "found error: $_";
}


# now rifle through everything that str2time can handle

# If our invocation of str2time (or, more accurately, str2time's guts) fails, our fallback will be
# such that it will just pass the parsing on to parsedate, which might very well succeed.  However,
# for this loop, str2time should *not* fail, so we need to consider a parsedate success as a test
# failure.  In order to achieve this, we're going to wrap Date::Easy::Date::_parsedate with a local
# closure that notifies us if the fallback triggers.
my $using_fallback;
{
	no warnings 'redefine';
	*Date::Easy::Date::_parsedate_orig = \&Date::Easy::Date::_parsedate;
	*Date::Easy::Date::_parsedate = sub { $using_fallback = 1; &Date::Easy::Date::_parsedate_orig };
}

foreach (keys %DATE_PARSE_TESTS)
{
	$using_fallback = 0;							# always reset this before calling date() (see above)
	lives_ok { $t = date($_) } "parse survival: $_";
	# figure out what the proper date *should* be by dropping any timezone specifier
	my $proper = _date_parse_remove_timezone($_);
	is $t->strftime($FMT), Time::Piece->_mktime(str2time($proper), 1)->strftime($FMT), "successful parse: $_"
			or diag("compared against parse of: $proper");
	is $using_fallback, 0, "parsed $_ without resorting to fallback";
}
# could undo our monkey patch here, but it isn't hurting anything, and we might find it useful later


# a few basic tests for the parsedate side of it

my $tomorrow = today + 1;
$t = date("tomorrow");
is $t->strftime($FMT), $tomorrow->strftime($FMT), "successful parse: tomorrow";

# this one is known to be unparseable by str2time()
# (taken from MUIR/Time-ParseDate-2013.1113/t/datetime.t)
$t = date('950404 00:22:12 "EDT');
is $t->strftime($FMT), '1995-04-04', "successful parse: funky datestring plus time";


# now rifle through everything that parsedate can handle

foreach (pairs @TIME_PARSE_DATE_TESTS)
{
	my ($str, $orig_t, @args) = ( $_->key, @{ $_->value } );
	# anything which str2date can successfully parse would be handled by it, not parsedate
	# so skip those
	next if defined str2time($str);

	# If parsedate() won't parse this (e.g. because it requires PREFER_PAST or PREFER_FUTURE, which
	# we're not going to supply, or because it's just expected to fail), skip this test.
	next unless defined parsedate($str);

	# figure out what the proper date *should* be by dropping any timezone specifier
																		# matching code from Time/ParseDate.pm:
	my $break = qr{(?:\s+|\Z|\b(?![-:.,/]\d))};												# line 67
	(my $proper = $str) =~ s/ (
					[+-] \d\d:?\d\d \( "? ( [A-Z]{1,4}[TCW56] | IDLE ) \)					# lines 424-435
				|	GMT \s* ( [-+]\d{1,2} )													# line 441
				|	( GMT \s* )? [+-] \d\d:?\d\d											# line 452
				|	"? ( [A-Z]{1,4}[TCW56] | IDLE )											# line 457
			) $break //x;

	# Assigning this to a scalar forces scalar context, obviously.  However, if you try to put this
	# directly into a call to `is` or `_mktime` or somesuch, you would have to use `scalar`.  Remember,
	# parsedate called in array context returns the "remainder" of the parsed string (which would
	# always be undef, which could wreak havoc with a call, particularly one to _mktime).
	my $parsedate_secs = parsedate($proper, DATE_REQUIRED => 1);

	# If the only thing that would cause parsedate to fail is not having a date (e.g. "now +4 secs"),
	# let's test that and make sure date() fails as well.
	unless (defined $parsedate_secs)
	{
		throws_ok { date($str) } qr/Illegal date/, "correctly refused to parse: $str";
		next;
	}

	# if we got this far, the parse shouldn't blow up
	lives_ok { $t = date($str) } "parse survival: $str";

	# and the date generated should be the same date parsedate would generate without the timezone
	is $t->strftime($FMT), Time::Piece->_mktime($parsedate_secs, 1)->strftime($FMT), "successful parse: $str"
			or diag("compared against parse of: $proper");

	# now make sure that our fiddling with the guts of parsedate didn't do any permanent damage
	# (don't forget that the `scalar` is mandatory here)
	is scalar parsedate($str, @args), $orig_t, "can still use parsedate normally ($str)";
}


# insure we properly handle a time of 0 (i.e. the exact day of the epoch)
my $local_epoch = timelocal gmtime 0;				# for whatever timezone we happen to be in
foreach (
			$local_epoch,							# handled internally (epoch seconds)
			'19700101',								# handled internally (compact datestring)
			'1970-1-1-00:00:00 GMT',				# handled by Date::Parse
			'1970/01/01 foo',						# handled by Time::ParseDate (zero in UTC)
		)
{
	is date($_)->strftime($FMT), Time::Piece->_mktime(0, 0)->strftime($FMT), "successful 0 parse: $_";
}

# we need to deal with both 0 UTC and whatever actual day 0 local time is
# (however, local time can only return 0 differently than UTC in the case of Time::ParseDate)
foreach (
			# handled by Time::ParseDate (zero in localtime)
			Time::Piece->_mktime(0, 1)->strftime("%Y/%m/%d %H:%M:%S foo"),
		)
{
	is date($_)->strftime($FMT), Time::Piece->_mktime(0, 1)->strftime($FMT), "successful local 0 parse: $_";
}


done_testing;
