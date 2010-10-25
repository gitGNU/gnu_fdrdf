### gdalinfo.pm --- FDRDF: GDAL processing module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::gdalinfo;

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
        = "uuid:4a48ad14-bbd2-11df-b186-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:ea1a00f1-68ba-4739-aa7e-f74967ce5eb8#";
    our $gdalinfo_prefix
        = $desc_prefix . "gdalinfo.";
}

## NB: not an OO method
sub uri_node {
    ## .
    return new RDF::Redland::URINode (@_);
}

sub add_rdf {
    my ($self, $model, $s, $k, $v) = @_;
    my $p = $self->{"rel.cache"}->transform ($k);
    my $o = new RDF::Redland::LiteralNode ($v);

    $model->add_statement ($s, $p, $o);
}

sub process_io {
    my ($self, $model, $subject, $io) = @_;

    drop_cloexec ($io);
    my $file = ("/dev/fd/" . $io->fileno ());
    my @cmd = ('gdalinfo', $file);
    open(HANDLE, "-|", @cmd);

    my $in_meta_p = "";
    my $in_multiline_p = "";
    my ($multiline_key, $multiline);

  LINE:
    while (<HANDLE>) {
        if ($in_multiline_p) {
            if (/^\t/) {
                $multiline .= substr ($_, 1, -1 + length ($_));
                next LINE;
            }
            chop;
            if (! /./) {
                $in_multiline_p = "";
                $self->add_rdf ($model, $subject, $multiline_key, $multiline);
                next LINE;
            }
            warn ("unexpected line in multiline context");
            $in_multiline_p = "";
        }

        chop;
        if ($in_meta_p) {
            if (/^[^[:blank:]].*:$/) {
                $in_meta_p = "";
                next LINE;
            }
            unless (/^\s+(.+?)=(.*)$/) {
                warn ("unexpected line in metadata context");
                next LINE;
            }
            if ($2 eq "") {
                $in_multiline_p = 1;
                $multiline_key  = $1;
                $multiline      = "";
            } else {
                $self->add_rdf ($model, $subject, "$1", "$2");
            }
            next LINE;
        }

        if (/^Metadata:$/) {
            $in_meta_p = 1;
            next LINE;
        }
    }
}

sub new {
    my ($class, $callback) = @_;

    our ($module_uri_s, $conf_prefix);
    our ($desc_prefix,  $gdalinfo_prefix);
    my $self = {
        "module"    => uri_node ($module_uri_s),
        "conf_pfx"  => $conf_prefix,
        "desc_pfx"  => $desc_prefix,
        "spec_pfx"  => $gdalinfo_prefix
    };

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
### gdalinfo.pm ends here
