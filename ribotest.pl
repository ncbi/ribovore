#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

# ribotest.pl :: test ribovore scripts [TEST SCRIPT]
# Usage: ribotest.pl [-options] <input test file e.g. testfiles/testin.1> <output directory to create>

require "epn-test.pm";
require "epn-options.pm";
require "epn-ofile.pm";
require "ribo.pm";

# make sure required environment variables are set
my $env_ribovore_dir    = ribo_VerifyEnvVariableIsValidDir("RIBODIR");

#my %execs_H = (); # hash with paths to all required executables
#$execs_H{"cmsearch"}    = $env_riboinfernal_dir . "/cmsearch";
#$execs_H{"esl-seqstat"} = $env_riboeasel_dir    . "/esl-seqstat";
#$execs_H{"esl-sfetch"}  = $env_riboeasel_dir    . "/esl-sfetch";
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
#     option            type       default               group   requires incompat    preamble-output                          help-output    
opt_Add("-h",           "boolean", 0,                        0,    undef, undef,      undef,                                   "display this help",                                  \%opt_HH, \@opt_order_A);
opt_Add("-f",           "boolean", 0,                        1,    undef, undef,      "forcing directory overwrite",           "force; if dir <output directory> exists, overwrite it",   \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                         "be verbose; output commands to stdout as they're run", \%opt_HH, \@opt_order_A);
opt_Add("-s",           "boolean", 0,                        1,    undef, undef,      "skip commands, they were already run, just compare files",  "skip commands, they were already run, just compare files",   \%opt_HH, \@opt_order_A);
$opt_group_desc_H{"2"} = "options for defining variables in testing files";
#       option       type        default                group  requires incompat          preamble-output                                              help-output    
#opt_Add("--dirbuild",   "string",  undef,                    2,   undef, undef,       "build directory, replaces !dirbuild! in test file with <s>", "build directory, replaces !dirbuild! in test file with <s>", \%opt_HH, \@opt_order_A);
$opt_group_desc_H{"3"} = "other options";
opt_Add("--keep",       "boolean", 0,                        3,    undef, undef,      "leaving intermediate files on disk", "do not remove intermediate files, keep them all on disk", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: ribotest.pl [-options] <input test file e.g. testfiles/testin.1> <output directory to create>\n";
my $synopsis = "ribotest.pl :: test ribovore scripts [TEST SCRIPT]";

my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"},
                'v'            => \$GetOptions_H{"-v"},
                'f'            => \$GetOptions_H{"-f"},
                's'            => \$GetOptions_H{"-s"},
#                'dirbuild=s'   => \$GetOptions_H{"--dirbuild"},
                'keep'         => \$GetOptions_H{"--keep"});

my $total_seconds = -1 * ribo_SecondsSinceEpoch(); # by multiplying by -1, we can just add another ribo_SecondsSinceEpoch call at end to get total time
my $executable    = $0;
my $date          = scalar localtime();
my $version       = "0.38";
my $releasedate   = "Feb 2019";
my $package_name  = "ribovore";
my $pkgstr        = "RIBO";

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
  print "\nTo see more help on available options, enter 'ribotest.pl -h'\n\n";
  exit(1);
}
my ($test_file, $dir_out) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

#############################
# create the output directory
#############################
my $cmd;              # a command to run with runCommand()
my @early_cmd_A = (); # array of commands we run before our log file is opened
if($dir_out !~ m/\/$/) { $dir_out =~ s/\/$//; } # remove final '/' if it exists
                
if(-d $dir_out) { 
  $cmd = "rm -rf $dir_out";
  if(opt_Get("-f", \%opt_HH)) { 
    ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef); push(@early_cmd_A, $cmd); 
  }
  else { # $dir_out directory exists but -f not used
    die "ERROR directory named $dir_out already exists. Remove it, or use -f to overwrite it."; 
  }
}
elsif(-e $dir_out) { 
  $cmd = "rm $dir_out";
  if(opt_Get("-f", \%opt_HH)) { 
    ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef); push(@early_cmd_A, $cmd); 
  }
  else { # $dir_out file exists but -f not used
    die "ERROR a file named $dir_out already exists. Remove it, or use -f to overwrite it."; 
  }
}

# create the dir
$cmd = "mkdir $dir_out";
ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), undef);
push(@early_cmd_A, $cmd);

my $dir_tail = $dir_out;
$dir_tail =~ s/^.+\///; # remove all but last dir
my $out_root = $dir_out . "/" . $dir_tail . ".ribotest";

#############################################
# output program banner and open output files
#############################################
# output preamble
my @arg_desc_A = ("test file", "output directory name");
my @arg_A      = ($test_file, $dir_out);
my %extra_H    = ();
$extra_H{"\$RIBODIR"} = $env_ribovore_dir;
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
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, "RIBO", "list", $out_root . ".list", 1, "List and description of all output files");
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, "RIBO", "log",  $out_root . ".log",  1, "Output printed to screen");
ofile_OpenAndAddFileToOutputInfo(\%ofile_info_HH, "RIBO", "cmd",  $out_root . ".cmd",  1, "List of executed commands");
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

#######################
# Parse the test file
#######################
my @cmd_A      = (); # array of the commands to run
my @desc_A     = (); # array of the descriptions for the commands
my @outfile_AA = (); # array of arrays of output files to compare for each command
my @expfile_AA = (); # array of arrays of expected files to compare output to for each command
my @rmdir_AA   = (); # array of directories to remove after each command is completed
my $ncmd = test_ParseTestFile($test_file, $pkgstr, \@cmd_A, \@desc_A, \@outfile_AA, \@expfile_AA, \@rmdir_AA, \%opt_HH, $ofile_info_HH{"FH"});

my $npass = 0;
my $nfail = 0;

# TODO: I SHOULD PUT THIS INTO A FUNCTION IN epn-test.pm (e.g. test_RunTestFile) but currently it requires
# a ribo_RunCommand() call in the rmdir section. 
# I could get around this by adding ofile_RemoveDir() and ofile_RemoveFile() functions.
my $start_secs = undef;
for(my $i = 1; $i <= $ncmd; $i++) { 
  my $cmd  = $cmd_A[($i-1)];
  my $desc = $desc_A[($i-1)];
  my $outfile_AR = \@{$outfile_AA[($i-1)]};
  my $expfile_AR = \@{$expfile_AA[($i-1)]};
  my $rmdir_AR   = \@{$rmdir_AA[($i-1)]};
  my $progress_w = 50; # the width of the left hand column in our progress output, hard-coded
  if((opt_IsUsed("-s", \%opt_HH)) && (opt_Get("-s", \%opt_HH))) { 
    # -s used, we aren't running commands, just comparing files
    $start_secs = ofile_OutputProgressPrior(sprintf("Skipping command %2d [%20s]", $i, $desc_A[($i-1)]), $progress_w, $log_FH, *STDOUT);
    ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
  }
  else { 
    # -s not used, run command
    $start_secs = ofile_OutputProgressPrior(sprintf("Running command %2d [%20s]", $i, $desc_A[($i-1)]), $progress_w, $log_FH, *STDOUT);
    ribo_RunCommand($cmd, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
    ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);
  }

  my $nout = scalar(@{$outfile_AR});
  for(my $j = 0; $j < $nout; $j++) { 
    my $diff_file = $out_root . "." . $i . "." . ($j+1) . ".diff";
    my $pass = test_DiffTwoFiles($outfile_AR->[$j], $expfile_AR->[$j], $diff_file, $pkgstr, $ofile_info_HH{"FH"});
    if($pass) { $npass++; }
    else      { $nfail++; }
  }

  if(($nfail == 0) && (! opt_Get("--keep", \%opt_HH))) { # only remove dir if no tests failed
    my $nrmdir = (defined $rmdir_AR) ? scalar(@{$rmdir_AR}) : 0;
    for(my $k = 0; $k < $nrmdir; $k++) { 
      ofile_OutputString($log_FH, 1, sprintf("#\t%-60s ... ", "removing directory $rmdir_AR->[$k]"));
      ribo_RunCommand("rm -rf $rmdir_AR->[$k]", opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"}); 
      ofile_OutputString($log_FH, 1, "done\n");
    }
  }
}

##########
# Conclude
##########
# summarize number of files checked and passed
my $overall_pass = ($nfail == 0) ? 1 : 0;
ofile_OutputString($log_FH, 1, "#\n#\n");
if($overall_pass) { 
  ofile_OutputString($log_FH, 1, "# PASS: all $npass files were created correctly.\n");
}
else { 
  ofile_OutputString($log_FH, 1, sprintf("# FAIL: %d of %d files were not created correctly.\n", $nfail, $npass+$nfail));
}
ofile_OutputString($log_FH, 1, sprintf("#\n"));

$total_seconds += ribo_SecondsSinceEpoch();
ofile_OutputConclusionAndCloseFiles($total_seconds, $pkgstr, $dir_out, \%ofile_info_HH);
exit(0);
