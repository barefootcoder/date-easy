package DateEasyTestUtil;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw< compare_times generate_times_and_compare is_true is_false >;

use Carp;
use Test::More;
use Test::Builder;


# Two functions to compare times.  See below for full details.

my %LOCAL_FLAG = ( local => 1, UTC => 0, GMT => 0 );
my %TIME_FMT   = ( 'Date::Easy::Date' => '%Y-%m-%d', 'Date::Easy::Datetime' => '%Y-%m-%d %H:%M:%S.000 %Z', );

sub _fmt_time
{
	my ($obj, $fmt) = @_;
	my $formatted = $obj->strftime($fmt);
	if (my $subsecond = $obj->epoch - int($obj->epoch))
	{
		$formatted =~ s/\.000/sprintf(".%3.3f", $subsecond)/e;
	}
	return $formatted;
}

sub _render_times
{
	my $obj = shift;
	my $fmt = $TIME_FMT{ ref $obj };
	my $err_tag = pop;
	my $expected;
	if (@_ == 1)
	{
		$expected = shift;
		$expected = _fmt_time($expected, $fmt) if ref $expected;
	}
	elsif (@_ == 2)
	{
		my ($zone, $epoch) = @_;
		# `scalar` below required because _mktime in list context returns list of time components
		$expected = _fmt_time(scalar Time::Piece->_mktime($epoch, $LOCAL_FLAG{$zone}), $fmt);
	}
	else
	{
		croak("illegal number of arguments $err_tag\n    (2nd time seems to consist of " . scalar @_ . " args)");
	}

	my $got = _fmt_time($obj, $fmt);
	return ($got, $expected);
}

# compare_times
#
# Call in one of two ways:
#
# 		compare_times( $date_or_datetime, $date_or_datetime_or_time_piece, $test_name );
# 		compare_times( $date_or_datetime, $zone_spec => $epoch_seconds,    $test_name );
#
# This will convert both date(time)s to strings, using a format based on the type (Date::Easy::Date
# or Date::Easy::Datetime) of the first argument.  Comparisons are done with `is` and reported from
# the persepctive of the caller.
sub compare_times
{
	my $testname = pop;
	my $caller = (caller(0))[3];
	my ($got, $expected) = _render_times(@_, "to $caller");

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is $got, $expected, $testname;
}

# generate_times_and_compare
#
# Call like so:
#
# 		generate_times_and_compare { $obj, $other_obj      } $test_name;
# 		generate_times_and_compare { $obj, $spec => $epoch } $test_name;
#
# except you probably want your code block to generate at least one of the date(times)s on the fly.
# If not, you could just call `compare_times` (above).  But if there's any chance that the system
# clock rolling over to a new second between assigning the two objects would cause them not to
# match, use this function and allow the code block to generate the objects.  The code block will be
# called up to 10 times: if the two objects match at any point, it bails out and records it as a
# passing test.  If, after 10 tries, they never match, that is recorded as a failing test, and
# reported from the perspective of the caller.
sub generate_times_and_compare (&$)
{
	my ($sub, $testname) = @_;

	# Try to generate and compare up to 10 times.  We're bound to manage to get both times within
	# the same second at least once after that many tries.
	my ($got, $expected);
	my $caller = (caller(0))[3];
	for (1..10)
	{
		($got, $expected) = _render_times($sub->(), "back from coderef in $caller");
		last if $got eq $expected;
	}

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is $got, $expected, $testname;
}


# These are my handy-dandy `is_true` and `is_false` functions that I wrote several years back,
# because `ok` doesn't give me enough info on failure, and `is` can't distinguish Perl's several
# false values or its infinitude of true values.  Maybe I will see if I can get these accepted into
# Test::More (or Test::Most, perhaps) one day.

sub is_true ($;$)
{
	my ($value, $testname) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	ok $value, $testname or diag("         got: $value\n    expected: something true\n");
}

sub is_false ($;$)
{
	my ($value, $testname) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	ok !$value, $testname or diag("         got: $value\n    expected: something false\n");
}
