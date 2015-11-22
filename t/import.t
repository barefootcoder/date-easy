use Test::Most 0.25;


package Test::T01;
use Test::Most 0.25;

use Date::Easy;

lives_ok { today() } 'Date::Easy imports today';
lives_ok { date(time) } 'Date::Easy imports date';


package Test::T02;
use Test::Most 0.25;

use Date::Easy::Date;

throws_ok { today() } qr/Undefined subroutine/, 'Date::Easy::Date does not import today';
throws_ok { date(time) } qr/Undefined subroutine/, 'Date::Easy::Date does not import date';


package Test::T03;
use Test::Most 0.25;

use Date::Easy::Date qw< today date >;

lives_ok { today() } 'Date::Easy::Date can import today';
lives_ok { date(time) } 'Date::Easy::Date can import date';


package main;										# back to main, or else done_testing won't be found

done_testing;
