#!/usr/bin/perl
### fdrdf.pl  -*- Perl -*-

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

## Based on: fcfs-xml.pl  (2010-04-29 11:10:52+00:00.)
## Based on: dda-stage.pl (2009-09-29 15:17:13+00:00.)

use strict;
# use warnings;

# use DateTime;
use English qw(-no_match_vars);
use Getopt::Mixed "nextOption";
# use MIME::Base64;
use RDF::Redland;
use URI::file;
use UUID;

use fdrdf::callback;
use fdrdf::config;
use fdrdf::util;

my $progname;
$progname = $PROGRAM_NAME;
$progname =~ s/^.*\///;

## NB: a la GNU Autotools
my ($PACKAGE, $PACKAGE_BUGREPORT);
my ($PACKAGE_NAME, $PACKAGE_VERSION);
$PACKAGE = "fdrdf";
$PACKAGE_NAME = "FDRDF";
$PACKAGE_VERSION = "0.1";
$PACKAGE_BUGREPORT = 'ivan@theory.asu.ru';

### Module API

sub init_module {
    my ($callback, $name) = @_;

    my $f = "fdrdf/module/" . $name . ".pm";
    eval { require $f; };
    die ("$name: failed to load: $@")
        if ($@);

    my $class = "fdrdf::module::" . $name;
    my $module
        = new $class ($callback);

    ## .
    return $module;
}

sub check_module_tags {
    my ($modules, $name, $module) = @_;

    my @tags
        = keys (%{$module->module_does ()});
    foreach my $tag (@tags) {
      SWITCH: {
          if (exists ($modules->{$tag})) {
              $modules->{$tag}->{$name} = $module;
              last SWITCH;
          }
          warn ("Unknown module tag $tag; ignored\n");
      }
    }
}

sub init_modules {
    my ($callback, $modules, @names) = @_;
    foreach my $name (@names) {
        next
            if (exists $modules->{$name});
        my $module
            = init_module ($callback, $name)
            or die ("$name: failed to initialize module");
        check_module_tags ($modules, $name, $module);
    }
}

### Processing individual files

sub process_file {
    my ($p_ref, $filename) = @_;
    my $model       = $p_ref->{"model"};
    my $modules     = $p_ref->{"modules"};
    my $uri
        = URI::file->new_abs ($filename);
    my $uri_s
        = $uri->as_string ();
    my $subject = new RDF::Redland::URINode ($uri_s);
    my $io1 = open_file ($filename, 0)
        or die ("$filename: cannot open");

    ## process tag: io
    foreach my $m (keys (%{$modules->{"io"}})) {
        my $module = $modules->{"io"}->{$m};
        open (my $io, "<&", $io1)
            or die ();
        $module->process_io ($model, $subject, $io);
        close ($io);
    }

    ## process tag: chunk
    process_chunk ($modules->{"chunks"}, "chunks", $io1,
                   $model, $subject);

    close_file ($io1);
}

sub process_chunk {
    my ($h_ref, $tag, $io1, @args) = @_;
    my $chunk_size = 262144;

    unless (-f $io1) {
        warn ("not a regular file; will not process in chunks");
        ## .
        return undef;
    }

    open (my $io_c, "<&", $io1);
    binmode ($io1);
    unless (sysseek ($io_c, 0, 0)) {
        warn ("cannot lseek(2); will not process in chunks");
        ## .
        return undef;
    }

    my @consumers = ();
    foreach my $m (keys (%$h_ref)) {
        push (@consumers,
              $h_ref->{$m}->process_chunks (@args));
    }

    my ($r, $buf);
    while (($r = sysread ($io_c, $buf, $chunk_size)) > 0) {
        foreach my $c (@consumers) {
            $c->add_chunk ($buf);
        }
    }
    die ()
        unless (defined ($r));

    foreach my $c (@consumers) {
        $c->close ();
    }
}

### Command line interface

## FIXME: use the Perl port of GNU Argp

sub help {
    my $p = $progname;
    print (""
           . "Usage: " . $p . " [OPTION...] FILE...\n"
           . "  or:  " . $p . " [OPTION...] -T FILE [FILE...]\n"
           . "Gather File metaData and produce its RDF"
           . " representation.\n"
           . "\n"
           . "  -0, --null                "
           . " -T reads null-terminated names\n"
           . "  -c, --config-file=RDF-FILE"
           . " read configuration from RDF-FILE\n"
           . "      --configuration=URI   "
           . " select specific parts of a multi-configuration\n"
           . "                            "
           . "   file\n"
           . "  -m, --modules=MODULES     "
           . " use MODULES to process files\n"
           . "      --no-output           "
           . " suppress model serialization and output\n"
           . "  -o, --output=FILE         "
           . " write result to FILE instead of standard output\n"
           . "      --storage-name=NAME   "
           . " use specific storage NAME\n"
           . "      --storage-options=OPTS"
           . " use specific storage options (default:\n"
           . "                            "
           . "   `new='yes',hash-type='memory'')\n"
           . "      --storage-type=TYPE   "
           . " use specific storage TYPE (default: `hashes')\n"
           . "  -T, --files-from=FILE     "
           . " get filenames to process from FILE\n"
           . "  -t, --output-format=FORMAT"
           . " use specific Raptor output serialization\n"
           . "                            "
           . " (default: `rdfxml')\n"
           . "\n"
           . "  -?, --help                 Give this help list\n"
           . "      --usage                Give a short usage message\n"
           . "  -V, --version              Print program version\n"
           . "\n"
           . "Mandatory or optional arguments to long options"
           . " are also mandatory or optional\n"
           . "for any corresponding short options.\n"
           . "\n"
           . "The output formats (serializations) are"
           . " provided by the Raptor library\n"
           . "and may include:\n"
           . "  `atom', `dot', `json', `json-triples',"
           . " `nquads', `ntriples', `rdfxml',\n"
           . "  `rdfxml-abbrev', `rdfxml-xmp',"
           . " `rss-1.0' and `turtle'.\n"
           . "\n"
           . "Report bugs to " . $PACKAGE_BUGREPORT . ".\n");
}

sub version {
    print ($progname
           . " (" . $PACKAGE_NAME . ") " . $PACKAGE_VERSION . "\n"
           . "Copyright (C) 2010 Ivan Shmakov\n"
           . "License GPLv3+: GNU GPL version 3 or later"
           . " <http://gnu.org/licenses/gpl.html>.\n"
           . "This is free software: you are free to change"
           . " and redistribute it.\n"
           . "There is NO WARRANTY, to the extent permitted"
           . " by law.\n");
}

my $warnings_p = 1;
BEGIN {
    $SIG{"__DIE__"} = sub {
        die ("$progname: ", @_);
    };
    $SIG{"__WARN__"} = sub {
        warn ("$progname: Warning: ", @_)
            if ($warnings_p);
    };
}

my @config_files = ();
my $config_format = "rdfxml";
my @configuration = ();
my @module_list;
my $null_p = 0;
my @files_from = ();
my $output = "-";
my $output_format = "rdfxml";
my $show_config_nodes_p = 1;
my $sto_type = "hashes";
my $sto_name = "";
my $sto_opts = {
    "new"       => "yes",
    "hash-type" => "memory"
};

Getopt::Mixed::init ("?      help>?"
                     . " V   version>V"
                     . " 0   null>0"
                     . " c=s config-file>c"
                     . "     configuration=s"
                     . " T=s files-from>T"
                     . " m=s modules>m"
                     . "     no-output"
                     . "     storage-name=s"
                     . "     storage-options=s"
                     . "     storage-type=s"
                     . " o=s output>o"
                     . " t=s output-format>t");
{
    my ($optstrip, $value, $_);
    ## FIXME: should distinguish --FOO= from --FOO (for --FOO[=ARG])
    while (($optstrip, $value, $_) = nextOption ()) {
      SWITCH: {
          if (/^-[?]|^--help/) {
              help ();
              exit 0;
              last SWITCH;
          }
          if (/^-V|^--version/) {
              version ();
              exit 0;
              last SWITCH;
          }
          if (/^-0|^--null/) {
              $null_p = 1;
              last SWITCH;
          }
          if (/^-c|^--config-file/) {
              push (@config_files, $value);
              last SWITCH;
          }
          if (/^--configuration/) {
              push (@configuration, $value);
              last SWITCH;
          }
          if (/^-T|^--files-from/) {
              push (@files_from, $value);
              last SWITCH;
          }
          if (/^-m|^--modules/) {
              push (@module_list, split (' ', $value));
              last SWITCH;
          }
          if (/^--storage-name/) {
              $sto_name = $value;
              last SWITCH;
          }
          if (/^--storage-options/) {
              $sto_opts = $value;
              last SWITCH;
          }
          if (/^--storage-type/) {
              $sto_type = $value;
              last SWITCH;
          }
          if (/^--no-output/) {
              $output = undef;
              last SWITCH;
          }
          if (/^-o|--output/) {
              $output = $value;
              last SWITCH;
          }
          if (/^-t|^--output-format/) {
              $output_format = $value;
              last SWITCH;
          }
      }
    }
}
Getopt::Mixed::cleanup ();

## Check for the extra arguments
unless ((1 + $#ARGV > 0) or (1 + $#files_from > 0)) {
    print STDERR (""
                  . "$progname: No filename given\n"
                  . "Try `$progname --help' for more information.\n");
    exit 1;
}

### Main code

my $out = undef;
if (defined ($output)) {
    $out = open_file ($output, 1)
        or die ("$output: cannot open file");
}

my $serializer
    = new RDF::Redland::Serializer ($output_format)
    or die ("$output_format: cannot initialize serializer");

my $sto
    = new RDF::Redland::Storage ($sto_type, $sto_name,
                                 $sto_opts);
my $cf_obj
    = new fdrdf::config ();
my $config
    = $cf_obj->config ();
my $model = new RDF::Redland::Model ($sto, "");

my $callback
    = new fdrdf::callback ("config", $config,
                           "selected_predicate",
                           $cf_obj->predicate ("selected"));

{
    my $p
        = new RDF::Redland::Parser ($config_format)
        or die ("cannot initialize RDF::Redland::Parser: ", $!);
    my $base_uri
        = new RDF::Redland::URI ("http://example.invalid/");
    for my $c (@config_files) {
        ## FIXME: I didn't manage parse_into_model () to work
        my $s;
        {
            local $/ = undef;
            open (my $io, "<", $c)
                or die ($c, ": ", $!);
            defined ($s = <$io>)
                or die ($c, ": ", $!);
            close ($io);
        }
        defined ($p->parse_string_into_model ($s, $base_uri, $config))
            or die ($c, ": ", $!);
    }
    # print STDERR ("Cf. size: ", $config->size (), "\n");
}

$cf_obj->select (@configuration);
my $use_default_p
    = ! $cf_obj->has_selected_p ();
$cf_obj->activate_default ()
    if ($use_default_p);
$cf_obj->activate_includes ();

## show selected configuration nodes (debug?)
if ($show_config_nodes_p) {
    $cf_obj->show_selected (\*STDERR);
}

my %the_modules
    = ("io"     => { },
       "chunks" => { });
init_modules ($callback, \%the_modules, @module_list);

my %process_info
    = ("config"     => $config,
       "model"      => $model,
       "modules"    => \%the_modules);
foreach my $i (@files_from) {
    my $in = open_file ($i, 0);
    unless (defined ($in)) {
        die ("$i: cannot open file");
    }

    local $_;
    local $/ = "\0"
        if ($null_p);
    while (<$in>) {
        chop ();
        process_file (\%process_info, $_);
    }
}
foreach my $file (@ARGV) {
    process_file (\%process_info, $file);
}

if (defined ($out)) {
    my ($uuid_bit, $uuid_s);
    UUID::generate ($uuid_bit);
    UUID::unparse  ($uuid_bit, $uuid_s);
    my $base
        = new RDF::Redland::URI ("uuid:" . $uuid_s);
    my $ser = $serializer;
    my $str
        = $ser->serialize_model_to_string ($base, $model);
    print $out $str;
}

## Local variables:
## fill-column: 72
## indent-tabs-mode: nil
## outline-regexp: "###"
## End:
### fdrdf.pl ends here
