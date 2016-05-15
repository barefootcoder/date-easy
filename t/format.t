use Test::Most 0.25;

use Date::Easy;


# test date: 3 Feb 2001, 04:05:06
my $dt = Date::Easy::Datetime->new(2001, 2, 3, 4, 5, 6);
# epoch works out to:
my $epoch = 981201906;
# dow is Sat


# just a few simple formats
# Note: Do not use anything locale specific (e.g. %b, %a, etc), as that would cause spurious
# failures for people whose locale is different from ours.
my %FORMATS =
(
	"%Y/%m/%d %H:%M:%S"		=>	"2001/02/03 04:05:06",
	"%l:%M:%S%p"			=>	" 4:05:06AM",
	"%u"					=>	"6",
	"%s"					=>	$epoch,
);

foreach (keys %FORMATS)
{
	is $dt->strftime($_), $FORMATS{$_}, "strftime format: $_";
}


done_testing;
