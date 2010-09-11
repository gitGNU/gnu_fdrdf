### io.pm --- FDRDF: module prototype, io interface  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::proto::io;

use strict;
use warnings;

use fdrdf::proto;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter fdrdf::proto);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();
}

sub module_does {
    ## FIXME: creates a couple of new references each time called
    ## .
    return {
        "io" => sub { $_[0]->process_io (@_); }
    };
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### io.pm ends here
