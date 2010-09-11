### proto.pm --- FDRDF: a common key to URI transform  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::xfmcache::proto;

use strict;
use warnings;

use RDF::Redland;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();
}

sub new_uri_node_transform {
    my ($self, $prefix, $suffix) = @_;
    $prefix //= $self->{"spec_pfx"} // "";
    $suffix //= $self->{"spec_sfx"} // "";

    ## .
    sub {
        my ($k) = @_;
        my $uri_s
            = ($prefix . $k . $suffix);
        ## .
        return
            new RDF::Redland::URINode ($uri_s);
    };
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### proto.pm ends here
