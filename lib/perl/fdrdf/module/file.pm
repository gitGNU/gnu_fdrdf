### file.pm --- FDRDF: file module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::file;

use strict;
use warnings;

use RDF::Redland;

use fdrdf::util;
use fdrdf::module;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();

    ## URI's and prefixes
    our $module_uri_s
        = "uuid:be8202c2-bbbc-11df-a158-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:a2cb5fd0-4e89-4d8a-a009-dc42c45bbcc5#file.";
    our $mime_type_uri_s
        = $desc_prefix . "mime-type";
}

sub process_file {
    my ($relation, $model, $subject, $io) = @_;

    drop_cloexec ($io);
    my @cmd
        = ("file", "-b", "-L", "--mime-type",
           "--", "/dev/fd/" . $io->fileno ());
    my $child
        = open (HANDLE, "-|", @cmd)
        or die ();

    defined ($_ = <HANDLE>)
        or die ();
    chop;
    my $type = $_;
    my $s = $subject;
    my $p = $relation;
    my $o = new RDF::Redland::LiteralNode ("" . $type);

    $model->add_statement ($s, $p, $o);
}

sub new {
    my ($pkg, $e_ref, $config) = @_;
    our ($mime_type_uri_s);
    my $relation
        = new RDF::Redland::URINode ($mime_type_uri_s);
    my @handle = (\&process_file, $relation);
    module_add_to_tag ($e_ref, "io", \@handle);

    ## .
    return $e_ref;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### file.pm ends here
