use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

require "epn-options.pm";

# first, determine the paths to all modules, scripts and executables that we'll need
# we currently use hard-coded-paths for Infernal, HMMER and easel executables:
my $inf_exec_dir      = "/usr/local/infernal/1.1.2/bin/";
my $hmmer_exec_dir    = "/usr/local/hmmer/3.1b2/bin/";
my $esl_exec_dir      = "/usr/local/infernal/1.1.2/bin/";

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
#     option            type       default               group   requires incompat    preamble-output                                   help-output    
opt_Add("-h",           "boolean", 0,                        0,    undef, undef,      undef,                                            "display this help",                                  \%opt_HH, \@opt_order_A);
opt_Add("-f",           "boolean", 0,                        1,    undef, undef,      "forcing directory overwrite",                    "force; if <output directory> exists, overwrite it",  \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                                     "be verbose; output commands to stdout as they're run", \%opt_HH, \@opt_order_A);
opt_Add("-d",           "real",    "50.",                    1,    undef, undef,      "set minimum acceptable score difference to <x>", "set minimum acceptable bit score difference between best and 2nd best model to <x> bits", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"2"} = "options for control search algorithm";
#       option               type   default                group  requires incompat                                  preamble-output             help-output    
opt_Add("--nhmmer",       "boolean", 0,                       2,  undef,   "--cmscan,--ssualign,--fast,--slow",      "annotate with nhmmer",     "using nhmmer for annotation", \%opt_HH, \@opt_order_A);
opt_Add("--cmscan",       "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign",                    "annotate with cmsearch",   "using cmscan for annotation", \%opt_HH, \@opt_order_A);
opt_Add("--ssualign",     "boolean", 0,                       2,  undef,   "--nhmmer,--cmscan,--fast,--slow",        "annotate with SSU-ALIGN",  "using SSU-ALIGN for annotation", \%opt_HH, \@opt_order_A);
opt_Add("--fast",         "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign,--slow",             "run in fast mode",         "run in fast mode, sacrificing accuracy of boundaries", \%opt_HH, \@opt_order_A);
opt_Add("--slow",         "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign,--fast",             "run in slow mode",         "run in slow mode, maximize boundary accuracy", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"3"} = "advanced options";
#       option               type   default                group  requires incompat  preamble-output             help-output    
opt_Add("--skipsearch",   "boolean", 0,                       3,  undef,   "-f",     "skip search stage",        "skip search stage, use results from earlier run", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: ribotyper.pl [-options] <fasta file to annotate> <model file> <clan/domain info file> <output directory>\n";
$usage      .= "\n";
my $synopsis = "ribotyper.pl :: detect and classify ribosomal RNA sequences";
my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"}, 
                'f'            => \$GetOptions_H{"-f"},
                'v'            => \$GetOptions_H{"-v"},
                'd=s'          => \$GetOptions_H{"-d"},
# algorithm options
                'nhmmer'       => \$GetOptions_H{"--nhmmer"},
                'cmscan'       => \$GetOptions_H{"--cmscan"},
                'ssualign'     => \$GetOptions_H{"--ssualign"},
                'fast'         => \$GetOptions_H{"--fast"},
                'slow'         => \$GetOptions_H{"--slow"},
# advanced options
                'skipsearch'   => \$GetOptions_H{"--skipsearch"});

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

my $cmd;                       # a command to be run by run_command()
my $ncpu = 0;                  # number of CPUs to use with search command
my $max_targetname_length = 0; # maximum length of any target name

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
    if(opt_Get("-f", \%opt_HH)) { run_command($cmd, opt_Get("-v", \%opt_HH)); }
    else                        { die "ERROR directory named $dir_out already exists. Remove it, or use -f to overwrite it."; }
  }
  elsif(-e $dir_out) { 
    $cmd = "rm $dir_out";
    if(opt_Get("-f", \%opt_HH)) { run_command($cmd, opt_Get("-v", \%opt_HH)); }
    else                        { die "ERROR a file named $dir_out already exists. Remove it, or use -f to overwrite it."; }
  }
  # if $dir_out does not exist, create it
  if(! -d $dir_out) { 
    $cmd = "mkdir $dir_out";
    run_command($cmd, opt_Get("-v", \%opt_HH));
  }
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

my $long_out_file  = $out_root . ".long.out";
my $short_out_file = $out_root . ".short.out";
my $long_out_FH;  # output file handle for long output file
my $short_out_FH; # output file handle for short output file
open($long_out_FH,  ">", $long_out_file)  || die "ERROR unable to open $long_out_file for writing";
open($short_out_FH, ">", $short_out_file) || die "ERROR unable to open $short_out_file for writing";

##########################
# determine search method
##########################
my $search_method = undef; # can be any of "cmsearch-hmmonly", "cmscan-hmmonly", 
#                                          "cmsearch-slow",    "cmscan-slow", 
#                                          "cmsearch-fast",    "cmscan-fast",
#                                          "nhmmer",           "ssualign"

if   (opt_Get("--nhmmer", \%opt_HH))   { $search_method = "nhmmer"; }
elsif(opt_Get("--cmscan", \%opt_HH))   { $search_method = "cmscan-hmmonly"; }
elsif(opt_Get("--ssualign", \%opt_HH)) { $search_method = "ssualign"; }
else                                   { $search_method = "cmsearch-hmmonly"; }

if(opt_Get("--fast", \%opt_HH)) { 
  if   ($search_method eq "cmsearch-hmmonly") { $search_method = "cmsearch-fast"; }
  elsif($search_method eq "cmscan-hmmonly")   { $search_method = "cmscan-fast"; }
  else { die "ERROR, --fast used in error, search_method: $search_method"; }
}
elsif(opt_Get("--slow", \%opt_HH)) { 
  if   ($search_method eq "cmsearch-hmmonly") { $search_method = "cmsearch-slow"; }
  elsif($search_method eq "cmscan-hmmonly")   { $search_method = "cmscan-slow"; }
  else { die "ERROR, --fast used in error, search_method: $search_method"; }
}

###################################################
# make sure the required executables are executable
###################################################
my %execs_H = (); # hash with paths to all required executables
$execs_H{"cmscan"}          = $inf_exec_dir   . "cmscan";
$execs_H{"cmsearch"}        = $inf_exec_dir   . "cmsearch";
$execs_H{"esl-seqstat"}     = $esl_exec_dir   . "esl-seqstat";
if($search_method eq "nhmmer") { 
  $execs_H{"nhmmer"}          = $hmmer_exec_dir . "nhmmer";
}
if($search_method eq "ssualign") { 
  $execs_H{"ssu-align"}       = $hmmer_exec_dir . "ssu-align";
}
#$execs_H{"esl_ssplit"}    = $esl_ssplit;
validate_executable_hash(\%execs_H);

###########################################################################
###########################################################################
# Step 1: Parse/validate input files and run esl-seqstat to get sequence lengths.
my $progress_w = 74; # the width of the left hand column in our progress output, hard-coded
my $start_secs = output_progress_prior("Parsing and validating input files and determining target sequence lengths", $progress_w, undef, *STDOUT);
###########################################################################
# parse clan file
# variables related to clans and domains
my %clan_H         = (); # hash of clans,   key: model name, value: name of clan model belongs to (e.g. SSU)
my %domain_H       = (); # hash of domains, key: model name, value: name of domain model belongs to (e.g. Archaea)
parse_clan_file($clan_file, \%clan_H, \%domain_H);

# run esl-seqstat to get sequence lengths
my $seqstat_file = $out_root . ".seqstat";
run_command("esl-seqstat -a $seq_file > $seqstat_file", opt_Get("-v", \%opt_HH));
my %seqlen_H = (); # key: sequence name, value: length of sequence, 
                   # value set to -1 after we output info for this sequence
                   # and then serves as flag for: "we output this sequence 
                   # already, if we see it again we know the tbl file was not
                   # sorted properly.
# parse esl-seqstat file to get lengths
parse_seqstat_file($seqstat_file, \$max_targetname_length, \%seqlen_H); 

# now that we know the max sequence name length, we can output headers to the output files
output_long_headers($long_out_FH, $max_targetname_length);
output_short_headers($short_out_FH, $max_targetname_length);
###########################################################################
output_progress_complete($start_secs, undef, undef, *STDOUT);
###########################################################################
###########################################################################

###########################################################################
# Step 2: run search algorithm
# determine which algorithm to use and options to use as well
# as the command for sorting the output and parsing the output
# set up defaults
my $cmsearch_and_cmscan_opts = "";
my $tblout_file = "";
my $sorted_tblout_file = "";
my $searchout_file = "";
my $search_cmd = "";
my $sort_cmd = "";

if($search_method eq "nhmmer") { 
  $tblout_file        = $out_root . ".nhmmer.tbl";
  $sorted_tblout_file = $tblout_file . ".sorted";
  $searchout_file     = $out_root . ".nhmmer.out";
  $search_cmd         = $execs_H{"nhmmer"} . " --noali --cpu $ncpu --tblout $tblout_file $model_file $seq_file > $searchout_file";
  $sort_cmd           = "grep -v ^\# $tblout_file | sort -k1 > " . $sorted_tblout_file;
}
elsif($search_method eq "ssualign") { 
  $tblout_file        = $out_root . "/" . $dir_out_tail . ".ribotyper.tab";
  $sorted_tblout_file = $tblout_file . ".sorted";
  $searchout_file     = $out_root . ".nhmmer.out";
  $search_cmd         = $execs_H{"ssu-align"} . " --no-align -m $model_file -f $seq_file $out_root > /dev/null";
  $sort_cmd           = "grep -v ^\# $tblout_file | awk ' { printf(\"%s %s %s %s %s %s %s %s %s\\n\", \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9); } ' | sort -k2 > " . $sorted_tblout_file;
}
else { 
  # search_method is "cmsearch-slow", "cmscan-slow', "cmsearch-fast", or "cmscan-slow"
  if($search_method eq "cmsearch-fast" || $search_method eq "cmscan-fast") { 
    $cmsearch_and_cmscan_opts .= " --F1 0.02 --doF1b --F1b 0.02 --F2 0.001 --F3 0.00001 --trmF3 --nohmmonly --notrunc ";
    if($search_method eq "cmscan-fast") { 
      $cmsearch_and_cmscan_opts .= " --fmt 2 ";
    }
  }
  elsif($search_method eq "cmsearch-slow" || $search_method eq "cmscan-slow") { 
    $cmsearch_and_cmscan_opts .= " --rfam ";
    if($search_method eq "cmscan-slow") { 
      $cmsearch_and_cmscan_opts .= " --fmt 2 ";
    }
  }
  else { # $search_method is either "cmsearch-hmmonly", or "cmscan-hmmonly";
    $cmsearch_and_cmscan_opts .= " --hmmonly ";
    if($search_method eq "cmscan-hmmonly") { 
      $cmsearch_and_cmscan_opts .= " --fmt 2 ";
    }
  }
  if(($search_method eq "cmsearch-slow") || ($search_method eq "cmsearch-fast") || ($search_method eq "cmsearch-hmmonly")) { 
    $tblout_file        = $out_root . ".cmsearch.tbl";
    $sorted_tblout_file = $tblout_file . ".sorted";
    $searchout_file     = $out_root . ".cmsearch.out";
    $executable         = $execs_H{"cmsearch"};
    $sort_cmd           = "grep -v ^\# $tblout_file | sort -k1 > " . $sorted_tblout_file;
  }
  else { # search_method is "cmscan-slow", "cmscan-fast", or "cmscan-hmmonly"
    $tblout_file        = $out_root . ".cmscan.tbl";
    $sorted_tblout_file = $tblout_file . ".sorted";
    $searchout_file     = $out_root . ".cmscan.out";
    $executable         = $execs_H{"cmscan"};
    if($search_method eq "cmscan-fast") { 
      $sort_cmd = "grep -v ^\# $tblout_file | awk '{ printf(\"%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s\\n\", \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, \$16, \$17); }' | sort -k3 > " . $sorted_tblout_file;
    }
    else { 
      $sort_cmd = "grep -v ^\# $tblout_file | sort -k4 > " . $sorted_tblout_file;
    }
  }
  $search_cmd = $executable . " --noali --cpu $ncpu $cmsearch_and_cmscan_opts --tblout $tblout_file $model_file $seq_file > $searchout_file";
}
if(! opt_Get("--skipsearch", \%opt_HH)) { 
  $start_secs = output_progress_prior("Performing $search_method search ", $progress_w, undef, *STDOUT);
}
else { 
  $start_secs = output_progress_prior("Skipping $search_method search stage (using results from previous run)", $progress_w, undef, *STDOUT);
}
if(! opt_Get("--skipsearch", \%opt_HH)) { 
  run_command($search_cmd, opt_Get("-v", \%opt_HH));
}
else { 
  if(! -s $tblout_file) { 
    die "ERROR with --skipsearch, tblout file ($tblout_file) should exist and be non-empty but it's not";
  }
}
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
parse_sorted_tbl_file($sorted_tblout_file, $search_method, $max_targetname_length, \%seqlen_H, \%clan_H, \%domain_H, $long_out_FH, $short_out_FH);
output_progress_complete($start_secs, undef, undef, *STDOUT);
###########################################################################

###########################################################################
# Add tails to output files and exit.
# now that we know the max sequence name length, we can output headers to the output files
output_long_tail($long_out_FH);
output_short_tail($short_out_FH);

close($short_out_FH);
close($long_out_FH);
printf("#\n# Short (3 column) output saved to file $short_out_file.\n");
printf("# Long (14 column) output saved to file $long_out_file.\n");
printf("#\n#[RIBO-SUCCESS]\n");

# cat the output file
#run_command("cat $short_out_file", opt_Get("-v", \%opt_HH));
#run_command("cat $long_out_file", opt_Get("-v", \%opt_HH));
###########################################################################

#####################################################################
# SUBROUTINES 
#####################################################################
# List of subroutines:
#
# Functions for parsing files:
# parse_clan_file:          parse the clan input file
# parse_seqstat_file:       parse esl-seqstat -a output file
# parse_sorted_tbl_file:    parse sorted tabular search results
#
# Helper functions for parse_sorted_tbl_file():
# init_vars:                 initialize variables for parse_sorted_tbl_file()
# set_vars:                  set variables for parse_sorted_tbl_file()
# 
# Functions for output: 
# output_one_target_wrapper: wrapper function for outputting info on one target sequence
#                            helper for parse_sorted_tbl_file()
# output_one_target:         output info on one target sequence
#                            helper for parse_sorted_tbl_file()
# output_short_headers:      output headers for short output file
# output_long_headers:       output headers for long output file
# output_banner:             output the banner with info on the script and options used
# output_progress_prior:     output routine for a step, prior to running the step
# output_progress_complete:  output routine for a step, after the running the step
#
# Miscellaneous functions:
# run_command:              run a command using system()
# validate_executable_hash: validate executables exist and are executable
# seconds_since_epoch:      number of seconds since the epoch, for timings
#

#################################################################
# Subroutine : parse_clan_file()
# Incept:      EPN, Mon Dec 19 10:01:32 2016
#
# Purpose:     Parse a clan input file.
#              
# Arguments: 
#   $clan_file:       file to parse
#   $clan_HR:         ref to hash of clan names, key is model name, value is clan name
#   $domain_HR:       ref to hash of domain names, key is model name, value is domain name
#
# Returns:     Nothing. Fills @{$clan_names_AR}, %{$clan_H}, @{$domain_names_AR}, %{$domain_HR}
# 
# Dies:        Never.
#
################################################################# 
sub parse_clan_file { 
  my $nargs_expected = 3;
  my $sub_name = "parse_clan_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($clan_file, $clan_HR, $domain_HR) = @_;

  open(IN, $clan_file) || die "ERROR unable to open esl-seqstat file $seqstat_file for reading";

# example line:
# SSU_rRNA_archaea SSU Archaea

  my %clan_exists_H   = ();
  my %domain_exists_H = ();

  open(IN, $clan_file) || die "ERROR unable to open $clan_file for reading"; 
  while(my $line = <IN>) { 
    chomp $line;
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 3) { 
      die "ERROR didn't read 3 tokens in clan input file $clan_file, line $line"; 
    }
    my($model, $clan, $domain) = (@el_A);

    if(! exists $clan_exists_H{$clan}) { 
      $clan_exists_H{$clan} = 1;
    }
    if(! exists $domain_exists_H{$domain}) { 
      $domain_exists_H{$domain} = 1;
    }
    if(exists $clan_HR->{$model}) { 
      die "ERROR read model $model twice in $clan_file"; 
    }
    $clan_HR->{$model}   = $clan;
    $domain_HR->{$model} = $domain;
  }
  close(IN);

  return;
}

#################################################################
# Subroutine : parse_seqstat_file()
# Incept:      EPN, Wed Dec 14 16:16:22 2016
#
# Purpose:     Parse an esl-seqstat -a output file.
#              
# Arguments: 
#   $seqstat_file:            file to parse
#   $max_targetname_length_R: REF to the maximum length of any target name, updated here
#   $seqlen_HR:               REF to hash of sequence lengths to fill here
#
# Returns:     Nothing. Fills %{$seqlen_HR}.
# 
# Dies:        Never.
#
################################################################# 
sub parse_seqstat_file { 
  my $nargs_expected = 3;
  my $sub_name = "parse_seqstat_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seqstat_file, $max_targetname_length_R, $seqlen_HR) = @_;

  open(IN, $seqstat_file) || die "ERROR unable to open esl-seqstat file $seqstat_file for reading";

  my $nread = 0;
  my $targetname_length;
  my $targetname;
  my $length;

  while(my $line = <IN>) { 
    # = lcl|dna_BP331_0.3k:467     1232 
    # = lcl|dna_BP331_0.3k:10     1397 
    # = lcl|dna_BP331_0.3k:1052     1414 
    chomp $line;
    #print $line . "\n";
    if($line =~ /^\=\s+(\S+)\s+(\d+)/) { 
      ($targetname, $length) = ($1, $2);
      $seqlen_HR->{$targetname} = $length;

      $targetname_length = length($targetname);
      if($targetname_length > $$max_targetname_length_R) { 
        $$max_targetname_length_R = $targetname_length;
      }

      $nread++;
    }
  }
  close(IN);
  if($nread == 0) { 
    die "ERROR did not read any sequence lengths in esl-seqstat file $seqstat_file, did you use -a option with esl-seqstat";
  }

  return;
}

#################################################################
# Subroutine : parse_sorted_tblout_file()
# Incept:      EPN, Thu Dec 29 09:52:16 2016
#
# Purpose:     Parse a sorted tabular output file and generate output.
#              
# Arguments: 
#   $sorted_tbl_file: file with sorted tabular search results
#   $search_method:   search method (one of "cmsearch-hmmonly", "cmscan-hmmonly"
#                                           "cmsearch-slow",    "cmscan-slow", 
#                                           "cmsearch-fast",    "cmscan-fast",
#                                           "nhmmer",           "ssualign")
#   $max_targetname_length: max length of any target name
#   $seqlen_HR:       ref to hash of sequence lengths, key is sequence name, value is length
#   $clan_HR:         ref to hash of clan names, key is model name, value is clan name
#   $domain_HR:       ref to hash of domain names, key is model name, value is domain name
#   $long_out_FH:     file handle for long output file, already open
#   $short_out_FH:    file handle for short output file, already open
#
# Returns:     Nothing. Fills %{$clan_H}, %{$domain_HR}
# 
# Dies:        Never.
#
################################################################# 
sub parse_sorted_tbl_file { 
  my $nargs_expected = 8;
  my $sub_name = "parse_sorted_tbl_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($sorted_tbl_file, $search_method, $max_targetname_length, $seqlen_HR, $clan_HR, $domain_HR, $long_out_FH, $short_out_FH) = @_;

  # validate search method (sanity check) 
  if(($search_method ne "cmsearch-hmmonly") && ($search_method ne "cmscan-hmmonly") && 
     ($search_method ne "cmsearch-slow")    && ($search_method ne "cmscan-slow") &&
     ($search_method ne "cmsearch-fast")    && ($search_method ne "cmscan-fast") &&      
     ($search_method ne "nhmmer")           && ($search_method ne "ssualign")) { 
    die "ERROR in $sub_name, invalid search method $search_method";
  }
  
  # Main data structures: 
  # 'one': current top scoring model for current sequence
  # 'two': current second best scoring model for current sequence 
  #        that overlaps with hit in 'one' data structures
  # 
  # keys for all below are clans (e.g. 'SSU' or 'LSU')
  # values are for the best scoring hit in this clan to current sequence
  my %one_model_H;  
  my %one_score_H;  
  my %one_evalue_H; 
  my %one_start_H;  
  my %one_stop_H;   
  my %one_strand_H; 
  
  # same as for 'one' data structures, but values are for second best scoring hit
  # in this clan to current sequence that overlaps with hit in 'one' data structures
  my %two_model_H;
  my %two_score_H;
  my %two_evalue_H;
  my %two_start_H;
  my %two_stop_H;
  my %two_strand_H;

  my $prv_target = undef; # target name of previous line
  my $clan       = undef; # clan of current model

  open(IN, $sorted_tbl_file) || die "ERROR unable to open sorted tabular file $sorted_tbl_file for reading";

  init_vars(\%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H);
  init_vars(\%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);

  my ($target, $model, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue);
  my $better_than_one; # set to true for each hit if it is better than our current 'one' hit
  my $better_than_two; # set to true for each hit if it is better than our current 'two' hit
  my $have_evalues = (($search_method eq "cmsearch-hmmonly") || ($search_method eq "cmscan-hmmonly") ||
                      ($search_method eq "cmsearch-slow")    || ($search_method eq "cmscan-slow")    ||
                      ($search_method eq "nhmmer")) ? 1 : 0;

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

    if(($search_method eq "cmsearch-fast") || ($search_method eq "cmscan-fast")) { 
      if($search_method eq "cmsearch-fast") {
        if(scalar(@el_A) != 9) { die "ERROR did not find 9 columns in fast cmsearch tabular output at line: $line"; }
        # NC_013790.1 SSU_rRNA_archaea 1215.0  760337  762896      +     ..  ?      2937203
        ($target, $model, $score, $seqfrom, $seqto, $strand) = 
            ($el_A[0], $el_A[1], $el_A[2], $el_A[3], $el_A[4], $el_A[5]);
      }
      else { # $search_method is "cmscan-fast"
        if(scalar(@el_A) != 17) { die "ERROR did not find 9 columns in fast cmscan tabular output at line: $line"; }
        ##idx target name          query name             clan name  score seq from   seq to strand bounds      seqlen olp anyidx afrct1 afrct2 winidx wfrct1 wfrct2
        ##--- -------------------- ---------------------- --------- ------ -------- -------- ------ ------ ----------- --- ------ ------ ------ ------ ------ ------
        # 1    SSU_rRNA_archaea     lcl|dna_BP331_0.3k:467 -          559.8        1     1232      +     []        1232  =       2  1.000  1.000      "      "      "
        ($target, $model, $score, $seqfrom, $seqto, $strand) = 
            ($el_A[2], $el_A[1], $el_A[4], $el_A[5], $el_A[6], $el_A[7]);
      }
    }    
    elsif($search_method eq "cmsearch-hmmonly" || $search_method eq "cmsearch-slow") { 
      ##target name             accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
      ##----------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
      #lcl|dna_BP444_24.8k:251  -         SSU_rRNA_archaea     RF01959   hmm        3     1443        2     1436      +     -    6 0.53   6.0 1078.9         0 !   -
      if(scalar(@el_A) < 18) { die "ERROR found less than 18 columns in cmsearch tabular output at line: $line"; }
      ($target, $model, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue) = 
          ($el_A[0], $el_A[2], $el_A[5], $el_A[6], $el_A[7], $el_A[8], $el_A[9],  $el_A[14], $el_A[15]);
    }
    elsif($search_method eq "cmscan-hmmonly" || $search_method eq "cmscan-slow") { 
      ##idx target name          accession query name             accession clan name mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc olp anyidx afrct1 afrct2 winidx wfrct1 wfrct2 description of target
      ##--- -------------------- --------- ---------------------- --------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- --- ------ ------ ------ ------ ------ ------ ---------------------
      #  1    SSU_rRNA_bacteria    RF00177   lcl|dna_BP331_0.3k:467 -         -         hmm       37     1301        1     1228      +     -    6 0.53   6.2  974.2  2.8e-296  !   ^       -      -      -      -      -      - -
      # same as cmsearch but target/query are switched
      if(scalar(@el_A) < 27) { die "ERROR found less than 27 columns in cmscan tabular output at line: $line"; }
      ($target, $model, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue) = 
          ($el_A[3], $el_A[1], $el_A[7], $el_A[8], $el_A[9], $el_A[10], $el_A[11],  $el_A[16], $el_A[17]);
    }
    elsif($search_method eq "nhmmer") { 
      ## target name            accession  query name           accession  hmmfrom hmm to alifrom  ali to envfrom  env to  sq len strand   E-value  score  bias  description of target
      ###    ------------------- ---------- -------------------- ---------- ------- ------- ------- ------- ------- ------- ------- ------ --------- ------ ----- ---------------------
      #  lcl|dna_BP444_24.8k:251  -          SSU_rRNA_archaea     RF01959          3    1443       2    1436       1    1437    1437    +           0 1036.1  18.0  -
      if(scalar(@el_A) < 16) { die "ERROR found less than 16 columns in nhmmer tabular output at line: $line"; }
      ($target, $model, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue) = 
          ($el_A[0], $el_A[2], $el_A[4], $el_A[5], $el_A[6], $el_A[7], $el_A[11],  $el_A[13], $el_A[12]);
    }
    elsif($search_method eq "ssualign") { 
      ##                                                 target coord   query coord                         
      ##                                       ----------------------  ------------                         
      ## model name  target name                    start        stop  start   stop    bit sc   E-value  GC%
      ## ----------  ------------------------  ----------  ----------  -----  -----  --------  --------  ---
      #  archaea     lcl|dna_BP331_0.3k:467            18        1227      1   1508    478.86         -   53
      if(scalar(@el_A) != 9) { die "ERROR did not find 9 columns in SSU-ALIGN tabular output line: $line"; }
      ($target, $model, $seqfrom, $seqto, $mdlfrom, $mdlto, $score) = 
          ($el_A[1], $el_A[0], $el_A[2], $el_A[3], $el_A[4], $el_A[5], $el_A[6]);
      $strand = "+";
      if($seqfrom > $seqto) { $strand = "-"; }
      $evalue = "-";
    }
    else { 
      die "ERROR, $search_method is not a valid method";
    }

    $clan = $clan_HR->{$model};
    if(! defined $clan) { 
      die "ERROR unrecognized model $model, no clan information";
    }

    # two sanity checks:
    # make sure we have sequence length information for this sequence
    if(! exists $seqlen_HR->{$target}) { 
      die "ERROR found sequence $target we didn't read length information for in $seqstat_file";
    }
    # make sure we haven't output information for this sequence already
    if($seqlen_HR->{$target} == -1) { 
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
      output_one_target_wrapper($long_out_FH, $short_out_FH, \%opt_HH, $have_evalues, $max_targetname_length, $domain_HR, $prv_target, $seqlen_HR,
                                \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
                                \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
    }
    ##############################################################
    
    ##########################################################
    # Determine if this hit is either a new 'one' or 'two' hit
    $better_than_one = 0; # set to '1' below if no 'one' hit exists yet, or this E-value/score is better than current 'one'
    $better_than_two = 0; # set to '1' below if no 'two' hit exists yet, or this E-value/score is better than current 'two'
    if(! defined $one_score_H{$clan}) {  # use 'score' not 'evalue' because some methods don't define evalue, but all define score
      $better_than_one = 1; # no current, 'one' this will be it
    }
    else { 
      if($have_evalues) { 
        if(($evalue < $one_evalue_H{$clan}) || # this E-value is better than (less than) our current 'one' E-value
           ($evalue eq $one_evalue_H{$clan} && $score > $one_score_H{$clan})) { # this E-value equals current 'one' E-value, 
          # but this score is better than current 'one' score
        $better_than_one = 1;
        }
      }
      else { # we don't have E-values
        if($score > $one_score_H{$clan}) { # score is better than current 'one' score
          $better_than_one = 1;
        }
      }
    }
    # only possibly set $better_than_two to TRUE if $better_than_one is FALSE, and it's not the same model as 'one'
    if((! $better_than_one) && ($model ne $one_model_H{$clan})) {  
      if(! defined $two_score_H{$clan}) {  # use 'score' not 'evalue' because some methods don't define evalue, but all define score
        $better_than_two = 1;
      }
      else { 
        if($have_evalues) { 
          if(($evalue < $two_evalue_H{$clan}) || # this E-value is better than (less than) our current 'two' E-value
             ($evalue eq $two_evalue_H{$clan} && $score > $two_score_H{$clan})) { # this E-value equals current 'two' E-value, 
            # but this score is better than current 'two' score
            $better_than_two = 1;
          }
        }
        else { # we don't have E-values
          if($score > $two_score_H{$clan}) { # score is better than current 'one' score
            $better_than_two = 1;
          }
        }
      }
    }
    # finished determining if this hit is a new 'one' or 'two' hit
    ##########################################################
    
    ##########################################################
    # if we have a new hit, update 'one' and/or 'two' data structures
    if($better_than_one) { 
      # new 'one' hit, update 'one' variables, 
      # but first copy existing 'one' hit values to 'two', if 'one' hit is defined and it's a different model than current $model
      if(defined $one_model_H{$clan} && $one_model_H{$clan} ne $model) { 
        set_vars($clan, \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H, 
                 $one_model_H{$clan},   $one_score_H{$clan},  $one_evalue_H{$clan},  $one_start_H{$clan},  $one_stop_H{$clan},  $one_strand_H{$clan});
      }
      # now set new 'one' hit values
      set_vars($clan, \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
               $model,       $score,      $evalue,      $seqfrom,    $seqto,     $strand);
    }
    elsif($better_than_two) { 
      # new 'two' hit, set it
      set_vars($clan, \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H, 
               $model,       $score,      $evalue,      $seqfrom,    $seqto,     $strand);
    }
    # finished updating 'one' or 'two' data structures
    ##########################################################

    $prv_target = $target;

    # sanity check
    if((defined $one_model_H{$clan} && defined $two_model_H{$clan}) && ($one_model_H{$clan} eq $two_model_H{$clan})) { 
      die "ERROR, coding error, one_model and two_model are identical for $clan $target";
    }
  }

  # output data for final sequence
  output_one_target_wrapper($long_out_FH, $short_out_FH, \%opt_HH, $have_evalues, $max_targetname_length, $domain_HR, $prv_target, $seqlen_HR,
                            \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
                            \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
  
  # close file handle
  close(IN);
  
  return;
}

#################################################################
# Subroutine : init_vars()
# Incept:      EPN, Tue Dec 13 14:53:37 2016
#
# Purpose:     Initialize variables to undefined 
#              given references to them.
#              
# Arguments: 
#   $model_HR:   REF to $model variable hash, a model name
#   $score_HR:   REF to $score variable hash, a bit score
#   $evalue_HR:  REF to $evalue variable hash, an E-value
#   $start_HR:   REF to $start variable hash, a start position
#   $stop_HR:    REF to $stop variable hash, a stop position
#   $strand_HR:  REF to $strand variable hash, a strand
# 
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub init_vars { 
  my $nargs_expected = 6;
  my $sub_name = "init_vars";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($model_HR, $score_HR, $evalue_HR, $start_HR, $stop_HR, $strand_HR) = @_;

  foreach my $key (keys %{$model_HR}) { 
    delete $model_HR->{$key};
    delete $score_HR->{$key};
    delete $evalue_HR->{$key};
    delete $start_HR->{$key};
    delete $stop_HR->{$key};
    delete $strand_HR->{$key};
  }
  

  return;
}

#################################################################
# Subroutine : set_vars()
# Incept:      EPN, Tue Dec 13 14:53:37 2016
#
# Purpose:     Set variables defining the top-scoring 'one' 
#              model. If necessary switch the current
#              'one' variable values to 'two' variables.
#              
# Arguments: 
#   $clan:      clan, key to hashes
#   $model_HR:  REF to hash of $model variables, a model name
#   $score_HR:  REF to hash of $score variables, a bit score
#   $evalue_HR: REF to hash of $evalue variables, an E-value
#   $start_HR:  REF to hash of $start variables, a start position
#   $stop_HR:   REF to hash of $stop variables, a stop position
#   $strand_HR: REF to hash of $strand variables, a strand
#   $model:     value to set $model_HR{$clan} to 
#   $score:     value to set $score_HR{$clan} to 
#   $evalue:    value to set $evalue_HR{$clan} to 
#   $start:     value to set $start_HR{$clan} to 
#   $stop:      value to set $stop_HR{$clan} to 
#   $strand:    value to set $strand_HR{$clan} to 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub set_vars { 
  my $nargs_expected = 13;
  my $sub_name = "set_vars";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($clan, 
      $model_HR, $score_HR, $evalue_HR, $start_HR, $stop_HR, $strand_HR, 
      $model,    $score,    $evalue,    $start,    $stop,    $strand) = @_;

  $model_HR->{$clan}  = $model;
  $score_HR->{$clan}  = $score;
  $evalue_HR->{$clan} = $evalue;
  $start_HR->{$clan}  = $start;
  $stop_HR->{$clan}   = $stop;
  $strand_HR->{$clan} = $strand;

  return;
}

#################################################################
# Subroutine : output_one_target_wrapper()
# Incept:      EPN, Thu Dec 22 13:49:53 2016
#
# Purpose:     Call function to output information and reset variables.
#              
# Arguments: 
#   $long_FH:       file handle to output long data to
#   $short_FH:      file handle to output short data to
#   $opt_HHR:       reference to 2D hash of cmdline options
#   $have_evalues:  '1' if we have E-values, '0' if not
#   $target_width:  maximum length of any target name
#   $domain_HR:     reference to domain hash
#   $target:        target name
#   $seqlen_HR:     hash of target sequence lengths
#   %one_model_HR:  'one' model
#   %one_score_HR:  'one' bit score
#   %one_evalue_HR: 'one' E-value
#   %one_start_HR:  'one' start position
#   %one_stop_HR:   'one' stop position
#   %one_strand_HR: 'one' strand 
#   %two_model_HR:  'two' model
#   %two_score_HR:  'two' bit score
#   %two_evalue_HR: 'two' E-value
#   %two_start_HR:  'two' start position
#   %two_stop_HR:   'two' stop position
#   %two_strand_HR: 'two' strand 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_one_target_wrapper { 
  my $nargs_expected = 20;
  my $sub_name = "output_one_target_wrapper";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($long_FH, $short_FH, $opt_HHR, $have_evalues, $target_width, $domain_HR, $target, $seqlen_HR, 
      $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
      $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR) = @_;

  # output to short and long output files
  output_one_target($long_FH, 0, $opt_HHR, $have_evalues, $target_width, $domain_HR, $target, $seqlen_HR->{$target}, 
                    $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
                    $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR);
  output_one_target($short_FH, 1, $opt_HHR, $have_evalues, $target_width, $domain_HR, $target, $seqlen_HR->{$target}, 
                    $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
                    $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR);

  # reset vars
  init_vars($one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR);
  init_vars($two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR);
  $seqlen_HR->{$target} = -1; # serves as a flag that we output info for this sequence
  
  return;
}

#################################################################
# Subroutine : output_one_target()
# Incept:      EPN, Tue Dec 13 15:30:12 2016
#
# Purpose:     Output information for current sequence in either
#              long or short mode. Short mode if $do_short is true.
#              
# Arguments: 
#   $FH:            file handle to output to
#   $do_short:      TRUE to output in 'short' concise mode, else do long mode
#   $opt_HHR:       reference to 2D hash of cmdline options
#   $have_evalues:  '1' if we have E-values, '0' if not
#   $target_width:  maximum length of any target name
#   $domain_HR:     reference to domain hash
#   $target:        target name
#   $seqlen:        length of target sequence
#   %one_model_HR:  'one' model
#   %one_score_HR:  'one' bit score
#   %one_evalue_HR: 'one' E-value
#   %one_start_HR:  'one' start position
#   %one_stop_HR:   'one' stop position
#   %one_strand_HR: 'one' strand 
#   %two_model_HR:  'two' model
#   %two_score_HR:  'two' bit score
#   %two_evalue_HR: 'two' E-value
#   %two_start_HR:  'two' start position
#   %two_stop_HR:   'two' stop position
#   %two_strand_HR: 'two' strand 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_one_target { 
  my $nargs_expected = 20;
  my $sub_name = "output_one_target";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $do_short, $opt_HHR, $have_evalues, $target_width, $domain_HR, $target, $seqlen, 
      $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
      $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR) = @_;

  my $diff_thresh = opt_Get("-d", $opt_HHR);

  # debug_print(*STDOUT, "$target:$seqlen:one", $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR);
  # debug_print(*STDOUT, "$target:$seqlen:two", $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR);

  # determine the winning clan
  my $wclan = undef;
  my $better_than_winning = 0;
  foreach my $clan (keys %{$one_model_HR}) { 
    # determine if this hit is better than our winning clan
    if(! defined $wclan) { 
      $better_than_winning = 1; 
    }
    elsif($have_evalues) { 
      if(($one_evalue_HR->{$clan} < $one_evalue_HR->{$wclan}) || # this E-value is better than (less than) our current winning E-value
         ($one_evalue_HR->{$clan} eq $one_evalue_HR->{$wclan} && $one_score_HR->{$clan} > $one_score_HR->{$wclan})) { # this E-value equals current 'one' E-value, but this score is better than current winning score
        $better_than_winning = 1;
      }
    }
    else { # we don't have E-values
      if($one_score_HR->{$clan} > $one_score_HR->{$wclan}) { # score is better than current winning score
        $better_than_winning = 1;
      }
    }
    if($better_than_winning) { 
      $wclan = $clan;
    }
  }

  # build up 'extra information' about other hits in other clans, if any
  my $extra_string = "";
  my $nhits = 1;
  foreach my $clan (keys %{$one_model_HR}) { 
    if($clan ne $wclan) { 
      if(exists($one_model_HR->{$clan})) { 
        if($extra_string ne "") { $extra_string .= ","; }
        if($have_evalues) { 
          $extra_string .= sprintf("%s:%s:%g:%.1f/%d-%d:%s",
                                   $clan, $one_model_HR->{$clan}, $one_evalue_HR->{$clan}, $one_score_HR->{$clan}, 
                                   $one_start_HR->{$clan}, $one_stop_HR->{$clan}, $one_strand_HR->{$clan});
        }
        else { # we don't have E-values
          $extra_string .= sprintf("%s:%s:%.1f/%d-%d:%s",
                                   $clan, $one_model_HR->{$clan}, $one_score_HR->{$clan}, 
                                   $one_start_HR->{$clan}, $one_stop_HR->{$clan}, $one_strand_HR->{$clan});
        }
        $nhits++;
      }
    }
  }
  my $coverage = (abs($one_stop_HR->{$wclan} - $one_start_HR->{$wclan}) + 1) / $seqlen;
  my $one_evalue2print = ($have_evalues) ? sprintf("%10g", $one_evalue_HR->{$wclan}) : "-";
  my $two_evalue2print = undef;
  if(defined $two_model_HR->{$wclan}) { 
    $two_evalue2print = ($have_evalues) ? sprintf("%10g", $two_evalue_HR->{$wclan}) : "-";
  }
  
  my $score_diff = (exists $two_score_HR->{$wclan}) ? ($one_score_HR->{$wclan} - $two_score_HR->{$wclan}) : $one_score_HR->{$wclan};
  # does the sequence pass or fail? 
  # FAILs iff: 
  # - score difference between top two models is exceeds $diff_thresh AND top two models are different domains
  # OR
  # - number of hits to different clans is higher than one
  my $pass_fail = "PASS";
  if(defined $two_model_HR->{$wclan}) { 
    if(($score_diff <= $diff_thresh) && 
       ($domain_HR->{$one_model_HR->{$wclan}} ne $domain_HR->{$two_model_HR->{$wclan}})) { 
      $pass_fail = "FAIL";
    }
  }
  if($nhits > 1) { $pass_fail = "FAIL"; }

  if($do_short) { 
    printf $FH ("%-*s  %-20s  %s\n", 
                $target_width, $target, $wclan . "." . $domain_HR->{$one_model_HR->{$wclan}}, $pass_fail);
  }
  else { 
    printf $FH ("%-*s  %4s  %10d  %3d  %3s  %-15s  %-22s  %10s  %10.1f  %s  %5.3f  %10d  %10d  ", 
                $target_width, $target, $pass_fail, $seqlen, $nhits, $wclan, $domain_HR->{$one_model_HR->{$wclan}}, $one_model_HR->{$wclan}, 
                $one_evalue2print, $one_score_HR->{$wclan}, $one_strand_HR->{$wclan}, $coverage, 
                $one_start_HR->{$wclan}, $one_stop_HR->{$wclan});
    
    if(defined $two_model_HR->{$wclan}) { 
      printf $FH ("%10.1f  %-22s  %10s  %10.1f  ", 
             $one_score_HR->{$wclan} - $two_score_HR->{$wclan}, $two_model_HR->{$wclan}, $two_evalue2print, $two_score_HR->{$wclan});
    }
    else { 
      printf $FH ("%10s  %-22s  %10s  %10.2s  ", 
             "-" , "-", "-", "-");
    }
    
    if($extra_string eq "") { 
      $extra_string = "-";
    }
    
    print $FH ("$extra_string\n");
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
#   $FH:            file handle to output to
#   $target_width:  maximum length of any target name
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

  my ($FH, $target_width) = (@_);

  printf $FH ("%-*s  %-20s  %s\n", $target_width, "#target", "classification", "pass/fail");
  printf $FH ("%-*s  %-20s  %s\n", $target_width, "#-----------------------------", "--------------------", "---------");

  return;
}

#################################################################
# Subroutine : output_long_headers()
# Incept:      EPN, Fri Dec 30 08:51:01 2016
#
# Purpose:     Output column headers to the long output file.
#              
# Arguments: 
#   $FH:            file handle to output to
#   $target_width:  maximum length of any target name
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_long_headers { 
  my $nargs_expected = 2;
  my $sub_name = "output_short_headers";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $target_width) = (@_);

  printf $FH ("%-*s  %4s  %10s  %3s  %3s  %-15s  %-80s  %10s  %-46s  %s\n", 
              $target_width, "#", "", "", "", "", "", "                              best-scoring model", "", "         second-best-scoring model", "",
              "model", "evalue", "score", "extra");
  printf $FH ("%-*s  %4s  %10s  %3s  %3s  %-15s  %78s  %10s  %46s  %s\n", 
              $target_width, "#", "", "", "", "", "", "--------------------------------------------------------------------------------", 
              "", "----------------------------------------------", "");

  printf $FH ("%-*s  %4s  %10s  %3s  %3s  %-15s  %-22s  %10s  %10s  %s  %5s  %10s  %10s  %10s  %-22s  %10s  %10s  %s\n", 
              $target_width, "#target", "p/f", "targetlen", "#ht", "fam", "domain", "model", "evalue", "score", "s", "cov", "start", "stop", "scdiff", 
              "model", "evalue", "score", "extra");
  printf $FH ("%-*s  %4s  %10s  %3s  %3s  %-15s  %-22s  %10s  %10s  %s  %5s  %10s  %10s  %10s  %-22s  %10s  %10s  %s\n", 
              $target_width, "#-----------------------------", "----", "----------", "---", "---", "---------------", "----------------------", "----------", "----------", "-", 
              "-----", "----------", "----------", "----------", "----------------------", "----------", "----------", "-----");

  return;
}

#################################################################
# Subroutine : output_short_tail()
# Incept:      EPN, Thu Feb 23 15:29:21 2017
#
# Purpose:     Output explanation of columns to short output file.
#              
# Arguments: 
#   $FH:       file handle to output to
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_short_tail { 
  my $nargs_expected = 1;
  my $sub_name = "output_short_tail";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH) = (@_);

#  printf $FH ("# Explanation of columns:\n");
#  printf $FH ("# Column 1: name of target sequence\n");
#  printf $FH ("# Column 2: classification of sequence\n");
#  printf $FH ("# Column 3: PASS/FAIL\n");

  return;
}


#################################################################
# Subroutine : output_long_tail()
# Incept:      EPN, Thu Feb 23 15:33:25 2017
#
# Purpose:     Output explanation of columns to long output file.
#              
# Arguments: 
#   $FH:       file handle to output to
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_long_tail { 
  my $nargs_expected = 1;
  my $sub_name = "output_long_tail";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH) = (@_);

#  printf $FH ("# Explanation of columns:\n");
#  printf $FH ("# Column 1: name of target sequence\n");
#  printf $FH ("# Column 2: classification of sequence\n");
#  printf $FH ("# Column 3: PASS/FAIL\n");

  return;
}


#####################################################################
# Subroutine: output_banner()
# Incept:     EPN, Thu Oct 30 09:43:56 2014 (rnavore)
# 
# Purpose:    Output the banner with info on the script, input arguments
#             and options used.
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

  foreach my $clan (sort keys %{$model_HR}) { 
    printf("clan: $clan\n");
    printf("\tmodel:  $model_HR->{$clan}\n");
    printf("\tscore:  $score_HR->{$clan}\n");
    printf("\tevalue: $evalue_HR->{$clan}\n");
    printf("\tstart:  $start_HR->{$clan}\n");
    printf("\tstop:   $stop_HR->{$clan}\n");
    printf("\tstrand: $strand_HR->{$clan}\n");
    printf("--------------------------------\n");
  }

  return;
}
