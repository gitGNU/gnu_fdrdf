### xfmcache.pm --- FDRDF: cache transform's results  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::xfmcache;

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

sub invalidate {
    my ($self) = @_;
    $self->{"cache"} = { };
}

sub transform {
    my ($self, $key) = @_;
    $self->{"cache"}->{$key} = &{$self->{"xform"}} ($key)
        unless ($self->{"cache"}->{$key});
    ## .
    $self->{"cache"}->{$key};
}

sub new {
    my ($class, $transform) = @_;
    my $self = {
        "xform" => $transform,
        "cache" => { }
    };
    bless ($self, $class);

    ## .
    $self;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### xfmcache.pm ends here
