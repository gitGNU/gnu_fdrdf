### gdal.pm --- FDRDF: GDAL processing module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::gdal;

use strict;
use warnings;

use Geo::GDAL;
use RDF::Redland;

use fdrdf::module;

BEGIN {
    require Exporter;
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = 0.1;
    @ISA = qw (Exporter);
    @EXPORT = qw ();
    @EXPORT_OK = qw ();
    %EXPORT_TAGS = ();

    ## URI's and prefixes
    our $module_uri_s
        = "uuid:19ab9b94-bbd2-11df-8d8b-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:4d0235c4-6c10-4c94-b537-1650395bc50b#";
    our $gdal_prefix
        = $desc_prefix . "gdal.";
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

sub process_gdal {
    my ($p_ref, $model, $subject, $io) = @_;

    my $file = ("/dev/fd/" . $io->fileno ());
    my $ds = Geo::GDAL::Open ($file, "ReadOnly");
    my $meta = $ds->GetMetadata ();
    foreach my $k (keys (%$meta)) {
        add_rdf ($p_ref, $model, $subject, "$k", "$meta->{$k}");
    }
}

sub new {
    my ($pkg, $e_ref, $config) = @_;
    our ($gdal_prefix);
    my %params
        = ("prefix" => $gdal_prefix,
           "cache"  => {});
    my @handle = (\&process_gdal, \%params);
    module_add_to_tag ($e_ref, "io", \@handle);

    ## .
    return $e_ref;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### gdal.pm ends here
