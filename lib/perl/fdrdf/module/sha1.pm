### sha1.pm --- FDRDF: SHA-1 calculation module  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::module::sha1;

use strict;
use warnings;

use Digest::SHA1;
use RDF::Redland;

use fdrdf::proto::chunks;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter fdrdf::proto::chunks);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();

    ## URI's and prefixes
    our $module_uri_s
        = "uuid:f1e05a1e-bbc2-11df-b3a7-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:eb1d54d8-b67d-11df-9eec-4040a5e6bfa3#";
    our $sha1_uri_s
        = $desc_prefix . "sha1";

    our ($chunk_size);
    $chunk_size = 262144;

    our ($xsd_prefix, @xsd_types_list);
    $xsd_prefix = "http://www.w3.org/2001/XMLSchema#";
    @xsd_types_list = qw(base64Binary);
}

## NB: not an OO method
sub uri_node {
    ## .
    return new RDF::Redland::URINode (@_);
}

sub process_chunks {
    my ($self, $model, $subject) = @_;
    my $digest = Digest::SHA1->new ();
    my $chunks = {
        "module"    => $self,
        "model"     => $model,
        "subject"   => $subject,
        "digest"    => $digest
    };
    bless ($chunks, "fdrdf::module::sha1::chunk");

    ## .
    $chunks;
}

package fdrdf::module::sha1::chunk;

sub close {
    my ($self) = @_;

    my $unpadded = $self->{"digest"}->b64digest ();
    ## NB: assuming that SHA-1 takes 160 bits = 27 Base64 chars
    my $d = $unpadded . "=";
    my $t = $self->{"module"}->{"uri.type.xsd.base64Binary"};
    my $s = $self->{"subject"};
    my $p = $self->{"module"}->{"rel.sha1"};
    my $o
        = new RDF::Redland::LiteralNode ($d, $t);

    $self->{"model"}->add_statement ($s, $p, $o);
}

sub add_chunk {
    my ($self, $chunk) = @_;

    $self->{"digest"}->add ($chunk);
}

package fdrdf::module::sha1;

sub new {
    my ($class, $config) = @_;

    our ($module_uri_s, $conf_prefix);
    our ($desc_prefix,  $sha1_uri_s);
    my $self = {
        "module"    => uri_node ($module_uri_s),
        "conf_pfx"  => $conf_prefix,
        "desc_pfx"  => $desc_prefix
    };
    $self->{"rel.sha1"} = uri_node ($sha1_uri_s);

    our ($xsd_prefix, @xsd_types_list);
    foreach my $type (@xsd_types_list) {
        $self->{"uri.type.xsd." . $type}
            = new RDF::Redland::URI ($xsd_prefix . $type);
    }

    bless ($self, $class);

    ## .
    $self;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### sha1.pm ends here
