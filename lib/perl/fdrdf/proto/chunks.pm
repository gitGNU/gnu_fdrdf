### chunks.pm --- FDRDF: module prototype, chunks interface  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::proto::chunks;

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
        "chunks" => sub { $_[0]->process_chunks (@_); }
    };
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### chunks.pm ends here
