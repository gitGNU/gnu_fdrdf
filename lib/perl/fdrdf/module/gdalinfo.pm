### gdalinfo.pm --- FDRDF: GDAL processing module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::gdalinfo;

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
    @EXPORT_OK = qw (&process_gdalinfo);
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

sub add_rdf {
    my ($p_ref, $model, $s, $k, $v) = @_;
    my $cache = $p_ref->{"cache"};
    unless (exists ($cache->{$k})) {
        my $uri_s
            = ($p_ref->{"prefix"} . $k);
        $cache->{$k} = new RDF::Redland::URINode ($uri_s);
    }
    my $p = $cache->{$k};
    my $o = new RDF::Redland::LiteralNode ($v);

    $model->add_statement ($s, $p, $o);
}

sub process_gdalinfo {
    my ($p_ref, $model, $subject, $io) = @_;

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
                add_rdf ($p_ref, $model, $subject, $multiline_key, $multiline);
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
                add_rdf ($p_ref, $model, $subject, "$1", "$2");
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
    my ($pkg, $e_ref, $config) = @_;
    our ($gdalinfo_prefix);
    my %params
        = ("prefix" => $gdalinfo_prefix,
           "cache"  => {});
    my @handle = (\&process_gdalinfo, \%params);
    module_add_to_tag ($e_ref, "io", \@handle);

    ## .
    return $e_ref;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### gdalinfo.pm ends here
