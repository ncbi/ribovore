use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

require "epn-options.pm";

# first, determine the paths to all modules, scripts and executables that we'll need
# we currently use hard-coded-paths for Infernal, HMMER and easel executables:
my $inf_exec_dir      = "/panfs/pan1/infernal/notebook/16_1213_ssu_ieb_tool/bin/";
my $hmmer_exec_dir    = "/panfs/pan1/infernal/notebook/16_1213_ssu_ieb_tool/bin/";
my $esl_exec_dir      = "/panfs/pan1/infernal/notebook/16_1213_ssu_ieb_tool/bin/";
my $ribo_exec_dir     = "/panfs/pan1/infernal/notebook/16_1213_ssu_ieb_tool/ribotyper-v1/";

#########################################################
# Command line and option processing using epn-options.pm
#
# opt_HH: 2D hash:
#         1D key: option name (e.g. "-h")
#         2D key: string denoting type of information 
#                 (one of "type", "default", "group", "requires", "incompatible", "preamble", "help")
#         value:  string explaining 2D key:
#                 "type":          "boolean", "string", "integer" or "real"
#                 "default":       default value for option
#                 "group":         integer denoting group number this option belongs to
#                 "requires":      string of 0 or more other options this option requires to work, each separated by a ','
#                 "incompatiable": string of 0 or more other options this option is incompatible with, each separated by a ','
#                 "preamble":      string describing option for preamble section (beginning of output from script)
#                 "help":          string describing option for help section (printed if -h used)
#                 "setby":         '1' if option set by user, else 'undef'
#                 "value":         value for option, can be undef if default is undef
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
#     option            type       default               group   requires incompat    preamble-output                   help-output    
opt_Add("-h",           "boolean", 0,                        0,    undef, undef,      undef,                           "display this help",                                  \%opt_HH, \@opt_order_A);
opt_Add("-f",           "boolean", 0,                        1,    undef, undef,      "forcing directory overwrite",   "force; if <output directory> exists, overwrite it",  \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                    "be verbose; output commands to stdout as they're run", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"2"} = "options for control search algorithm";
#       option               type   default                group  requires incompat                                  preamble-output             help-output    
opt_Add("--nhmmer",       "boolean", 0,                       2,  undef,   "--cmscan,--ssualign,--fast,--slow",      "annotate with nhmmer",     "using nhmmer for annotation", \%opt_HH, \@opt_order_A);
opt_Add("--cmscan",       "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign,--fast,--slow",      "annotate with cmsearch",   "using cmscan for annotation", \%opt_HH, \@opt_order_A);
opt_Add("--ssualign",     "boolean", 0,                       2,  undef,   "--nhmmer,--cmscan,--fast,--slow",        "annotate with SSU-ALIGN",  "using SSU-ALIGN for annotation", \%opt_HH, \@opt_order_A);
opt_Add("--fast",         "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign,--slow",             "run in fast mode",         "run in fast mode, sacrificing accuracy of boundaries", \%opt_HH, \@opt_order_A);
opt_Add("--slow",         "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign,--fast",             "run in slow mode",         "run in slow mode, maximize boundary accuracy", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: ribotyper.pl [-options] <fasta file to annotate> <model file> <clan/domain info file> <output directory>\n";
$usage      .= "\n";
my $synopsis = "ribotyper.pl :: detect and classify ribosomal RNA sequences";
my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"}, 
                'f'            => \$GetOptions_H{"-f"},
                'v'            => \$GetOptions_H{"-v"},
# algorithm options
                'nhmmer'       => \$GetOptions_H{"--nhmmer"},
                'cmscan'       => \$GetOptions_H{"--cmscan"},
                'ssualign'     => \$GetOptions_H{"--ssualign"},
                'fast'         => \$GetOptions_H{"--fast"},
                'slow'         => \$GetOptions_H{"--slow"});

my $total_seconds = -1 * seconds_since_epoch(); # by multiplying by -1, we can just add another seconds_since_epoch call at end to get total time
my $executable    = $0;
my $date          = scalar localtime();
my $version       = "0.01";
my $releasedate   = "Dec 2016";

# make *STDOUT file handle 'hot' so it automatically flushes whenever we print to it
select *STDOUT;
$| = 1;

# print help and exit if necessary
if((! $options_okay) || ($GetOptions_H{"-h"})) { 
  output_banner(*STDOUT, $version, $releasedate, $synopsis, $date);
  opt_OutputHelp(*STDOUT, $usage, \%opt_HH, \@opt_order_A, \%opt_group_desc_H);
  if(! $options_okay) { die "ERROR, unrecognized option;"; }
  else                { exit 0; } # -h, exit with 0 status
}

# check that number of command line args is correct
if(scalar(@ARGV) != 4) {   
  print "Incorrect number of command line arguments.\n";
  print $usage;
  print "\nTo see more help on available options, do dnaorg_annotate.pl -h\n\n";
  exit(1);
}
my ($seq_file, $model_file, $clan_file, $dir_out) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

my $cmd;
my $ncpu = 0;

# if $dir_out already exists remove it only if -f also used
if(-d $dir_out) { 
  $cmd = "rm -rf $dir_out";
  if(opt_Get("-f", \%opt_HH)) { run_command($cmd, opt_Get("-v", \%opt_HH)); }
  else                        { die "ERROR directory named $dir_out already exists. Remove it, or use -f to overwrite it."; }
}
if(-e $dir_out) { 
  $cmd = "rm $dir_out";
  if(opt_Get("-f", \%opt_HH)) { run_command($cmd, opt_Get("-v", \%opt_HH)); }
  else                        { die "ERROR a file named $dir_out already exists. Remove it, or use -f to overwrite it."; }
}
# if $dir_out does not exist, create it
if(! -d $dir_out) {
  $cmd = "mkdir $dir_out";
  run_command($cmd, opt_Get("-v", \%opt_HH));
}

my $dir_out_tail   = $dir_out;
$dir_out_tail   =~ s/^.+\///; # remove all but last dir
my $out_root   = $dir_out .   "/" . $dir_out_tail   . ".ribotyper";

#############################################
# output program banner and open output files
#############################################
# output preamble
my @arg_desc_A = ();
my @arg_A      = ();

push(@arg_desc_A, "target sequence input file");
push(@arg_A, $seq_file);

push(@arg_desc_A, "query model input file");
push(@arg_A, $model_file);

push(@arg_desc_A, "clan information input file");
push(@arg_A, $clan_file);

push(@arg_desc_A, "output directory name");
push(@arg_A, $dir_out);

output_banner(*STDOUT, $version, $releasedate, $synopsis, $date);
opt_OutputPreamble(*STDOUT, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

###################################################
# make sure the required executables are executable
###################################################
my %execs_H = (); # hash with paths to all required executables
$execs_H{"cmscan"}          = $inf_exec_dir   . "cmscan";
$execs_H{"cmsearch"}        = $inf_exec_dir   . "cmsearch";
$execs_H{"nhmmer"}          = $hmmer_exec_dir . "nhmmer";
$execs_H{"ssu-align"}       = $hmmer_exec_dir . "ssu-align";
$execs_H{"esl-seqstat"}     = $esl_exec_dir   . "esl-seqstat";
$execs_H{"ribotyper-parse"} = $ribo_exec_dir  . "ribotyper-parse.pl";
#$execs_H{"esl_ssplit"}    = $esl_ssplit;
validate_executable_hash(\%execs_H);

###########################################################################
# Step 1: run esl-seqstat to get sequence lengths and validate input file
my $seqstat_file = $out_root . ".seqstat";
my $progress_w = 85; # the width of the left hand column in our progress output, hard-coded
my $start_secs = output_progress_prior("Validating target sequence file and determining sequence lengths", $progress_w, undef, *STDOUT);
run_command("esl-seqstat -a $seq_file > $seqstat_file", opt_Get("-v", \%opt_HH));
output_progress_complete($start_secs, undef, undef, *STDOUT);
###########################################################################

###########################################################################
# Step 2: run search algorithm
# determine which algorithm to use and options to use as well
# as the command for sorting the output and parsing the output
# set up defaults
$start_secs = output_progress_prior("Performing search ", $progress_w, undef, *STDOUT);
my $do_cmsearch = 0;
my $do_nhmmer   = 0;
my $do_cmscan   = 0;
my $do_ssualign = 0;
my $do_fast     = 0;
my $do_slow     = 0;

if   (opt_Get("--nhmmer", \%opt_HH))   { $do_nhmmer = 1; }
elsif(opt_Get("--cmscan", \%opt_HH))   { $do_cmscan = 1; }
elsif(opt_Get("--ssualign", \%opt_HH)) { $do_ssualign = 1; }
else                                   { $do_cmsearch = 1; }

if   (opt_Get("--fast", \%opt_HH))   { $do_fast = 1; }
elsif(opt_Get("--slow", \%opt_HH))   { $do_slow = 1; }

my $cmsearch_and_cmscan_opts = "";
my $tblout_file = "";
my $sorted_tblout_file = "";
my $searchout_file = "";
my $search_cmd = "";
my $sort_cmd = "";
my $parse_method = "";

if($do_nhmmer) { 
  $tblout_file    = $out_root . ".nhmmer.tbl";
  $searchout_file = $out_root . ".nhmmer.out";
  $search_cmd = $execs_H{"nhmmer"} . " --noali --cpu $ncpu --tblout $tblout_file $model_file $seq_file > $searchout_file";
  $sort_cmd   = "grep -v ^\# $tblout_file | sort -k1 > sorted_" . $tblout_file;
  $parse_method = "nhmmer";
}
elsif($do_ssualign) { 
  $tblout_file        = $out_root . "/" . $dir_out_tail . ".ribotyper.tab";
  $sorted_tblout_file = $out_root . "/" . $dir_out_tail . ".ribotyper.tab.sorted";
  $searchout_file     = $out_root . ".nhmmer.out";
  $search_cmd         = $execs_H{"ssu-align"} . " --no-align -m $model_file -f $seq_file $out_root > /dev/null";
  $sort_cmd           = "grep -v ^\# $tblout_file | awk ' { printf(\"%s %s %s %s %s %s %s %s %s\\n\", \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9); } ' | sort -k2 > $sorted_tblout_file";
  $parse_method       = "ssualign";
}
elsif(($do_cmsearch) || ($do_cmscan)) { 
  if($do_fast) { 
    $cmsearch_and_cmscan_opts .= " --F1 0.02 --doF1b --F1b 0.02 --F2 0.001 --F3 0.00001 --trmF3 --nohmmonly --notrunc ";
  }
  elsif($do_slow) { 
    $cmsearch_and_cmscan_opts .= " --rfam ";
  }
  else { 
    $cmsearch_and_cmscan_opts .= " --hmmonly ";
  }
  if($do_cmsearch) { 
    $tblout_file    = $out_root . ".cmsearch.tbl";
    $searchout_file = $out_root . ".cmsearch.out";
    $executable = $execs_H{"cmsearch"};
    $sort_cmd   = "grep -v ^\# $tblout_file | sort -k1 > sorted_" . $tblout_file;
    if($do_fast) { 
      $parse_method = "fast-cmsearch";
    }
    else { 
      $parse_method = "cmsearch";
    }
  }
  else { 
    $tblout_file    = $out_root . ".cmscan.tbl";
    $searchout_file = $out_root . ".cmscan.out";
    $executable = $execs_H{"cmscan"};
    if($do_fast) { 
      $sort_cmd     = "grep -v ^\# $tblout_file | awk '{ printf(\"%s %s %s %s %s %s %s %s %s\\n\", \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9); }' | sort -k2 > sorted_" . $tblout_file;
      $parse_method = "fast-cmscan";
    }
    else { 
      $sort_cmd     = "grep -v ^\# $tblout_file | sort -k4 > sorted_" . $tblout_file;
      $parse_method = "cmscan";
    }
  }
  $search_cmd = $executable . " --noali --cpu $ncpu $cmsearch_and_cmscan_opts --tblout $tblout_file $model_file $seq_file > $searchout_file";
}
run_command($search_cmd, opt_Get("-v", \%opt_HH));
output_progress_complete($start_secs, undef, undef, *STDOUT);

###########################################################################
# Step 3: Sort output
$start_secs = output_progress_prior("Sorting tabular search results", $progress_w, undef, *STDOUT);
run_command($sort_cmd, opt_Get("-v", \%opt_HH));
output_progress_complete($start_secs, undef, undef, *STDOUT);
###########################################################################

###########################################################################
# Step 4: Parse sorted output
$start_secs = output_progress_prior("Parsing tabular search results", $progress_w, undef, *STDOUT);
my $parse_cmd  = "perl " . $execs_H{"ribotyper-parse"} . " $parse_method $seqstat_file $clan_file $sorted_tblout_file $out_root.long.out $out_root.short.out"; 
run_command($parse_cmd, opt_Get("-v", \%opt_HH));
output_progress_complete($start_secs, undef, undef, *STDOUT);
###########################################################################


#####################################################################
# SUBROUTINES 
#####################################################################
# Subroutine: output_banner()
# Incept:     EPN, Thu Oct 30 09:43:56 2014 (rnavore)
# 
# Purpose:    Output the dnaorg banner.
#
# Arguments: 
#    $FH:                file handle to print to
#    $version:           version of dnaorg
#    $releasedate:       month/year of version (e.g. "Feb 2016")
#    $synopsis:          string reporting the date
#    $date:              date information to print
#
# Returns:    Nothing, if it returns, everything is valid.
# 
# Dies: never
####################################################################
sub output_banner {
  my $nargs_expected = 5;
  my $sub_name = "outputBanner()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($FH, $version, $releasedate, $synopsis, $date) = @_;

  print $FH ("\# $synopsis\n");
  print $FH ("\# dnaorg $version ($releasedate)\n");
#  print $FH ("\# Copyright (C) 2014 HHMI Janelia Research Campus\n");
#  print $FH ("\# Freely distributed under the GNU General Public License (GPLv3)\n");
  print $FH ("\# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
  if(defined $date)    { print $FH ("# date:    $date\n"); }
  printf $FH ("#\n");

  return;
}

#################################################################
# Subroutine:  run_command()
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
#
# Returns:    amount of time the command took, in seconds
#
# Dies:       if $cmd fails
#################################################################
sub run_command {
  my $sub_name = "run_command()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmd, $be_verbose) = @_;
  
  if($be_verbose) { 
    print ("Running cmd: $cmd\n"); 
  }

  my ($seconds, $microseconds) = gettimeofday();
  my $start_time = ($seconds + ($microseconds / 1000000.));

  system($cmd);

  ($seconds, $microseconds) = gettimeofday();
  my $stop_time = ($seconds + ($microseconds / 1000000.));

  if($? != 0) { 
    die "ERROR in $sub_name, the following command failed:\n$cmd\n";
  }

  return ($stop_time - $start_time);
}

#################################################################
# Subroutine : validate_executable_hash()
# Incept:      EPN, Sat Feb 13 06:27:51 2016
#
# Purpose:     Given a reference to a hash in which the 
#              values are paths to executables, validate
#              those files are executable.
#
# Arguments: 
#   $execs_HR: REF to hash, keys are short names to executable
#              e.g. "cmbuild", values are full paths to that
#              executable, e.g. "/usr/local/infernal/1.1.1/bin/cmbuild"
# 
# Returns:     void
#
# Dies:        if one or more executables does not exist#
#
################################################################# 
sub validate_executable_hash { 
  my $nargs_expected = 1;
  my $sub_name = "validate_executable_hash()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($execs_HR) = (@_);

  my $fail_str = undef;
  foreach my $key (sort keys %{$execs_HR}) { 
    if(! -e $execs_HR->{$key}) { 
      $fail_str .= "\t$execs_HR->{$key} does not exist.\n"; 
    }
    elsif(! -x $execs_HR->{$key}) { 
      $fail_str .= "\t$execs_HR->{$key} exists but is not an executable file.\n"; 
    }
  }
  
  if(defined $fail_str) { 
    die "ERROR in $sub_name(),\n$fail_str"; 
  }

  return;
}

#################################################################
# Subroutine : seconds_since_epoch()
# Incept:      EPN, Sat Feb 13 06:17:03 2016
#
# Purpose:     Return the seconds and microseconds since the 
#              Unix epoch (Jan 1, 1970) using 
#              Time::HiRes::gettimeofday().
#
# Arguments:   NONE
# 
# Returns:     Number of seconds and microseconds
#              since the epoch.
#
################################################################# 
sub seconds_since_epoch { 
  my $nargs_expected = 0;
  my $sub_name = "seconds_since_epoch()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seconds, $microseconds) = gettimeofday();
  return ($seconds + ($microseconds / 1000000.));
}

#################################################################
# Subroutine : output_progress_prior()
# Incept:      EPN, Fri Feb 12 17:22:24 2016 [dnaorg.pm]
#
# Purpose:      Output to $FH1 (and possibly $FH2) a message indicating
#               that we're about to do 'something' as explained in
#               $outstr.  
#
#               Caller should call *this* function, then do
#               the 'something', then call output_progress_complete().
#
#               We return the number of seconds since the epoch, which
#               should be passed into the downstream
#               output_progress_complete() call if caller wants to
#               output running time.
#
# Arguments: 
#   $outstr:     string to print to $FH
#   $progress_w: width of progress messages
#   $FH1:        file handle to print to, can be undef
#   $FH2:        another file handle to print to, can be undef
# 
# Returns:     Number of seconds and microseconds since the epoch.
#
################################################################# 
sub output_progress_prior { 
  my $nargs_expected = 4;
  my $sub_name = "output_progress_prior()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($outstr, $progress_w, $FH1, $FH2) = @_;

  if(defined $FH1) { printf $FH1 ("# %-*s ... ", $progress_w, $outstr); }
  if(defined $FH2) { printf $FH2 ("# %-*s ... ", $progress_w, $outstr); }

  return seconds_since_epoch();
}

#################################################################
# Subroutine : output_progress_complete()
# Incept:      EPN, Fri Feb 12 17:28:19 2016 [dnaorg.pm]
#
# Purpose:     Output to $FH1 (and possibly $FH2) a 
#              message indicating that we've completed 
#              'something'.
#
#              Caller should call *this* function,
#              after both a call to output_progress_prior()
#              and doing the 'something'.
#
#              If $start_secs is defined, we determine the number
#              of seconds the step took, output it, and 
#              return it.
#
# Arguments: 
#   $start_secs:    number of seconds either the step took
#                   (if $secs_is_total) or since the epoch
#                   (if !$secs_is_total)
#   $extra_desc:    extra description text to put after timing
#   $FH1:           file handle to print to, can be undef
#   $FH2:           another file handle to print to, can be undef
# 
# Returns:     Number of seconds the step took (if $secs is defined,
#              else 0)
#
################################################################# 
sub output_progress_complete { 
  my $nargs_expected = 4;
  my $sub_name = "output_progress_complete()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($start_secs, $extra_desc, $FH1, $FH2) = @_;

  my $total_secs = undef;
  if(defined $start_secs) { 
    $total_secs = seconds_since_epoch() - $start_secs;
  }

  if(defined $FH1) { printf $FH1 ("done."); }
  if(defined $FH2) { printf $FH2 ("done."); }

  if(defined $total_secs || defined $extra_desc) { 
    if(defined $FH1) { printf $FH1 (" ["); }
    if(defined $FH2) { printf $FH2 (" ["); }
  }
  if(defined $total_secs) { 
    if(defined $FH1) { printf $FH1 (sprintf("%.1f seconds%s", $total_secs, (defined $extra_desc) ? ", " : "")); }
    if(defined $FH2) { printf $FH2 (sprintf("%.1f seconds%s", $total_secs, (defined $extra_desc) ? ", " : "")); }
  }
  if(defined $extra_desc) { 
    if(defined $FH1) { printf $FH1 $extra_desc };
    if(defined $FH2) { printf $FH2 $extra_desc };
  }
  if(defined $total_secs || defined $extra_desc) { 
    if(defined $FH1) { printf $FH1 ("]"); }
    if(defined $FH2) { printf $FH2 ("]"); }
  }

  if(defined $FH1) { printf $FH1 ("\n"); }
  if(defined $FH2) { printf $FH2 ("\n"); }
  
  return (defined $total_secs) ? $total_secs : 0.;
}
