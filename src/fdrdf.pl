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

# use DateTime;
use English qw(-no_match_vars);
use Getopt::Mixed "nextOption";
# use MIME::Base64;
use RDF::Redland;
use URI::file;
use UUID;

use fdrdf::module qw(&module_entry &module_tags &module_invoke_tag);
use fdrdf::util;

$progname = $PROGRAM_NAME;
$progname =~ s/^.*\///;

## NB: a la GNU Autotools
$PACKAGE = "fdrdf";
$PACKAGE_NAME = "FDRDF";
$PACKAGE_VERSION = "0.1";
$PACKAGE_BUGREPORT = 'ivan@theory.asu.ru';

sub init_module {
    my ($config, $module) = @_;

    my $f = "fdrdf/module/" . $module . ".pm";
    eval { require $f; };
    die ("$m: failed to load: $@")
        if ($@);

    my $pkg = "fdrdf::module::" . $module;
    my $handle
        = new $pkg (module_entry (), $config);

    ## .
    return $handle;
}

sub check_module_tags {
    my ($modules, $name, $e_ref) = @_;

    my @tags
        = module_tags ($e_ref);
    foreach my $tag (@tags) {
      SWITCH: {
          if ($tag eq "io") {
              $modules->{$tag}->{$name} = $e_ref;
              last SWITCH;
          }
          print STDERR
              "$progname: Warning: Unknown module tag $tag; ignored\n";
      }
    }
}

sub init_modules {
    my ($config, $handles, @modules) = @_;
    foreach my $m (@modules) {
        next
            if (exists $$handles{$m});
        my $handle;
        $handle = init_module ($config, $m)
            or die ("$m: failed to initialize module");
        check_module_tags ($handles, $m, $handle);
    }
}

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
    foreach my $m (keys (%{$modules->{"io"}})) {
        my $handle = $modules->{"io"}->{$m};
        open (my $io, "<&", $io1)
            or die ();
        module_invoke_tag ($handle, "io", $model, $subject, $io);
        close ($io);
    }
    close_file ($io1);
}

## FIXME: use the Perl port of GNU Argp

sub help {
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
           . "  -m, --modules=MODULES     "
           . " use MODULES to process files\n"
           . "  -o, --output=FILE         "
           . " write result to FILE instead of standard output\n"
           . "  -T, --files-from=FILE     "
           . " get filenames to process from FILE\n"
           . "  -t, --output-format=FORMAT"
           . " use specific librdf output serialization;\n"
           . "                            "
           . " may be: `rdfxml' (default), `ntriples'\n"
           . "\n"
           . "  -?, --help                 Give this help list\n"
           . "      --usage                Give a short usage message\n"
           . "  -V, --version              Print program version\n"
           . "\n"
           . "Mandatory or optional arguments to long options"
           . " are also mandatory or optional\n"
           . "for any corresponding short options.\n"
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

my @config_files = ();
my @module_list;
my $null_p = 0;
my @files_from = ();
my $output = "-";
my $output_format = "rdfxml";

Getopt::Mixed::init ("?      help>?"
                     . " V   version>V"
                     . " 0   null>0"
                     . " c=s config-file>c"
                     . " T=s files-from>T"
                     . " m=s modules>m"
                     . " o=s output>o"
                     . " t=s output-format>t");
{
    my $optstrip, $value, $_;
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
          if (/^-T|^--files-from/) {
              push (@files_from, $value);
              last SWITCH;
          }
          if (/^-m|^--modules/) {
              push (@module_list, split (' ', $value));
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

my $out = open_file ($output, 1);
unless (defined ($out)) {
    die ("$output: cannot open file");
}

my $serializer
    = new RDF::Redland::Serializer ($output_format)
    or die ("$output_format: cannot initialize serializer");

my $sto = new RDF::Redland::Storage ("hashes", "test",
                                     "new='yes', hash-type='memory'");
my $config
    = new RDF::Redland::Model ($sto, "");
my $model = new RDF::Redland::Model ($sto, "");

my %the_modules = ();
init_modules ($config, \%the_modules, @module_list);

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

{
    my $uuid_bit, $uuid_s;
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
## End:
### fdrdf.pl ends here
