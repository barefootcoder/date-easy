use Test::Most 0.25;

use Date::Easy;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateParseTests qw< %DATE_PARSE_TESTS >;


# Check to make sure epoch seconds are not pumped through a parser.
# (This somewhat mirrors the first set of tests in t/date.t,
# except we don't have to worry about datestrings.)

my %TEST_DATES =
(
	1426446360		=>	'2015-03-15',				# simple epoch
	-99590400		=>	'1966-11-05',				# epoch (negative)
);

my $t;
foreach (keys %TEST_DATES)
{
	lives_ok { $t = datetime($_) } "parse survival: $_";
	is $t->epoch, $_, "successful parse: $_";
}


foreach (keys %DATE_PARSE_TESTS)
{
	lives_ok { $t = datetime($_) } "parse survival: $_";
	cmp_ok $t ? $t->epoch : undef, '==', local_adjusted($_, $DATE_PARSE_TESTS{$_}), "successful parse: $_";
}


done_testing;


sub local_adjusted
{
	my ($string, $time) = @_;

	# First, figure out whether this datetime needs to be local-adjusted or not.
	# The Parse::Date unit tests did this by knowing how many tests needed to be adjusted and just
	# using a hardcoded number (i.e. the first N tests get adjusted).
	# That seems too fragile to me, so I'm going to use the same method I did when testing `date`:
	# use a regex to figure out whether the string contains a timezone specifier or not.
	# If it does, no adjustment is necessary.
	return $time if $string =~ / ( [+-] \d{1,2} :? \d{2} | [A-Z]{3} (\h+ \d{4})? | [+-] \d{4} \h \( [A-Z]{3} \) | Z ) $/x;

	# This code is lifted from GBARR/TimeDate-1.17/t/getdate.t, lines 177-192.
	# ( https://github.com/gbarr/perl-TimeDate/blob/v1.17/t/getdate.t#L177-L192 )
	# Some changes were made:
	# 	*	The original code adjusted the returned time.  I'm adjusting the expected time instead.
	# 		Because of this, the last line of the original code uses -=; my code uses +=.
	# 	*	The original code takes the localtime and gmtime of the expected time; I use the
	# 		returned time.  Since these are only used for the delta between the two, this shouldn't
	# 		make any difference.  I suppose if the DST cutover time had reached UTC but not the
	# 		local time (or vice-versa?), it _could_, theoretically, maybe?  But that situation
	# 		doesn't seem to exist in the current test data set.
	# Other than that the code is identical.
	my @lt = localtime($time);
	my @gt = gmtime($time);

	my $tzsec = ($gt[1] - $lt[1]) * 60 + ($gt[2] - $lt[2]) * 3600;

	my($lday,$gday) = ($lt[7],$gt[7]);
	if($lt[5] > $gt[5]) {
		$tzsec -= 24 * 3600;
	}
	elsif($gt[5] > $lt[5]) {
		$tzsec += 24 * 3600;
	}
	else {
		$tzsec += ($gt[7] - $lt[7]) * (24 * 3600);
	}
	$time += $tzsec;
	# END STOLEN CODE

	return $time;
}
