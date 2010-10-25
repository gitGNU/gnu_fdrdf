### file.pm --- FDRDF: file module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::file;

use strict;
use warnings;

use RDF::Redland;

use fdrdf::proto::io;
use fdrdf::util;

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
        = "uuid:be8202c2-bbbc-11df-a158-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:a2cb5fd0-4e89-4d8a-a009-dc42c45bbcc5#file.";
    our $mime_type_uri_s
        = $desc_prefix . "mime-type";
}

## NB: not an OO method
sub uri_node {
    ## .
    return new RDF::Redland::URINode (@_);
}

sub process_io {
    my ($self, $model, $subject, $io) = @_;

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
    my $p = $self->{"rel.mime-type"};
    my $o = new RDF::Redland::LiteralNode ("" . $type);

    $model->add_statement ($s, $p, $o);
}

sub new {
    my ($class, $callback) = @_;

    our ($module_uri_s, $conf_prefix);
    our ($desc_prefix,  $mime_type_uri_s);
    my $self = {
        "module"    => uri_node ($module_uri_s),
        "conf_pfx"  => $conf_prefix,
        "desc_pfx"  => $desc_prefix
    };
    $self->{"rel.mime-type"} = uri_node ($mime_type_uri_s);

    bless ($self, $class);

    ## .
    $self;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### file.pm ends here
