### config.pm --- FDRDF: configuration object  -*- Perl -*-

### Copyright (C) 2010 Ivan Shmakov

## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.

## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

package fdrdf::config;

use strict;
use warnings;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    ## set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();

    ## storage options
    our ($sto_type, $sto_name)
        = ("hashes", "cf");
    our $sto_opts = {
        "new"           => "yes",
        "contexts"      => "yes",
        "hash-type"     => "memory"
    };
}

sub config {
    my ($self) = @_;
    ## .
    $self->{"config"};
}

sub new {
    my ($class) = @_;

    our ($module_uri_s, $conf_prefix);
    my $self = {
        "conf_pfx"  => $conf_prefix
    };

    our ($sto_type, $sto_name, $sto_opts);
    my $storage
        = new RDF::Redland::Storage ($sto_type, $sto_name,
                                     $sto_opts);
    ## FIXME: constructor should accept a hash reference
    my $config
        = new RDF::Redland::Model ($storage, "");

    $self->{"storage"}  = $storage;
    $self->{"config"}   = $config;

    bless ($self, $class);

    ## .
    $self;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### config.pm ends here
