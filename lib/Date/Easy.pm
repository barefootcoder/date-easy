package Date::Easy;

use strict;
use warnings;
use autodie;

# VERSION

use Date::Easy::Date ();
use Date::Easy::Datetime ();

use Exporter;
use parent 'Exporter';
our @EXPORT = ( @Date::Easy::Date::EXPORT_OK, @Date::Easy::Datetime::EXPORT_OK, );


sub import
{
	Date::Easy::Date->import(':all');
	Date::Easy::Datetime->import(':all', @_[1..$#_]);
	@_ = (shift);
	goto &Exporter::import;
}


1;

# ABSTRACT: easy dates with Time::Piece compatibility
# COPYRIGHT


=head1 DESCRIPTION

More complete docs coming soon.  For now, refer to my blog series
I<L<A Date with CPAN|http://blogs.perl.org/users/buddy_burden/2015/09/a-date-with-cpan-part-1-state-of-the-union.html>>.
