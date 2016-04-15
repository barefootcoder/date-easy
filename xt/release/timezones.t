use Test::Most 0.25;

use Date::Easy;


my $zoneinfo = "/usr/share/zoneinfo";
die("can't find timezone files to test with!") unless -d $zoneinfo;

foreach (`find $zoneinfo -type f`)
{
	chomp;
	s{^$zoneinfo/}{};
	$ENV{TZ} = $_;

	my $td = date("04/95 00:22:12 PDT");
	is join('-', $td->year, $td->mon, $td->mday), '1995-4-1', "simple parse in timezone: $_";
}


done_testing;
