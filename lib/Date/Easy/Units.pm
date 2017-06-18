package Date::Easy::Units;

use strict;
use warnings;
use autodie;

# VERSION

use Carp;

use Exporter;
use parent 'Exporter';
my @date_units = qw< days weeks months years >;
my @datetime_units = (qw< seconds minutes hours >, @date_units);
our @EXPORT_OK = @datetime_units;
our %EXPORT_TAGS = ( date => \@date_units, datetime => \@datetime_units, all => \@EXPORT_OK );


##############################
# FUNCTIONS (*NOT* METHODS!) #
##############################

sub seconds () { __PACKAGE__->new("seconds") }
sub minutes () { __PACKAGE__->new("minutes") }
sub hours   () { __PACKAGE__->new("hours")   }
sub days    () { __PACKAGE__->new("days")    }
sub weeks   () { __PACKAGE__->new("weeks")   }
sub months  () { __PACKAGE__->new("months")  }
sub years   () { __PACKAGE__->new("years")   }


#######################
# REGULAR CLASS STUFF #
#######################

sub new
{
	my ($class, $unit, $qty) = @_;
	if (defined $qty)
	{
		croak("can only do integer math") unless $qty == int($qty);
	}
	else
	{
		$qty = 1;
	}
	return bless { qty => $qty, unit => $unit }, $class;
}


sub to_string
{
	my $self = shift;

	my $qty  = $self->{qty};
	my $unit = $self->{unit};
	$unit =~ s/s$// if $qty == 1;
	return "$qty $unit";
}


########################
# OVERLOADED OPERATORS #
########################

use overload
	'""'	=>	sub { shift->to_string },
	'cmp'	=>	sub { $_[0]->to_string cmp $_[1] },

	'*'		=>	sub { __PACKAGE__->new( $_[0]->{unit}, $_[0]->{qty} * $_[1] ) },
;



1;



# ABSTRACT: units objects for easy date/datetime math
# COPYRIGHT


=head1 SYNOPSIS

    use Date::Easy::Units ':all';

    my @units = (seconds, minutes, hours, days, weeks, months, years);
    my $quarters = 3 * months;          # set the quantity (default: 1)
    my $year1 = 4 * $quarters;          # a year is 12 months
    my $year2 = 1 * years;              # `1 *' is redudant, but clearer

    # units stringify as you'd expect
    say 3 * weeks;
    # prints "3 weeks"
    say 1 * hours;
    # prints "1 hour"

    # $year1 and $year2 are _conceptually_ equal
    today + $year1 == today + $year2;   # true
    # but not _actually_ equal
    $year1 ne $year2;                   # because "12 months" ne "1 year"


=head1 DESCRIPTION

Date::Easy::Units objects represent a quantity and a unit: seconds, minutes, hours, days, weeks,
months, or years.  The default quantity is 1, but you can multiply that by an integer (positive or
negative) to get a different quantity.  Multiplying a quantity other than 1 by an integer does what
you expect.

You I<could> create a units object the "normal" OOP way:

    my $s1 = Date::Easy::Units->new("seconds");
    my $m4 = Date::Easy::Units->new("minutes", 4);

But you will rarely do it that way.  More likely you'll just use the exportable (but not exported by
default) functions:

    my $s1 = seconds;
    my $m4 = 4 * minutes;

Units objects are immutable.

See L<Date::Easy> for more general usage notes.


=head1 USAGE

=head2 Import Parameters

You can request only certain of the constructors below be exported, or use C<:all> to get them all.

=head2 Constructors

=head3 seconds

=head3 minutes

=head3 hours

=head3 days

=head3 weeks

=head3 months

=head3 years

Each constructor returns a units object with the specified unit and a quantity of 1.  Multiply them
by an integer to get a different quantity.

=head3 new

Takes either one or two arguments: unit name (required) and quantity (optional).  Most of the time
you will not use this.

=head2 Other Methods

=head3 to_string

Does the work of the overloaded stringification, in case you ever want to call it explicitly.

=head2 Overloaded Operators

=head3 Multiplication

Returns a new units object with the same unit and a quantity equal to the existing quantity times
the operand.  Thus, the operand should be an integer.  Multiplying by a floating point causes an
exception.  Multiplying by a string likely just gets you 0 (depending on whether your string can be
interpreted as a number), and probably a warning (if you have warnings turned on (which you
should)).


=head1 BUGS, CAVEATS and NOTES

This:

    use Date::Easy::Units ':all';

    say -1 * seconds;

prints "-1 seconds" as opposed to "-1 second."  Whether or not you consider that a bug depends on
where your concepts of arithmetic and grammar intersect.

See also L<Date::Easy/"Limitations">.
