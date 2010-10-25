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

use fdrdf::util::rdf;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    ## set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();

    ## URI's and prefixes
    our $program_uri_s
        = "uuid:0c953d4c-cb8c-11df-a381-4040a5e6bfa3";
    our $conf_prefix
        = $program_uri_s . "#cf.";
    our $xsd_prefix
        = "http://www.w3.org/2001/XMLSchema#";

    our @cf_keys_list
        = qw (default includes selected);

    our $common_sparql_prefixes
        = (""
           . "PREFIX xsd: <" . $xsd_prefix . ">\n");
    our $common_sparql_cf_prefixes
        = ($common_sparql_prefixes
           . "PREFIX fdrdf: <" . $conf_prefix . ">\n");

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

sub predicate {
    my ($self, $key) = @_;
    ## .
    $self->{"node.pred"}->{$key};
}

sub select {
    my ($self, @uris) = @_;
    my $config
        = $self->{"config"};
    my $selected
        = $self->{"node.pred"}->{"selected"};
    my $xsd_true
        = $self->{"node.obj.true"};

    ## place cf.selected configuration markers
    foreach my $uri (@uris) {
        $config->add_statement ($uri, $selected, $xsd_true);
    }
}

sub has_selected_p {
    my ($self, @uris) = @_;
    my $config
        = $self->{"config"};
    my $selected
        = $self->{"node.pred"}->{"selected"};
    my $query
        = query_ask_true_relation ($selected);

    ## .
    $config->query_execute ($query)->get_boolean ();
}

sub activate_default {
    my ($self, @uris) = @_;
    my $config
        = $self->{"config"};

    ## transform cf.default arcs into cf.selected ones
    my @q_lang
        = (undef, undef, "sparql");
    my $q_s
        = ($self->{"sparql.pfx.cf"}
           . "CONSTRUCT {\n"
           . "  ?c  fdrdf:selected true .\n"
           . "}\n"
           . "WHERE {\n"
           . "  ?c  fdrdf:default  true .\n"
           . "}\n");
    my $query
        = new RDF::Redland::Query ($q_s, @q_lang);

    $self->{"defaults_active"} = 1;

    ## .
    query_transform ($query, $config, $config);
}

sub activate_includes {
    my ($self, @uris) = @_;
    my $config
        = $self->{"config"};

    ## process cf.includes arcs
    my @q_lang
        = (undef, undef, "sparql");
    my $q_s
        = ($self->{"sparql.pfx.cf"}
           . "CONSTRUCT {\n"
           . "  ?c  fdrdf:selected true .\n"
           . "}\n"
           . "WHERE {\n"
           . "  ?c1 fdrdf:selected true .\n"
           . "  ?c1 fdrdf:includes ?c .\n"
           . "  OPTIONAL { ?c fdrdf:selected ?cs . }\n"
           . "  FILTER (!bound (?cs))\n"
           . "}\n");
    my $query
        = new RDF::Redland::Query ($q_s, @q_lang);

    my $count;
    for ($count = 128;
         $count > 0 && query_transform ($query, $config, $config);
         $count--) {
        ## do nothing
    }
    warn ("Suspicious condition: cf.includes nesting is too deep")
        unless ($count > 0);
}

sub show_selected {
    my ($self, $out) = @_;
    my $config
        = $self->{"config"};
    my $selected
        = $self->{"node.pred"}->{"selected"};

    ## show selected configuration nodes
    my $query
        = query_true_relation ($selected);
    my $r
        = $config->query_execute ($query);

    print $out (("Selected configuration nodes"
                 . ($self->{"defaults_active"}
                    ? " (defaults active)"
                    : "")
                 . ":\n"))
        unless ($r->finished ());
    for (;
         ! $r->finished ();
         $r->next_result ()) {
        my $c
            = $r->binding_value_by_name ("s");
        print $out ("  " . $c->as_string () . "\n");
    }
}

sub new {
    my ($class) = @_;

    our ($module_uri_s, $conf_prefix);
    our ($common_sparql_prefixes, $common_sparql_cf_prefixes);
    my $self = {
        "conf_pfx"  => $conf_prefix,
        "sparql.pfx"    => $common_sparql_prefixes,
        "sparql.pfx.cf" => $common_sparql_cf_prefixes,
        "defaults_active" => 0
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

    our (@cf_keys_list);
    foreach my $key (@cf_keys_list) {
        next
            if ($key =~ /^_/);
        my $uri_s
            = $conf_prefix . $key;
        $self->{"node.pred"}->{$key}
            = new RDF::Redland::URINode ($uri_s);
    }

    our ($xsd_prefix);
    my $xsd_boolean
        = new RDF::Redland::URI ($xsd_prefix . "boolean");
    $self->{"node.obj.true"}
        = new RDF::Redland::LiteralNode ("true", $xsd_boolean);

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
