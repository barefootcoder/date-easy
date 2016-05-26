use Test::Most 0.25;

use Date::Easy;


# test date: 3 Feb 2001, 04:05:06
my $dt = Date::Easy::Datetime->new(UTC => 2001, 2, 3, 4, 5, 6);
# epoch works out to:
my $epoch = 981173106;
# dow is Sat


# just a few simple formats
# Note: Do not use anything locale specific (e.g. %b, %a, etc), as that would cause spurious
# failures for people whose locale is different from ours.
my %FORMATS =
(
	"%Y/%m/%d %H:%M:%S"		=>	"2001/02/03 04:05:06",
	"%l:%M:%S%p"			=>	" 4:05:06AM",
	"%u"					=>	"6",
	"%s %%s %s"				=>	"$epoch %s $epoch",
);

foreach (keys %FORMATS)
{
	is $dt->strftime($_), $FORMATS{$_}, "strftime format: $_";
}

# make sure I didn't bork the empty format call
# note also that I avoid the locale-specific parts by using a regex with \w+
my $str;
warning_is { $str = $dt->strftime } undef, "no uninitialized warning on empty format";
like $str, qr/^\w+, 03 \w+ 2001 04:05:06 UTC$/, "empty format produces default format";


done_testing;
