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

use Carp;
use Time::Local;


# this can be modified (preferably using `local`) to use GMT/UTC as the default
# or you can pass a value to `import` via your `use` line
our $DEFAULT_ZONE = 'local';

my %ZONE_FLAG = ( local => 1, UTC => 0, GMT => 0 );


sub import
{
	my @args;
	exists $ZONE_FLAG{$_} ? $DEFAULT_ZONE = $_ : push @args, $_ foreach @_;
	@_ = @args;
	goto &Exporter::import;
}


##############################
# FUNCTIONS (*NOT* METHODS!) #
##############################

sub datetime
{
	my @zonespec = @_ % 2 == 0 ? shift : ();
	my $datetime = shift;
	if ( $datetime =~ /^-?\d+$/ )
	{
		return Date::Easy::Datetime->new(@zonespec, $datetime);
	}
	else
	{
		my $t = _str2time($datetime);
		$t = _parsedate($datetime) unless defined $t;
		croak("Illegal datetime: $datetime") unless defined $t;
		return Date::Easy::Datetime->new( @zonespec, $t );
	}
	die("reached unreachable code");
}

sub now () { Date::Easy::Datetime->new }


sub _str2time
{
	require Date::Parse;
	return &Date::Parse::str2time;
}

sub _parsedate
{
	require Time::ParseDate;
	return scalar &Time::ParseDate::parsedate;
}


#######################
# REGULAR CLASS STUFF #
#######################

sub new
{
	my $class = shift;
	my $zonespec = @_ == 2 || @_ == 7 ? shift : $DEFAULT_ZONE;
	croak("Unrecognized timezone specifier") unless exists $ZONE_FLAG{$zonespec};

	my $t;
	if (@_ == 0)
	{
		$t = time;
	}
	elsif (@_ == 6)
	{
		my ($y, $m, $d, $H, $M, $S) = @_;
		--$m;										# timelocal/timegm will expect month as 0..11
		$t = $zonespec eq 'local' ? timelocal($S, $M, $H, $d, $m, $y) : timegm($S, $M, $H, $d, $m, $y);
	}
	elsif (@_ == 1)
	{
		$t = shift;
	}
	else
	{
		croak("Illegal number of arguments to datetime()");
	}

	return scalar $class->_mktime($t, $ZONE_FLAG{$zonespec});
}


sub is_local {  shift->[Time::Piece::c_islocal] }
sub is_gmt   { !shift->[Time::Piece::c_islocal] }
*is_utc = \&is_gmt;
