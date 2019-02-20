#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

# ribosensor.pl :: analyze ribosomal RNA sequences with profile HMMs and BLASTN
# Usage: ribosensor.pl [-options] <fasta file to annotate> <output directory>\n";

require "epn-options.pm";
require "epn-ofile.pm";
require "ribo.pm";

# make sure required environment variables are set
my $env_ribotyper_dir    = ribo_VerifyEnvVariableIsValidDir("RIBODIR");
my $env_sensor_dir       = ribo_VerifyEnvVariableIsValidDir("SENSORDIR");
my $env_riboinfernal_dir = ribo_VerifyEnvVariableIsValidDir("RIBOINFERNALDIR");
my $env_riboeasel_dir    = ribo_VerifyEnvVariableIsValidDir("RIBOEASELDIR");
my $env_riboblast_dir    = ribo_VerifyEnvVariableIsValidDir("RIBOBLASTDIR");
my $env_ribotime_dir     = ribo_VerifyEnvVariableIsValidDir("RIBOTIMEDIR");
my $df_model_dir         = $env_ribotyper_dir . "/models/";

my %execs_H = (); # hash with paths to all required executables
$execs_H{"ribo"}               = $env_ribotyper_dir . "/ribotyper.pl";
$execs_H{"rRNA_sensor_script"} = $env_sensor_dir    . "/rRNA_sensor_script";
$execs_H{"esl-seqstat"}        = $env_riboeasel_dir . "/esl-seqstat";
$execs_H{"esl-sfetch"}         = $env_riboeasel_dir . "/esl-sfetch";
$execs_H{"blastn"}             = $env_riboblast_dir . "/blastn";
$execs_H{"blastdbcmd"}         = $env_riboblast_dir . "/blastdbcmd";
$execs_H{"time"}               = $env_ribotime_dir  . "/time";
ribo_ValidateExecutableHash(\%execs_H);


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
# Group 2 optional arguments are passed directly to sensor and are irrelevant to ribotyper
# Group 1 and group 3 optional arguments are not specific to sensor or ribotyper
# This section needs to be kept in sync (manually) with the &GetOptions call below
$opt_group_desc_H{"1"} = "basic options";
#     option            type       default               group   requires incompat    preamble-output                                    help-output    
opt_Add("-h",           "boolean", 0,                        0,    undef, undef,      undef,                                               "display this help",                                       \%opt_HH, \@opt_order_A);
opt_Add("-f",           "boolean", 0,                        1,    undef, undef,      "forcing directory overwrite",                       "force; if <output directory> exists, overwrite it",       \%opt_HH, \@opt_order_A);
opt_Add("-m",           "string",  "16S",                    1,    undef, undef,      "set mode to <s>",                                   "set mode to <s>, possible <s> values are \"16S\" and \"18S\"", \%opt_HH, \@opt_order_A);
opt_Add("-c",           "boolean", 0,                        1,    undef, undef,      "assert that sequences are from cultured organisms", "assert that sequences are from cultured organisms",            \%opt_HH, \@opt_order_A);
opt_Add("-n",           "integer", 0,                        1,    undef, "-p",       "use <n> CPUs",                                      "use <n> CPUs",                                            \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                                        "be verbose; output commands to stdout as they're run",    \%opt_HH, \@opt_order_A);
opt_Add("-i",           "string",  undef,                    1,    undef, undef,      "use model info file <s> instead of default",        "use model info file <s> instead of default",              \%opt_HH, \@opt_order_A);
opt_Add("--keep",       "boolean", 0,                        1,    undef, undef,      "keep all intermediate files",                       "keep all intermediate files that are removed by default", \%opt_HH, \@opt_order_A);
opt_Add("--skipsearch", "boolean", 0,                        1,    undef,  "-f",      "skip search stages, use results from earlier run",  "skip search stages, use results from earlier run",        \%opt_HH, \@opt_order_A);
$opt_group_desc_H{"2"} = "rRNA_sensor related options";
opt_Add("--Sminlen",    "integer", 100,                      2,    undef, undef,      "set rRNA_sensor minimum seq length to <n>",                      "set rRNA_sensor minimum sequence length to <n>", \%opt_HH, \@opt_order_A);
opt_Add("--Smaxlen",    "integer", 2000,                     2,    undef, undef,      "set rRNA_sensor maximum seq length to <n>",                      "set rRNA_sensor minimum sequence length to <n>", \%opt_HH, \@opt_order_A);
opt_Add("--Smaxevalue",    "real", 1e-40,                    2,    undef, undef,      "set rRNA_sensor maximum E-value to <x>",                         "set rRNA_sensor maximum E-value to <x>", \%opt_HH, \@opt_order_A);
opt_Add("--Sminid1",    "integer", 75,                       2,    undef, undef,      "set rRNA_sensor min percent id for seqs <= 350 nt to <n>",       "set rRNA_sensor minimum percent id for seqs <= 350 nt to <n>", \%opt_HH, \@opt_order_A);
opt_Add("--Sminid2",    "integer", 80,                       2,    undef, undef,      "set rRNA_sensor min percent id for seqs [351..600] nt to <n>",   "set rRNA_sensor minimum percent id for seqs [351..600] nt to <n>", \%opt_HH, \@opt_order_A);
opt_Add("--Sminid3",    "integer", 86,                       2,    undef, undef,      "set rRNA_sensor min percent id for seqs > 600 nt to <n>",        "set rRNA_sensor minimum percent id for seqs > 600 nt to <n>", \%opt_HH, \@opt_order_A);
opt_Add("--Smincovall", "integer", 10,                       2,    undef, undef,      "set rRNA_sensor min percent coverage for all sequences to <n>",  "set rRNA_sensor minimum coverage for all sequences to <n>", \%opt_HH, \@opt_order_A);
opt_Add("--Smincov1",   "integer", 80,                       2,    undef, undef,      "set rRNA_sensor min percent coverage for seqs <= 350 nt to <n>", "set rRNA_sensor minimum coverage for seqs <= 350 nt to <n>", \%opt_HH, \@opt_order_A);
opt_Add("--Smincov2",   "integer", 86,                       2,    undef, undef,      "set rRNA_sensor min percent coverage for seqs  > 350 nt to <n>", "set rRNA_sensor minimum coverage for seqs  > 350 nt to <n>", \%opt_HH, \@opt_order_A);
$opt_group_desc_H{"3"} = "options for saving sequence subsets to files";
opt_Add("--psave",       "boolean",0,                        3,    undef, undef,      "save passing sequences to a file",                              "save passing sequences to a file", \%opt_HH, \@opt_order_A);
$opt_group_desc_H{"4"} = "options for parallelizing cmsearch on a compute farm";
#     option            type       default                group   requires incompat    preamble-output                                                help-output    
opt_Add("-p",           "boolean", 0,                         4,    undef, undef,      "parallelize ribotyper and rRNA_sensor on a compute farm",     "parallelize ribotyper and rRNA_sensor on a compute farm",              \%opt_HH, \@opt_order_A);
opt_Add("-q",           "string",  undef,                     4,     "-p", undef,      "use qsub info file <s> instead of default",                   "use qsub info file <s> instead of default", \%opt_HH, \@opt_order_A);
opt_Add("-s",           "integer", 181,                       4,     "-p", undef,      "seed for random number generator is <n>",                     "seed for random number generator is <n>", \%opt_HH, \@opt_order_A);
opt_Add("--nkb",        "integer", 100,                       4,     "-p", undef,      "number of KB of seq for each farm job is <n>",                "number of KB of sequence for each farm job is <n>", \%opt_HH, \@opt_order_A);
opt_Add("--wait",       "integer", 500,                       4,     "-p", undef,      "allow <n> minutes for jobs on farm",                          "allow <n> wall-clock minutes for jobs on farm to finish, including queueing time", \%opt_HH, \@opt_order_A);
opt_Add("--errcheck",   "boolean", 0,                         4,     "-p", undef,      "consider any farm stderr output as indicating a job failure", "consider any farm stderr output as indicating a job failure", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: ribosensor.pl [-options] <fasta file to annotate> <output directory>\n";
$usage      .= "\n";
my $synopsis = "ribosensor.pl :: analyze ribosomal RNA sequences with profile HMMs and BLASTN";
my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"}, 
                'f'            => \$GetOptions_H{"-f"},
                'm=s'          => \$GetOptions_H{"-m"},
                'c'            => \$GetOptions_H{"-c"},
                'n=s'          => \$GetOptions_H{"-n"},
                'v'            => \$GetOptions_H{"-v"},
                'i=s'          => \$GetOptions_H{"-i"},
                'keep'         => \$GetOptions_H{"--keep"}, 
                'skipsearch'   => \$GetOptions_H{"--skipsearch"},
                'Sminlen=s'    => \$GetOptions_H{"--Sminlen"}, 
                'Smaxlen=s'    => \$GetOptions_H{"--Smaxlen"}, 
                'Smaxevalue=s' => \$GetOptions_H{"--Smaxevalue"}, 
                'Sminid1=s'    => \$GetOptions_H{"--Sminid1"}, 
                'Sminid2=s'    => \$GetOptions_H{"--Sminid2"}, 
                'Sminid3=s'    => \$GetOptions_H{"--Sminid3"},
                'Smincovall=s' => \$GetOptions_H{"--Smincovall"},
                'Smincov1=s'   => \$GetOptions_H{"--Smincov1"},
                'Smincov2=s'   => \$GetOptions_H{"--Smincov2"},
                'psave'        => \$GetOptions_H{"--psave"},
# options for parallelization
                'p'            => \$GetOptions_H{"-p"},
                'q=s'          => \$GetOptions_H{"-q"},
                's=s'          => \$GetOptions_H{"-s"},
                'nkb=s'        => \$GetOptions_H{"--nkb"},
                'wait=s'       => \$GetOptions_H{"--wait"},
                'errcheck'     => \$GetOptions_H{"--errcheck"});

my $total_seconds          = -1 * ribo_SecondsSinceEpoch(); # by multiplying by -1, we can just add another ribo_SecondsSinceEpoch call at end to get total time
my $executable        = $0;
my $date              = scalar localtime();
my $version           = "0.36";
my $model_version_str = "0p30"; # model info file unchanged since version 0.30
my $qsub_version_str  = "0p32"; # for qsubinfo file only
my $releasedate       = "Feb 2019";
my $package_name      = "ribovore";
my $pkgstr            = "RIBO";

# make *STDOUT file handle 'hot' so it automatically flushes whenever we print to it
select *STDOUT;
$| = 1;

# print help and exit if necessary
if((! $options_okay) || ($GetOptions_H{"-h"})) { 
  ofile_OutputBanner(*STDOUT, $package_name, $version, $releasedate, $synopsis, $date, undef);
  opt_OutputHelp(*STDOUT, $usage, \%opt_HH, \@opt_order_A, \%opt_group_desc_H);
  if(! $options_okay) { die "ERROR, unrecognized option;"; }
  else                { exit 0; } # -h, exit with 0 status
}

# check that number of command line args is correct
if(scalar(@ARGV) != 2) {   
  print "Incorrect number of command line arguments.\n";
  print $usage;
  print "\nTo see more help on available options, do dnaorg_annotate.pl -h\n\n";
  exit(1);
}
my ($seq_file, $dir_out) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

my $cmd  = undef;                    # a command to be run by ribo_RunCommand()
my $ncpu = opt_Get("-n" , \%opt_HH); # number of CPUs to use with search command (default 0: --cpu 0)
my @early_cmd_A = (); # array of commands we run before our log file is opened
my @to_remove_A = (); # array of files to remove at end



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
  if(-d $dir_out) { 
    $cmd = "rm -rf $dir_out";
    if(opt_Get("--psave", \%opt_HH)) { 
      die "ERROR you used --psave but directory $dir_out already exists.\nYou can either run with --skipsearch to create the psave file and not redo the searches OR\nremove the $dir_out directory and then rerun with --psave if you really want to redo the search steps";
    }
    elsif(opt_Get("-f", \%opt_HH)) { 
      ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef); 
    }
    else { 
      die "ERROR directory named $dir_out already exists. Remove it, or use -f to overwrite it."; 
    }
  }
  elsif(-e $dir_out) { 
    $cmd = "rm $dir_out";
    if(opt_Get("-f", \%opt_HH)) { ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef); }
    else                        { die "ERROR a file named $dir_out already exists. Remove it, or use -f to overwrite it."; }
  }
}
# if $dir_out does not exist, create it
if(! -d $dir_out) { 
  $cmd = "mkdir $dir_out";
  ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef);
}

my $dir_out_tail = $dir_out;
$dir_out_tail    =~ s/^.+\///; # remove all but last dir
my $out_root     = $dir_out .   "/" . $dir_out_tail   . ".ribosensor";

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

my %extra_H    = ();
$extra_H{"\$RIBODIR"}         = $env_ribotyper_dir;
$extra_H{"\$SENSORDIR"}       = $env_sensor_dir;
$extra_H{"\$RIBOINFERNALDIR"} = $env_riboinfernal_dir;
$extra_H{"\$RIBOEASELDIR"}    = $env_riboeasel_dir;
$extra_H{"\$RIBOBLASTDIR"}    = $env_riboblast_dir;
$extra_H{"\$RIBOTIMEDIR"}     = $env_ribotime_dir;
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

# open the list, log and command files 
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, $pkgstr, "list", $out_root . ".list", 1, "List and description of all output files");
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, $pkgstr, "log",  $out_root . ".log",  1, "Output printed to screen");
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, $pkgstr, "cmd",  $out_root . ".cmd",  1, "List of executed commands");
my $log_FH = $ofile_info_HH{"FH"}{"log"};
my $cmd_FH = $ofile_info_HH{"FH"}{"cmd"};
# output files are all open, if we exit after this point, we'll need
# to close these first.

# now we have the log file open, output the banner there too
ofile_OutputBanner($log_FH, $package_name, $version, $releasedate, $synopsis, $date, \%extra_H);
opt_OutputPreamble($log_FH, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

# output any commands we already executed to $log_FH
foreach $cmd (@early_cmd_A) { 
  print $cmd_FH $cmd . "\n";
}

# make sure the sequence, modelinfo, and qsubinfo (if -q) files exist
my $df_modelinfo_file = $df_model_dir . "ribosensor." . $model_version_str . ".modelinfo";
my $modelinfo_file = undef;
if(! opt_IsUsed("-i", \%opt_HH)) { $modelinfo_file = $df_modelinfo_file; }
else                             { $modelinfo_file = opt_Get("-i", \%opt_HH); }

my $df_qsubinfo_file = $df_model_dir . "ribo." . $qsub_version_str . ".qsubinfo";
my $qsubinfo_file = undef;
# if -p, check for existence of qsub info file
if(! opt_IsUsed("-q", \%opt_HH)) { $qsubinfo_file = $df_qsubinfo_file; }
else                             { $qsubinfo_file = opt_Get("-q", \%opt_HH); }

ribo_CheckIfFileExistsAndIsNonEmpty($seq_file, "sequence file", undef, 1, $ofile_info_HH{"FH"}); # '1' says: die if it doesn't exist or is empty
if(! opt_IsUsed("-i", \%opt_HH)) {
  ribo_CheckIfFileExistsAndIsNonEmpty($modelinfo_file, "default model info file", undef, 1, $ofile_info_HH{"FH"}); # '1' says: die if it doesn't exist or is empty
}
else { # -i used on the command line
  ribo_CheckIfFileExistsAndIsNonEmpty($modelinfo_file, "model info file specified with -i", undef, 1, $ofile_info_HH{"FH"}); # '1' says: die if it doesn't exist or is empty
}
if(! opt_IsUsed("-q", \%opt_HH)) {
  ribo_CheckIfFileExistsAndIsNonEmpty($qsubinfo_file, "default qsub info file", undef, 1, $ofile_info_HH{"FH"}); # '1' says: die if it doesn't exist or is empty
}
else { # -q used on the command line
  ribo_CheckIfFileExistsAndIsNonEmpty($qsubinfo_file, "qsub info file specified with -q", undef, 1, $ofile_info_HH{"FH"}); # 1 says: die if it doesn't exist or is empty
}
# we check for the existence of model file after we parse the model info file

##############################
# define and open output files
##############################
my $unsrt_sensor_indi_file  = $out_root . ".sensor.unsrt.out"; # ribosensor-processed, unsorted sensor output
my $sensor_indi_file        = $out_root . ".sensor.out";       # ribosensor-processed, sorted 'gpipe' format sensor output
my $ribo_indi_file          = $out_root . ".ribo.out";         # ribosensor-processed, ribotyper output
my $combined_out_file       = $out_root . ".out";              # ribosensor-processed, sensor+ribotyper combined output, human readable
my $combined_gpipe_file     = $out_root . ".gpipe";            # ribosensor-processed, sensor+ribotyper combined output, machine readable with gpipe errors 
my $passes_sfetch_file      = $out_root . ".pass.sfetch";      # input file for esl-sfetch that will fetch all sequences that passed 
my $passes_seq_file         = $out_root . ".pass.fa";          # all sequences that passed as a FASTA-formatted file 

if(! opt_Get("--keep", \%opt_HH)) { 
  push(@to_remove_A, $unsrt_sensor_indi_file);
  if(opt_Get("--psave", \%opt_HH)) { 
    push(@to_remove_A, $passes_sfetch_file);
  }
}

my $unsrt_sensor_indi_FH = undef; # output file handle for unsorted sensor gpipe file
my $sensor_indi_FH       = undef; # output file handle for gpipe file sorted by input sequence index
my $ribo_indi_FH         = undef; # output file handle for ribotyper gpipe file sorted by input sequence index
my $combined_out_FH      = undef; # output file handle for the combined output file
my $combined_gpipe_FH    = undef; # output file handle for the combined gpipe file
open($unsrt_sensor_indi_FH, ">", $unsrt_sensor_indi_file) || ofile_FileOpenFailure($unsrt_sensor_indi_file, "RIBO", "ribosensor.pl::main()", $!, "writing", $ofile_info_HH{"FH"});
open($sensor_indi_FH,       ">", $sensor_indi_file)       || ofile_FileOpenFailure($sensor_indi_file,       "RIBO", "ribosensor.pl::main()", $!, "writing", $ofile_info_HH{"FH"});
open($ribo_indi_FH,         ">", $ribo_indi_file)         || ofile_FileOpenFailure($ribo_indi_file,         "RIBO", "ribosensor.pl::main()", $!, "writing", $ofile_info_HH{"FH"});
open($combined_out_FH,      ">", $combined_out_file)      || ofile_FileOpenFailure($combined_out_file,      "RIBO", "ribosensor.pl::main()", $!, "writing", $ofile_info_HH{"FH"});
open($combined_gpipe_FH,    ">", $combined_gpipe_file)    || ofile_FileOpenFailure($combined_gpipe_file,    "RIBO", "ribosensor.pl::main()", $!, "writing", $ofile_info_HH{"FH"});

# parse the model info file
my ($sensor_blastdb, $ribo_modelinfo_file, $ribo_accept_file) = parse_modelinfo_file($modelinfo_file, $execs_H{"blastdbcmd"}, opt_Get("-m", \%opt_HH), $df_model_dir, $env_sensor_dir, \%opt_HH, $ofile_info_HH{"FH"});

my $qsub_prefix   = undef; # qsub prefix for submitting jobs to the farm
my $qsub_suffix   = undef; # qsub suffix for submitting jobs to the farm
if(opt_IsUsed("-p", \%opt_HH)) { 
  ($qsub_prefix, $qsub_suffix) = ribo_ParseQsubFile($qsubinfo_file, $ofile_info_HH{"FH"});
}

###################################################################
# Step 1: Split up input sequence file into 3 files based on length
###################################################################
# The primary reason for the split is that rRNA_sensor uses different thresholds
# depending on whether the length is [0,350], [351,600}, or [601, infinity]
# The filter that rRNA sequences are expected to be below a certain length
# is applied within rRNA_sensor, not here.
# We do this split by length before running ribotyper, even though ribotyper is run
# on the full file. A beneficial side effect is that we exit early, if there
# is a detectable syntactic problem in the sequence file.
my $progress_w = 60; # the width of the left hand column in our progress output, hard-coded
my $start_secs;
my @seqorder_A = (); # array of sequences in order they appear in input file
my %seqidx_H = (); # key: sequence name, value: index of sequence in original input sequence file (1..$nseq)
my %seqlen_H = (); # key: sequence name, value: length of sequence
my %width_H  = (); # hash, key is "model" or "target", value is maximum length of any model/target
my $tot_nseq = 0;  # total number of sequences in the sequence file
my $tot_nnt  = 0;  # total number of nucleotides in the full sequence file
$width_H{"taxonomy"} = length("SSU.Euk-Microsporidia"); # longest possible classification in number of characters in the column header
$width_H{"strand"}   = length("mixed(S):minus(R)");     # longest possible strand string in number of characters
$width_H{"index"}    = length("#idx");                  # longest possible index string in number of characters
my $ssi_file = $seq_file . ".ssi";
my $seqstat_file = $out_root . ".seqstat";
my $i;

my $nseq_parts     = 3;               # hard-coded, number of sequence partitions based on length
my @spart_minlen_A = (0,   351, 601); # hard-coded, minimum length for each sequence partition
my @spart_maxlen_A = (350, 600, -1);  # hard-coded, maximum length for each sequence partition, -1 represents infinity
my @spart_desc_A   = ("0..350", "351..600", "601..inf");

my $ncov_parts     = 2;               # hard-coded, number of coverage threshold partitions based on length
my @cpart_minlen_A = (0,   351);      # hard-coded, minimum length for each coverage threshold partition
my @cpart_maxlen_A = (350, -1);       # hard-coded, maximum length for each coverage threshold partition, -1 represents infinity

my @subseq_file_A   = (); # array of fasta files that we fetch into
my @subseq_sfetch_A = (); # array of sfetch input files that we created
my @subseq_nseq_A   = (); # array of number of sequences in each length range
my @subseq_nnt_A    = (); # array of summed length of sequences in each length range

if(! opt_Get("--skipsearch", \%opt_HH)) { 
  $start_secs = ofile_OutputProgressPrior("Partitioning sequence file based on sequence lengths", $progress_w, $log_FH, *STDOUT);
  # check for SSI index file for the sequence file,
  # if it doesn't exist, create it
  if(ribo_CheckIfFileExistsAndIsNonEmpty($ssi_file, undef, undef, 0, $ofile_info_HH{"FH"}) != 1) { 
    ribo_RunCommand("esl-sfetch --index $seq_file > /dev/null", opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    if(ribo_CheckIfFileExistsAndIsNonEmpty($ssi_file, undef, undef, 0, $ofile_info_HH{"FH"}) != 1) { 
      ofile_FAIL("ERROR, tried to create $ssi_file, but failed", "RIBO", 1, $ofile_info_HH{"FH"}); 
    }
  }
}
else { 
  $start_secs = ofile_OutputProgressPrior("Determining size of input sequence file", $progress_w, $log_FH, *STDOUT);
}
  
$tot_nnt  = ribo_ProcessSequenceFile($execs_H{"esl-seqstat"}, $seq_file, $seqstat_file, \@seqorder_A, \%seqidx_H, \%seqlen_H, \%width_H, \%opt_HH, \%ofile_info_HH);
$tot_nseq = scalar(keys %seqidx_H);
if(length($tot_nseq) > $width_H{"index"}) { 
  $width_H{"index"} = length($tot_nseq);
}
if(! opt_Get("--keep", \%opt_HH)) { 
  push(@to_remove_A, $seqstat_file);
}
  
# create new files for the 3 sequence length ranges:
my $do_fetch = (opt_Get("--skipsearch", \%opt_HH)) ? 0 : 1; # do not fetch the sequences if --skipsearch enabled
for($i = 0; $i < $nseq_parts; $i++) { 
  $subseq_sfetch_A[$i] = $out_root . "." . ($i+1) . ".sfetch";
  $subseq_file_A[$i]   = $out_root . "." . ($i+1) . ".fa";
  ($subseq_nseq_A[$i], $subseq_nnt_A[$i]) = fetch_seqs_in_length_range("esl-sfetch", $seq_file, $do_fetch, $spart_minlen_A[$i], $spart_maxlen_A[$i], \%seqlen_H, $subseq_sfetch_A[$i], $subseq_file_A[$i], \%opt_HH, $ofile_info_HH{"FH"});

  # files are marked for removal at this step, but not actually 
  # removed until the rRNA_sensor analysis has been completed
  if(! opt_Get("--keep", \%opt_HH)) { 
    push(@to_remove_A, $subseq_sfetch_A[$i]);
    if($subseq_nseq_A[$i] > 0) { 
      push(@to_remove_A, $subseq_file_A[$i]);
    }
  }
}
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

#############################################
# Step 2: Run ribotyper on full sequence file
#############################################
# It's important that we run ribotyper only once on the full file so that E-values are accurate. 
my $ribo_dir_out    = $dir_out . "/ribo-out";
my $ribo_stdoutfile = $out_root . ".ribotyper.stdout";
# determine ribotyper options
my $ribotyper_options = " -f -i $ribo_modelinfo_file --inaccept $ribo_accept_file --scfail --covfail --tshortcov 0.80 --tshortlen 350 ";
if(opt_IsUsed("-n",            \%opt_HH)) { $ribotyper_options .= " -n " . opt_Get("-n", \%opt_HH); }
if(opt_IsUsed("-p",            \%opt_HH)) { $ribotyper_options .= " -p"; }
if(opt_IsUsed("-q",            \%opt_HH)) { $ribotyper_options .= " -q " . opt_Get("-q", \%opt_HH); }
if(opt_IsUsed("-s",            \%opt_HH)) { $ribotyper_options .= " -s " . opt_Get("-s", \%opt_HH); }
if(opt_IsUsed("--nkb",         \%opt_HH)) { $ribotyper_options .= " --nkb " . opt_Get("--nkb", \%opt_HH); }
if(opt_IsUsed("--wait",        \%opt_HH)) { $ribotyper_options .= " --wait " . opt_Get("--wait", \%opt_HH); }
if(opt_IsUsed("--errcheck",    \%opt_HH)) { $ribotyper_options .= " --errcheck"; }
if(opt_IsUsed("--keep",        \%opt_HH)) { $ribotyper_options .= " --keep"; }
my $ribotyper_cmd  = $execs_H{"ribo"} . " $ribotyper_options $seq_file $ribo_dir_out > $ribo_stdoutfile";
my $ribo_secs      = 0.; # total number of seconds elapsed for ribotyper stage
my $ribo_p_secs    = 0.; # if -p: summed number of seconds elapsed for all ribotyper jobs
my $ribo_shortfile = $ribo_dir_out . "/ribo-out.ribotyper.short.out";
my $ribo_logfile   = $ribo_dir_out . "/ribo-out.ribotyper.log";
if(! opt_Get("--skipsearch", \%opt_HH)) { 
  $start_secs = ofile_OutputProgressPrior("Running ribotyper on full sequence file", $progress_w, $log_FH, *STDOUT);
  ribo_RunCommand($ribotyper_cmd, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  $ribo_secs = ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
  ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", "ribostdout",  $ribo_stdoutfile, 0, "ribotyper stdout output");
}  
# if -p used, overwrite ribo_secs with summed seconds
if(opt_Get("-p", \%opt_HH)) { 
  $ribo_p_secs = ribo_ParseLogFileForParallelTime($ribo_logfile, $ofile_info_HH{"FH"});
}

##############################################################################
# Step 3: Run rRNA_sensor on the (up to 3) length-partitioned sequence files
##############################################################################
my @sensor_dir_out_A             = (); # [0..$i..$nseq_parts-1], directory created for sensor run on partition $i
my @sensor_stdoutfile_A          = (); # [0..$i..$nseq_parts-1], standard output file for sensor run on partition $i
my @sensor_classfile_argument_A  = (); # [0..$i..$nseq_parts-1], sensor script argument for classification output file for partition $i
my @sensor_classfile_fullpath_A  = (); # [0..$i..$nseq_parts-1], full path to classification output file name for partition $i
my @sensor_minid_A               = (); # [0..$i..$nseq_parts-1], minimum identity percentage threshold to use for round $i
my $sensor_cmd = undef;                # command used to run sensor

my $sensor_minlen    = opt_Get("--Sminlen",    \%opt_HH);
my $sensor_maxlen    = opt_Get("--Smaxlen",    \%opt_HH);
my $sensor_maxevalue = opt_Get("--Smaxevalue", \%opt_HH);
my $sensor_secs      = 0.; # total number of seconds elapsed for rRNA_sensor stage
my $sensor_p_secs    = 0.; # if -p: summed number of seconds elapsed for all rRNA_sensor jobs
my $sensor_ncpu      = ($ncpu == 0) ? 1 : $ncpu;

for($i = 0; $i < $nseq_parts; $i++) { 
  $sensor_minid_A[$i] = opt_Get("--Sminid" . ($i+1), \%opt_HH);
  if($subseq_nseq_A[$i] > 0) { 
    $sensor_dir_out_A[$i]             = $dir_out . "/sensor-" . ($i+1) . "-out";
    $sensor_stdoutfile_A[$i]          = $out_root . ".sensor-" . ($i+1) . ".stdout";
    $sensor_classfile_argument_A[$i]  = "sensor-class." . ($i+1) . ".out";
    $sensor_classfile_fullpath_A[$i]  = $sensor_dir_out_A[$i] . "/sensor-class." . ($i+1) . ".out";
    #$sensor_cmd = $execs_H{"sensor"} . " $sensor_minlen $sensor_maxlen $subseq_file_A[$i] $sensor_classfile_argument_A[$i] $sensor_minid_A[$i] $sensor_maxevalue $sensor_ncpu $sensor_dir_out_A[$i] $sensor_blastdb > $sensor_stdoutfile_A[$i]";
    if(! opt_Get("--skipsearch", \%opt_HH)) { 
      $start_secs = ofile_OutputProgressPrior("Running rRNA_sensor on seqs of length $spart_desc_A[$i]", $progress_w, $log_FH, *STDOUT);
      my %info_H = (); 
      $info_H{"IN:seqfile"}        = $subseq_file_A[$i];
      $info_H{"minlen"}            = $sensor_minlen;
      $info_H{"maxlen"}            = $sensor_maxlen;
      $info_H{"OUT-DIR:classpath"} = $sensor_classfile_fullpath_A[$i];
      $info_H{"OUT-DIR:lensum"}    = $sensor_dir_out_A[$i] . "/length_summary1.txt";
      $info_H{"OUT-DIR:blastout"}  = $sensor_dir_out_A[$i] . "/middle_out_" . $sensor_blastdb . "_blastn_fmt6.txt";
      $info_H{"minid"}             = $sensor_minid_A[$i];
      $info_H{"maxevalue"}         = $sensor_maxevalue;
      $info_H{"ncpu"}              = $sensor_ncpu;
      $info_H{"OUT-NAME:outdir"}   = $sensor_dir_out_A[$i];
      $info_H{"blastdb"}           = $sensor_blastdb;
      $info_H{"OUT-NAME:stdout"}   = $sensor_stdoutfile_A[$i];
      $info_H{"OUT-NAME:time"}     = $sensor_stdoutfile_A[$i] . ".time";;
      $info_H{"OUT-NAME:stderr"}   = $sensor_stdoutfile_A[$i] . ".err";
      $info_H{"OUT-NAME:qcmd"}     = $sensor_stdoutfile_A[$i] . ".qcmd";
      ribo_RunCmsearchOrCmalignOrRRnaSensorWrapper(\%execs_H, "rRNA_sensor_script", $qsub_prefix, $qsub_suffix, \%seqlen_H, $progress_w, 
                                                   $out_root, $subseq_nseq_A[$i], $subseq_nnt_A[$i], "", \%info_H, \%opt_HH, \%ofile_info_HH);
      $sensor_p_secs += ribo_ParseUnixTimeOutput($info_H{"OUT-NAME:time"}, $ofile_info_HH{"FH"});

      $sensor_secs += ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
      ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", "sensorstdout" . $i,  $sensor_stdoutfile_A[$i], 0, "rRNA_sensor stdout output for length class" . ($i+1));
      if(! opt_IsUsed("--keep", \%opt_HH)) { # remove the fasta files that rRNA_sensor created
        my $sensor_mid_fafile = $sensor_dir_out_A[$i] . "/middle_queries.fsa";
        my $sensor_out_fafile = $sensor_dir_out_A[$i] . "/outlier_queries.fsa";
        push(@to_remove_A, $sensor_mid_fafile);
        push(@to_remove_A, $sensor_out_fafile);
      }
    }
  }
  else { 
    $sensor_dir_out_A[$i]            = undef;
    $sensor_stdoutfile_A[$i]         = undef;
    $sensor_classfile_fullpath_A[$i] = undef;
    $sensor_classfile_argument_A[$i] = undef;
  }
}

###########################################################################
# Step 4: Parse rRNA_sensor results and create intermediate file 
###########################################################################
# define data structures for statistics/counts that we will output
my @outcome_type_A;        # array of outcome 'types', in order they should be output
my @outcome_cat_A;         # array of outcome 'categories' in order they should be output
my %outcome_ct_HH  = ();   # 2D hash of counts of 'outcomes'
                           # 1D key is outcome type, an element from @outcome_type_A
                           # 2D key is outcome category, an element from @outcome_cat_A
                           # value is count
my @herror_A       = ();   # array of 'human' error types, in order they should be output
my %herror_ct_HH   = ();   # 2D hash of counts of 'human' error types, 
                           # 1D key is outcome type, e.g. "RPSF", 
                           # 2D key is human error type, an element from @herror_A
                           # value is count
my %herror_failsto_H = (); # hash that explains if each human error fails to "submitter" or "indexer",
                           # key is $herror from @herror_A, value is "NONE, "submitter" or "indexer"
my @gerror_A       = ();   # array of 'gpipe' error types, in order they should be output
my %gerror_ct_HH   = ();   # 2D hash of counts of 'gpipe' error types, 
                           # 1D key is outcome type, e.g. "RPSF", 
                           # 2D key is gpipe error type, an element from @gerror_A
                           # value is count
my @RPSF_ignore_A  = ();   # array of human errors to ignore for sequences that pass ribotyper and
                           # fail sensor (RPSF)
my @RFSP_ignore_A  = ();   # array of human errors to ignore for sequences that fail ribotyper and
                           # pass sensor (RFSP)
my %RFSF_ignore_HA = ();   # hash of arrays, hash key: human error 1, value is array, where each element
                           # is human error 2..N. If human error 2..N is observed, then ignore human 
                           # error 1 if sequence fails both ribotyper and sensor (RFSF)
my @indexer_A      = ();   # array of human errors that fail to indexer rather than submitter
my @submitter_A    = ();   # array of human errors that fail to submitter rather than indexer

@outcome_type_A    = ("RPSP", "RPSF", "RFSP", "RFSF", "*all*");
@outcome_cat_A     = ("total", "pass", "indexer", "submitter", "unmapped");
@herror_A     = ("CLEAN",
                 "S_NoHits",
                 "S_TooLong", 
                 "S_TooShort", 
                 "S_LowScore",
                 "S_BothStrands",
                 "S_MultipleHits",
                 "S_NoSimilarity",
                 "S_LowSimilarity",
                 "R_NoHits",
                 "R_MultipleFamilies",
                 "R_BothStrands",
                 "R_UnacceptableModel", 
                 "R_QuestionableModel", 
                 "R_LowScore",
                 "R_LowCoverage",
                 "R_DuplicateRegion",
                 "R_InconsistentHits",
                 "R_MultipleHits");
@gerror_A     = ("CLEAN",
                 "SEQ_HOM_NotSSUOrLSUrRNA",
                 "SEQ_HOM_SSUAndLSUrRNA",
                 "SEQ_HOM_LowSimilarity",
                 "SEQ_HOM_LengthShort",
                 "SEQ_HOM_LengthLong",
                 "SEQ_HOM_MisAsBothStrands",
                 "SEQ_HOM_MisAsHitOrder",
                 "SEQ_HOM_MisAsDupRegion",
                 "SEQ_HOM_TaxNotExpectedSSUrRNA",
                 "SEQ_HOM_TaxQuestionableSSUrRNA",
                 "SEQ_HOM_LowCoverage",
                 "SEQ_HOM_MultipleHits");

# hard-coded list of errors that we ignore when triggering GPIPE
# errors if sequence is RPSF (pass ribotyper, fail sensor) and -c not
# used
@RPSF_ignore_A = ("S_NoHits", 
                  "S_LowScore",
                  "S_NoSimilarity",
                  "S_LowSimilarity");

# hard-coded list of errors that we ignore when triggering GPIPE
# errors if sequence is RFSP (fail ribotyper, pass sensor)
@RFSP_ignore_A = ("R_MultipleHits");

# hard-coded list of errors that we ignore (if other errors are also
# observed) when triggering GPIPE errors if sequence is RFSF (fail
# ribotyper, fail sensor), key is error to ignore, value is array of
# other errors, if any of the other errors are present we ignore the
# key error
@{$RFSF_ignore_HA{"S_NoHits"}}        = ("R_UnacceptableModel", "R_QuestionableModel");
@{$RFSF_ignore_HA{"S_NoSimilarity"}}  = ("R_UnacceptableModel", "R_QuestionableModel");
@{$RFSF_ignore_HA{"S_LowSimilarity"}} = ("R_UnacceptableModel", "R_QuestionableModel");
@{$RFSF_ignore_HA{"S_LowScore"}}      = ("R_UnacceptableModel", "R_QuestionableModel");

# hard-coded list of errors that fail to the indexer, all other errors
# fail to the submitter
@indexer_A  = ("R_QuestionableModel", 
               "R_LowCoverage", 
               "S_MultipleHits", 
               "R_MultipleHits");

# create the failsto hash, mapping each error type to indexer or submitter
define_failsto_hash(\@herror_A, \@indexer_A, \%herror_failsto_H);
  
# create the map of gpipe errors to human errors
my %gpipe2human_HH = ();
define_gpipe_to_human_map(\%gpipe2human_HH, \@gerror_A, \@herror_A);

$start_secs = ofile_OutputProgressPrior("Parsing and combining rRNA_sensor and ribotyper output", $progress_w, $log_FH, *STDOUT);
# parse rRNA_sensor file to create gpipe format file
# first unsorted, then sort it.
parse_sensor_files($unsrt_sensor_indi_FH, \@sensor_classfile_fullpath_A, \@cpart_minlen_A, \@cpart_maxlen_A, \%seqidx_H, \%seqlen_H, \%width_H, \%opt_HH);
close($unsrt_sensor_indi_FH);

# sort sensor shortfile
output_headers_without_fails_to($sensor_indi_FH, \%width_H, $ofile_info_HH{"FH"});
close($sensor_indi_FH);

$cmd = "sort -n $unsrt_sensor_indi_file >> $sensor_indi_file";
ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
open($sensor_indi_FH, ">>", $sensor_indi_file) || die "ERROR, unable to open $sensor_indi_file for appending";
output_tail_without_fails_to($sensor_indi_FH, \%opt_HH); 
close($sensor_indi_FH);
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", "sensorout", $sensor_indi_file, 1, "summary of rRNA_sensor results");

# convert ribotyper output to gpipe 
output_headers_without_fails_to($ribo_indi_FH, \%width_H, $ofile_info_HH{"FH"});
convert_ribo_short_to_indi_file($ribo_indi_FH, $ribo_shortfile, \@herror_A, \%seqidx_H, \%width_H, \%opt_HH);
output_tail_without_fails_to($ribo_indi_FH, \%opt_HH); 
close($ribo_indi_FH);
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", "riboout", $ribo_indi_file, 1, "summary of ribotyper results");

initialize_hash_of_hash_of_counts(\%outcome_ct_HH, \@outcome_type_A, \@outcome_cat_A);
initialize_hash_of_hash_of_counts(\%herror_ct_HH,  \@outcome_type_A, \@herror_A);
initialize_hash_of_hash_of_counts(\%gerror_ct_HH,  \@outcome_type_A, \@gerror_A);

# combine sensor and ribotyper indi output files to get combined output file
output_headers_with_fails_to   ($combined_out_FH,   \%width_H, $ofile_info_HH{"FH"});
output_headers_without_fails_to($combined_gpipe_FH, \%width_H, $ofile_info_HH{"FH"});
combine_gpipe_files($combined_out_FH, $combined_gpipe_FH, $sensor_indi_file, $ribo_indi_file, 
                    \@gerror_A, \%gpipe2human_HH, \%outcome_ct_HH, 
                    \%herror_ct_HH, \%gerror_ct_HH, 
                    (opt_Get("-c", \%opt_HH) ? undef : \@RPSF_ignore_A), # only ignore some sensor errors if -c not used
                    \@RFSP_ignore_A,  # list of ribotyper errors to ignore if sensor pass
                    \%RFSF_ignore_HA, # list of errors to ignore if RFSF, if other errors are observed
                    \%herror_failsto_H, \%width_H, \%opt_HH);
output_tail_with_fails_to   ($combined_out_FH,   \%opt_HH); 
output_tail_without_fails_to($combined_gpipe_FH, \%opt_HH); 
close($combined_out_FH);
close($combined_gpipe_FH);

ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", "combinedout",   $combined_out_file,   1, "summary of combined rRNA_sensor and ribotyper results (original errors)");
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", "combinedgpipe", $combined_gpipe_file, 1, "summary of combined rRNA_sensor and ribotyper results (GPIPE errors)");

# remove files we do not want anymore, then exit
foreach my $file (@to_remove_A) { 
  if(-e $file) { 
    unlink $file;
  }
}

# save output files that were specified with cmdline options
my $nseq_passed    = 0; # number of sequences 
my $nseq_revcomped = 0; # number of sequences reverse complemented
if(opt_Get("--psave", \%opt_HH)) { 
  ($nseq_passed, $nseq_revcomped) = fetch_seqs_given_gpipe_file("esl-sfetch", $seq_file, $combined_out_file, "pass", 6, 1, $passes_sfetch_file, $passes_seq_file, \%seqlen_H, \%opt_HH, $ofile_info_HH{"FH"});
}

output_outcome_counts(*STDOUT, \%outcome_ct_HH, $ofile_info_HH{"FH"});
output_outcome_counts($log_FH, \%outcome_ct_HH, $ofile_info_HH{"FH"});

output_error_counts(*STDOUT, "Per-program error counts:", $tot_nseq, \%{$herror_ct_HH{"*all*"}}, \@herror_A, $ofile_info_HH{"FH"});
output_error_counts($log_FH, "Per-program error counts:", $tot_nseq, \%{$herror_ct_HH{"*all*"}}, \@herror_A, $ofile_info_HH{"FH"});

output_error_counts(*STDOUT, "GPIPE error counts:", $tot_nseq, \%{$gerror_ct_HH{"*all*"}}, \@gerror_A, $ofile_info_HH{"FH"});
output_error_counts($log_FH, "GPIPE error counts:", $tot_nseq, \%{$gerror_ct_HH{"*all*"}}, \@gerror_A, $ofile_info_HH{"FH"});

$total_seconds += ribo_SecondsSinceEpoch();
output_timing_statistics(*STDOUT, $tot_nseq, $tot_nnt, $ncpu, $ribo_secs, $ribo_p_secs, $sensor_secs, $sensor_p_secs, $total_seconds, \%opt_HH, $ofile_info_HH{"FH"});
output_timing_statistics($log_FH, $tot_nseq, $tot_nnt, $ncpu, $ribo_secs, $ribo_p_secs, $sensor_secs, $sensor_p_secs, $total_seconds, \%opt_HH, $ofile_info_HH{"FH"});

printf("#\n# Human readable error-based output saved to file $combined_out_file\n");
printf("# GPIPE error-based output saved to file $combined_gpipe_file\n");
if((opt_Get("--psave", \%opt_HH)) && ($nseq_passed > 0)) { 
  printf("#\n# The $nseq_passed sequences that passed (with $nseq_revcomped minus strand sequences\n# reverse complemented) saved to file $passes_seq_file\n");
}

ofile_OutputConclusionAndCloseFiles($total_seconds, "RIBO", $dir_out, \%ofile_info_HH);

###############
# SUBROUTINES #
###############

#################################################################
# Subroutine : fetch_seqs_in_length_range()
# Incept:      EPN, Fri May 12 11:13:46 2017
#
# Purpose:     Use esl-sfetch to fetch sequences in a given length
#              range from <$seq_file> given the lengths in %{$seqlen_HR}.
#
# Arguments: 
#   $sfetch_exec:  path to esl-sfetch executable
#   $seq_file:     sequence file to fetch sequences from
#   $do_fetch:     '1' to fetch the sequences, '0' not to
#   $minlen:       minimum length sequence to fetch
#   $maxlen:       maximum length sequence to fetch (-1 for infinity)
#   $seqlen_HR:    ref to hash of sequence lengths to fill here
#   $sfetch_file:  name of esl-sfetch input file to create
#   $subseq_file:  name of fasta file to create 
#   $opt_HHR:      reference to 2D hash of cmdline options
#   $FH_HR:        ref to hash of file handles, including "cmd"
# 
# Returns:     Two values: 
#              $nseq_fetched: number of sequences fetched.
#              $nnt_fetched:  summed length of all seqs fetched.
#
# Dies:        If the esl-sfetch command fails.
#
################################################################# 
sub fetch_seqs_in_length_range { 
  my $nargs_expected = 10;
  my $sub_name = "fetch_seqs_in_length_range";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($sfetch_exec, $seq_file, $do_fetch, $minlen, $maxlen, $seqlen_HR, $sfetch_file, $subseq_file, $opt_HHR, $FH_HR) = (@_);

  my $target;   # name of a target sequence
  my $nseq = 0; # number of sequences fetched
  my $nnt  = 0; # summed length of sequences fetched

  open(SFETCH, ">", $sfetch_file) || die "ERROR unable to open $sfetch_file for writing";

  foreach $target (keys %{$seqlen_HR}) { 
    if(! exists $seqlen_HR->{$target}) { 
      die "ERROR in $sub_name, no length data for $target"; 
    }
    if(($seqlen_HR->{$target} >= $minlen) && 
       (($maxlen == -1) || ($seqlen_HR->{$target} <= $maxlen))) {  
      print SFETCH $target . "\n";
      $nseq++;
      $nnt += $seqlen_HR->{$target};
    }
  }
  close(SFETCH);

  if($nseq > 0 && ($do_fetch)) { 
    my $sfetch_cmd = $sfetch_exec . " -f $seq_file $sfetch_file > $subseq_file"; 
    ribo_RunCommand($sfetch_cmd, opt_Get("-v", $opt_HHR), $FH_HR);
  }

  return ($nseq, $nnt);
}

#################################################################
# Subroutine : parse_sensor_files()
# Incept:      EPN, Fri May 12 16:33:57 2017
#
# Purpose:     For each sequence in a set of sensor 'classification'
#              output files, output a single summary line to a new file.
#
# Arguments: 
#   $FH:           filehandle to output to
#   $classfile_AR: ref to array with names of sensor class files
#   $minlen_AR:    ref to array of minimum lengths for coverage threshold partitions 
#   $maxlen_AR:    ref to array of maximum lengths for coverage threshold partitions 
#   $seqidx_HR:    ref to hash of sequence indices
#   $seqlen_HR:    ref to hash of sequence lengths
#   $width_HR:     ref to hash with max lengths of sequence index and target
#   $opt_HHR:      reference to 2D hash of cmdline options
# 
# Returns:     Number of sequences fetched.
#
# Dies:        If the esl-sfetch command fails.
#
################################################################# 
sub parse_sensor_files { 
  my $nargs_expected = 8;
  my $sub_name = "parse_sensor_files";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($FH, $classfile_AR, $minlen_AR, $maxlen_AR, $seqidx_HR, $seqlen_HR, $width_HR, $opt_HHR) = (@_);

  my $nclassfiles = scalar(@{$classfile_AR});
  my $line   = undef; # a line of input
  my $seqid  = undef; # name of a sequence
  my $class  = undef; # class of a sequence
  my $strand = undef; # strand of a sequence
  my $nhits  = undef; # number of hits to a sequence
  my $cov    = undef; # coverage of a sequence;
  my @el_A   = ();    # array of elements on a line
  my $passfail = undef; # PASS or FAIL for a sequence
  my $failmsg  = undef; # list of errors for the sequence
  my $i;                # a counter
  my $nexp_tokens = 5;  # number of expected tokens/columns in a sensor 'class' file

  # get the coverage thresholds for each coverage threshold partition
  my $ncov_parts  = scalar(@{$minlen_AR});
  my $cthresh_all = opt_Get("--Smincovall", $opt_HHR);
  my @cthresh_part_A = ();
  my $cov_part = undef; # the coverage partition a sequence belongs to (index in $cthresh_part_)
  for($i = 0; $i < $ncov_parts; $i++) { 
    $cthresh_part_A[$i] = opt_Get("--Smincov" . ($i+1), $opt_HHR);
  }

  foreach my $classfile (@{$classfile_AR}) { 
    if(defined $classfile) { 
      open(IN, $classfile) || die "ERROR unable to open $classfile for reading in $sub_name"; 
      while($line = <IN>) { 
        # example lines:
        #ALK.1_567808	imperfect_match	minus	1	38
        #T12A.3_40999	imperfect_match	minus	1	41
        #T13A.1_183523	imperfect_match	minus	1	41
        chomp $line;

        my @el_A = split(/\t/, $line);
        if(scalar(@el_A) != $nexp_tokens) { die "ERROR unable to parse sensor output file line: $line"; }
        ($seqid, $class, $strand, $nhits, $cov) = (@el_A);
        $passfail = "PASS";
        $failmsg = "";

        # sanity check
        if((! exists $seqidx_HR->{$seqid}) || (! exists $seqlen_HR->{$seqid})) { 
          die "ERROR in $sub_name, found unexpected sequence $seqid\n";
        }

        if($class eq "too long") { 
          $passfail = "FAIL";
          $failmsg .= "S_TooLong;"; # TODO: add to analysis document
        }
        elsif($class eq "too short") { 
          $passfail = "FAIL";
          $failmsg .= "S_TooShort;"; # TODO: add to analysis document
        }
        elsif($class eq "no") { 
          $passfail = "FAIL";
          $failmsg .= "S_NoHits;"; # TODO: add to analysis document
        }
        elsif($class eq "yes") { 
          $passfail = "PASS";
        }
        #elsif($class eq "partial") { 
        # I think sensor no longer can output this
        #}
        elsif($class eq "imperfect_match") { 
          $passfail = "FAIL";
          $failmsg  .= "S_LowScore;";
        }
        # now stop the else, because remainder don't depend on class
        if($strand eq "mixed") { 
          $passfail = "FAIL";
          $failmsg  .= "S_BothStrands;";
        }
        if(($nhits ne "NA") && ($nhits > 1)) { 
          $passfail = "FAIL";
          $failmsg  .= "S_MultipleHits;";
        }
        if($cov ne "NA") { 
          $cov_part = determine_coverage_threshold($seqlen_HR->{$seqid}, $minlen_AR, $maxlen_AR, $ncov_parts);
          if($cov < $cthresh_all) { 
            $passfail = "FAIL";
            $failmsg  .= "S_NoSimilarity;"; 
            # TODO put this in table 1 in analysis doc, in table 3 but not table 1
          }
          elsif($cov < $cthresh_part_A[$cov_part]) { 
            $passfail = "FAIL";
            $failmsg  .= "S_LowSimilarity;";
          }
        }
        if($failmsg eq "") { $failmsg = "-"; }
        output_gpipe_line_without_fails_to($FH, $seqidx_HR->{$seqid}, $seqid, "?", $strand, $passfail, $failmsg, $width_HR, $opt_HHR);
      }
    }
  }
  return;
}

#################################################################
# Subroutine : determine_coverage_threshold()
# Incept:      EPN, Fri May 12 17:02:43 2017
#
# Purpose:     Given a sequence length and arrays of min and max values
#              in arrays, determine what index of the array the length
#              falls in between the min and max of.
#
# Arguments: 
#   $length:    length of the sequence
#   $min_AR:    ref to array of minimum lengths for coverage threshold partitions 
#   $max_AR:    ref to array of maximum lengths for coverage threshold partitions 
#   $n:         size of the arrays
# 
# Returns:     Index (0..n-1).
#
# Dies:        If $length is outside the range
#
################################################################# 
sub determine_coverage_threshold { 
  my $nargs_expected = 4;
  my $sub_name = "determine_coverage_threshold";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($length, $min_AR, $max_AR, $n) = (@_);

  my $i; # counter

  for($i = 0; $i < $n; $i++) {
    if($length < $min_AR->[$i]) { die "ERROR in $sub_name, length $length out of bounds (too short)"; }
    if(($max_AR->[$i] == -1) || ($length <= $max_AR->[$i])) { 
      return $i;
    }
  }
  die "ERROR in $sub_name, length $length out of bounds (too long)"; 

  return 0; # never reached
}

#################################################################
# Subroutine : output_headers_without_fails_to()
# Incept:      EPN, Sat May 13 05:51:17 2017
#
# Purpose:     Output column headers to a gpipe format output
#              file for either sensor or ribotyper.
#              
# Arguments: 
#   $FH:        file handle to output to
#   $width_HR:  ref to hash, keys include "model" and "target", 
#               value is width (maximum length) of any target/model
#   $FH_HR:     ref to hash of file handles, including "cmd"
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_headers_without_fails_to { 
  my $nargs_expected = 3;
  my $sub_name = "output_headers_without_fails_to";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $width_HR, $FH_HR) = (@_);

  my $index_dash_str  = "#" . ribo_GetMonoCharacterString($width_HR->{"index"}-1, "-", $FH_HR);
  my $target_dash_str = ribo_GetMonoCharacterString($width_HR->{"target"}, "-", $FH_HR);
  my $tax_dash_str    = ribo_GetMonoCharacterString($width_HR->{"taxonomy"}, "-", $FH_HR);
  my $strand_dash_str = ribo_GetMonoCharacterString($width_HR->{"strand"}, "-", $FH_HR);

  printf $FH ("%-*s  %-*s  %-*s  %-*s  %4s  %s\n", 
              $width_HR->{"index"},    "#idx", 
              $width_HR->{"target"},   "sequence", 
              $width_HR->{"taxonomy"}, "taxonomy",
              $width_HR->{"strand"},   "strand", 
              "p/f", "error(s)");
  printf $FH ("%s  %s  %s  %s  %s  %s\n", $index_dash_str, $target_dash_str, $tax_dash_str, $strand_dash_str, "----", "--------");

  return;
}

#################################################################
# Subroutine : output_headers_with_fails_to()
# Incept:      EPN, Mon May 22 14:51:15 2017
#
# Purpose:     Output combined output file headers
#              
# Arguments: 
#   $FH:        file handle to output to
#   $width_HR:  ref to hash, keys include "model" and "target", 
#               value is width (maximum length) of any target/model
#   $FH_HR:     ref to hash of file handles, including "cmd"
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_headers_with_fails_to { 
  my $nargs_expected = 3;
  my $sub_name = "output_headers_with_fails_to";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $width_HR, $FH_HR) = (@_);

  my $index_dash_str  = "#" . ribo_GetMonoCharacterString($width_HR->{"index"}-1, "-", $FH_HR);
  my $target_dash_str = ribo_GetMonoCharacterString($width_HR->{"target"}, "-", $FH_HR);
  my $tax_dash_str    = ribo_GetMonoCharacterString($width_HR->{"taxonomy"}, "-", $FH_HR);
  my $strand_dash_str = ribo_GetMonoCharacterString($width_HR->{"strand"}, "-", $FH_HR);

  printf $FH ("%-*s  %-*s  %-*s  %-*s  %4s  %9s  %s\n", 
              $width_HR->{"index"},    "#idx", 
              $width_HR->{"target"},   "sequence", 
              $width_HR->{"taxonomy"}, "taxonomy",
              $width_HR->{"strand"},   "strand", 
              "type", "failsto", "error(s)");
  printf $FH ("%s  %s  %s  %s  %s  %s  %s\n", $index_dash_str, $target_dash_str, $tax_dash_str, $strand_dash_str, "----", "---------", "--------");

  return;
}

#################################################################
# Subroutine : output_tail_without_fails_to()
# Incept:      EPN, Sat May 13 06:17:57 2017
#
# Purpose:     Output explanation of columns for individual
#              output file.
#              
# Arguments: 
#   $FH:         file handle to output to
#   $opt_HHR:    reference to 2D hash of cmdline options
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_tail_without_fails_to { 
  my $nargs_expected = 2;
  my $sub_name = "output_tail_without_fails_to";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $opt_HHR) = (@_);

  printf $FH ("#\n");
  printf $FH ("# Explanation of columns:\n");
  printf $FH ("#\n");
  printf $FH ("# Column 1 [idx]:      index of sequence in input sequence file\n");
  printf $FH ("# Column 2 [target]:   name of target sequence\n");
  printf $FH ("# Column 3 [taxonomy]: inferred taxonomy of sequence\n");
  printf $FH ("# Column 4 [strnd]:    strand ('plus' or 'minus') of best-scoring hit\n");
  printf $FH ("# Column 5 [type]:     \"R<1>S<2>\" <1> is 'P' if passes ribotyper, 'F' if fails; <2> is same, but for sensor\n");
  printf $FH ("# Column 6 [error(s)]: reason(s) for failure (see 00README.txt)\n");
  
  output_errors_explanation($FH, $opt_HHR);

  return;
}

#################################################################
# Subroutine : output_tail_with_fails_to()
# Incept:      EPN, Mon May 22 14:52:27 2017
#
# Purpose:     Output explanation of columns for combined
#              output file.
#              
# Arguments: 
#   $FH:         file handle to output to
#   $opt_HHR:    reference to 2D hash of cmdline options
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_tail_with_fails_to { 
  my $nargs_expected = 2;
  my $sub_name = "output_tail_without_fails_to";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $opt_HHR) = (@_);

  printf $FH ("#\n");
  printf $FH ("# Explanation of columns:\n");
  printf $FH ("#\n");
  printf $FH ("# Column 1 [idx]:      index of sequence in input sequence file\n");
  printf $FH ("# Column 2 [target]:   name of target sequence\n");
  printf $FH ("# Column 3 [taxonomy]: inferred taxonomy of sequence\n");
  printf $FH ("# Column 4 [strnd]:    strand ('plus' or 'minus') of best-scoring hit\n");
  printf $FH ("# Column 5 [type]:     \"R<1>S<2>\" <1> is 'P' if passes ribotyper, 'F' if fails; <2> is same, but for sensor\n");
  printf $FH ("# Column 6 [failsto]:  'pass' if sequence passes\n");
  printf $FH ("#                      'indexer'   to fail to indexer\n");
  printf $FH ("#                      'submitter' to fail to submitter\n");
  printf $FH ("#                      '?' if situation is not covered in the code\n");
  printf $FH ("# Column 7 [error(s)]: reason(s) for failure (see 00README.txt)\n");
  
  output_errors_explanation($FH, $opt_HHR);

  return;
}

#################################################################
# Subroutine : output_errors_explanation()
# Incept:      EPN, Mon May 15 05:25:51 2017
#
# Purpose:     Output explanation of error(s) in a gpipe file.
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
sub output_errors_explanation { 
  my $nargs_expected = 2;
  my $sub_name = "output_errors_explanation";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $opt_HHR) = (@_);

#  print $FH ("#\n");
#  print $FH ("# Explanation of possible values in error(s) column:\n");
#  print $FH ("#\n");
#  print $FH ("# This column will include a '-' if none of the error(s) listed below are detected.\n");
#  print $FH ("# Or it will contain one or more of the following types of messages. There are no\n");
#  print $FH ("# whitespace characters in this field. Errors from rRNA_sensor begin with \'sensor\'.\n");
#  print $FH ("# Errors from ribotyper begin with 'ribotyper'.\n");
#  print $FH ("#\n");

  return;
}

#################################################################
# Subroutine : convert_ribo_short_to_indi_file()
# Incept:      EPN, Mon May 15 05:35:28 2017
#
# Purpose:     Convert a ribotyper short format output file 
#              to gpipe format. 
#
# Arguments: 
#   $FH:             filehandle to output to
#   $shortfile:      name of ribotyper short file
#   $herror_AR:      ref to array of human error types for ribosensor
#   $seqidx_HR:      ref to hash of sequence indices
#   $width_HR:       ref to hash with max lengths of sequence index and target
#   $opt_HHR:        ref to 2D hash of cmdline options
# 
# Returns:     void
#
# Dies:        if short file is in unexpected format
#
################################################################# 
sub convert_ribo_short_to_indi_file { 
  my $nargs_expected = 6;
  my $sub_name = "convert_ribo_short_to_indi_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($FH, $shortfile, $herror_AR, $seqidx_HR, $width_HR, $opt_HHR) = (@_);

  my @el_A              = ();    # array of elements on a line
  my @ufeature_A        = ();    # array of unexpected features on a line
  my $ufeature          = undef; # a single unexpected feature
  my $ufeature_str      = undef; # a string of unexpected features
  my $ufeature_stripped = undef; # an unexpected feature without sequence specific information
  my $line              = undef; # a line of input
  my $failmsg           = undef; # list of errors for the sequence
  my $idx               = undef; # a sequence index
  my $seqid             = undef; # name of a sequence
  my $class             = undef; # class of a sequence
  my $strand            = undef; # strand of a sequence
  my $passfail          = undef; # PASS or FAIL for a sequence
  my $i;                         # a counter
  my $herror;                    # an element of @{$herror_AR}
  my %herror_H = ();             # identity hash of herrors, created for @{$herror_AR}
                                 # to quickly determine if an herror is in @{$herror_AR} or not
  foreach $herror (@{$herror_AR}) { 
    $herror_H{$herror} = 1;
  }

  open(IN, $shortfile) || die "ERROR unable to open $shortfile for reading in $sub_name"; 
  while($line = <IN>) { 
    if($line !~ m/^\#/) { 
      # example lines:
      #idx  target                                         classification         strnd   p/f  unexpected_features
      #---  ---------------------------------------------  ---------------------  -----  ----  -------------------
      #14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus   FAIL  *UnacceptableModel(SSU_rRNA_Eukarya)
      #15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  FAIL  *UnacceptableModel(SSU_rRNA_Eukarya);MinusStrand
      chomp $line;
      
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 6) { die "ERROR unable to parse ribotyper short file line: $line"; }
      ($idx, $seqid, $class, $strand, $passfail, $ufeature_str) = (@el_A);
      if($strand eq "-") { $strand = "NA"; }
      $failmsg = "";
      
      # sanity checks
      if(! exists $seqidx_HR->{$seqid}) { 
      die "ERROR in $sub_name, found unexpected sequence $seqid\n";
      }
      if($seqidx_HR->{$seqid} != $idx) { 
        die "ERROR in $sub_name, sequence $seqid has index $idx but expected index $seqidx_HR->{$seqid}.\n";
      }      
      
      if($ufeature_str eq "-") { 
        # sanity check
        if($passfail ne "PASS") { 
          die "ERROR in $sub_name, sequence $seqid has no unexpected features, but does not PASS:\n$line\n";
        }
        output_gpipe_line_without_fails_to($FH, $idx, $seqid, $class, $strand, $passfail, "-", $width_HR, $opt_HHR);
      }
      else { # ufeature_str ne "-", prepend an "R_" to each unexpected feature
        @ufeature_A = split(";", $ufeature_str);
        if(scalar(@ufeature_A) > 0) { 
          foreach $ufeature (@ufeature_A) { 
            $ufeature =~ s/^\*//; # remove leading '*' if it exists
            $ufeature_stripped = $ufeature; 
            $ufeature_stripped =~ s/\:.+$//; # remove ':' and everything after (the sequence specific information)
            $ufeature_stripped = "R_" . $ufeature_stripped;
            # determine if this is a ufeature that maps to an error in ribosensor
            if(exists $herror_H{$ufeature_stripped}) { 
              $failmsg .= "R_" . $ufeature . ";";
              $passfail = "FAIL";
            }
          }
        }
        if($failmsg eq "") { 
          if($passfail ne "PASS") { 
            die "ERROR in $sub_name, sequence $seqid has no unexpected features that cause errors, but does not PASS:\n$line\n";
          }
          $failmsg = "-"; 
        }
        output_gpipe_line_without_fails_to($FH, $idx, $seqid, $class, $strand, $passfail, $failmsg, $width_HR, $opt_HHR);
      } # end of else entered if $ufeature_str ne "-"
    }
  }
  close(IN);
  return;
}
  
#################################################################
# Subroutine : output_gpipe_line_with_fails_to()
# Incept:      EPN, Mon May 15 05:46:28 2017
#
# Purpose:     Output a single line to a gpipe file file handle.
#
# Arguments: 
#   $FH:                 filehandle to output to
#   $idx:                sequence index
#   $seqid:              sequence identifier
#   $class:              classification value
#   $strand:             strand value
#   $passfail:           "PASS" or "FAIL"
#   $failmsg:            failure message
#   $doctored_failmsg:   failure message with any errors that we should ignore 
#                        for purposes of pass/failure removed
#   $herror_failsto_HR:  ref to hash explaining how each human error fails
#   $width_HR:           ref to hash with max lengths of sequence index and target
#   $opt_HHR:            ref to 2D hash of cmdline options
#
# Returns:     nothing
#
# Dies:        never
#
################################################################# 
sub output_gpipe_line_with_fails_to { 
  my $nargs_expected = 11;
  my $sub_name = "output_gpipe_line_with_fails_to";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($FH, $idx, $seqid, $class, $strand, $passfail, $failmsg, $doctored_failmsg, $herror_failsto_HR, $width_HR, $opt_HHR) = (@_);

  my $failsto = "";

  $failsto = determine_fails_to_string($doctored_failmsg, $herror_failsto_HR, $opt_HHR);
  printf $FH ("%-*d  %-*s  %-*s  %-*s  %4s  %9s  %s\n", 
              $width_HR->{"index"},    $idx, 
              $width_HR->{"target"},   $seqid, 
              $width_HR->{"taxonomy"}, $class, 
              $width_HR->{"strand"},   $strand, 
              $passfail, $failsto, $failmsg);

  return $failsto;
}

#################################################################
# Subroutine : output_gpipe_line_without_fails_to()
# Incept:      EPN, Mon May 22 13:55:26 2017
#
# Purpose:     Output a single line to a gpipe file file handle.
#
# Arguments: 
#   $FH:          filehandle to output to
#   $idx:         sequence index
#   $seqid:       sequence identifier
#   $class:       classification value
#   $strand:      strand value
#   $passfail:    "PASS" or "FAIL"
#   $failmsg:     failure message
#   $width_HR:    ref to hash with max lengths of sequence index and target
#   $opt_HHR:     ref to 2D hash of cmdline options
#
# Returns:     "fails_to" string, only if $type eq "hcombined" else ""
#
# Dies:        never
#
################################################################# 
sub output_gpipe_line_without_fails_to { 
  my $nargs_expected = 9;
  my $sub_name = "output_gpipe_line_without_fails_to";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($FH, $idx, $seqid, $class, $strand, $passfail, $failmsg, $width_HR, $opt_HHR) = (@_);

  printf $FH ("%-*d  %-*s  %-*s  %-*s  %4s  %s\n", 
              $width_HR->{"index"},    $idx, 
              $width_HR->{"target"},   $seqid, 
              $width_HR->{"taxonomy"}, $class, 
              $width_HR->{"strand"},   $strand, 
              $passfail, $failmsg);

  return;
}

#################################################################
# Subroutine : combine_gpipe_files()
# Incept:      EPN, Mon May 15 09:08:38 2017
#
# Purpose:     Combine the information in two gpipe files, one
#              from sensor and one from ribotyper into a single file.
#
# Arguments: 
#   $out_FH:            filehandle to output 'human' readable file to 
#   $gpipe_FH:          filehandle to output gpipe file to 
#   $sensor_gpipe_file: name of sensor gpipe file to read
#   $ribo_gpipe_file:   name of ribotyper gpipe file to read
#   $gerror_AR:         ref to array of gpipe errors
#   $g2h_HHR:           ref to 2D hash, key1: gpipe error, key2: human error,
#                       value: '1' if key1 is triggered by key2.
#   $outcome_ct_HHR:    ref to 2D hash of counts of outcomes,
#                       1D key: "RPSP", "RPSF", "RFSP", "RFSF", "*all*"
#                       2D key: "total", "pass", "indexer", "submitter", "unmapped"
#                       values: counts of sequences
#   $herror_ct_HHR:     ref to 2D hash of counts of human errors
#                       1D key: "RPSP", "RPSF", "RFSP", "RFSF", "*all*"
#                       2D key: name of human error (e.g. 'R_NoHits')
#                       values: counts of sequences
#   $gerror_ct_HHR      ref to 2D hash of counts of gpipe errors
#                       1D key: "RPSP", "RPSF", "RFSP", "RFSF", "*all*"
#                       2D key: name of gpipe error (e.g. 'SEQ_HOM_NotSSUOrLSUrRNA')
#                       values: counts of sequences
#   $RPSF_ignore_AR:    ref to array of sensor    errors to ignore if RPSF (ribotyper pass, sensor fail)
#   $RFSP_ignore_AR:    ref to array of ribotyper errors to ignore if RFSP (ribotyper fail, sensor pass)
#   $RFSF_ignore_HAR:   ref to hash of arrays of errors to ignore if RFSF (ribotyper fail, sensor pass)
#                       and other errors are observed. Key is error to ignore, value is list of other
#                       errors, if any of the other errors are observed we ignore the key error.
#   $herror_failsto_HR: ref to hash explaining how each human error fails
#   $width_HR:          ref to hash with max lengths of sequence index, target, and classifications
#   $opt_HHR:           ref to 2D hash of cmdline options
# 
# Returns:     void
#
# Dies:        if there's a problem parsing the gpipe files
#
################################################################# 
sub combine_gpipe_files { 
  my $nargs_expected = 15;
  my $sub_name = "combine_gpipe_files";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($out_FH, $gpipe_FH, $sensor_gpipe_file, $ribo_gpipe_file, $gerror_AR, $g2h_HHR, $outcome_ct_HHR, $herror_ct_HHR, $gerror_ct_HHR, $RPSF_ignore_AR, $RFSP_ignore_AR, $RFSF_ignore_HAR, $herror_failsto_HR, $width_HR, $opt_HHR) = (@_);

  my @sel_A    = ();    # array of elements on a sensor line
  my @rel_A    = ();    # array of elements on a ribotyper line
  my $sline    = undef; # a line of sensor input
  my $rline    = undef; # a line of ribotyper input
  my ($sidx,      $ridx,      $idx);      # a sensor, ribotyper, and combined sequence index
  my ($sseqid,    $rseqid,    $seqid);    # a sensor, ribotyper, and combined sequence identifier
  my ($sclass,    $rclass,    $class);    # a sensor, ribotyper, and combined classification string
  my ($sstrand,   $rstrand,   $strand);   # a sensor, ribotyper, and combined strand
  my ($spassfail, $rpassfail, $passfail); # a sensor, ribotyper, and combined pass/fail string
  my ($sfailmsg,  $rfailmsg,  $failmsg);  # a sensor, ribotyper, and combined output failure message
  my $doctored_failmsg;     # combined failmsg with errors to ignore removed
  my $found_reqd_error;     # '1' if we find a required error necessary for ignoring a different error (for processing %RFSF_ignore_HAR)
  my $gpipe_failmsg;        # doctored_failmsg converted to gpipe errors
  my $i;                    # a counter
  my $slidx    = 0;         # line number in sensor file we're currently on
  my $rlidx    = 0;         # line number in ribotyper file we're currently on
  my $keep_going = 1;       # flag to keep reading the input files, set to '0' to stop
  my $have_sline = undef;   # '1' if we have a valid sensor line
  my $have_rline = undef;   # '1' if we have a valid ribotyper line
  my $out_lidx = 0;         # number of lines output
  my $failsto_str  = undef; # string of where sequence fails to ('indexer' or 'submitter') or 'pass' or 'unmapped'
  my $error = undef;        # a single error
  my $error2 = undef;       # a different single error

  open(SIN, $sensor_gpipe_file) || die "ERROR unable to open $sensor_gpipe_file for reading in $sub_name"; 
  open(RIN, $ribo_gpipe_file)   || die "ERROR unable to open $ribo_gpipe_file for reading in $sub_name"; 

  # we know that the first few lines of both files are comment lines, that begin with "#", chew them up
  $sline = <SIN>;
  $slidx++;
  while((defined $sline) && ($sline =~ m/^\#/)) { 
    $sline = <SIN>;
    $slidx++;
  }

  $rline = <RIN>;
  $rlidx++;
  while((defined $rline) && ($rline =~ m/^\#/)) { 
    $rline = <RIN>;
    $rlidx++;
  }

  $keep_going = 1;
  while($keep_going) { 
    my $have_sline = ((defined $sline) && ($sline !~ m/^\#/)) ? 1 : 0;
    my $have_rline = ((defined $rline) && ($rline !~ m/^\#/)) ? 1 : 0;
    if($have_sline && $have_rline) { 
      chomp $sline;
      chomp $rline;
      # example lines, the hashes at the left are added here to be able to include the 
      # example lines as comment lines in code
      ##idx  sequence                                       taxonomy  strnd   p/f  error(s)
      ##---  ---------------------------------------------  --------  -----  ----  --------
      #1     00052::Halobacterium_sp.::AE005128                 ?      plus  PASS  -
      #2     00013::Methanobacterium_formicicum::M36508         ?      plus  PASS  -

      my @sel_A = split(/\s+/, $sline);
      my @rel_A = split(/\s+/, $rline);

      if(scalar(@sel_A) != 6) { die "ERROR in $sub_name, unable to parse sensor gpipe line: $sline"; }
      if(scalar(@rel_A) != 6) { die "ERROR in $sub_name, unable to parse ribotyper gpipe line: $rline"; }

      ($sidx, $sseqid, $sclass, $sstrand, $spassfail, $sfailmsg) = (@sel_A);
      ($ridx, $rseqid, $rclass, $rstrand, $rpassfail, $rfailmsg) = (@rel_A);

      if($sidx   != $ridx)   { die "ERROR In $sub_name, index mismatch\n$sline\n$rline\n"; }
      if($sseqid ne $rseqid) { die "ERROR In $sub_name, sequence name mismatch\n$sline\n$rline\n"; }

      if($sstrand ne $rstrand) { 
        if(($sstrand ne "NA") && ($rstrand ne "NA")) { 
          $strand = $sstrand . "(S):" . $rstrand . "(R)";
        }
        elsif(($sstrand eq "NA") && ($rstrand ne "NA")) { 
          $strand = $rstrand;
        }
        elsif(($sstrand ne "NA") && ($rstrand eq "NA")) { 
          $strand = $sstrand;
        }
      }
      else { # $sstrand eq $rstrand
        $strand = $sstrand; 
      } 

      if($rpassfail eq "FAIL") { $passfail  = "RF"; }
      else                     { $passfail  = "RP"; }
      if($spassfail eq "FAIL") { $passfail .= "SF"; }
      else                     { $passfail .= "SP"; }

      if   ($sfailmsg eq "-" && $rfailmsg eq "-") { $failmsg = "-"; }
      elsif($sfailmsg ne "-" && $rfailmsg eq "-") { $failmsg = $sfailmsg; }
      elsif($sfailmsg eq "-" && $rfailmsg ne "-") { $failmsg = $rfailmsg; }
      elsif($sfailmsg ne "-" && $rfailmsg ne "-") { $failmsg = $sfailmsg . $rfailmsg; }

      # look for special cases: 
      # 1. if passfail is "RPSF" then we ignore S_NoHits, S_NoSimilarity, S_LowSimilarity, and S_LowScore (stored in @{$RPSF_ignore_AR})
      # 2. if passfail is "RFSP" then we ignore R_MultipleHits (stored in @{$RFSP_ignore_AR})
      # 3. if passfail is "RFSF" then we ignore S_NoHits, S_NoSimilarity, S_LowSimilarity, S_LowScore IF 
      #                          R_UnacceptableModel or R_QuestionableModel also observed (stored in @{$RFSP_ignore_AR})
      $doctored_failmsg = $failmsg;
      if($passfail eq "RPSF") { 
        foreach $error (@{$RPSF_ignore_AR}) { 
          $doctored_failmsg =~ s/$error\;//;
        }
        if($doctored_failmsg eq "") { $doctored_failmsg = "-"; }
      }
      if($passfail eq "RFSP") { 
        foreach $error (@{$RFSP_ignore_AR}) { 
          $doctored_failmsg =~ s/$error\:\(.+\)\;//; # remember to match the extra description of the error in ()
          $doctored_failmsg =~ s/$error\;//;         # match the error if it is lacking a description
        }
        if($doctored_failmsg eq "") { $doctored_failmsg = "-"; }
      }
      if($passfail eq "RFSF") { 
        foreach $error (sort keys (%{$RFSF_ignore_HAR})) { 
          # first determine if we have a match to any of the errors in @{$RFSF_ignore_HAR->{$error}}
          $found_reqd_error = 0;
          foreach $error2 (@{$RFSF_ignore_HAR->{$error}}) { 
            if($doctored_failmsg =~ m/$error2/) { 
              $found_reqd_error = 1;
              last;
            }
          }
          if($found_reqd_error) { 
            # now remove $error if it exists (not $error2)
            $doctored_failmsg =~ s/$error\:\(.+\)\;//; # remember to match the extra description of the error in ()
            $doctored_failmsg =~ s/$error\;//;         # match the error if it is lacking a description
          }
        }
      }
      $gpipe_failmsg = human_to_gpipe_fail_message($doctored_failmsg, $g2h_HHR, $gerror_AR);

      $failsto_str = output_gpipe_line_with_fails_to($out_FH, $sidx, $sseqid, $rclass, $strand, $passfail, $failmsg, $doctored_failmsg,
                                                     $herror_failsto_HR, $width_HR, $opt_HHR); 
      output_gpipe_line_without_fails_to($gpipe_FH, $sidx, $sseqid, $rclass, $strand, $passfail, $gpipe_failmsg, $width_HR, $opt_HHR); 

      $out_lidx++;
      # update counts of outcomes 
      $outcome_ct_HHR->{"*all*"}{"total"}++;
      $outcome_ct_HHR->{"*all*"}{$failsto_str}++;
      $outcome_ct_HHR->{$passfail}{"total"}++;
      $outcome_ct_HHR->{$passfail}{$failsto_str}++;

      # update counts of errors
      update_error_count_hash(\%{$herror_ct_HHR->{"*all*"}},   ($failmsg eq "-") ? "CLEAN" : $failmsg);
      update_error_count_hash(\%{$herror_ct_HHR->{$passfail}}, ($failmsg eq "-") ? "CLEAN" : $failmsg);
      update_error_count_hash(\%{$gerror_ct_HHR->{"*all*"}},   ($gpipe_failmsg eq "-") ? "CLEAN" : $gpipe_failmsg);
      update_error_count_hash(\%{$gerror_ct_HHR->{$passfail}}, ($gpipe_failmsg eq "-") ? "CLEAN" : $gpipe_failmsg);

      # get new lines
      $sline = <SIN>;
      $rline = <RIN>;
      $slidx++;
      $rlidx++;
    }
    # check for some unexpected errors
    elsif(($have_sline) && (! $have_rline)) { 
      die "ERROR in $sub_name, ran out of sequences from ribotyper gpipe file before sensor gpipe file";
    }
    elsif((! $have_sline) && ($have_rline)) { 
      die "ERROR in $sub_name, ran out of sequences from sensor gpipe file before ribotyper gpipe file"; 
    }
    else { # don't have either line
      $keep_going = 0;
    }
  }

  if($out_lidx == 0) { 
    die "ERROR in $sub_name, did not output information on any sequences"; 
  }

  return;
}

#################################################################
# Subroutine : determine_fails_to_string()
# Incept:      EPN, Mon May 15 10:42:52 2017
#
# Purpose:     Based on the human gpipe errors, determine if 
#              we fail to indexer or submitter. If there are
#              any indexer errors, then we fail to indexer.

#              Input is a string that includes all human gpipe errors separated
#              by semi-colons, determine if this sequence either:
#              1) passes             (return "pass")
#              2) fails to indexer   (return "indexer")
#              3) fails to submitter (return "submitter")
#             
# Arguments: 
#   $failmsg:            all human readable errors separated by ";"
#   $herror_failsto_HR:  ref to hash explaining how each human error fails
#   $opt_HHR:            ref to 2D hash of cmdline options
#
# Returns:     "pass", "submitter", or "indexer"
#
# Dies:       In the unexpected situation in which the sequence has at least
#             one error, but none of the errors can be classified as a
#             submitter error or an indexer error
#
################################################################# 
sub determine_fails_to_string { 
  my $nargs_expected = 3;
  my $sub_name = "determine_fails_to_string";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($failmsg, $herror_failsto_HR, $opt_HHR) = (@_);

  my $to_ignore     = undef;
  my $indexer_error = undef;  # an indexer error
  my $found_submitter = 0; # set to TRUE if we see an submitter error
  my $found_indexer   = 0; # set to TRUE if we see an indexer error
  my @error_A = ();   # array of human errors in $failmsg (after remove those that get ignored)
  my $error;          # an error
  my $error_stripped; # an error without any sequence specific information

  # take care of the easy part
  if($failmsg eq "-") { 
    return "pass";
  }
  else { 
    # look at each error and determine if we have >= 1 submitter errors ($found_submitter)
    # and >= 1 indexer errors ($found_indexer)
    @error_A = split(";", $failmsg);
    foreach $error (@error_A) { 
      $error_stripped = $error;
      $error_stripped =~ s/\:.+$//; # remove ':' and everything after (the sequence specific information)
      if(! exists $herror_failsto_HR->{$error_stripped}) { 
        die "ERROR in $sub_name, unrecognized human error: $error_stripped"; 
      }
      if($herror_failsto_HR->{$error_stripped} eq "indexer") {
        $found_indexer = 1;
      }
      elsif($herror_failsto_HR->{$error_stripped} eq "submitter") {
        $found_submitter = 1;
      }
    }                                                                  
  }
  if((! $found_submitter) && (! $found_indexer)) { 
    die "ERROR in $sub_name, did not find any submitter or indexer errors";
  }
  if($found_submitter) { 
    return "submitter";
  }
  else { 
    # $found_indexer must be true
    return "indexer";
  }
}

#################################################################
# Subroutine : determine_fails_to_string_May15_meeting()
# Incept:      EPN, Mon May 15 10:42:52 2017
#
# Purpose:     Given a 4 character ribotyper/sensor pass fail type
#              of either:
#              RPSP: passes both ribotyper and sensor
#              RPSF: passes ribotyper, fails sensor
#              RFSP: fails ribotyper, passes sensor
#              RFSF: fails both ribotyper and sensor
# 
#              And a string that includes all gpipe errors separated
#              by semi-colons, determine if this sequence either:
#              1) passes             (return "PASS")
#              2) fails to indexer   (return "indexer")
#              3) fails to submitter (return "submitter")
#             
# Arguments: 
#   $pftype:      "RPSP", "RPSF", "RFSP", or "RFSF"
#   $failmsg:     all gpipe error separated by ";"
#   $opt_HHR:     ref to 2D hash of cmdline options
#
# Returns:     "pass", "indexer", or "submitter" 
#
# Dies:        Various conditions in which the pass/fail decision is 
#              inconsistent with the error string
#
################################################################# 
sub determine_fails_to_string_May15_meeting { 
  my $nargs_expected = 3;
  my $sub_name = "determine_fails_to_string_May15_meeting";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($pftype, $failmsg, $opt_HHR) = (@_);

  if($pftype eq "RPSP") { 
    if($failmsg ne "-") { # failmsg should be empty
      die "ERROR in $sub_name, pftype: $pftype, but failmsg is not empty: $failmsg"; 
    }
    return "pass";
  }
  elsif($pftype eq "RFSF") { 
    if($failmsg eq "-") { # failmsg should not be empty
      die "ERROR in $sub_name, pftype: $pftype, but failmsg is empty: $failmsg"; 
    }
    if($failmsg !~ m/S\_/) { # failmsg should contain at least one sensor error
      die "ERROR in $sub_name, pftype: $pftype, but failmsg does not contain a sensor error: $failmsg"; 
    }
    if($failmsg !~ m/R\_/) { # failmsg should contain at least one ribotyper error
      die "ERROR in $sub_name, pftype: $pftype, but failmsg does not contain a ribotyper error: $failmsg"; 
    }

    # can we determine submitter/indexer based on sensor errors? 
    if(($failmsg =~ m/S\_BothStrands/)   || 
       ($failmsg =~ m/S\_LowSimilarity/) || 
       ($failmsg =~ m/S\_NoHits/)) { 
      return "submitter"; 
    }
    elsif($failmsg =~ m/S\_MultipleHits/) { 
      return "indexer"; 
    }
    # we can't determine submitter/indexer based on sensor errors, 
    # can we determine submitter/indexer based on ribotyper errors? 
    elsif(($failmsg =~ m/R\_nohits/) || 
          ($failmsg =~ m/R\_BothStrands/) ||
          ($failmsg =~ m/R\_DuplicateRegion/) ||
          ($failmsg =~ m/R\_InconsistentHits/) ||
          ($failmsg =~ m/R\_LowScore/)) {
      return "submitter";
    }
    elsif(($failmsg =~ m/R\_LowCoverage/)  || 
          ($failmsg =~ m/R\_MultipleNits/) || 
          ($failmsg =~ m/R\_UnacceptableModel/)) { 
      return "indexer";
    }
    else { 
      return "unmapped"; 
      # die "ERROR in $sub_name, unmapped situation $pftype $failmsg\n";
    }
  }
  elsif($pftype eq "RFSP") { 
    if($failmsg eq "-") { # failmsg should not be empty
      die "ERROR in $sub_name, pftype: $pftype, but failmsg is empty: $failmsg"; 
    }
    if($failmsg =~ m/S\_/) { # failmsg should contain at least one sensor error
      die "ERROR in $sub_name, pftype: $pftype, but failmsg contains a sensor error: $failmsg"; 
    }
    if($failmsg !~ m/R\_/) { # failmsg should contain at least one ribotyper error
      die "ERROR in $sub_name, pftype: $pftype, but failmsg does not contain a ribotyper error: $failmsg"; 
    }

    if($failmsg =~ m/R\_MultipleFamilies/) { 
      return "submitter"; 
    }
    elsif($failmsg =~ m/R\_UnacceptableModel/) { 
      return "indexer"; 
    }
    elsif($failmsg =~ m/R\_QuestionableModel/) { 
      return "indexer"; 
    }
    else { 
#      return "indexer*";  # * = share with Alejandro and Eric
      return "indexer";
    }
  }

  elsif($pftype eq "RPSF") {  # most complicated case
    if($failmsg eq "-") { # failmsg should not be empty
      die "ERROR in $sub_name, pftype: $pftype, but failmsg is empty: $failmsg"; 
    }
    if($failmsg !~ m/S\_/) { # failmsg should contain at least one sensor errors
      die "ERROR in $sub_name, pftype: $pftype, but failmsg contains a sensor error: $failmsg"; 
    }
    if($failmsg =~ m/R\_/) { # failmsg should not contain any ribotyper errors
      die "ERROR in $sub_name, pftype: $pftype, but failmsg does not contain a ribotyper error: $failmsg"; 
    }

    my $is_cultured = opt_Get("-c", $opt_HHR);
    if($failmsg =~ m/S\_Misassembly/) { 
      return "submitter";
    }
    if($failmsg eq "S_MultipleHits;") { # HSPproblem is only error
      return "indexer";
    }
    if((($failmsg =~ m/S\_LowSimilarity/) || 
        ($failmsg =~ m/S\_No/)            || 
        ($failmsg =~ m/S\_LowScore/)) # either 'lowsimilarity' or 'no' or 'imperfect_match' error
       && ($failmsg !~ m/S\_BothStrands/)) { # misassembly error not present
      if($is_cultured) { 
        return "submitter";
      }
      else { 
        if($failmsg =~ m/S\_MultipleHits/) { 
          return "indexer";
        }
        else { 
          return "pass";
        }
      }
    }
  }

  die "ERROR in $sub_name, unaccounted for case\npftype: $pftype\nfailmsg: $failmsg\n";
  return ""; # 
}

#################################################################
# Subroutine: output_outcome_counts()
# Incept:     EPN, Mon May 15 11:51:12 2017
#
# Purpose:    Output the tabular outcome counts.
#
# Arguments:
#   $FH:             output file handle
#   $outcome_ct_HHR: ref to the outcome count 2D hash
#   $FH_HR:          ref to hash of file handles, including "cmd"
#
# Returns:  Nothing.
# 
# Dies:     Never.
#
#################################################################
sub output_outcome_counts { 
  my $sub_name = "output_outcome_counts";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $outcome_ct_HHR, $FH_HR) = (@_);

  # determine max width of each column
  my %width_H = ();  # key: name of column, value max width for column
  my $type;          # a 1D key
  my $category;      # a 2D key

  $width_H{"type"}      = length("type");
  $width_H{"total"}     = length("total");
  $width_H{"pass"}      = length("pass");
  $width_H{"indexer"}   = length("indexer");
  $width_H{"submitter"} = length("submitter");
  $width_H{"unmapped"}  = length("unmapped");

  foreach $type (keys %{$outcome_ct_HHR}) { 
    if(length($type) > $width_H{"type"}) { 
      $width_H{"type"} = length($type);
    }
    foreach $category (keys %{$outcome_ct_HHR->{$type}}) { 
      if(length($outcome_ct_HHR->{$type}{$category}) > $width_H{$category}) { 
        $width_H{$category} = length($outcome_ct_HHR->{$type}{$category}); 
      }
    }
  }

  printf $FH ("#\n");
  printf $FH ("# Outcome counts:\n");
  printf $FH ("#\n");
  
  # line 1
  printf $FH ("# %-*s  %*s  %*s  %*s  %*s  %*s\n",
                  $width_H{"type"},      "type",
                  $width_H{"total"},     "total",
                  $width_H{"pass"},      "pass", 
                  $width_H{"indexer"},   "indexer", 
                  $width_H{"submitter"}, "submitter",
                  $width_H{"unmapped"},  "unmapped");
  # line 2
  printf $FH ("# %-*s  %*s  %*s  %*s  %*s  %*s\n", 
                  $width_H{"type"},      ribo_GetMonoCharacterString($width_H{"type"}, "-", $FH_HR),
                  $width_H{"total"},     ribo_GetMonoCharacterString($width_H{"total"}, "-", $FH_HR),
                  $width_H{"pass"},      ribo_GetMonoCharacterString($width_H{"pass"}, "-", $FH_HR),
                  $width_H{"indexer"},   ribo_GetMonoCharacterString($width_H{"indexer"}, "-", $FH_HR),
                  $width_H{"submitter"}, ribo_GetMonoCharacterString($width_H{"submitter"}, "-", $FH_HR),
                  $width_H{"unmapped"},  ribo_GetMonoCharacterString($width_H{"unmapped"}, "-", $FH_HR));
  
  foreach $type ("RPSP", "RPSF", "RFSP", "RFSF", "*all*") { 
    if($type eq "*all*") { print $FH "#\n"; }
    printf $FH ("  %-*s  %*d  %*d  %*d  %*d  %*d\n", 
                $width_H{"type"},      $type,
                $width_H{"total"},     $outcome_ct_HHR->{$type}{"total"}, 
                $width_H{"pass"},      $outcome_ct_HHR->{$type}{"pass"}, 
                $width_H{"indexer"},   $outcome_ct_HHR->{$type}{"indexer"}, 
                $width_H{"submitter"}, $outcome_ct_HHR->{$type}{"submitter"}, 
                $width_H{"unmapped"},  $outcome_ct_HHR->{$type}{"unmapped"}); 
  }

  return;
}

#################################################################
# Subroutine: output_error_counts()
# Incept:     EPN, Tue May 16 09:16:49 2017
#
# Purpose:    Output the tabular error counts for a single category,
#             usually '*all*'.
#
# Arguments:
#   $FH:       output file handle
#   $title:    string to call this table
#   $tot_nseq: total number of sequences in input
#   $ct_HR:    ref to the count 2D hash
#   $key_AR:   ref to array of 1D keys
#   $FH_HR:    ref to hash of file handles, including "cmd"
#
# Returns:  Nothing.
# 
# Dies:     Some error is unrecognized
#
#################################################################
sub output_error_counts { 
  my $sub_name = "output_error_counts";
  my $nargs_expected = 6;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $title, $tot_nseq, $ct_HR, $key_AR, $FH_HR) = (@_);

  # determine max width of each column
  my %width_H = ();  # key: name of column, value max width for column
  my $error;         # an error name, a 1D key

  $width_H{"error"}    = length("error");
  $width_H{"seqs"}     = length("of seqs");
  $width_H{"fraction"} = length("fraction");

  foreach $error (@{$key_AR}) { 
    if(! exists $ct_HR->{$error}) { 
      die "ERROR in $sub_name, count for error $error does not exist";
    }
    if(($ct_HR->{$error} > 0) && (length($error) > $width_H{"error"})) { 
      $width_H{"error"} = length($error);
    }
  }

  printf $FH ("#\n");
  printf $FH ("# $title\n");
  printf $FH ("#\n");
  
  # line 1 
  printf $FH ("# %-*s  %-*s  %*s\n",
                  $width_H{"error"},    "", 
                  $width_H{"seqs"},     "number",
                  $width_H{"fraction"}, "fraction");
  
  # line 2
  printf $FH ("# %-*s  %-*s  %*s\n",
                  $width_H{"error"},    "error", 
                  $width_H{"seqs"},     "of seqs",
                  $width_H{"fraction"}, "of seqs");

  # line 3
  printf $FH ("# %-*s  %-*s  %*s\n", 
                  $width_H{"error"},    ribo_GetMonoCharacterString($width_H{"error"}, "-", $FH_HR),
                  $width_H{"seqs"},     ribo_GetMonoCharacterString($width_H{"seqs"}, "-", $FH_HR),
                  $width_H{"fraction"}, ribo_GetMonoCharacterString($width_H{"fraction"}, "-", $FH_HR));

  foreach $error (@{$key_AR}) { 
    if(($ct_HR->{$error} > 0) || ($error eq "CLEAN")) { 
      printf $FH ("  %-*s  %*d  %*.5f\n", 
                      $width_H{"error"},    $error,
                      $width_H{"seqs"},     $ct_HR->{$error},
                      $width_H{"fraction"}, $ct_HR->{$error} / $tot_nseq);
    }
  }
  printf $FH ("#\n");
  
  return;
  
}


#################################################################
# Subroutine: initialize_hash_of_hash_of_counts()
# Incept:     EPN, Tue May 16 06:26:59 2017
#
# Purpose:    Initialize a 2D hash of counts given arrays that
#             include the 1D and 2D keys.
#
# Arguments:
#   $ct_HHR:  ref to the count 2D hash
#   $key1_AR: ref to array of 1D keys
#   $key2_AR: ref to array of 2D keys
#
# Returns:  Nothing.
# 
# Dies:     Never.
#
#################################################################
sub initialize_hash_of_hash_of_counts { 
  my $sub_name = "initialize_hash_of_hash_of_counts()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($ct_HHR, $key1_AR, $key2_AR) = (@_);
  
  foreach my $key1 (@{$key1_AR}) { 
    %{$ct_HHR->{$key1}} = ();
    foreach my $key2 (@{$key2_AR}) { 
      $ct_HHR->{$key1}{$key2} = 0;
    }
  }

  return;
}

#################################################################
# Subroutine: update_error_count_hash()
# Incept:     EPN, Tue May 16 09:09:07 2017
#
# Purpose:    Update a hash of counts of errors given a string
#             that has those errors separated by a ';'
#             include the 1D and 2D keys.
#
# Arguments:
#   $ct_HR:   ref to the count hash, each key is a possible error
#   $errstr:  string of >= 1 errors, each separated by a ';'
#
# Returns:  Nothing.
# 
# Dies:     Some error is unrecognized.
#
#################################################################
sub update_error_count_hash { 
  my $sub_name = "update_error_count_hash()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($ct_HR, $errstr) = (@_);

  if($errstr eq "-") { die "ERROR in $sub_name, no errors in error string"; }

  my @err_A = split(";", $errstr);
  foreach my $err (@err_A) { 
    if($err =~ m/^R\_/) { # ribotyper error, remove sequence specific info, if any
      $err =~ s/\:.+$//;
    }
    if(! exists $ct_HR->{$err}) { 
      die "ERROR in $sub_name, unknown error string $err"; 
    }
    $ct_HR->{$err}++;
  }

  return;
}

#################################################################
# Subroutine: output_timing_statistics()
# Incept:     EPN, Mon May 15 15:33:17 2017
#
# Purpose:    Output timing statistics in units of seconds. 
#
# Arguments:
#   $FH:            output file handle
#   $tot_nseq:      number of sequences in input file
#   $tot_nnt:       number of nucleotides in input file
#   $ncpu:          number of CPUs used to do searches
#   $ribo_secs:     number of seconds elapased for ribotyper stage
#   $ribo_p_secs:   if -p: summed total elapsed secs required for all ribotyper jobs
#   $sensor_secs:   number of seconds required for sensor
#   $sensor_p_secs: if -p: summed total elapsed secs required for all rRNA_sensor jobs
#   $tot_secs:      number of total seconds for script
#   $opt_HHR:       ref to 2D hash of cmdline options
#   $FH_HR:         ref to hash of file handles, including "cmd"
#
# Returns:  Nothing.
# 
# Dies:     Never.
#
#################################################################
sub output_timing_statistics { 
  my $sub_name = "output_timing_statistics";
  my $nargs_expected = 11;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $tot_nseq, $tot_nnt, $ncpu, $ribo_secs, $ribo_p_secs, $sensor_secs, $sensor_p_secs, $tot_secs, $opt_HHR, $FH_HR) = (@_);

  if($ncpu == 0) { $ncpu = 1; } 

  # get total number of sequences and nucleotides for each round from %{$class_stats_HHR}

  # determine max width of each column
  my %width_H = ();  # key: name of column, value max width for column
  my $stage;         # a class, 1D key in ${%class_stats_HHR}

  $width_H{"stage"}    = length("ribotyper");
  $width_H{"nseq"}     = length("num seqs");
  $width_H{"seqsec"}   = 7;
  $width_H{"ntsec"}    = 10;
  $width_H{"ntseccpu"} = 10;
  $width_H{"total"}    = 23;
  
  my $ribo_secs2print   = undef;
  my $sensor_secs2print = undef;
  if(opt_Get("-p", $opt_HHR)) { 
    $tot_secs         += $ribo_p_secs;
    $tot_secs         += $sensor_p_secs;
    $ribo_secs2print   = $ribo_p_secs;
    $sensor_secs2print = $sensor_p_secs;
  }
  else { 
    $ribo_secs2print   = $ribo_secs;
    $sensor_secs2print = $sensor_secs;
  }

  printf $FH ("#\n");
  printf $FH ("# Timing statistics:\n");
  printf $FH ("#\n");

  # line 1
  printf $FH ("# %-*s  %*s  %*s  %*s  %*s  %-*s\n",
                  $width_H{"stage"},    "stage",
                  $width_H{"nseq"},     "num seqs",
                  $width_H{"seqsec"},   "seq/sec",
                  $width_H{"ntsec"},    "nt/sec",
                  $width_H{"ntseccpu"}, "nt/sec/cpu",
                  $width_H{"total"},    "total time");

  
  # line 2
  printf $FH ("# %-*s  %*s  %*s  %*s  %*s  %*s\n",
                  $width_H{"stage"},    ribo_GetMonoCharacterString($width_H{"stage"},    "-", $FH_HR),
                  $width_H{"nseq"},     ribo_GetMonoCharacterString($width_H{"nseq"},     "-", $FH_HR),
                  $width_H{"seqsec"},   ribo_GetMonoCharacterString($width_H{"seqsec"},   "-", $FH_HR),
                  $width_H{"ntsec"},    ribo_GetMonoCharacterString($width_H{"ntsec"},    "-", $FH_HR),
                  $width_H{"ntseccpu"}, ribo_GetMonoCharacterString($width_H{"ntseccpu"}, "-", $FH_HR),
                  $width_H{"total"},    ribo_GetMonoCharacterString($width_H{"total"},    "-", $FH_HR));
  
  

  $stage = "ribotyper";
  if(opt_Get("--skipsearch", $opt_HHR)) { 
    printf $FH ("  %-*s  %*d  %*s  %*s  %*s  %*s\n", 
                $width_H{"stage"},    $stage,
                $width_H{"nseq"},     $tot_nseq,
                $width_H{"seqsec"},   "-",
                $width_H{"ntsec"},    "-",
                $width_H{"ntseccpu"}, "-",
                $width_H{"total"},    "-");
  }
  else { 
    printf $FH ("  %-*s  %*d  %*.1f  %*.1f  %*.1f  %*s\n", 
                $width_H{"stage"},    $stage,
                $width_H{"nseq"},     $tot_nseq,
                $width_H{"seqsec"},   $tot_nseq / $ribo_secs2print,
                $width_H{"ntsec"},    $tot_nnt  / $ribo_secs2print, 
                $width_H{"ntseccpu"}, ($tot_nnt  / $ribo_secs2print) / $ncpu, 
                $width_H{"total"},    ribo_GetTimeString($ribo_secs2print));
  }
     
  $stage = "sensor";
  if(opt_Get("--skipsearch", $opt_HHR)) { 
    printf $FH ("  %-*s  %*d  %*s  %*s  %*s  %*s\n", 
                $width_H{"stage"},    $stage,
                $width_H{"nseq"},     $tot_nseq,
                $width_H{"seqsec"},   "-",
                $width_H{"ntsec"},    "-",
                $width_H{"ntseccpu"}, "-",
                $width_H{"total"},    "-");
  }
  else { 
    printf $FH ("  %-*s  %*d  %*.1f  %*.1f  %*.1f  %*s\n", 
                $width_H{"stage"},    $stage,
                $width_H{"nseq"},     $tot_nseq,
                $width_H{"seqsec"},   $tot_nseq / $sensor_secs2print,
                $width_H{"ntsec"},    $tot_nnt  / $sensor_secs2print, 
                $width_H{"ntseccpu"}, ($tot_nnt  / $sensor_secs2print) / $ncpu, 
                $width_H{"total"},    ribo_GetTimeString($sensor_secs2print));
  }

  $stage = "total";
  if(opt_Get("--skipsearch", $opt_HHR)) { 
    printf $FH ("  %-*s  %*d  %*s  %*s  %*s  %*s\n", 
                $width_H{"stage"},    $stage,
                $width_H{"nseq"},     $tot_nseq,
                $width_H{"seqsec"},   "-",
                $width_H{"ntsec"},    "-",
                $width_H{"ntseccpu"}, "-",
                $width_H{"total"},    ribo_GetTimeString($tot_secs));
  }
  else { 
    printf $FH ("  %-*s  %*d  %*.1f  %*.1f  %*.1f  %*s\n", 
                $width_H{"stage"},    $stage,
                $width_H{"nseq"},     $tot_nseq,
                $width_H{"seqsec"},   $tot_nseq / $tot_secs,
                $width_H{"ntsec"},    $tot_nnt  / $tot_secs, 
                $width_H{"ntseccpu"}, ($tot_nnt  / $tot_secs) / $ncpu, 
                $width_H{"total"},    ribo_GetTimeString($tot_secs));
  }

  printf $FH ("#\n");
  if(opt_Get("-p", $opt_HHR)) { 
    printf $FH ("# 'ribotyper' and 'sensor' timing statistics are summed elapsed time of multiple jobs [-p]\n");
    printf $FH ("# and do not include time elapsed time spent waiting for those jobs by this process, totalling %s,\n", ribo_GetTimeString($ribo_secs + $sensor_secs));
    printf $FH ("# but that wait time by this process is included in the 'total' timing statistics.\n");
    printf $FH ("#\n");
  }
  
  return;

}

#################################################################
# Subroutine: fetch_seqs_given_gpipe_file()
# Incept:     EPN, Tue May 16 11:38:57 2017
#
# Purpose:    Fetch sequences to a file given the gpipe output file
#             based on the sequence type.
#
# Arguments:
#   $sfetch_exec: path to esl-sfetch executable
#   $seq_file:    sequence file to fetch from 
#   $gpipe_file:  the gpipe file to parse to determine what sequences
#                 to fetch
#   $string:      string to match in column $column of sequences to fetch
#   $column:      column to look for $string in (<= 7)
#   $do_revcomp:  '1' to reverse complement minus strand sequences, '0' not to
#   $sfetch_file: the sfetch file to create for fetching purposes 
#   $subseq_file: the sequence file to create
#   $opt_HHR:     ref to 2D hash of cmdline options
#   $FH_HR:       ref to hash of file handles, including "cmd"
#
# Returns:  Two values:
#           Number of sequences fetched.
#           Number of sequences reversed complemented as they're fetched
#           (second value will always be 0 if $do_revcomp is 0)
#
# Dies:     The argument column has an unexpected value.
#
#################################################################
sub fetch_seqs_given_gpipe_file { 
  my $sub_name = "fetch_seqs_given_gpipe_file()";
  my $nargs_expected = 11;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($sfetch_exec, $seq_file, $gpipe_file, $string, $column, $do_revcomp, $sfetch_file, $subseq_file, $seqlen_HR, $opt_HHR, $FH_HR) = (@_);

  my @el_A           = ();    # array of the space delimited tokens in a line
  my $nseq           = 0;     # number of sequences fetched
  my $nseq_revcomped = 0;     # number of sequences reversed complemented when they're fetched
  my $strand         = undef; # strand of the hit
  my $seqid          = undef; # a sequence id
  my $seqlen         = undef; # length of a sequence

  if(($column <= 0) || ($column > 7)) { 
    die "ERROR in $sub_name, invalid column: $column, should be between 1 and 7"; 
  }

  open(GPIPE,        $gpipe_file) || die "ERROR in $sub_name, unable to open $gpipe_file for reading";
  open(SFETCH, ">", $sfetch_file) || die "ERROR in $sub_name, unable to open $sfetch_file for writing";

  while(my $line = <GPIPE>) { 
    # example lines
    ##idx   sequence                                      taxonomy               strnd              type    failsto  error(s)
    ##----  --------------------------------------------  ---------------------  -----------------  ----  ---------  --------
    #1      gi|290622485|gb|GU635890.1|                   SSU.Bacteria           plus               RPSP       pass  -
    #2      gi|188039824|gb|EU677786.1|                   SSU.Bacteria           plus               RPSP       pass  -
    #3      gi|333495999|gb|JF781658.1|                   SSU.Bacteria           plus               RPSP       pass  -
    #4      gi|269165748|gb|GU035339.1|                   SSU.Bacteria           plus               RPSP       pass  -
    if($line !~ m/^\#/) { 
      @el_A = split(/\s+/, $line);
      if($el_A[($column-1)] =~ m/$string/) { 
        # format of sfetch line: <newname> <start> <end> <sourcename>
        $seqid  = $el_A[1];
        if(! exists $seqlen_HR->{$seqid}) { 
          die "ERROR in $sub_name, no length information for sequence $seqid";
        }
        $seqlen = $seqlen_HR->{$seqid};

        if($do_revcomp) { 
          # determine if sequence is minus strand:
          $strand = determine_strand_given_gpipe_strand($el_A[3], $el_A[4]);
          if($strand eq "minus") { 
            printf SFETCH ("$seqid  $seqlen 1 $seqid\n");
            $nseq_revcomped++;
          }
          else { # not minus strand
            printf SFETCH ("$seqid  1 $seqlen $seqid\n");
          }
        }
        else { # ! $do_revcomp
          printf SFETCH ("$seqid\n");
        }
        $nseq++;
      }
    }
  }
  close(GPIPE);
  close(SFETCH);

  if($nseq > 0) { 
    my $sfetch_cmd;
    if($do_revcomp) { 
      $sfetch_cmd = $sfetch_exec . " -Cf $seq_file $sfetch_file > $subseq_file"; 
    }
    else { 
      $sfetch_cmd = $sfetch_exec . " -f $seq_file $sfetch_file > $subseq_file"; 
    }
    ribo_RunCommand($sfetch_cmd, opt_Get("-v", $opt_HHR), $FH_HR);
  }

  return ($nseq, $nseq_revcomped);
}

#################################################################
# Subroutine: determine_strand_given_gpipe_strand()
# Incept:     EPN, Tue May 16 15:30:53 2017
#
# Purpose:    Given the strand field for a sequence from the GPIPE file,
#             determine if it is 'minus' or 'plus' strand. 
#
# Arguments:
#   $strand:      <s> = 'plus', 'minus', 'NA', or 'mixed', OR <s>(S):<s>(R)
#                 for <s>, we just return <s>, for <s1>(S):<s2>(R) we return
#                 <s2> if ribotyper passed (determine from $type string)
#                 and we return <s1> if ribotyper failed and ribotyper passed
#   $type:        'RPSP', 'RPSF', 'RFSP', /RFSF'
#
# Returns:  "minus", "plus", "mixed", or "NA"
# 
# Dies:  The value of type is not one of the four expected strings
#        listed above; or the value of strand does not meet the
#        syntactic specification above.
#
#################################################################
sub determine_strand_given_gpipe_strand { 
  my $sub_name = "determine_strand_given_gpipe_strand()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($strand, $type) = (@_);

  my $rstrand = undef; # strand predicted by ribotyper
  my $sstrand = undef; # strand predicted by sensor


  if(($strand eq "plus")   || 
     ($strand eq "minus")  || 
     ($strand eq "NA")     || 
     ($strand eq "mixed")) { 
    return $strand;
  }
  elsif($strand =~ /^(\S+)\(S\)(\S+)\(R\)$/) { 
    ($sstrand, $rstrand) = ($1, $2);
    if($type eq "RPSP" || $type eq "RPSF") { 
      return $rstrand;
    }
    elsif($type eq "RFSP") { 
      return $sstrand;
    }
    elsif($type eq "RFSF") { 
      return $strand; # return full string
    }
    else { 
      die "ERROR in $sub_name, unexpected type: $type";
    }
  }
  else { 
    die "ERROR in $sub_name, unable to parse strand value: $strand";
  }

  return; # never reached
}

#################################################################
# Subroutine: define_gpipe_to_human_map()
# Incept:     EPN, Mon May 22 10:28:37 2017
#
# Purpose:    Define the hard-coded mapping between machine and human errors.
#
# Arguments:
#   $m2h_HHR:    ref to 2D hash, key1: machine error, key2: human error,
#                value: '1' if key1 is triggered by key2.
#   $m_AR:       ref to array of machine errors
#   $h_AR:       ref to array of human errors
#
# Returns:  Nothing.
# 
# Dies:     Never.
#
#################################################################
sub define_gpipe_to_human_map { 
  my $sub_name = "define_gpipe_to_human_map()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($m2h_HHR, $m_AR, $h_AR) = (@_);

  my ($gerror, $herror);

  # initialize the empty map
  foreach $gerror (@{$m_AR}) { 
    %{$m2h_HHR->{$gerror}} = ();
    foreach $herror (@{$h_AR}) { 
      $m2h_HHR->{$gerror}{$herror} = 0;
    }
  }

  # now fill in the map
  #1.  SEQ_HOM_NotSSUOrLSUrRNA         submitter   S_NoHits(C), R_NoHits
  #2.  SEQ_HOM_SSUAndLSUrRNA           submitter   R_MultipleFamilies^
  #3.  SEQ_HOM_LowSimilarity           submitter   S_NoSimilarity(C), S_LowSimilarity(C), S_LowScore(C), R_LowScore
  #4.  SEQ_HOM_LengthShort             submitter   S_TooShort(C)^,R_TooShort
  #5.  SEQ_HOM_LengthLong              submitter   S_TooLong(C)^,R_TooLong
  #6.  SEQ_HOM_MisAsBothStrands        submitter   S_BothStrands, R_BothStrands^
  #7.  SEQ_HOM_MisAsHitOrder           submitter   R_InconsistentHits^ (not yet looked for by sensor)
  #8.  SEQ_HOM_MisAsDupRegion          submitter   R_DuplicateRegion^  (not yet looked for by sensor)
  #9.  SEQ_HOM_TaxExpectedSSUrRNA      submitter   R_UnacceptableModel
  #10. SEQ_HOM_TaxQuestionableSSUrRNA  indexer     R_QuestionableModel
  #11. SEQ_HOM_LowCoverage             indexer     R_LowCoverage^
  #12. SEQ_HOM_MultipleHits            indexer     S_MultipleHits, R_MultipleHits^

  $m2h_HHR->{"SEQ_HOM_NotSSUOrLSUrRNA"}{"S_NoHits"} = 1;
  $m2h_HHR->{"SEQ_HOM_NotSSUOrLSUrRNA"}{"R_NoHits"} = 1;

  $m2h_HHR->{"SEQ_HOM_SSUAndLSUrRNA"}{"R_MultipleFamilies"} = 1;

  $m2h_HHR->{"SEQ_HOM_LowSimilarity"}{"S_NoSimilarity"}  = 1;
  $m2h_HHR->{"SEQ_HOM_LowSimilarity"}{"S_LowSimilarity"} = 1;
  $m2h_HHR->{"SEQ_HOM_LowSimilarity"}{"S_LowScore"}      = 1;
  $m2h_HHR->{"SEQ_HOM_LowSimilarity"}{"R_LowScore"}      = 1;

  $m2h_HHR->{"SEQ_HOM_LengthShort"}{"S_TooShort"} = 1;
  $m2h_HHR->{"SEQ_HOM_LengthShort"}{"R_TooShort"} = 1;

  $m2h_HHR->{"SEQ_HOM_LengthLong"}{"S_TooLong"} = 1;
  $m2h_HHR->{"SEQ_HOM_LengthLong"}{"R_TooLong"} = 1;

  $m2h_HHR->{"SEQ_HOM_MisAsBothStrands"}{"S_BothStrands"} = 1;
  $m2h_HHR->{"SEQ_HOM_MisAsBothStrands"}{"R_BothStrands"} = 1;

  $m2h_HHR->{"SEQ_HOM_MisAsHitOrder"}{"R_InconsistentHits"} = 1;

  $m2h_HHR->{"SEQ_HOM_MisAsDupRegion"}{"R_DuplicateRegion"} = 1;

  $m2h_HHR->{"SEQ_HOM_TaxNotExpectedSSUrRNA"}{"R_UnacceptableModel"} = 1;

  $m2h_HHR->{"SEQ_HOM_TaxQuestionableSSUrRNA"}{"R_QuestionableModel"} = 1;

  $m2h_HHR->{"SEQ_HOM_LowCoverage"}{"R_LowCoverage"} = 1; 

  $m2h_HHR->{"SEQ_HOM_MultipleHits"}{"S_MultipleHits"} = 1;
  $m2h_HHR->{"SEQ_HOM_MultipleHits"}{"R_MultipleHits"} = 1;

  return;
}

#################################################################
# Subroutine: define_failsto_hash()
# Incept:     EPN, Tue May 30 10:31:32 2017
#
# Purpose:    Define what each type of human error fails to:
#             'submitter', 'indexer' or 'NONE'
#
# Arguments:
#   $herror_AR:         ref to array of all human errors
#   $indexer_AR:        ref to array of all indexer errors
#   $herror_failsto_HR: ref to hash of to fill in this subroutine
#
# Returns:  Nothing.
# 
# Dies:     Never.
#
#################################################################
sub define_failsto_hash {
  my $sub_name = "define_failsto_hash";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($herror_AR, $indexer_AR, $herror_failsto_HR) = (@_);

  my $error;

  foreach $error (@{$herror_AR}) { 
    if($error eq "CLEAN") { 
      $herror_failsto_HR->{$error} = "NONE";
    }
    else { 
      $herror_failsto_HR->{$error} = "submitter";
    }
  }
  foreach $error (@{$indexer_AR}) { 
    $herror_failsto_HR->{$error} = "indexer";
  }

  return;
}

#################################################################
# Subroutine: human_to_gpipe_fail_message()
# Incept:     EPN, Mon May 22 10:46:43 2017
#
# Purpose:    Given an human fail message, convert it to a 'machine' one.
#
# Arguments:
#   $h_failmsg:  the human readable fail message
#   $g2h_HHR:    ref to 2D hash, key1: gpipe error, key2: human error,
#                value: '1' if key1 is triggered by key2.
#   $g_AR:       ref to array of gpipe errors, in order we want them
#                output
#
# Returns:  The machine fail message.
# 
# Dies:     If an error string is not recognized
#
#################################################################
sub human_to_gpipe_fail_message { 
  my $sub_name = "human_to_gpipe_fail_message()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($h_failmsg, $g2h_HHR, $g_AR) = (@_);

  my $gerr    = undef; # a gpipe error
  my $herr    = undef; # a human error
  my $i       = 0;     # counter over gpipe errors
  my $j       = 0;     # counter over human errors
  my @herr_A  = ();    # array of human errors
  my $n_herr  = 0;     # size of @herr_A
  my $n_gerr  = 0;     # size of @{$g_AR}
  my $ret_str = "";

  $n_gerr = scalar(@{$g_AR});
  if($h_failmsg eq "-") { 
    return "-";
  }
  else { 
    @herr_A = split(";", $h_failmsg);
    $n_herr = scalar(@herr_A);
    # remove sequence specific information
    for($j = 0; $j < $n_herr; $j++) { 
      if($herr_A[$j] =~ m/^R\_/) { # ribotyper error, remove sequence specific info, if any
        $herr_A[$j] =~ s/\:.+$//;
      }
    }
    
    for($i = 0; $i < $n_gerr; $i++) { 
      $gerr = $g_AR->[$i];
      for($j = 0; $j < $n_herr; $j++) { 
        $herr = $herr_A[$j];
        if(! exists ($g2h_HHR->{$gerr}{$herr})) { 
          die "ERROR in $sub_name, no map entry for machine error: $gerr and human error: $herr"; 
        }
        if($g2h_HHR->{$gerr}{$herr} == 1) { 
          $ret_str .= $gerr . ";";
          $j = $n_herr; # breaks loop because we only want to print each GPIPE error once
        }
      }
    }
    return $ret_str;
  }
  
  return ""; # not reached
}

#################################################################
# Subroutine : parse_modelinfo_file()
# Incept:      EPN, Tue Oct 16 14:54:17 2018
#
# Purpose:     Parse a model info input file and verify all 
#              required files exist, and that the blast DB 
#              is in the 
#              BLAST DB exists.
#              
# Arguments: 
#   $modelinfo_file:    file to parse
#   $blastdbcmd:        path to 'blastdbcmd' executable
#   $in_mode:           mode we are running, default is "16S"
#   $df_ribo_model_dir: default $RIBODIR/models directory, where default models should be
#   $df_sensor_dir:     default $SENSORDIR directory, where default blast DBs should be
#   $opt_HHR:           ref to 2D hash of cmdline options (needed to determine if -i was used)
#   $FH_HR:             ref to hash of file handles, including "cmd"
#
# Returns:     3 values:
#              $sensor_blastdb:      name of BLAST DB to supply to rRNA_sensor
#              $ribo_modelinfo_file: path to ribotyper model info file to supply to ribotyper
#              $ribo_accept_file:    path to ribotyper accept file to supply to ribotyper
# 
# Dies:        - If $modelinfo_file cannot be opened.
#              - If BLAST DB read from relevant line of $modelinfo_file is not in $BLASTDB path
#              - If $mode doesn't exist in $modelinfo_file
#              - If ribo model info file listed in $modelinfo_file does not exist              
#              - If ribo accept file listed in $modelinfo_file does not exist              
#
################################################################# 
sub parse_modelinfo_file { 
  my $nargs_expected = 7;
  my $sub_name = "parse_modelinfo_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($modelinfo_file, $blastdbcmd, $in_mode, $df_ribo_model_dir, $df_sensor_dir, $opt_HHR, $FH_HR) = @_;

  my $opt_i_used        = opt_IsUsed("-i", $opt_HHR);
  my $modelinfo_in_df;     # flag for whether we found model info file in default dir or not
  my $modelinfo_in_nondf;  # flag for whether we found model info file in non-default dir or not
  my $accept_in_df;        # flag for whether we found accept file in default dir or not
  my $accept_in_nondf;     # flag for whether we found accept file in non-default dir or not
  my $ret_ribo_modelinfo_file = undef;
  my $ret_ribo_accept_file = undef;
  my $ret_sensor_blastdb   = undef;

  # determine directory that $modelinfo_file exists in if -i used, all files must 
  # either be in this directory or in $ribo_model_dir
  my $non_df_modelinfo_dir = undef; # directory with modelinfo file, if -i used
  if($opt_i_used) { 
    $non_df_modelinfo_dir = ribo_GetDirPath($modelinfo_file);
  }

  # actually parse modelinfo file: 
  # example lines:
  # ---
  # 16S 16S_centroids      ribo.0p20.modelinfo ribosensor.0p30.ssu-arc-bac.accept
  # 18S 18S_centroids.1091 ribo.0p20.modelinfo ribosensor.0p30.ssu-euk.accept
  # ---
  my $found_mode = 0;
  open(IN, $modelinfo_file) || ofile_FileOpenFailure($modelinfo_file, "RIBO", $sub_name, $!, "reading", $FH_HR);
  while(my $line = <IN>) { 
    if($line !~ m/^\#/ && $line =~ m/\w/) { # skip comment lines and blank lines
      chomp $line;
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 4) { 
        ofile_FAIL("ERROR didn't read 4 tokens in model info input file $modelinfo_file, line $line", "RIBO", 1, $FH_HR);
      }
      my($mode, $sensor_blastdb, $ribo_modelinfo_file, $ribo_accept_file) = (@el_A);
      if($mode eq $in_mode) { # we found our mode, now verify that required files exist
        if($found_mode) { 
          ofile_FAIL("ERROR in $sub_name, two lines match mode $in_mode", "RIBO", 1, $ofile_info_HH{"FH"});
        }
        $found_mode = 1;
        $ret_sensor_blastdb = $sensor_blastdb; # we don't verify that this exists
        # make sure this blastdb exists, if this command does not fail, then it does
        ribo_RunCommand("$blastdbcmd -info -db $ret_sensor_blastdb > /dev/null", opt_Get("-v", $opt_HHR), $ofile_info_HH{"FH"});

        # make sure that the ribotyper modelinfo file exists, either in $df_ribo_model_dir or, if
        # -i was used, in the same directory that $modelinfo_file is in
        my $df_ribo_modelinfo_file = $df_ribo_model_dir . $ribo_modelinfo_file;
        my $df_ribo_accept_file    = $df_ribo_model_dir . $ribo_accept_file;
        if($opt_i_used) { 
          my $non_df_ribo_modelinfo_file = $non_df_modelinfo_dir . $ribo_modelinfo_file;
          my $non_df_ribo_accept_file    = $non_df_modelinfo_dir . $ribo_accept_file;
          my $modelinfo_in_nondf = ribo_CheckIfFileExistsAndIsNonEmpty($non_df_ribo_modelinfo_file, undef, $sub_name, 0, $FH_HR); # don't die if it doesn't exist
          my $modelinfo_in_df    = ribo_CheckIfFileExistsAndIsNonEmpty($df_ribo_modelinfo_file,     undef, $sub_name, 0, $FH_HR); # don't die if it doesn't exist
          my $accept_in_nondf    = ribo_CheckIfFileExistsAndIsNonEmpty($non_df_ribo_accept_file, undef, $sub_name, 0, $FH_HR); # don't die if it doesn't exist
          my $accept_in_df       = ribo_CheckIfFileExistsAndIsNonEmpty($df_ribo_accept_file,     undef, $sub_name, 0, $FH_HR); # don't die if it doesn't exist

          # check for modelinfo file: if it exists in both places, use the -i specified version
          if(($modelinfo_in_nondf == 0) && ($modelinfo_in_df == 0)) { 
            ofile_FAIL("ERROR in $sub_name, looking for model info file $ribo_modelinfo_file, did not find it in the two places it's looked for:\ndirectory $non_df_modelinfo_dir (where model info file specified with -i is) AND\ndirectory $df_ribo_model_dir (default model directory)\n", "RIBO", 1, $ofile_info_HH{"FH"});
          }
          elsif(($modelinfo_in_nondf == -1) && ($modelinfo_in_df == 0)) { 
            ofile_FAIL("ERROR in $sub_name, looking for model file $ribo_modelinfo_file, it exists as $non_df_ribo_modelinfo_file but is empty", "RIBO", 1, $ofile_info_HH{"FH"});
          }
          elsif(($modelinfo_in_nondf == 0) && ($modelinfo_in_df == -1)) { 
            ofile_FAIL("ERROR in $sub_name, looking for model file $ribo_modelinfo_file, it exists as $df_ribo_modelinfo_file but is empty", "RIBO", 1, $ofile_info_HH{"FH"});
          }
          elsif($modelinfo_in_nondf == 1) { 
            $ret_ribo_modelinfo_file = $non_df_ribo_modelinfo_file;
          }
          elsif($modelinfo_in_df == 1) { 
            $ret_ribo_modelinfo_file = $df_ribo_modelinfo_file;
          }
          else { 
            ofile_FAIL("ERROR in $sub_name, looking for ribotyper modelinfo file $ribo_modelinfo_file, unexpected situation (in_nondf: $modelinfo_in_nondf, in_df: $modelinfo_in_df)\n", "RIBO", 1, $ofile_info_HH{"FH"});
          }

          # check for accept file: if it exists in both places, use the -i specified version
          if(($accept_in_nondf == 0) && ($accept_in_df == 0)) { 
            ofile_FAIL("ERROR in $sub_name, looking for model info file $ribo_modelinfo_file, did not find it in the two places it's looked for:\ndirectory $non_df_modelinfo_dir (where model info file specified with -i is) AND\ndirectory $df_ribo_model_dir (default model directory)\n", "RIBO", 1, $ofile_info_HH{"FH"});
          }
          elsif(($accept_in_nondf == -1) && ($accept_in_df == 0)) { 
            ofile_FAIL("ERROR in $sub_name, looking for model file $ribo_modelinfo_file, it exists as $non_df_ribo_modelinfo_file but is empty", "RIBO", 1, $ofile_info_HH{"FH"});
          }
          elsif(($accept_in_nondf == 0) && ($accept_in_df == -1)) { 
            ofile_FAIL("ERROR in $sub_name, looking for model file $ribo_modelinfo_file, it exists as $df_ribo_modelinfo_file but is empty", "RIBO", 1, $ofile_info_HH{"FH"});
          }
          elsif($accept_in_nondf == 1) { 
            $ret_ribo_accept_file = $non_df_ribo_accept_file;
          }
          elsif($accept_in_df == 1) { 
            $ret_ribo_accept_file = $df_ribo_accept_file;
          }
          else { 
            ofile_FAIL("ERROR in $sub_name, looking for ribotyper modelinfo file $ribo_accept_file, unexpected situation (in_nondf: $accept_in_nondf, in_df: $accept_in_df)\n", "RIBO", 1, $ofile_info_HH{"FH"});
          }
        } #end of 'if($opt_is_used)'
        else { # $opt_i_used is FALSE, -i not used, models must be in $df_model_dir
          ribo_CheckIfFileExistsAndIsNonEmpty($df_ribo_modelinfo_file, "model file name read from default model info file", $sub_name, 1, $FH_HR); # die if it doesn't exist
          ribo_CheckIfFileExistsAndIsNonEmpty($df_ribo_accept_file, "accept file name read from default model info file", $sub_name, 1, $FH_HR); # die if it doesn't exist
          $ret_ribo_modelinfo_file = $df_ribo_modelinfo_file;
          $ret_ribo_accept_file = $df_ribo_accept_file;
        }
      }
    }
  }
  close(IN);

  if(! $found_mode) { 
    if($opt_i_used) { 
      ofile_FAIL("ERROR in $sub_name, didn't find mode $in_mode listed as first token\nin modelinfo file $modelinfo_file (specified with -i)", "RIBO", 1, $FH_HR); 
    }
    else { 
      ofile_FAIL("ERROR in $sub_name, didn't find mode $in_mode listed as first token\nin default modelinfo file. Is your RIBODIR env variable set correctly?", "RIBO", 1, $FH_HR);
    }
  }

  return ($ret_sensor_blastdb, $ret_ribo_modelinfo_file, $ret_ribo_accept_file);
}
