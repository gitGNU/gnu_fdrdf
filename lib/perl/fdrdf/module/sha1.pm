### sha1.pm --- FDRDF: SHA-1 calculation module  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::module::sha1;

use strict;
use warnings;

use Digest::SHA1;
use RDF::Redland;

use fdrdf::module;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw (&new);
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw (&process_new);

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

sub process_new {
    my ($p_ref, $model, $subject) = @_;
    my (%handle);
    my $digest = Digest::SHA1->new ();

    my @args = (@_, $digest);
    $handle{"chunk"}    = sub { process_chunk (@args, @_) };
    $handle{"close"}    = sub { process_close (@args, @_) };

    ## .
    return
        \%handle;
}

sub process_close {
    my ($p_ref, $model, $subject, $digest) = @_;

    my $unpadded = $digest->b64digest ();
    ## NB: assuming that SHA-1 takes 160 bits = 27 Base64 chars
    my $d = $unpadded . "=";
    my $t = $p_ref->{"uri.type.xsd.base64Binary"};
    my $s = $subject;
    my $p = $p_ref->{"node.pred.sha1-base64"};
    my $o
        = new RDF::Redland::LiteralNode ($d, $t);

    $model->add_statement ($s, $p, $o);
}

sub process_chunk {
    my ($p_ref, $model, $subject, $digest, $chunk) = @_;

    $digest->add($chunk);
}

sub new {
    my ($pkg, $e_ref, $config) = @_;

    my %params;
    my @handle = (\&process_new, \%params);

    our ($xsd_prefix, @xsd_types_list);
    foreach my $type (@xsd_types_list) {
        $params{"uri.type.xsd." . $type}
            = new RDF::Redland::URI ($xsd_prefix . $type);
    }

    our ($sha1_uri_s);
    {
        my $node
            = new RDF::Redland::URINode ($sha1_uri_s);
        $params{"node.pred.sha1-base64"} = $node;
    }

    module_add_to_tag ($e_ref, "chunk", \@handle);

    ## .
    return $e_ref;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### sha1.pm ends here
