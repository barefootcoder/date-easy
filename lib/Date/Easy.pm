package Date::Easy;

use strict;
use warnings;
use autodie;

# VERSION

use Date::Easy::Date ':all';

use Exporter;
use parent 'Exporter';
our @EXPORT = @Date::Easy::Date::EXPORT_OK;


1;

# ABSTRACT: easy dates with Time::Piece compatibility
# COPYRIGHT

__END__
