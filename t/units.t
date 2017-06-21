use Test::Most 0.25;

use Date::Easy;


my @units = qw< seconds minutes hours days weeks months years >;
foreach (@units)
{
	my $unit_func = \&{ $_ };
	my $unit = $unit_func->();

	(my $singular = $_) =~ s/s$//;
	is $unit, "1 $singular", "singular version works: $_";

	my $multiple;
	lives_ok { $multiple = $unit * 4 } "multiplication works: $_";
	is $multiple, "4 $_", "plural version works: $_";

	throws_ok { $unit * 1.5   } qr/can only do integer math/, "multiplication rejects floating point: $_";
}


done_testing;
