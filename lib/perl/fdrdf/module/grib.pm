### grib.pm --- FDRDF: GRIB processing module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::grib;

use strict;
use warnings;

use RDF::Redland;

use fdrdf::proto::io;
use fdrdf::util;
use fdrdf::xfmcache;
use fdrdf::xfmcache::proto;

BEGIN {
    require Exporter;
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = 0.1;
    @ISA = qw (Exporter fdrdf::proto::io fdrdf::xfmcache::proto);
    @EXPORT = qw ();
    @EXPORT_OK = qw ();
    %EXPORT_TAGS = ();

    ## URI's and prefixes
    our $module_uri_s
        = "uuid:e4367fb4-bbd2-11df-8c7b-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:cf81ffce-b43b-11df-b10e-0026b917f4bd#";
    our $grib_prefix
        = $desc_prefix . "grib.";

    our ($pred_contains, $pred_field_number);
    $pred_contains = $desc_prefix . "contains";
    $pred_field_number = $desc_prefix . "fieldNumber";
}

## NB: not an OO method
sub uri_node {
    ## .
    return new RDF::Redland::URINode (@_);
}

sub process_io {
    my ($self, $model, $subject, $io) = @_;

    drop_cloexec ($io);
    my @cmd = ("grib_ls", "/dev/fd/" . $io->fileno ());

    my $child
        = open (HANDLE, "-|", @cmd)
        or die ();

    ## skip the first line
    defined ($_ = <HANDLE>)
        or die ();

    ## retrieve the fields
    defined ($_ = <HANDLE>)
        or die ();
    chop;

    my @fields = split ();

    ## process the rest
    my $s1
        = $subject;
    my $p1
        = $self->{"rel.contains"};
    my $p_field_number
        = $self->{"rel.fieldNumber"};

    my $field_no = 0;
  BLK:
    while (<HANDLE>) {
        last BLK
            if (/ grib messages in /);
        $field_no++;
        chop ();
        my @values = split ();
        # print STDERR "O $field_no (" . join (", ", @fields) . "): $_\n";
        my $s = new RDF::Redland::BlankNode ();
        $model->add_statement ($s1, $p1, $s);
        {
            my $p
                = $p_field_number;
            my $o
                = new RDF::Redland::LiteralNode ("" . $field_no);
            my $st = new RDF::Redland::Statement ($s,  $p,  $o);
            $model->add_statement ($st);
        }
        for (my $i = 0; $i <= $#values; $i++) {
            my $literal = $values[$i];
            my $p
                = $self->{"rel.cache"}->transform ($fields[$i]);
            my $o
                = new RDF::Redland::LiteralNode ($literal);
            my $st = new RDF::Redland::Statement ($s,  $p,  $o);
            $model->add_statement ($st);
        }
    }

    ## consume the rest
    while (<HANDLE>) { }

    waitpid ($child, 0);

    return $!;
}

sub new {
    my ($class, $config) = @_;

    our ($module_uri_s, $conf_prefix);
    our ($desc_prefix);
    our ($grib_prefix);
    my $self = {
        "module"    => uri_node ($module_uri_s),
        "conf_pfx"  => $conf_prefix,
        "desc_pfx"  => $desc_prefix,
        "spec_pfx"  => $grib_prefix
    };
    our ($pred_contains, $pred_field_number);
    $self->{"rel.contains"}     = uri_node ($pred_contains);
    $self->{"rel.fieldNumber"}  = uri_node ($pred_field_number);

    bless ($self, $class);

    {
        my $xfm
            = $self->new_uri_node_transform ();
        $self->{"rel.cache"} = new fdrdf::xfmcache ($xfm);
    }

    ## .
    $self;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### grib.pm ends here
