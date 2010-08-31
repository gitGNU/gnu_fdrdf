### grib.pm --- FDRDF: GRIB processing module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::grib;

use strict;
use warnings;

use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use RDF::Redland;

BEGIN {
    require Exporter;
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = 0.1;
    @ISA = qw (Exporter);
    @EXPORT = qw (&new);
    @EXPORT_OK = qw (&process_grib);
    %EXPORT_TAGS = ();
    our ($desc_prefix, $grib_prefix);
    $desc_prefix
        = "uuid:cf81ffce-b43b-11df-b10e-0026b917f4bd#";
    $grib_prefix
        = $desc_prefix . "grib.";
    our ($pred_contains, $pred_field_number);
    $pred_contains = $desc_prefix . "contains";
    $pred_field_number = $desc_prefix . "fieldNumber";
}

sub drop_cloexec {
    my ($io) = @_;
    my $flags;
    $flags = fcntl ($io, F_GETFD, 0)
        or die ();
    $flags &= (~ FD_CLOEXEC);
    $flags  = fcntl ($io, F_SETFD, $flags)
        or die ();
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
        my $st2 = new RDF::Redland::Statement ($s1, $p1, $s);
        {
            my $p
                = new RDF::Redland::URINode ($pred_field_number);
            my $o
                = new RDF::Redland::LiteralNode ("" . $field_no);
            my $st = new RDF::Redland::Statement ($s,  $p,  $o);
            $model->add_statement ($st);
        }
        for (my $i = 0; $i <= $#values; $i++) {
            print STDERR $fields[$i], ", ", $values[$i], "\n";
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
    my @handle = (\&process_grib);
    return
        \@handle;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### grib.pm ends here
