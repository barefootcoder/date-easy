package Date::Easy::Date;

use strict;
use warnings;
use autodie;

# VERSION

use Exporter;
use parent 'Exporter';
our @EXPORT_OK = qw< date today >;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use parent 'Date::Easy::Datetime';

use Carp;
use Time::Local;
use Scalar::Util 'blessed';


##############################
# FUNCTIONS (*NOT* METHODS!) #
##############################


sub date
{
	my $date = shift;
	if ( $date =~ /^-?\d+$/ )
	{
		if ($date < 29000000 and $date >= 10000000)
		{
			my @time = $date =~ /^(\d{4})(\d{2})(\d{2})$/;
			return Date::Easy::Date->new(@time);
		}
		return Date::Easy::Date->new($date);
	}
	elsif ( $date !~ /\d/ )
	{
		my $time = _parsedate($date);
		croak("Illegal date: $date") unless defined $time;
		return Date::Easy::Date->new($time);
	}
	else
	{
		my ($d, $m, $y) = _strptime($date);
		if (defined $y)													# they're either all defined, or it's bogus
		{
			return Date::Easy::Date->new($y, $m, $d);
		}
		else
		{
			my $time = _parsedate($date);
			croak("Illegal date: $date") unless defined $time;
			return Date::Easy::Date->new($time);
		}
	}
	die("reached unreachable code");
}

sub today () { Date::Easy::Date->new }


sub _strptime
{
	require Date::Parse;
	# Most of this code is stolen from Date::Parse, by Graham Barr.
	#
	# In an ideal world, I would just use the code from there and not repeat it here.  However, the
	# problem is that str2time() calls strptime() to generate the pieces of a datetime, then does
	# some validation, then returns epoch seconds by calling timegm (from Time::Local) on it.  I
	# don't _want_ to call str2time because I'm just going to take the epoch seconds and turn them
	# back into pieces, so it's inefficicent.  But more importantly I _can't_ call str2time because
	# it convertes to UTC, and I want the pieces as they are relative to whatever timezone the
	# parsed date has.
	#
	# On the other hand, the problem with calling strptime directly is that str2time is doing two
	# things there: the conversion to epoch seconds, which I don't want or need, and the validation,
	# which, it turns out, I *do* want, and need.  For instance, strptime will happily return a
	# month of -1 if it hits a parsing hiccough.  Which then strftime will turn into undef, as you
	# would expect.  But, if you're just calling strptime, that doesn't help you much. :-(
	#
	# Thus, I'm left with 3 possibilities, none of them very palatable:
	# 	#	call strptime, then call str2time as well
	#	#	repeat at least some of the code from str2time here
	#	#	do Something Devious, like wrap/monkey-patch strptime
	# #1 doesn't seem practical, because it means that every string that has to be parsed this way
	# has to be parsed twice, meaning it will take twice as long.  #3 seems too complex--since the
	# call to strptime is out of my control, I can't add arguments to it, or get any extra data out
	# of it, which means I have to store things in global variables, which means it wouldn't be
	# reentrant ... it would be a big mess.  So #2, unpalatable as it is, is what we're going with.
	#
	# Of course, this gives me the opportunity to tweak a few things.  For instance, we can tweak
	# the year value to fix RT/105031 (noted below).  Also, since this is only used by our ::Date
	# class, we don't give a crap about times or timezones, so we can totally ignore those parts.
	# (Well, *almost* totally: we still want to verify that we're getting valid values for them.)
	# Which makes this code actually much smaller than its Date::Parse equivalent.
	#
	# On top of that, this is a tiny bit more efficient.

	my ($str) = @_;

	# don't really care about seconds, minutes, or hours, but need to verify them
	# don't care about timezone at all
	my ($ss,$mm,$hh, $day, $month, $year, undef) = Date::Parse::strptime($str);
	my $num_defined = defined($day) + defined($month) + defined($year);
	return undef if $num_defined == 0;
	if ($num_defined < 3)
	{
		my @lt  = localtime(time);

		$month = $lt[4] unless defined $month;
		$day  = $lt[3] unless defined $day;
		$year = ($month > $lt[4]) ? ($lt[5] - 1) : $lt[5] unless defined $year;
	}
	$year += 1900; ++$month;											# undo timelocal's funkiness
																		# (this also corrects RT/105031)

	return undef unless $month >= 1 and $month <= 12 and $day >= 1 and $day <= 31;
	# we don't actually care about the hours/mins/secs, but if they're illegal, we should still fail
	return undef unless ($hh || 0) <= 23 and ($mm || 0) <= 59 and ($ss || 0) <= 59;
	return ($day, $month, $year);
}


sub _parsedate
{
	require Time::ParseDate;
	my $string = shift;

	# Remove any timezone specifier so we get the date as it was in that timezone.
	# I've gathered up all timezone matching code from Time::ParseDate as of v2015.103.
																		# matching code from Time/ParseDate.pm:
	my $break = qr{(?:\s+|\Z|\b(?![-:.,/]\d))};												# line 67
	$string =~ s/
			(?:
					[+-] \d\d:?\d\d \s+ \( "? (?: [A-Z]{1,4}[TCW56] | IDLE ) \)				# lines 424-435
				|	GMT \s* [-+]\d{1,2}														# line 441
				|	(?: GMT \s* )? [+-] \d\d:?\d\d											# line 452
				|	"? (?: [A-Z]{1,4}[TCW56] | IDLE )										# line 457 (and 695-700)
			) $break //x;

	# We *must* force scalar context.  Remember, parsedate called in list context also returns the
	# "remainder" of the parsed string (which is often undef, which could wreak havoc with a call
	# that incorporates our return value, particularly one to _mktime).
	return scalar Time::ParseDate::parsedate($string, DATE_REQUIRED => 1);
}


#######################
# REGULAR CLASS STUFF #
#######################


sub new
{
	my $class = shift;
	my ($y, $m, $d);
	if (@_ == 3)
	{
		($y, $m, $d) = @_;
		--$m;										# timegm will expect month as 0..11
	}
	else
	{
		my ($time) = @_;
		$time = time unless defined $time;
		if (my $conv_class = blessed $time)
		{
			if ( $time->isa('Time::Piece') )
			{
				($d, $m, $y) = ($time->mday, $time->_mon, $time->year);
			}
			else
			{
				croak("Don't know how to convert $conv_class to $class");
			}
		}
		else
		{
			($d, $m, $y) = (localtime $time)[3..5];	# `Date`s are parsed relative to local time ...
			$y += 1900;								# (timelocal/timegm does odd things w/ 2-digit dates)
		}
	}

	my $truncated_date =
			eval { timegm( 0,0,0, $d,$m,$y ) };		# ... but stored as UTC
	croak("Illegal date: $y/$m/$d") unless defined $truncated_date;
	return $class->_mkdate($truncated_date);
}

sub _mkdate
{
	my ($invocant, $epoch) = @_;
	my $class = ref $invocant || $invocant;
	return bless Date::Easy::Datetime->new(UTC => $epoch), $class;		# always UTC
}


# override addition and subtraction
# numbers added to a ::Date are days

use overload
		'+' => \&add,
		'-' => \&subtract;

sub add
{
	my ($self, $rhs) = @_;

	return $self->_mkdate($self->epoch + 86_400 * $rhs);
}

sub subtract
{
	my ($self, $rhs) = @_;

	return $self->_mkdate($self->epoch - 86_400 * $rhs);
}



1;

# ABSTRACT: easy date class
# COPYRIGHT
