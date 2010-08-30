#!/usr/bin/perl
### fdrdf.pl  -*- Perl -*-

### Copyright (C) 2010 Ivan Shmakov

## Based on: fcfs-xml.pl  (2010-04-29 11:10:52+00:00.)
## Based on: dda-stage.pl (2009-09-29 15:17:13+00:00.)

# use DateTime;
use Getopt::Mixed "nextOption";
use IO::File;
# use MIME::Base64;
use RDF::Redland;
use URI::file;
use UUID;

## FIXME: basename?
$progname = $PROGRAM_NAME;

sub open_file {
    my ($fn, $write_p) = @_;

    ## .
    return
        (($fn ne "-") ? new IO::File ($fn, $write_p ? O_WRONLY : O_RDONLY)
         : $write_p ? STDOUT
         : STDIN);
}

sub close_file {
    my ($f) = @_;
    close ($f)
        unless ($f eq STDIN || $f eq STDOUT);
}

sub init_module {
    my ($config, $module) = @_;

    my $f = "fdrdf/module/" . $module . ".pm";
    eval { require $f; };
    die ("$m: failed to load: $@")
        if ($@);

    my $pkg = "fdrdf::module::" . $module;
    my $handle = new $pkg ($config);

    ## .
    return $handle;
}

sub init_modules {
    my ($config, $handles, @modules) = @_;
    foreach my $m (@modules) {
        next
            if (exists $$handles{$m});
        my $handle;
        $handle = init_module ($config, $m)
            or die ("$m: failed to initialize module");
        $$handles{$m} = $handle;
    }
}

sub process_file {
    my ($model, $modules, $filename) = @_;
    my $uri
        = URI::file->new_abs ($filename);
    ## FIXME: implement proper escaping
    my $uri_s
        = $uri->as_string ();
    my $subject = new RDF::Redland::URINode ($uri_s);
    foreach my $m (keys (%$modules)) {
        my $handle = $$modules{$m};
        my ($sub, @args) = @$handle;
        my $io = open_file ($filename, 0)
            or die ("$filename: cannot open");
        push (@args, $model, $subject, $io);
        &$sub (@args);
        close_file ($io);
    }
}

my @config_files = ();
my %the_modules = ();
my $null_p = 0;
my @files_from = ();
my $output = "-";
## FIXME: handle GNU standard --help and --version options
Getopt::Mixed::init ("0 null>0"
                     . " c=s config-file>c"
                     . " T=s files-from>T"
                     . " m=s modules>m"
                     . " o=s output>o");
{
    my $optstrip, $value, $_;
    ## FIXME: should distinguish --FOO= from --FOO (for --FOO[=ARG])
    while (($optstrip, $value, $_) = nextOption ()) {
      SWITCH: {
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
              init_modules ($config, \%the_modules,
                            split (' ', $value));
              last SWITCH;
          }
          if (/^-o|--output/) {
              $output = $value;
              last SWITCH;
          }
      }
    }
}
Getopt::Mixed::cleanup ();

## Check for the extra arguments
unless ((1 + $#ARGV > 0) or (1 + $#files_from > 0)) {
    my $p = $progname;
    print STDERR (""
                  . "Usage: " . $p . " [OPTION...] FILE...\n"
                  . "  or:  " . $p . " [OPTION...] -T FILE [FILE...]\n");
    exit 1;
}

my $out = open_file ($output, 1);
unless (defined ($out)) {
    die ("$output: cannot open file");
}

my $sto = new RDF::Redland::Storage ("hashes", "test",
                                     "new='yes', hash-type='memory'");
my $model = new RDF::Redland::Model ($sto, "");

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
        process_file ($model, \%the_modules, $_);
    }
}
foreach my $file (@ARGV) {
    process_file ($model, \%the_modules, $file);
}

{
    my $uuid_bit, $uuid_s;
    UUID::generate ($uuid_bit);
    UUID::unparse  ($uuid_bit, $uuid_s);
    my $base
        = new RDF::Redland::URI ("uuid:" . $uuid_s);
    my $ser = new RDF::Redland::Serializer ("rdfxml");
    my $str
        = $ser->serialize_model_to_string ($base, $model);
    print $out $str;
}

## Local variables:
## fill-column: 72
## indent-tabs-mode: nil
## End:
### fdrdf.pl ends here
