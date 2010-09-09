### test.pm --- FDRDF: test module  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::module::test;

use strict;
use warnings;

use RDF::Redland;

use fdrdf::module;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw (&new);
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();
}

sub test {
    my ($relation, $model, $subject, $io) = @_;
    print STDERR "test: " . join (", ", @_) . "\n";

    my $s = $subject;
    my $p = $relation;
    my $o = new RDF::Redland::LiteralNode ("yes");

    my $st = new RDF::Redland::Statement ($s, $p, $o);

    $model->add_statement ($st);
}

sub new {
    my ($pkg, $e_ref, $config) = @_;
    my $relation_uri_s
        = ("uuid:35cef816-b42f-11df-84e9-4040a5e6bfa3#"
	   . "fdrdf::modules::test");
    my $relation
	= new RDF::Redland::URINode ($relation_uri_s);
    my @handle = (\&test, $relation);
    module_add_to_tag ($e_ref, "io", \@handle);

    ## .
    return $e_ref;
}

1;

### test.pm ends here
