package Date::Easy::Datetime;

use strict;
use warnings;
use autodie;

# VERSION

use Exporter;
use parent 'Exporter';
our @EXPORT_OK = qw< datetime now >;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use parent 'Time::Piece';

use Time::Local;


##############################
# FUNCTIONS (*NOT* METHODS!) #
##############################

sub datetime
{
}

sub now () { Date::Easy::Datetime->new }


#######################
# REGULAR CLASS STUFF #
#######################

sub new
{
	my $class = shift;

	my $t;
	if (@_ == 0)
	{
		$t = time;
	}
	elsif (@_ == 6)
	{
		my ($y, $m, $d, $H, $M, $S) = @_;
		--$m;										# timelocal/timegm will expect month as 0..11
		$t = timelocal($S, $M, $H, $d, $m, $y);
	}
	elsif (@_ == 1)
	{
		$t = shift;
	}
	else
	{
		die("Illegal number of arguments to datetime()");
	}

	return $class->_mktime($t, 1);
}
