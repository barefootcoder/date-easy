package DateEasyTestUtil;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw< compare_times >;

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
