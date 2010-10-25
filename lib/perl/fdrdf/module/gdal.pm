### gdal.pm --- FDRDF: GDAL processing module  -*- Perl -*-

### Svetlana Zelenina, 2010
## This code is in the public domain.

package fdrdf::module::gdal;

use strict;
use warnings;

use Geo::GDAL;
use RDF::Redland;

use fdrdf::proto::io;
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
        = "uuid:19ab9b94-bbd2-11df-8d8b-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:4d0235c4-6c10-4c94-b537-1650395bc50b#";
    our $gdal_prefix
        = $desc_prefix . "gdal.";
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

    my $file = ("/dev/fd/" . $io->fileno ());
    my $ds = Geo::GDAL::Open ($file, "ReadOnly");
    my $meta = $ds->GetMetadata ();
    foreach my $k (keys (%$meta)) {
        $self->add_rdf ($model, $subject, $k, $meta->{$k});
    }
}

sub new {
    my ($class, $callback) = @_;

    our ($module_uri_s, $conf_prefix);
    our ($desc_prefix,  $gdal_prefix);
    my $self = {
        "module"    => uri_node ($module_uri_s),
        "conf_pfx"  => $conf_prefix,
        "desc_pfx"  => $desc_prefix,
        "spec_pfx"  => $gdal_prefix
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
### gdal.pm ends here
