### callback.pm --- FDRDF: module to tool API  -*- Perl -*-

### Copyright (C) 2010 Ivan Shmakov

## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.

## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

package fdrdf::callback;

use strict;
use warnings;

use fdrdf::util::rdf;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();
}

sub config {
    my ($self) = @_;
    ## .
    $self->{"config"};
}

sub selected_predicate {
    my ($self) = @_;
    ## .
    $self->{"selected_predicate"};
}

sub selected_sparql {
    my ($self) = @_;
    my $sel_predicate_s
        = node_for_sparql ($self->selected_predicate ());
    my $sel_object_s
        = "true";

    ## .
    return
        ($sel_predicate_s . " " . $sel_object_s);
}

sub new {
    my ($class, %params) = @_;
    my $self = \%params;

    bless ($self, $class);

    ## .
    $self;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### callback.pm ends here
