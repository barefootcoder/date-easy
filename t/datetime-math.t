use Test::Most 0.25;

use Date::Easy;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< is_true is_false >;


my $FMT = '%Y/%m/%d %H:%M:%S';

# test datetimes
my $dt1 = datetime("2010-01-01 13:06:00");
my $dt2 = datetime("2010-01-01 13:06:00");
my $dt3 = datetime("2010-01-01 13:06:30");


# comparison operators

is_true $dt1 == $dt2, "datetime equality";
is_true $dt1 != $dt3, "datetime inequality";
is_true $dt1 <  $dt3, "datetime less than";
is_true $dt1 <= $dt2, "datetime less than/equal to";
is_true $dt3 >  $dt1, "datetime greater than";
is_true $dt1 >= $dt2, "datetime greater than/equal to";

is $dt1 <=> $dt2,  0, "datetime spaceship (equals)";
is $dt1 <=> $dt3, -1, "datetime spaceship (less than)";
is $dt3 <=> $dt1,  1, "datetime spaceship (greater than)";


# simple addition / subtraction

is $dt1 + 30, $dt3, "datetimes add seconds";
is $dt3 - 30, $dt1, "datetimes subtract seconds";


# type checks for things
isa_ok $dt1 + 30, 'Date::Easy::Datetime', 'addition result';
isa_ok $dt3 - 30, 'Date::Easy::Datetime', 'subtraction result';


done_testing;
