### mark.pm --- FDRDF: mark resources with arbitrary P, V pairs  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::module::mark;

use strict;
use warnings;

use RDF::Redland;

use fdrdf::proto::io;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter fdrdf::proto::io);
    @EXPORT = qw ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();

    ## URI's and prefixes
    our $module_uri_s
        = "uuid:0b54e2a6-bea4-11df-afda-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:0fa291e6-bea4-11df-86d6-4040a5e6bfa3#";
    our $mark_pair_uri_s
        = $conf_prefix . "markWithPair";
    our $mark_uri_s
        = $desc_prefix . "mark";
    our $mark_value
        = "1";
    our $mark_value_type
        = "http://www.w3.org/2001/XMLSchema#boolean";
}

## NB: not an OO method
sub uri_node {
    ## .
    return new RDF::Redland::URINode (@_);
}

sub process_io {
    my ($self, $model, $subject, $io) = @_;

    my $s = $subject;
    for my $r_o (@{$self->{"relations-values"}}) {
        $model->add_statement ($s, @$r_o);
    }
}

sub configure {
    my ($self, $callback, $default) = @_;
    my $config = $callback->config ();
    my @rv
        = ();
    {
        my $mark_pair_uri_s
            = $self->{"uri.s.markWithPair"};
        my $selected
            = $callback->selected_sparql ();
        my @q_lang
            = (undef, undef, "sparql");
        my $q_s
            = ("PREFIX rdf:"
               . " <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n"
               . "PREFIX mark:"
               . " <" . $mark_pair_uri_s . ">\n"
               . "SELECT ?p ?v\n"
               . "WHERE {\n"
               . "  ?n1 " . $selected . " .\n"
               . "  ?n1 mark: ?n2 .\n"
               . "  ?n2 rdf:predicate ?p ;\n"
               . "      rdf:value     ?v .\n"
               . "}\n");
        my $query
            = new RDF::Redland::Query ($q_s, @q_lang);
        for (my $r = $config->query_execute ($query);
             ! $r->finished ();
             $r->next_result ()) {
            my @pair
                = ($r->binding_value_by_name ("p"),
                   $r->binding_value_by_name ("v"));
            push (@rv, \@pair);
        }
    }
    push (@{$self->{"relations-values"}}, @rv);
    &$default
        unless ($#rv >= 0);
}

sub new {
    my ($class, $callback) = @_;

    our ($module_uri_s, $conf_prefix);
    our ($desc_prefix);
    our ($mark_pair_uri_s);
    our ($mark_uri_s,   $mark_value,   $mark_value_type);
    my $self = {
        "module"    => uri_node ($module_uri_s),
        "conf_pfx"  => $conf_prefix,
        "desc_pfx"  => $desc_prefix
    };
    $self->{"uri.s.markWithPair"} = $mark_pair_uri_s;
    {
        my @null
            = ();
        $self->{"relations-values"} = \@null;
    }
    my $default = sub {
        my @pair
            = (uri_node ($mark_uri_s),
               new RDF::Redland::LiteralNode ($mark_value,
                                              $mark_value_type));
        push (@{$self->{"relations-values"}}, \@pair);
    };

    bless ($self, $class);
    $self->configure ($callback, $default);

    ## .
    $self;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### mark.pm ends here
