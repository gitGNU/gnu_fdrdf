### oisst.pm --- FDRDF: process OISST files  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::module::oisst;

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
        = "uuid:f089fa08-c180-11df-a92f-4040a5e6bfa3";
    our $conf_prefix
        = $module_uri_s . "#cf.";
    our $desc_prefix
        = "uuid:f70c3c88-c180-11df-bfdc-4040a5e6bfa3#";

    our (@keys_list);
    @keys_list
        = qw (startDate endDate numDays index);
    our ($xs_prefix, @xs_types_list);
    $xs_prefix = "http://www.w3.org/2001/XMLSchema#";
    @xs_types_list = qw (date integer);
}

## NB: not an OO method
sub uri_node {
    ## .
    return new RDF::Redland::URINode (@_);
}

sub process_io {
    my ($self, $model, $subject, $io) = @_;

    binmode ($io);
    my $h_words = 1 + 8 + 1;
    my $h_len = $h_words * 4;
    ($io->read (my $header, $h_len) == $h_len)
	or die ($!);

    my ($l1, $y1, $m1, $d1, $y2, $m2, $d2, $days, $ix, $l2)
	= unpack ("L>$h_words", $header);
    ($l1 == 32 && $l2 == 32)
	or die ();

    my $t_date
	= $self->{"uri.type.xs.date"};
    my $t_integer
	= $self->{"uri.type.xs.integer"};

    my $p_ts1
	= $self->{"node.pred"}->{"startDate"};
    my $p_ts2
	= $self->{"node.pred"}->{"endDate"};
    my $p_days
	= $self->{"node.pred"}->{"numDays"};
    my $p_ix
	= $self->{"node.pred"}->{"index"};

    my $s_ts1
	= sprintf ("%04d-%02d-%02d", $y1, $m1, $d1);
    my $n_ts1
	= new RDF::Redland::LiteralNode ($s_ts1, $t_date);
    my $s_ts2
	= sprintf ("%04d-%02d-%02d", $y2, $m2, $d2);
    my $n_ts2
	= new RDF::Redland::LiteralNode ($s_ts2, $t_date);
    my $n_days
	= new RDF::Redland::LiteralNode ("" . $days, $t_integer);
    my $n_ix
	= new RDF::Redland::LiteralNode ("" . $ix,   $t_integer);

    $model->add_statement ($subject, $p_ts1,  $n_ts1);
    $model->add_statement ($subject, $p_ts2,  $n_ts2);			   
    $model->add_statement ($subject, $p_days, $n_days);
    $model->add_statement ($subject, $p_ix,   $n_ix);			   
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
    our (@keys_list);
    our ($xs_prefix, @xs_types_list);
    foreach my $type (@xs_types_list) {
        $self->{"uri.type.xs." . $type}
            = new RDF::Redland::URI ($xs_prefix . $type);
    }
    foreach my $key (@keys_list) {
        next
            if ($key =~ /^_/);
        my $uri_s = $desc_prefix . $key;
        $self->{"node.pred"}->{$key}
            = new RDF::Redland::URINode ($uri_s);
    }

    bless ($self, $class);

    ## .
    $self;
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### oisst.pm ends here
