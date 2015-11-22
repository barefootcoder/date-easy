use Test::Most 0.25;

use Date::Easy;

use Date::Parse;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateParseTests qw< %DATE_PARSE_TESTS >;


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
foreach (keys %DATE_PARSE_TESTS)
{
	lives_ok { $t = date($_) } "parse survival: $_";
	# figure out what the proper date *should* be by dropping any timezone specifier
	(my $proper = $_) =~ s/ ( [+-] \d{4} | [A-Z]{3} | [+-] \d{4} \h \( [A-Z]{3} \) | Z ) $//x;
	is $t->strftime($FMT), Time::Piece->_mktime(str2time($proper), 1)->strftime($FMT), "successful parse: $_"
			or diag("compared against parse of: $proper");
}


done_testing;
