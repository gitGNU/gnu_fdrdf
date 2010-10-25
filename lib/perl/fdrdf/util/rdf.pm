### rdf.pm --- FDRDF: RDF utilities  -*- Perl -*-

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

package fdrdf::util::rdf;

use strict;
use warnings;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    ## set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw (node_for_sparql
                  query_ask_true_relation
                  query_true_relation
                  query_transform);
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();
}

### Utility

sub node_for_sparql {
    my ($node) = @_;

    die ()
        if ($node->is_blank ());

    ## .
    return ($node->is_resource ()
            ? ("<"  . $node->uri ()->as_string () . ">")
            : ("\"" . $node->literal_value ()     . "\""
               . (defined ($node->literal_datatype ())
                  ? ("^^<"
                     . $node->literal_datatype ()->as_string ()
                     . ">")
                  : "")));
}

### SPARQL Constructors

sub query_true_relation_1 {
    my ($relation) = @_;
    ## FIXME: should also accept strings
    my $relation_s
        = node_for_sparql ($relation);

    ## .
    return
        (""
         . "WHERE {\n"
         . "  ?s " . $relation_s . " true .\n"
         . "}\n");
}

sub query_ask_true_relation {
    my $q_s
        = ("ASK\n"
           . query_true_relation_1 (@_));
    ## .
    new RDF::Redland::Query ($q_s, undef, undef, "sparql");
}

sub query_true_relation {
    my $q_s
        = ("SELECT ?s\n"
           . query_true_relation_1 (@_));
    ## .
    new RDF::Redland::Query ($q_s, undef, undef, "sparql");
}

### Query application

sub query_transform {
    my ($query, $from, $to) = @_;
    my $results
        = $from->query_execute ($query);
    my $stream
        = $results->as_stream ();

    if ($stream->end ()) {
        ## .
        return 0;
    }

    $to->add_statements ($stream);
    ## .
    1;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## outline-regexp: "###"
## End:
### rdf.pm ends here
