### proto.pm --- FDRDF: module prototype  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::proto;

use strict;
use warnings;

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

sub module_uri_node {
    ## .
    return $_[0]->{"module"};
}

sub module_conf_prefix {
    ## .
    return $_[0]->{"conf_pfx"};
}

sub module_desc_prefix {
    ## .
    return $_[0]->{"desc_pfx"};
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### proto.pm ends here
