#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

require "epn-options.pm";
require "epn-ofile.pm";
require "ribo.pm";

# make sure the RIBODIR variable is set
my $env_ribotyper_dir     = ribo_VerifyEnvVariableIsValidDir("RIBODIR");
#my $env_infernal_exec_dir = ribo_VerifyEnvVariableIsValidDir("INFERNALDIR");
#my $env_easel_exec_dir    = ribo_VerifyEnvVariableIsValidDir("EASELDIR");
my $df_model_dir          = $env_ribotyper_dir . "/models/";

# make sure the required executables are executable
my %execs_H = (); # key is name of program, value is path to the executable
$execs_H{"ribotyper"}          = $env_ribotyper_dir     . "/ribotyper.pl";
$execs_H{"ribolengthchecker"}  = $env_ribotyper_dir     . "/ribolengthchecker.pl";
# Currently, we require infernal and easel executables are in the user's path, 
# but do not check. The program will die if the commands using them fail. 
# The block below is retained in in case we want to use it eventually.
#$execs_H{"cmalign"}    = $env_infernal_exec_dir . "/cmalign";
#$execs_H{"esl-sfetch"} = $env_easel_exec_dir    . "/esl-sfetch";
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
opt_Add("-f",           "boolean", 0,                        1,    undef, undef,      "forcing directory overwrite",                    "force; if <output directory> exists, overwrite it",  \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                                       "be verbose; output commands to stdout as they're run", \%opt_HH, \@opt_order_A);
opt_Add("-n",           "integer", 1,                        1,    undef, undef,      "use <n> CPUs",                                     "use <n> CPUs", \%opt_HH, \@opt_order_A);
opt_Add("-i",           "string",  undef,                    1,    undef, undef,      "use model info file <s> instead of default",       "use model info file <s> instead of default", \%opt_HH, \@opt_order_A);
opt_Add("--fetch",      "string",  undef,                    1,    undef, "--fasta",  "fetch sequences using seqfetch query in <s>",      "fetch sequences using seqfetch query in <s>",                                  \%opt_HH, \@opt_order_A);
opt_Add("--fasta",      "string",  undef,                    1,    undef, "--fetch",  "sequences provided as fasta input in <s>",         "don't fetch sequences, <s> is fasta file of input sequences",                           \%opt_HH, \@opt_order_A);
## options related to the ribotyper call
#$opt_group_desc_H{"2"} = "options related to the internal call to ribotyper.pl";
#opt_Add("--riboopts",   "string",  undef,                    2,    undef, undef,      "read command line options for ribotyper from <s>",     "read command line options to supply to ribotyper from file <s>", \%opt_HH, \@opt_order_A);
#opt_Add("--noscfail",   "boolean", 0,                        2,    undef, undef,      "do not fail sequences in ribotyper with low scores",   "do not fail sequences in ribotyper with low scores", \%opt_HH, \@opt_order_A);
#opt_Add("--nocovfail",  "boolean", 0,                        2,    undef, undef,      "do not fail sequences in ribotyper with low coverage", "do not fail sequences in ribotyper with low coverage", \%opt_HH, \@opt_order_A);

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
                'i=s'          => \$GetOptions_H{"-i"},
                'fetch=s'      => \$GetOptions_H{"--fetch"},
                'fasta=s'      => \$GetOptions_H{"--fasta"});
#                'riboopts=s'   => \$GetOptions_H{"--riboopts"},
#                'noscfail'     => \$GetOptions_H{"--noscfail"},
#                'nocovfail'    => \$GetOptions_H{"--nocovfail"});

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

#############################
# create the output directory
#############################
my $cmd;              # a command to run with runCommand()
my @early_cmd_A = (); # array of commands we run before our log file is opened
if($dir !~ m/\/$/) { $dir =~ s/\/$//; } # remove final '/' if it exists

if(-d $dir) { 
  $cmd = "rm -rf $dir";
  if(opt_Get("-f", \%opt_HH)) { ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH)); push(@early_cmd_A, $cmd); }
  else                        { die "ERROR directory named $dir already exists. Remove it, or use -f to overwrite it."; }
}
if(-e $dir) { 
  $cmd = "rm $dir";
  if(opt_Get("-f", \%opt_HH)) { ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH)); push(@early_cmd_A, $cmd); }
  else                        { die "ERROR a file named $dir already exists. Remove it, or use -f to overwrite it."; }
}

# create the dir
$cmd = "mkdir $dir";
ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH));
push(@early_cmd_A, $cmd);

my $dir_tail = $dir;
$dir_tail =~ s/^.+\///; # remove all but last dir
my $out_root = $dir . "/" . $dir_tail . ".dnaorg_build";

#############################################
# output program banner and open output files
#############################################
# output preamble
my @arg_desc_A = ("reference accession");
my @arg_A      = ($dir);
my %extra_H    = ();
$extra_H{"\$RIBODIR"} = $env_ribotyper_dir;
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

##############################################################################
# Step 1. Fetch the sequences (if --fetch) or copy the fasta file (if --fasta)
##############################################################################
my $progress_w = 50; # the width of the left hand column in our progress output, hard-coded
my $start_secs;
my $raw_fasta_file = $out_root . ".raw.fa";
my $full_fasta_file = $out_root . ".full.fa";
if(defined $in_fetch_file) { 
  $start_secs = ofile_OutputProgressPrior("Executing command to fetch sequences ", $progress_w, $log_FH, *STDOUT);
  open(FETCH, $in_fetch_file) || ofile_FileOpenFailure($in_fetch_file, $pkgstr, "ribodbcreate.pl:main()", $!, "reading", $ofile_info_HH{"FH"});
  my $fetch_command = <FETCH>; # read only the first line of the file
  chomp $fetch_command;
  if($fetch_command =~ m/\>/) { 
    ofile_FAIL("ERROR, fetch command read from $in_fetch_file includes an output character \>", $pkgstr, $!, $ofile_info_HH{"FH"}); 
  }
  $fetch_command .= " > $raw_fasta_file";
  new_ribo_RunCommand($fetch_command, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
}
else { # $in_fasta_file must be defined
  if(! defined $in_fasta_file) { 
    ofile_FAIL("ERROR, neither --fetch nor --fasta was used, exactly one must be.", $pkgstr, $!, $ofile_info_HH{"FH"}); 
  }
  $start_secs = ofile_OutputProgressPrior("Copying input fasta file ", $progress_w, $log_FH, *STDOUT);
  my $cp_command .= "cp $in_fasta_file $raw_fasta_file";
  new_ribo_RunCommand($cp_command, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
  ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
}

# reformat the names of the sequences:
# gi|675602128|gb|KJ925573.1| becomes KJ925573.1
$start_secs = ofile_OutputProgressPrior("Reformatting names of sequences ", $progress_w, $log_FH, *STDOUT);
my $check_fetched_names_format = (opt_Get("--fetch", \%opt_HH)) ? 1 : 0;
$check_fetched_names_format = 1; # TEMP 
reformat_sequence_names_in_fasta_file($raw_fasta_file, $full_fasta_file, $check_fetched_names_format, $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "fullfa", "$full_fasta_file", 1, "Fasta file with all sequences with names possibly reformatted to accession version");
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

# get lengths of all seqs and create a list of all sequences
my $seqstat_file = $out_root . ".full.seqstat";
my %seqidx_H = (); # key: sequence name, value: index of sequence in original input sequence file (1..$nseq)
my %seqlen_H = (); # key: sequence name, value: length of sequence, 
                   # value multiplied by -1 after we output info for this sequence
                   # in round 1. Multiplied by -1 again after we output info 
                   # for this sequence in round 2. We do this so that we know
                   # that 'we output this sequence already', so if we 
                   # see it again before the next round, then we know the 
                   # tbl file was not sorted properly. That shouldn't happen,
                   # but if somehow it does then we want to know about it.
$start_secs = ofile_OutputProgressPrior("Determining target sequence lengths", $progress_w, $log_FH, *STDOUT);
ribo_ProcessSequenceFile("esl-seqstat", $full_fasta_file, $seqstat_file, \%seqidx_H, \%seqlen_H, undef, \%opt_HH);
my $nseq = scalar(keys %seqidx_H);
my $full_list_file = $out_root . ".full.list";
new_ribo_RunCommand("grep ^\= $seqstat_file | awk '{ print \$2 }' > $full_list_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "fulllist", "$full_list_file", 1, "File with list of all $nseq input sequences");

ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);


##############################################################################
# Step 2. Run srcchk and filter for formal names
##############################################################################
$start_secs = ofile_OutputProgressPrior("Running srcchk for all sequences ", $progress_w, $log_FH, *STDOUT);
my $full_srcchk_file = $out_root . ".full.srcchk";
new_ribo_RunCommand("srcchk -i $full_list_file -f \'taxid,organism\' > $full_srcchk_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "fullsrcchk", "$full_srcchk_file", 1, "srcchk output for all $nseq input sequences");
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

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

  open(IN,       $in_file)  || ofile_FileOpenFailure($in_file,  "RIBO", "ribodbcreate.pl:main()", $!, "reading", $ofile_info_HH{"FH"});
  open(OUT, ">", $out_file) || ofile_FileOpenFailure($out_file, "RIBO", "ribodbcreate.pl:main()", $!, "writing", $ofile_info_HH{"FH"});

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
