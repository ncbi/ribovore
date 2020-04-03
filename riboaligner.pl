#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

require "epn-options.pm";
require "epn-ofile.pm";
require "ribo.pm";

# make sure required environment variables are set
my $env_ribotyper_dir    = ribo_VerifyEnvVariableIsValidDir("RIBODIR");
my $env_riboinfernal_dir = ribo_VerifyEnvVariableIsValidDir("RIBOINFERNALDIR");
my $env_riboeasel_dir    = ribo_VerifyEnvVariableIsValidDir("RIBOEASELDIR");
my $env_ribotime_dir     = ribo_VerifyEnvVariableIsValidDir("RIBOTIMEDIR");
my $df_model_dir         = $env_ribotyper_dir . "/models/";

my %execs_H = (); # hash with paths to all required executables
$execs_H{"cmalign"}      = $env_riboinfernal_dir . "/cmalign";
$execs_H{"esl-sfetch"}   = $env_riboeasel_dir    . "/esl-sfetch";
$execs_H{"esl-alimanip"} = $env_riboeasel_dir    . "/esl-alimanip";
$execs_H{"esl-alimerge"} = $env_riboeasel_dir    . "/esl-alimerge";
$execs_H{"esl-reformat"} = $env_riboeasel_dir    . "/esl-reformat";
$execs_H{"ribotyper"}    = $env_ribotyper_dir    . "/ribotyper.pl";
$execs_H{"time"}         = $env_ribotime_dir  . "/time";
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
#                 "setby":        '1' if option set by the user, else 'undef'
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
#     option            type       default               group   requires incompat    preamble-output                                     help-output    
opt_Add("-h",           "boolean", 0,                        0,    undef, undef,      undef,                                              "display this help",                                  \%opt_HH, \@opt_order_A);
opt_Add("-f",           "boolean", 0,                        1,    undef, undef,      "forcing directory overwrite",                      "force; if <output directory> exists, overwrite it",  \%opt_HH, \@opt_order_A);
opt_Add("-b",           "integer", 10,                       1,    undef, undef,      "number of positions <n> to look for indels",       "number of positions <n> to look for indels at the 5' and 3' boundaries",  \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                                       "be verbose; output commands to stdout as they're run", \%opt_HH, \@opt_order_A);
opt_Add("-n",           "integer", 1,                        1,    undef, "-p",       "use <n> CPUs",                                     "use <n> CPUs", \%opt_HH, \@opt_order_A);
opt_Add("-i",           "string",  undef,                    1,    undef, undef,      "use model info file <s> instead of default",       "use model info file <s> instead of default", \%opt_HH, \@opt_order_A);
opt_Add("--keep",       "boolean", 0,                        1,    undef, undef,      "keep all intermediate files",                      "keep all intermediate files that are removed by default", \%opt_HH, \@opt_order_A);

# options related to the ribotyper call
$opt_group_desc_H{"2"} = "options related to the internal call to ribotyper.pl";
opt_Add("--riboopts",   "string",  undef,                    2,    undef, undef,      "read command line options for ribotyper from <s>",     "read command line options to supply to ribotyper from file <s>", \%opt_HH, \@opt_order_A);
opt_Add("--noscfail",   "boolean", 0,                        2,    undef, undef,      "do not fail sequences in ribotyper with low scores",   "do not fail sequences in ribotyper with low scores", \%opt_HH, \@opt_order_A);
opt_Add("--nocovfail",  "boolean", 0,                        2,    undef, undef,      "do not fail sequences in ribotyper with low coverage", "do not fail sequences in ribotyper with low coverage", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"3"} = "options for parallelizing cmsearch and cmalign on a compute farm";
#     option            type       default                group   requires incompat    preamble-output                                          help-output    
opt_Add("-p",           "boolean", 0,                         3,    undef, undef,      "parallelize ribotyper and cmalign on a compute farm",   "parallelize ribotyper and cmalign on a compute farm",    \%opt_HH, \@opt_order_A);
opt_Add("-q",           "string",  undef,                     3,     "-p", undef,      "use qsub info file <s> instead of default",             "use qsub info file <s> instead of default", \%opt_HH, \@opt_order_A);
opt_Add("-s",           "integer", 181,                       3,     "-p", undef,      "seed for random number generator is <n>",               "seed for random number generator is <n>", \%opt_HH, \@opt_order_A);
opt_Add("--nkb",        "integer", 100,                       3,     "-p", undef,      "number of KB of seq for each farm job is <n>",          "number of KB of sequence for each farm job is <n>",  \%opt_HH, \@opt_order_A);
opt_Add("--wait",       "integer", 500,                       3,     "-p", undef,      "allow <n> minutes for jobs on farm",                    "allow <n> wall-clock minutes for jobs on farm to finish, including queueing time", \%opt_HH, \@opt_order_A);
opt_Add("--errcheck",   "boolean", 0,                         3,     "-p", undef,      "consider any farm stderr output as indicating a job failure", "consider any farm stderr output as indicating a job failure", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: riboaligner.pl [-options] <fasta file to annotate> <output file name root>\n";
$usage      .= "\n";
my $synopsis = "riboaligner.pl :: classify lengths of ribosomal RNA sequences";
my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"}, 
                'f'            => \$GetOptions_H{"-f"}, 
                'b=s'          => \$GetOptions_H{"-b"},
                'n=s'          => \$GetOptions_H{"-n"},
                'v'            => \$GetOptions_H{"-v"},
                'i=s'          => \$GetOptions_H{"-i"},
                'keep'         => \$GetOptions_H{"--keep"},
                'riboopts=s'   => \$GetOptions_H{"--riboopts"},
                'noscfail'     => \$GetOptions_H{"--noscfail"},
                'nocovfail'    => \$GetOptions_H{"--nocovfail"}, 
                # options for parallelization
                'p'            => \$GetOptions_H{"-p"},
                'q=s'          => \$GetOptions_H{"-q"},
                's=s'          => \$GetOptions_H{"-s"},
                'nkb=s'        => \$GetOptions_H{"--nkb"},
                'maxnjobs=s'   => \$GetOptions_H{"--maxnjobs"},
                'wait=s'       => \$GetOptions_H{"--wait"},
                'errcheck'     => \$GetOptions_H{"--errcheck"});

my $total_seconds     = -1 * ribo_SecondsSinceEpoch(); # by multiplying by -1, we can just add another ribo_SecondsSinceEpoch call at end to get total time
my $executable        = $0;
my $date              = scalar localtime();
my $version           = "0.39";
my $releasedate       = "April 2020";
my $package_name      = "ribovore";
my $ribotyper_model_version_str   = "0p20"; 
my $riboaligner_model_version_str = "0p15";
my $qsub_version_str  = "0p32"; 

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
  print "\nTo see more help on available options, enter 'riboaligner.pl -h'\n\n";
  exit(1);
}
my ($seq_file, $dir_out) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

my $cmd         = undef; # a command to be run by ribo_RunCommand()
my @early_cmd_A = (); # array of commands we run before our log file is opened
my @to_remove_A = ();    # array of files to remove at end
my $ncpu        = opt_Get("-n", \%opt_HH); # number of CPUs to use with search command (default 0: --cpu 0)
my $nbound      = opt_Get("-b", \%opt_HH); # number of positions to check for indels at 5' and 3' boundaries
if($ncpu == 1) { $ncpu = 0; } # prefer --cpu 0 to --cpu 1

# if $dir_out already exists remove it only if -f also used
if(-d $dir_out) { 
  $cmd = "rm -rf $dir_out";
  if(opt_Get("-f", \%opt_HH)) { ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef); push(@early_cmd_A, $cmd); }
  else                        { die "ERROR intended output directory named $dir_out already exists. Remove it, or use -f to overwrite it."; }
}
elsif(-e $dir_out) { 
  $cmd = "rm $dir_out";
  if(opt_Get("-f", \%opt_HH)) { ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef); push(@early_cmd_A, $cmd); }
  else                        { die "ERROR a file matching the name of the intended output directory $dir_out already exists. Remove the file, or use -f to overwrite it."; }
}
# if $dir_out does not exist, create it
if(! -d $dir_out) { 
  $cmd = "mkdir $dir_out";
  ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef); push(@early_cmd_A, $cmd); 
}
my $dir_out_tail = $dir_out;
$dir_out_tail    =~ s/^.+\///; # remove all but last dir
my $out_root     = $dir_out .   "/" . $dir_out_tail   . ".riboaligner";


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
$extra_H{"\$RIBOINFERNALDIR"} = $env_riboinfernal_dir;
$extra_H{"\$RIBOEASELDIR"}    = $env_riboeasel_dir;
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
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, "RIBO", "list", $out_root . ".list", 1, "List and description of all output files");
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, "RIBO", "log",  $out_root . ".log",  1, "Output printed to screen");
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, "RIBO", "cmd",  $out_root . ".cmd",  1, "List of executed commands");
my $log_FH = $ofile_info_HH{"FH"}{"log"};
my $cmd_FH = $ofile_info_HH{"FH"}{"cmd"};
my $FH_HR  = $ofile_info_HH{"FH"};
# output files are all open, if we exit after this point, we'll need
# to close these first.

# now we have the log file open, output the banner there too
ofile_OutputBanner($log_FH, $package_name, $version, $releasedate, $synopsis, $date, \%extra_H);
opt_OutputPreamble($log_FH, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

# output any commands we already executed to $log_FH
foreach $cmd (@early_cmd_A) { 
  print $cmd_FH $cmd . "\n";
}

# make sure the sequence,qsubinfo and modelinfo files exist
my $df_modelinfo_file = $df_model_dir . "riboaligner." . $riboaligner_model_version_str . ".modelinfo";
my $modelinfo_file = undef;
if(! opt_IsUsed("-i", \%opt_HH)) {
  $modelinfo_file = $df_modelinfo_file;
}
else { 
  $modelinfo_file = opt_Get("-i", \%opt_HH);
}
my $df_qsubinfo_file = $df_model_dir . "ribo." . $qsub_version_str . ".qsubinfo";
my $qsubinfo_file = undef;
# if -p, check for existence of qsub info file
if(! opt_IsUsed("-q", \%opt_HH)) { $qsubinfo_file = $df_qsubinfo_file; }
else                             { $qsubinfo_file = opt_Get("-q", \%opt_HH); }

ribo_CheckIfFileExistsAndIsNonEmpty($seq_file, "sequence file", undef, 1, $ofile_info_HH{"FH"}); # 1 says: die if it doesn't exist or is empty
if(! opt_IsUsed("-i", \%opt_HH)) {
  ribo_CheckIfFileExistsAndIsNonEmpty($modelinfo_file, "default model info file", undef, 1, $ofile_info_HH{"FH"}); # 1 says: die if it doesn't exist or is empty
}
else { # -i used on the command line
  ribo_CheckIfFileExistsAndIsNonEmpty($modelinfo_file, "model info file specified with -i", undef, 1, $ofile_info_HH{"FH"}); # 1 says: die if it doesn't exist or is empty
}
if(! opt_IsUsed("-q", \%opt_HH)) {
  ribo_CheckIfFileExistsAndIsNonEmpty($qsubinfo_file, "default qsub info file", undef, 1, $ofile_info_HH{"FH"}); # '1' says: die if it doesn't exist or is empty
}
else { # -q used on the command line
  ribo_CheckIfFileExistsAndIsNonEmpty($qsubinfo_file, "qsub info file specified with -q", undef, 1, $ofile_info_HH{"FH"}); # 1 says: die if it doesn't exist or is empty
}
# we check for the existence of model files after we parse the model info file, below

# read command line options for ribotyper from file if --riboopts used
my $extra_ribotyper_options = "";
if(opt_IsUsed("--riboopts", \%opt_HH)) { 
  ribo_CheckIfFileExistsAndIsNonEmpty(opt_Get("--riboopts", \%opt_HH), "--riboopts file", undef, 1, $ofile_info_HH{"FH"}); # last argument as 1 says: die if it doesn't exist or is empty
}

# parse --riboopts file
if(opt_IsUsed("--riboopts", \%opt_HH)) { 
  my $ribotyper_file = opt_Get("--riboopts", \%opt_HH);
  open(RIBO, $ribotyper_file) || ofile_FileOpenFailure($ribotyper_file,  "RIBO", "ribolengtchecker.pl::Main", $!, "reading", $FH_HR);
  $extra_ribotyper_options = <RIBO>;
  chomp $extra_ribotyper_options;
  while(<RIBO>) { 
    if($_ =~ m/\w/) { 
      ofile_FAIL("ERROR, expected exactly one line in $ribotyper_file, with command line options for ribotyper, but read more than one line", "RIBO", 1, $FH_HR);
    }
  }
  if($extra_ribotyper_options =~ m/\s*\-f/)          { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include -f, it will be used anyway", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\--keep/)      { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include --keep, use --keep with riboaligner.pl instead", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\-n/)          { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include -n, use -n option with riboaligner.pl instead", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\--scfail/)    { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include --scfail, it will be used anyway", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\--covfail/)   { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include --covfail, it will be used anyway", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\--minusfail/) { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include --minusfail, it will be used anyway", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\--inaccept/)  { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include --inaccept, it will be used anyway", "RIBO", 1, $FH_HR); }
  # options related to parallelization
  if($extra_ribotyper_options =~ m/\s*\-p/)          { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include -p, use -p option with riboaligner.pl instead", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\-q/)          { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include -q, use -q option with riboaligner.pl instead", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\--nkb/)       { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include --nkb, use --nkb option with riboaligner.pl instead", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\--wait/)      { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include --wait, use --wait option with riboaligner.pl instead", "RIBO", 1, $FH_HR); }
  if($extra_ribotyper_options =~ m/\s*\--errcheck/)  { ofile_FAIL("ERROR with --riboopts, command-line options for ribotyper cannot include --errcheck, use --errcheck option with riboaligner.pl instead", "RIBO", 1, $FH_HR); }
  close(RIBO);
}

###########################################################################
# Step 1: Parse/validate input files
###########################################################################
my $progress_w = 48; # the width of the left hand column in our progress output, hard-coded
my $start_secs = ofile_OutputProgressPrior("Validating input files", $progress_w, $log_FH, *STDOUT);

# parse the modelinfo file, this tells us where the CM files are
my @family_order_A     = (); # family names, in order
my %family_modelfile_H = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is CM file for that family
my %family_modellen_H  = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is consensus length for that family
my %family_rtname_HA   = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is array of ribotyper models to align with this family
my $family;
my $qsub_prefix   = undef; # qsub prefix for submitting jobs to the farm
my $qsub_suffix   = undef; # qsub suffix for submitting jobs to the farm
ribo_ParseRAModelinfoFile($modelinfo_file, $df_model_dir, \@family_order_A, \%family_modelfile_H, \%family_modellen_H, \%family_rtname_HA, $ofile_info_HH{"FH"});
# NOTE: the array of ribotyper models in family_rtname_HA for each family should match the models that are assigned to 
# family $family in ribotyper, as encoded in the ribotyper model file, but THIS IS NOT CURRENTLY CHECKED FOR!

# verify the CM files listed in $modelinfo_file exist
foreach $family (@family_order_A) { 
  if(! -s $family_modelfile_H{$family}) { 
    ofile_FAIL("ERROR, model file $family_modelfile_H{$family} specified in $modelinfo_file does not exist or is empty", "RIBO", 1, $FH_HR);
  }
}

# parse qsub file, if nec
if(opt_IsUsed("-p", \%opt_HH)) { 
  ($qsub_prefix, $qsub_suffix) = ribo_ParseQsubFile($qsubinfo_file, $ofile_info_HH{"FH"});
}

# index the fasta file, the index will be used later to fetch with esl-sfetch
my $ssi_file = $seq_file . ".ssi";
# remove it if it already exists
if(-e $ssi_file) { 
  unlink $ssi_file; 
}
ribo_RunCommand($execs_H{"esl-sfetch"} . " --index $seq_file > /dev/null", opt_Get("-v", \%opt_HH), $FH_HR);
if(! -s $ssi_file) { 
  ofile_FAIL("ERROR, tried to create $ssi_file, but failed", "RIBO", 1, $FH_HR); 
} 
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

####################################################
# Step 2: Run ribotyper on the sequence file
####################################################
$start_secs = ofile_OutputProgressPrior("Running ribotyper", $progress_w, $log_FH, *STDOUT);

my $ribotyper_accept_file  = $out_root . ".ribotyper.accept";
my $ribotyper_outdir       = $out_root . "-rt";
my $ribotyper_outdir_tail  = $dir_out_tail . ".riboaligner-rt";
my $ribotyper_outfile      = $out_root . ".ribotyper.out";
my $ribotyper_short_file   = $ribotyper_outdir . "/" . $ribotyper_outdir_tail . ".ribotyper.short.out";
my $ribotyper_long_file    = $ribotyper_outdir . "/" . $ribotyper_outdir_tail . ".ribotyper.long.out";
my $ribotyper_seqstat_file = $ribotyper_outdir . "/" . $ribotyper_outdir_tail . ".ribotyper.seqstat";
my $ribotyper_log_file     = $ribotyper_outdir . "/" . $ribotyper_outdir_tail . ".ribotyper.log";
my $found_family_match;  # set to '1' if a sequence matches one of the families we are aligning for
my @fail_str_A    = (); # array of strings of FAIL sequences to output 
my @nomatch_str_A = (); # array of strings of FAIL sequences to output 
my $rt_opt_p_sum_cpu_secs = 0; # summed elapsed seconds of worker jobs in ribotyper
my $extra_desc = undef; # extra description of a stage

# information about the sequences, which we get by processing the ribotyper seqstat file
my $tot_nnt    = 0;  # total number of nucleotides in target sequence file (summed length of all seqs)
my $nseq       = 0;  # total number of sequences in target sequence file
my @seqorder_A = (); # key: sequence name, value: index of sequence in original input sequence file (1..$nseq)
my %seqidx_H   = (); # key: sequence name, value: index of sequence in original input sequence file (1..$nseq)
my %seqlen_H   = (); # key: sequence name, value: length of sequence
my %width_H    = (); # hash, key is "target", value is maximum length of target

# create the .accept file to supply to ribotyper
my @accept_A = ();
foreach $family (@family_order_A) { push(@accept_A, @{$family_rtname_HA{$family}}); }
ribo_WriteAcceptFile(\@accept_A, $ribotyper_accept_file, $FH_HR);
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", "accept", $ribotyper_accept_file, 0, "accept input file for ribotyper");

# run ribotyper
my $ribotyper_options = " -f --inaccept $ribotyper_accept_file --minusfail "; 
if(opt_IsUsed("-n",            \%opt_HH)) { $ribotyper_options .= " -n " . opt_Get("-n", \%opt_HH); }
if(! opt_IsUsed("--noscfail",  \%opt_HH)) { $ribotyper_options .= " --scfail"; }
if(! opt_IsUsed("--nocovfail", \%opt_HH)) { $ribotyper_options .= " --covfail"; }
if(opt_IsUsed("--keep",        \%opt_HH)) { $ribotyper_options .= " --keep"; }
if(opt_IsUsed("-p",            \%opt_HH)) { $ribotyper_options .= " -p"; }
if(opt_IsUsed("-q",            \%opt_HH)) { $ribotyper_options .= " -q " . opt_Get("-q", \%opt_HH); }
if(opt_IsUsed("-s",            \%opt_HH)) { $ribotyper_options .= " -s " . opt_Get("-s", \%opt_HH); }
if(opt_IsUsed("--nkb",         \%opt_HH)) { $ribotyper_options .= " --nkb " . opt_Get("--nkb", \%opt_HH); }
if(opt_IsUsed("--wait",        \%opt_HH)) { $ribotyper_options .= " --wait " . opt_Get("--wait", \%opt_HH); }
if(opt_IsUsed("--errcheck",    \%opt_HH)) { $ribotyper_options .= " --errcheck"; }
$ribotyper_options .= " " . $extra_ribotyper_options . " ";
ribo_RunCommand($execs_H{"ribotyper"} . " " . $ribotyper_options . " $seq_file $ribotyper_outdir > $ribotyper_outfile", opt_Get("-v", \%opt_HH), $FH_HR);
# if -p: parse the ribotyper log file to get CPU+wait time for parallel
$rt_opt_p_sum_cpu_secs = 0;
if(opt_Get("-p", \%opt_HH)) { 
  $rt_opt_p_sum_cpu_secs = ribo_ParseLogFileForParallelTime($ribotyper_log_file, $FH_HR);
}
$extra_desc = ((opt_Get("-p", \%opt_HH)) && ($rt_opt_p_sum_cpu_secs > 0.)) ? sprintf("(%.1f summed elapsed seconds for all jobs)", $rt_opt_p_sum_cpu_secs) : undef;
ofile_OutputProgressComplete($start_secs, $extra_desc, $log_FH, *STDOUT);

# parse the ribotyper seqstat file
$tot_nnt = ribo_ParseSeqstatFile($ribotyper_seqstat_file, undef, undef, \$nseq, \@seqorder_A, \%seqidx_H, \%seqlen_H, $FH_HR);

# parse ribotyper output and create sfetch input files for sequences to fetch
my %family_sfetch_filename_H = ();  # key: family name, value: sfetch input file name
my %family_sfetch_FH_H       = ();  # key: family name, value: output file handle for sfetch input file
my %family_seqfile_H         = ();  # key: family name, value: fasta file 
my %family_nseq_H            = ();  # key: family name, value: number of sequences in the fasta file $family_seqfile_H{$family}
my %family_nnt_H             = ();  # key: family name, value: number of nucleotides in the fasta file $family_seqfile_H{$family}
foreach $family (@family_order_A) { 
  $family_sfetch_filename_H{$family} = $out_root . "." . $family . ".sfetch";
  $family_seqfile_H{$family}         = $out_root . "." . $family . ".fa";
  $family_nseq_H{$family}            = 0;
  $family_nnt_H{$family}             = 0;
  open($family_sfetch_FH_H{$family}, ">", $family_sfetch_filename_H{$family});
}

open(RIBO, $ribotyper_short_file) || ofile_FileOpenFailure($ribotyper_short_file,  "RIBO", "riboaligner.pl::Main", $!, "reading", $FH_HR);
while(my $line = <RIBO>) { 
  if($line !~ m/^\#/) { 
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 6) { 
      ofile_FAIL("ERROR, unable to parse ribotyper short output file, expected 6 tokens on line:\n$line\n", "RIBO", 1, $FH_HR); 
    }
    my ($seqname, $class, $passfail) = ($el_A[1], $el_A[2], $el_A[4]);
    $found_family_match = 0;
    foreach $family (@family_order_A) { 
      if($class eq $family) { 
        $found_family_match = 1;
        if($passfail eq "PASS") { 
          print { $family_sfetch_FH_H{$family} } ($seqname . "\n");
          $family_nseq_H{$family}++;
          $family_nnt_H{$family} += $seqlen_H{$seqname};
        }
        else { 
          push(@fail_str_A, ($seqname . "\n"));
        }
      }
    }
    if(! $found_family_match) { 
      push(@nomatch_str_A, ($seqname . "\n")); 
    }
  }
}
close(RIBO);

foreach $family (@family_order_A) { 
  close($family_sfetch_FH_H{$family});
  ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . " sfetch file", $family_sfetch_filename_H{$family}, 0, "list file for $family");
}
                                                       
##########################################################
# Step 3: Run cmalign on sequences that passed ribotyper
##########################################################
$start_secs = ofile_OutputProgressPrior(sprintf("Running cmalign and classifying sequence lengths%s", (opt_Get("-p", \%opt_HH)) ? " in parallel across multiple jobs" : ""), $progress_w, $log_FH, *STDOUT);
# for each family to align, run cmalign:
my $nfiles = 0;               # number of fasta files that exist for this sequence directory
my $rtkey_seq_file = undef; # a ribotyper key fasta file
my $cat_cmd;                  # a cat command used to pipe the fasta files into cmalign
my $cmalign_stk_file;         # cmalign output alignment
my $cmalign_insert_file;      # cmalign insert file output
my $cmalign_el_file;          # cmalign EL (local end) file output
my $cmalign_out_file;         # cmalign output 
my %family_length_class_HHA;  # key 1D is family, key 2D is length class (e.g. 'partial'), value is an array of sequences that 
                              # for this family that belong to this length class
my %out_tbl_HH = ();          # hash of hashes with information for output file
                              # key 1 is sequence name, key 2 is a column name, e.g. pred_cmfrom
my $cmalign_opts = " --mxsize 4096. --outformat pfam --cpu $ncpu "; # cmalign options that are consistently used in all cmalign calls
my $opt_p_sum_cpu_secs = 0; # if -p: summed number of elapsed CPU secs all cmsearch jobs required to finish, '0' if -p was not used

foreach $family (@family_order_A) { 
  if(-s $family_sfetch_filename_H{$family}) { 
    # fetch the sequences
    ribo_RunCommand($execs_H{"esl-sfetch"} . " -f $seq_file $family_sfetch_filename_H{$family} > $family_seqfile_H{$family}", opt_Get("-v", \%opt_HH), $FH_HR);
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . " fasta file", $family_seqfile_H{$family}, 0, "sequence file for $family");

    # align the sequences
    my %info_H = ();
    $info_H{"IN:seqfile"}         = $family_seqfile_H{$family};
    $info_H{"IN:modelfile"}       = $family_modelfile_H{$family}; 
    $info_H{"OUT-NAME:ifile"}     = $out_root . "." . $family . ".cmalign.ifile";
    $info_H{"OUT-NAME:elfile"}    = $out_root . "." . $family . ".cmalign.elfile";
    $info_H{"OUT-NAME:stk"}       = $out_root . "." . $family . ".cmalign.stk";
    $info_H{"IN:seqlist"}         = $family_sfetch_filename_H{$family};
    $info_H{"OUT-NAME:stdout"}    = $out_root . "." . $family . ".cmalign.out";
    $info_H{"OUT-NAME:time"}      = $out_root . "." . $family . ".cmalign.time";
    $info_H{"OUT-NAME:stderr"}    = $out_root . "." . $family . ".cmalign.out.err";
    $info_H{"OUT-NAME:qcmd"}      = $out_root . "." . $family . ".cmalign.qcmd";
    ribo_RunCmsearchOrCmalignOrRRnaSensorWrapper(\%execs_H, "cmalign", $qsub_prefix, $qsub_suffix, \%seqlen_H, $progress_w, $out_root, $family_nseq_H{$family}, $family_nnt_H{$family}, $cmalign_opts, \%info_H, \%opt_HH, \%ofile_info_HH);
    $opt_p_sum_cpu_secs = ribo_ParseUnixTimeOutput($info_H{"OUT-NAME:time"}, $ofile_info_HH{"FH"});

    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . " insert file",  $info_H{"OUT-NAME:ifile"},   1, "insert file for $family");
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . " EL file",      $info_H{"OUT-NAME:elfile"},  1, "EL file for $family");
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . " stk file",     $info_H{"OUT-NAME:stk"},     1, "stockholm alignment file for $family");
    ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . " cmalign file", $info_H{"OUT-NAME:stdout"},  1, "cmalign output file for $family");

    # parse cmalign file
    parse_cmalign_file($info_H{"OUT-NAME:stdout"}, \%out_tbl_HH, $FH_HR);

    # parse alignment file
    parse_stk_file($info_H{"OUT-NAME:stk"}, $family_modellen_H{$family}, $nbound, \%out_tbl_HH, \%{$family_length_class_HHA{$family}}, $FH_HR);

    # if we have no more than 100K seqs, convert to stockholm now that we're done parsing it
    if($family_nseq_H{$family} <= 100000) { 
      my $reformat_cmd = $execs_H{"esl-reformat"} . " stockholm " . $info_H{"OUT-NAME:stk"} . " > " . $info_H{"OUT-NAME:stk"} . ".reformat; mv " . $info_H{"OUT-NAME:stk"} . ".reformat " . $info_H{"OUT-NAME:stk"};
      ribo_RunCommand($reformat_cmd, opt_Get("-v", \%opt_HH), $FH_HR);
    }
  }
}

$extra_desc = ((opt_Get("-p", \%opt_HH)) && ($opt_p_sum_cpu_secs > 0.)) ? sprintf("(%.1f summed elapsed seconds for all jobs)", $opt_p_sum_cpu_secs) : undef;
ofile_OutputProgressComplete($start_secs, $extra_desc, $log_FH, *STDOUT);
# add in -p time from ribotyper run
$opt_p_sum_cpu_secs += $rt_opt_p_sum_cpu_secs;

##########################################################
# Step 5: Extract class subsets from cmalign output files
##########################################################
$start_secs = ofile_OutputProgressPrior("Extracting alignments for each length class", $progress_w, $log_FH, *STDOUT);
my $length_class_list_file = undef; # file name for list file for this length class and family
foreach $family (@family_order_A) { 
  my $family_cmalign_stk_file    = $out_root . "." . $family . ".cmalign.stk";
  my $family_cmalign_insert_file = $out_root . "." . $family . ".cmalign.ifile";
  my $family_cmalign_el_file     = $out_root . "." . $family . ".cmalign.elfile";
  my $family_cmalign_out_file    = $out_root . "." . $family . ".cmalign.out";

  foreach my $length_class (sort keys %{$family_length_class_HHA{$family}}) { 
    if(scalar(@{$family_length_class_HHA{$family}{$length_class}}) > 0) { 
      $length_class_list_file = $out_root . "." . $family . "." . $length_class . ".list";
      $cmalign_stk_file       = $out_root . "." . $family . "." . $length_class . ".stk";
      $cmalign_insert_file    = $out_root . "." . $family . "." . $length_class . ".ifile";
      $cmalign_el_file        = $out_root . "." . $family . "." . $length_class . ".elfile";
      $cmalign_out_file       = $out_root . "." . $family . "." . $length_class . ".cmalign";

      open(OUT, ">", $length_class_list_file) || ofile_FileOpenFailure($length_class_list_file,  "RIBO", "ribolengtchecker.pl::Main", $!, "writing", $FH_HR);
      foreach my $seqname (@{$family_length_class_HHA{$family}{$length_class}}) { 
        print OUT $seqname . "\n";
      }
      close(OUT);
      ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . "." . $length_class . "listfile", $length_class_list_file, 1, sprintf("%-18s for %6d %-12s %10s sequences", "List file", scalar(@{$family_length_class_HHA{$family}{$length_class}}), $family, $length_class));

      # extract relevant lines from insert file and EL file:
      subset_from_insert_or_el_or_cmalign_file($family_cmalign_insert_file, $cmalign_insert_file, $family_length_class_HHA{$family}{$length_class}, 0, $FH_HR);
      subset_from_insert_or_el_or_cmalign_file($family_cmalign_el_file,     $cmalign_el_file,     $family_length_class_HHA{$family}{$length_class}, 0, $FH_HR);
      subset_from_insert_or_el_or_cmalign_file($family_cmalign_out_file,    $cmalign_out_file,    $family_length_class_HHA{$family}{$length_class}, 1, $FH_HR);

      # extract subset from the alignment
      ribo_RunCommand($execs_H{"esl-alimanip"} . " --seq-k $length_class_list_file $family_cmalign_stk_file | " . $execs_H{"esl-reformat"} . " --mingap --keeprf stockholm - > $cmalign_stk_file", opt_Get("-v", \%opt_HH), $FH_HR);

      ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . "." . $length_class . "stkfile", $cmalign_stk_file,    1, sprintf("%-18s for %6d %-12s %10s sequences", "Alignment",      scalar(@{$family_length_class_HHA{$family}{$length_class}}), $family, $length_class));
      ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . "." . $length_class . "ifile",   $cmalign_insert_file, 1, sprintf("%-18s for %6d %-12s %10s sequences", "Insert file",    scalar(@{$family_length_class_HHA{$family}{$length_class}}), $family, $length_class));
      ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . "." . $length_class . "EL",      $cmalign_el_file,     1, sprintf("%-18s for %6d %-12s %10s sequences", "EL file",        scalar(@{$family_length_class_HHA{$family}{$length_class}}), $family, $length_class));
      ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, "RIBO", $family . "." . $length_class . "cmalign", $cmalign_out_file,    1, sprintf("%-18s for %6d %-12s %10s sequences", "cmalign output", scalar(@{$family_length_class_HHA{$family}{$length_class}}), $family, $length_class));
    }
  }
}
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
                                                       
##############################
# Create output file and exit.
##############################
my $output_file = $out_root . ".tbl";
output_tabular_file($output_file, $ribotyper_short_file, $nbound, \%out_tbl_HH, $FH_HR);

if((scalar(@fail_str_A) == 0) && (scalar(@nomatch_str_A) == 0)) { 
  ofile_OutputString($log_FH, 1, "#\n# All input sequences passed ribotyper and were aligned.\n");
}
else { 
  if(scalar(@fail_str_A) > 0) { 
    ofile_OutputString($log_FH, 1, sprintf("#\n# WARNING: %d sequence(s) classified as one of:", scalar(@fail_str_A))); 
    foreach $family (@family_order_A) { 
      ofile_OutputString($log_FH, 1, " $family");
    }
    ofile_OutputString($log_FH, 1, ", but FAILed ribotyper:\n");
    foreach my $str (@fail_str_A) { 
      ofile_OutputString($log_FH, 1, "#  " . $str);
    }
  }
  if(scalar(@nomatch_str_A) > 0) {
    ofile_OutputString($log_FH, 1, sprintf("#\n# WARNING: %d sequence(s) were not aligned because they were not classified by ribotyper into one of:", scalar(@nomatch_str_A))); 
    foreach $family (@family_order_A) { 
      ofile_OutputString($log_FH, 1, " $family");
    }
    ofile_OutputString($log_FH, 1, "\n");
    foreach my $str (@nomatch_str_A) { 
      ofile_OutputString($log_FH, 1, "#  " . $str);
    }
  }
  else { 
    ofile_OutputString($log_FH, 1, "#\n# All sequences that passed ribotyper were aligned.\n");
  }
  ofile_OutputString($log_FH, 1, "#\n# See details in:\n#  $ribotyper_short_file\n#  and\n#  $ribotyper_long_file\n#\n");
}

ofile_OutputString($log_FH, 1, "#\n# ribotyper output saved as $ribotyper_outfile\n");
ofile_OutputString($log_FH, 1, "# ribotyper output directory saved as $ribotyper_outdir\n");

ofile_OutputString($log_FH, 1, "#\n# Tabular output saved to file $output_file\n");

$total_seconds += ribo_SecondsSinceEpoch();

if(opt_Get("-p", \%opt_HH)) { 
  ofile_OutputString($log_FH, 1, "#\n");
  ofile_OutputString($log_FH, 1, sprintf("# Elapsed time below does not include summed elapsed time of multiple jobs [-p], totalling %s (does not include waiting time)\n", ribo_GetTimeString($opt_p_sum_cpu_secs)));
  ofile_OutputString($log_FH, 1, "#\n");
}

ofile_OutputConclusionAndCloseFiles($total_seconds, "RIBO", $dir_out, \%ofile_info_HH);

#################################################################
# SUBROUTINES
#################################################################
# List of subroutines:
#
# output_tabular_file
# parse_cmalign_file
# parse_stk_file
# subset_from_insert_or_el_or_cmalign_file
# 
#################################################################
# Subroutine : output_tabular_file()
# Incept:      EPN, Mon Oct 23 16:20:55 2017
#
# Purpose:     Output to the tabular output file, by appending 
#              a few columns to the ribotyper 'short' output file.
#
# Arguments: 
#   $out_tbl_file:     file to output to
#   $ribo_short_file:  ribotyper short output file
#   $nbound:           number of positions we checked for indels
#                      at beginning/end of alignment
#   $out_tbl_HHR:      ref to array of lines to output
#   $FH_HR:            ref to hash of file handles, including "cmd"
#
# Returns:     void
#
################################################################# 
sub output_tabular_file { 
  my $sub_name = "output_tabular_file()";
  my $nargs_expected = 5;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($out_tbl_file, $ribo_short_file, $nbound, $out_tbl_HHR, $FH_HR) = @_; 

  # open the ribotyper short output file for input and output file for output
  open(IN, $ribo_short_file)    || ofile_FileOpenFailure($ribo_short_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  open(OUT, ">", $out_tbl_file) || ofile_FileOpenFailure($out_tbl_file,     "RIBO", $sub_name, $!, "writing", $FH_HR);

  my $line_ctr = 0;
  while(my $line = <IN>) { 
    $line_ctr++;
    if($line !~ m/^\#/ || $line_ctr < 3) { # the $line_ctr < 3 gets the first two header lines
      ##idx  target                          classification         strnd   p/f  unexpected_features
      ##---  ------------------------------  ---------------------  -----  ----  -------------------
      
      #1     gi|631252343|ref|NR_113541.1|   SSU.Archaea            plus   PASS  -
      #2     gi|631253163|ref|NR_114361.1|   SSU.Archaea            plus   PASS  -
      #3     gi|1212229201|ref|NR_148269.1|  SSU.Archaea            plus   PASS  -
      if($line =~ /^(\#?\S+\s+\S+\s+\S+\s+\S+\s+\S+)\s+(\S+)\n/) { 
        my ($prefix, $suffix) = ($1, $2);
        my $seqname = $prefix;
        $seqname =~ s/^\d+\s+//;
        $seqname =~ s/\s+.*//;
        if($line_ctr == 1) { 
          printf OUT ("$prefix  %6s  %6s  %17s  $suffix\n", "mstart", "mstop", "length_class");
        }
        elsif($line_ctr == 2) { 
          printf OUT ("$prefix  %6s  %6s  %17s  $suffix\n", "------", "------", "-----------------");
        }
        elsif(exists $out_tbl_HHR->{$seqname}) { 
          printf OUT ("$prefix  %6d  %6d  %17s  $suffix\n", $out_tbl_HHR->{$seqname}{"pred_cmfrom"}, $out_tbl_HHR->{$seqname}{"pred_cmto"}, $out_tbl_HHR->{$seqname}{"length_class"}); 
        }
        else { # this sequence must not have been aligned
          printf OUT ("$prefix  %6s  %6s  %17s  $suffix\n", "-", "-", "-");
        }
      }
      else { 
        ofile_FAIL("ERROR unable to parse non-comment line of $ribo_short_file:\n$line\n", "RIBO", 1, $FH_HR);
      }
    }
    else { # comment line
      if($line =~ m/Column 6 \[unexpected\_features\]/) { 
        # special case, add the descriptions of the 3 columns that we added:
        printf OUT ("%-33s %s\n", "# Column 6 [mstart]:",       "model start position");
        printf OUT ("%-33s %s\n", "# Column 7 [mstop]:",        "model stop position");
        printf OUT ("%-33s %s\n", "# Column 8 [length_class]:", "classification of length, one of:");
        printf OUT ("%-33s %s\n", "#",                          "'partial:'             does not extend to first model position or final model position");
        printf OUT ("%-33s %s\n", "#",                          "'full-exact':          spans full model and no 5' or 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       and no indels in first or final $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "'full-extra':          spans full model but has 5' and/or 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "'full-ambig-more':     spans full model and no 5' or 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       but has indel(s) in first and/or final $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "                       and insertions outnumber deletions at 5' and/or 3' end");
        printf OUT ("%-33s %s\n", "#",                          "'full-ambig-less':     spans full model and no 5' or 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       but has indel(s) in first and/or final $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "                       and insertions do not outnumber deletions at neither 5' nor 3' end");
        printf OUT ("%-33s %s\n", "#",                          "'5flush-exact':        extends to first but not final model position, has no 5' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       and no indels in first $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "'5flush-extra':        extends to first but not final model position and has 5' inserts");
        printf OUT ("%-33s %s\n", "#",                          "'5flush-ambig-more':   extends to first but not final model position and has no 5' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       but has indel(s) in first $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "                       and insertions outnumber deletions at 5' end");
        printf OUT ("%-33s %s\n", "#",                          "'5flush-ambig-less':   extends to first but not final model position and has no 5' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       but has indel(s) in first $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "                       and insertions do not outnumber deletions at 5' end");
        printf OUT ("%-33s %s\n", "#",                          "'3flush-exact':        extends to final but not first model position, has no 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       and no indels in final $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "'3flush-extra':        extends to final but not first model position and has 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "'3flush-ambig-more':   extends to final but not first model position and has no 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       but has indel(s) in final $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "                       and insertions outnumber deletions at 3' end");
        printf OUT ("%-33s %s\n", "#",                          "'3flush-ambig-less':   extends to final but not first model position and has no 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "                       but has indel(s) in final $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "                       and insertions do not outnumber deletions at 3' end");

        printf OUT ("%-33s %s\n", "# Column 9 [unexpected_features]:", "unexpected/unusual features of sequence (see below)")
      }
      else { # regurgitate other comment lines
        print OUT $line;
      }
    }
  }
  close(IN);
  return;
}

#################################################################
# Subroutine : parse_cmalign_file()
# Incept:      EPN, Fri Aug 18 11:32:24 2017
#
# Purpose:     Parse a cmalign file, storing only the start and end 
#              positions in the model in %{$out_tbl_HHR}.
#              
# Arguments: 
#   $cmalign_file: file to parse
#   $out_tbl_HHR:  ref to array of hashes, with output info
#   $FH_HR:        ref to hash of file handles, including "cmd"
#
# Returns:     void; 
#
################################################################# 
sub parse_cmalign_file { 
  my $nargs_expected = 3;
  my $sub_name = "parse_cmalign_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmalign_file, $out_tbl_HHR, $FH_HR) = @_;

  open(IN, $cmalign_file) || ofile_FileOpenFailure($cmalign_file, "RIBO", $sub_name, $!, "reading", $FH_HR);

  while(my $line = <IN>) { 
##                                                                           running time (s)                 
##                                                                    -------------------------------          
## idx  seq name   length  cm from    cm to  trunc    bit sc  avg pp  band calc  alignment      total  mem (Mb)
## ---  ---------  ------  -------  -------  -----  --------  ------  ---------  ---------  ---------  --------
#    1  NR_043409    1493        1     1477     no   1501.40   0.987       0.37       0.19       0.56     50.52
#    2  NR_043410    1497        1     1477     no   1541.35   0.989       0.36       0.19       0.55     50.55
#    3  NR_029127    1496        1     1477     no   1568.97   0.987       0.38       0.17       0.55     50.16
    chomp $line; 
    if($line !~ /^\#/) { 
      $line =~ s/^\s+//; # remove leading whitespace
      $line =~ s/\s+$//; # remove trailing whitespace
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 12) { ofile_FAIL("ERROR in $sub_name, unexpected number of tokens on cmalign output file line: $line", "RIBO", 1, $FH_HR);  }
      my ($seqname, $cmfrom, $cmto) = ($el_A[1], $el_A[3], $el_A[4]);
      $out_tbl_HHR->{$seqname}{"pred_cmfrom"} = $cmfrom;
      $out_tbl_HHR->{$seqname}{"pred_cmto"}   = $cmto;
    }
  }
  close(IN);
  return;
}

#################################################################
# Subroutine : parse_stk_file()
# Incept:      EPN, Fri Oct 20 15:05:27 2017
#
# Purpose:     Parse a PFAM formatted (one line per seq) alignment
#              and store information in %{$out_tbl_HHR}.
#              
# Arguments: 
#   $stk_file:     file to parse
#   $modellen:     consensus length of the model 
#   $nbound:       number of positions at boundary of model to inspect
#                  when classifying full length sequences as 'exact', 'extra'
#                  or 'ambig'.
#   $out_tbl_HHR:  ref to hash of hashes, with output info, added to here
#   $lenclass_HAR: ref to hash of arrays, key is length class, value is array
#                  of sequences that belong to this class
#   $FH_HR:        ref to hash of file handles, including "cmd"
#
# Returns:     void; 
#
################################################################# 
sub parse_stk_file { 
  my $nargs_expected = 6;
  my $sub_name = "parse_stk_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($stk_file, $modellen, $nbound, $out_tbl_HHR, $lenclass_HAR, $FH_HR) = @_;

  # initialize lenclass_HAR for each length class:
  @{$lenclass_HAR->{"partial"}}           = ();
  @{$lenclass_HAR->{"full-exact"}}        = ();
  @{$lenclass_HAR->{"full-extra"}}        = ();
  @{$lenclass_HAR->{"full-ambig-more"}}   = ();
  @{$lenclass_HAR->{"full-ambig-less"}}   = ();
  @{$lenclass_HAR->{"5flush-exact"}}      = ();
  @{$lenclass_HAR->{"5flush-extra"}}      = ();
  @{$lenclass_HAR->{"5flush-ambig-more"}} = ();
  @{$lenclass_HAR->{"5flush-ambig-less"}} = ();
  @{$lenclass_HAR->{"3flush-exact"}}      = ();
  @{$lenclass_HAR->{"3flush-extra"}}      = ();
  @{$lenclass_HAR->{"3flush-ambig-more"}} = ();
  @{$lenclass_HAR->{"3flush-ambig-less"}} = ();

  # first pass through the file to get the RF line:
  my $line;
  my $rfstr = "";
  open(IN, $stk_file) || ofile_FileOpenFailure($stk_file, "RIBO", $sub_name, $!, "reading", $FH_HR);
  while($line = <IN>) { 
    if($line =~ m/^#=GC RF\s+(\S+)/) { 
      if($rfstr ne "") { 
        ofile_FAIL("ERROR in $sub_name, more than one RF line, alignment is not in Pfam format", "RIBO", 1, $FH_HR); 
      }
      $rfstr = $1;
    }
  }
  close(IN);
  if($rfstr eq "") { 
    ofile_FAIL("ERROR in $sub_name, no RF line found, alignment is not in Pfam format", "RIBO", 1, $FH_HR); 
  }

  # make a map of alignment positions to nongap RF positions
  my $rfpos = 0;  # nongap RF position
  my $apos  = 0; # alignment position
  my @rf_A  = split("", $rfstr);
  my $alen  = scalar(@rf_A);
  my @r2a_map_A = (); # [1..rfpos..rflen], r2a_map_A[$rfpos] = $apos, nongap RF position $rfpos maps to alignment position $apos
  my @i_am_rf_A = (); # [1..apos..alen],   i_am_rf_A[$apos]  = 1 if alignment position is a nongap RF position, else 0
  $r2a_map_A[0] = -1; # invalid element
  $i_am_rf_A[0] = -1; # invalid element
  # nongap RF positions go 1..rflen
  # alignment positions go 1..alen
  for($apos = 0; $apos < $alen; $apos++) { 
    if($rf_A[$apos] =~ m/\w/) { # a word character, this is a reference position
      $rfpos++;
      $r2a_map_A[$rfpos] = $apos+1;
      $i_am_rf_A[($apos+1)] = 1;
    }
    else { 
      $i_am_rf_A[($apos+1)] = 0;
    }
  }
  my $apos_first_rfpos = $r2a_map_A[1];
  my $apos_5p_nbound   = $r2a_map_A[$nbound]; 
  my $apos_3p_nbound   = $r2a_map_A[($modellen - $nbound + 1)]; 
  my $apos_final_rfpos = $r2a_map_A[$modellen];
  # $apos_first_rfpos is the alignment position which is the first nongap in the RF string
  # $apos_5p_nbound is the alignment position that is the $nbound'th nongap in the RF string
  # $apos_3p_nbound is the alignment position that is the ($modellen - $nbound + 1)'th nongap in the RF string
  # $apos_final_rfpos is the alignment position that is the final nongap in the RF string

  # second pass through alignment
  open(IN, $stk_file) || ofile_FAIL("ERROR unable to open cmalign file $stk_file for reading", "RIBO", 1, $FH_HR);
  while($line = <IN>) { 
    if($line !~ m/^#/ && $line =~ m/\w/) { 
      # a sequence line
      if($line =~ /(\S+)\s+(\S+)/) { 
        my ($seqname, $seqstr) = ($1, $2);
        if(! exists $out_tbl_HHR->{$seqname}) { 
          ofile_FAIL("ERROR found sequence in alignment $stk_file without an entry in the output table", "RIBO", 1, $FH_HR); 
        }

        my $i_before_first_rfpos = 0; # number of insertions before RF position 1
        my $i_early              = 0; # number of insertions between RF position 1 and $nbound
        my $d_early              = 0; # number of deletions  between RF position 1 and $nbound
        my $i_after_final_rfpos  = 0; # number of insertions after RF position $modellen
        my $i_late               = 0; # number of insertions between RF position $modellen-$nbound+1 and $modellen
        my $d_late               = 0; # number of insertions between RF position $modellen-$nbound+1 and $modellen
        if($out_tbl_HHR->{$seqname}{"pred_cmfrom"} == 1) { 
          my @seqstr_A = split("", $seqstr);
          # count number of insertions before RF position 1
          for($apos = 1; $apos < $apos_first_rfpos; $apos++) { 
            if($seqstr_A[($apos-1)] =~ m/\w/) { 
              $i_before_first_rfpos++;
            }
          }
          # count number of deletions and insertions between RF position 1 and $nbound
          for($apos = $apos_first_rfpos; $apos <= $apos_5p_nbound; $apos++) { 
            if($i_am_rf_A[$apos]) { # nongap RF position
              if($seqstr_A[($apos-1)] !~ m/\w/) { # a gap: a deletion
                $d_early++;
              }
            }
            else { # gap RF position
              if($seqstr_A[($apos-1)] =~ m/\w/) { # nongap: an insertion
                $i_early++;
              }
            }
          }
        }
        # count number of deletions and insertions between RF position ($modellen-$nbound+1) and $modellen
        if($out_tbl_HHR->{$seqname}{"pred_cmto"}   == $modellen) { 
          my @seqstr_A = split("", $seqstr);
          for($apos = $apos_3p_nbound; $apos <= $apos_final_rfpos; $apos++) { 
            if($i_am_rf_A[$apos]) { # nongap RF position
              if($seqstr_A[($apos-1)] !~ m/\w/) { # a gap: a deletion
                $d_late++;
              }
            }
            else { # gap RF position
              if($seqstr_A[($apos-1)] =~ m/\w/) { # nongap: an insertion
                $i_late++;
              }
            }
          }
          # count number of insertions after RF position $modellen
          for($apos = $apos_final_rfpos+1; $apos <= $alen; $apos++) { 
            if($seqstr_A[($apos-1)] =~ m/\w/) { 
              $i_after_final_rfpos++;
            }
          }
        }

        # classify
        if(($out_tbl_HHR->{$seqname}{"pred_cmfrom"} == 1) &&
           ($out_tbl_HHR->{$seqname}{"pred_cmto"}   == $modellen)) { 
          # spans the full model, classify further as:
          # 'full-exact':       has 0 indels in first and final $nbound RF positions 
          # 'full-extra':       has >=1 inserts before first RF position or after final RF position
          # 'full-ambig-more':  has 0 inserts before first RF position or after final RF position, but
          #                     has >= 1 indel in first or final $nbound RF positions
          #                     and #insertions > #deletions at 5' or 3' end
          # 'full-ambig-less':  has 0 inserts before first RF position or after final RF position, but
          #                     has >= 1 indel in first or final $nbound RF positions
          #                     and #insertions <= #deletions at 5' and 3' end
          if(($i_before_first_rfpos == 0) && ($d_early == 0) && ($i_early == 0) && 
             ($i_after_final_rfpos  == 0) && ($d_late  == 0) && ($i_late  == 0)) { 
            $out_tbl_HHR->{$seqname}{"length_class"} = "full-exact";
            push(@{$lenclass_HAR->{"full-exact"}}, $seqname);
          }
          elsif(($i_before_first_rfpos != 0) || ($i_after_final_rfpos != 0)) { 
            $out_tbl_HHR->{$seqname}{"length_class"} = "full-extra";
            push(@{$lenclass_HAR->{"full-extra"}}, $seqname);
          }
          else { 
            if(($d_late >= $i_late) && ($d_early >= $i_early)) { 
              $out_tbl_HHR->{$seqname}{"length_class"} = "full-ambig-less";
              push(@{$lenclass_HAR->{"full-ambig-less"}}, $seqname);
            }
            else { 
              $out_tbl_HHR->{$seqname}{"length_class"} = "full-ambig-more";
              push(@{$lenclass_HAR->{"full-ambig-more"}}, $seqname);
            }
          }
        } # end of if(($out_tbl_HHR->{$seqname}{"pred_cmfrom"} == 1) &&
          # ($out_tbl_HHR->{$seqname}{"pred_cmto"}   == $modellen)) { 
        elsif($out_tbl_HHR->{$seqname}{"pred_cmfrom"} == 1) { 
          # spans to 5' end, but not 3' end, classify further as:
          # '5flush-exact':      has 0 indels in first $nbound RF positions 
          # '5flush-extra':      has >=1 inserts before first RF position
          # '5flush-ambig-more': has 0 inserts before first RF position, but
          #                      has >= 1 indel in first $nbound RF positions
          #                      and #insertions > #deletions at 5' end
          # '5flush-ambig-less': has 0 inserts before first RF position, but
          #                      has >= 1 indel in first $nbound RF positions
          #                      and #insertions <= #deletions at 5' end
          if(($i_before_first_rfpos == 0) && ($d_early == 0) && ($i_early == 0)) { 
            $out_tbl_HHR->{$seqname}{"length_class"} = "5flush-exact";
            push(@{$lenclass_HAR->{"5flush-exact"}}, $seqname);
          }
          elsif($i_before_first_rfpos != 0) { 
            $out_tbl_HHR->{$seqname}{"length_class"} = "5flush-extra";
            push(@{$lenclass_HAR->{"5flush-extra"}}, $seqname);
          }
          else { 
            if($d_early >= $i_early) { 
              $out_tbl_HHR->{$seqname}{"length_class"} = "5flush-ambig-less";
              push(@{$lenclass_HAR->{"5flush-ambig-less"}}, $seqname);
            }
            else { 
              $out_tbl_HHR->{$seqname}{"length_class"} = "5flush-ambig-more";
              push(@{$lenclass_HAR->{"5flush-ambig-more"}}, $seqname);
            }
          }
        }
        elsif($out_tbl_HHR->{$seqname}{"pred_cmto"} == $modellen) { 
          # spans to 3' end, but not 5' end, classify further as:
          # '3flush-exact':       has 0 indels in final $nbound RF positions 
          # '3flush-extra':       has >=1 inserts before first RF position or after final RF position
          # '3flush-ambig-more':  has 0 inserts before first RF position or after final RF position, but
          #                       has >= 1 indel in first or final $nbound RF positions
          #                       and #insertions > #deletions at 5' or 3' end
          # '3flush-ambig-less':  has 0 inserts before first RF position or after final RF position, but
          #                       has >= 1 indel in first or final $nbound RF positions
          #                       and #insertions <= #deletions at 5' and 3' end
          if(($i_after_final_rfpos  == 0) && ($d_late  == 0) && ($i_late  == 0)) { 
            $out_tbl_HHR->{$seqname}{"length_class"} = "3flush-exact";
            push(@{$lenclass_HAR->{"3flush-exact"}}, $seqname);
          }
          elsif($i_after_final_rfpos != 0) { 
            $out_tbl_HHR->{$seqname}{"length_class"} = "3flush-extra";
            push(@{$lenclass_HAR->{"3flush-extra"}}, $seqname);
          }
          else { 
            if($d_late >= $i_late) { 
              $out_tbl_HHR->{$seqname}{"length_class"} = "3flush-ambig-less";
              push(@{$lenclass_HAR->{"3flush-ambig-less"}}, $seqname);
            }
            else { 
              $out_tbl_HHR->{$seqname}{"length_class"} = "3flush-ambig-more";
              push(@{$lenclass_HAR->{"3flush-ambig-more"}}, $seqname);
            }
          }
        }
        else { 
          # does not extend to either 5' nor 3' end
          $out_tbl_HHR->{$seqname}{"length_class"} = "partial";
          push(@{$lenclass_HAR->{"partial"}}, $seqname);
        }
      }
    }
  }
  close(IN);
  
  return;
}

#################################################################
# Subroutine : subset_from_insert_or_el_or_cmalign_file()
# Incept:      EPN, Mon Jul  9 13:53:42 2018
#
# Purpose:     Given an insert, EL or cmalign output file 
#              and an array of sequences to save output for,
#              save that output to a new file.
#              
# Arguments: 
#   $master_file:  master file to extract subset of lines from
#   $sub_file:     file to create with subset of lines
#   $AR:           ref to array with names of seqs for $sub_file
#   $cmalign_flag: '1' if file is a cmalign output file, '0' if it
#                  is an insert or EL file
#   $FH_HR:        ref to hash of file handles, including "cmd"
#
# Returns:     void; 
#
################################################################# 
sub subset_from_insert_or_el_or_cmalign_file { 
  my $nargs_expected = 5;
  my $sub_name = "subset_from_insert_or_el_or_cmalign_file()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($master_file, $sub_file, $AR, $cmalign_flag, $FH_HR) = @_;

  open(IN,  $master_file)   || ofile_FileOpenFailure($master_file, "RIBO", $sub_name, $!, "reading", $FH_HR);
  open(OUT, ">", $sub_file) || ofile_FileOpenFailure($sub_file,    "RIBO", $sub_name, $!, "reading", $FH_HR);


  my $col_idx = ($cmalign_flag) ? 1 : 0; # if cmalign file, column 1 has sequence name, else column 0 does
  my $noncomment_line_ctr = 0;

  # convert array into a hash of identity
  my %H = ();
  my $el;
  foreach $el (@{$AR}) { 
    $H{$el} = 1; 
  }

  while(my $line = <IN>) { 
    my $print_flag = 0;
    my $orig_line = $line;
    if(($line !~ m/^\#/) && ($line !~ m/^\/\//)) { 
      $noncomment_line_ctr++;
      if(($noncomment_line_ctr == 1) && (! $cmalign_flag)) { 
        $print_flag = 1; # print first non-comment line in EL and insert files
      }
      else { # only print non-comment line if it pertains to a sequence in @{$AR}
        $line =~ s/^\s+//; # remove leading  whitespace
        $line =~ s/\s+$//; # remove trailing whitespace
        my @el_A = split(/\s+/, $line); 
        if(scalar(@el_A) <= $col_idx) { 
          ofile_FAIL("ERROR in $sub_name, unable to parse line, too few elements: $line", "RIBO", 1, $FH_HR);
        }
        if(exists $H{$el_A[$col_idx]}) { 
          if($H{$el_A[$col_idx]} != 1) { 
            ofile_FAIL("ERROR in $sub_name, read $el_A[$col_idx] more than once: $line", "RIBO", 1, $FH_HR);
          }
          $print_flag = 1; 
          $H{$el_A[$col_idx]} = 0;
        }
      }
    }
    else { # line begins with # or //, always print it
      $print_flag = 1;
    }
    if($print_flag) { 
      print OUT $orig_line;
    }
  }
  close(OUT);
  close(IN);
  
  my $failstr = "";
  # make sure each sequence was found
  foreach $el (@{$AR}) { 
    if($H{$el} != 0) { 
      $failstr .= $el . "\n";
    }
  }
  if($failstr ne "") { 
    ofile_FAIL("ERROR in $sub_name, at least one sequence not found in $master_file:\n$failstr", "RIBO", 1, $FH_HR);
  }

  return;
}
