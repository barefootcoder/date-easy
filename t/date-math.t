use Test::Most 0.25;

use Date::Easy;


my $FMT = '%m/%d/%Y';


# simple math stuff first

my $d = date("2001-01-04");
is $d->strftime($FMT), '01/04/2001', 'sanity check: base date';

my $d2 = $d + 1;
isa_ok $d2, 'Date::Easy::Date', 'object after addition';
is $d2->strftime($FMT), '01/05/2001', 'simple addition test';

$d2 = $d - 1;
isa_ok $d2, 'Date::Easy::Date', 'object after subtraction';
is $d2->strftime($FMT), '01/03/2001', 'simple subtraction test';


# slightly more complex
# let's cross some month and year boundaries

$d2 = $d + 30;
is $d2->strftime($FMT), '02/03/2001', 'math across month boundary';

$d2 = $d - 5;
is $d2->strftime($FMT), '12/30/2000', 'math across year boundary';


done_testing;
