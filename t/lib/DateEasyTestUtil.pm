package DateEasyTestUtil;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw< compare_times is_true is_false >;

use Carp;
use Test::More;
use Test::Builder;


my %LOCAL_FLAG = ( local => 1, UTC => 0, GMT => 0 );
my %TIME_FMT   = ( 'Date::Easy::Date' => '%Y-%m-%d', 'Date::Easy::Datetime' => '%Y-%m-%d %H:%M:%S.000 %Z', );

sub _fmt_time
{
	my ($obj, $fmt) = @_;
	my $formatted = $obj->strftime($fmt);
	if (my $subsecond = $obj->epoch - int($obj->epoch))
	{
		$formatted =~ s/\.000/sprintf("x%3.3f", $subsecond)/e;
	}
	return $formatted;
}

sub compare_times
{
	my $obj = shift;
	my $fmt = $TIME_FMT{ ref $obj };
	my $testname = pop;
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
		croak("illegal number of arguments to compare_times: must be either 3 or 4 (not " . (@_ + 2) . ")");
	}

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is _fmt_time($obj, $fmt), $expected, $testname;
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
