#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

require "epn-options.pm";
require "epn-ofile.pm";
require "ribo.pm";

# make sure the RIBODIR variable is set, others we will wait to see
# if they are required first
my $env_ribotyper_dir     = ribo_VerifyEnvVariableIsValidDir("RIBODIR");
my $env_vecplus_dir       = undef;
my $env_ribotax_dir       = undef;
my $env_riboblast_dir     = undef;
#my $env_infernal_exec_dir = ribo_VerifyEnvVariableIsValidDir("INFERNALDIR");
#my $env_easel_exec_dir    = ribo_VerifyEnvVariableIsValidDir("EASELDIR");
my $df_model_dir          = $env_ribotyper_dir . "/models/";

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
#                 "setby":        '1' if option set by the user, else 'undef'
#                 "value":        value for option, can be undef if default is undef
#
# opt_order_A: array of options in the order they should be processed
# 
# opt_group_desc_H: key: group number (integer), value: description of group for help output
my %opt_HH = ();      
my @opt_order_A = (); 
my %opt_group_desc_H = ();
my $g = 0;
# Add all options to %opt_HH and @opt_order_A.
# This section needs to be kept in sync (manually) with the &GetOptions call below
$opt_group_desc_H{++$g} = "basic options";
#     option            type       default               group   requires incompat     preamble-output                                            help-output    
opt_Add("-h",           "boolean", 0,                        0,    undef, undef,       undef,                                                     "display this help",                                            \%opt_HH, \@opt_order_A);
opt_Add("-f",           "boolean", 0,                       $g,    undef, undef,       "forcing directory overwrite",                             "force; if <output directory> exists, overwrite it",            \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                       $g,    undef, undef,       "be verbose",                                              "be verbose; output commands to stdout as they're run",         \%opt_HH, \@opt_order_A);
opt_Add("-n",           "integer", 1,                       $g,    undef, undef,       "use <n> CPUs",                                            "use <n> CPUs",                                                 \%opt_HH, \@opt_order_A);
opt_Add("--fetch",      "string",  undef,                   $g,    undef, "--fasta",   "fetch sequences using seqfetch query in <s>",             "fetch sequences using seqfetch query in <s>",                  \%opt_HH, \@opt_order_A);
opt_Add("--fasta",      "string",  undef,                   $g,    undef, "--fetch",   "sequences provided as fasta input in <s>",                "don't fetch sequences, <s> is fasta file of input sequences",  \%opt_HH, \@opt_order_A);
opt_Add("--keep",      "boolean", 0,                        $g,    undef,   undef,     "keep all intermediate files",                             "keep all intermediate files that are removed by default",      \%opt_HH, \@opt_order_A);

$g++;
$opt_group_desc_H{++$g} = "options for skipping stages";
#               option  type       default               group   requires                incompat   preamble-output                                                 help-output    
opt_Add("--skipfambig", "boolean", 0,                       $g,    undef,                   undef,  "skip stage that filters based on ambiguous nucleotides",       "skip stage that filters based on ambiguous nucleotides",       \%opt_HH, \@opt_order_A);
opt_Add("--skipftaxid", "boolean", 0,                       $g,    undef,                   undef,  "skip stage that filters by taxid",                             "skip stage that filters by taxid",                             \%opt_HH, \@opt_order_A);
opt_Add("--skipfvecsc", "boolean", 0,                       $g,    undef,                   undef,  "skip stage that filters based on VecScreen",                   "skip stage that filters based on VecScreen",                   \%opt_HH, \@opt_order_A);
opt_Add("--skipfblast", "boolean", 0,                       $g,    undef,                   undef,  "skip stage that filters based on BLAST hits to self",          "skip stage that filters based on BLAST hits to self",          \%opt_HH, \@opt_order_A);
opt_Add("--skipfribos", "boolean", 0,                       $g,"--skipfmspan,--skipfingrp", undef,  "skip stage that filters based on ribotyper/ribolengthchecker", "skip stage that filters based on ribotyper/ribolengthchecker", \%opt_HH, \@opt_order_A);
opt_Add("--skipfmspan", "boolean", 0,                       $g,    undef,                   undef,  "skip stage that filters based on model span of hits",          "skip stage that filters based on model span of hits",          \%opt_HH, \@opt_order_A);
opt_Add("--skipfingrp", "boolean", 0,                       $g,    undef,                   undef,  "skip stage that filters based on ingroup analysis",            "skip stage that filters based on ingroup analysis",            \%opt_HH, \@opt_order_A);
opt_Add("--skipclustr", "boolean", 0,                       $g,    undef,                   undef,  "skip stage that clusters surviving sequences",                 "skip stage that clusters sequences surviving all filters",     \%opt_HH, \@opt_order_A);
opt_Add("--skiplistms", "boolean", 0,                       $g,    undef,                   undef,  "skip stage that lists missing taxids",                         "skip stage that lists missing taxids",                         \%opt_HH, \@opt_order_A);

$opt_group_desc_H{++$g} = "options for controlling the stage that filters based on ambiguous nucleotides";
#              option   type       default               group  requires incompat                    preamble-output                                            help-output    
opt_Add("--maxnambig",  "integer", 0,                       $g,    undef,"--skipfambig,--maxfambig", "set maximum number of allowed ambiguous nts to <n>",      "set maximum number of allowed ambiguous nts to <n>",           \%opt_HH, \@opt_order_A);
opt_Add("--maxfambig",  "real",    0,                       $g,    undef,"--skipfambig,--maxnambig", "set maximum fraction of of allowed ambiguous nts to <x>", "set maximum fraction of allowed ambiguous nts to <x>",         \%opt_HH, \@opt_order_A);

$g++;
$opt_group_desc_H{++$g} = "options for controlling the stage that filters based on self-BLAST hits";
#              option   type       default               group  requires incompat                    preamble-output                                            help-output    
opt_Add("--fbcsize",  "integer",   20,                      $g,    undef,"--skipfblast",             "set num seqs for each BLAST run to <n>",   "set num seqs for each BLAST run to <n>",                          \%opt_HH, \@opt_order_A);
opt_Add("--fbcall",   "boolean",   0,                       $g,    undef,"--skipfblast,--fbcsize",   "do single BLAST run with all N seqs",      "do single BLAST run with all N seqs (CAUTION: slow for large N)", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{++$g} = "options for controlling the stage that filters based on ribotyper/ribolengthchecker";
# THESE OPTIONS SHOULD BE MANUALLY KEPT IN SYNC WITH THE CORRESPONDING OPTION GROUP IN ribolengthchecker.pl
#       option          type       default               group  requires  incompat        preamble-output                                         help-output    
opt_Add("-i",           "string",  undef,                   $g,    undef, "--skipfribos", "use rlc model info file <s> instead of default",       "use ribolengthchecker.pl model info file <s> instead of default", \%opt_HH, \@opt_order_A);
opt_Add("--riboopts",   "string",  undef,                   $g,    undef, "--skipfribos", "read command line options for ribotyper from <s>",     "read command line options to supply to ribotyper from file <s>", \%opt_HH, \@opt_order_A);
opt_Add("--noscfail",   "boolean", 0,                       $g,    undef, "--skipfribos", "do not fail sequences in ribotyper with low scores",   "do not fail sequences in ribotyper with low scores", \%opt_HH, \@opt_order_A);
opt_Add("--nocovfail",  "boolean", 0,                       $g,    undef, "--skipfribos", "do not fail sequences in ribotyper with low coverage", "do not fail sequences in ribotyper with low coverage", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{++$g} = "options for controlling the stage that filters based model span of hits:";
#       option           type        default             group  requires  incompat              preamble-output                                          help-output    
opt_Add("--pos",         "integer",  undef,                 $g,    undef, "--skipfmspan",       "aligned sequences must span from <n> to L - <n> + 1",   "aligned sequences must span from <n> to L - <n> + 1 for model of length L", \%opt_HH, \@opt_order_A);
opt_Add("--lpos",        "integer",  undef,                 $g,  "--rpos","--skipfmspan,--pos", "aligned sequences must extend from position <n>",       "aligned sequences must extend from position <n> for model of length L", \%opt_HH, \@opt_order_A);
opt_Add("--rpos",        "integer",  undef,                 $g,  "--lpos","--skipfmspan,--pos", "aligned sequences must extend to position L - <n> + 1", "aligned sequences must extend to <n> to L - <n> + 1 for model of length L", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{++$g} = "advanced options for debugging and testing:";
#       option           type        default             group  requires  incompat              preamble-output                                          help-output    
opt_Add("--prvcmd",      "boolean",  0,                     $g,    undef, "-f",                 "do not execute commands; use output from previous run", "do not execute commands; use output from previous run", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: ribodbcreate.pl [-options] <file with seqfetch command> <output file name root>\n";
$usage      .= "\n";
my $synopsis = "ribodbcreate.pl :: create representative database of ribosomal RNA sequences";
my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"}, 
                'f'            => \$GetOptions_H{"-f"},
                'n=s'          => \$GetOptions_H{"-n"},
                'v'            => \$GetOptions_H{"-v"},
                'fetch=s'      => \$GetOptions_H{"--fetch"},
                'fasta=s'      => \$GetOptions_H{"--fasta"},
                'keep'         => \$GetOptions_H{"--keep"},
                'skipftaxid'   => \$GetOptions_H{"--skipftaxid"},
                'skipfambig'   => \$GetOptions_H{"--skipfambig"},
                'skipfvecsc'   => \$GetOptions_H{"--skipfvecsc"},
                'skipfblast'   => \$GetOptions_H{"--skipfblast"},
                'skipfribos'   => \$GetOptions_H{"--skipfribos"},
                'skipfmspan'   => \$GetOptions_H{"--skipfmspan"},
                'skipfingrp'   => \$GetOptions_H{"--skipfingrp"},
                'skipclustr'   => \$GetOptions_H{"--skipclustr"},
                'skiplistms'   => \$GetOptions_H{"--skiplistms"},
                'maxnambig=s'  => \$GetOptions_H{"--maxnambig"},
                'maxfambig=s'  => \$GetOptions_H{"--maxfambig"},
                'fbcsize=s'    => \$GetOptions_H{"--fbcsize"},
                'fbcall'       => \$GetOptions_H{"--fbcall"},
                'i=s'          => \$GetOptions_H{"-i"},
                'riboopts=s'   => \$GetOptions_H{"--riboopts"},
                'noscfail'     => \$GetOptions_H{"--noscfail"},
                'nocovfail'    => \$GetOptions_H{"--nocovfail"},
                'pos=s'        => \$GetOptions_H{"--pos"},
                'lpos=s'       => \$GetOptions_H{"--lpos"},
                'rpos=s'       => \$GetOptions_H{"--rpos"}, 
                'prvcmd'       => \$GetOptions_H{"--prvcmd"}); 


my $total_seconds     = -1 * ribo_SecondsSinceEpoch(); # by multiplying by -1, we can just add another ribo_SecondsSinceEpoch call at end to get total time
my $executable        = $0;
my $date              = scalar localtime();
my $version           = "0.15";
my $model_version_str = "0p15"; 
my $releasedate       = "Mar 2018";
my $package_name      = "ribotyper";
my $pkgstr    = "RIBO";

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
if(scalar(@ARGV) != 1) {   
  print "Incorrect number of command line arguments.\n";
  print $usage;
  print "\nTo see more help on available options, enter ribolengthchcker.pl -h\n\n";
  exit(1);
}
my ($dir) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

# determine what stages we are going to do:
my $do_ftaxid = opt_Get("--skipftaxid", \%opt_HH) ? 0 : 1;
my $do_fambig = opt_Get("--skipfambig", \%opt_HH) ? 0 : 1;
my $do_fvecsc = opt_Get("--skipfvecsc", \%opt_HH) ? 0 : 1;
my $do_fblast = opt_Get("--skipfblast", \%opt_HH) ? 0 : 1;
my $do_fribos = opt_Get("--skipfribos", \%opt_HH) ? 0 : 1;
my $do_fmspan = opt_Get("--skipfmspan", \%opt_HH) ? 0 : 1;
my $do_fingrp = opt_Get("--skipfingrp", \%opt_HH) ? 0 : 1;
my $do_clustr = opt_Get("--skipclustr", \%opt_HH) ? 0 : 1;
my $do_listms = opt_Get("--skiplistms", \%opt_HH) ? 0 : 1;
my $do_prvcmd = opt_Get("--prvcmd",     \%opt_HH) ? 1 : 0;
my $do_keep   = opt_Get("--keep",       \%opt_HH) ? 1 : 0;

# do checks that are too sophisticated for epn-options.pm
if((! (opt_IsUsed("--fetch", \%opt_HH))) && (! (opt_IsUsed("--fasta", \%opt_HH)))) { 
  die "ERROR, neither --fetch nor --fasta options were used. Exactly one must be.";
}

my $in_fetch_file = opt_Get("--fetch", \%opt_HH); # this will be undefined unless --fetch set on the command line
my $in_fasta_file = opt_Get("--fasta", \%opt_HH); # this will be undefined unless --fasta set on the command line
# verify required files exist
if(defined $in_fetch_file) { 
  ribo_CheckIfFileExistsAndIsNonEmpty($in_fetch_file, "--fetch argument", undef, 1); 
}
if(defined $in_fasta_file) { 
  ribo_CheckIfFileExistsAndIsNonEmpty($in_fasta_file, "--fasta argument", undef, 1); 
}

# now that we know what steps we are doing, make sure that:
# - required ENV variables are set and point to valid dirs
# - required executables exist and are executable
# - required files exist
# we do this for each stage individually

my $in_riboopts_file = undef;
my $df_rlc_modelinfo_file = $df_model_dir . "ribolengthchecker." . $model_version_str . ".modelinfo";
my $rlc_modelinfo_file = undef;
my %execs_H = (); # key is name of program, value is path to the executable
my $taxonomy_tree_wlevels_file            = undef;
my $taxonomy_tree_wspecified_species_file = undef;
if($do_ftaxid || $do_fingrp || $do_fvecsc) { 
  $env_vecplus_dir = ribo_VerifyEnvVariableIsValidDir("VECPLUSDIR");
  if($do_fvecsc) { 
    $execs_H{"vecscreen"}            = $env_vecplus_dir    . "/scripts/vecscreen"; 
    $execs_H{"parse_vecscreen.pl"}   = $env_vecplus_dir    . "/scripts/parse_vecscreen.pl";
    $execs_H{"combine_summaries.pl"} = $env_vecplus_dir    . "/scripts/combine_summaries.pl";
  }
  if($do_ftaxid || $do_fingrp) { 
    $execs_H{"srcchk"} = $env_vecplus_dir . "/scripts/srcchk";

    $env_ribotax_dir = ribo_VerifyEnvVariableIsValidDir("RIBOTAXDIR");
    if($do_fingrp) { 
      $taxonomy_tree_wlevels_file = $env_ribotax_dir . "/taxonomy_tree_wlevels.txt";
      ribo_CheckIfFileExistsAndIsNonEmpty($taxonomy_tree_wlevels_file, "taxonomy tree file with taxonomic levels", undef, 1); # 1 says: die if it doesn't exist or is empty
      $execs_H{"find_taxonomy_ancestors.pl"} = $env_vecplus_dir . "/scripts/find_taxonomy_ancestors.pl";
    }
    if($do_ftaxid) { 
      $taxonomy_tree_wspecified_species_file = $env_ribotax_dir . "/taxonomy_tree_wspecspecies.txt";
      ribo_CheckIfFileExistsAndIsNonEmpty($taxonomy_tree_wspecified_species_file, "taxonomy tree file with taxonomic levels", undef, 1); # 1 says: die if it doesn't exist or is empty
    }
  }
}

if($do_fblast) { 
  $env_riboblast_dir = ribo_VerifyEnvVariableIsValidDir("RIBOBLASTDIR");
  $execs_H{"blastn"} = $env_riboblast_dir  . "/blastn";
}

if($do_fribos) { 
  # make sure the ribolengthchecker modelinfo files exists
  if(! opt_IsUsed("-i", \%opt_HH)) { 
    $rlc_modelinfo_file = $df_rlc_modelinfo_file;  
    ribo_CheckIfFileExistsAndIsNonEmpty($rlc_modelinfo_file, "default ribolengthchecker model info file", undef, 1); # 1 says: die if it doesn't exist or is empty
  }
  else { # -i used
    $rlc_modelinfo_file = opt_Get("-i", \%opt_HH); }
  if(! opt_IsUsed("-i", \%opt_HH)) {
    ribo_CheckIfFileExistsAndIsNonEmpty($rlc_modelinfo_file, "ribolengthchecker model info file specified with -i", undef, 1); # 1 says: die if it doesn't exist or is empty
  }

  # make sure the riboinfo file exists
  if(! opt_IsUsed("--riboopts", \%opt_HH)) {
    die "ERROR, --riboopts is a required option, unless --skipfribos is used";
  }
  $in_riboopts_file = opt_Get("--riboopts", \%opt_HH);
  ribo_CheckIfFileExistsAndIsNonEmpty($in_riboopts_file, "riboopts file specified with --riboopts", undef, 1); # last argument as 1 says: die if it doesn't exist or is empty

  $execs_H{"ribotyper"}         = $env_ribotyper_dir  . "/ribotyper.pl";
  $execs_H{"ribolengthchecker"} = $env_ribotyper_dir  . "/ribolengthchecker.pl";
}

# either --pos or both of --lpos and --rpos are required
my $in_pos  = undef;
my $in_lpos = undef;
my $in_rpos = undef;
if($do_fmspan) { 
  if(opt_IsUsed("--pos",  \%opt_HH)) { $in_pos  = opt_Get("--pos", \%opt_HH); }
  if(opt_IsUsed("--lpos", \%opt_HH)) { $in_lpos = opt_Get("--lpos", \%opt_HH); }
  if(opt_IsUsed("--rpos", \%opt_HH)) { $in_rpos = opt_Get("--rpos", \%opt_HH); }
  if((! defined $in_pos) && (! defined $in_lpos) && (! defined $in_rpos)) { 
    die "ERROR, either --pos, or both --lpos and --rpos are required.";
  }
}

# Currently, we require infernal and easel executables are in the user's path, 
# but do not check. The program will die if the commands using them fail. 
# The block below is retained in in case we want to use it eventually.
#$execs_H{"cmalign"}    = $env_infernal_exec_dir . "/cmalign";
#$execs_H{"esl-sfetch"} = $env_easel_exec_dir    . "/esl-sfetch";
ribo_ValidateExecutableHash(\%execs_H);

#############################
# create the output directory
#############################
my $cmd;              # a command to run with runCommand()
my @early_cmd_A = (); # array of commands we run before our log file is opened
if($dir !~ m/\/$/) { $dir =~ s/\/$//; } # remove final '/' if it exists
                
if(-d $dir) { 
  $cmd = "rm -rf $dir";
  if(opt_Get("-f", \%opt_HH)) { 
    ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH)); push(@early_cmd_A, $cmd); 
  }
  else { # $dir directory exists but -f not used
    if(! $do_prvcmd) { 
      die "ERROR directory named $dir already exists. Remove it, or use -f to overwrite it."; 
    }
  }
}
elsif(-e $dir) { 
  $cmd = "rm $dir";
  if(opt_Get("-f", \%opt_HH)) { 
    ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH)); push(@early_cmd_A, $cmd); 
  }
  else { # $dir file exists but -f not used
    die "ERROR a file named $dir already exists. Remove it, or use -f to overwrite it."; 
  }
}

# create the dir
$cmd = "mkdir $dir";
if(! $do_prvcmd) { 
  ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH));
  push(@early_cmd_A, $cmd);
}

my $dir_tail = $dir;
$dir_tail =~ s/^.+\///; # remove all but last dir
my $out_root = $dir . "/" . $dir_tail . ".ribodbcreate";


#############################################
# output program banner and open output files
#############################################
# output preamble
my @arg_desc_A = ("reference accession");
my @arg_A      = ($dir);
my %extra_H    = ();
$extra_H{"\$RIBODIR"} = $env_ribotyper_dir;
if(defined $env_ribotax_dir) { $extra_H{"\$RIBOTAXDIR"} = $env_ribotax_dir; }
if(defined $env_vecplus_dir) { $extra_H{"\$VECPLUSDIR"} = $env_vecplus_dir; }
ofile_OutputBanner(*STDOUT, $package_name, $version, $releasedate, $synopsis, $date, \%extra_H);
opt_OutputPreamble(*STDOUT, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

# open the log and command files:
# set output file names and file handles, and open those file handles
my %ofile_info_HH = ();  # hash of information on output files we created,
                         # 1D keys: 
                         #  "fullpath":  full path to the file
                         #  "nodirpath": file name, full path minus all directories
                         #  "desc":      short description of the file
                         #  "FH":        file handle to output to for this file, maybe undef
                         # 2D keys:
                         #  "log": log file of what's output to stdout
                         #  "cmd": command file with list of all commands executed

# open the log and command files 
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, $pkgstr, "log", $out_root . ".log", 1, "Output printed to screen");
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, $pkgstr, "cmd", $out_root . ".cmd", 1, "List of executed commands");
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, $pkgstr, "list", $out_root . ".list", 1, "List and description of all output files");
my $log_FH = $ofile_info_HH{"FH"}{"log"};
my $cmd_FH = $ofile_info_HH{"FH"}{"cmd"};
# output files are all open, if we exit after this point, we'll need
# to close these first.

# now we have the log file open, output the banner there too
ofile_OutputBanner($log_FH, $pkgstr, $version, $releasedate, $synopsis, $date, \%extra_H);
opt_OutputPreamble($log_FH, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

# output any commands we already executed to $log_FH
foreach $cmd (@early_cmd_A) { 
  print $cmd_FH $cmd . "\n";
}

###########################################################################
# Preliminary stage: Parse/validate input files
# We do this first, so we can die quickly if anything goes wrong
# as opposed to waiting until we get to the relevant stage.
###########################################################################
my $progress_w = 80; # the width of the left hand column in our progress output, hard-coded
my $start_secs;
$start_secs = ofile_OutputProgressPrior("[Stage: prelim] Validating input files", $progress_w, $log_FH, *STDOUT);

# parse the modelinfo file, this tells us where the CM files are
my @family_order_A     = (); # family names, in order
my %family_modelname_H = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is CM file for that family
my %family_modellen_H  = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is consensus length for that family
my $family;

if($do_fribos) { 
  ribo_ParseRLCModelinfoFile($rlc_modelinfo_file, $df_model_dir, \@family_order_A, \%family_modelname_H, \%family_modellen_H);

  # verify the CM files listed in $rlc_modelinfo_file exist
  foreach $family (@family_order_A) { 
    if(! -s $family_modelname_H{$family}) { 
      die "Model file $family_modelname_H{$family} specified in $rlc_modelinfo_file does not exist or is empty";
    }
  }
}
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

###########################################################################################
# Preliminary stage: Fetch the sequences (if --fetch) or copy the fasta file (if --fasta)
###########################################################################################
my $raw_fasta_file = $out_root . ".raw.fa";
my $full_fasta_file = $out_root . ".full.fa";
if(defined $in_fetch_file) { 
  $start_secs = ofile_OutputProgressPrior("[Stage: prelim] Executing command to fetch sequences ", $progress_w, $log_FH, *STDOUT);
  open(FETCH, $in_fetch_file) || ofile_FileOpenFailure($in_fetch_file, $pkgstr, "ribodbcreate.pl:main()", $!, "reading", $ofile_info_HH{"FH"});
  my $fetch_command = <FETCH>; # read only the first line of the file
  chomp $fetch_command;
  if($fetch_command =~ m/\>/) { 
    ofile_FAIL("ERROR, fetch command read from $in_fetch_file includes an output character \>", $pkgstr, $!, $ofile_info_HH{"FH"}); 
  }
  $fetch_command .= " > $raw_fasta_file";
  if(! $do_prvcmd) { 
    new_ribo_RunCommand($fetch_command, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  }
  ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
}
else { # $in_fasta_file must be defined
  if(! defined $in_fasta_file) { 
    ofile_FAIL("ERROR, neither --fetch nor --fasta was used, exactly one must be.", $pkgstr, $!, $ofile_info_HH{"FH"}); 
  }
  $start_secs = ofile_OutputProgressPrior("[Stage: prelim] Copying input fasta file ", $progress_w, $log_FH, *STDOUT);
  my $cp_command .= "cp $in_fasta_file $raw_fasta_file";
  if(! $do_prvcmd) { 
    new_ribo_RunCommand($cp_command, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  }
  ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
}

# reformat the names of the sequences:
# gi|675602128|gb|KJ925573.1| becomes KJ925573.1
$start_secs = ofile_OutputProgressPrior("[Stage: prelim] Reformatting names of sequences ", $progress_w, $log_FH, *STDOUT);
my $check_fetched_names_format = (opt_Get("--fetch", \%opt_HH)) ? 1 : 0;
$check_fetched_names_format = 1; # TEMP 
reformat_sequence_names_in_fasta_file($raw_fasta_file, $full_fasta_file, $check_fetched_names_format, $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "fullfa", "$full_fasta_file", 1, "Fasta file with all sequences with names possibly reformatted to accession version");
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

# get lengths of all seqs and create a list of all sequences
my $seqstat_file = $out_root . ".full.seqstat";
my $comptbl_file = $out_root . ".full.comptbl";
my %seqidx_H = (); # key: sequence name, value: index of sequence in original input sequence file (1..$nseq)
my %seqlen_H = (); # key: sequence name, value: length of sequence, 
                   # value multiplied by -1 after we output info for this sequence
                   # in round 1. Multiplied by -1 again after we output info 
                   # for this sequence in round 2. We do this so that we know
                   # that 'we output this sequence already', so if we 
                   # see it again before the next round, then we know the 
                   # tbl file was not sorted properly. That shouldn't happen,
                   # but if somehow it does then we want to know about it.
my %seqnambig_H  = (); # number of ambiguous nucleotides per sequence
my @seqorder_A   = (); # array of sequence names in order they appeared in the file
my $nseq = 0;
my $full_list_file = $out_root . ".full.list";

$start_secs = ofile_OutputProgressPrior("[Stage: prelim] Determining target sequence lengths", $progress_w, $log_FH, *STDOUT);
ribo_ProcessSequenceFile("esl-seqstat", $full_fasta_file, $seqstat_file, \%seqidx_H, \%seqlen_H, undef, \%opt_HH);
$nseq = scalar(keys %seqidx_H);
ribo_CountAmbiguousNucleotidesInSequenceFile("esl-seqstat", $full_fasta_file, $comptbl_file, \%seqnambig_H, \%opt_HH);
if(! $do_prvcmd) { 
  new_ribo_RunCommand("grep ^\= $seqstat_file | awk '{ print \$2 }' > $full_list_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
}
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "fulllist", "$full_list_file", 1, "File with list of all $nseq input sequences");
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

# index the sequence file
if(! $do_prvcmd) { 
  new_ribo_RunCommand("esl-sfetch --index $full_fasta_file > /dev/null", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
}

# create the ordered array of sequence anmes

###########################################################################################
# Preliminary stage: Run srcchk, if necessary (if $do_ftaxid || $do_fingrp)
###########################################################################################
my $full_srcchk_file = undef;
if($do_ftaxid || $do_fingrp) { 
  $start_secs = ofile_OutputProgressPrior("[Stage: prelim] Running srcchk for all sequences ", $progress_w, $log_FH, *STDOUT);
  $full_srcchk_file = $out_root . ".full.srcchk";
  if(! $do_prvcmd) { 
    new_ribo_RunCommand($execs_H{"srcchk"} . " -i $full_list_file -f \'taxid,organism\' > $full_srcchk_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  }
  ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "fullsrcchk", "$full_srcchk_file", 1, "srcchk output for all $nseq input sequences");
  ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
}

####################
# FILTERING STAGES #
####################

my %seqfailstr_H = (); # hash that keeps track of failure strings for each sequence, will be "" for a passing sequence
my %curfailstr_H = (); # hash that keeps track of failure string for current stage only, will be "" for a passing sequence
my $seqname;
my $npass = 0;
# fill the seqorder array
foreach $seqname (keys %seqidx_H) { 
  $seqorder_A[($seqidx_H{$seqname} - 1)] = $seqname;
}  
initialize_hash_to_empty_string(\%curfailstr_H, \@seqorder_A);
initialize_hash_to_empty_string(\%seqfailstr_H, \@seqorder_A);
my $stage_key = undef;

########################################################
# 'fambig' stage: filter based on ambiguous nucleotides
########################################################
my $maxnambig = opt_Get("--maxnambig", \%opt_HH);
my $do_fract_ambig = opt_IsUsed("--maxfambig", \%opt_HH);
my $maxfambig = opt_Get("--maxfambig", \%opt_HH);
if($do_fambig) { 
  $stage_key = "fambig";
  $start_secs = ofile_OutputProgressPrior("[Stage: $stage_key] Filtering based on ambiguous nucleotides ", $progress_w, $log_FH, *STDOUT);
  foreach $seqname (keys %seqnambig_H) { 
    if($do_fract_ambig) { 
      $maxnambig = $maxfambig * $seqlen_H{$seqname}; 
    }
    if($seqnambig_H{$seqname} > $maxnambig) { 
      $curfailstr_H{$seqname} = "ambig[" . $seqnambig_H{$seqname} . "];"; 
    }
    else { 
      $curfailstr_H{$seqname} = "";
    }
  }
  $npass = update_and_output_pass_fails(\%curfailstr_H, \%seqfailstr_H, \@seqorder_A, $out_root, $stage_key, \%ofile_info_HH);
  ofile_OutputProgressComplete($start_secs, sprintf("%6d pass; %6d fail;", $npass, $nseq-$npass), $log_FH, *STDOUT);
}

###############################################
# 'ftaxid' stage: filter for specified species
###############################################
if($do_ftaxid) { 
  $stage_key = "ftaxid";
  $start_secs = ofile_OutputProgressPrior("[Stage: $stage_key] Filtering for specified species ", $progress_w, $log_FH, *STDOUT);
  $npass = parse_srcchk_and_tax_files_for_specified_species($full_srcchk_file, $taxonomy_tree_wspecified_species_file, \%seqfailstr_H, \@seqorder_A, $out_root, \%opt_HH, \%ofile_info_HH);
  ofile_OutputProgressComplete($start_secs, sprintf("%6d pass; %6d fail;", $npass, $nseq-$npass), $log_FH, *STDOUT);
}
  
#########################################################
# 'fvecscr' stage: filter for non-weak VecScreen matches 
#########################################################
$stage_key = "fvecsc";
my $parse_vecscreen_terminal_file = $out_root . "." . $stage_key . ".terminal.parse_vecscreen";
my $parse_vecscreen_internal_file = $out_root . "." . $stage_key . ".internal.parse_vecscreen";
my $parse_vecscreen_combined_file = $out_root . "." . $stage_key . ".combined.parse_vecscreen";
if($do_fvecsc) { 
  $start_secs = ofile_OutputProgressPrior("[Stage: $stage_key] Identifying vector sequences with VecScreen", $progress_w, $log_FH, *STDOUT);
  my $vecscreen_output_file = $out_root . ".vecscreen";
  my $vecscreen_cmd  = $execs_H{"vecscreen"} . " -text_output -query $full_fasta_file > $vecscreen_output_file";
  if(! $do_prvcmd) { 
    new_ribo_RunCommand($vecscreen_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  }
  ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "vecout", "$vecscreen_output_file", 1, "vecscreen output file");

  # parse vecscreen 
  my $parse_vecscreen_cmd   = $execs_H{"parse_vecscreen.pl"} . " --verbose --input $vecscreen_output_file --outfile_terminal $parse_vecscreen_terminal_file --outfile_internal $parse_vecscreen_internal_file";
  my $combine_summaries_cmd = $execs_H{"combine_summaries.pl"} . " --input_internal $parse_vecscreen_internal_file --input_terminal $parse_vecscreen_terminal_file --outfile $parse_vecscreen_combined_file";
  if(! $do_prvcmd) { 
    new_ribo_RunCommand($parse_vecscreen_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    new_ribo_RunCommand($combine_summaries_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  }
  ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "parsevec", "$parse_vecscreen_combined_file", 1, "combined parse_vecscreen.pl output file");

  # get list of accessions in combined parse_vecscreen output that have non-Weak matches
  $npass = parse_parse_vecscreen_combined_file($parse_vecscreen_combined_file, \%seqfailstr_H, \@seqorder_A, $out_root, \%opt_HH, \%ofile_info_HH);

  #my $get_vecscreen_fails_list_cmd = "cat $parse_vecscreen_combined_file | awk -F \'\\t\' '{ printf(\"%s %s\\n\", \$1, \$7); }' | grep -i -v weak | awk '{ printf(\"%s\\n\", \$1); }' | sort | uniq > $vecscreen_fails_list_file";
  #new_ribo_RunCommand($get_vecscreen_fails_list_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  #ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "vecfails", "$vecscreen_fails_list_file", 1, "list of sequences that had non-Weak VecScreen matches");
  ofile_OutputProgressComplete($start_secs, sprintf("%6d pass; %6d fail;", $npass, $nseq-$npass), $log_FH, *STDOUT);
}

###################################################################
# 'fblast' stage: self-blast all sequences to find tandem repeats
###################################################################
if($do_fblast) { 
  $stage_key = "fblast";
  $start_secs = ofile_OutputProgressPrior("[Stage: $stage_key] Identifying repeats by BLASTing against self", $progress_w, $log_FH, *STDOUT);
  
  initialize_hash_to_empty_string(\%curfailstr_H, \@seqorder_A);

  # split input sequence file into chunks and process each
  my $chunksize = opt_Get("--fbcall", \%opt_HH) ? $nseq : opt_Get("--fbcsize", \%opt_HH);
  my $seqline = undef;
  my $seq = undef;
  my $cur_seqidx = 0;
  my $chunk_sfetch_file = undef;
  my $chunk_fasta_file  = undef;
  my $chunk_blast_file  = undef;
  my $sfetch_cmd        = undef;
  my $blast_cmd         = undef; 
  my %cur_nhit_H        = (); # key is sequence name, value is number of of hits this sequence has in current chunk
                              # keys for sequence names not in the current chunk do not exist in the hash
  my %nblasted_H        = (); # key is sequence name, value is number of times this sequence was ever in the current set 
                              # (e.g. times blasted against itself), should be 1 for all at end of function
  foreach $seq (@seqorder_A) { 
    $nblasted_H{$seq} = 0;
  }

  # loop through all seqs
  # when we reach $chunksize (50) seqs in our current temp file, stop and run blast
  # this avoids the N^2 runtime of running blast all v all
  # 50 was good tradeoff between overhead of starting up blast and speed of execution on 18S
  open(LIST, $full_list_file) || ofile_FileOpenFailure($full_list_file,  "RIBO", "ribodbcreate.pl:main()", $!, "reading", $ofile_info_HH{"FH"});
  my $keep_going   = 1; 
  my $cidx         = 0; # chunk counter
  my $do_blast     = 0; # flag for whether we need to run blast on current set
  my $do_open_next = 1; # flag for whether we need to open a new chunk sequence file or not
  while($keep_going) { 
    if($do_open_next) { # open new sfetch file
      $cidx++;
      $chunk_sfetch_file = $out_root . "." . $stage_key . "." . $cidx . ".sfetch"; # name of our temporary sfetch file
      $chunk_fasta_file  = $out_root . "." . $stage_key . "." . $cidx . ".fa";     # name of our temporary fasta file
      $chunk_blast_file  = $out_root . "." . $stage_key . "." . $cidx  .".blast";  # name of our temporary blast file
      open(SFETCH, ">", $chunk_sfetch_file) || ofile_FileOpenFailure($chunk_sfetch_file,  "RIBO", "ribodbcreate.pl:main()", $!, "writing", $ofile_info_HH{"FH"});
      $cur_seqidx = 0;
      %cur_nhit_H   = ();
      $do_open_next = 0;
      $do_blast = 0;
    }
    if($seqline = <LIST>) { 
      $seq = $seqline;
      chomp($seq);
      $cur_nhit_H{$seq} = 0; # 
      $nblasted_H{$seq}++;
      print SFETCH $seqline;
      $cur_seqidx++;
      if($cur_seqidx == $chunksize) { # reached chunksize, close file and blast, below
        close(SFETCH);
        $do_blast     = 1; # set flag to blast
        $do_open_next = 1; # set flag to open new output file when we read the next seq
      }
    }
    else { # no more sequences
      close(SFETCH);
      $do_blast     = ($cur_seqidx > 0) ? 1 : 0; # set flag to blast if we have any seqs in the set
      $do_open_next = 0;                         # out of seqs, lower flag to open new output file 
      $keep_going   = 0;                         # set flag to stop reading sequences
    }
    if($do_blast) { 
      if(! $do_prvcmd) { # NOTE: this will only work if previous run used --fbcall and --keep
        $sfetch_cmd = "esl-sfetch -f $full_fasta_file $chunk_sfetch_file > $chunk_fasta_file";
        new_ribo_RunCommand($sfetch_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
        if(! $do_keep) { 
          new_ribo_RunCommand("rm $chunk_sfetch_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
        }
        $blast_cmd  = $execs_H{"blastn"} . " -num_threads 1 -subject $chunk_fasta_file -query $chunk_fasta_file -outfmt \"6 qaccver qstart qend nident length gaps pident sacc sstart send\" -max_target_seqs 1 > $chunk_blast_file";
        #$blast_cmd  = $execs_H{"blastn"} . " -num_threads 1 -subject $chunk_fasta_file -query $chunk_fasta_file -outfmt \"6 qaccver qstart qend nident length gaps pident sacc sstart send\" > $chunk_blast_file";
        new_ribo_RunCommand($blast_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
        # parse the blast output, keeping track of failures in curfailstr_H
        parse_blast_output_for_self_hits($chunk_blast_file, \%cur_nhit_H, \%curfailstr_H, \%opt_HH, $ofile_info_HH{"FH"});
        if(! $do_keep) { 
          new_ribo_RunCommand("rm $chunk_fasta_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
          new_ribo_RunCommand("rm $chunk_blast_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
        }
      }
    }
  }

  # clean up final empty sfetch file that may exist
  if((! $do_keep) && (-e $chunk_sfetch_file)) { 
    new_ribo_RunCommand("rm $chunk_sfetch_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  }

  # make sure all seqs were blasted against each other exactly once
  foreach $seq (@seqorder_A) { 
    if($nblasted_H{$seq} != 1) { 
      ofile_FAIL("ERROR in ribodbcreate.pl::main, sequence $seq was BLASTed against itself $nblasted_H{$seq} times (should be 1)", $pkgstr, $?, $ofile_info_HH{"FH"});
    }
  }

  # create pass and fail lists
  $npass = update_and_output_pass_fails(\%curfailstr_H, \%seqfailstr_H, \@seqorder_A, $out_root, $stage_key, \%ofile_info_HH);

  ofile_OutputProgressComplete($start_secs, sprintf("%6d pass; %6d fail;", $npass, $nseq-$npass), $log_FH, *STDOUT);
}

###################################################################
# 'fribos' stage: stage that filters based on ribolengthchecker.pl
###################################################################
my @rlcpass_seqorder_A = (); # order of sequences that pass rlcpass stage
if($do_fribos) { 
  $stage_key = "fribos";
  $start_secs = ofile_OutputProgressPrior("[Stage: $stage_key] Running ribolengthchecker, filtering out ribotyper FAILures", $progress_w, $log_FH, *STDOUT);
  # copy the riboopts file to the output directory
  my $riboopts_file = $out_root . ".riboopts";
  if(! $do_prvcmd) { 
    new_ribo_RunCommand("cp $in_riboopts_file $riboopts_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  }
  
  my $rlc_options = "";
  if(opt_IsUsed("-i",          \%opt_HH)) { $rlc_options .= " -i " . opt_Get("-i", \%opt_HH); }
  if(opt_IsUsed("--noscfail",  \%opt_HH)) { $rlc_options .= " --noscfail "; }
  if(opt_IsUsed("--nocovfail", \%opt_HH)) { $rlc_options .= " --nocovfail "; }
  my $rlc_out_file       = $out_root . ".ribolengthchecker";
  my $rlc_tbl_out_file   = $out_root . ".ribolengthchecker.tbl.out";
  my $local_fasta_file   = ribo_RemoveDirPath($full_fasta_file);
  my $rlc_command = $execs_H{"ribolengthchecker"} . " --riboopts $riboopts_file $rlc_options $full_fasta_file $out_root > $rlc_out_file";
  if(! $do_prvcmd) { 
    new_ribo_RunCommand($rlc_command, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  }
  ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "rlcout", "$rlc_out_file", 1, "output of ribolengthchecker");
  
  # parse ribolengthchecker tbl file
  my ($rt_npass, $rlc_npass, $ms_npass) = parse_ribolengthchecker_tbl_file($rlc_tbl_out_file, \%family_modellen_H, \%seqfailstr_H, \@seqorder_A, \@rlcpass_seqorder_A, \%opt_HH, \%ofile_info_HH);
  ofile_OutputProgressComplete($start_secs, sprintf("%6d pass; %6d fail;", $rt_npass, $nseq-$rt_npass), $log_FH, *STDOUT);

  $start_secs = ofile_OutputProgressPrior("[Stage: $stage_key] Filtering out seqs ribolengthchecker identified as too long", $progress_w, $log_FH, *STDOUT);
  ofile_OutputProgressComplete($start_secs, sprintf("%6d pass; %6d fail;", $rlc_npass, $rt_npass-$rlc_npass), $log_FH, *STDOUT);

  $stage_key = "fmspan";
  $start_secs = ofile_OutputProgressPrior("[Stage: $stage_key] Filtering out seqs based on model span", $progress_w, $log_FH, *STDOUT);
  ofile_OutputProgressComplete($start_secs, sprintf("%6d pass; %6d fail;", $ms_npass, $rlc_npass-$ms_npass), $log_FH, *STDOUT);
}
else { # skipping ribolengthchecker stage
  @rlcpass_seqorder_A = @seqorder_A; # since ribolengthchecker stage was skipped, all sequences 'survive' it
}
  
##############################################################################
# Step 6. Do the ingroup test
##############################################################################

# first, create an alignment
# TEMPORARY? of all sequences that passed ribotyper, actually I already have these, they were
# created by ribolengthchecker
# merge with esl-alimerge
if(0) { 
  my $create_list_cmd = undef;
  $start_secs = ofile_OutputProgressPrior("Determine percent identities in alignments ", $progress_w, $log_FH, *STDOUT);
  my $level = "order";
  foreach my $class (keys %family_modelname_H) { 
    my $merged_rfonly_stk_file    = $out_root . "." . $class . ".merged.rfonly.stk";
    my $merged_rfonly_alipid_file = $out_root . "." . $class . ".merged.rfonly.alipid";
    my $merged_list_file          = $out_root . "." . $class . ".merged.list";
    my $taxinfo_file              = $out_root . "." . $class . ".taxinfo.txt";
    my $taxinfo_wlevel_file       = $out_root . "." . $class . ".taxinfo_wlevel.txt";
    my $alipid_analyze_file       = $out_root . "." . $class . ".alipid.analyze.txt";
    
    my $alimerge_cmd       = "ls " . $out_root . "*" . $class . "*.stk | grep -v cmalign\.stk | esl-alimerge --list - | esl-alimask --rf-is-mask - > $merged_rfonly_stk_file";
    my $alipid_cmd         = "esl-alipid $merged_rfonly_stk_file > $merged_rfonly_alipid_file";
    my $alistat_cmd        = "esl-alistat --list $merged_list_file $merged_rfonly_stk_file > /dev/null";
    my $srcchk_cmd         = $execs_H{"srcchk"} . " -i $merged_list_file -f \'TaxId,taxname\' > $taxinfo_file";
    my $find_tax_cmd       = $execs_H{"find_taxonomy_ancestors.pl"} . " --input_summary $taxinfo_file --input_tax $taxonomy_tree_wlevels_file --input_level $level --outfile $taxinfo_wlevel_file";
    my $alipid_analyze_cmd = "perl alipid-taxinfo-analyze.pl $merged_rfonly_alipid_file $taxinfo_wlevel_file $out_root > $alipid_analyze_file";
    
    if(! $do_prvcmd) { 
      new_ribo_RunCommand($alimerge_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    }
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "merged" . $class . "rfonlystk", "$merged_rfonly_stk_file", 1, "merged RF-column-only alignment of $class sequences");
    
    if(! $do_prvcmd) { 
      new_ribo_RunCommand($alipid_cmd,         $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    }
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "merged" . $class . "alipid", "$merged_rfonly_alipid_file", 1, "esl-alipid output for $merged_rfonly_stk_file");
    
    if(! $do_prvcmd) { 
      new_ribo_RunCommand($alistat_cmd,        $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    }
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "merged" . $class . "list", "$merged_list_file", 1, "list of sequences in $merged_rfonly_stk_file");
    
    if(! $do_prvcmd) { 
      new_ribo_RunCommand($srcchk_cmd,         $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    }
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "merged" . $class . "taxinfo", "$taxinfo_file", 1, "srcchk output for sequences in $merged_list_file");
    
    if(! $do_prvcmd) { 
      new_ribo_RunCommand($find_tax_cmd,       $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    }
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "merged" . $class . "taxinfo-level", "$taxinfo_wlevel_file", 1, "taxinfo file with level for sequences in $merged_list_file");
    
    if(! $do_prvcmd) { 
      new_ribo_RunCommand($alipid_analyze_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    }
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "merged" . $class . "alipid-analyze", "$alipid_analyze_file", 1, "output file from alipid-taxinfo-analyze.pl");
  }
  ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
}


##########
# Output
##########
# output tabular output file
my $out_tbl = $out_root . ".tbl";
my $pass_fail = undef;
my $seqfailstr = undef;
open(OUT, ">", $out_tbl) || ofile_FileOpenFailure($out_tbl,  "RIBO", "ribodbcreate.pl:main()", $!, "writing", $ofile_info_HH{"FH"});
foreach $seqname (@seqorder_A) { 
  if($seqfailstr_H{$seqname} eq "") { 
    $pass_fail = "PASS";
    $seqfailstr = "-";
  }
  else { 
    $pass_fail = "FAIL";
    $seqfailstr = $seqfailstr_H{$seqname};
  }
  printf OUT ("%-5d  %-30s  %4s  %s\n", $seqidx_H{$seqname}, $seqname, $pass_fail, $seqfailstr);
}
close(OUT);
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "tbl", $out_tbl, 1, "tabular output summary file");

#system("cat $out_tbl");

##########
# Conclude
##########

$total_seconds += ribo_SecondsSinceEpoch();
ofile_OutputConclusionAndCloseFiles($total_seconds, $pkgstr, $dir, \%ofile_info_HH);
exit 0;

#################################################################
# Subroutine:  new_ribo_RunCommand()
# Incept:      EPN, Mon Dec 19 10:43:45 2016
#
# Purpose:     Runs a command using system() and exits in error 
#              if the command fails. If $be_verbose, outputs
#              the command to stdout. If $FH_HR->{"cmd"} is
#              defined, outputs command to that file handle.
#
# Arguments:
#   $cmd:         command to run, with a "system" command;
#   $be_verbose:  '1' to output command to stdout before we run it, '0' not to
#   $FH_HR:       REF to hash of file handles, including "cmd"
#
# Returns:    amount of time the command took, in seconds
#
# Dies:       if $cmd fails
#################################################################
sub new_ribo_RunCommand {
  my $sub_name = "new_ribo_RunCommand()";
  my $nargs_expected = 4;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmd, $pkgstr, $be_verbose, $FH_HR) = @_;
  
  my $cmd_FH = undef;
  if(defined $FH_HR && defined $FH_HR->{"cmd"}) { 
    $cmd_FH = $FH_HR->{"cmd"};
  }

  if($be_verbose) { 
    print ("Running cmd: $cmd\n"); 
  }

  if(defined $cmd_FH) { 
    print $cmd_FH ("$cmd\n");
  }

  my ($seconds, $microseconds) = gettimeofday();
  my $start_time = ($seconds + ($microseconds / 1000000.));

  system($cmd);

  ($seconds, $microseconds) = gettimeofday();
  my $stop_time = ($seconds + ($microseconds / 1000000.));

  if($? != 0) { 
    ofile_FAIL("ERROR in $sub_name, the following command failed:\n$cmd\n", $pkgstr, $?, $FH_HR);
  }

  return ($stop_time - $start_time);
}

#################################################################
# Subroutine:  reformat_sequence_names_in_fasta_file()
# Incept:      EPN, Tue May 29 11:24:06 2018
#
# Purpose:     Given a fasta file, create a copy of it with 
#              sequences renamed in accession.version format
#              for those sequence names that match an 
#              expected input format.
#
# Arguments:
#   $in_file:      name of input file to change names of
#   $out_file:     name of output file to create
#   $check_format: '1' to check if sequence names match expected format
#                  and die if they don't
#   $FH_HR:        REF to hash of file handles, including "cmd"
#
# Returns:    void
#
# Dies:       if a sequence name in $in_file does not match the expected
#             format and $check_format is TRUE.
#################################################################
sub reformat_sequence_names_in_fasta_file { 
  my $sub_name = "reformat_sequence_names_in_fasta_file()";
  my $nargs_expected = 4;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_file, $out_file, $check_format, $FH_HR) = (@_);

  open(IN,       $in_file)  || ofile_FileOpenFailure($in_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  open(OUT, ">", $out_file) || ofile_FileOpenFailure($out_file, "RIBO", $sub_name, $!, "writing", $FH_HR);

  while(my $line = <IN>) { 
    if($line =~ /^>(\S+)/) { 
      # header line
      my $orig_name = $1;
      my $desc = "";
      if($line =~ /^\>\S+\s+(.+)/) { 
        $desc = " " . $1;
      }
      my $new_name = ribo_ConvertFetchedNameToAccVersion($orig_name, $check_format);
      printf OUT (">%s%s\n", $new_name, $desc);
    }
    else { 
      print OUT $line; 
    }
  }
  close(OUT);
      
  return;
}

#################################################################
# Subroutine:  filter_list_file()
# Incept:      EPN, Tue May 29 15:15:42 2018
#
# Purpose:     Given a file with a list of sequences names, 
#              filter that list to make a new list file based on 
#              the values in the hash %{$value_HR}. Keep only sequences 
#              for which the value of %{$value_HR} is <= $maxvalue.
#
# Arguments:
#   $in_file:      name of input list file to filter
#   $out_file:     name of output list file to create
#   $maxvalue:     maximum value to allow in %{$HR} 
#   $value_HR:     ref to hash with values to use to determine filtering
#   $FH_HR:        REF to hash of file handles, including "cmd"
#
# Returns:    Two values: 
#             Number of sequences kept in filtered list
#             Number of sequences removed from input list
#
# Dies:       if a sequence name read in $in_file does not exist in %{$value_HR}
#################################################################
sub filter_list_file { 
  my $sub_name = "filter_list_file()";
  my $nargs_expected = 5;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_file, $out_file, $maxvalue, $value_HR, $FH_HR) = (@_);

  open(IN,       $in_file)  || ofile_FileOpenFailure($in_file,  "RIBO", "ribodbcreate.pl:main()", $!, "reading", $FH_HR);
  open(OUT, ">", $out_file) || ofile_FileOpenFailure($out_file, "RIBO", "ribodbcreate.pl:main()", $!, "writing", $FH_HR);

  my $nkept    = 0;
  my $nremoved = 0;
  while(my $line = <IN>) { 
    chomp $line;
    if($line =~ /^(\S+)/) { 
      my $seqname = $1;
      if(! exists $value_HR->{$seqname}) { 
        ofile_FAIL("ERROR in $sub_name, the following command failed:\n$cmd\n", "RIBO", $?, $FH_HR); 
      }
      if($value_HR->{$seqname} <= $maxvalue) { 
        print OUT $line .= "\n";
        $nkept++;
      }
      else { 
        $nremoved++; 
      }
    }
  }
  close(IN);
  close(OUT);
  
  return ($nkept, $nremoved);
}

#################################################################
# Subroutine:  parse_srcchk_and_tax_files_for_specified_species()
# Incept:      EPN, Tue Jun 12 13:51:51 2018
#
# Purpose:     Parse a tab delimited tax file that includes
#              as its fourth column a '1' if the sequence is
#              from a 'specified species' and '0' if it is not,
#              and save information for those that are not from 
#              specified species in %{$failstr_HR}.
#
# Arguments:
#   $srcchk_file:    name of srcchk output file to parse
#   $tax_file:       name of tax file to parse
#   $seqfailstr_HR:  ref to hash of failure string to add to here
#   $seqorder_AR:    ref to array of sequences in order
#   $out_root:       for naming output files
#   $opt_HHR:        reference to 2D hash of cmdline options
#   $ofile_info_HHR: ref to the ofile info 2D hash
#
# Returns:    Number of sequences that pass.
#
# Dies:       if a sequence is not in the $tax_file
#################################################################
sub parse_srcchk_and_tax_files_for_specified_species { 
  my $sub_name = "parse_srcchk_and_tax_files_for_specified_species";
  my $nargs_expected = 7;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($srcchk_file, $tax_file, $seqfailstr_HR, $seqorder_AR, $out_root, $opt_HHR, $ofile_info_HHR) = (@_);

  my %specified_species_H = ();
  my %curfailstr_H = ();  # will hold fail string 
  my $FH_HR = $ofile_info_HHR->{"FH"}; # for convenience
  my $seqname;

  initialize_hash_to_empty_string(\%curfailstr_H, $seqorder_AR);

  # PASS 1 of 2 through srrchk_file to initialize specified_species_H{} with keys of taxids we
  # need to parse in $tax-file (initialize values for all keys to -1)
  open(SRCCHK, $srcchk_file)  || ofile_FileOpenFailure($srcchk_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  # first line is header
  my $line = <SRCCHK>;
  while($line = <SRCCHK>) { 
    #accessiontaxidorganism
    #KJ925573.1100272uncultured eukaryote
    #FJ552229.1221169uncultured Gemmatimonas sp.
    chomp $line;
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 3) { 
      ofile_FAIL("ERROR in $sub_name, srcchk file line did not have exactly 3 tab-delimited tokens: $line\n", "RIBO", $?, $FH_HR);
    }
    my ($accver, $taxid, $organism) = @el_A;
    $specified_species_H{$taxid} = -1;
  }
  close(SRCCHK);

  # PASS 1 of 1 through tax_file to fill specified_species_H{} for existing taxid keys read from srcchk_file
  open(TAX, $tax_file) || ofile_FileOpenFailure($tax_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  while($line = <TAX>) { 
    #11no rank0
    #2131567superkingdom0
    #6335928genus0
    #76species1
    chomp $line;
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 4) { 
      ofile_FAIL("ERROR in $sub_name, tax file line did not have exactly 4 tab-delimited tokens: $line\n", "RIBO", $?, $FH_HR);
    }
    my ($taxid, $parent_taxid, $rank, $specified_species) = @el_A;
    if(exists $specified_species_H{$taxid}) { 
      $specified_species_H{$taxid} = $specified_species; 
    }
  }
  close(SRCCHK);
    
  # PASS 2 of 2 through srrchk_file to determine if each sequence passes or fails
  open(SRCCHK, $srcchk_file)  || ofile_FileOpenFailure($srcchk_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  # first line is header
  my $diestr = ""; # if we add to this below for >= 1 sequences, we will fail after going through the full file
  $line = <SRCCHK>;
  while($line = <SRCCHK>) { 
    #accessiontaxidorganism
    #KJ925573.1100272uncultured eukaryote
    #FJ552229.1221169uncultured Gemmatimonas sp.
    chomp $line;
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 3) { 
      ofile_FAIL("ERROR in $sub_name, srcchk file line did not have exactly 3 tab-delimited tokens: $line\n", "RIBO", $?, $FH_HR);
    }
    my ($accver, $taxid, $organism) = @el_A;
    if($specified_species_H{$taxid} == -1) { 
      $diestr .= "taxid: $taxid, accession: $accver\n";
    }
    elsif($specified_species_H{$taxid} == 0) { 
      $curfailstr_H{$accver} = "not-specified-species";
    }
    elsif($specified_species_H{$taxid} != 1) { 
      ofile_FAIL("ERROR in $sub_name, tax file had unexpected value (not '0' or '1') for specified species for taxid $taxid ($accver)", "RIBO", $?, $FH_HR);
    }
  }
  close(SRCCHK);

  if($diestr ne "") { 
    ofile_FAIL("ERROR in $sub_name, >= 1 taxids for sequences in sequence file had no tax information in $tax_file:\n$diestr", "RIBO", $?, $FH_HR);
  }

  # now output pass and fail files
  return update_and_output_pass_fails(\%curfailstr_H, $seqfailstr_HR, $seqorder_AR, $out_root, "ftaxid", $ofile_info_HHR);
  
}

#################################################################
# Subroutine:  parse_parse_vecscreen_combined_files()
# Incept:      EPN, Wed Jun 20 15:05:28 2018
#
# Purpose:     Parse output file from parse_vecscreen.pl followed
#              by combine_summaries.pl.
#
# Arguments:
#   $parse_vecscreen_combined_file: name of parse_vecscreen_combined output file
#   $seqfailstr_HR:                 ref to hash of failure string to add to here
#   $seqorder_AR:                   ref to array of sequences in order
#   $out_root:                      for naming output files
#   $opt_HHR:                       reference to 2D hash of cmdline options
#   $ofile_info_HHR:                ref to the ofile info 2D hash
#
# Returns:    Number of sequences that pass.
#
# Dies:       if a sequence in $parse_vecscreen_combined_file is not in @{$seqorder_AR}
#################################################################
sub parse_parse_vecscreen_combined_file { 
  my $sub_name = "parse_parse_vecscreen_combined_file()";
  my $nargs_expected = 6;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($parse_vecscreen_combined_file, $seqfailstr_HR, $seqorder_AR, $out_root, $opt_HHR, $ofile_info_HHR) = (@_);

  my %curfailstr_H = ();  # will hold fail string 
  my $FH_HR = $ofile_info_HHR->{"FH"}; # for convenience
  my $seqname;

  initialize_hash_to_empty_string(\%curfailstr_H, $seqorder_AR);

  open(VEC, $parse_vecscreen_combined_file)  || ofile_FileOpenFailure($parse_vecscreen_combined_file, "RIBO", $sub_name, $!, "reading", $FH_HR);
  #AY803752.1	3	18	uv|DQ391279.1:11528-12003	345	360	Weak	Weak	Suspect[1,2];
  while(my $line = <VEC>) { 
    chomp $line;
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 9) { 
      ofile_FAIL("ERROR in $sub_name, parse_vecscreen combined output line in $parse_vecscreen_combined_file does not have the expected 9 tab-delimited fields\n", "RIBO", $?, $FH_HR); 
    }
    my ($seqname, $strength) = ($el_A[0], $el_A[6]);
    if($el_A[6] ne "Weak") { 
      $curfailstr_H{$seqname} = "vecscreen-match[$strength];";
    }
  }
  close(VEC);

  # now output pass and fail files
  return update_and_output_pass_fails(\%curfailstr_H, $seqfailstr_HR, $seqorder_AR, $out_root, "fvecsc", $ofile_info_HHR);
  
  return;
}

#################################################################
# Subroutine:  parse_ribolengthchecker_tbl_file()
# Incept:      EPN, Wed May 30 14:11:47 2018
#
# Purpose:     Parse a tbl output file from ribolengthchecker.pl
#
# Arguments:
#   $in_file:             name of input tbl file to parse
#   $mlen_HR:             ref to hash of model lengths, key is value in classification
#                         column of $in_file
#   $seqfailstr_HR:       ref to hash of failure string to add to here
#   $seqorder_AR:         ref to array of sequences in order
#   $rlcpass_seqorder_AR: ref to array of sequences in order
#   $opt_HHR:             ref to 2D hash of cmdline options
#   $ofile_info_HHR:      ref to the ofile info 2D hash
#
# Returns:    3 values:
#             $rt_npass:  number of sequences that pass ribotyper stage
#             $rlc_npass: number of sequences that pass ribolengthchecker stage
#             $ms_npass:  number of sequences that pass model span stage
#
# Dies:       if options are unexpected
#             if unable to parse a tabular line
#             in there's no model length for an observed classification
# 
#################################################################
sub parse_ribolengthchecker_tbl_file { 
  my $sub_name = "parse_ribolengthchecker_tbl_file()";
  my $nargs_expected = 7;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_file, $mlen_HR, $seqfailstr_HR, $seqorder_AR, $rlcpass_seqorder_AR, $opt_HHR, $ofile_info_HHR) = (@_);

  my %rt_curfailstr_H  = (); # holds fail strings for ribotyper
  my %rlc_curfailstr_H = (); # holds fail strings for ribolengthchecker
  my %ms_curfailstr_H  = (); # holds fail strings for model span stage
  my @rtpass_seqorder_A = (); # array of sequences that pass ribotyper stage, in order
  my $FH_HR = $ofile_info_HHR->{"FH"}; # for convenience

  initialize_hash_to_empty_string(\%rt_curfailstr_H,  $seqorder_AR);
  # for %rlc_curfailstr_H, we only do pass/fail for those that survive ribotyper
  # for %ms_curfailstr_H,  we only do pass/fail for those that survive ribotyper and ribolengthchecker
  # so we can't initialize those yet, we will fill in the FAILs and PASSes as we see them in the output

  my $in_pos  = undef;
  my $in_lpos = undef;
  my $in_rpos = undef;
  if(opt_IsUsed("--pos",  \%opt_HH)) { $in_pos  = opt_Get("--pos", \%opt_HH); }
  if(opt_IsUsed("--lpos", \%opt_HH)) { $in_lpos = opt_Get("--lpos", \%opt_HH); }
  if(opt_IsUsed("--rpos", \%opt_HH)) { $in_rpos = opt_Get("--rpos", \%opt_HH); }

  # determine maximum 5' start position and minimum 3' stop position required to be kept
  # for each family
  my %max_lpos_H = ();
  my %min_rpos_H = ();
  foreach my $class (keys (%{$mlen_HR})) { 
    if(defined $in_pos) { 
      $max_lpos_H{$class} = $in_pos;
      $min_rpos_H{$class} = $mlen_HR->{$class} - $in_pos + 1;
    }
    else { 
      if((! defined $in_lpos) || (! defined $in_rpos)) { 
        ofile_FAIL("ERROR in $sub_name, --pos not used, but at least one of --lpos or --rpos not used either", "RIBO", $?, $FH_HR);
      }
      $max_lpos_H{$class} = $in_lpos;
      $min_rpos_H{$class} = $in_rpos;
    }
  }

  # parse each line of the output file
  open(IN, $in_file)  || ofile_FileOpenFailure($in_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  my $nlines = 0;

  while(my $line = <IN>) { 
    ##idx  target      classification         strnd   p/f  mstart   mstop  length_class  unexpected_features
    ##---  ----------  ---------------------  -----  ----  ------  ------  ------------  -------------------
    #1     Z36893.1    SSU.Eukarya            plus   PASS       1    1851    full-exact  -
    #2     Z26765.1    SSU.Eukarya            plus   PASS       1    1851    full-exact  -
    #3     X74753.1    SSU.Eukarya            plus   FAIL       -       -             -  *LowCoverage:(0.831<0.860);MultipleHits:(2);
    #4     X51542.1    SSU.Eukarya            plus   FAIL       -       -             -  *LowScore:(0.09<0.50);*LowCoverage:(0.085<0.860);
    #5     X66111.1    SSU.Eukarya            plus   FAIL       -       -             -  *LowScore:(0.01<0.50);*LowCoverage:(0.019<0.860);
    #6     X56532.1    SSU.Eukarya            plus   PASS       1    1849       partial  -
    #7     AY572456.1  SSU.Eukarya            plus   PASS       1    1851    full-exact  -
    #8     AY364851.1  SSU.Eukarya            plus   PASS      35    1816       partial  -
    if($line !~ m/^\#/) { 
      chomp $line;
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 9) { 
        ofile_FAIL("ERROR in $sub_name, rlc tblout file line did not have exactly 9 space-delimited tokens: $line\n", "RIBO", $?, $FH_HR);
      }
      my ($idx, $target, $class, $strand, $passfail, $mstart, $mstop, $lclass, $ufeatures) = @el_A;
      $nlines++;

      # add to failstr if necessary
      if($passfail eq "FAIL") { 
        $rt_curfailstr_H{$target} = "ribotyper[" . $ufeatures . "]";
      }
      else { # $passfail eq "PASS"
        # check for ribolengthchecker fail
        if(($lclass eq "full-extra") || ($lclass eq "full-ambig")) { 
          $rlc_curfailstr_H{$target} = "ribolengthchecker[" . $lclass . "]";
        }
        else { 
          $rlc_curfailstr_H{$target} = "";
          
          # check for model span fail
          if((! exists $max_lpos_H{$class}) || (! exists $min_rpos_H{$class})) { 
            ofile_FAIL("ERROR in $sub_name, unexpected classification $class", "RIBO", $?, $FH_HR);
          }
          if(($mstart > $max_lpos_H{$class}) || ($mstop < $min_rpos_H{$class})) { 
            $ms_curfailstr_H{$target} = "mdlspan[" . $mstart . "-" . $mstop . "]";
          }
          else { 
            $ms_curfailstr_H{$target} = "";
          }
        }
      }
    }
  }
  close(IN);
  
  # fill @rtpass_seqorder_A and @{$rlcpass_seqorder_AR}
  @rtpass_seqorder_A     = ();
  @{$rlcpass_seqorder_AR} = ();
  my $seqname;
  foreach $seqname (@{$seqorder_AR}) { 
    if(exists $rlc_curfailstr_H{$seqname}) { 
      push(@rtpass_seqorder_A, $seqname); 
    }
    if(exists $ms_curfailstr_H{$seqname}) { 
      push(@{$rlcpass_seqorder_AR}, $seqname);
    }
  }

  my $rt_npass  = update_and_output_pass_fails(\%rt_curfailstr_H,  $seqfailstr_HR, $seqorder_AR,         $out_root, "fribty", \%ofile_info_HH);
  my $rlc_npass = update_and_output_pass_fails(\%rlc_curfailstr_H, $seqfailstr_HR, \@rtpass_seqorder_A,  $out_root, "friblc", \%ofile_info_HH);
  my $ms_npass  = update_and_output_pass_fails(\%ms_curfailstr_H,  $seqfailstr_HR, $rlcpass_seqorder_AR, $out_root, "fmspan", \%ofile_info_HH);

  return ($rt_npass, $rlc_npass, $ms_npass);
}

#################################################################
# Subroutine:  parse_blast_output_for_self_hits()
# Incept:      EPN, Wed Jun 13 15:21:14 2018
#
# Purpose:     Parse a blast output file that should have only self hits in it 
#              because the query and subject were identical files and the 
#              '-max_target_seqs 1' flag was used.
#
# Arguments:
#   $in_file:      name of input blast output file to parse
#   $nhit_HR:      ref to hash, keys are expected sequence names, values are '1'
#   $failstr_HR:   ref to hash of failure string to add to here
#   $opt_HHR:      reference to 2D hash of cmdline options
#   $FH_HR:        REF to hash of file handles, including "cmd"
#
# Returns:    Number of sequences that pass (do not have self hits)
#
# Dies:       if blast output is not in expected format (number of fields)
#             if any of the sequences in nhit_HR are not in the blast output
#             if any of the sequences in nhit_HR do not have a full length self hit in the blast output
# 
#################################################################
sub parse_blast_output_for_self_hits { 
  my $sub_name = "parse_blast_output_for_self_hits()";
  my $nargs_expected = 5;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_file, $nhit_HR, $failstr_HR, $top_HHR, $FH_HR) = (@_);

  my %local_failstr_H = (); # fail string created in this subroutine for each sequence

  open(IN, $in_file)  || ofile_FileOpenFailure($in_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  while(my $line = <IN>) { 
    # print "read line: $line";
    chomp $line;
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 10) { 
      ofile_FAIL("ERROR in $sub_name, did not read 10 tab-delimited columns on line $line", "RIBO", 1, $FH_HR); 
    }
    
    my ($qaccver, $qstart, $qend, $nident, $length, $gaps, $pident, $sacc, $sstart, $send) = @el_A;
    my $qlen;   # length of hit on query
    my $slen;   # length of hit on subject
    my $maxlen; # max of $qlen and $slen

    # is this a self-hit? NOTE: we tried '-max_target_seqs 1' previously to enforce this was true but it doesn't work
    # if one sequence is a subsequence of another you're not guaranteed to that the target selected will be self (example: KX765300.1 and MG520988.1)
    if($qaccver eq $sacc) { 
      # sanity check: query/subject should be to a sequence we expect
      if(! exists $nhit_HR->{$qaccver}){ 
        ofile_FAIL("ERROR in $sub_name, found unexpected query $qaccver:\n$line", "RIBO", 1, $FH_HR); 
      }
      if(! exists $nhit_HR->{$sacc}){ 
        ofile_FAIL("ERROR in $sub_name, found unexpected subject $sacc:\n$line", "RIBO", 1, $FH_HR); 
      }
      $nhit_HR->{$qaccver}++;
      
      # determine if this is a self hit (qstart == sstart and qend == send) or a repeat (qstart != sstart || qend != send)
      if(($qstart != $sstart) || ($qend != $send)) { 
        # repeat, should we keep information on it? don't want to double count (repeat his will occur twice), so we
        # use a simple rule to only pick one:
        if($qstart <= $sstart) { 
          $qlen = abs($qstart - $qend) + 1;
          $slen = abs($sstart - $send) + 1;
          $maxlen = ($qlen > $slen) ? $qlen : $slen;
          # store information on it
          if(exists $local_failstr_H{$qaccver}) { 
            $local_failstr_H{$qaccver} .= ","; 
          }
          else { 
            $local_failstr_H{$qaccver} = ""; 
          }
          # now append the info
          $local_failstr_H{$qaccver} .= "$maxlen:$qstart..$qend/$sstart..$send($pident|$gaps)";
        }
      }
    }
  }
  close(IN);

  # final sanity check, each seq should have had at least 1 hit
  # and also fill $failstr_HR:
  foreach my $key (keys %{$expseq_HR}) { 
    if($nhit_HR->{$key} == 0) { 
      ofile_FAIL("ERROR in $sub_name, found zero hits to query $key", "RIBO", 1, $FH_HR); 
    }
    if(exists $local_failstr_H{$key}) { 
      $failstr_HR->{$key} .= "blastrepeat[$local_failstr_H{$key}];";
    }
  }

  return;
}

#################################################################
# Subroutine:  OLD_parse_blast_output_for_self_hits()
# Incept:      EPN, Wed Jun 13 15:21:14 2018
#
# Purpose:     Parse a blast output file that should have only self hits in it 
#              because the query and subject were identical files and the 
#              '-max_target_seqs 1' flag was used.
#
# Arguments:
#   $in_file:      name of input blast output file to parse
#   $nhit_HR:      ref to hash, keys are expected sequence names, values are '1'
#   $failstr_HR:   ref to hash of failure string to add to here
#   $opt_HHR:      reference to 2D hash of cmdline options
#   $FH_HR:        REF to hash of file handles, including "cmd"
#
# Returns:    Number of sequences that pass (do not have self hits)
#
# Dies:       if blast output is not in expected format (number of fields)
#             if any of the sequences in expseq_HR are not in the blast output
#             if any of the sequences in expseq_HR do not have a full length self hit in the blast output
# 
#################################################################
sub OLD_parse_blast_output_for_self_hits { 
  my $sub_name = "OLD_parse_blast_output_for_self_hits()";
  my $nargs_expected = 5;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_file, $nhit_HR, $failstr_HR, $top_HHR, $FH_HR) = (@_);

  my %local_failstr_H = (); # fail string created in this subroutine for each sequence

  open(IN, $in_file)  || ofile_FileOpenFailure($in_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  while(my $line = <IN>) { 
    # print "read line: $line";
    chomp $line;
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 10) { 
      ofile_FAIL("ERROR in $sub_name, did not read 10 tab-delimited columns on line $line", "RIBO", 1, $FH_HR); 
    }
    
    my ($qaccver, $qstart, $qend, $nident, $length, $gaps, $pident, $sacc, $sstart, $send) = @el_A;
    my $qlen;   # length of hit on query
    my $slen;   # length of hit on subject
    my $maxlen; # max of $qlen and $slen

    # two sanity checks: 
    # 1: query and subject should be sequences we expect ($nhit_HR->{} exists)
    # 2: hit should be to self (due to -max_target_nseqs 1 flag)
    #    OR if not, if it's the first hit it should be 100% identical.
    #    It is possible the top hit will be to another seq IFF
    #    that sequence is identical to the query or a supersequence of the query, either
    #    way we should be okay because we'd still be detecting 'self-hits' due to the 100%
    #    identity
    if($qaccver ne $sacc) { 
      if(($nhit_HR->{$qaccver} == 0) && ($pident ne "100.000")) { 
        ofile_FAIL("ERROR in $sub_name, not a self hit OR top hit and not 100 percent identity in blast output (with -max_target_seqs 1) line:\n$line", "RIBO", 1, $FH_HR); 
      }
    }
    $nhit_HR->{$qaccver}++; 

    # determine if this is a self hit (qstart == sstart and qend == send) or a repeat (qstart != sstart || qend != send)
    if(($nhit_HR->{$qaccver} != ($qstart != $sstart) || ($qend != $send)) { 
      # repeat, should we keep information on it? don't want to double count (repeat his will occur twice), so we
      # use a simple rule to only pick one:
      if($qstart <= $sstart) { 
        $qlen = abs($qstart - $qend) + 1;
        $slen = abs($sstart - $send) + 1;
        $maxlen = ($qlen > $slen) ? $qlen : $slen;
        # store information on it
        if(exists $local_failstr_H{$qaccver}) { 
          $local_failstr_H{$qaccver} .= ","; 
        }
        else { 
          $local_failstr_H{$qaccver} = ""; 
        }
        # now append the info
        $local_failstr_H{$qaccver} .= "$maxlen:$qstart..$qend/$sstart..$send($pident|$gaps)";
      }
    }
  }
  close(IN);

  # final sanity check, each seq should have had at least 1 hit
  # and also fill $failstr_HR:
  foreach my $key (keys %{$expseq_HR}) { 
    if($expseq_HR->{$key} != 0) { 
      ofile_FAIL("ERROR in $sub_name, found zero hits to query $key", "RIBO", 1, $FH_HR); 
    }
    if(exists $local_failstr_H{$key}) { 
      $failstr_HR->{$key} .= "blastrepeat[$local_failstr_H{$key}];";
    }
  }

  return;
}


#################################################################
# Subroutine:  update_and_output_pass_fails()
# Incept:      EPN, Wed Jun 20 12:43:14 2018
#
# Purpose:     Given a hash of currently failure strings for all
#              sequences, in which sequences that pass have a "" value,
#              Update %{$seqfailstr_H} by adding the current failure
#              strings in %{$curfailstr_H} and output a file listing all
#              sequences that passed, and a file listing all sequences
#              that failed this stage.
#
# Arguments:
#   $curfailstr_HR:  ref to hash of current fail strings
#   $seqfailstr_HR:  ref to hash of full fail strings, to add to
#   $seqorder_AR:    ref to array of sequence order
#   $out_root:       string for naming output files
#   $stage_key:      string that explains a stage
#   $ofile_info_HHR: ref to the ofile info 2D hash
#
# Returns:    Number of sequences that pass.
#
# Dies:       if $curfailstr_HR->{$key} does not exist for an expected $key from @{$seqorder_AR}
#             if $seqfailstr_HR->{$key} does not exist for an expected $key from @{$seqorder_AR}
# 
#################################################################
sub update_and_output_pass_fails { 
  my $sub_name = "update_and_output_pass_fails()";
  my $nargs_expected = 6;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($curfailstr_HR, $seqfailstr_HR, $seqorder_AR, $out_root, $stage_key, $ofile_info_HHR) = (@_);

  my %pass_H = (); # temporary hash refilled per stage, key is sequence name, value is '1' if passes filter, '0' if fails
  my $npass   = 0;  # number of sequences that passed current stage
  my $nfail   = 0;  # number of sequences that failed current stage
  my $seqname = undef; 
  my $FH_HR = $ofile_info_HHR->{"FH"}; # for convenience

  foreach $seqname (@{$seqorder_AR}) { 
    if(! exists $curfailstr_HR->{$seqname}) { ofile_FAIL("ERROR in $sub_name, sequence $seqname not in curfailstr_HR hash", "RIBO", 1, $FH_HR); }
    if(! exists $seqfailstr_HR->{$seqname}) { ofile_FAIL("ERROR in $sub_name, sequence $seqname not in seqfailstr_HR hash", "RIBO", 1, $FH_HR); }
    if($curfailstr_HR->{$seqname} ne "") { 
      $seqfailstr_HR->{$seqname} .= $curfailstr_HR->{$seqname};
      $pass_H{$seqname} = 0;
      $nfail++;
    }
    else { 
      $pass_H{$seqname} = 1;
      $npass++;
    }
  }
  
  my $pass_file = $out_root . "." . $stage_key . ".pass.list";
  my $fail_file = $out_root . "." . $stage_key . ".fail.list";

  open(PASS, ">", $pass_file) || ofile_FileOpenFailure($pass_file,  "RIBO", $sub_name, $!, "writing", $FH_HR);
  open(FAIL, ">", $fail_file) || ofile_FileOpenFailure($fail_file,  "RIBO", $sub_name, $!, "writing", $FH_HR);
  foreach $seqname (@{$seqorder_AR}) { 
    if($pass_H{$seqname}) { print PASS $seqname . "\n"; }
    else                  { print FAIL $seqname . "\n"; }
  }
  close(PASS);
  close(FAIL);

  ofile_AddClosedFileToOutputInfo($ofile_info_HHR, "RIBO", $stage_key . ".pass.list", "$pass_file", 1, "sequences that PASSed $stage_key stage [$npass]");
  ofile_AddClosedFileToOutputInfo($ofile_info_HHR, "RIBO", $stage_key . ".fail.list", "$fail_file", 1, "sequences that FAILed $stage_key stage [$nfail]");

  return $npass;
}

#################################################################
# Subroutine:  initialize_hash_to_empty_string()
# Incept:      EPN, Wed Jun 20 14:29:28 2018
#
# Purpose:     Initialize all values of a hash to the empty string.
#
# Arguments:
#   $HR:  ref to hash to fill with empty string values for all keys in @{$AR}
#   $AR:  ref to array with all keys to create for $HR
#
# Returns:    void
#
# Dies: void
# 
#################################################################
sub initialize_hash_to_empty_string {
  my $sub_name = "initialize_hash_to_empty_string()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($HR, $AR) = (@_);

  %{$HR} = (); 
  foreach my $key (@{$AR}) { 
    $HR->{$key} = "";
  }

  return;
}
