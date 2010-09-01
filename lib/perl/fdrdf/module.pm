### module.pm --- FDRDF: module support  -*- Perl -*-

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

package fdrdf::module;

use strict;
use warnings;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    ## set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw (&module_tags &module_add_to_tag);
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw (&module_entry &module_invoke_tag);
}

sub module_entry
{
    our ($VERSION);
    my %tags = ();
    my %entry
        = ("version" => $VERSION, "tags" => \%tags);
    ## .
    return
        \%entry;
}

sub module_tags
{
    my ($e_ref) = @_;
    return
        keys (%{$e_ref->{"tags"}});
}

sub module_add_to_tag
{
    my ($e_ref, $tag, @h_refs) = @_;
    unless (exists ($e_ref->{"tags"}->{$tag})) {
        my @null = ();
        ${$e_ref->{"tags"}->{$tag}} = \@null;
    }
    push (@${$e_ref->{"tags"}->{$tag}}, @h_refs);
}

sub module_invoke_tag
{
    my ($e_ref, $tag, @args) = @_;
    foreach my $ref (@${$e_ref->{"tags"}->{$tag}}) {
        my ($sub_ref, @args1) = @$ref;
        &$sub_ref (@args1, @args);
    }
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### module.pm ends here
