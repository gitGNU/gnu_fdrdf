### test.pm --- FDRDF: test module  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::module::test;

use strict;
use warnings;

use RDF::Redland;

use fdrdf::proto::io;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter fdrdf::proto::io);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();

    ## URI's and prefixes
    our $module_uri_s
        = "uuid:95ec9414-bbd3-11df-b954-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:35cef816-b42f-11df-84e9-4040a5e6bfa3#";
    our $test_uri_s
        = $desc_prefix . "fdrdf::modules::test";
}

## NB: not an OO method
sub uri_node {
    ## .
    return new RDF::Redland::URINode (@_);
}

sub process_io {
    my ($self, $model, $subject, $io) = @_;

    my $s = $subject;
    my $p = $self->{"rel.test"};
    my $o = new RDF::Redland::LiteralNode ("yes");

    my $st = new RDF::Redland::Statement ($s, $p, $o);

    $model->add_statement ($st);
}

sub new {
    my ($class, $config) = @_;

    our ($module_uri_s, $conf_prefix);
    our ($desc_prefix,  $test_uri_s);
    my $self = {
        "module"    => uri_node ($module_uri_s),
        "conf_pfx"  => $conf_prefix,
        "desc_pfx"  => $desc_prefix
    };
    $self->{"rel.test"} = uri_node ($test_uri_s);

    bless ($self, $class);

    ## .
    $self;
}

1;

### test.pm ends here
