### stat.pm --- FDRDF: stat(2) module  -*- Perl -*-

### Ivan Shmakov, 2010
## This code is in the public domain.

package fdrdf::module::stat;

use strict;
use warnings;

use fdrdf::module;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION = 0.1;

    @ISA = qw (Exporter);
    @EXPORT = qw (&new);
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw ();
    our ($conf_prefix);
    $conf_prefix = "uuid:21624fe2-b54f-11df-b9c0-4040a5e6bfa3#cf.";
    our ($desc_prefix, $num_prefix, $sym_prefix);
    $desc_prefix = "uuid:2e22aa82-b550-11df-9d5c-4040a5e6bfa3#stat.";
    $num_prefix  = $desc_prefix . "n.";
    $sym_prefix  = $desc_prefix . "s.";
    our (@keys_list);
    @keys_list
        = qw(dev ino mode nlink uid gid _rdev size
             atime mtime ctime blksize blocks);
    # atime_usec mtime_usec ctime_usec
    our ($xs_prefix, @xs_types_list);
    $xs_prefix = "http://www.w3.org/2001/XMLSchema#";
    @xs_types_list = qw(integer);
}

sub process_stat {
    my ($p_ref, $model, $subject, @stat) = @_;
    our (@keys_list);

    my $s = $subject;
    my @r = @stat;
    my $num
        = $$p_ref{"uri.type.xs.integer"};
    for (my $i = 0; $i <= $#keys_list; $i++) {
        my $key = $keys_list[$i];
        next
            if ($key =~ /^_/);
        {
            my $p
                = $$p_ref{"node.pred.numeric"}{$key};
            my $o
                = new RDF::Redland::LiteralNode ("" . $r[$i], $num);
            $model->add_statement ($s, $p, $o);
        }
    }
}

sub process_file {
    my ($p_ref, $model, $subject, $io) = @_;

    ## FIXME: cannot do lstat () here
    my @r = stat ($io);
    process_stat ($p_ref, $model, $subject, @r);
}

sub new {
    my ($pkg, $e_ref, $config) = @_;
    our ($num_prefix, $sym_prefix);
    our (@keys_list);
    our ($xs_prefix, @xs_types_list);
    my %params;
    my @handle = (\&process_file, \%params);

    foreach my $type (@xs_types_list) {
        $params{"uri.type.xs." . $type}
            = new RDF::Redland::URI ($xs_prefix . $type);
    }
    foreach my $key (@keys_list) {
        next
            if ($key =~ /^_/);
        my $uri_s = $num_prefix . $key;
        $params{"node.pred.numeric"}{$key}
            = new RDF::Redland::URINode ($uri_s);
    }
    module_add_to_tag ($e_ref, "io", \@handle);

    ## .
    return $e_ref;    
}

1;

## Local variables:
## indent-tabs-mode: nil
## fill-column: 72
## End:
### stat.pm ends here
