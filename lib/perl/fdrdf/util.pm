### util.pm --- FDRDF: utilities support  -*- Perl -*-

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

package fdrdf::util;

use strict;
use warnings;

use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use IO::File;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    ## set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw (close_file drop_cloexec open_file);
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();
}

sub open_file {
    my ($fn, $write_p) = @_;

    ## .
    return
        (($fn ne "-") ? new IO::File ($fn, $write_p ? O_WRONLY : O_RDONLY)
         : $write_p ? \*STDOUT
         : \*STDIN);
}

sub close_file {
    my ($f) = @_;
    close ($f)
        unless ($f eq \*STDIN || $f eq \*STDOUT);
}

sub drop_cloexec {
    my ($io) = @_;
    my $flags;
    $flags = fcntl ($io, F_GETFD, 0)
        or die ();
    $flags &= (~ FD_CLOEXEC);
    $flags  = fcntl ($io, F_SETFD, $flags)
        or die ();
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### util.pm ends here
