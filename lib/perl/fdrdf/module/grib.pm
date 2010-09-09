### grib.pm --- FDRDF: GRIB processing module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::grib;

use strict;
use warnings;

use RDF::Redland;

use fdrdf::module;
use fdrdf::util;

BEGIN {
    require Exporter;
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = 0.1;
    @ISA = qw (Exporter);
    @EXPORT = qw (&new);
    @EXPORT_OK = qw (&process_grib);
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

sub process_grib {
    my ($model, $subject, $io) = @_;
    our ($grib_prefix);
    our ($pred_contains, $pred_field_number);
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
        = new RDF::Redland::URINode ($pred_contains);

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
                = new RDF::Redland::URINode ($pred_field_number);
            my $o
                = new RDF::Redland::LiteralNode ("" . $field_no);
            my $st = new RDF::Redland::Statement ($s,  $p,  $o);
            $model->add_statement ($st);
        }
        for (my $i = 0; $i <= $#values; $i++) {
            my $literal = $values[$i];
            my $p_u = $grib_prefix . $fields[$i];
            my $p
                = new RDF::Redland::URINode ($p_u);
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
    my ($pkg, $e_ref, $config) = @_;
    my @handle = (\&process_grib);
    module_add_to_tag ($e_ref, "io", \@handle);
    ## .
    return $e_ref;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### grib.pm ends here
