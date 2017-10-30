#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

require "epn-options.pm";
require "ribo.pm";

# make sure the RIBODIR, INFERNALDIR and EASELDIR environment variables are set
my $env_ribotyper_dir     = ribo_VerifyEnvVariableIsValidDir("RIBODIR");
#my $env_infernal_exec_dir = ribo_VerifyEnvVariableIsValidDir("INFERNALDIR");
#my $env_easel_exec_dir    = ribo_VerifyEnvVariableIsValidDir("EASELDIR");
my $df_model_dir          = $env_ribotyper_dir . "/models/";

# Currently, we require infernal and easel executables are in user's path, 
# but don't check. The program will die if the commands using them fail. 
# Below block is left in in case we want to use it eventually.
# make sure the required executables are executable
#my %execs_H = (); # hash with paths to all required executables
#$execs_H{"cmsearch"}    = $env_infernal_exec_dir . "/cmsearch";
#$execs_H{"esl-seqstat"} = $env_easel_exec_dir    . "/esl-seqstat";
#$execs_H{"esl-sfetch"}  = $env_easel_exec_dir    . "/esl-sfetch";
#ribo_ValidateExecutableHash(\%execs_H);
 
#########################################################
# Command line and option processing using epn-options.pm
#
# opt_HH: 2D hash:
#         1D key: option name (e.g. "-h")
#         2D key: string denoting type of information 
#                 (one of "type", "default", "group", "requires", "incompatible", "preamble", "help")
#         value:  string explaining 2D key:
#                 "type":         "boolean", "string", "integer" or "real"
#                 "default":      default value for option
#                 "group":        integer denoting group number this option belongs to
#                 "requires":     string of 0 or more other options this option requires to work, each separated by a ','
#                 "incompatible": string of 0 or more other options this option is incompatible with, each separated by a ','
#                 "preamble":     string describing option for preamble section (beginning of output from script)
#                 "help":         string describing option for help section (printed if -h used)
#                 "setby":        '1' if option set by user, else 'undef'
#                 "value":        value for option, can be undef if default is undef
#
# opt_order_A: array of options in the order they should be processed
# 
# opt_group_desc_H: key: group number (integer), value: description of group for help output
my %opt_HH = ();      
my @opt_order_A = (); 
my %opt_group_desc_H = ();

# Add all options to %opt_HH and @opt_order_A.
# This section needs to be kept in sync (manually) with the &GetOptions call below
$opt_group_desc_H{"1"} = "basic options";
#     option            type       default               group   requires incompat    preamble-output                                   help-output    
opt_Add("-h",           "boolean", 0,                        0,    undef, undef,      undef,                                            "display this help",                                  \%opt_HH, \@opt_order_A);
opt_Add("-f",           "boolean", 0,                        1,    undef, undef,      "forcing directory overwrite",                    "force; if <output directory> exists, overwrite it",  \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                                     "be verbose; output commands to stdout as they're run", \%opt_HH, \@opt_order_A);
opt_Add("-n",           "integer", 0,                        1,    undef, undef,      "use <n> CPUs",                                   "use <n> CPUs", \%opt_HH, \@opt_order_A);
opt_Add("-i",           "string",  undef,                    1,    undef, undef,      "use model info file <s> instead of default",     "use model info file <s> instead of default", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"2"} = "options for controlling the first round search algorithm";
#       option               type   default                group  requires incompat    preamble-output                            help-output    
opt_Add("--1hmm",          "boolean", 0,                       2,  undef,   undef,     "run first round in slower HMM mode",     "run first round in slower HMM mode", \%opt_HH, \@opt_order_A);
opt_Add("--1slow",         "boolean", 0,                       2,  undef,   undef,     "run first round in slow CM mode",        "run first round in slow CM mode that scores structure+sequence",    \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"3"} = "options for controlling the second round search algorithm";
#       option               type   default                group  requires incompat    preamble-output                        help-output    
opt_Add("--2slow",         "boolean", 0,                       3,  undef,   "--1slow", "run second round in slow CM mode",    "run second round in slow CM mode that scores structure+sequence",    \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"4"} = "options related to bit score REPORTING thresholds";
#     option                 type   default                group   requires incompat   preamble-output                                            help-output    
opt_Add("--minpsc",        "real",   "20.",                   4,  undef,   undef,      "set minimum bit score cutoff for primary hits to <x>",    "set minimum bit score cutoff for primary hits to include to <x> bits", \%opt_HH, \@opt_order_A);
opt_Add("--minssc",        "real",   "10.",                   4,  undef,   undef,      "set minimum bit score cutoff for secondary hits to <x>",  "set minimum bit score cutoff for secondary hits to include to <x> bits", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"5"} = "options for controlling which sequences PASS/FAIL (turning on optional failure criteria)";
#     option                 type   default                group   requires incompat    preamble-output                                          help-output    
opt_Add("--minusfail",  "boolean",   0,                        5,  undef,   undef,      "hits on negative (minus) strand FAIL",                 "hits on negative (minus) strand defined as FAILures", \%opt_HH, \@opt_order_A);
opt_Add("--scfail",     "boolean",   0,                        5,  undef,   undef,      "seqs that fall below low score threshold FAIL",        "seqs that fall below low score threshold FAIL", \%opt_HH, \@opt_order_A);
opt_Add("--difffail",   "boolean",   0,                        5,  undef,   undef,      "seqs that fall below low score diff threshold FAIL",   "seqs that fall below low score difference threshold FAIL", \%opt_HH, \@opt_order_A);
opt_Add("--covfail",    "boolean",   0,                        5,  undef,   undef,      "seqs that fall below low coverage threshold FAIL",     "seqs that fall below low coverage threshold FAIL", \%opt_HH, \@opt_order_A);
opt_Add("--multfail",   "boolean",   0,                        5,  undef,   undef,      "seqs that have more than one hit to best model FAIL",  "seqs that have more than one hit to best model FAIL", \%opt_HH, \@opt_order_A);
opt_Add("--questfail",  "boolean",   0,                        5,"--inaccept",undef,    "seqs that score best to questionable models FAIL",     "seqs that score best to questionable models FAIL", \%opt_HH, \@opt_order_A);
opt_Add("--shortfail",  "integer",   0,                        5,  undef,   undef,      "seqs that are shorter than <n> nucleotides FAIL",      "seqs that are shorter than <n> nucleotides FAIL", \%opt_HH, \@opt_order_A);
opt_Add("--longfail",   "integer",   0,                        5,  undef,   undef,      "seqs that are longer than <n> nucleotides FAIL",       "seqs that are longer than <n> nucleotides FAIL", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"6"} = "options for controlling thresholds for failure/warning criteria";
#     option                 type    default               group   requires incompat    preamble-output                                            help-output    
opt_Add("--lowppossc",     "real",   "0.5",                    6,  undef,   undef,      "set minimum bit per position threshold to <x>",           "set minimum bit per position threshold for reporting suspiciously low scores to <x> bits", \%opt_HH, \@opt_order_A);
opt_Add("--tcov",          "real",   "0.86",                   6,  undef,   undef,      "set low total coverage threshold to <x>",                 "set low total coverage threshold to <x> fraction of target sequence", \%opt_HH, \@opt_order_A);
opt_Add("--tshortcov",     "real",   undef,                    6,"--tshortlen",undef,   "set low total coverage for short seqs threshold to <x>",  "set low total coverage threshold for short seqs to <x> fraction of target sequence", \%opt_HH, \@opt_order_A);
opt_Add("--tshortlen",   "integer",  undef,                    6,"--tshortcov",undef,   "set maximum length for short seqs coverage calc to <n>",  "set maximum length for short seq coverage threshold to <n> nucleotides", \%opt_HH, \@opt_order_A);
opt_Add("--lowpdiff",      "real",   "0.10",                   6,  undef,   "--absdiff","set low per-posn score difference threshold to <x>",      "set 'low'      per-posn score difference threshold to <x> bits", \%opt_HH, \@opt_order_A);
opt_Add("--vlowpdiff",     "real",   "0.04",                   6,  undef,   "--absdiff","set very low per-posn score difference threshold to <x>", "set 'very low' per-posn score difference threshold to <x> bits", \%opt_HH, \@opt_order_A);
opt_Add("--absdiff",    "boolean",   0,                        6,  undef,   undef,      "use total score diff threshold, not per-posn",            "use total score difference thresholds instead of per-posn", \%opt_HH, \@opt_order_A);
opt_Add("--lowadiff",      "real",   "100.",                   6,"--absdiff",undef,     "set 'low' total sc diff threshold to <x>",                "set 'low'      total score difference threshold to <x> bits", \%opt_HH, \@opt_order_A);
opt_Add("--vlowadiff",     "real",   "40.",                    6,"--absdiff",undef,     "set 'very low' total sc diff threshold to <x>",           "set 'very low' total score difference threshold to <x> bits", \%opt_HH, \@opt_order_A);
opt_Add("--maxoverlap", "integer",   "10",                     6,  undef,   undef,      "set maximum allowed model position overlap to <n>",       "set maximum allowed number of model positions to overlap before failure to <n>", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"7"} = "optional input files";
#       option               type   default                group  requires incompat  preamble-output                                  help-output    
opt_Add("--inaccept",     "string",  undef,                   7,  undef,   undef,    "read acceptable/questionable models from <s>",  "read acceptable/questionable domains/models from file <s>", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"8"} = "options that modify the behavior of --1slow or --2slow";
#       option               type   default                group  requires incompat    preamble-output                   help-output    
opt_Add("--mid",          "boolean", 0,                       8,  undef,  "--max",    "use --mid instead of --rfam",   "with --1slow/--2slow use cmsearch --mid option instead of --rfam", \%opt_HH, \@opt_order_A);
opt_Add("--max",          "boolean", 0,                       8,  undef,  "--mid",    "use --max instead of --rfam",   "with --1slow/--2slow use cmsearch --max option instead of --rfam", \%opt_HH, \@opt_order_A);
opt_Add("--smxsize",         "real", undef,                   8,"--max",   undef,      "with --max, use --smxsize <x>", "with --max also use cmsearch --smxsize <x>", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"9"} = "advanced options";
#       option               type   default                group  requires incompat             preamble-output                               help-output    
opt_Add("--evalues",      "boolean", 0,                       9,  undef,   "--ssualign",        "rank by E-values, not bit scores",           "rank hits by E-values, not bit scores", \%opt_HH, \@opt_order_A);
opt_Add("--skipsearch",   "boolean", 0,                       9,  undef,   "-f",                "skip search stage",                          "skip search stage, use results from earlier run", \%opt_HH, \@opt_order_A);
opt_Add("--noali",        "boolean", 0,                       9,  undef,   "--skipsearch",      "no alignments in output",                    "no alignments in output with --1hmm, --1slow, or --2slow", \%opt_HH, \@opt_order_A);
opt_Add("--samedomain",   "boolean", 0,                       9,  undef,   undef,               "top two hits can be same domain",            "top two hits can be to models in the same domain", \%opt_HH, \@opt_order_A);
opt_Add("--keep",         "boolean", 0,                       9,  undef,   undef,               "keep all intermediate files",                "keep all intermediate files that are removed by default", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: ribotyper.pl [-options] <fasta file to annotate> <output directory>\n";
$usage      .= "\n";
my $synopsis = "ribotyper.pl :: detect and classify ribosomal RNA sequences";
my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"}, 
                'f'            => \$GetOptions_H{"-f"},
                'v'            => \$GetOptions_H{"-v"},
                'n=s'          => \$GetOptions_H{"-n"},
                'i=s'          => \$GetOptions_H{"-i"},
# first round algorithm options
                '1hmm'          => \$GetOptions_H{"--1hmm"},
                '1slow'         => \$GetOptions_H{"--1slow"},
# first round algorithm options
                '2slow'         => \$GetOptions_H{"--2slow"},
# options controlling minimum bit score cutoff 
                'minpsc=s'    => \$GetOptions_H{"--minpsc"},
                'minssc=s'    => \$GetOptions_H{"--minssc"},
                'lowppossc'   => \$GetOptions_H{"--lowppossc"},
# options controlling which sequences pass/fail
                'minusfail'    => \$GetOptions_H{"--minusfail"},
                'scfail'       => \$GetOptions_H{"--scfail"},
                'difffail'     => \$GetOptions_H{"--difffail"},
                'covfail'      => \$GetOptions_H{"--covfail"},
                'multfail'     => \$GetOptions_H{"--multfail"},
                'questfail'    => \$GetOptions_H{"--questfail"},
                'shortfail=s'  => \$GetOptions_H{"--shortfail"},
                'longfail=s'   => \$GetOptions_H{"--longfail"},
# options controlling thresholds for warnings and failures
                'lowppossc'    => \$GetOptions_H{"--lowppossc"},
                'tcov=s'       => \$GetOptions_H{"--tcov"}, 
                'tshortcov=s'  => \$GetOptions_H{"--tshortcov"}, 
                'tshortlen=s'  => \$GetOptions_H{"--tshortlen"}, 
                'lowpdiff=s'   => \$GetOptions_H{"--lowpdiff"},
                'vlowpdiff=s'  => \$GetOptions_H{"--vlowpdiff"},
                'absdiff'      => \$GetOptions_H{"--absdiff"},
                'lowadiff=s'   => \$GetOptions_H{"--lowadiff"},
                'vlowadiff=s'  => \$GetOptions_H{"--vlowadiff"},
                'maxoverlap=s' => \$GetOptions_H{"--maxoverlap"},
# optional input files
                'inaccept=s'   => \$GetOptions_H{"--inaccept"},
# options that affect --1slow and --2slow
                'mid'          => \$GetOptions_H{"--mid"},
                'max'          => \$GetOptions_H{"--max"},
                'smxsize=s'    => \$GetOptions_H{"--smxsize"},
# advanced options
                'evalues'      => \$GetOptions_H{"--evalues"},
                'skipsearch'   => \$GetOptions_H{"--skipsearch"},
                'noali'        => \$GetOptions_H{"--noali"},
                'keep'         => \$GetOptions_H{"--keep"},
                'samedomain'   => \$GetOptions_H{"--samedomain"});

my $total_seconds     = -1 * ribo_SecondsSinceEpoch(); # by multiplying by -1, we can just add another ribo_SecondsSinceEpoch call at end to get total time
my $executable        = $0;
my $date              = scalar localtime();
my $version           = "0.08";
my $model_version_str = "0p02"; # models are unchanged since version 0.02
my $releasedate       = "Oct 2017";
my $package_name      = "ribotyper";

# make *STDOUT file handle 'hot' so it automatically flushes whenever we print to it
select *STDOUT;
$| = 1;

# print help and exit if necessary
if((! $options_okay) || ($GetOptions_H{"-h"})) { 
  ribo_OutputBanner(*STDOUT, $package_name, $version, $releasedate, $synopsis, $date);
  opt_OutputHelp(*STDOUT, $usage, \%opt_HH, \@opt_order_A, \%opt_group_desc_H);
  if(! $options_okay) { die "ERROR, unrecognized option;"; }
  else                { exit 0; } # -h, exit with 0 status
}

# check that number of command line args is correct
if(scalar(@ARGV) != 2) {   
  print "Incorrect number of command line arguments.\n";
  print $usage;
  print "\nTo see more help on available options, do ribotyper.pl -h\n\n";
  exit(1);
}
my ($seq_file, $dir_out) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

# do some final option checks that are currently too sophisticated for epn-options
if(opt_Get("--evalues", \%opt_HH)) { 
  if((! opt_Get("--nhmmer", \%opt_HH)) && 
     (! opt_Get("--1hmm", \%opt_HH)) && 
     (! opt_Get("--1slow", \%opt_HH)) &&
     (! opt_Get("--2slow", \%opt_HH))) { 
    die "ERROR, --evalues requires one of --nhmmer, --1hmm, --1slow or --2slow";
  }
}
if(opt_Get("--mid", \%opt_HH)) { 
  if((! opt_Get("--1slow", \%opt_HH)) &&
     (! opt_Get("--2slow", \%opt_HH))) { 
    die "ERROR, --mid requires one of --1slow or --2slow";
  }
}
if(opt_Get("--max", \%opt_HH)) { 
  if((! opt_Get("--1slow", \%opt_HH)) &&
     (! opt_Get("--2slow", \%opt_HH))) { 
    die "ERROR, --max requires one of --1slow or --2slow";
  }
}
if(opt_Get("--noali", \%opt_HH)) { 
  if((! opt_Get("--nhmmer", \%opt_HH)) && 
     (! opt_Get("--1hmm", \%opt_HH)) && 
     (! opt_Get("--1slow", \%opt_HH)) && 
     (! opt_Get("--2slow", \%opt_HH))) { 
    die "ERROR, --noali requires one of --nhmmer, --1hmm, --1slow or --2slow";
  }
}
if(opt_IsUsed("--lowpdiff",\%opt_HH) || opt_IsUsed("--vlowpdiff",\%opt_HH)) { 
  if(opt_Get("--lowpdiff",\%opt_HH) < opt_Get("--vlowpdiff",\%opt_HH)) { 
    die sprintf("ERROR, with --lowpdiff <x> and --vlowpdiff <y>, <x> must be less than <y> (got <x>: %f, <y>: %f)\n", 
                opt_Get("--lowpdiff",\%opt_HH), opt_Get("--vlowpdiff",\%opt_HH)); 
  }
}
if(opt_IsUsed("--lowadiff",\%opt_HH) || opt_IsUsed("--vlowadiff",\%opt_HH)) { 
  if(opt_Get("--lowadiff",\%opt_HH) < opt_Get("--vlowadiff",\%opt_HH)) { 
    die sprintf("ERROR, with --lowadiff <x> and --vlowadiff <y>, <x> must be less than <y> (got <x>: %f, <y>: %f)\n", 
                opt_Get("--lowadiff",\%opt_HH), opt_Get("--vlowadiff",\%opt_HH)); 
  }
}
if((opt_IsUsed("--shortfail",\%opt_HH) && opt_IsUsed("--longfail",\%opt_HH)) && 
   (opt_Get("--shortfail",\%opt_HH) >= opt_Get("--longfail",\%opt_HH))) { 
  die sprintf("ERROR, with --shortfail <n1> and --longfail <n2>, <n1> must be less than <n2> (got <n1>: %f, <n2>: %f)\n", 
                opt_Get("--shortfail",\%opt_HH), opt_Get("--longfail",\%opt_HH)); 
}

my $min_primary_sc   = opt_Get("--minpsc", \%opt_HH);
my $min_secondary_sc = opt_Get("--minssc", \%opt_HH);
if($min_secondary_sc > $min_primary_sc) { 
  if((opt_IsUsed("--minpsc", \%opt_HH)) && (opt_IsUsed("--minssc", \%opt_HH))) { 
    die sprintf("ERROR, with --minpsc <x> and --minssc <y>, <x> must be less than or equal to <y> (got <x>: %f, <y>: %f)\n", 
                opt_Get("--minpsc",\%opt_HH), opt_Get("--minssc",\%opt_HH)); 
  }
  elsif(opt_IsUsed("--minpsc", \%opt_HH)) { 
    die sprintf("ERROR, with --minpsc <x>, <x> must be less than or equal to <y>=%d (default value for --minssc)\nOr you must lower <y> with the --minssc option too.\n", 
                opt_Get("--minpsc",\%opt_HH), opt_Get("--minssc",\%opt_HH)); 
  }
  elsif(opt_IsUsed("--minssc", \%opt_HH)) { 
    die sprintf("ERROR, with --minssc <y>, <x> must be greater or equal to <x>=%d (default value for --minpsc)\nOr you must lower <x> with the --minpsc option too.\n", 
                opt_Get("--minssc",\%opt_HH), opt_Get("--minpsc",\%opt_HH)); 
  }
  else { 
    die "ERROR default values for --minpsc and --minssc are messed up." 
    # this will only happen if the default values in this file are changed so that --minpsc default is less than --minssc default
  }
}

my $cmd         = undef; # a command to be run by ribo_RunCommand()
my @to_remove_A = ();    # array of files to remove at end
my $r1_secs     = undef; # number of seconds required for round 1 search
my $r2_secs     = undef; # number of seconds required for round 2 search
my $ncpu        = opt_Get("-n" , \%opt_HH); # number of CPUs to use with search command (default 0: --cpu 0)
if($ncpu == 1) { $ncpu = 0; } # prefer --cpu 0 to --cpu 1

# the way we handle the $dir_out differs markedly if we have --skipsearch enabled
# so we handle that separately
if(opt_Get("--skipsearch", \%opt_HH)) { 
  if(-d $dir_out) { 
    # this is what we expect, do nothing
  }
  elsif(-e $dir_out) { 
    die "ERROR with --skipsearch, $dir_out must already exist as a directory, but it exists as a file, delete it first, then run without --skipsearch";
  }
  else { 
    die "ERROR with --skipsearch, $dir_out must already exist as a directory, but it does not. Run without --skipsearch";
  }
}
else {  # --skipsearch not used, normal case
  # if $dir_out already exists remove it only if -f also used
  if(-d $dir_out) { 
    $cmd = "rm -rf $dir_out";
    if(opt_Get("-f", \%opt_HH)) { ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH)); }
    else                        { die "ERROR directory named $dir_out already exists. Remove it, or use -f to overwrite it."; }
  }
  elsif(-e $dir_out) { 
    $cmd = "rm $dir_out";
    if(opt_Get("-f", \%opt_HH)) { ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH)); }
    else                        { die "ERROR a file named $dir_out already exists. Remove it, or use -f to overwrite it."; }
  }
  # if $dir_out does not exist, create it
  if(! -d $dir_out) { 
    $cmd = "mkdir $dir_out";
    ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH));
  }
}
my $dir_out_tail = $dir_out;
$dir_out_tail    =~ s/^.+\///; # remove all but last dir
my $out_root     = $dir_out .   "/" . $dir_out_tail   . ".ribotyper";

my $df_modelinfo_file = $df_model_dir . "ribo." . $model_version_str . ".modelinfo";
my $modelinfo_file = undef;
if(! opt_IsUsed("-i", \%opt_HH)) {
  $modelinfo_file = $df_modelinfo_file;
}
else { 
  $modelinfo_file = opt_Get("-i", \%opt_HH);
}
# make sure the sequence and modelinfo files exists
ribo_CheckIfFileExistsAndIsNonEmpty($seq_file, "sequence file", undef, 1); # 1 says: die if it doesn't exist or is empty
if(! opt_IsUsed("-i", \%opt_HH)) {
  ribo_CheckIfFileExistsAndIsNonEmpty($modelinfo_file, "default model info file", undef, 1); # 1 says: die if it doesn't exist or is empty
}
else { # -i used on the command line
  ribo_CheckIfFileExistsAndIsNonEmpty($modelinfo_file, "model info file specified with -i", undef, 1); # 1 says: die if it doesn't exist or is empty
}
# we check for the existence of model file after we parse the model info file

#############################################
# output program banner and open output files
#############################################
# output preamble
my @arg_desc_A = ();
my @arg_A      = ();

push(@arg_desc_A, "target sequence input file");
push(@arg_A, $seq_file);

push(@arg_desc_A, "output directory name");
push(@arg_A, $dir_out);

push(@arg_desc_A, "model information input file");
push(@arg_A, $modelinfo_file);

ribo_OutputBanner(*STDOUT, $package_name, $version, $releasedate, $synopsis, $date);
opt_OutputPreamble(*STDOUT, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

##############################################
# determine search methods for rounds 1 and 2
##############################################
my $alg1 = undef; # can be any of "fast", "hmmonly", or "slow"
if   (opt_Get("--1hmm",  \%opt_HH))   { $alg1 = "hmmonly"; }
elsif(opt_Get("--1slow", \%opt_HH))   { $alg1 = "slow"; }
else                                  { $alg1 = "fast"; }

my $alg2 = undef; # can be "hmmonly" or "slow"
if(! opt_Get("--1slow", \%opt_HH)) { 
  if(opt_Get("--2slow", \%opt_HH)) { 
    $alg2 = "slow"; 
  }
  elsif(! opt_Get("--1hmm", \%opt_HH)) { 
    $alg2 = "hmmonly";
  }
}

##############################
# define and open output files
##############################
my $r1_unsrt_long_out_file  = $out_root . ".r1.unsrt.long.out";
my $r1_unsrt_short_out_file = $out_root . ".r1.unsrt.short.out";
my $r1_srt_long_out_file    = undef;
my $r1_srt_short_out_file   = undef;
my $r2_unsrt_long_out_file  = undef;
my $r2_unsrt_short_out_file = undef;
my $r2_srt_long_out_file    = undef;
my $r2_srt_short_out_file   = undef;
my $final_long_out_file     = $out_root . ".long.out";  # the final long output file, created combining r1 and r2 files (or copying r1 file, if r2 is skipped)
my $final_short_out_file    = $out_root . ".short.out"; # the final short output file, created combining r1 and r2 files (or copying r1 file, if r2 is skipped)
if(defined $alg2) { 
  $r1_srt_long_out_file    = $out_root . ".r1.long.out";
  $r1_srt_short_out_file   = $out_root . ".r1.short.out";
  $r2_unsrt_long_out_file  = $out_root . ".r2.unsrt.long.out";
  $r2_unsrt_short_out_file = $out_root . ".r2.unsrt.short.out";
  $r2_srt_long_out_file    = $out_root . ".r2.long.out";
  $r2_srt_short_out_file   = $out_root . ".r2.short.out";
}
else { 
  $r1_srt_long_out_file    = $out_root . ".long.out";  # same name as $final_long_out_file, which is ok, the r1 file is the final file
  $r1_srt_short_out_file   = $out_root . ".short.out"; # same name as $final_short_out_file, which is ok, the r1 file is the final file
}

my $r1_unsrt_long_out_FH  = undef; # output file handle for unsorted long output file
my $r1_unsrt_short_out_FH = undef; # output file handle for unsorted short output file
my $r1_srt_long_out_FH    = undef; # output file handle for sorted long output file
my $r1_srt_short_out_FH   = undef; # output file handle for sorted short output file
my $r2_unsrt_long_out_FH  = undef; # output file handle for unsorted long output file
my $r2_unsrt_short_out_FH = undef; # output file handle for unsorted short output file
my $r2_srt_long_out_FH    = undef; # output file handle for unsorted long output file
my $r2_srt_short_out_FH   = undef; # output file handle for unsorted short output file
my $final_long_out_FH     = undef; # output file handle for final long output file
my $final_short_out_FH    = undef; # output file handle for final short output file

if(! opt_Get("--keep", \%opt_HH)) { 
  push(@to_remove_A, $r1_unsrt_long_out_file);
  push(@to_remove_A, $r1_unsrt_short_out_file);
  push(@to_remove_A, $r1_srt_long_out_file);
  push(@to_remove_A, $r1_srt_short_out_file);
  if(defined $alg2) { 
    push(@to_remove_A, $r2_unsrt_long_out_file);
    push(@to_remove_A, $r2_unsrt_short_out_file);
    push(@to_remove_A, $r2_srt_long_out_file);
    push(@to_remove_A, $r2_srt_short_out_file);
  }
}

open($r1_unsrt_long_out_FH,  ">", $r1_unsrt_long_out_file)  || die "ERROR unable to open $r1_unsrt_long_out_file for writing";
open($r1_unsrt_short_out_FH, ">", $r1_unsrt_short_out_file) || die "ERROR unable to open $r1_unsrt_short_out_file for writing";
open($r1_srt_long_out_FH,    ">", $r1_srt_long_out_file)    || die "ERROR unable to open $r1_srt_long_out_file for writing";
open($r1_srt_short_out_FH,   ">", $r1_srt_short_out_file)   || die "ERROR unable to open $r1_srt_short_out_file for writing";
if(defined $alg2) { 
  open($r2_unsrt_long_out_FH,  ">", $r2_unsrt_long_out_file)  || die "ERROR unable to open $r2_unsrt_long_out_file for writing";
  open($r2_unsrt_short_out_FH, ">", $r2_unsrt_short_out_file) || die "ERROR unable to open $r2_unsrt_short_out_file for writing";
  open($r2_srt_long_out_FH,    ">", $r2_srt_long_out_file)    || die "ERROR unable to open $r2_srt_long_out_file for writing";
  open($r2_srt_short_out_FH,   ">", $r2_srt_short_out_file)   || die "ERROR unable to open $r2_srt_short_out_file for writing";
  open($final_long_out_FH,     ">", $final_long_out_file)     || die "ERROR unable to open $final_long_out_file for writing";
  open($final_short_out_FH,    ">", $final_short_out_file)    || die "ERROR unable to open $final_short_out_file for writing";
}
my $have_evalues_r1 = determine_if_we_have_evalues(1, \%opt_HH);
my $have_evalues_r2 = determine_if_we_have_evalues(2, \%opt_HH);
my @ufeature_A    = (); # array of unexpected feature strings
my %ufeature_ct_H = (); # hash of counts of unexpected features (keys are elements of @{$ufeature_A})
initialize_ufeature_stats(\@ufeature_A, \%ufeature_ct_H, \%opt_HH);

###########################################################################
# Step 1: Parse/validate input files
###########################################################################
my $progress_w = 48; # the width of the left hand column in our progress output, hard-coded
my $start_secs = ribo_OutputProgressPrior("Validating input files", $progress_w, undef, *STDOUT);

# parse model info file, which checks that all CM files exist
# variables related to fams and domains
my %family_H      = (); # hash of fams,    key: model name, value: name of family model belongs to (e.g. SSU)
my %domain_H      = (); # hash of domains, key: model name, value: name of domain model belongs to (e.g. Archaea)
my %indi_cmfile_H = (); # hash of individual CM files; key model name: path to individual CM file for this model
my %sfetchfile_H  = (); # key is model, value is name of sfetch input file to use to create $seqfile_H{$model}
my %seqfile_H     = (); # key is model, value is name of sequence file search this model with for round 2, undef if none

my $master_model_file = parse_modelinfo_file($modelinfo_file, $df_model_dir, \%family_H, \%domain_H, \%indi_cmfile_H, \%opt_HH);

# parse the model file and make sure that there is a 1:1 correspondence between 
# models in the models file and models listed in the model info file
my %width_H = (); # hash, key is "model" or "target", value is maximum length of any model/target
$width_H{"model"} = parse_and_validate_model_files($master_model_file, \%family_H, \%indi_cmfile_H);

# determine max width of domain, family, and classification (formed as family.domain)
$width_H{"domain"}         = length("domain");
$width_H{"family"}         = length("fam");
$width_H{"classification"} = length("classification");
my $model;
foreach $model (keys %domain_H) { 
  my $domain_len = length($domain_H{$model});
  my $family_len = length($family_H{$model});
  my $class_len  = $domain_len + $family_len + 1; # +1 is for the '.' separator
  if($domain_len > $width_H{"domain"})         { $width_H{"domain"}         = $domain_len; }
  if($family_len > $width_H{"family"})         { $width_H{"family"}         = $family_len; } 
  if($class_len  > $width_H{"classification"}) { $width_H{"classification"} = $class_len;  }
}

# parse input accept file, if nec
my %accept_H   = ();
my %question_H = ();
if(opt_IsUsed("--inaccept", \%opt_HH)) { 
  foreach $model (keys %domain_H) { 
    $accept_H{$model}   = 0;
    $question_H{$model} = 0;
  }    
  parse_inaccept_file(opt_Get("--inaccept", \%opt_HH), \%accept_H, \%question_H);
}
else { # --inaccept not used, all models are acceptable
  foreach $model (keys %domain_H) { 
    $accept_H{$model}   = 1;
    $question_H{$model} = 0;
  }   
} 

# check for SSI index file for the sequence file,
# if it doesn't exist, create it
my $ssi_file = $seq_file . ".ssi";
if(ribo_CheckIfFileExistsAndIsNonEmpty($ssi_file, undef, undef, 0) != 1) { 
  #ribo_RunCommand($execs_H{"esl-sfetch"} . " --index $seq_file > /dev/null", opt_Get("-v", \%opt_HH));
  ribo_RunCommand("esl-sfetch --index $seq_file > /dev/null", opt_Get("-v", \%opt_HH));
  if(ribo_CheckIfFileExistsAndIsNonEmpty($ssi_file, undef, undef, 0) != 1) { 
    die "ERROR, tried to create $ssi_file, but failed"; 
  }
}
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

###########################################################################
# Step 2: Use esl-seqstat to determine sequence lengths of all target seqs
###########################################################################
$start_secs = ribo_OutputProgressPrior("Determining target sequence lengths", $progress_w, undef, *STDOUT);
my $tot_nnt = 0;   # total number of nucleotides in target sequence file (summed length of all seqs)
my $Z_value = 0;   # total number of Mb of search space in target sequence file, 
                   # this is (2*$tot_nnt)/1000000 (the 2 is because we search both strands)
my %seqidx_H = (); # key: sequence name, value: index of sequence in original input sequence file (1..$nseq)
my %seqlen_H = (); # key: sequence name, value: length of sequence, 
                   # value multiplied by -1 after we output info for this sequence
                   # in round 1. Multiplied by -1 again after we output info 
                   # for this sequence in round 2. We do this so that we know
                   # that 'we output this sequence already', so if we 
                   # see it again before the next round, then we know the 
                   # tbl file was not sorted properly. That shouldn't happen,
                   # but if somehow it does then we want to know about it.
# use esl-seqstat to determine sequence lengths
my $seqstat_file = $out_root . ".seqstat";
if(! opt_Get("--keep", \%opt_HH)) { 
  push(@to_remove_A, $seqstat_file);
}
#$tot_nnt = ribo_ProcessSequenceFile($execs_H{"esl-seqstat"}, $seq_file, $seqstat_file, \%seqidx_H, \%seqlen_H, \%width_H, \%opt_HH);
$tot_nnt = ribo_ProcessSequenceFile("esl-seqstat", $seq_file, $seqstat_file, \%seqidx_H, \%seqlen_H, \%width_H, \%opt_HH);
$Z_value = sprintf("%.6f", (2 * $tot_nnt) / 1000000.);

# now that we know the max sequence name length, we can output headers to the output files
output_long_headers($r1_srt_long_out_FH, 1, \%opt_HH, \%width_H);
output_short_headers($r1_srt_short_out_FH, \%width_H);
if(defined $alg2) { 
  output_long_headers($r2_srt_long_out_FH, 2, \%opt_HH, \%width_H);
  output_short_headers($r2_srt_short_out_FH, \%width_H);
  output_long_headers($final_long_out_FH, "final", \%opt_HH, \%width_H);
  output_short_headers($final_short_out_FH, \%width_H);
}
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

###########################################################################
# Step 3: classify sequences using round 1 search algorithm
# determine which algorithm to use and options to use as well
# as the command for sorting the output and parsing the output
# set up defaults
###########################################################################
my $alg1_opts = "";
my $r1_tblout_file = "";
my $r1_sorted_tblout_file = "";
my $r1_searchout_file = "";
my $r1_search_cmd = "";
my $r1_sort_cmd = "";

$alg1_opts             = determine_cmsearch_opts($alg1, \%opt_HH);
$r1_tblout_file        = $out_root . ".r1.cmsearch.tbl";
$r1_sorted_tblout_file = $r1_tblout_file . ".sorted";
$r1_searchout_file     = $out_root . ".r1.cmsearch.out";
$r1_sort_cmd           = "grep -v ^\# $r1_tblout_file | sort -k1 > " . $r1_sorted_tblout_file;
$r1_search_cmd         = "cmsearch -T $min_secondary_sc -Z $Z_value --cpu $ncpu $alg1_opts --tblout $r1_tblout_file $master_model_file $seq_file > $r1_searchout_file";

if(! opt_Get("--skipsearch", \%opt_HH)) { 
  $start_secs = ribo_OutputProgressPrior("Classifying sequences", $progress_w, undef, *STDOUT);
}
else { 
  $start_secs = ribo_OutputProgressPrior("Skipping sequence classification (using results from previous run)", $progress_w, undef, *STDOUT);
}
if(! opt_Get("--skipsearch", \%opt_HH)) { 
  ribo_RunCommand($r1_search_cmd, opt_Get("-v", \%opt_HH));
}
else { 
  if(! -s $r1_tblout_file) { 
    die "ERROR with --skipsearch, tblout file ($r1_tblout_file) should exist and be non-empty but it's not";
  }
}
if(! opt_Get("--keep", \%opt_HH)) { 
  push(@to_remove_A, $r1_tblout_file);
  push(@to_remove_A, $r1_sorted_tblout_file);
  if(($alg1 ne "slow" || 
      $alg1 ne "hmmonly") && 
     (! opt_Get("--noali", \%opt_HH))) { 
    push(@to_remove_A, $r1_searchout_file);
  }
}
$r1_secs = ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

###########################################################################
# Step 4: Sort round 1 output
###########################################################################
$start_secs = ribo_OutputProgressPrior("Sorting classification results", $progress_w, undef, *STDOUT);
ribo_RunCommand($r1_sort_cmd, opt_Get("-v", \%opt_HH));
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);
###########################################################################

###########################################################################
# Step 5: Parse round 1 sorted output
###########################################################################
$start_secs = ribo_OutputProgressPrior("Processing classification results", $progress_w, undef, *STDOUT);
parse_sorted_tbl_file($r1_sorted_tblout_file, $alg1, 1, \%opt_HH, \%width_H, \%seqidx_H, \%seqlen_H, 
                      \%family_H, \%domain_H, \%accept_H, \%question_H, $r1_unsrt_long_out_FH, $r1_unsrt_short_out_FH);

# add data for sequences with 0 hits and then sort the output files 
# based on sequence index from original input file.
output_all_hitless_targets($r1_unsrt_long_out_FH, $r1_unsrt_short_out_FH, 1, \%opt_HH, \%width_H, \%seqidx_H, \%seqlen_H); # 1: round 1

# now close the unsorted file handles (we're done with these) 
# and also the sorted file handles (so we can output directly to them using system())
# Remember, we already output the headers to these files above
close($r1_unsrt_long_out_FH);
close($r1_unsrt_short_out_FH);
close($r1_srt_long_out_FH);
close($r1_srt_short_out_FH);

$cmd = "sort -n $r1_unsrt_short_out_file >> $r1_srt_short_out_file";
ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH));

$cmd = "sort -n $r1_unsrt_long_out_file >> $r1_srt_long_out_file";
ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH));

# reopen them, and add tails to the output files
open($r1_srt_long_out_FH,  ">>", $r1_srt_long_out_file)  || die "ERROR unable to open $r1_unsrt_long_out_file for appending";
open($r1_srt_short_out_FH, ">>", $r1_srt_short_out_file) || die "ERROR unable to open $r1_unsrt_short_out_file for appending";
output_long_tail($r1_srt_long_out_FH, 1, \@ufeature_A, \%opt_HH); # 1: round 1 of searching
output_short_tail($r1_srt_short_out_FH, \@ufeature_A, \%opt_HH);
close($r1_srt_short_out_FH);
close($r1_srt_long_out_FH);

ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

###########################################################################
# Step 6: Parse the round 1 output to create sfetch files for fetching
#         sequence sets for each model.
###########################################################################
if(defined $alg2) { # only do this if we're doing a second round of searching
  if(! opt_Get("--skipsearch", \%opt_HH)) { 
    $start_secs = ribo_OutputProgressPrior("Fetching per-model sequence sets", $progress_w, undef, *STDOUT);
    
    my %seqsub_HA = (); # key is model, value is an array of all sequences to fetch to research with that model
    # first initialize all arrays to empty
    foreach $model (keys %family_H) { 
      @{$seqsub_HA{$model}} = ();
    }
    
    # fill the arrays with sequence names for each model
    parse_round1_long_file($r1_srt_long_out_file, \%seqsub_HA); 
    
    # create the sfetch files with sequence names
    foreach $model (sort keys %family_H) { 
      $sfetchfile_H{$model} = undef;
      if(scalar(@{$seqsub_HA{$model}}) > 0) { 
        $sfetchfile_H{$model} = $out_root . ".$model.sfetch";
        write_array_to_file($seqsub_HA{$model}, $sfetchfile_H{$model}); 
        if(! opt_Get("--keep", \%opt_HH)) { 
          push(@to_remove_A, $sfetchfile_H{$model});
        }
      }
    }
    ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);
    
    foreach $model (sort keys %family_H) { 
      if(defined $sfetchfile_H{$model}) { 
        $seqfile_H{$model} = $out_root . ".$model.fa";
        #ribo_RunCommand($execs_H{"esl-sfetch"} . " -f $seq_file " . $sfetchfile_H{$model} . " > " . $seqfile_H{$model}, opt_Get("-v", \%opt_HH));
        ribo_RunCommand("esl-sfetch -f $seq_file " . $sfetchfile_H{$model} . " > " . $seqfile_H{$model}, opt_Get("-v", \%opt_HH));
        if(! opt_Get("--keep", \%opt_HH)) { 
          push(@to_remove_A, $seqfile_H{$model});
        }
      }
    }
  }
}

###########################################################################
# Step 7: Do round 2 of searches, one model at a time.
###########################################################################
my $alg2_opts;                    # algorithm 2 cmsearch options
my @r2_model_A = ();              # models we performed round 2 for
my @r2_tblout_file_A = ();        # tblout files for each model we performed round 2 for
my @r2_searchout_file_A = ();     # search output file for each model we performed round 2 for
my @r2_search_cmd_A = ();         # search command for each model we performed round 2 for
my $r2_all_tblout_file;           # file that is concatenation of all files in @r2_tblout_file_A
my $r2_all_sorted_tblout_file;    # single sorted tblout file for all models we performed round 2 for
my $r2_all_sort_cmd;              # sort command for $r2_all_tblout_file to create $r2_tblout_file
my $midx = 0;                     # counter of models in round 2
my $nr2 = 0;                      # number of models we run round 2 searches for
if(defined $alg2) { 
  $alg2_opts = determine_cmsearch_opts($alg2, \%opt_HH);
  if(! opt_Get("--skipsearch", \%opt_HH)) { 
    $start_secs = ribo_OutputProgressPrior("Searching sequences against best-matching models", $progress_w, undef, *STDOUT);
  }
  else { 
    $start_secs = ribo_OutputProgressPrior("Skipping sequence search (using results from previous run)", $progress_w, undef, *STDOUT);
  }
  my $cmd  = undef;
  foreach $model (sort keys %family_H) { 
    if(defined $sfetchfile_H{$model}) { 
      push(@r2_model_A, $model);
      push(@r2_tblout_file_A,        $out_root . ".r2.$model.cmsearch.tbl");
      push(@r2_searchout_file_A,     $out_root . ".r2.$model.cmsearch.out");
      push(@r2_search_cmd_A,         "cmsearch -T $min_secondary_sc -Z $Z_value --cpu $ncpu $alg2_opts --tblout " . $r2_tblout_file_A[$midx] . " " . $indi_cmfile_H{$model} . " " . $seqfile_H{$model} . " > " . $r2_searchout_file_A[$midx]);

      if(! opt_Get("--skipsearch", \%opt_HH)) { 
        ribo_RunCommand($r2_search_cmd_A[$midx], opt_Get("-v", \%opt_HH));
        if(! opt_Get("--keep", \%opt_HH)) { 
          push(@to_remove_A, $r2_tblout_file_A[$midx]);
          if(($alg2 ne "slow") && 
             (! opt_Get("--noali", \%opt_HH))) { 
            push(@to_remove_A, $r2_searchout_file_A[$midx]);
          }
        }
      }
      else { 
        if(! -s $r2_tblout_file_A[$midx]) { 
          die "ERROR with --skipsearch, tblout file " . $r2_tblout_file_A[$midx] . " should exist and be non-empty but it's not";
        }
      }
      $midx++; 
    }
  }
  $nr2 = $midx;
  $r2_secs = ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

  # concatenate round 2 tblout files 
  my $cat_cmd = ""; # command used to concatenate tabular output from all round 2 searches
  $r2_all_tblout_file = $out_root . ".r2.all.cmsearch.tbl";
  if(defined $alg2) { 
    if($nr2 >= 1) { 
      $start_secs = ribo_OutputProgressPrior("Concatenating tabular round 2 search results", $progress_w, undef, *STDOUT);
      $cat_cmd = "cat $r2_tblout_file_A[0] ";
      for($midx = 1; $midx < $nr2; $midx++) { 
        $cat_cmd .= "$r2_tblout_file_A[$midx] ";
      }
      $cat_cmd .= "> " . $r2_all_tblout_file;
      ribo_RunCommand($cat_cmd, opt_Get("-v", \%opt_HH));
      ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);
      if(! opt_Get("--keep", \%opt_HH)) { 
        push(@to_remove_A, $r2_all_tblout_file);
      }
    }
  }
}

###########################################################################
# Step 8: Sort round 2 output
###########################################################################
if((defined $alg2) && ($nr2 > 0)) { 
  $start_secs = ribo_OutputProgressPrior("Sorting search results", $progress_w, undef, *STDOUT);
  $r2_all_sorted_tblout_file = $r2_all_tblout_file . ".sorted";
  $r2_all_sort_cmd = "grep -v ^\# " . $r2_all_tblout_file . " | sort -k1 > " . $r2_all_sorted_tblout_file;
  ribo_RunCommand($r2_all_sort_cmd, opt_Get("-v", \%opt_HH));
  if(! opt_Get("--keep", \%opt_HH)) { 
    push(@to_remove_A, $r2_all_sorted_tblout_file);
  }
  ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);
}

###########################################################################
# Step 9: Parse round 2 sorted output
###########################################################################
if(defined $alg2) { 
  $start_secs = ribo_OutputProgressPrior("Processing tabular round 2 search results", $progress_w, undef, *STDOUT);
  if($nr2 > 0) { 
    parse_sorted_tbl_file($r2_all_sorted_tblout_file, $alg2, 2, \%opt_HH, \%width_H, \%seqidx_H, \%seqlen_H,
                          \%family_H, \%domain_H, \%accept_H, \%question_H, $r2_unsrt_long_out_FH, $r2_unsrt_short_out_FH);
  }
  # add data for sequences with 0 hits and then sort the output files 
  # based on sequence index from original input file.
  output_all_hitless_targets($r2_unsrt_long_out_FH, $r2_unsrt_short_out_FH, 2, \%opt_HH, \%width_H, \%seqidx_H, \%seqlen_H); # 2: round 2

  # now close the unsorted file handles (we're done with these) 
  # and also the sorted file handles (so we can output directly to them using system())
  # Remember, we already output the headers to these files above
  close($r2_unsrt_long_out_FH);
  close($r2_unsrt_short_out_FH);
  close($r2_srt_long_out_FH);
  close($r2_srt_short_out_FH);

  $cmd = "sort -n $r2_unsrt_short_out_file >> $r2_srt_short_out_file";
  ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH));

  $cmd = "sort -n $r2_unsrt_long_out_file >> $r2_srt_long_out_file";
  ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH));

  # reopen them, and add tails to the output files
  # now that we know the max sequence name length, we can output headers to the output files
  open($r2_srt_long_out_FH,  ">>", $r2_srt_long_out_file)  || die "ERROR unable to open $r2_unsrt_long_out_file for appending";
  open($r2_srt_short_out_FH, ">>", $r2_srt_short_out_file) || die "ERROR unable to open $r2_unsrt_short_out_file for appending";
  output_long_tail($r2_srt_long_out_FH, 2, \@ufeature_A, \%opt_HH); # 2: round 2 of searching
  output_short_tail($r2_srt_short_out_FH, \@ufeature_A, \%opt_HH);
  close($r2_srt_short_out_FH);
  close($r2_srt_long_out_FH);
  
  ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);
}
###########################################################################
# Step 10: Combine the round 1 and round 2 output files to create the 
#          final output file.
###########################################################################
my %class_stats_HH = (); # hash of hashes with summary statistics 
                         # 1D key: class name (e.g. "SSU.Bacteria") or "*all*" or "*none*" or "*input*"
                         # 2D key: "nseq", "nnt_cov", "nnt_tot"

if(defined $alg2) { 
  $start_secs = ribo_OutputProgressPrior("Creating final output files", $progress_w, undef, *STDOUT);
  open($r1_srt_long_out_FH,  $r1_srt_long_out_file)  || die "ERROR unable to open $r1_unsrt_long_out_file for reading";
  open($r1_srt_short_out_FH, $r1_srt_short_out_file) || die "ERROR unable to open $r1_unsrt_short_out_file for reading";
  open($r2_srt_long_out_FH,  $r2_srt_long_out_file)  || die "ERROR unable to open $r2_unsrt_long_out_file for reading";
  open($r2_srt_short_out_FH, $r2_srt_short_out_file) || die "ERROR unable to open $r2_unsrt_short_out_file for reading";
  output_combined_short_or_long_file($final_short_out_FH, $r1_srt_short_out_FH, $r2_srt_short_out_FH, 1,  # 1: $do_short = TRUE
                                     undef, undef, \%width_H, \%opt_HH);
  output_combined_short_or_long_file($final_long_out_FH,  $r1_srt_long_out_FH,  $r2_srt_long_out_FH,  0,  # 0: $do_short = FALSE
                                     \%class_stats_HH, \%ufeature_ct_H, \%width_H, \%opt_HH);
  output_short_tail($final_short_out_FH, \@ufeature_A, \%opt_HH);
  output_long_tail($final_long_out_FH, "final", \@ufeature_A, \%opt_HH);
  close($final_short_out_FH);
  ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);
}

# remove files we don't want anymore, then exit
foreach my $file (@to_remove_A) { 
  unlink $file;
}

output_summary_statistics(*STDOUT, \%class_stats_HH);
output_ufeature_statistics(*STDOUT, \%ufeature_ct_H, \@ufeature_A, $class_stats_HH{"*input*"}{"nseq"});

$total_seconds += ribo_SecondsSinceEpoch();
output_timing_statistics(*STDOUT, \%class_stats_HH, $ncpu, $r1_secs, $r2_secs, $total_seconds);
  
#printf("#\n# Round 1 short (6 column) output saved to file $r1_srt_short_out_file\n");
#printf("# Round 1 long (%d column) output saved to file $r1_srt_long_out_file\n", determine_number_of_columns_in_long_output_file(1, \%opt_HH));
#if(defined $alg2) { 
#  printf("# Round 2 short (6 column) output saved to file $r2_srt_short_out_file\n");
#  printf("# Round 2 long (%d column) output saved to file $r2_srt_long_out_file\n", determine_number_of_columns_in_long_output_file(2, \%opt_HH));
#}
printf("#\n# Short (6 column) output saved to file $final_short_out_file\n");
printf("# Long (%d column) output saved to file $final_long_out_file\n", determine_number_of_columns_in_long_output_file("final", \%opt_HH));
printf("#\n#[RIBO-SUCCESS]\n");

###########################################################################

#####################################################################
# SUBROUTINES 
#####################################################################
# List of subroutines:
#
# Functions for parsing files:
# parse_modelinfo_file:     parse the model info input file
# parse_inaccept_file:      parse the inaccept input file (--inaccept)
# parse_model_file:         parse the model file 
# parse_sorted_tbl_file:    parse sorted tabular search results
#
# Helper functions for parse_sorted_tbl_file():
# init_model_vars:          initialize variables for parse_sorted_tbl_file()
# set_modelvars:            set variables for parse_sorted_tbl_file()
# 
# Functions for output: 
# output_one_target:         output info on one target sequence
#                            helper for parse_sorted_tbl_file()
# output_short_headers:      output headers for short output file
# output_long_headers:       output headers for long output file
#
# Miscellaneous functions:
# debug_print:              print out info of a hit for debugging
# center_string:            center a string inside a string of whitespace of specified length
# determine_if_coverage_is_accurate(): determine if coverage values are accurate based on cmdline options
# get_overlap():            determine the extent of overlap of two regions
# get_overlap_helper():     does actual work to determine overlap
#
#################################################################
# Subroutine : parse_modelinfo_file()
# Incept:      EPN, Mon Dec 19 10:01:32 2016
#
# Purpose:     Parse a model info input file.
#              
# Arguments: 
#   $modelinfo_file:  file to parse
#   $df_model_dir:    default $RIBODIR/models directory, where default models should be
#   $family_HR:       ref to hash of family names, key is model name, value is family name
#   $domain_HR:       ref to hash of domain names, key is model name, value is domain name
#   $indi_cmfile_HR:  ref to hash of CM files, key is model name, value is path to CM file
#   $opt_HHR:         reference to 2D hash of cmdline options (needed to determine if -i was used)
#
# Returns:     Path to master CM file. Fills %{$family_H}, %{$domain_HR}, %{$indi_cmfile_HR}
# 
# Dies:        Never.
#
################################################################# 
sub parse_modelinfo_file { 
  my $nargs_expected = 6;
  my $sub_name = "parse_modelinfo_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($modelinfo_file, $df_model_dir, $family_HR, $domain_HR, $indi_cmfile_HR, $opt_HHR) = @_;

  open(IN, $modelinfo_file) || die "ERROR unable to open model info file $modelinfo_file for reading";

  my $opt_i_used        = opt_IsUsed("-i", $opt_HHR);
  my $found_master      = 0;     # set to '1' when we find master file line
  my $master_cmfile     = undef; # name of 'master' CM file with all CMs
  my $non_df_model_file = undef; # non-default model file
  my $df_model_file     = undef; # default model file
  my $in_df;                     # flag for whether we found model file in default dir or not
  my $in_nondf;                  # flag for whether we found model file in non-default dir or not

  # determine directory that $modelinfo_file exists in if -i used, all models must 
  # either be in this directory or in $df_model_dir
  my $non_df_modelinfo_dir = undef; # directory with modelinfo file, if -i used
  if($opt_i_used) { 
    $non_df_modelinfo_dir = get_dir_path($modelinfo_file);
  }

  # actually parse modelinfo file: 
  # example lines:
  # ---
  # SSU_rRNA_archaea SSU Archaea ribo.0p02.SSU_rRNA_archaea.cm
  # LSU_rRNA_eukarya LSU Eukarya ribo.0p02.LSU_rRNA_eukarya.cm
  # *all*            -   -       ribo.0p02.cm
  # ---
  # exactly one line must have model name as '*all*'
  open(IN, $modelinfo_file) || die "ERROR unable to open $modelinfo_file for reading"; 
  while(my $line = <IN>) { 
    if($line !~ m/^\#/ && $line =~ m/\w/) { # skip comment lines and blank lines
      chomp $line;
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 4) { 
        die "ERROR didn't read 4 tokens in model info input file $modelinfo_file, line $line"; 
      }
      my($model, $family, $domain, $cmfile) = (@el_A);
      
      # make sure that the model file exists, either in $df_model_dir or, if
      # -i was used, in the same directory that $modelinfo_file is in
      $df_model_file = $df_model_dir . $cmfile;
      if($opt_i_used) { 
        $non_df_model_file = $non_df_modelinfo_dir . $cmfile;
        $in_nondf = ribo_CheckIfFileExistsAndIsNonEmpty($non_df_model_file, undef, $sub_name, 0); # don't die if it doesn't exist
        $in_df    = ribo_CheckIfFileExistsAndIsNonEmpty($df_model_file,     undef, $sub_name, 0); # don't die if it doesn't exist
        if(($in_nondf != 0) && ($in_df != 0)) { # exists in two places
          die "ERROR in $sub_name, looking for model file $cmfile, found it in the two places it's looked for:\ndirectory $non_df_modelinfo_dir (where model info file specified with -i is) AND\ndirectory $df_model_dir (default model directory)\nIt can only exist in one of these places, so either\nrename it or remove of the copies (do NOT remove the copy from the default model directory unless you put it there)\n."
        }
        elsif(($in_nondf == 0) && ($in_df == 0)) { 
          die "ERROR in $sub_name, looking for model file $cmfile, did not find it in the two places it's looked for:\ndirectory $non_df_modelinfo_dir (where model info file specified with -i is) AND\ndirectory $df_model_dir (default model directory)\n";
        }
        elsif(($in_nondf == -1) && ($in_df == 0)) { 
          die "ERROR in $sub_name, looking for model file $cmfile, it exists as $non_df_model_file but is empty";
        }
        elsif(($in_nondf == 0) && ($in_df == -1)) { 
          die "ERROR in $sub_name, looking for model file $cmfile, it exists as $df_model_file but is empty";
        }
       elsif($in_nondf == 1) { 
          $cmfile = $non_df_model_file;
        }
        elsif($in_df == 1) { 
          $cmfile = $df_model_file;
        }
        else { 
          die "ERROR in $sub_name, looking for model file, unexpected situation (in_nondf: $in_nondf, in_df: $in_df)\n";
        }
      }     
      else { # $opt_i_used is FALSE, -i not used, models must be in $df_model_dir
        ribo_CheckIfFileExistsAndIsNonEmpty($df_model_file, "model file name read from default model info file", $sub_name, 1); # die if it doesn't exist
        $cmfile = $df_model_file;
      }
        
      if($model eq "*all*") { 
        if($found_master) { 
          die "ERROR read model $model twice in $modelinfo_file";
        }
        $found_master = 1;
        $master_cmfile = $cmfile
      }
      else { 
        if(exists $family_HR->{$model}) { 
          die "ERROR read model $model twice in $modelinfo_file"; 
        }
        $family_HR->{$model}      = $family;
        $domain_HR->{$model}      = $domain;
        $indi_cmfile_HR->{$model} = $cmfile;
      }
    }
  }
  close(IN);

  if(! $found_master) { 
    if($opt_i_used) { 
      die "ERROR in $sub_name, didn't read special line with '*all*' as first token\nin modelinfo file $modelinfo_file (specified with -i) which\nspecifies the master CM file"; 
    }
    else { 
      die "ERROR in $sub_name, didn't read special line'*all*' as first token\nin default modelinfo file. Is your RIBODIR env variable set correctly?\n";
    }
  }

  return $master_cmfile;
}

#################################################################
# Subroutine : parse_inaccept_file()
# Incept:      EPN, Wed Mar  1 11:59:13 2017
#
# Purpose:     Parse the 'inaccept' input file.
#              
# Arguments: 
#   $inaccept_file:  file to parse
#   $accept_HR:      ref to hash of names, key is model name, value is '1' if model is acceptable
#                    This hash should already be defined with all model names and all values as '0'.
#   $question_HR:    ref to hash of names, key is model name, value is '1' if model is questionable
#                    This hash should already be defined with all model names and all values as '0'.
#
# Returns:     Nothing. Updates %{$accept_HR} and %{$question_HR}.
# 
# Dies:        If the file is in the wrong format.
#
################################################################# 
sub parse_inaccept_file { 
  my $nargs_expected = 3;
  my $sub_name = "parse_inaccept_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($inaccept_file, $accept_HR, $question_HR) = @_;

  open(IN, $inaccept_file) || die "ERROR unable to open input accept file $inaccept_file for reading";

# example lines (two token per line)
# SSU_rRNA_archaea questionable
# SSU_rRNA_bacteria acceptable

  # construct string of all valid model names to use for error message
  my $valid_name_str = "\n";
  my $model;
  foreach $model (sort keys (%{$accept_HR})) { 
    $valid_name_str .= "\t" . $model . "\n";
  }

  my $accept_or_question; # second token from the inaccept file
  open(IN, $inaccept_file) || die "ERROR unable to open $inaccept_file for reading"; 
  while(my $line = <IN>) { 
    chomp $line;
    if(($line !~ m/^\#/) && ($line =~ m/\w/))  { # skip comment and blank lines
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 2) { 
        die "ERROR, in $sub_name, didn't read 2 token in inaccept input file $inaccept_file, line $line\nEach line should have exactly 1 white-space delimited token, a valid model name"; 
      }
      ($model, $accept_or_question) = (@el_A);
      
      if(! exists $accept_HR->{$model}) { 
        die "ERROR, in $sub_name, read invalid model name \"$model\" in inaccept input file $inaccept_file\nValid model names are $valid_name_str"; 
      }
      if(! exists $question_HR->{$model}) { 
        die "ERROR, in $sub_name,  read invalid model name \"$model\" in inaccept input file $inaccept_file\nValid model names are $valid_name_str"; 
      }

      if($accept_or_question eq "acceptable") { 
        if($question_HR->{$model}) { 
          die "ERROR, in $sub_name, read model name \"$model\" name twice in $inaccept_file, once with acceptable and once with questionable";
        }
        $accept_HR->{$model} = 1;
      }
      elsif($accept_or_question eq "questionable") { 
        if($accept_HR->{$model}) { 
          die "ERROR, in $sub_name, read model name \"$model\" name twice in $inaccept_file, once with acceptable and once with questionable";
        }
        $question_HR->{$model} = 1;
      }
      else { 
        die "ERROR, in $sub_name, read unexpected second token $accept_or_question on line: $line\n";
      }
    }
  }
  close(IN);

  return;
}

#################################################################
# Subroutine : parse_and_validate_model_files()
# Incept:      EPN, Wed Mar  1 14:46:19 2017
#
# Purpose:     Parse the master model file to get model names and
#              validate that there is 1:1 correspondence between
#              model names in the model file and the keys 
#              from %{$family_HR}. Also make sure that the 
#              checksum values read for each model in the master 
#              model file are equal to the corresponding checksum 
#              values from the individual CM files. 
#              We've already verified that all CM files exist 
#              and are non-empty.
#              
# Arguments: 
#   $master_model_file: master model file to parse
#   $family_HR:         ref to hash of families for each model, 
#                       ALREADY FILLED, we use this only for validation
#   $indi_cmfile_HR     ref to hash of individual CM files for each model,
#                       ALREADY FILLED we use this only for validation
#
# Returns:     Maximum length of any model read from the model file.
# 
# Dies:        If master model file does not have exactly the 
#              same set of models that are keys in $family_HR
#              and match the checksum values in the individual
#              CM files.
#
################################################################# 
sub parse_and_validate_model_files { 
  my $nargs_expected = 3;
  my $sub_name = "parse_and_validate_model_files";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($master_model_file, $family_HR, $indi_cmfile_HR) = @_;

  # make copy of %{$family_HR} with all values set to '0' 
  my $model; # a model name
  my $cksum; # a checksum value
  my @tmp_family_model_A = ();
  my %tmp_family_model_H = ();
  my $expected_nmodels = scalar(keys %{$family_HR});
  foreach $model (keys %{$family_HR}) { 
    push(@tmp_family_model_A, $model);
    $tmp_family_model_H{$model} = 0; 
    # we will set to '1' when we see it in the model file and validate it's checksum
  }

  my $model_width = length("model");
  my $name_output = `grep NAME $master_model_file | awk '{ print \$2 }'`;
  my @name_A = split("\n", $name_output);
  my $cksum_output = `grep CKSUM $master_model_file | awk '{ print \$2 }'`;
  my @cksum_A = split("\n", $cksum_output);

  my $indi_cksum_output = undef;
  my @indi_cksum_A = ();
  my $indi_cmfile = undef;

  my $nnames = scalar(@name_A);
  if($nnames != scalar(@cksum_A)) { 
    die "ERROR in $sub_name, did not read the same number of names and checksum lines from master model file:\n$master_model_file\n"; 
  }
  if($nnames != (2 * $expected_nmodels)) { 
    # each CM file has 2 occurrences of each name, once for the CM and once for the HMM filter
    die sprinft("ERROR in $sub_name, expected to read 2 names for each model for a total of %d names, but read $nnames\nDoes the master model file $master_model_file have more models than are listed in the modelinfo file?\nIf so, remove the ones that are not in the modelinfo file\n", 2*$expected_nmodels); 
  }
  for(my $i = 0; $i < scalar(@name_A); $i++) { 
    $model = $name_A[$i];
    $cksum = $cksum_A[$i];
    $indi_cmfile = $indi_cmfile_HR->{$model};
    if(! exists $tmp_family_model_H{$model}) { 
      die "ERROR read model \"$model\" from model file $master_model_file that is not listed in the model info file.";
    }
    if($tmp_family_model_H{$model} == 0) { # only check if we haven't seen this name before
      $indi_cksum_output = `grep CKSUM $indi_cmfile | awk '{ print \$2 }'`;
      @indi_cksum_A = split("\n", $indi_cksum_output);
      if(scalar(@indi_cksum_A) != 2) { 
        die "ERROR in $sub_name, did not read the expected 2 CKSUM lines from $indi_cmfile, it should have exactly 1 model in it"; 
      }
      if($indi_cksum_A[0] != $indi_cksum_A[1]) { 
        die "ERROR in $sub_name, the two CKSUM lines from $indi_cmfile differ unexpectedly"; 
      }
      if($indi_cksum_A[0] != $cksum) { 
        die "ERROR in $sub_name, for model $model, checksum mismatch between the master CM file and the individual CM file\nmaster CM file: $master_model_file\nindividual CM file: $indi_cmfile\nAre you sure these models are the same? They are required to be identical.\n";
      }
    }
    # if we get here, checksum test has passed
    $tmp_family_model_H{$model} = 1;
    if(length($model) > $model_width) { 
      $model_width = length($model);
    }
  }

  foreach $model (keys %tmp_family_model_H) { 
    if($tmp_family_model_H{$model} == 0) { 
      die "ERROR model \"$model\" read from model info file is not in the model file.";
    }
  }

  return $model_width;
}


#################################################################
# Subroutine : parse_sorted_tblout_file()
# Incept:      EPN, Thu Dec 29 09:52:16 2016
#
# Purpose:     Parse a sorted tabular output file and generate output.
#              
# Arguments: 
#   $sorted_tbl_file: file with sorted tabular search results
#   $alg:             search method (one of "fast", "hmmonly", or "slow")
#   $round:           '1' or '2', what round of searching we're in
#   $opt_HHR:         ref to 2D options hash of cmdline option values
#   $width_HR:        hash, key is "model" or "target", value 
#                     is width (maximum length) of any target/model
#   $seqidx_HR:       ref to hash of sequence indices, key is sequence name, value is index
#   $seqlen_HR:       ref to hash of sequence lengths, key is sequence name, value is length
#   $family_HR:       ref to hash of family names, key is model name, value is family name
#   $domain_HR:       ref to hash of domain names, key is model name, value is domain name
#   $accept_HR:       ref to hash of acceptable models, key is model name, value is '1' if acceptable
#   $question_HR:     ref to hash of questionable models, key is model name, value is '1' if questionable
#   $long_out_FH:     file handle for long output file, already open
#   $short_out_FH:    file handle for short output file, already open
#
# Returns:     Nothing. Fills %{$family_H}, %{$domain_HR}
# 
# Dies:        Never.
#
################################################################# 
sub parse_sorted_tbl_file { 
  my $nargs_expected = 13;
  my $sub_name = "parse_sorted_tbl_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($sorted_tbl_file, $alg, $round, $opt_HHR, $width_HR, $seqidx_HR, $seqlen_HR, $family_HR, $domain_HR, $accept_HR, $question_HR, $long_out_FH, $short_out_FH) = @_;

  # validate search method (sanity check) 
  if(($alg ne "fast") && ($alg ne "hmmonly") && ($alg ne "slow")) { 
    die "ERROR in $sub_name, invalid search method $alg";
  }

  # determine minimum bit score cutoff
  my $min_primary_sc = opt_Get("--minpsc", $opt_HHR);
  
  # Main data structures: 
  # 'first': current top scoring model for current sequence
  # 'second': current second best scoring model for current sequence 
  #          that overlaps with hit in 'one' data structures
  # 
  # keys for all below are families (e.g. 'SSU' or 'LSU')
  # values are for the best scoring hit in this family to current sequence
  my %first_model_HH = ();  # 1st dim key are families (e.g. 'SSU', 'LSU')
                            # 2nd dim keys: "model", "domain", "score", "evalue", "sstart", "sstop", "mstart", "mstop", "strand"
                            # values are 2nd dim attribute for best scoring hit in this family to current sequence
  my %second_model_HH = (); # 1st dim key are families (e.g. 'SSU', 'LSU')
                            # 2nd dim keys: "model", "domain", "score", "evalue", "sstart", "sstop", "mstart", "mstop", "strand"
                            # values are 2nd dim attribute for best scoring hit in this family to current sequence

  # for convenience, copies of current first and second values, to simplify writing them out
  my $first_model    = undef;
  my $first_domain   = undef;
  my $first_evalue   = undef;
  my $first_score    = undef;
  my $first_start    = undef;
  my $first_stop     = undef;
  my $first_strand   = undef;
  my $first_mdlstart = undef;
  my $first_mdlstop  = undef;
  
  my $second_model    = undef;
  my $second_domain   = undef;
  my $second_evalue   = undef;
  my $second_score    = undef;
  my $second_start    = undef;
  my $second_stop     = undef;
  my $second_strand   = undef;
  my $second_mdlstart = undef;
  my $second_mdlstop  = undef;

  # statistics we keep track of per model and strand, used to detect various output statistics and
  # to report 'unexpected features'
  my %nnts_per_model_HH  = ();   # hash; key 1: model name, key 2: strand ("+" or "-") value: number of 
                                 # nucleotides in all hits (no threshold applied) to model for that strand for 
                                 # current target sequence
  my %nnts_at_per_model_HH  = ();# hash; key 1: model name, key 2: strand ("+" or "-") value: number of 
                                 # nucleotides in all hits above threshold to model for that strand for 
                                 # current target sequence
  my %nhits_per_model_HH = ();   # hash; key 1: model name, key 2: strand ("+" or "-") value: number of 
                                 # hits to model (no threshold applied) for that strand for current target sequence
  my %nhits_at_per_model_HH = ();# hash; key 1: model name, key 2: strand ("+" or "-") value: number of 
                                 # hits to model above threshold for that strand for current target sequence
  my %tbits_per_model_HH = ();   # hash; key 1: model name, key 2: strand ("+" or "-") value: total (summed)
                                 # bit score for all hits to model (no threshold applied) for that current target sequence
  my %mdl_bd_per_model_HHA = (); # hash; key 1: model name, key 2: strand ("+" or "-") value: an array of model 
                                 # coordinate boundaries for all hits (no threshold applied, sorted by score), 
                                 # each element of the array is a string of the format <d1>-<d2>, 
                                 # where <d1> is the 5' model position boundary of the hit and 
                                 # <d2> is the 3' model position boundary of the hit
  my %seq_bd_per_model_HHA = (); # hash; key 1: model name, key 2: strand ("+" or "-") value: an array of sequence
                                 # coordinate boundaries for all hits (no threshold applied, sorted by score), 
                                 # each element of the array is a string of the format <d1>-<d2>, 
                                 # where <d1> is the 5' sequence position boundary of the hit and 
                                 # <d2> is the 3' sequence position boundary of the hit
                                 # if strand is '+', <d1> <= <d2> and if strand is '-', <d1> >= <d2>

  my $prv_target = undef; # target name of previous line
  my $family     = undef; # family of current model

  open(IN, $sorted_tbl_file) || die "ERROR unable to open sorted tabular file $sorted_tbl_file for reading";

  my ($target, $model, $domain, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue) = 
      (undef, undef, undef, undef, undef, undef, undef, undef, undef, undef);
  my $cur_becomes_first; # set to true for each hit if it is better than our current 'first' hit
  my $cur_becomes_second; # set to true for each hit if it is better than our current 'second' hit
  my $cur_domain_or_model; # domain (default) or model (--samedomain) of current hit
  my $one_domain_or_model; # domain (default) or model (--samedomain) of current 'one' hit
  my $two_domain_or_model; # domain (default) or model (--samedomain) of current 'two' hit
  my $nhits_above_thresh = 0; # number of hits above threshold for current sequence
  my $have_accurate_coverage = determine_if_coverage_is_accurate($round, $opt_HHR);
  my $have_model_coords      = determine_if_we_have_model_coords($round, $opt_HHR);
  my $have_evalues           = determine_if_we_have_evalues($round, $opt_HHR);
  my $sort_by_evalues        = opt_Get("--evalues", $opt_HHR);

  # for convenience, copies of current first and second values, to simplify writing them out

  if($sort_by_evalues && (! $have_evalues)) { 
    die "ERROR, trying to sort by E-values but we don't have them. Coding error."; 
  }

  while(my $line = <IN>) { 
    ######################################################
    # Parse the data on this line, this differs depending
    # on our annotation method
    chomp $line;
    $line =~ s/^\s+//; # remove leading whitespace
    
    if($line =~ m/^\#/) { 
      die "ERROR, found line that begins with #, input should have these lines removed and be sorted by the first column:$line.";
    }
    my @el_A = split(/\s+/, $line);

    if($alg eq "fast") {
      if(scalar(@el_A) != 9) { die "ERROR did not find 9 columns in fast cmsearch tabular output at line: $line"; }
      # NC_013790.1 SSU_rRNA_archaea 1215.0  760337  762896      +     ..  ?      2937203
      ($target, $model, $score, $seqfrom, $seqto, $strand) = 
          ($el_A[0], $el_A[1], $el_A[2], $el_A[3], $el_A[4], $el_A[5]);
      $mdlfrom = 1; # irrelevant, but removes uninitialized value warnings
      $mdlto   = 1; # irrelevant, but removes uninitialized value warnings
    }
    else { # "hmmonly" or "slow"
      ##target name             accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
      ##----------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
      #lcl|dna_BP444_24.8k:251  -         SSU_rRNA_archaea     RF01959   hmm        3     1443        2     1436      +     -    6 0.53   6.0 1078.9         0 !   -
      if(scalar(@el_A) < 18) { die "ERROR found less than 18 columns in cmsearch tabular output at line: $line"; }
      ($target, $model, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue) = 
          ($el_A[0], $el_A[2], $el_A[5], $el_A[6], $el_A[7], $el_A[8], $el_A[9],  $el_A[14], $el_A[15]);
    }

    $family = $family_HR->{$model};
    if(! defined $family) { 
      die "ERROR unrecognized model $model, no family information";
    }

    # two sanity checks:
    # make sure we have sequence length information for this sequence
    if(! exists $seqlen_HR->{$target}) { 
      die "ERROR found sequence $target we didn't read length information for in $seqstat_file";
    }
    # make sure we haven't output information for this sequence already
    if((($round == 1) && ($seqlen_HR->{$target} < 0)) || 
       (($round == 2) && ($seqlen_HR->{$target} > 0)))  { 
      die "ERROR found line with target $target previously output, did you sort by sequence name?";
    }
    # finished parsing data for this line
    ######################################################

    ##############################################################
    # Are we now finished with the previous sequence? 
    # Yes, if target sequence we just read is different from it
    # If yes, output info for it, and re-initialize data structures
    # for new sequence just read
    if((defined $prv_target) && ($prv_target ne $target)) { 
      if($nhits_above_thresh > 0) { 
        output_one_target($short_out_FH, $long_out_FH, $opt_HHR, $round, $have_accurate_coverage, $have_model_coords, $have_evalues, 
                          $sort_by_evalues, $width_HR, $domain_HR, $accept_HR, $question_HR, 
                          $prv_target, $seqidx_HR->{$prv_target}, abs($seqlen_HR->{$prv_target}), 
                          \%nhits_per_model_HH, \%nhits_at_per_model_HH, \%nnts_per_model_HH, \%nnts_at_per_model_HH, 
                          \%tbits_per_model_HH, \%mdl_bd_per_model_HHA, \%seq_bd_per_model_HHA, 
                          \%first_model_HH, \%second_model_HH);
        $seqlen_HR->{$prv_target} *= -1; # serves as a flag that we output info for this sequence
      }
      %first_model_HH        = ();
      %second_model_HH       = ();
      $nhits_above_thresh    = 0;
      %nhits_per_model_HH    = ();
      %nhits_at_per_model_HH = ();
      %tbits_per_model_HH    = ();
      %nnts_per_model_HH     = ();
      %nnts_at_per_model_HH  = ();
      %mdl_bd_per_model_HHA  = ();
      %seq_bd_per_model_HHA  = ();
    }
    ##############################################################
    
    ###############################################################
    # Determine if this hit is either a new 'first' or 'second' hit
    $cur_becomes_first     = 0;       # set to '1' below if no 'one' hit exists yet, or this E-value/score is better than current 'one'
    $cur_becomes_second     = 0;       # set to '1' below if no 'two' hit exists yet, or this E-value/score is better than current 'two'
    $domain = $domain_HR->{$model}; # the domain for this model
    $one_domain_or_model = undef;   # top hit's domain (default) or model (if --samedomain)
    $two_domain_or_model = undef;   # second best hit's domain (default) or model (if --samedomain)
    $cur_domain_or_model = (opt_Get("--samedomain", $opt_HHR)) ? $model : $domain;

    # we count all nucleotides in all hits (don't enforce minimum threshold) to each model
    $nnts_per_model_HH{$model}{$strand} += abs($seqfrom - $seqto) + 1;
    $nhits_per_model_HH{$model}{$strand}++;
    $tbits_per_model_HH{$model}{$strand} += $score;
    if(! exists $mdl_bd_per_model_HHA{$model}{$strand}) { 
      @{$mdl_bd_per_model_HHA{$model}{$strand}} = ();
      @{$seq_bd_per_model_HHA{$model}{$strand}} = ();
    }
    push(@{$mdl_bd_per_model_HHA{$model}{$strand}}, ($mdlfrom . "." . $mdlto)); 
    push(@{$seq_bd_per_model_HHA{$model}{$strand}}, ($seqfrom . "." . $seqto)); 

    if(exists $first_model_HH{$family}) { 
      $first_model    = $first_model_HH{$family}{"model"};
      $first_domain   = $first_model_HH{$family}{"domain"};
      $first_evalue   = $first_model_HH{$family}{"evalue"};
      $first_score    = $first_model_HH{$family}{"score"};
      $first_start    = $first_model_HH{$family}{"start"};
      $first_stop     = $first_model_HH{$family}{"stop"};
      $first_strand   = $first_model_HH{$family}{"strand"};
      $first_mdlstart = $first_model_HH{$family}{"mdlstart"};
      $first_mdlstop  = $first_model_HH{$family}{"mdlstop"};
    }
    else { 
      $first_model    = undef;
      $first_domain   = undef;
      $first_evalue   = undef;
      $first_score    = undef;
      $first_start    = undef;
      $first_stop     = undef;
      $first_strand   = undef;
      $first_mdlstart = undef;
      $first_mdlstop  = undef;
    }
    if(exists $second_model_HH{$family}) { 
      $second_model    = $second_model_HH{$family}{"model"};
      $second_domain   = $second_model_HH{$family}{"domain"};
      $second_evalue   = $second_model_HH{$family}{"evalue"};
      $second_score    = $second_model_HH{$family}{"score"};
      $second_start    = $second_model_HH{$family}{"start"};
      $second_stop     = $second_model_HH{$family}{"stop"};
      $second_strand   = $second_model_HH{$family}{"strand"};
      $second_mdlstart = $second_model_HH{$family}{"mdlstart"};
      $second_mdlstop  = $second_model_HH{$family}{"mdlstop"};
    }
    else { 
      $second_model    = undef;
      $second_domain   = undef;
      $second_evalue   = undef;
      $second_score    = undef;
      $second_start    = undef;
      $second_stop     = undef;
      $second_strand   = undef;
      $second_mdlstart = undef;
      $second_mdlstop  = undef;
    }

    # first, enforce our global bit score minimum
    if($score >= $min_primary_sc) { 
      # yes, we either have no minimum, or our score exceeds our minimum
      $nhits_above_thresh++;
      $nhits_at_per_model_HH{$model}{$strand}++;
      $nnts_at_per_model_HH{$model}{$strand} += abs($seqfrom - $seqto) + 1;
      if(! defined $first_model) {  # use 'score' not 'evalue' because some methods don't define evalue, but all define score
        $cur_becomes_first = 1; # no current, 'one' this will be it
      }
      else { 
        # determine the domain (default) or model (--samedomain) of top hit and current hit we're looking at
        # if --samedomain, we require that top two hits be different models, not necessarily different domains
        $one_domain_or_model = (opt_Get("--samedomain", $opt_HHR)) ? $first_model : $first_domain;
        if($sort_by_evalues) { 
          if(($evalue < $first_evalue) || # this E-value is better than (less than) our current 'first' E-value
             ($evalue eq $first_evalue && $score > $first_score)) { # this E-value equals current 'first' E-value, 
            # but this score is better than current 'one' score
            $cur_becomes_first = 1;
          }
        }
        else { # we don't have E-values
          if($score > $first_score) { # score is better than current 'one' score
            $cur_becomes_first = 1;
          }
        }
      }
      # only possibly set $cur_becomes_second to TRUE if $cur_becomes_first is FALSE, and it's not the same model/domain as 'one'
      if((! $cur_becomes_first) && ($cur_domain_or_model ne $one_domain_or_model)) { 
        if(! defined $second_score) {  # use 'score' not 'evalue' because some methods don't define evalue, but all define score
          $cur_becomes_second = 1;
        }
        else { 
          $two_domain_or_model = (opt_Get("--samedomain", $opt_HHR)) ? $second_model : $second_domain;
          if($sort_by_evalues) { 
            if(($evalue < $second_evalue) || # this E-value is better than (less than) our current 'two' E-value
               ($evalue eq $second_evalue && $score > $second_score)) { # this E-value equals current 'two' E-value, 
              # but this score is better than current 'two' score
              $cur_becomes_second = 1;
            }
          }
          else { # we don't have E-values
            if($score > $second_score) { # score is better than current 'one' score
              $cur_becomes_second = 1;
            }
          }
        }
      }
    } # end of 'if($score >= $min_primary_sc))'
    # finished determining if this hit is a new 'one' or 'two' hit
    ##########################################################
    
    ##########################################################
    # if we have a new hit, update 'one' and/or 'two' data structures
    if($cur_becomes_first) { 
      # new 'one' hit, update 'one' variables, 
      # but first copy existing 'one' hit values to 'two', if 'one' hit is defined and it's a different model than current $model
      if((defined $one_domain_or_model) && ($one_domain_or_model ne $cur_domain_or_model)) { 
        set_model_vars(\%{$second_model_HH{$family}}, $first_model, $first_domain, $first_score, $first_evalue, $first_start, $first_stop, $first_strand, $first_mdlstart, $first_mdlstop);
      }
      # now set new 'one' hit values
      set_model_vars(\%{$first_model_HH{$family}}, $model, $domain, $score, $evalue, $seqfrom, $seqto, $strand, $mdlfrom, $mdlto);
    }
    elsif(($cur_becomes_second) && ($one_domain_or_model ne $cur_domain_or_model)) { 
      # new 'two' hit, set it
      # (we don't need to check that 'one_domain_or_model ne cur_domain_or_model' because we did that
      #  above before we set cur_becomes_second to true)
      set_model_vars(\%{$second_model_HH{$family}}, $model, $domain, $score, $evalue, $seqfrom, $seqto, $strand, $mdlfrom, $mdlto);
    }

    # finished updating 'one' or 'two' data structures
    ##########################################################

    $prv_target = $target;

    # sanity check
    if(((exists $first_model_HH{$family})  && (defined $first_model_HH{$family}{"model"})) && 
       ((exists $second_model_HH{$family}) && (defined $second_model_HH{$family}{"model"})) && 
       ($first_model_HH{$family}{"model"} eq $second_model_HH{$family}{"model"})) { 
      die "ERROR, coding error, first model and second model are identical for $family $target";
    }
  }

  # output data for final sequence
  if($nhits_above_thresh > 0) { 
    output_one_target($short_out_FH, $long_out_FH, $opt_HHR, $round, $have_accurate_coverage, $have_model_coords, $have_evalues, 
                      $sort_by_evalues, $width_HR, $domain_HR, $accept_HR, $question_HR, 
                      $prv_target, $seqidx_HR->{$prv_target}, abs($seqlen_HR->{$prv_target}), 
                      \%nhits_per_model_HH, \%nhits_at_per_model_HH, \%nnts_per_model_HH, \%nnts_at_per_model_HH, 
                      \%tbits_per_model_HH, \%mdl_bd_per_model_HHA, \%seq_bd_per_model_HHA, 
                      \%first_model_HH, \%second_model_HH);
    $seqlen_HR->{$prv_target} *= -1; # serves as a flag that we output info for this sequence
  }
  $nhits_above_thresh   = 0;
  %first_model_HH       = ();
  %second_model_HH      = ();
  %nhits_per_model_HH   = ();
  %tbits_per_model_HH   = ();
  %nnts_per_model_HH    = ();
  %mdl_bd_per_model_HHA = ();
  %seq_bd_per_model_HHA = ();

  # close file handle
  close(IN);
  
  return;
}


#################################################################
# Subroutine : set_model_vars()
# Incept:      EPN, Tue Dec 13 14:53:37 2016
#
# Purpose:     Set values of a hash.
#              
# Arguments: 
#   $HR:        REF to hash to set values of
#   $model:     value to set $HR->{"model"} to 
#   $domain:    value to set $HR->{"domain"} to 
#   $score:     value to set $HR->{"score"} to
#   $evalue:    value to set $HR->{"evalue"} to
#   $start:     value to set $HR->{"start"} to
#   $stop:      value to set $HR->{"stop"} to 
#   $strand:    value to set $HR->{"strand"} to
#   $mdlstart:  value to set $HR->{"mdlstart"} to
#   $mdlstop:   value to set $HR->{"mdlstop"} to 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub set_model_vars { 
  my $nargs_expected = 10;
  my $sub_name = "set_model_vars";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($HR, $model, $domain, $score, $evalue, $start, $stop, $strand, $mdlstart, $mdlstop) = @_;

  $HR->{"model"}    = $model;
  $HR->{"domain"}   = $domain;
  $HR->{"score"}    = $score;
  $HR->{"evalue"}   = $evalue;
  $HR->{"start"}    = $start;
  $HR->{"stop"}     = $stop;
  $HR->{"strand"}   = $strand;
  $HR->{"mdlstart"} = $mdlstart;
  $HR->{"mdlstop"}  = $mdlstop;

  return;
}

#################################################################
# Subroutine : output_all_hitless_targets()
# Incept:      EPN, Fri May  5 09:09:01 2017
#
# Purpose:     Call function to output information for all targets
#              with zero hits.
#              
# Arguments: 
#   $long_FH:       file handle to output long data to
#   $short_FH:      file handle to output short data to
#   $round:         '1' or '2', what round of searching we're in
#   $opt_HHR:       reference to 2D hash of cmdline options
#   $width_HR:      hash, key is "model" or "target", value 
#                   is width (maximum length) of any target/model
#   $seqidx_HR:     hash of target sequence indices
#   $seqlen_HR:     hash of target sequence lengths
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_all_hitless_targets { 
  my $nargs_expected = 7;
  my $sub_name = "output_all_hitless_targets";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($long_FH, $short_FH, $round, $opt_HHR, $width_HR, $seqidx_HR, $seqlen_HR) = @_;

  my $target;

  my $have_evalues      = determine_if_we_have_evalues($round, $opt_HHR);
  my $have_model_coords = determine_if_we_have_model_coords($round, $opt_HHR);

  if($round eq "1") { 
    foreach $target (keys %{$seqlen_HR}) { 
      if($seqlen_HR->{$target} >= 0) { # in round 1, positive sequence length values indicate no hits were found
        output_one_hitless_target($short_FH, $long_FH, $round, $opt_HHR, $width_HR, $target, $seqidx_HR->{$target}, abs($seqlen_HR->{$target}), $have_evalues, $have_model_coords);
        $seqlen_HR->{$target} *= -1; # serves as a flag that we output info for this sequence
      }
    }
  }
  elsif($round eq "2") { 
    foreach $target (keys %{$seqlen_HR}) { 
      if($seqlen_HR->{$target} <= 0) { # in round 2, negative sequence length values indicate no hits were found
        output_one_hitless_target($short_FH, $long_FH, $round, $opt_HHR, $width_HR, $target, $seqidx_HR->{$target}, abs($seqlen_HR->{$target}), $have_evalues, $have_model_coords);
        $seqlen_HR->{$target} *= -1; # serves as a flag that we output info for this sequence
      }
    }
  }

  return;
}

#################################################################
# Subroutine : output_one_hitless_target()
# Incept:      EPN, Thu Mar  2 11:37:13 2017
#
# Purpose:     Output information for current sequence with zero
#              hits in either long or short mode. Short mode if 
#              $do_short is true.
#              
# Arguments: 
#   $short_FH:          file handle to output short output to (can be undef to not output short output)
#   $long_FH:           file handle to output long output to (can be undef to not output long output)
#   $round:             '1' or '2', what round of searching we're in
#   $opt_HHR:           reference to 2D hash of cmdline options
#   $width_HR:          hash, key is "model" or "target", value 
#                       is width (maximum length) of any target/model
#   $target:            target name
#   $seqidx:            index of target sequence
#   $seqlen:            length of target sequence
#   $have_evalues:      '1' to print space for E-values
#   $have_model_coords: '1' to print space for E-values
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_one_hitless_target { 
  my $nargs_expected = 10;
  my $sub_name = "output_one_hitless_target";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($short_FH, $long_FH, $round, $opt_HHR, $width_HR, $target, $seqidx, $seqlen, $have_evalues, $have_model_coords) = @_;

  my $pass_fail = "FAIL";
  my $unusual_features = "*NoHits;";
  my $nfams = 0;
  my $nhits = 0;

  if(defined $short_FH) { 
    printf $short_FH ("%-*s  %-*s  %-*s  %-5s  %s  %s\n", 
                      $width_HR->{"index"}, $seqidx,
                      $width_HR->{"target"}, $target, 
                      $width_HR->{"classification"}, "-",
                      "-", $pass_fail, $unusual_features);
  }
  if(defined $long_FH) { 
    printf $long_FH ("%-*s  %-*s  %4s  %*d  %3d  %-*s  %-*s  %-*s  %-5s  %3s  %6s  %6s  %4s  %s%5s  %5s  %*s  %*s  ", 
                     $width_HR->{"index"}, $seqidx,
                     $width_HR->{"target"}, $target, 
                     $pass_fail, 
                     $width_HR->{"length"}, $seqlen, 
                     $nfams,
                     $width_HR->{"family"}, "-",
                     $width_HR->{"domain"}, "-", 
                     $width_HR->{"model"}, "-", 
                     "-", 
                     "-", 
                     "-", 
                     "-",
                     "-",
                     ($have_evalues) ? "       -  " : "",
                     "-",
                     "-", 
                     $width_HR->{"length"}, "-", 
                     $width_HR->{"length"}, "-");
    if($have_model_coords) { 
      printf $long_FH ("%5s  %5s  ", "-", "-");
    }
    if($round ne "2") { 
      printf $long_FH ("%6s  %6s  %-*s  %6s  %s", 
                       "-" , 
                       "-" , 
                       $width_HR->{"model"}, "-", 
                     "-", 
                       ($have_evalues) ? "       -  " : "");
    }
    printf $long_FH ("%s\n", 
                     $unusual_features);
  }
  return;
}

#################################################################
# Subroutine : output_one_target()
# Incept:      EPN, Tue Dec 13 15:30:12 2016
#
# Purpose:     Output information for current sequence in short 
#              and/or long mode (depending on whether $short_FH 
#              and $long_FH are defined or not).
#              
# Arguments: 
#   $short_FH:               file handle to output short output to (can be undef to not output short output)
#   $long_FH:                file handle to output long output to (can be undef to not output long output)
#   $opt_HHR:                reference to 2D hash of cmdline options
#   $round:                  '1' or '2', what round of searching we're in
#   $have_accurate_coverage: '1' if we have accurate coverage, '0' if not
#   $have_model_coords:      '1' if we have model coords, '0' if not
#   $have_evalues:           '1' if we have E-values, '0' if not
#   $sort_by_evalues:        '1' if we are sorting by E-values, '0' if not
#   $width_HR:               hash, key is "model" or "target", value 
#                            is width (maximum length) of any target/model
#   $domain_HR:              reference to domain hash
#   $accept_HR:              reference to the 'accept' hash, key is "model"
#                            value is '1' if hits to model should have unexpected_model
#                            ufeature, 0 if not
#   $question_HR:            reference to the 'question' hash, key is "model"
#                            value is '1' if hits to model should have questionable_model
#                            ufeature, 0 if not
#   $target:                 target name
#   $seqidx:                 index of target sequence
#   $seqlen:                 length of target sequence
#   $nhits_HHR:              reference to hash of num hits (no threshold) per model (key 1), strand (key 2)
#   $nhits_at_HHR:           reference to hash of num hits above threshold per model (key 1), strand (key 2)
#   $nnts_HHR:               reference to hash of num nucleotides (no threshold) in all hits per model (key 1), strand (key 2)
#   $nnts_at_HHR:            reference to hash of num nucleotides above threshold in all hits per model (key 1), strand (key 2)
#   $tbits_HHR:              reference to hash of total (summed) bit score in all hits per model (key 1), per strand (key 2)
#   $mdl_bd_HHAR:            reference to hash of hash of array of model boundaries per hits, per model (key 1), per strand (key 2)
#   $seq_bd_HHAR:            reference to hash of hash of array of sequence boundaries per hits, per model (key 1), per strand (key 2)
#   $first_model_HHR:        hit stats for first model (best model)
#   $second_model_HHR:        hit stats for second model (second-best model)
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_one_target { 
  my $nargs_expected = 24;
  my $sub_name = "output_one_target";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($short_FH, $long_FH, $opt_HHR, $round, $have_accurate_coverage, $have_model_coords, $have_evalues, 
      $sort_by_evalues, $width_HR, $domain_HR, $accept_HR, $question_HR, $target, 
      $seqidx, $seqlen, $nhits_HHR, $nhits_at_HHR, $nnts_HHR, $nnts_at_HHR, $tbits_HHR, $mdl_bd_HHAR, $seq_bd_HHAR, 
      $first_model_HHR, $second_model_HHR) = @_;

  # determine the winning family
  my $wfamily = undef;
  my $better_than_winning = 0;
  foreach my $family (keys %{$first_model_HHR}) { 
    $better_than_winning = 0;
    # determine if this hit is better than our winning clan
    if(! defined $wfamily) { 
      $better_than_winning = 1; 
    }
    elsif($sort_by_evalues) { 
      if(($first_model_HHR->{$family}{"evalue"} < $first_model_HHR->{$wfamily}{"evalue"}) || # this E-value is better than (less than) our current winning E-value
         ($first_model_HHR->{$family}{"evalue"} eq $first_model_HHR->{$wfamily}{"evalue"} && $first_model_HHR->{$family}{"score"} > $first_model_HHR->{$wfamily}{"score"})) { # this E-value equals current 'one' E-value, but this score is better than current winning score
        $better_than_winning = 1;
      }
    }
    else { # we are not sorting by E-values
      if($first_model_HHR->{$family}{"score"} > $first_model_HHR->{$wfamily}{"score"}) { # score is better than current winning score
        $better_than_winning = 1;
      }
    }
    if($better_than_winning) { 
      $wfamily = $family;
    }
  }
  my $nfams_fail_str = $wfamily; # used only if we FAIL because there's 
                                 # more than one hit to different families for this sequence
  my $nhits     = $nhits_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}};
  my $nhits_at  = $nhits_at_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}};
  my $one_tbits = $tbits_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}};
  my $two_tbits = undef;

  if(defined $second_model_HHR->{$wfamily}{"model"}) { 
    $two_tbits = $tbits_HHR->{$second_model_HHR->{$wfamily}{"model"}}{$second_model_HHR->{$wfamily}{"strand"}};
    if($round eq "2") { # sanity check
      die "ERROR in $sub_name, round 2, but we have hits to more than one model"; 
    }
  }

  # determine if we have hits on both strands, and if so, build up failure string
  my $both_strands_fail_str = "";
  # add a '.' followed by <d>, where <d> is number of hits on opposite strand of best hit, if <d> > 0
  my $other_strand = ($first_model_HHR->{$wfamily}{"strand"} eq "+") ? "-" : "+";
  if(exists $nhits_at_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$other_strand} && 
     $nhits_at_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$other_strand} > 0) { 
    $nhits_at += $nhits_at_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$other_strand};
    $both_strands_fail_str  = "BothStrands:(" . $first_model_HHR->{$wfamily}{"strand"} . ":";
    $both_strands_fail_str .= $nhits_at_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}} . "_hit(s)"; 
    if($have_accurate_coverage) { 
      $both_strands_fail_str .= "[" . $nnts_at_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}} . "_nt]";
    }
    $both_strands_fail_str .= "," . $other_strand . ":";
    $both_strands_fail_str .= $nhits_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$other_strand} . "_hit(s)";
    if($have_accurate_coverage) { 
      $both_strands_fail_str .= "[" . $nnts_at_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$other_strand} . "_nt])";
    }
  }

  # determine if we have hits that overlap on the model by more than maximum allowed amount
  my $duplicate_model_region_str = "";
  if($have_model_coords) { # we can only do this if search output included model coords
    $nhits = scalar(@{$mdl_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}});
    my $noverlap_allowed = opt_Get("--maxoverlap", $opt_HHR);
    for(my $i = 0; $i < $nhits; $i++) { 
      for(my $j = $i+1; $j < $nhits; $j++) { 
        my $bd1 = $mdl_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}[$i];
        my $bd2 = $mdl_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}[$j];
        my ($noverlap, $overlap_str) = get_overlap($bd1, $bd2);
        if($noverlap > $noverlap_allowed) { 
          if($duplicate_model_region_str eq "") { 
            $duplicate_model_region_str .= "DuplicateRegion:"; 
          }
          else { 
            $duplicate_model_region_str .= ",";
          }
          $duplicate_model_region_str .= "(" . $overlap_str . ")_hits_" . ($i+1) . "_and_" . ($j+1) . "($bd1,$bd2)";
        }
      }
    }
  }
    
  # determine if hits are out of order between model and sequence
  my $out_of_order_str = "";
  if($have_model_coords) { # we can only do this if search output included model coords
    if($nhits > 1) { 
      my $i;
      my @seq_hit_order_A = (); # array of sequence boundary hit indices in sorted order [0..nhits-1] values are in range 1..nhits
      my @mdl_hit_order_A = (); # array of model    boundary hit indices in sorted order [0..nhits-1] values are in range 1..nhits
      my $seq_hit_order_str = sort_hit_array($seq_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}, \@seq_hit_order_A, 0); # 0 means duplicate values in first array are not allowed
      my $mdl_hit_order_str = sort_hit_array($mdl_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}, \@mdl_hit_order_A, 1); # 1 means duplicate values in first array are allowed
      # check if the hits are out of order we don't just check for equality of the
      # two strings because it's possible (but rare) that there could be duplicates in the model
      # order array (but not in the sequence array), so we need to allow for that.
      my $out_of_order_flag = 0;
      for($i = 0; $i < $nhits; $i++) { 
        my $x = $mdl_hit_order_A[$i];
        my $y = $seq_hit_order_A[$i];
        # check to see if hit $i is same order in both mdl and seq coords
        # or if it is not, it's okay if it is identical to the one that is
        # example: 
        # hit 1 seq 1..10   model  90..99
        # hit 2 seq 11..20  model 100..110
        # hit 3 seq 21..30  model 100..110
        # seq order: 1,2,3
        # mdl order: 1,3,2 (or 1,2,3) we want both to be ok (not FAIL)
        if(($x ne $y) && # hits are not the same order
           ($mdl_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}[($x-1)] ne
            $mdl_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}[($y-1)])) { # hit is not identical to hit in correct order
          $out_of_order_flag = 1;
        }
      }
      if($out_of_order_flag) { 
        $out_of_order_str = "*InconsistentHits:seq_order(" . $seq_hit_order_str . "[";
        for($i = 0; $i < $nhits; $i++) { 
          $out_of_order_str .= $seq_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}[$i]; 
          if($i < ($nhits-1)) { $out_of_order_str .= ","; }
        }
        $out_of_order_str .= "]),mdl_order(" . $mdl_hit_order_str . "[";
        for($i = 0; $i < $nhits; $i++) { 
          $out_of_order_str .= $mdl_bd_HHAR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}}[$i]; 
          if($i < ($nhits-1)) { $out_of_order_str .= ","; }
        }
        $out_of_order_str .= "])";
      }
    }
  }

  my $nnts  = $nnts_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}};
  # build up 'other_hits_string' string about other hits in other clans, if any
  my $other_hits_string = "";
  my $nfams = 1;
  foreach my $family (keys %{$first_model_HHR}) { 
    if($family ne $wfamily) { 
      if(exists($first_model_HHR->{$family}{"model"})) { 
        if($other_hits_string ne "") { $other_hits_string .= ","; }
        if($have_evalues) { 
          $other_hits_string .= sprintf("%s:%s:%g:%.1f/%d-%d:%s",
                                   $family, $first_model_HHR->{$family}{"model"}, $first_model_HHR->{$family}{"evalue"}, $first_model_HHR->{$family}{"score"}, 
                                   $first_model_HHR->{$family}{"start"}, $first_model_HHR->{$family}{"stop"}, $first_model_HHR->{$family}{"strand"});
        }
        else { # we don't have E-values
          $other_hits_string .= sprintf("%s:%s:%.1f/%d-%d:%s",
                                   $family, $first_model_HHR->{$family}{"model"}, $first_model_HHR->{$family}{"score"}, 
                                   $first_model_HHR->{$family}{"start"}, $first_model_HHR->{$family}{"stop"}, $first_model_HHR->{$family}{"strand"});
        }
        $nfams++;
        $nfams_fail_str .= "+" . $family;
      }
    }
  }
  if(! defined $wfamily) { die "ERROR wfamily undefined for $target"; }
  my $best_coverage = (abs($first_model_HHR->{$wfamily}{"stop"} - $first_model_HHR->{$wfamily}{"start"}) + 1) / $seqlen;
  my $tot_coverage  = $nnts / $seqlen;
  my $one_evalue2print = ($have_evalues) ? sprintf("%8g  ", $first_model_HHR->{$wfamily}{"evalue"}) : "";
  my $two_evalue2print = undef;
  if(defined $second_model_HHR->{$wfamily}{"model"}) { 
    $two_evalue2print = ($have_evalues) ? sprintf("%8g  ", $second_model_HHR->{$wfamily}{"evalue"}) : "";
  }
  
  # if we have a second-best model, determine score difference between best and second-best model
  my $do_ppos_score_diff = 1; # true unless --absdiff option used
  if(opt_IsUsed("--absdiff", $opt_HHR)) { 
    $do_ppos_score_diff = 0;
  }
  my $score_total_diff = undef; # score total difference 
  my $score_ppos_diff  = undef; # score per position difference 
  my $diff_low_thresh  = undef; # bit score difference for 'low difference' warning/failure
  my $diff_vlow_thresh = undef; # bit score difference for 'very low difference 'warning/failure
  my $diff_low_str     = undef; # string that explains low bit score difference warning/failure
  my $diff_vlow_str    = undef; # string that explains very low bit score difference warning/failure

  if(defined $second_model_HHR->{$wfamily}{"score"}) { 
    # determine score difference threshold
    $score_total_diff = ($first_model_HHR->{$wfamily}{"score"} - $second_model_HHR->{$wfamily}{"score"});
    $score_ppos_diff  = $score_total_diff / abs($first_model_HHR->{$wfamily}{"stop"} - $first_model_HHR->{$wfamily}{"start"});
    if($do_ppos_score_diff) { 
      # default: per position score difference, dependent on length of hit
      $diff_low_thresh  = opt_Get("--lowpdiff",  $opt_HHR);
      $diff_vlow_thresh = opt_Get("--vlowpdiff", $opt_HHR);
      $diff_low_str     = $diff_low_thresh . "_bits_per_posn";
      $diff_vlow_str    = $diff_vlow_thresh . "_bits_per_posn";
    }
    else { 
      # absolute score difference, regardless of length of hit
      $diff_low_thresh  = opt_Get("--lowadiff", $opt_HHR); 
      $diff_vlow_thresh = opt_Get("--vlowadiff", $opt_HHR); 
      $diff_low_str     = $diff_low_thresh . "_total_bits";
      $diff_vlow_str    = $diff_vlow_thresh . "_total_bits";
    }
  }

  # Determine if there are any unusual features 
  # and if the sequence PASSes or FAILs.
  # 
  # Possible unusual feature criteria are listed below. 
  # A FAILure occurs if either the criteria is a strict failure criteria
  # or if it is a optional criteria and the relevant command line option is used.
  # 
  # Four strict failure criteria:
  # - no hits (THIS WILL NEVER HAPPEN HERE, THEY'RE HANDLED BY output_one_hitless_target())
  # - number of hits to different families is higher than one (e.g. SSU and LSU hit)
  # - hits to best model on both strands 
  # - hits overlap on model (duplicate model region)
  # - inconsistent hit order
  # 
  # Optional failure criteria, require a specific command line option to cause a failure
  #  but always get printed to unusual_features columns)
  # - winning hit is to unacceptable model (requires --inaccept to FAIL or get reported)
  # - hit is on minus strand (requires --minusfail to FAIL, always reported))
  # - low score, bits per position below threshold (requires --scfail)
  # - low coverage (requires --covfail)
  # - score difference between top two models is below $diff_thresh (requires --difffail)
  # - number of this to best model is > 1 (requires --multfail)
  # 
  # Optional unusual features, these will automatically cause a sequence if FAIL if
  # reported
  # - sequence is less than <n1> nucleotides (requires --shortfail <n1>)
  # - sequence is more than <n2> nucleotides (requires --longfail <n2>)
  my $pass_fail = "PASS";
  my $unusual_features = "";

  # check/enforce strict failure criteria
  # hits to more than one family?
  if($nfams > 1) { 
    $pass_fail = "FAIL";
    $unusual_features .= "*MultipleFamilies:($nfams_fail_str,$other_hits_string);";
  }
  # hits on both strands to best model?
  if($both_strands_fail_str ne "") { 
    $pass_fail = "FAIL";
    $unusual_features .= "*" . $both_strands_fail_str . ";";
  }    
  # duplicate model region
  if($duplicate_model_region_str ne "") { 
    $pass_fail = "FAIL";
    $unusual_features .= "*" . $duplicate_model_region_str . ";";
  }    
  # hits in inconsistent order
  if($out_of_order_str ne "") { 
    $pass_fail = "FAIL";
    $unusual_features .= $out_of_order_str . ";";
  }

  # check/enforce optional failure criteria

  # determine if the sequence hits to an questionable or unacceptable model
  if($question_HR->{$first_model_HHR->{$wfamily}{"model"}} == 1) { 
    if(opt_Get("--questfail", $opt_HHR)) { 
      $pass_fail = "FAIL";
      $unusual_features .= "*";
    }
    $unusual_features .= "QuestionableModel:(" . $first_model_HHR->{$wfamily}{"model"} . ");";
  }
  elsif($accept_HR->{$first_model_HHR->{$wfamily}{"model"}} != 1) { 
    $pass_fail = "FAIL";
    $unusual_features .= "*UnacceptableModel:(" . $first_model_HHR->{$wfamily}{"model"} . ");";
  }
  # determine if sequence is on opposite strand
  if($first_model_HHR->{$wfamily}{"strand"} eq "-") { 
    if(opt_Get("--minusfail", $opt_HHR)) { 
      $pass_fail = "FAIL";
      $unusual_features .= "*";
    }
    $unusual_features .= "MinusStrand;";
  }
  # determine if the sequence has a 'low_score'
  # it does if bits per position (of entire sequence not just hit)
  # is below the threshold (--lowppossc) minimum
  my $bits_per_posn = $one_tbits / $seqlen;
  if($bits_per_posn < opt_Get("--lowppossc", $opt_HHR)) { 
    if(opt_Get("--scfail", $opt_HHR)) { 
      $pass_fail = "FAIL";
      $unusual_features .= "*";
    }
    $unusual_features .= sprintf("LowScore:(%.2f<%.2f);", $bits_per_posn, opt_Get("--lowppossc", $opt_HHR));
  }
  # determine if coverage is low
  my $cov_thresh = undef;
  if(opt_IsUsed("--tshortlen", $opt_HHR)) { 
    # threshold depends on length
    $cov_thresh = ($seqlen <= opt_Get("--tshortlen", $opt_HHR)) ? opt_Get("--tshortcov", $opt_HHR) : opt_Get("--tcov", $opt_HHR);
  }
  else { 
    # threshold does not depend on length
    $cov_thresh = opt_Get("--tcov", $opt_HHR);
  }
  if($tot_coverage < $cov_thresh) { 
    if(opt_Get("--covfail", $opt_HHR)) { 
      $pass_fail = "FAIL";
      $unusual_features .= "*";
    }
    $unusual_features .= sprintf("LowCoverage:(%.3f<%.3f);", $tot_coverage, $cov_thresh);
  }
  # determine if the sequence has a low score difference between the top
  # two domains
  if(defined $second_model_HHR->{$wfamily}{"model"}) { 
    # determine score difference threshold
    $score_total_diff = $one_tbits - $two_tbits; 
    $score_ppos_diff  = $score_total_diff / $nnts;
    if($do_ppos_score_diff) { 
      # default: per position score difference, dependent on length of hit
      $diff_vlow_thresh = opt_Get("--vlowpdiff", $opt_HHR);
      $diff_low_thresh  = opt_Get("--lowpdiff",  $opt_HHR);
      if($score_ppos_diff < $diff_vlow_thresh) { 
        if(opt_Get("--difffail", $opt_HHR)) { 
          $pass_fail = "FAIL"; 
          $unusual_features .= "*";
        }
        $unusual_features .= sprintf("VeryLowScoreDifference:(%.3f<%.3f_bits_per_posn);", $score_ppos_diff, $diff_vlow_thresh);
      }
      elsif($score_ppos_diff < $diff_low_thresh) { 
        if(opt_Get("--difffail", $opt_HHR)) { 
          $pass_fail = "FAIL"; 
          $unusual_features .= "*";
        }
        $unusual_features .= sprintf("LowScoreDifference:(%.3f<%.3f_bits_per_posn);", $score_ppos_diff, $diff_low_thresh);
      }
    }
    else { 
      # absolute score difference, regardless of length of hit
      $diff_vlow_thresh = opt_Get("--vlowadiff", $opt_HHR);
      $diff_low_thresh  = opt_Get("--lowadiff",  $opt_HHR);
      if($score_total_diff < $diff_vlow_thresh) { 
        if(opt_Get("--difffail", $opt_HHR)) { 
          $pass_fail = "FAIL"; 
          $unusual_features .= "*";
        }
        $unusual_features .= sprintf("VeryLowScoreDifference:(%.3f<%.3f_total_bits);", $score_total_diff, $diff_vlow_thresh);
      }
      elsif($score_total_diff < $diff_low_thresh) { 
        if(opt_Get("--difffail", $opt_HHR)) { 
          $pass_fail = "FAIL"; 
          $unusual_features .= "*";
        }
        $unusual_features .= sprintf("LowScoreDifference:(%.3f<%.3f_total_bits);", $score_total_diff, $diff_low_thresh);
      }
    }
  }
  # determine if there are more than one hit to the best model
  $nhits = $nhits_HHR->{$first_model_HHR->{$wfamily}{"model"}}{$first_model_HHR->{$wfamily}{"strand"}};
  if($nhits > 1) {
    if(opt_Get("--multfail", $opt_HHR)) { 
      $pass_fail = "FAIL";
      $unusual_features .= "*";
    }
    $unusual_features .= "MultipleHits:($nhits);";
  }
  # optional unusual features (if any)
  if((opt_IsUsed("--shortfail", $opt_HHR)) && ($seqlen < opt_Get("--shortfail", $opt_HHR))) { 
    $pass_fail = "FAIL";
    $unusual_features .= "*TooShort:($seqlen<" . opt_Get("--shortfail", $opt_HHR) . ");";
  }
  if((opt_IsUsed("--longfail", $opt_HHR)) && ($seqlen > opt_Get("--longfail", $opt_HHR))) { 
    $pass_fail = "FAIL";
    $unusual_features .= "*TooLong:($seqlen>" . opt_Get("--longfail", $opt_HHR) . ");";
  }
  # if there are no unusual features, set the unusual feature string as '-'
  if($unusual_features eq "") { $unusual_features = "-"; }

  # finally, output
  if(defined $short_FH) { 
    printf $short_FH ("%-*s  %-*s  %-*s  %-5s  %s  %s\n", 
                      $width_HR->{"index"}, $seqidx,
                      $width_HR->{"target"}, $target, 
                      $width_HR->{"classification"}, $wfamily . "." . $domain_HR->{$first_model_HHR->{$wfamily}{"model"}}, 
                      ($first_model_HHR->{$wfamily}{"strand"} eq "+") ? "plus" : "minus", 
                      $pass_fail, $unusual_features);
  }
  if(defined $long_FH) { 
    printf $long_FH ("%-*s  %-*s  %4s  %*d  %3d  %-*s  %-*s  %-*s  %-5s  %3d  %6.1f  %6.1f  %4.2f  %s%5.3f  %5.3f  %*d  %*d  ", 
                     $width_HR->{"index"}, $seqidx,
                     $width_HR->{"target"}, $target, 
                     $pass_fail, 
                     $width_HR->{"length"}, $seqlen, 
                     $nfams, 
                     $width_HR->{"family"}, $wfamily, 
                     $width_HR->{"domain"}, $domain_HR->{$first_model_HHR->{$wfamily}{"model"}}, 
                     $width_HR->{"model"}, $first_model_HHR->{$wfamily}{"model"}, 
                     ($first_model_HHR->{$wfamily}{"strand"} eq "+") ? "plus" : "minus", 
                     $nhits, 
                     $one_tbits,
                     $first_model_HHR->{$wfamily}{"score"}, 
                     $bits_per_posn, 
                     $one_evalue2print, 
                     $tot_coverage, 
                     $best_coverage, 
                     $width_HR->{"length"}, $first_model_HHR->{$wfamily}{"start"}, 
                     $width_HR->{"length"}, $first_model_HHR->{$wfamily}{"stop"});
    if($have_model_coords) { 
      printf $long_FH ("%5d  %5d  ", 
                       $first_model_HHR->{$wfamily}{"mdlstart"},
                       $first_model_HHR->{$wfamily}{"mdlstop"});
    }

    if($round ne "2") { # we never have info for a second model if round is 2
      if(defined $second_model_HHR->{$wfamily}{"model"}) { 
        printf $long_FH ("%6.1f  %6.3f  %-*s  %6.1f  %s", 
                         $score_total_diff, 
                         $score_ppos_diff,
                         $width_HR->{"model"}, $second_model_HHR->{$wfamily}{"model"}, 
                         $two_tbits,
                         $two_evalue2print);
      }
      else { 
        printf $long_FH ("%6s  %6s  %-*s  %6s  %s", 
                         "-" , 
                         "-" , 
                         $width_HR->{"model"}, "-", 
                         "-", 
                         ($have_evalues) ? "       -  " : "");
      }
    }
    
    if($unusual_features eq "") { 
      $unusual_features = "-";
    }
    
    print $long_FH ("$unusual_features\n");
  }

  return;
}


#################################################################
# Subroutine : output_short_headers()
# Incept:      EPN, Fri Dec 30 08:51:01 2016
#
# Purpose:     Output column headers to the short output file.
#              
# Arguments: 
#   $FH:        file handle to output to
#   $width_HR:  ref to hash, keys include "model" and "target", 
#               value is width (maximum length) of any target/model
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_short_headers { 
  my $nargs_expected = 2;
  my $sub_name = "output_short_headers";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $width_HR) = (@_);

  my $index_dash_str  = "#" . ribo_GetMonoCharacterString($width_HR->{"index"}-1, "-");
  my $target_dash_str = ribo_GetMonoCharacterString($width_HR->{"target"}, "-");
  my $class_dash_str  = ribo_GetMonoCharacterString($width_HR->{"classification"}, "-");

  printf $FH ("%-*s  %-*s  %-*s  %5s  %4s  %s\n", 
              $width_HR->{"index"}, "#idx", 
              $width_HR->{"target"}, "target", 
              $width_HR->{"classification"}, "classification", 
              "strnd", "p/f", "unexpected_features");
  printf $FH ("%-*s  %-*s  %-*s  %3s  %4s  %s\n", 
              $width_HR->{"index"},          $index_dash_str, 
              $width_HR->{"target"},         $target_dash_str, 
              $width_HR->{"classification"}, $class_dash_str, 
              "-----", "----", "-------------------");
  return;
}

#################################################################
# Subroutine : output_long_headers()
# Incept:      EPN, Fri Dec 30 08:51:01 2016
#
# Purpose:     Output column headers to the long output file.
#              
# Arguments: 
#   $FH:        file handle to output to
#   $round:     '1', '2', or 'final' the round of the file that
#               we're outputting for (final is the combined file
#               created from both rounds 1 and 2)
#   $opt_HHR:   ref to 2D options hash
#   $width_HR:  ref to hash, keys include "model" and "target", 
#               value is width (maximum length) of any target/model
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_long_headers { 
  my $nargs_expected = 4;
  my $sub_name = "output_long_headers";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $round, $opt_HHR, $width_HR) = (@_);

  my $index_dash_str   = "#" . ribo_GetMonoCharacterString($width_HR->{"index"}-1, "-");
  my $target_dash_str  = ribo_GetMonoCharacterString($width_HR->{"target"}, "-");
  my $model_dash_str   = ribo_GetMonoCharacterString($width_HR->{"model"},  "-");
  my $family_dash_str  = ribo_GetMonoCharacterString($width_HR->{"family"}, "-");
  my $domain_dash_str  = ribo_GetMonoCharacterString($width_HR->{"domain"}, "-");
  my $length_dash_str  = ribo_GetMonoCharacterString($width_HR->{"length"}, "-");

  my $have_model_coords = determine_if_we_have_model_coords($round, $opt_HHR);
  my $have_evalues      = determine_if_we_have_evalues($round, $opt_HHR);
  my $have_evalues_r1   = determine_if_we_have_evalues(1, $opt_HHR);

  my $best_model_group_width   = $width_HR->{"model"} + 2 + 6 + 2 + 6 + 2 + 4 + 2 + 3 + 2 + 5 + 2 + 5 + 2 + 5 + 2 + $width_HR->{"length"} + 2 + $width_HR->{"length"};
  my $second_model_group_width = $width_HR->{"model"} + 2 + 6;

  if($have_evalues) { 
    $best_model_group_width   += 2 + 8;
  }
  if($round eq "final") { # final round is special, second model E-values will come from round 1
    if($have_evalues_r1) { 
      $second_model_group_width += 2 + 8;
    }
  }
  else { # not final round, second model E-values come from current round
    if($have_evalues) { 
      $second_model_group_width += 2 + 8;
    }
  }

  if($have_model_coords) { 
    $best_model_group_width   += 2 + 5 + 2 + 5;
  }

  if(length("best-scoring model") > $best_model_group_width) { 
    $best_model_group_width = length("best-scoring model"); 
  }
  if(opt_Get("--samedomain", $opt_HHR)) { 
    if(length("second best-scoring model") > $second_model_group_width) { 
      $second_model_group_width = length("second best-scoring model"); 
    } 
  }
  else { 
    if(length("different domain's best-scoring model") > $second_model_group_width) { 
      $second_model_group_width = length("different domain's best-scoring model"); 
    } 
  }

  my $best_model_group_dash_str   = ribo_GetMonoCharacterString($best_model_group_width, "-");
  my $second_model_group_dash_str = ribo_GetMonoCharacterString($second_model_group_width, "-");
  
  # line 1
  printf $FH ("%-*s  %-*s  %4s  %*s  %3s  %*s  %*s  %-*s  %6s  %6s", 
              $width_HR->{"index"},  "#",
              $width_HR->{"target"}, "",
              "", 
              $width_HR->{"length"}, "", 
              "", 
              $width_HR->{"family"}, "", 
              $width_HR->{"domain"}, "", 
              $best_model_group_width, center_string($best_model_group_width, "best-scoring model"), 
              "", 
              "");
  if($round ne "2") { # round 2: skip second model section
    printf $FH ("  %-*s", 
                $second_model_group_width, center_string($second_model_group_width, (opt_Get("--samedomain", $opt_HHR)) ? "second best-scoring model" : "different domain's best-scoring model"));
  }
  printf $FH ("  %s\n", "");
  
  # line 2
  printf $FH ("%-*s  %-*s  %4s  %*s  %3s  %*s  %*s  %-*s  %6s  %6s",
              $width_HR->{"index"},  "#",
              $width_HR->{"target"}, "",
              "", 
              $width_HR->{"length"}, "", 
              "", 
              $width_HR->{"family"}, "", 
              $width_HR->{"domain"}, "", 
              $best_model_group_width, $best_model_group_dash_str, 
              "", 
              "");
  if($round ne "2") { # round 2: skip second model section
    printf $FH ("  %-*s", 
                $second_model_group_width, $second_model_group_dash_str);
  }
  printf $FH ("  %s\n", "");
  
  # line 3
  printf $FH ("%-*s  %-*s  %4s  %*s  %3s  %-*s  %-*s  %-*s  %5s  %3s  %6s  %6s  %4s  %s%5s  %5s  %*s  %*s  ",
              $width_HR->{"index"},  "#idx", 
              $width_HR->{"target"}, "target",
              "p/f", 
              $width_HR->{"length"}, "length", 
              "#fm", 
              $width_HR->{"family"}, "fam", 
              $width_HR->{"domain"}, "domain", 
              $width_HR->{"model"},  "model", 
              "strnd",
              "#ht", 
              "tscore", 
              "bscore", 
              "s/nt",
              ($have_evalues) ? " bevalue  " : "", 
              "tcov",
              "bcov",
              $width_HR->{"length"}, "bfrom",
              $width_HR->{"length"}, "bto");

  if($have_model_coords) { 
    printf $FH ("%5s  %5s  ", 
                "mfrom",
                "mto");
  }
  if($round ne "2") { 
    printf $FH ("%6s  %6s  %-*s  %6s  %s",  
                "scdiff",
                "scd/nt",
                $width_HR->{"model"},  "model", 
                "tscore", 
                ($have_evalues_r1) ? "  bevalue  " : "");
  }
  printf $FH ("%s\n",
              "unexpected_features");

  # line 4
  printf $FH ("%-*s  %-*s  %4s  %*s  %3s  %*s  %*s  %-*s  %5s  %3s  %6s  %6s  %4s  %s%5s  %5s  %*s  %*s  ", 
              $width_HR->{"index"},  $index_dash_str,
              $width_HR->{"target"}, $target_dash_str, 
              "----", 
              $width_HR->{"length"}, $length_dash_str,
              "---", 
              $width_HR->{"family"}, $family_dash_str,
              $width_HR->{"domain"}, $domain_dash_str, 
              $width_HR->{"model"},  $model_dash_str,
              "-----", 
              "---",
              "------", 
              "------", 
              "----",
              ($have_evalues) ? "--------  " : "",
              "-----",
              "-----",
              $width_HR->{"length"}, $length_dash_str,
              $width_HR->{"length"}, $length_dash_str);

  if($have_model_coords) { 
    printf $FH ("%5s  %5s  ", 
                "-----",
                "-----");
  }
  if($round ne "2") { 
    printf $FH ("%6s  %6s  %-*s  %6s  %s", 
                "------", 
                "------", 
                $width_HR->{"model"},  $model_dash_str, 
                "------", 
                ($have_evalues_r1) ? "--------  " : "");
  }
  printf $FH ("%s\n", 
              "-------------------");

  return;
}

#################################################################
# Subroutine : output_short_tail()
# Incept:      EPN, Thu Feb 23 15:29:21 2017
#
# Purpose:     Output explanation of columns to short output file.
#              
# Arguments: 
#   $FH:           file handle to output to
#   $ufeature_AR:  ref to array of all unexpected feature strings
#   $opt_HHR:      reference to options 2D hash
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_short_tail { 
  my $nargs_expected = 3;
  my $sub_name = "output_short_tail";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $ufeature_AR, $opt_HHR) = (@_);

  printf $FH ("#\n");
  printf $FH ("# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - \n");
  printf $FH ("# Explanation of columns:\n");
  printf $FH ("#\n");
  printf $FH ("# Column 1 [idx]:                 index of sequence in input sequence file\n");
  printf $FH ("# Column 2 [target]:              name of target sequence\n");
  printf $FH ("# Column 3 [classification]:      classification of sequence\n");
  printf $FH ("# Column 4 [strnd]:               strand ('plus' or 'minus') of best-scoring hit\n");
#  printf $FH ("# Column 5 [p/f]:                 PASS or FAIL (see below for more on FAIL)\n");
  printf $FH ("# Column 5 [p/f]:                 PASS or FAIL (reasons for failure begin with '*' in final column)\n");
  printf $FH ("# Column 6 [unexpected_features]: unexpected/unusual features of sequence (see below)\n");
  
  output_unexpected_features_explanation($FH, $ufeature_AR, $opt_HHR);

  return;
}


#################################################################
# Subroutine : output_long_tail()
# Incept:      EPN, Thu Feb 23 15:33:25 2017
#
# Purpose:     Output explanation of columns to long output file.
#              
# Arguments: 
#   $FH:           file handle to output to
#   $round:        '1', '2' or 'final', indicates which file we're
#                  output this for, round 1, round 2, or the final
#                  output file.
#   $ufeature_AR:  ref to array of all unexpected feature strings
#   $opt_HHR:      reference to options 2D hash
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_long_tail { 
  my $nargs_expected = 4;
  my $sub_name = "output_long_tail";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $round, $ufeature_AR, $opt_HHR) = (@_);

  my $have_evalues           = determine_if_we_have_evalues     ($round, $opt_HHR);  # 
  my $have_evalues_r1        = determine_if_we_have_evalues     (1, $opt_HHR);       # do we have E-values in round 1? 
  my $have_accurate_coverage = determine_if_coverage_is_accurate($round, $opt_HHR);
  my $have_model_coords      = determine_if_we_have_model_coords($round, $opt_HHR);

  my $inaccurate_cov_str = ("#                                  (these values are inaccurate, run with --1hmm or --1slow to get accurate coverage)\n");

  my $column_ct = 1;

  printf $FH ("#\n");
  printf $FH ("# Explanation of columns:\n");
  printf $FH ("#\n");
  printf $FH ("# Column %2d [idx]:                 index of sequence in input sequence file\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [target]:              name of target sequence\n", $column_ct); 
  $column_ct++;
  printf $FH ("# Column %2d [p/f]:                 PASS or FAIL (reasons for failure begin with '*' in final column)\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [length]:              length of target sequence (nt)\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [#fm]:                 number of different families detected in sequence\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [fam]:                 name of family the best-scoring model to this sequence belongs to\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [domain]:              name of domain the best-scoring model to this sequence belongs to\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [model]:               name of best-scoring model\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [strnd]:               strand ('plus' or 'minus') of best-scoring hit\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [#ht]:                 number of hits to best model on strand of best hit (no score threshold enforced)\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [tscore]:              summed bit scores of all hits between best model and this sequence (no score threshold enforced)\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [bscore]:              bit score of best-scoring hit between best model and this sequence (above threshold)\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [s/nt]:                summed bit scores of all hits divided by length of the sequence\n", $column_ct);
  $column_ct++;
  if($have_evalues) { 
    printf $FH ("# Column %2d [bevalue]:             E-value of best-scoring hit to this sequence\n", $column_ct);
    $column_ct++;
  }
  printf $FH ("# Column %2d [tcov]:                fraction of target sequence included in all (non-overlapping) hits to the best-scoring model\n", $column_ct);
  if(! $have_accurate_coverage) { print $FH $inaccurate_cov_str; }
  $column_ct++;
  printf $FH ("# Column %2d [bcov]:                fraction of target sequence included in single best-scoring hit\n", $column_ct);
  if(! $have_accurate_coverage) { print $FH $inaccurate_cov_str; }
  $column_ct++;
  printf $FH ("# Column %2d [bfrom]:               start position in the sequence of best-scoring hit\n", $column_ct);
  $column_ct++;
  printf $FH ("# Column %2d [bto]:                 stop position in the sequence of best-scoring hit\n", $column_ct);
  $column_ct++;
  if($have_model_coords) { 
    printf $FH ("# Column %2d [mfrom]:               start position in the model of best-scoring hit\n", $column_ct);
    $column_ct++;
    printf $FH ("# Column %2d [mto]:                 stop position in the model of best-scoring hit\n", $column_ct);
    $column_ct++;
  }
  if($round eq "1" || $round eq "final") { 
    if($round eq "final") { 
      printf $FH ("# Column %2d [scdiff]:              difference in score from classification stage between summed score of hits to best model and summed scores of hits to second best model\n", $column_ct);
    }
    elsif($round eq "1") { 
      printf $FH ("# Column %2d [scdiff]:              difference in score between summed scores of hits to best model and summed scores of hits to second best model\n", $column_ct);
    }
    $column_ct++;
    printf $FH ("# Column %2d [scd/nt]:              score difference per position: 'scdiff' value divided by total length of all hits to best model\n", $column_ct);
    $column_ct++;
    printf $FH ("# Column %2d [model]:               name of second best-scoring model\n", $column_ct);
    $column_ct++;
    printf $FH ("# Column %2d [tscore]:              summed bit scores of all hits between second-best model and this sequence (no score threshold enforced)\n", $column_ct);
    $column_ct++;
    if($have_evalues_r1) { 
      printf $FH ("# Column %2d [bevalue]:             E-value of best-scoring hit between second-best model and this sequence\n", $column_ct);
      $column_ct++;
    }
  }
  printf $FH ("# Column %2d [unexpected_features]: unexpected/unusual features of sequence (see below)\n", $column_ct);
  $column_ct++;
  
  output_unexpected_features_explanation($FH, $ufeature_AR, $opt_HHR);

  return;
}

#################################################################
# Subroutine : output_unexpected_features_explanation()
# Incept:      EPN, Tue Mar 28 15:29:10 2017
#
# Purpose:     Output explanation of possible unexpected features.
#              
# Arguments: 
#   $FH:       file handle to output to
#   $opt_HHR:  reference to options 2D hash
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_unexpected_features_explanation { 
  my $nargs_expected = 3;
  my $sub_name = "output_unexpected_features_explanation";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $ufeature_AR, $opt_HHR) = (@_);

  my $u_ctr               = 1;     # counter of unexpected features
  my $ufeature            = undef; # an unusual feature
  my @explanation_lines_A = (); # explanation of an unusual feature

  print $FH ("# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - \n");
  print $FH ("#\n");
  print $FH ("# Explanation of possible values in unexpected_features column:\n");
  print $FH ("#\n");
  print $FH ("# This column will include a '-' if none of the features listed below are detected.\n");
  print $FH ("# Or it will contain one or more of the following types of messages. There are no\n");
  print $FH ("# whitespaces in this field, to make parsing easier.\n");
  print $FH ("#\n");
  print $FH ("# Values that begin with \"*\" automatically cause a sequence to FAIL.\n");
  print $FH ("# Values that do not begin with \"*\" do not cause a sequence to FAIL.\n");
  print $FH ("#\n");

  my $u_width = 0;
  foreach $ufeature (@{$ufeature_AR}) { 
    if($ufeature !~ m/CLEAN/) { 
      if(length($ufeature) > $u_width) {
        $u_width = length($ufeature);
      }
    }
  }
  foreach $ufeature (@{$ufeature_AR}) { 
    if($ufeature !~ m/CLEAN/) { 
      determine_unexpected_feature_explanation($ufeature, \@explanation_lines_A, $opt_HHR);
      for(my $i = 0; $i < scalar(@explanation_lines_A); $i++) { 
        printf $FH ("# %3s  %-*s  %s\n", 
                    ($i == 0) ? sprintf("%2d.", $u_ctr) : "",
                    $u_width, 
                    ($i == 0) ? $ufeature               : "", 
                    $explanation_lines_A[$i]);
      }
      if(scalar(@explanation_lines_A) > 0) { 
        #printf $FH ("#\n");
        $u_ctr++;
      }
    }
  }
  printf $FH("#\n");
}

#################################################################
# Subroutine : determine_unexpected_feature_explanation()
# Incept:      EPN, Fri May 19 09:32:37 2017
#
# Purpose:     Return an explanation of an unexpected feature.
#              
# Arguments: 
#   $ufeature: feature to return explanation of
#   $exp_AR:   ref to array to fill with >= 1 lines of explanation
#   $opt_HHR:  reference to options 2D hash
#
# Returns:     Nothing. Fills @{$exp_AR}.
# 
# Dies:        If $ufeature is not an expected unexpected feature.
#
################################################################# 
sub determine_unexpected_feature_explanation { 
  my $nargs_expected = 3;
  my $sub_name = "determine_unexpected_feature_explanation()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($ufeature, $exp_AR, $opt_HHR) = (@_);

  # max width of a line is 55 characters
  @{$exp_AR} = ();
  if($ufeature =~ m/NoHits/) { 
    push(@{$exp_AR}, "No primary hits to any models above the minimum primary score");
    push(@{$exp_AR}, sprintf("threshold of %d bits (--minpsc) were found.", opt_Get("--minpsc", $opt_HHR)));
  }
  elsif($ufeature =~ m/UnacceptableModel/ && (opt_IsUsed("--inaccept", $opt_HHR))) { 
    push(@{$exp_AR}, "Best hit is to a model that is 'unacceptable' as defined in");
    push(@{$exp_AR}, "input file " . opt_Get("--inaccept", $opt_HHR) . " (--inaccept).");
  }
  elsif($ufeature =~ m/MultipleFamilies/) { 
    push(@{$exp_AR}, "One or more primary hits to two or more \"families\" (e.g. SSU");
    push(@{$exp_AR}, "or LSU) exists for the same sequence.");
  }
  elsif($ufeature =~ m/BothStrands/) { 
    push(@{$exp_AR}, "One or more primary hits above the minimum primary score threshold");
    push(@{$exp_AR}, sprintf("of %d bits (--minpsc) were found on each strand.", opt_Get("--minpsc", $opt_HHR)));
  }
  elsif($ufeature =~ m/DuplicateRegion/) { 
    push(@{$exp_AR}, "At least two hits (primary or secondary) on the same strand overlap");
    push(@{$exp_AR}, "in model coordinates by " . opt_Get("--maxoverlap", $opt_HHR) . " (--maxoverlap) positions or more");
  }
  elsif($ufeature =~ m/InconsistentHits/) { 
    push(@{$exp_AR}, "Not all hits (primary or secondary) are in the same order in the");
    push(@{$exp_AR}, "sequence and in the model.");
  }
  elsif($ufeature =~ m/QuestionableModel/ && (opt_IsUsed("--inaccept", $opt_HHR))) { 
    push(@{$exp_AR}, "Best hit is to a model that is 'questionable' as defined in");
    push(@{$exp_AR}, "input file " . opt_Get("--inaccept", $opt_HHR) . " (--inaccept).");
  }
  elsif($ufeature =~ m/MinusStrand/) { 
    push(@{$exp_AR}, "Best hit is on the minus strand.");
  }
  elsif($ufeature =~ m/LowScore/) { 
    push(@{$exp_AR}, "The bits per nucleotide (total bit score divided by total length");
    push(@{$exp_AR}, "of sequence) is below threshold of " . opt_Get("--lowppossc", $opt_HHR) . " (--lowppossc).");
  }
  elsif($ufeature =~ m/LowCoverage/) { 
    push(@{$exp_AR}, "The total coverage of all hits (primary and secondary) to the best");
    push(@{$exp_AR}, "model (summed length of all hits divided by total length of sequence)");
    if(opt_IsUsed("--tshortlen", $opt_HHR)) { 
      push(@{$exp_AR}, "is either (a) below threshold of " . opt_Get("--tcov", $opt_HHR) . " (--tcov) and sequence is");
      push(@{$exp_AR}, "more than " . opt_Get("--tshortlen", $opt_HHR) . " nucleotides (--tshortlen)");
      push(@{$exp_AR}, "OR (b) below threshold of " . opt_Get("--tshortcov", $opt_HHR) . " (--tshortcov) and sequence is");
      push(@{$exp_AR}, "less than or equal to " . opt_Get("--tshortlen", $opt_HHR) . " nucleotides (--tshortlen).");
    }
    else { 
      push(@{$exp_AR}, "is below threshold of " . opt_Get("--tcov", $opt_HHR) . " (--tcov).");
    }
  }
  elsif($ufeature =~ m/VeryLowScoreDifference/) { # important to put this before LowScoreDifference in elsif
    if(opt_Get("--absdiff")) { 
      push(@{$exp_AR}, "The difference between the top two " . (opt_Get("--samedomain", $opt_HHR) ? "models" : "domains") . " is below the \'very low\'");
      push(@{$exp_AR}, "threshold of " . opt_Get("--vlowadiff", $opt_HHR) . " (--vlowadiff) bits.");
    }
    else { 
      push(@{$exp_AR}, "The difference between the top two " . (opt_Get("--samedomain", $opt_HHR) ? "models" : "domains") . " is below the \'very low\'");
      push(@{$exp_AR}, "threshold of " . opt_Get("--vlowpdiff", $opt_HHR) . " (--vlowpdiff) bits per position (total bit score");
      push(@{$exp_AR}, "divided by summed length of all hits).");
    }
  }
  elsif($ufeature =~ m/LowScoreDifference/) { 
    if(opt_Get("--absdiff", $opt_HHR)) { 
      push(@{$exp_AR}, "The difference between the top two " . (opt_Get("--samedomain", $opt_HHR) ? "models" : "domains") . " is below the \'low\'");
      push(@{$exp_AR}, "threshold of " . opt_Get("--lowadiff", $opt_HHR) . " (--lowadiff) bits.");
    }
    else { 
      push(@{$exp_AR}, "The difference between the top two " . (opt_Get("--samedomain", $opt_HHR) ? "models" : "domains") . " is below the \'low\'");
      push(@{$exp_AR}, "threshold of " . opt_Get("--lowpdiff", $opt_HHR) . " (--lowpdiff) bits per position (total bit score");
      push(@{$exp_AR}, "divided by summed length of all hits).");
    }
  }
  elsif($ufeature =~ m/MultipleHits/) { 
    push(@{$exp_AR}, "There is more than one hit to the best scoring model on the same strand.");
  }
  elsif($ufeature =~ m/TooShort/) { 
    if(opt_Get("--shortfail", $opt_HHR)) { 
      push(@{$exp_AR}, "Sequence is below minimum length threshold of " . opt_Get("--shortfail", $opt_HHR) . " (--shortfail).");
    }
  }
  elsif($ufeature =~ m/TooLong/) { 
    if(opt_Get("--longfail", $opt_HHR)) { 
      push(@{$exp_AR}, "Sequence is above maximum length threshold of " . opt_Get("--longfail", $opt_HHR) . " (--longfail).");
    }
  }
  return;
}

#################################################################
# Subroutine : debug_print()
# Incept:      EPN, Thu Jan  5 14:11:21 2017
#
# Purpose:     Output information for current sequence in either
#              long or short mode. Short mode if $do_short is true.
#              
# Arguments: 
#   $FH:            file handle to output to
#   $title:         title to print before any values
#   %model_HR:  'one' model
#   %score_HR:  'one' bit score
#   %evalue_HR: 'one' E-value
#   %start_HR:  'one' start position
#   %stop_HR:   'one' stop position
#   %strand_HR: 'one' strand 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub debug_print { 
  my $nargs_expected = 8;
  my $sub_name = "debug_print";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $title, $model_HR, $score_HR, $evalue_HR, $start_HR, $stop_HR, $strand_HR) = @_;

  printf $FH ("************************************************************\n");
  printf $FH ("in $sub_name, title: $title\n");

  foreach my $family (sort keys %{$model_HR}) { 
    printf("family: $family\n");
    printf("\tmodel:  $model_HR->{$family}\n");
    printf("\tscore:  $score_HR->{$family}\n");
    printf("\tevalue: $evalue_HR->{$family}\n");
    printf("\tstart:  $start_HR->{$family}\n");
    printf("\tstop:   $stop_HR->{$family}\n");
    printf("\tstrand: $strand_HR->{$family}\n");
    printf("--------------------------------\n");
  }

  return;
}


#################################################################
# Subroutine: center_string()
# Incept:     EPN, Thu Mar  2 10:01:39 2017
#
# Purpose:    Given a string and width, return the string with
#             prepended spaces (" ") so that the returned string
#             will be roughly centered in a window of length 
#             $width.
#
# Arguments:
#   $width:  width to center in
#   $str:    string to center
#
# Returns:  $str prepended with spaces so that it centers
# 
# Dies:     Never
#
#################################################################
sub center_string { 
  my $sub_name = "center_string";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($width, $str) = @_;

  my $nspaces_to_prepend = int(($width - length($str)) / 2);
  if($nspaces_to_prepend < 0) { $nspaces_to_prepend = 0; }

  return ribo_GetMonoCharacterString($nspaces_to_prepend, " ") . $str; 
}

#################################################################
# Subroutine: determine_if_coverage_is_accurate()
# Incept:     EPN, Thu Apr 20 10:30:28 2017
#
# Purpose:    Based on the command line options and what round we are in,
#             determine if the coverage values are accurate. With the
#             fast mode, coverage values are not accurate, but with
#             some options like --1hmm and --1slow, they are.
#
# Arguments:
#   $round:    what round of searching we're in, '1', '2', or 'final'
#   $opt_HHR:  reference to 2D hash of cmdline options
#
# Returns:  '1' if coverage is accurate, else '0'
# 
# Dies:     Never
#
#################################################################
sub determine_if_coverage_is_accurate { 
  my $sub_name = "determine_if_coverage_is_accurate()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($round, $opt_HHR) = (@_);

  my $have_accurate_coverage = 0;
  if($round eq "1") { 
    if(opt_Get("--1hmm",  $opt_HHR)) { $have_accurate_coverage = 1; }
    if(opt_Get("--1slow", $opt_HHR)) { $have_accurate_coverage = 1; }
  }
  elsif($round eq "2" || $round eq "final") { 
    $have_accurate_coverage = 1; # always true for round 2
  }
  else { 
    die "ERROR in $sub_name, invalid round value of $round"; 
  }

  return $have_accurate_coverage;
}

#################################################################
# Subroutine: determine_if_we_have_model_coords()
# Incept:     EPN, Tue May  2 09:40:34 2017
#
# Purpose:    Based on the command line options and what round
#             we are in, determine if the search output includes 
#             model coordinates or not.
#
# Arguments:
#   $round:   what round of searching we're in, '1', '2', or 'final'
#   $opt_HHR: reference to 2D hash of cmdline options
#
# Returns:  '1' if we have model coords, else '0'
# 
# Dies:     Never
#
#################################################################
sub determine_if_we_have_model_coords { 
  my $sub_name = "determine_if_we_have_model_coords()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($round, $opt_HHR) = (@_);

  my $have_model_coords = 0;
  if($round eq "1") { 
    if(opt_Get("--1hmm",  $opt_HHR)) { $have_model_coords = 1; }
    if(opt_Get("--1slow", $opt_HHR)) { $have_model_coords = 1; }
  }
  elsif($round eq "2" || $round eq "final") { 
    $have_model_coords = 1; # always true for round 2
  }
  else { 
    die "ERROR in $sub_name, invalid round value of $round"; 
  }

  return $have_model_coords;
}

#################################################################
# Subroutine: determine_if_we_evalues()
# Incept:     EPN, Fri May  5 10:51:03 2017
#
# Purpose:    Based on the command line options and what round
#             we are in, determine the search output includes 
#             E-values or not.
#
# Arguments:
#   $round:   what round of searching we're in, '1', '2', or 'final'
#   $opt_HHR: reference to 2D hash of cmdline options
#
# Returns:  '1' if we have model coords, else '0'
# 
# Dies:     Never
#
#################################################################
sub determine_if_we_have_evalues { 
  my $sub_name = "determine_if_we_have_evalues()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($round, $opt_HHR) = (@_);

  my $have_evalues = 0;
  if($round eq "1") { 
    if(opt_Get("--1hmm",  $opt_HHR)) { $have_evalues = 1; }
    if(opt_Get("--1slow", $opt_HHR)) { $have_evalues = 1; }
  }
  elsif($round eq "2" || $round eq "final") { 
    $have_evalues = 1; # always true for round 2
  }
  else { 
    die "ERROR in $sub_name, invalid round value of $round"; 
  }

  return $have_evalues;
}

#################################################################
# Subroutine: get_overlap()
# Incept:     EPN, Mon Apr 24 15:47:13 2017
#
# Purpose:    Determine if there is overlap between two regions
#             defined by strings of the format <d1>-<d2> where
#             <d1> is the beginning of the region and <d2> is the
#             end. If strand is "+" then <d1> <= <d2> and if strand
#             is "-" then <d1> >= <d2>.
#
# Arguments:
#   $regstr1:  string 1 defining region 1
#   $regstr2:  string 2 defining region 2
#
# Returns:  Two values:
#           $noverlap:    Number of nucleotides of overlap between hit1 and hit2, 
#                         0 if none
#           $overlap_reg: region of overlap, "" if none
# 
# Dies:     If regions are not formatted correctly, or
#           regions are different strands.
#
#################################################################
sub get_overlap { 
  my $sub_name = "get_overlap()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($regstr1, $regstr2) = (@_);

  my ($start1, $stop1, $strand1) = decompose_region_str($regstr1);
  my ($start2, $stop2, $strand2) = decompose_region_str($regstr2);

  if($strand1 ne $strand2) { 
    die "ERROR in $sub_name, different strands for regions $regstr1 and $regstr2";
  }

  if($strand1 eq "-") { 
    my $tmp = $start1; 
    $start1 = $stop1;
    $stop1  = $tmp;
    $tmp    = $start2;
    $start2 = $stop2;
    $stop2  = $tmp;
  }

  return get_overlap_helper($start1, $stop1, $start2, $stop2);
}

#################################################################
# Subroutine: get_overlap_helper()
# Incept:     EPN, Mon Mar 14 13:47:57 2016 [dnaorg_scripts:dnaorg.pm:getOverlap()]
#
# Purpose:    Calculate number of nucleotides of overlap between
#             two regions.
#
# Args:
#  $start1: start position of hit 1 (must be <= $end1)
#  $end1:   end   position of hit 1 (must be >= $end1)
#  $start2: start position of hit 2 (must be <= $end2)
#  $end2:   end   position of hit 2 (must be >= $end2)
#
# Returns:  Two values:
#           $noverlap:    Number of nucleotides of overlap between hit1 and hit2, 
#                         0 if none
#           $overlap_reg: region of overlap, "" if none
#
# Dies:     if $end1 < $start1 or $end2 < $start2.
sub get_overlap_helper {
  my $sub_name = "get_overlap_helper";
  my $nargs_exp = 4;
  if(scalar(@_) != 4) { die "ERROR $sub_name entered with wrong number of input args"; }

  my ($start1, $end1, $start2, $end2) = @_; 

  # printf("in $sub_name $start1..$end1 $start2..$end2\n");

  if($start1 > $end1) { die "ERROR in $sub_name start1 > end1 ($start1 > $end1)"; }
  if($start2 > $end2) { die "ERROR in $sub_name start2 > end2 ($start2 > $end2)"; }

  # Given: $start1 <= $end1 and $start2 <= $end2.
  
  # Swap if nec so that $start1 <= $start2.
  if($start1 > $start2) { 
    my $tmp;
    $tmp   = $start1; $start1 = $start2; $start2 = $tmp;
    $tmp   =   $end1;   $end1 =   $end2;   $end2 = $tmp;
  }
  
  # 3 possible cases:
  # Case 1. $start1 <=   $end1 <  $start2 <=   $end2  Overlap is 0
  # Case 2. $start1 <= $start2 <=   $end1 <    $end2  
  # Case 3. $start1 <= $start2 <=   $end2 <=   $end1
  if($end1 < $start2) { return (0, ""); }                                           # case 1
  if($end1 <   $end2) { return (($end1 - $start2 + 1), ($start2 . "-" . $end1)); }  # case 2
  if($end2 <=  $end1) { return (($end2 - $start2 + 1), ($start2 . "-" . $end2)); }  # case 3
  die "ERROR in $sub_name, unforeseen case in $start1..$end1 and $start2..$end2";

  return; # NOT REACHED
}

#################################################################
# Subroutine: sort_hit_array()
# Incept:     EPN, Tue Apr 25 06:23:42 2017
#
# Purpose:    Sort an array of regions of hits.
#
# Args:
#  $tosort_AR:   ref of array to sort
#  $order_AR:    ref to array of original indices corresponding to @{$tosort_AR}
#  $allow_dups:  '1' to allow duplicates in $tosort_AR, '0' to not and die if
#                they're found
#
# Returns:  string indicating the order of the elements in $tosort_AR in the sorted
#           array.
#
# Dies:     - if some of the regions in @{$tosort_AR} are on different strands
#             or are in the wrong format
#           - if there are duplicate values in $tosort_AR and $allow_dups is 0
sub sort_hit_array { 
  my $sub_name = "sort_hit_array";
  my $nargs_exp = 3;
  if(scalar(@_) != 3) { die "ERROR $sub_name entered with wrong number of input args"; }

  my ($tosort_AR, $order_AR, $allow_dups) = @_;

  my ($i, $j); # counters

  my $nel = scalar(@{$tosort_AR});

  if($nel == 1) { die "ERROR in $sub_name, nel is 1 (should be > 1)"; }

  # make sure all elements are on the same strand
  my(undef, undef, $strand) = decompose_region_str($tosort_AR->[0]);
  for($i = 1; $i < $nel; $i++) { 
    my(undef, undef, $cur_strand) = decompose_region_str($tosort_AR->[$i]);
    if($strand ne $cur_strand) { 
      die "ERROR in $sub_name, not all regions are on same strand, region 1: $tosort_AR->[0] $strand, region " . $i+1 . ": $tosort_AR->[$i] $cur_strand";
    }
  }

  # make a temporary hash and sort it by value
  my %hash = ();
  for($i = 0; $i < $nel; $i++) { 
    $hash{($i+1)} = $tosort_AR->[$i];
  }
  @{$order_AR} = (sort {$hash{$a} <=> $hash{$b}} (keys %hash));

  # now that we have the sorted order, we can easily check for dups
  if(! $allow_dups) { 
    for($i = 1; $i < $nel; $i++) { 
      if($hash{$order_AR->[($i-1)]} eq $hash{$order_AR->[$i]}) { 
        die "ERROR in $sub_name, duplicate values exist in the array: " . $hash{$order_AR->[$i]} . " appears twice"; 
      }
    }
  }

  # reverse array if strand is "-"
  if($strand eq "-") { 
    @{$order_AR} = reverse @{$order_AR};
  }

  # construct return string
  my $ret_str = $order_AR->[0];
  for($i = 1; $i < $nel; $i++) { 
    $ret_str .= "," . $order_AR->[$i];
  }

  return $ret_str;
}

#################################################################
# Subroutine: decompose_region_str()
# Incept:     EPN, Wed Apr 26 06:09:45 2017
#
# Purpose:    Given a 'region' string in the format <d1>.<d2>, 
#             decompose it and return <d1>, <d2> and <strand>.
#
# Args:
#  $regstr:    region string in format <d1>.<d2>
#
# Returns:  Three values:
#           <d1>: beginning of region
#           <d2>: end of region
#           <strand>: "+" if <d1> <= <d2>, else "-"
#
# Dies:     if $regstr is not in correct format 
sub decompose_region_str { 
  my $sub_name = "decompose_region_str";
  my $nargs_exp = 1;
  if(scalar(@_) != 1) { die "ERROR $sub_name entered with wrong number of input args"; }

  my ($regstr) = @_;

  my ($d1, $d2, $strand); 
  if($regstr =~ /(\d+)\.(\d+)/) { ($d1, $d2) = ($1, $2); }
  else                          { die "ERROR in $sub_name, region string $regstr not parseable"; }

  $strand = ($d1 <= $d2) ? "+" : "-";

  return($d1, $d2, $strand);
}


#################################################################
# Subroutine : get_dir_path()
# Incept:      EPN, Thu May  4 09:39:06 2017
#              EPN, Mon Mar 15 10:17:11 2010 [ssu.pm:ReturnDirPath()]
#
# Purpose:     Given a file name return the directory path, with the final '/'
#              For example: "foodir/foodir2/foo.stk" becomes "foodir/foodir2/".
#
# Arguments: 
#   $orig_file: name of original file
# 
# Returns:     The string $orig_file with actual file name removed
#
################################################################# 
sub get_dir_path {
  my $narg_expected = 1;
  my $sub_name = "get_dir_path()";
  if(scalar(@_) != $narg_expected) { printf STDERR ("ERROR, in $sub_name, entered with %d != %d input arguments.\n", scalar(@_), $narg_expected); exit(1); } 
  my $orig_file = $_[0];
  
  $orig_file =~ s/[^\/]+$//; # remove final string of non '/' characters
  
  if($orig_file eq "") { return "./";       }
  else                 { return $orig_file; }
}

#################################################################
# Subroutine : determine_cmsearch_opts()
# Incept:      EPN, Thu May  4 13:14:10 2017
#
# Purpose:     Determine the CM search options given an algorithm
#              type of either "fast", "hmmonly", or "slow" and 
#              a reference to the command line options.
#
# Arguments: 
#   $alg:      algorithm, either "fast", "hmmonly" or "slow"
#   $opt_HHR:  reference to 2D hash of cmdline options
# 
# Returns:     String of options to use for cmsearch.
#
# Dies:        If $alg string is invalid.
# 
################################################################# 
sub determine_cmsearch_opts { 
  my $nargs_expected = 2;
  my $sub_name = "determine_cmsearch_opts()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($alg, $opt_HHR) = @_;

  my $alg_opts = undef;
  if($alg eq "fast") { 
    $alg_opts .= " --F1 0.02 --doF1b --F1b 0.02 --F2 0.001 --F3 0.00001 --trmF3 --nohmmonly --notrunc --noali ";
  }
  elsif($alg eq "slow") { 
    if(opt_Get("--mid", $opt_HHR)) { 
      $alg_opts .= " --mid "; 
    }
    elsif(opt_Get("--max", $opt_HHR)) { 
      $alg_opts .= " --max "; 
      if(opt_IsUsed("--smxsize", $opt_HHR)) { 
        $alg_opts .= " --smxsize " . opt_Get("--smxsize", $opt_HHR) . " ";
      }
    }
    else { # default for slow, --mid nor --max used (use cmsearch --rfam)
      $alg_opts .= " --rfam "; 
    }
    if(opt_Get("--noali", $opt_HHR)) { 
      $alg_opts .= " --noali ";
    }
  }
  elsif($alg eq "hmmonly") { 
    $alg_opts .= " --hmmonly ";
    if(opt_Get("--noali", $opt_HHR)) { 
      $alg_opts .= " --noali ";
    }
  }
  else { 
    die "ERROR in $sub_name, algorithm is invalid: $alg\n";
  }

  return $alg_opts;
}

#################################################################
# Subroutine : parse_round1_long_file()
# Incept:      EPN, Thu May  4 13:54:36 2017
#
# Purpose:     Parse a 'long' output file created by this script
#              and fill %seqsub_HA with names of sequences to 
#              that are best-matches to each model.
#              
# Arguments: 
#   $long_file:    'long' format file to parse
#   $seqsub_HAR:   ref to hash of arrays, key is model name, value is array of 
#                  sequences that match best to the model
#
# Returns:     Nothing. Updates %{$seqsub_HAR}.
# 
# Dies:        If $long_file is in incorrect format.
#
################################################################# 
sub parse_round1_long_file {
  my $nargs_expected = 2;
  my $sub_name = "parse_round1_long_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($long_file, $seqsub_HAR) = @_;

  my @el_A    = (); # array of elements in a line
  my $model   = undef; # a model
  my $seqname = undef; # a sequence name

  open(IN, $long_file) || die "ERROR in $sub_name, unable to open $long_file for reading";

  while(my $line = <IN>) { 
    if($line !~ m/^\#/) { # skip comment lines
      @el_A = split(/\s+/, $line);
      ($seqname, $model) = ($el_A[1], $el_A[7]);
      if($model ne "-") { 
        if(! exists $seqsub_HAR->{$model}) {
          die "ERROR in $sub_name, unexpected model value: $model\nline: $line\n";
        }
        push(@{$seqsub_HAR->{$model}}, $seqname);
      }
    }
  }
  close(IN);
  
  return;
}

#################################################################
# Subroutine : write_array_to_file()
# Incept:      EPN, Thu May  4 14:11:03 2017
#
# Purpose:     Create a file with each element in an array on 
#              a different line.
#              
# Arguments: 
#   $AR:    reference to array 
#   $file:  name of file to create
#
# Returns:  Nothing.
# 
# Dies:     If $AR is empty.
#
################################################################# 
sub write_array_to_file {
  my $nargs_expected = 2;
  my $sub_name = "write_array_to_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($AR, $file) = @_;

  if((! defined $AR) || (scalar(@{$AR}) == 0)) { 
    die "ERROR in $sub_name, array is empty or not defined";
  }

  open(OUT, ">", $file) || die "ERROR in $sub_name, unable to open file $file for writing";

  foreach my $el (@{$AR}) { 
    print OUT $el . "\n"; 
  }
  close(OUT);

  return;
}

#################################################################
# Subroutine : output_combined_short_or_long_file()
# Incept:      EPN, Mon May  8 14:09:49 2017
#
# Purpose:     Combine the round 1 and round 2 long output files 
#              to create the final file.
#              
# Arguments: 
#   $out_FH:         file handle to print to
#   $r1_in_FH:       file handle of open round 1 long file
#   $r2_in_FH:       file handle of open round 2 long file
#   $do_short:       '1' if we're combining short files, '0' if 
#                    we're combining long files
#   $stats_HHR:      ref to 2D hash of stats:
#                    1D key: model name, "*all*" or "*none*"
#                    2D key: "nseq", "npass", "summed_tcov", "nnt_tot"
#                    filled here, can and should be undef if $do_short is '1'
#   $ufeature_ct_HR: ref to hash of unexpected feature counts 
#                    filled here, can and should be undef if $do_short is '1'
#   $width_HR:       hash, key is "model" or "target", value 
#                    is width (maximum length) of any target/model
#   $opt_HHR:        reference to 2D hash of cmdline options
#
# Returns:  Nothing.
# 
# Dies:     If there are not the same sequences in 
#           the same order in the round 1 and round 2 files.
#
################################################################# 
sub output_combined_short_or_long_file { 
  my $nargs_expected = 8;
  my $sub_name = "output_combined_short_or_long_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($out_FH, $r1_in_FH, $r2_in_FH, $do_short, $stats_HHR, $ufeature_ct_HR, $width_HR, $opt_HHR) = @_;

  my $r1_line;             # line from round 1 file
  my $r2_line;             # line from round 2 file 
  my $r1_lidx;             # line index in round 1 file
  my $r2_lidx;             # line index in round 2 file
  my $keep_going = 1;      # flag to keep reading the input files, set to '0' to stop
  my @r1_el_A = ();        # array of space-delimited tokens in a round 1 line
  my @r2_el_A = ();        # array of space-delimited tokens in a round 1 line
  my @r1_ufeatures_A = (); # array of unexpected features in round 1 line
  my $ufeature = undef;    # a single unexpected feature
  my $did_edit_r2_line;    # flag, set to 1 if we edited the r2 line, 0 if not
  my $did_make_fail;       # flag, set to 1 if we edited the r2 line and it should become FAIL, 0 if not
  my $have_evalues_r1      = determine_if_we_have_evalues(1, $opt_HHR);
  my $have_evalues_r2      = determine_if_we_have_evalues(2, $opt_HHR);
  my $have_model_coords_r1 = determine_if_we_have_model_coords(1, $opt_HHR);
  my $have_model_coords_r2 = determine_if_we_have_model_coords(2, $opt_HHR);
  my $expected_ncols_r1 = 0; # number of columns we expect in round 1 file
  my $expected_ncols_r2 = 0; # number of columns we expect in round 2 file
  my $ncols_r1          = 0; # actual number of columns in round 1 line
  my $ncols_r2          = 0; # actual number of columns in round 2 line
  my $r2_to_add         = undef; # string to add to r2 line, the 'second-best model' columns from r1 line
  my $r2_final_column   = undef; # final column of r2 line
  # variables for a single target related to updating %{$stats_HHR}
  my $class  = undef; # classification
  my $pf     = undef; # 'PASS' or 'FAIL'
  my $nnt    = undef; # size of current target
  my $fam    = undef; # family of current target
  my $domain = undef; # domain of current target
  my $model  = undef; # model of current target
  my $tcov   = undef; # total coverage of current target
  if(defined $stats_HHR) { 
    initialize_class_stats(\%{$stats_HHR->{"*input*"}});
    initialize_class_stats(\%{$stats_HHR->{"*none*"}});
    initialize_class_stats(\%{$stats_HHR->{"*all*"}});
  }

  if($do_short) { 
    $expected_ncols_r1 = 6;
    $expected_ncols_r2 = 6;
    if(defined $stats_HHR) { 
      die "ERROR in $sub_name, do_short is true and stats_HHR is defined";
    }
  }
  else { 
    $expected_ncols_r1 = determine_number_of_columns_in_long_output_file("1",     $opt_HHR);
    $expected_ncols_r2 = determine_number_of_columns_in_long_output_file("2",     $opt_HHR);
  }

  # we know that the first few lines of both files are comment lines, that begin with "#", chew them up
  $r1_line = <$r1_in_FH>;
  $r1_lidx++;
  while((defined $r1_line) && ($r1_line =~ m/^\#/)) { 
    $r1_line = <$r1_in_FH>; 
    $r1_lidx++;
  }

  $r2_line = <$r2_in_FH>;
  $r2_lidx++;
  while((defined $r2_line) && ($r2_line =~ m/^\#/)) { 
    $r2_line = <$r2_in_FH>; 
    $r2_lidx++;
  }

  while($keep_going) { 
    my $have_r1_line = ((defined $r1_line) && ($r1_line !~ m/^\#/)) ? 1 : 0;
    my $have_r2_line = ((defined $r2_line) && ($r2_line !~ m/^\#/)) ? 1 : 0;
    if($have_r1_line && $have_r2_line) { 
      chomp $r1_line;
      chomp $r2_line;
      # example short lines:
      #idx  target                                         classification         strnd   p/f  unexpected_features
      #---  ---------------------------------------------  ---------------------  -----  ----  -------------------
      #15   00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  PASS  opposite_strand
      #16   01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus   PASS  -
      #
      # example long lines:
      # (round 1 without e-values)
      #                                                                                                                                    best-scoring model                                                        different domain's best-scoring model  
      #                                                                                               ---------------------------------------------------------------------------------------------                  -------------------------------------  
      #idx  target                                          p/f  length  #fm  fam  domain             model                          strnd  #ht  tscore  bscore  b/nt   tcov   bcov   bfrom     bto  scdiff  scd/nt  model                          tscore  unexpected_features
      #---  ---------------------------------------------  ----  ------  ---  ---  -----------------  -----------------------------  -----  ---  ------  ------  ----  -----  -----  ------  ------  ------  ------  -----------------------------  ------  -------------------
      #15    00229::Oxytricha_granulifera.::AF164122        PASS     600    1  SSU  Eukarya            SSU_rRNA_eukarya               minus    1   611.2   611.2  1.02  1.000  1.000     600       1   378.6   0.631  SSU_rRNA_microsporidia          232.6  opposite_strand
      #16    01710::Oryza_sativa.::X00755                   PASS    2046    1  SSU  Eukarya            SSU_rRNA_eukarya               plus     1  2076.7  2076.7  1.02  1.000  1.000       1    2046  1253.1   0.612  SSU_rRNA_microsporidia          823.6  -
      #
      # (round 2 with e-values)
      #                                                                                                                                                best-scoring model                                                                    
      #                                                                                               ---------------------------------------------------------------------------------------------------------------------                  
      #idx  target                                          p/f  length  #fm  fam  domain             model                          strnd  #ht  tscore  bscore  b/nt   bevalue   tcov   bcov   bfrom     bto  mfrom    mto  unexpected_features
      #---  ---------------------------------------------  ----  ------  ---  ---  -----------------  -----------------------------  -----  ---  ------  ------  ----  --------  -----  -----  ------  ------  -----  -----  -------------------
      #15    00229::Oxytricha_granulifera.::AF164122        PASS     600    1  SSU  Eukarya            SSU_rRNA_eukarya               minus    1   611.2   611.2  1.02  8.8e-187  0.915  0.915     549       1    720   1266 opposite_strand
      #16    01710::Oryza_sativa.::X00755                   PASS    2046    1  SSU  Eukarya            SSU_rRNA_eukarya               plus     1  2076.6  2076.6  1.01         0  0.885  0.885      75    1885      1   1850 -

      @r1_el_A = split(/\s+/, $r1_line);
      @r2_el_A = split(/\s+/, $r2_line);
      if($r1_el_A[1] ne $r2_el_A[1]) { 
        die "ERROR in $sub_name, read different sequence on line $r1_lidx of round 1 file (" . $r1_el_A[1] . ") and $r2_lidx of round 2 file (" . $r2_el_A[1] . ")\nr1 line: $r1_line\nr2 line: $r2_line\n"; 
      }
      $ncols_r1 = scalar(@r1_el_A);
      $ncols_r2 = scalar(@r2_el_A);
      if($ncols_r1 != $expected_ncols_r1) { 
        die "ERROR in $sub_name, read unexpected number of columns on line $r1_lidx of round 1 file (" . $ncols_r1 . " != " . $expected_ncols_r1 . ")";
      }
      if($ncols_r2 != $expected_ncols_r2) { 
        die "ERROR in $sub_name, read unexpected number of columns on line $r2_lidx of round 2 file (" . $ncols_r2 . " != " . $expected_ncols_r2 . ")";
      }

      # pick out the r1 columns: 'scdiff', 'scd/nt' 'model', 'tscore' and possibly 'evalue' to add to the $r2_line
      $r2_to_add = undef;
      if(! $do_short) { 
        # we want to add round 1 columns 'scdiff', 'scd/nt' 'model', 'tscore' and possibly 'evalue' 
        # to round 2 lines to get final lines
        if($have_evalues_r1) { 
          $r2_to_add = sprintf("  %6s  %6s  %-*s  %6s  %8s", 
                               $r1_el_A[($ncols_r1-6)],  # 'scdiff'
                               $r1_el_A[($ncols_r1-5)],  # 'scd/nt'
                               $width_HR->{"model"}, $r1_el_A[($ncols_r1-4)],  # 'model'
                               $r1_el_A[($ncols_r1-3)], # 'tscore'
                               $r1_el_A[($ncols_r1-2)]); # 'evalue'
        }
        else { 
          $r2_to_add = sprintf("  %6s  %6s  %-*s  %6s", 
                               $r1_el_A[($ncols_r1-5)], # 'scdiff'
                               $r1_el_A[($ncols_r1-4)], # 'scd/nt'
                               $width_HR->{"model"}, $r1_el_A[($ncols_r1-3)],  # 'model'
                               $r1_el_A[($ncols_r1-2)]); # 'tscore'
        }
        # now save the final column:
        $r2_final_column = $r2_el_A[($ncols_r2-1)];
        # remove final column 
        $r2_line =~ s/\s\s\S+$//; # remove final column
        # now stick in the $r2_to_add
        $r2_line .= $r2_to_add . "  " . $r2_final_column;
      }

      # look for the three types of unexpected error that we want from round 1 to add to round 2:
      # 1) low_score_difference_between_top_two...
      # 2) very_low_score_difference_between_top_two... 
      # 3) hits_to_more_than_one_family...
      # either one can have a "*" at the beginning of it, which we want to capture
      # we append these to the end of our current unexpected_features
      if($r1_el_A[($ncols_r1-1)] ne $r2_el_A[($ncols_r2-1)]) { 
        $did_edit_r2_line = 0;
        $did_make_fail    = 0;
        @r1_ufeatures_A = split(";", $r1_el_A[($ncols_r1-1)]); 
        foreach $ufeature (@r1_ufeatures_A) { 

          if(($ufeature =~ m/LowScoreDifference/) ||
             ($ufeature =~ m/MultipleFamilies/)) { 
            $did_edit_r2_line = 1;
            if($ufeature =~ m/^\*/) { 
              $did_make_fail = 1;
            }
            if($r2_el_A[($ncols_r2-1)] eq "-") { 
              $r2_el_A[($ncols_r2-1)] = $ufeature . ";";
            }
            else { 
              $r2_el_A[($ncols_r2-1)] .= $ufeature . ";";
            }
          }
        }
        if($did_edit_r2_line) { 
          if($did_make_fail) { 
            # sequence 'FAILs' now
            if($do_short) { # short file, change the PASS to FAIL
              $r2_el_A[4] = "FAIL";
              if($r2_line =~ /(^\d+\s+\S+\s+\S+\s+\S+\s+)PASS(\s+.+$)/) { 
                $r2_line = $1 . "FAIL" . $2;
              }
            }
            else { # long file, change the PASS to FAIL if it exists
              $r2_el_A[2] = "FAIL";
              if($r2_line =~ /(^\d+\s+\S+\s+)PASS(\s+.+$)/) { 
                $r2_line = $1 . "FAIL" . $2;
              }
            }
          }
          # now append round 1 error to final column of round 2 output:
          $r2_line =~ s/\s\s\S+$//; # remove final column
          $r2_line .= "  " . $r2_el_A[($ncols_r2-1)];
        }
      }

      # update %{$stats_HHR}
      if(defined $stats_HHR) { 
        # we know that $do_short if FALSE, so we're dealing with the long file
        ($pf, $nnt, $fam, $domain, $model, $tcov) = ($r2_el_A[2], $r2_el_A[3], $r2_el_A[5], $r2_el_A[6], $r2_el_A[7], $r2_el_A[14]);
        $class = $fam . "." . $domain;
        if($class eq "-.-") { $class = "*none*"; }
        if(! defined $stats_HHR->{$class}) { 
          initialize_class_stats(\%{$stats_HHR->{$class}})
        }
        update_class_stats(\%{$stats_HHR->{$class}},    $tcov, $nnt, ($pf eq "PASS") ? 1 : 0);
        update_class_stats(\%{$stats_HHR->{"*input*"}}, 1.0,   $nnt, 0);
        update_class_stats(\%{$stats_HHR->{"*all*"}},   $tcov, $nnt, ($pf eq "PASS") ? 1 : 0);
      }

      # update the ufeature counts hash if we have one
      if(defined $ufeature_ct_HR) { 
        update_one_ufeature_sequence($ufeature_ct_HR, $r2_el_A[($ncols_r2-1)]);
      }

      print $out_FH $r2_line . "\n";

      # get new lines
      $r1_line = <$r1_in_FH>; 
      $r2_line = <$r2_in_FH>; 
      $r1_lidx++;
      $r2_lidx++;
    }
    # check for some unexpected errors
    elsif(($have_r1_line) && (! $have_r2_line)) { 
      die "ERROR in $sub_name, ran out of sequences from round 1 output before round 2"; 
    }
    elsif((! $have_r1_line) && ($have_r2_line)) { 
      die "ERROR in $sub_name, ran out of sequences from round 2 output before round 1"; 
    }
    else { # don't have either line
      $keep_going = 0;
    }
  }
      
  return;
}

#################################################################
# Subroutine: update_class_stats
# Incept:     EPN, Tue May  9 09:35:07 2017
#
# Purpose:    Update a class_stats hash given the relevant info
#             for one sequence.
#
# Arguments:
#   $stats_HR: ref to 1D hash, keys: "nseq", "summed_tcov", "nnt_tot", "npass"
#   $tcov:     total fractional coverage for this sequence
#   $nnt:      number of nucleotides for this sequence
#   $pass:     '1' if sequence passes, else '0'
#
# Returns:  void
# 
# Dies:     Never
#
#################################################################
sub update_class_stats { 
  my $sub_name = "update_class_stats";
  my $nargs_expected = 4;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($stats_HR, $tcov, $nnt, $pass) = (@_);

  if($tcov eq "-") { $tcov = 0.; }

  $stats_HR->{"nseq"}++;
  $stats_HR->{"summed_tcov"} += $tcov;
  $stats_HR->{"nnt_tot"}     += $nnt;
  if($pass) { $stats_HR->{"npass"}++; }

  return;
}

#################################################################
# Subroutine: debug_print_class_stats
# Incept:     EPN, Wed May 10 12:10:03 2017
#
# Purpose:    Output all values in a class_stats hash.
#
# Arguments:
#   $stats_HR: ref to 1D hash, keys: "nseq", "summed_tcov", "nnt_tot", "npass"
#   $class:    name of class
#
# Returns:  void
# 
# Dies:     Never
#
#################################################################
sub debug_print_class_stats { 
  my $sub_name = "debug_print_class_stats";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($stats_HR, $class) = (@_);

  printf("debug_print_class_stats, class: $class\n");

  printf("nseq:        %d\n", $stats_HR->{"nseq"});
  printf("summed_tcov: %f\n", $stats_HR->{"summed_tcov"});
  printf("nnt_tot:     %d\n", $stats_HR->{"nnt_tot"});
  printf("npass:       %d\n", $stats_HR->{"npass"});
  printf("\n");

  return;
}

#################################################################
# Subroutine: initialize_class_stats
# Incept:     EPN, Tue May  9 10:51:08 2017
#
# Purpose:    Initialize a class_stats hash.
#
# Arguments:
#   $stats_HR: ref to 1D hash, keys: "nseq", "summed_tcov", "nnt_tot", "npass"
#
# Returns:  void
# 
# Dies:     Never
#
#################################################################
sub initialize_class_stats { 
  my $sub_name = "initialize_class_stats";
  my $nargs_expected = 1;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($stats_HR) = (@_);

  %{$stats_HR} = ();
  $stats_HR->{"nseq"}        = 0;
  $stats_HR->{"summed_tcov"} = 0.;
  $stats_HR->{"nnt_tot"}     = 0;
  $stats_HR->{"npass"}       = 0;

  return;
}

#################################################################
# Subroutine: initialize_ufeature_stats
# Incept:     EPN, Tue May  9 21:03:39 2017
#
# Purpose:    Initialize a ufeature array and counts hash.
#             Array elements, which will be keys in the 
#             counts hash, are unique messages/descriptions 
#             of each possible unexpected feature. Hash
#             values will be counts. 
#
# Arguments:
#   $ufeature_AR:    ref to array of all unexpected feature strings
#   $ufeature_ct_HR: ref to hash of counts
#   $opt_HHR:        reference to 2D hash of cmdline options
#
# Returns:  void
# 
# Dies:     Never
#
#################################################################
sub initialize_ufeature_stats { 
  my $sub_name = "initialize_ufeature_stats";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($ufeature_AR, $ufeature_ct_HR, $opt_HHR) = (@_);

  @{$ufeature_AR}    = ();
  %{$ufeature_ct_HR} = ();

  # first category is a special one, it will hold the counts of
  # sequences with 0 unexpected features
  push(@{$ufeature_AR}, "CLEAN");

  # next, we want the unexpected features that will cause failures 
  # those that always cause failures (regardless of cmdline options):
  push(@{$ufeature_AR}, "*NoHits");
  push(@{$ufeature_AR}, "*UnacceptableModel");
  push(@{$ufeature_AR}, "*MultipleFamilies");
  push(@{$ufeature_AR}, "*BothStrands");
  push(@{$ufeature_AR}, "*DuplicateRegion");
  push(@{$ufeature_AR}, "*InconsistentHits");

  # those that can cause failure, if they do so:
  if(opt_Get("--questfail", $opt_HHR)) { push(@{$ufeature_AR}, "*QuestionableModel"); }
  if(opt_Get("--minusfail", $opt_HHR)) { push(@{$ufeature_AR}, "*MinusStrand"); }
  if(opt_Get("--scfail",    $opt_HHR)) { push(@{$ufeature_AR}, "*LowScore"); }
  if(opt_Get("--covfail",   $opt_HHR)) { push(@{$ufeature_AR}, "*LowCoverage"); }
  if(opt_Get("--difffail",  $opt_HHR)) { push(@{$ufeature_AR}, "*LowScoreDifference"); }
  if(opt_Get("--difffail",  $opt_HHR)) { push(@{$ufeature_AR}, "*VeryLowScoreDifference"); }
  if(opt_Get("--multfail",  $opt_HHR)) { push(@{$ufeature_AR}, "*MultipleHits"); }

  # those that are only reported if a specific option is enabled
  if(opt_IsUsed("--shortfail", $opt_HHR)) { push(@{$ufeature_AR}, "*TooShort"); }
  if(opt_IsUsed("--longfail",  $opt_HHR)) { push(@{$ufeature_AR}, "*TooLong"); }

  # those that don't cause failure, if they don't
  if(! opt_Get("--questfail", $opt_HHR)) { push(@{$ufeature_AR}, "QuestionableModel"); }
  if(! opt_Get("--minusfail", $opt_HHR)) { push(@{$ufeature_AR}, "MinusStrand"); }
  if(! opt_Get("--scfail",    $opt_HHR)) { push(@{$ufeature_AR}, "LowScore"); }
  if(! opt_Get("--covfail",   $opt_HHR)) { push(@{$ufeature_AR}, "LowCoverage"); }
  if(! opt_Get("--difffail",  $opt_HHR)) { push(@{$ufeature_AR}, "LowScoreDifference"); }
  if(! opt_Get("--difffail",  $opt_HHR)) { push(@{$ufeature_AR}, "VeryLowScoreDifference"); }
  if(! opt_Get("--multfail",  $opt_HHR)) { push(@{$ufeature_AR}, "MultipleHits"); }

  foreach my $ufeature (@{$ufeature_AR}) { 
    $ufeature_ct_HR->{$ufeature} = 0;
  }

  return;
}

#################################################################
# Subroutine: update_one_ufeature_sequence
# Incept:     EPN, Tue May  9 15:36:32 2017
#
# Purpose:    Call update_one_ufeature_count for each 
#             unusual feature for a sequence.
#
# Arguments:
#   $ufeature_ct_HR: ref to hash
#   $ufeature_str:   the ufeature string with potentially >= 1 
#                    unexpected features.
#
# Returns:  void
# 
# Dies:     - If $ufeature_str contains a $ufeature that does not exist 
#             in %{$ufeature_ct_HR}
#
#################################################################
sub update_one_ufeature_sequence { 
  my $sub_name = "update_one_ufeature_sequence";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($ufeature_ct_HR, $ufeature_str) = (@_);

  # print("in $sub_name, string is $ufeature_str\n");

  my @ufeatures_A = ();
  if($ufeature_str eq "-") { 
    update_one_ufeature_count($ufeature_ct_HR, "CLEAN");
  }
  else { 
    my @ufeatures_A = split(";", $ufeature_str);
    foreach my $ufeature (@ufeatures_A) { 
      update_one_ufeature_count($ufeature_ct_HR, $ufeature);
    }
  }

  return; 
}

#################################################################
# Subroutine: update_one_ufeature_count
# Incept:     EPN, Tue May  9 15:19:40 2017
#
# Purpose:    Update a ufeature counts hash by incrementing 
#             the relevant count by 1.
#
# Arguments:
#   $ufeature_ct_HR: ref to hash
#   $ufeature:       the ufeature to update
#
# Returns:  void
# 
# Dies:     - If $ufeature that does not exist in %{$ufeature_ct_HR}
#
#################################################################
sub update_one_ufeature_count { 
  my $sub_name = "update_one_ufeature_count";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($ufeature_ct_HR, $ufeature) = (@_);

  # remove ':' and anything after, this removes any hit/sequence specific information
  $ufeature =~ s/\:.+$//;

  if(! exists $ufeature_ct_HR->{$ufeature}) { 
    die "ERROR in $sub_name, unknown unusual feature: $ufeature";
  }

  $ufeature_ct_HR->{$ufeature}++;

  return;
}

#################################################################
# Subroutine: determine_number_columns_long_output_file()
# Incept:     EPN, Mon May  8 15:32:52 2017
#
# Purpose:    Determine how many columns should be in the long 
#             output file for a given round.
#
# Arguments:
#   $round:   what round of searching we're interested in, '1', '2', or 'final'
#   $opt_HHR: reference to 2D hash of cmdline options
#
# Returns:  Number of columns.
# 
# Dies:     Never
#
#################################################################
sub determine_number_of_columns_in_long_output_file { 
  my $sub_name = "determine_number_of_columns_in_long_output_file";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($round, $opt_HHR) = (@_);

  my $have_evalues      = determine_if_we_have_evalues($round, \%opt_HH);
  my $have_evalues_r1   = determine_if_we_have_evalues(1, \%opt_HH);
  my $have_model_coords = determine_if_we_have_model_coords($round, \%opt_HH);

  my $ncols = 18;
  if($have_evalues)      { $ncols++; }
  if($have_model_coords) { $ncols += 2; }
  if($round ne "2") { # add in columns for 'second-best model'
    # no 'second-best model' for round 2, never ever
    $ncols += 4; # 'scdiff', 'scd/nt', 'model', 'tscore';
    if($have_evalues_r1) { $ncols++; } # 'e-value' column in 2nd best model
  }

  return $ncols;
}


#################################################################
# Subroutine: output_summary_statistics()
# Incept:     EPN, Tue May  9 09:42:59 2017
#
# Purpose:    Output the tabular summary statistics.
#
# Arguments:
#   $out_FH:          output file handle
#   $class_stats_HHR: ref to the class statistics 2D hash
#
# Returns:  Nothing.
# 
# Dies:     Never.
#
#################################################################
sub output_summary_statistics { 
  my $sub_name = "output_summary_statistics";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($out_FH, $class_stats_HHR) = (@_);

  # determine max width of each column
  my %width_H = ();  # key: name of column, value max width for column
  my $class;         # a class, 1D key in ${%class_stats_HHR}

  $width_H{"class"}    = length("class");
  $width_H{"nseq"}     = length("of seqs");
  $width_H{"fraction"} = length("fraction");
  $width_H{"length"}   = length("average");
  $width_H{"coverage"} = length("coverage");
  $width_H{"pass"}     = length("that PASS");
  $width_H{"fail"}     = length("that FAIL");

  foreach my $class (keys %{$class_stats_HHR}) { 
    if(length($class) > $width_H{"class"}) { 
      $width_H{"class"} = length($class);
    }
    if(length($class_stats_HHR->{$class}{"nseq"}) > $width_H{"nseq"}) { 
      $width_H{"nseq"} = length($class_stats_HHR->{$class}{"nseq"});
    }
    if(length($class_stats_HHR->{$class}{"npass"}) > $width_H{"pass"}) { 
      $width_H{"pass"} = length($class_stats_HHR->{$class}{"npass"});
    }
    if(length($class_stats_HHR->{$class}{"nseq"}) > $width_H{"fail"}) { 
      $width_H{"fail"} = length($class_stats_HHR->{$class}{"nseq"});
    }
  }    
  
  printf $out_FH ("#\n");
  printf $out_FH ("# Summary statistics:\n");
  printf $out_FH ("#\n");
  
  # line 1
  printf $out_FH ("# %-*s  %*s  %*s  %*s  %*s  %*s  %*s\n", 
                  $width_H{"class"},    "",
                  $width_H{"nseq"},     "number",
                  $width_H{"fraction"}, "fraction",
                  $width_H{"length"},   "average",
                  $width_H{"coverage"}, "average",
                  $width_H{"pass"},     "fraction",
                  $width_H{"fail"},     "number");
  # line 2
  printf $out_FH ("# %-*s  %*s  %*s  %*s  %*s  %*s  %*s\n", 
                  $width_H{"class"},    "class",
                  $width_H{"nseq"},     "of seqs",
                  $width_H{"fraction"}, "of total",
                  $width_H{"length"},   "length",
                  $width_H{"coverage"}, "coverage",
                  $width_H{"pass"},     "that PASS",
                  $width_H{"fail"},     "that FAIL");
  # line 3
  printf $out_FH ("# %-*s  %*s  %*s  %*s  %*s  %*s  %*s\n", 
                  $width_H{"class"},    ribo_GetMonoCharacterString($width_H{"class"}, "-"),
                  $width_H{"nseq"},     ribo_GetMonoCharacterString($width_H{"nseq"}, "-"),
                  $width_H{"fraction"}, ribo_GetMonoCharacterString($width_H{"fraction"}, "-"),
                  $width_H{"length"},   ribo_GetMonoCharacterString($width_H{"length"}, "-"),
                  $width_H{"coverage"}, ribo_GetMonoCharacterString($width_H{"coverage"}, "-"),
                  $width_H{"pass"},     ribo_GetMonoCharacterString($width_H{"pass"}, "-"),
                  $width_H{"fail"},     ribo_GetMonoCharacterString($width_H{"fail"}, "-"));
  
  $class = "*input*";
  printf $out_FH ("  %-*s  %*d  %*.4f  %*.2f  %*.4f  %*s  %*s\n", 
                  $width_H{"class"},    $class,
                  $width_H{"nseq"},     $class_stats_HHR->{$class}{"nseq"},
                  $width_H{"fraction"}, $class_stats_HHR->{$class}{"nseq"} / $class_stats_HHR->{"*input*"}{"nseq"},
                  $width_H{"length"},   $class_stats_HHR->{$class}{"nnt_tot"} / $class_stats_HHR->{$class}{"nseq"},
                  $width_H{"coverage"}, $class_stats_HHR->{$class}{"summed_tcov"} / $class_stats_HHR->{$class}{"nseq"},
                  $width_H{"pass"},     "-",
                  $width_H{"fail"},     "-");
  
  printf $out_FH ("#\n");
  foreach $class (sort keys (%{$class_stats_HHR})) { 
    if($class ne "*input*" && $class ne "*all*" && $class ne "*none*") { 
      printf $out_FH ("  %-*s  %*d  %*.4f  %*.2f  %*.4f  %*.4f  %*d\n", 
                      $width_H{"class"},    $class,
                      $width_H{"nseq"},     $class_stats_HHR->{$class}{"nseq"},
                      $width_H{"fraction"}, $class_stats_HHR->{$class}{"nseq"} / $class_stats_HHR->{"*input*"}{"nseq"},
                      $width_H{"length"},   $class_stats_HHR->{$class}{"nnt_tot"} / $class_stats_HHR->{$class}{"nseq"},
                      $width_H{"coverage"}, $class_stats_HHR->{$class}{"summed_tcov"} / $class_stats_HHR->{$class}{"nseq"},
                      $width_H{"pass"},     $class_stats_HHR->{$class}{"npass"} / $class_stats_HHR->{$class}{"nseq"},
                      $width_H{"fail"},     $class_stats_HHR->{$class}{"nseq"} - $class_stats_HHR->{$class}{"npass"});
    }
  }
  printf $out_FH ("#\n");

  $class = "*all*";
  printf $out_FH ("  %-*s  %*d  %*.4f  %*.2f  %*.4f  %*.4f  %*d\n", 
                  $width_H{"class"},    $class,
                  $width_H{"nseq"},     $class_stats_HHR->{$class}{"nseq"},
                  $width_H{"fraction"}, $class_stats_HHR->{$class}{"nseq"} / $class_stats_HHR->{"*input*"}{"nseq"},
                  $width_H{"length"},   $class_stats_HHR->{$class}{"nnt_tot"} / $class_stats_HHR->{$class}{"nseq"},
                  $width_H{"coverage"}, $class_stats_HHR->{$class}{"summed_tcov"} / $class_stats_HHR->{$class}{"nseq"},
                  $width_H{"pass"},     $class_stats_HHR->{$class}{"npass"} / $class_stats_HHR->{$class}{"nseq"}, 
                  $width_H{"fail"},     $class_stats_HHR->{$class}{"nseq"} - $class_stats_HHR->{$class}{"npass"});

  $class = "*none*";
  if($class_stats_HHR->{$class}{"nseq"} == 0) { 
    printf $out_FH ("  %-*s  %*d  %*.4f  %*.2f  %*.4f  %*.4f  %*d\n", 
                    $width_H{"class"},    $class,
                    $width_H{"nseq"},     0,
                    $width_H{"fraction"}, 0.,
                    $width_H{"length"},   0.,
                    $width_H{"coverage"}, 0.,
                    $width_H{"pass"},     0., 
                    $width_H{"fail"},     0);
  }
  else { 
    printf $out_FH ("  %-*s  %*d  %*.4f  %*.2f  %*.4f  %*.4f  %*d\n", 
                    $width_H{"class"},    $class,
                    $width_H{"nseq"},     $class_stats_HHR->{$class}{"nseq"},
                    $width_H{"fraction"}, $class_stats_HHR->{$class}{"nseq"} / $class_stats_HHR->{"*input*"}{"nseq"},
                    $width_H{"length"},   $class_stats_HHR->{$class}{"nnt_tot"} / $class_stats_HHR->{$class}{"nseq"},
                    $width_H{"coverage"}, $class_stats_HHR->{$class}{"summed_tcov"} / $class_stats_HHR->{$class}{"nseq"},
                    $width_H{"pass"},     $class_stats_HHR->{$class}{"npass"} / $class_stats_HHR->{$class}{"nseq"},
                    $width_H{"fail"},     $class_stats_HHR->{$class}{"nseq"} - $class_stats_HHR->{$class}{"npass"});
  }
  
  return;
}

#################################################################
# Subroutine: output_timing_statistics()
# Incept:     EPN, Tue May  9 11:03:08 2017
#
# Purpose:    Output timing statistics.
#
# Arguments:
#   $out_FH:          output file handle
#   $class_stats_HHR: ref to the class statistics 2D hash
#   $ncpu:            number of CPUs used to do searches
#   $r1_secs:         number of seconds required for round 1 searches
#   $r2_secs:         number of seconds required for round 2 searches
#   $tot_secs:        number of seconds required for entire script
#
# Returns:  Nothing.
# 
# Dies:     Never.
#
#################################################################
sub output_timing_statistics { 
  my $sub_name = "output_timing_statistics";
  my $nargs_expected = 6;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($out_FH, $class_stats_HHR, $ncpu, $r1_secs, $r2_secs, $tot_secs) = (@_);

  if($ncpu == 0) { $ncpu = 1; } 

  # get total number of sequences and nucleotides for each round from %{$class_stats_HHR}
  my $r1_nseq = $class_stats_HHR->{"*input*"}{"nseq"};
  my $r1_nnt  = $class_stats_HHR->{"*input*"}{"nnt_tot"};
  my $r2_nseq = $class_stats_HHR->{"*input*"}{"nseq"} - $class_stats_HHR->{"*none*"}{"nseq"};
  my $r2_nnt  = $class_stats_HHR->{"*input*"}{"nnt_tot"} - $class_stats_HHR->{"*none*"}{"nnt_tot"};
  my $tot_nseq = $r1_nseq;
  my $tot_nnt  = $r2_nnt;

  # determine max width of each column
  my %width_H = ();  # key: name of column, value max width for column
  my $class;         # a class, 1D key in ${%class_stats_HHR}

  $width_H{"class"}    = length("classification");
  $width_H{"nseq"}     = length("num seqs");
  $width_H{"seqsec"}   = 7;
  $width_H{"ntsec"}    = 10;
  $width_H{"ntseccpu"} = 10;
  $width_H{"total"}    = 23;
  
  printf $out_FH ("#\n");
  printf $out_FH ("# Timing statistics:\n");
  printf $out_FH ("#\n");

  # line 1
  printf $out_FH ("# %-*s  %*s  %*s  %*s  %*s  %-*s\n",
                  $width_H{"class"},    "stage",
                  $width_H{"nseq"},     "num seqs",
                  $width_H{"seqsec"},   "seq/sec",
                  $width_H{"ntsec"},    "nt/sec",
                  $width_H{"ntseccpu"}, "nt/sec/cpu",
                  $width_H{"total"},    "total time");
  
  # line 2
  printf $out_FH ("# %-*s  %*s  %*s  %*s  %*s  %*s\n",
                  $width_H{"class"},    ribo_GetMonoCharacterString($width_H{"class"}, "-"),
                  $width_H{"nseq"},     ribo_GetMonoCharacterString($width_H{"nseq"}, "-"),
                  $width_H{"seqsec"},   ribo_GetMonoCharacterString($width_H{"seqsec"}, "-"),
                  $width_H{"ntsec"},    ribo_GetMonoCharacterString($width_H{"ntsec"}, "-"),
                  $width_H{"ntseccpu"}, ribo_GetMonoCharacterString($width_H{"ntseccpu"}, "-"),
                  $width_H{"total"},    ribo_GetMonoCharacterString($width_H{"total"}, "-"));
  
  $class = "classification";
  printf $out_FH ("  %-*s  %*d  %*.1f  %*.1f  %*.1f  %*s\n", 
                  $width_H{"class"},    $class,
                  $width_H{"nseq"},     $r1_nseq,
                  $width_H{"seqsec"},   $r1_nseq / $r1_secs,
                  $width_H{"ntsec"},    $r1_nnt  / $r1_secs, 
                  $width_H{"ntseccpu"}, ($r1_nnt  / $r1_secs) / $ncpu, 
                  $width_H{"total"},    ribo_GetTimeString($r1_secs));

  $class = "search";
  printf $out_FH ("  %-*s  %*d  %*.1f  %*.1f  %*.1f  %*s\n", 
                  $width_H{"class"},    $class,
                  $width_H{"nseq"},     $r2_nseq,
                  $width_H{"seqsec"},   $r2_nseq / $r2_secs,
                  $width_H{"ntsec"},    $r2_nnt  / $r2_secs, 
                  $width_H{"ntseccpu"}, ($r2_nnt  / $r2_secs) / $ncpu, 
                  $width_H{"total"},    ribo_GetTimeString($r2_secs));
  
  
  $class = "total";
  printf $out_FH ("  %-*s  %*d  %*.1f  %*.1f  %*.1f  %*s\n", 
                  $width_H{"class"},    $class,
                  $width_H{"nseq"},     $r1_nseq,
                  $width_H{"seqsec"},   $r1_nseq / $tot_secs,
                  $width_H{"ntsec"},    $r1_nnt  / $tot_secs,
                  $width_H{"ntseccpu"}, ($r1_nnt  / $tot_secs) / $ncpu, 
                  $width_H{"total"},    ribo_GetTimeString($tot_secs));
                  
  printf $out_FH ("#\n");
  
  return;

}

#################################################################
# Subroutine: output_ufeature_statistics()
# Incept:     EPN, Tue May  9 15:30:14 2017
#
# Purpose:    Output counts of each unexpected feature.
#
# Arguments:
#   $out_FH:         output file handle
#   $ufeature_ct_HR: ref to the ufeature count hash
#   $ufeature_AR:    ref to array of ufeature strings
#   $tot_nseq:       total number of sequences in input file
#
# Returns:  Nothing.
# 
# Dies:     Never.
#
#################################################################
sub output_ufeature_statistics { 
  my $sub_name = "output_ufeature_statistics";
  my $nargs_expected = 4;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($out_FH, $ufeature_ct_HR, $ufeature_AR, $tot_nseq) = (@_);

  my $ufeature = undef; # an unexpected feature

  # determine max width of each column
  my %width_H = ();  # key: name of column, value max width for column

  $width_H{"ufeature"} = length("unexpected feature");
  $width_H{"fail"}     = length("failure?");
  $width_H{"seqs"}     = length("of seqs");
  $width_H{"fraction"} = length("fraction");

  # want to skip other_family_hits
  foreach $ufeature (@{$ufeature_AR}) { 
    if(($ufeature_ct_HR->{$ufeature} > 0) || ($ufeature eq "CLEAN")) { 
      if(length($ufeature) > $width_H{"ufeature"}) { 
        $width_H{"ufeature"} = length($ufeature);
      }
      if(length($ufeature_ct_HR->{$ufeature}) > $width_H{"seqs"}) {
        $width_H{"seqs"} = length($ufeature_ct_HR->{$ufeature});
      }
    }
  }
  
  printf $out_FH ("#\n");
  printf $out_FH ("# Unexpected feature statistics:\n");
  printf $out_FH ("#\n");
  
  # line 1 
  printf $out_FH ("# %-*s  %-*s  %*s  %*s\n",
                  $width_H{"ufeature"}, "", 
                  $width_H{"fail"},     "causes",
                  $width_H{"seqs"},     "number",
                  $width_H{"fraction"}, "fraction");
  
  # line 2
  printf $out_FH ("# %-*s  %-*s  %*s  %*s\n",
                  $width_H{"ufeature"}, "unexpected feature",
                  $width_H{"fail"},     "failure?",
                  $width_H{"seqs"},     "of seqs",
                  $width_H{"fraction"}, "of seqs");

  # line 3
  printf $out_FH ("# %-*s  %-*s  %*s  %*s\n", 
                  $width_H{"ufeature"}, ribo_GetMonoCharacterString($width_H{"ufeature"}, "-"),
                  $width_H{"fail"},     ribo_GetMonoCharacterString($width_H{"fail"}, "-"),
                  $width_H{"seqs"},     ribo_GetMonoCharacterString($width_H{"seqs"}, "-"),
                  $width_H{"fraction"}, ribo_GetMonoCharacterString($width_H{"fraction"}, "-"));

  foreach $ufeature (@{$ufeature_AR}) { 
    if(($ufeature_ct_HR->{$ufeature} > 0) || ($ufeature eq "CLEAN")) { 
      printf $out_FH ("  %-*s  %-*s  %*d  %*.5f\n", 
                      $width_H{"ufeature"}, $ufeature,
                      $width_H{"fail"},     ($ufeature =~ m/^\*/) ? "yes" : "no",
                      $width_H{"seqs"},     $ufeature_ct_HR->{$ufeature},
                      $width_H{"fraction"}, $ufeature_ct_HR->{$ufeature} / $tot_nseq);
    }
  }
  printf $out_FH ("#\n");
  
  return;
  
}



#################################################################
# Subroutine: debug_print_model_stats
# Incept:     EPN, Thu May 11 14:13:27 2017
#
# Purpose:    Output all values in a model stats hash
#
# Arguments:
#   $model_HHR: ref to 2D hash, 1D keys families, 2D keys:
#               "model", "domain", "evalue", "score",
#               "start", "stop", "strand", "mdlstart", "mdlstop"
#   $name:      name of model 2D hash
#
# Returns:  void
# 
# Dies:     Never
#
#################################################################
sub debug_print_model_stats { 
  my $sub_name = "debug_print_model_stats";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($model_HHR, $name) = (@_);

  printf("$sub_name, name: $name\n");

  foreach my $family (sort keys (%{$model_HHR})) { 
    printf("family: $family\n");
    foreach my $key ("model", "domain", "evalue", "score", "start", "stop", "strand", "mdlstart", "mdlstop") { 
      printf("\t%10s: ", $key);
      if(defined $model_HHR->{$family}{$key}) { 
        printf($model_HHR->{$family}{$key} . "\n"); 
      }
      else { 
        printf("undefined\n");
      }
    }
  }
  return;
}
