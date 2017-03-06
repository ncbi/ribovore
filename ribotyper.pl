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

$opt_group_desc_H{"2"} = "options for controlling the search algorithm";
#       option               type   default                group  requires incompat                                  preamble-output             help-output    
opt_Add("--nhmmer",       "boolean", 0,                       2,  undef,   "--cmscan,--ssualign,--hmm,--slow",       "annotate with nhmmer",     "using nhmmer for annotation",    \%opt_HH, \@opt_order_A);
opt_Add("--cmscan",       "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign",                    "annotate with cmsearch",   "using cmscan for annotation",    \%opt_HH, \@opt_order_A);
opt_Add("--ssualign",     "boolean", 0,                       2,  undef,   "--nhmmer,--cmscan,--hmm,--slow",         "annotate with SSU-ALIGN",  "using SSU-ALIGN for annotation", \%opt_HH, \@opt_order_A);
opt_Add("--hmm",          "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign,--slow",             "run in slower HMM mode",   "run in slower HMM mode",         \%opt_HH, \@opt_order_A);
opt_Add("--slow",         "boolean", 0,                       2,  undef,   "--nhmmer,--ssualign,--hmm",              "run in slow CM mode",      "run in slow CM mode, maximize boundary accuracy", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"3"} = "options for controlling the minimum bit score for any hit";
#     option                 type   default                group   requires incompat    preamble-output                                 help-output    
opt_Add("--minbit",        "real",   "20.",                   3,  undef,   undef,      "set minimum bit score cutoff for hits to <x>",  "set minimum bit score cutoff for hits to include to <x> bits", \%opt_HH, \@opt_order_A);
opt_Add("--nominbit",   "boolean",   0,                       3,  undef,   undef,      "turn off minimum bit score cutoff for hits",    "turn off minimum bit score cutoff for hits", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"4"} = "options for controlling the score difference failure threshold";
#     option                 type   default                group   requires incompat    preamble-output                                          help-output    
opt_Add("--posdiff",       "real",   "0.05",                  4,  undef,   undef,      "use min acceptable per-posn score difference of <x>", "use minimum acceptable bit per posn score difference b/t best and 2nd best model to <x> bits", \%opt_HH, \@opt_order_A);
opt_Add("--absdiff",       "real",   "50.",                   4,  undef,   undef,      "use min acceptable total score difference of <x>",    "use minimum acceptable bit total score difference b/t best and 2nd best model to <x> bits", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"5"} = "optional input files";
#       option               type   default                group  requires incompat  preamble-output                     help-output    
opt_Add("--inaccept",     "string",  undef,                   5,  undef,   undef,    "read acceptable models from <s>",  "read acceptable domains/models from file <s>", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"6"} = "advanced options";
#       option               type   default                group  requires incompat             preamble-output                     help-output    
opt_Add("--evalues",      "boolean", 0,                       6,  undef,   "--ssualign",        "rank by E-values, not bit scores", "rank hits by E-values, not bit scores", \%opt_HH, \@opt_order_A);
opt_Add("--skipsearch",   "boolean", 0,                       6,  undef,   "-f",                "skip search stage",                "skip search stage, use results from earlier run", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: ribotyper.pl [-options] <fasta file to annotate> <model file> <fam/domain info file> <output directory>\n";
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
                'hmm'          => \$GetOptions_H{"--hmm"},
                'slow'         => \$GetOptions_H{"--slow"},
# options controlling minimum bit score cutoff 
                'minbit=s'     => \$GetOptions_H{"--minbit"},
                'nominbit'     => \$GetOptions_H{"--nominbit"},
# options controlling the score difference failure threshold
                'posdiff=s'    => \$GetOptions_H{"--posdiff"},
                'absdiff=s'    => \$GetOptions_H{"--absdiff"},
# optional input files
                'inaccept=s'   => \$GetOptions_H{"--inaccept"},
# advanced options
                'evalues'      => \$GetOptions_H{"--evalues"},
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
my ($seq_file, $model_file, $modelinfo_file, $dir_out) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

# do some final option check that is currently too sophisticated for epn-options
if(opt_Get("--evalues", \%opt_HH)) { 
  if((! opt_Get("--nhmmer", \%opt_HH)) && 
     (! opt_Get("--hmm", \%opt_HH)) && 
     (! opt_Get("--slow", \%opt_HH))) { 
    die "ERROR, --evalues requires one of --nhmmer, --hmm or --slow";
  }
}

my $cmd;                       # a command to be run by run_command()
my $ncpu = 0;                  # number of CPUs to use with search command

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

push(@arg_desc_A, "model information input file");
push(@arg_A, $modelinfo_file);

push(@arg_desc_A, "output directory name");
push(@arg_A, $dir_out);

output_banner(*STDOUT, $version, $releasedate, $synopsis, $date);
opt_OutputPreamble(*STDOUT, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

my $unsrt_long_out_file  = $out_root . ".unsrt.long.out";
my $unsrt_short_out_file = $out_root . ".unsrt.short.out";
my $srt_long_out_file  = $out_root . ".long.out";
my $srt_short_out_file = $out_root . ".short.out";
my $unsrt_long_out_FH;  # output file handle for unsorted long output file
my $unsrt_short_out_FH; # output file handle for unsorted short output file
my $srt_long_out_FH;    # output file handle for sorted long output file
my $srt_short_out_FH;   # output file handle for sorted short output file
open($unsrt_long_out_FH,  ">", $unsrt_long_out_file)  || die "ERROR unable to open $unsrt_long_out_file for writing";
open($unsrt_short_out_FH, ">", $unsrt_short_out_file) || die "ERROR unable to open $unsrt_short_out_file for writing";
open($srt_long_out_FH,    ">", $srt_long_out_file)    || die "ERROR unable to open $srt_long_out_file for writing";
open($srt_short_out_FH,   ">", $srt_short_out_file)   || die "ERROR unable to open $srt_short_out_file for writing";

##########################
# determine search method
##########################
my $search_method = undef; # can be any of "cmsearch-hmmonly", "cmscan-hmmonly", 
#                                          "cmsearch-slow",    "cmscan-slow", 
#                                          "cmsearch-fast",    "cmscan-fast",
#                                          "nhmmer",           "ssualign"

if   (opt_Get("--nhmmer", \%opt_HH))   { $search_method = "nhmmer"; }
elsif(opt_Get("--cmscan", \%opt_HH))   { $search_method = "cmscan-fast"; }
elsif(opt_Get("--ssualign", \%opt_HH)) { $search_method = "ssualign"; }
else                                   { $search_method = "cmsearch-fast"; }

if(opt_Get("--hmm", \%opt_HH)) { 
  if   ($search_method eq "cmsearch-fast") { $search_method = "cmsearch-hmmonly"; }
  elsif($search_method eq "cmscan-fast")   { $search_method = "cmscan-hmmonly"; }
  else { die "ERROR, --hmm used in error, search_method: $search_method"; }
}
elsif(opt_Get("--slow", \%opt_HH)) { 
  if   ($search_method eq "cmsearch-fast") { $search_method = "cmsearch-slow"; }
  elsif($search_method eq "cmscan-fast")   { $search_method = "cmscan-slow"; }
  else { die "ERROR, --hmm used in error, search_method: $search_method"; }
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
# parse fam file
# variables related to fams and domains
my %family_H = (); # hash of fams,   key: model name, value: name of family model belongs to (e.g. SSU)
my %domain_H = (); # hash of domains, key: model name, value: name of domain model belongs to (e.g. Archaea)
parse_modelinfo_file($modelinfo_file, \%family_H, \%domain_H);

# parse the model file and make sure that there is a 1:1 correspondence between 
# models in the models file and models listed in the model info file
my %width_H = (); # hash, key is "model" or "target", value is maximum length of any model/target
$width_H{"model"} = parse_model_file($model_file, \%family_H);

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
my %accept_H = ();
if(opt_IsUsed("--inaccept", \%opt_HH)) { 
  foreach $model (keys %domain_H) { 
    $accept_H{$model} = 0;
  }    
  parse_inaccept_file(opt_Get("--inaccept", \%opt_HH), \%accept_H);
}
else { # --inaccept not used, all models are acceptable
  foreach $model (keys %domain_H) { 
    $accept_H{$model} = 1;
  }   
} 

# run esl-seqstat to get sequence lengths
my $seqstat_file = $out_root . ".seqstat";
run_command("esl-seqstat -a $seq_file > $seqstat_file", opt_Get("-v", \%opt_HH));
my %seqidx_H = (); # key: sequence name, value: index of sequence in original input sequence file (1..$nseq)
my %seqlen_H = (); # key: sequence name, value: length of sequence, 
                   # value set to -1 after we output info for this sequence
                   # and then serves as flag for: "we output this sequence 
                   # already, if we see it again we know the tbl file was not
                   # sorted properly.
# parse esl-seqstat file to get lengths
my $max_targetname_length = length("target"); # maximum length of any target name
my $max_length_length     = length("length"); # maximum length of the string-ized length of any target
my $nseq                  = 0; # number of sequences read
parse_seqstat_file($seqstat_file, \$max_targetname_length, \$max_length_length, \$nseq, \%seqidx_H, \%seqlen_H); 
$width_H{"target"} = $max_targetname_length;
$width_H{"length"} = $max_length_length;
$width_H{"index"}  = length($nseq);
if($width_H{"index"} < length("#idx")) { $width_H{"index"} = length("#idx"); }

# now that we know the max sequence name length, we can output headers to the output files
output_long_headers($srt_long_out_FH,     \%opt_HH, \%width_H);
output_short_headers($srt_short_out_FH,             \%width_H);
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
parse_sorted_tbl_file($sorted_tblout_file, $search_method, \%opt_HH, \%width_H, \%seqidx_H, \%seqlen_H, 
                      \%family_H, \%domain_H, \%accept_H, $unsrt_long_out_FH, $unsrt_short_out_FH);
output_progress_complete($start_secs, undef, undef, *STDOUT);
###########################################################################

#######################################################
# Step 5: Add data for sequences with 0 hits and then sort the output files 
#         based on sequence index
#         from original input file
###########################################################################
$start_secs = output_progress_prior("Sorting and finalizing output files", $progress_w, undef, *STDOUT);

# for any sequence that has 0 hits (we'll know these as those that 
# do not have a value of -1 in $seqlen_HR->{$target} at this stage
my $target;
foreach $target (keys %seqlen_H) { 
  if($seqlen_H{$target} ne "-1") { 
    output_one_hitless_target_wrapper($unsrt_long_out_FH, $unsrt_short_out_FH, \%opt_HH, \%width_H, $target, \%seqidx_H, \%seqlen_H);
  }
}

# now close the unsorted file handles (we're done with these) 
# and also the sorted file handles (so we can output directly to them using system())
# Remember, we already output the headers to these files above
close($unsrt_long_out_FH);
close($unsrt_short_out_FH);
close($srt_long_out_FH);
close($srt_short_out_FH);

$cmd = "sort -n $unsrt_short_out_file >> $srt_short_out_file";
run_command($cmd, opt_Get("-v", \%opt_HH));

$cmd = "sort -n $unsrt_long_out_file >> $srt_long_out_file";
run_command($cmd, opt_Get("-v", \%opt_HH));

# reopen them, and add tails to the output files and exit.
# now that we know the max sequence name length, we can output headers to the output files
open($srt_long_out_FH,  ">>", $unsrt_long_out_file)  || die "ERROR unable to open $unsrt_long_out_file for appending";
open($srt_short_out_FH, ">>", $unsrt_short_out_file) || die "ERROR unable to open $unsrt_short_out_file for appending";
output_long_tail($srt_long_out_FH);
output_short_tail($srt_short_out_FH);
close($srt_short_out_FH);
close($srt_long_out_FH);
output_progress_complete($start_secs, undef, undef, *STDOUT);

printf("#\n# Short (6 column) output saved to file $srt_short_out_file.\n");
printf("# Long (%d column) output saved to file $srt_long_out_file.\n", (opt_Get("--evalues", \%opt_HH) ? 15 : 13));
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
# parse_modelinfo_file:    parse the model info input file
# parse_inaccept_file:      parse the inaccept input file (--inaccept)
# parse_model_file:         parse the model file 
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
# Subroutine : parse_modelinfo_file()
# Incept:      EPN, Mon Dec 19 10:01:32 2016
#
# Purpose:     Parse a model info input file.
#              
# Arguments: 
#   $modelinfo_file: file to parse
#   $family_HR:       ref to hash of family names, key is model name, value is family name
#   $domain_HR:       ref to hash of domain names, key is model name, value is domain name
#
# Returns:     Nothing. Fills %{$family_H}, %{$domain_HR}
# 
# Dies:        Never.
#
################################################################# 
sub parse_modelinfo_file { 
  my $nargs_expected = 3;
  my $sub_name = "parse_modelinfo_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($modelinfo_file, $family_HR, $domain_HR) = @_;

  open(IN, $modelinfo_file) || die "ERROR unable to open model info file $modelinfo_file for reading";

# example line:
# SSU_rRNA_archaea SSU Archaea

  open(IN, $modelinfo_file) || die "ERROR unable to open $modelinfo_file for reading"; 
  while(my $line = <IN>) { 
    if($line !~ m/^\#/) { # skip comment lines
      chomp $line;
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 3) { 
        die "ERROR didn't read 3 tokens in model info input file $modelinfo_file, line $line"; 
      }
      my($model, $family, $domain) = (@el_A);

      if(exists $family_HR->{$model}) { 
        die "ERROR read model $model twice in $modelinfo_file"; 
      }
      $family_HR->{$model} = $family;
      $domain_HR->{$model} = $domain;
    }
  }
  close(IN);

  return;
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
#
# Returns:     Nothing. Updates %{$accpep_HR}.
# 
# Dies:        Never.
#
################################################################# 
sub parse_inaccept_file { 
  my $nargs_expected = 2;
  my $sub_name = "parse_inaccept_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($inaccept_file, $accept_HR) = @_;

  open(IN, $inaccept_file) || die "ERROR unable to open input accept file $inaccept_file for reading";

# example line (one token per line)
# SSU_rRNA_archaea

  # construct string of all valid model names to use for error message
  my $valid_name_str = "\n";
  my $model;
  foreach $model (sort keys (%{$accept_HR})) { 
    $valid_name_str .= "\t" . $model . "\n";
  }

  open(IN, $inaccept_file) || die "ERROR unable to open $inaccept_file for reading"; 
  while(my $line = <IN>) { 
    chomp $line;
    if($line =~ m/\w/) { # skip blank lines
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 1) { 
        die "ERROR didn't read 1 token in inaccept input file $inaccept_file, line $line\nEach line should have exactly 1 white-space delimited token, a valid model name"; 
      }
      ($model) = (@el_A);
      
      if(! exists $accept_HR->{$model}) { 
        die "ERROR read invalid model name \"$model\" in inaccept input file $inaccept_file\nValid model names are $valid_name_str"; 
      }
      
      $accept_HR->{$model} = 1;
    }
  }
  close(IN);

  return;
}

#################################################################
# Subroutine : parse_model_file()
# Incept:      EPN, Wed Mar  1 14:46:19 2017
#
# Purpose:     Parse the model file to get model names and
#              validate that there is 1:1 correspondence between
#              model names in the model file and the keys 
#              from %{$family_HR}.
#              
# Arguments: 
#   $model_file:  model file to parse
#   $family_HR:   ref to hash of families for each model, ALREADY FILLED
#                 we use this only for validation
#
# Returns:     Maximum length of any model read from the model file.
# 
# Dies:        If $model_file does not exist or is empty.
#
################################################################# 
sub parse_model_file { 
  my $nargs_expected = 2;
  my $sub_name = "parse_inaccept_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($model_file, $family_HR) = @_;

  if(! -e $model_file) { die "ERROR model file $model_file does not exist"; }
  if(! -s $model_file) { die "ERROR model file $model_file exists but is empty"; }

  # make copy of %{$family_HR} with all values set to '0' 
  my $model;
  my @tmp_family_model_A = ();
  my %tmp_family_model_H = ();
  foreach $model (keys %{$family_HR}) { 
    push(@tmp_family_model_A, $model);
    $tmp_family_model_H{$model} = 0; # will set to '1' when we see it in the model file
  }

  my $model_width = length("model");
  my $name_output = `grep NAME $model_file | awk '{ print \$2 }'`;
  my @name_A = split("\n", $name_output);
  foreach $model (@name_A) { 
    if(! exists $tmp_family_model_H{$model}) { 
      die "ERROR read model \"$model\" from model file $model_file that is not listed in the model info file.";
    }
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
# Subroutine : parse_seqstat_file()
# Incept:      EPN, Wed Dec 14 16:16:22 2016
#
# Purpose:     Parse an esl-seqstat -a output file.
#              
# Arguments: 
#   $seqstat_file:            file to parse
#   $max_targetname_length_R: REF to the maximum length of any target name, updated here
#   $max_length_length_R:     REF to the maximum length of string-ized length of any target seq, updated here
#   $nseq_R:                  REF to the number of sequences read, updated here
#   $seqidx_HR:               REF to hash of sequence indices to fill here
#   $seqlen_HR:               REF to hash of sequence lengths to fill here
#
# Returns:     Nothing. Fills %{$seqidx_HR} and %{$seqlen_HR} and updates 
#              $$max_targetname_length_R, $$max_length_length_R, and $$nseq_R.
# 
# Dies:        Never.
#
################################################################# 
sub parse_seqstat_file { 
  my $nargs_expected = 6;
  my $sub_name = "parse_seqstat_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seqstat_file, $max_targetname_length_R, $max_length_length_R, $nseq_R, $seqidx_HR, $seqlen_HR) = @_;

  open(IN, $seqstat_file) || die "ERROR unable to open esl-seqstat file $seqstat_file for reading";

  my $nread = 0;
  my $targetname_length;
  my $seqlength_length;
  my $targetname;
  my $length;

  while(my $line = <IN>) { 
    # = lcl|dna_BP331_0.3k:467     1232 
    # = lcl|dna_BP331_0.3k:10     1397 
    # = lcl|dna_BP331_0.3k:1052     1414 
    chomp $line;
    #print $line . "\n";
    if($line =~ /^\=\s+(\S+)\s+(\d+)/) { 
      $nread++;
      ($targetname, $length) = ($1, $2);
      $seqidx_HR->{$targetname} = $nread;
      $seqlen_HR->{$targetname} = $length;

      $targetname_length = length($targetname);
      if($targetname_length > $$max_targetname_length_R) { 
        $$max_targetname_length_R = $targetname_length;
      }

      $seqlength_length  = length($length);
      if($seqlength_length > $$max_length_length_R) { 
        $$max_length_length_R = $seqlength_length;
      }

    }
  }
  close(IN);
  if($nread == 0) { 
    die "ERROR did not read any sequence lengths in esl-seqstat file $seqstat_file, did you use -a option with esl-seqstat";
  }

  $$nseq_R = $nread;
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
#   $opt_HHR:         ref to 2D options hash of cmdline option values
#   $width_HR:        hash, key is "model" or "target", value 
#                     is width (maximum length) of any target/model
#   $seqidx_HR:       ref to hash of sequence indices, key is sequence name, value is index
#   $seqlen_HR:       ref to hash of sequence lengths, key is sequence name, value is length
#   $family_HR:       ref to hash of family names, key is model name, value is family name
#   $domain_HR:       ref to hash of domain names, key is model name, value is domain name
#   $accept_HR:       ref to hash of acceptable models, key is model name, value is '1' if acceptable
#   $long_out_FH:     file handle for long output file, already open
#   $short_out_FH:    file handle for short output file, already open
#
# Returns:     Nothing. Fills %{$family_H}, %{$domain_HR}
# 
# Dies:        Never.
#
################################################################# 
sub parse_sorted_tbl_file { 
  my $nargs_expected = 11;
  my $sub_name = "parse_sorted_tbl_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($sorted_tbl_file, $search_method, $opt_HHR, $width_HR, $seqidx_HR, $seqlen_HR, $family_HR, $domain_HR, $accept_HR, $long_out_FH, $short_out_FH) = @_;

  # validate search method (sanity check) 
  if(($search_method ne "cmsearch-hmmonly") && ($search_method ne "cmscan-hmmonly") && 
     ($search_method ne "cmsearch-slow")    && ($search_method ne "cmscan-slow") &&
     ($search_method ne "cmsearch-fast")    && ($search_method ne "cmscan-fast") &&      
     ($search_method ne "nhmmer")           && ($search_method ne "ssualign")) { 
    die "ERROR in $sub_name, invalid search method $search_method";
  }

  # determine minimum bit score cutoff
  my $minbit = undef;
  if(! opt_Get("--nominbit", $opt_HHR)) { 
    $minbit = opt_Get("--minbit", $opt_HHR);
  }
  
  # Main data structures: 
  # 'one': current top scoring model for current sequence
  # 'two': current second best scoring model for current sequence 
  #        that overlaps with hit in 'one' data structures
  # 
  # keys for all below are families (e.g. 'SSU' or 'LSU')
  # values are for the best scoring hit in this family to current sequence
  my %one_model_H;  
  my %one_score_H;  
  my %one_evalue_H; 
  my %one_start_H;  
  my %one_stop_H;   
  my %one_strand_H; 
  
  # same as for 'one' data structures, but values are for second best scoring hit
  # in this family to current sequence that overlaps with hit in 'one' data structures
  my %two_model_H;
  my %two_score_H;
  my %two_evalue_H;
  my %two_start_H;
  my %two_stop_H;
  my %two_strand_H;

  my $prv_target = undef; # target name of previous line
  my $family     = undef; # family of current model

  open(IN, $sorted_tbl_file) || die "ERROR unable to open sorted tabular file $sorted_tbl_file for reading";

  init_vars(\%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H);
  init_vars(\%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);

  my ($target, $model, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue);
  my $better_than_one; # set to true for each hit if it is better than our current 'one' hit
  my $better_than_two; # set to true for each hit if it is better than our current 'two' hit
  my $use_evalues = opt_Get("--evalues", $opt_HHR);

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
      output_one_target_wrapper($long_out_FH, $short_out_FH, $opt_HHR, $use_evalues, $width_HR, $domain_HR, $accept_HR, 
                                $prv_target, $seqidx_HR, $seqlen_HR, 
                                \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
                                \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
    }
    ##############################################################
    
    ##########################################################
    # Determine if this hit is either a new 'one' or 'two' hit
    $better_than_one = 0; # set to '1' below if no 'one' hit exists yet, or this E-value/score is better than current 'one'
    $better_than_two = 0; # set to '1' below if no 'two' hit exists yet, or this E-value/score is better than current 'two'
    # first, enforce our global bit score minimum
    if((! defined $minbit) || ($score >= $minbit)) { 
      # yes, we either have no minimum, or our score exceeds our minimum
      if(! defined $one_score_H{$family}) {  # use 'score' not 'evalue' because some methods don't define evalue, but all define score
        $better_than_one = 1; # no current, 'one' this will be it
      }
      else { 
        if($use_evalues) { 
          if(($evalue < $one_evalue_H{$family}) || # this E-value is better than (less than) our current 'one' E-value
             ($evalue eq $one_evalue_H{$family} && $score > $one_score_H{$family})) { # this E-value equals current 'one' E-value, 
            # but this score is better than current 'one' score
            $better_than_one = 1;
          }
        }
        else { # we don't have E-values
          if($score > $one_score_H{$family}) { # score is better than current 'one' score
            $better_than_one = 1;
          }
        }
      }
      # only possibly set $better_than_two to TRUE if $better_than_one is FALSE, and it's not the same model as 'one'
      if((! $better_than_one) && ($model ne $one_model_H{$family})) {  
        if(! defined $two_score_H{$family}) {  # use 'score' not 'evalue' because some methods don't define evalue, but all define score
          $better_than_two = 1;
        }
        else { 
          if($use_evalues) { 
            if(($evalue < $two_evalue_H{$family}) || # this E-value is better than (less than) our current 'two' E-value
               ($evalue eq $two_evalue_H{$family} && $score > $two_score_H{$family})) { # this E-value equals current 'two' E-value, 
              # but this score is better than current 'two' score
              $better_than_two = 1;
            }
          }
          else { # we don't have E-values
            if($score > $two_score_H{$family}) { # score is better than current 'one' score
              $better_than_two = 1;
            }
          }
        }
      }
    } # end of 'if((! defined $minbit) || ($score >= $minbit))'
    # finished determining if this hit is a new 'one' or 'two' hit
    ##########################################################
    
    ##########################################################
    # if we have a new hit, update 'one' and/or 'two' data structures
    if($better_than_one) { 
      # new 'one' hit, update 'one' variables, 
      # but first copy existing 'one' hit values to 'two', if 'one' hit is defined and it's a different model than current $model
      if(defined $one_model_H{$family} && $one_model_H{$family} ne $model) { 
        set_vars($family, \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H, 
                 $one_model_H{$family},   $one_score_H{$family},  $one_evalue_H{$family},  $one_start_H{$family},  $one_stop_H{$family},  $one_strand_H{$family});
      }
      # now set new 'one' hit values
      set_vars($family, \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
               $model,       $score,      $evalue,      $seqfrom,    $seqto,     $strand);
    }
    elsif($better_than_two) { 
      # new 'two' hit, set it
      set_vars($family, \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H, 
               $model,       $score,      $evalue,      $seqfrom,    $seqto,     $strand);
    }
    # finished updating 'one' or 'two' data structures
    ##########################################################

    $prv_target = $target;

    # sanity check
    if((defined $one_model_H{$family} && defined $two_model_H{$family}) && ($one_model_H{$family} eq $two_model_H{$family})) { 
      die "ERROR, coding error, one_model and two_model are identical for $family $target";
    }
  }

  # output data for final sequence
  output_one_target_wrapper($long_out_FH, $short_out_FH, $opt_HHR, $use_evalues, $width_HR, $domain_HR, $accept_HR, 
                            $prv_target, $seqidx_HR, $seqlen_HR, 
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
#   $family:    family, key to hashes
#   $model_HR:  REF to hash of $model variables, a model name
#   $score_HR:  REF to hash of $score variables, a bit score
#   $evalue_HR: REF to hash of $evalue variables, an E-value
#   $start_HR:  REF to hash of $start variables, a start position
#   $stop_HR:   REF to hash of $stop variables, a stop position
#   $strand_HR: REF to hash of $strand variables, a strand
#   $model:     value to set $model_HR{$family} to 
#   $score:     value to set $score_HR{$family} to 
#   $evalue:    value to set $evalue_HR{$family} to 
#   $start:     value to set $start_HR{$family} to 
#   $stop:      value to set $stop_HR{$family} to 
#   $strand:    value to set $strand_HR{$family} to 
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

  my ($family, 
      $model_HR, $score_HR, $evalue_HR, $start_HR, $stop_HR, $strand_HR, 
      $model,    $score,    $evalue,    $start,    $stop,    $strand) = @_;

  $model_HR->{$family}  = $model;
  $score_HR->{$family}  = $score;
  $evalue_HR->{$family} = $evalue;
  $start_HR->{$family}  = $start;
  $stop_HR->{$family}   = $stop;
  $strand_HR->{$family} = $strand;

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
#   $use_evalues:  '1' if we have E-values, '0' if not
#   $width_HR:      hash, key is "model" or "target", value 
#                   is width (maximum length) of any target/model
#   $domain_HR:     reference to domain hash
#   $accept_HR:     reference to the 'accept' hash, key is "model"
#                   value is '1' if hits to model are "PASS"es '0'
#                   if they are "FAIL"s
#   $target:        target name
#   $seqidx_HR:     hash of target sequence indices
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
  my $nargs_expected = 22;
  my $sub_name = "output_one_target_wrapper";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($long_FH, $short_FH, $opt_HHR, $use_evalues, $width_HR, $domain_HR, $accept_HR, 
      $target, $seqidx_HR, $seqlen_HR, 
      $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
      $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR) = @_;

  # output to short and long output files
  output_one_target($long_FH, 0, $opt_HHR, $use_evalues, $width_HR, $domain_HR, $accept_HR, $target, $seqidx_HR->{$target}, $seqlen_HR->{$target}, 
                    $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
                    $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR);
  output_one_target($short_FH, 1, $opt_HHR, $use_evalues, $width_HR, $domain_HR, $accept_HR, $target, $seqidx_HR->{$target}, $seqlen_HR->{$target}, 
                    $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
                    $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR);

  # reset vars
  init_vars($one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR);
  init_vars($two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR);
  $seqlen_HR->{$target} = -1; # serves as a flag that we output info for this sequence
  
  return;
}

#################################################################
# Subroutine : output_one_hitless_target_wrapper()
# Incept:      EPN, Thu Mar  2 11:35:28 2017
#
# Purpose:     Call function to output information for a target
#              with zero hits.
#              
# Arguments: 
#   $long_FH:       file handle to output long data to
#   $short_FH:      file handle to output short data to
#   $opt_HHR:       reference to 2D hash of cmdline options
#   $width_HR:      hash, key is "model" or "target", value 
#                   is width (maximum length) of any target/model
#   $target:        target name
#   $seqidx_HR:     hash of target sequence indices
#   $seqlen_HR:     hash of target sequence lengths
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_one_hitless_target_wrapper { 
  my $nargs_expected = 7;
  my $sub_name = "output_one_hitless_target_wrapper";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($long_FH, $short_FH, $opt_HHR, $width_HR, $target, $seqidx_HR, $seqlen_HR) = @_;

  # output to short and long output files
  output_one_hitless_target($long_FH,  0, $opt_HHR, $width_HR, $target, $seqidx_HR->{$target}, $seqlen_HR->{$target}); 
  output_one_hitless_target($short_FH, 1, $opt_HHR, $width_HR, $target, $seqidx_HR->{$target}, $seqlen_HR->{$target}); 

  #$seqlen_HR->{$target} = -1; # serves as a flag that we output info for this sequence
  
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
#   $use_evalues:  '1' if we have E-values, '0' if not
#   $width_HR:      hash, key is "model" or "target", value 
#                   is width (maximum length) of any target/model
#   $domain_HR:     reference to domain hash
#   $accept_HR:     reference to the 'accept' hash, key is "model"
#                   value is '1' if hits to model are "PASS"es '0'
#                   if they are "FAIL"s
#   $target:        target name
#   $seqidx:        index of target sequence
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
  my $nargs_expected = 22;
  my $sub_name = "output_one_target";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $do_short, $opt_HHR, $use_evalues, $width_HR, $domain_HR, $accept_HR, $target, $seqidx, $seqlen, 
      $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
      $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR) = @_;

  # debug_print(*STDOUT, "$target:$seqlen:one", $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR);
  # debug_print(*STDOUT, "$target:$seqlen:two", $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR);

  # determine the winning family
  my $wfamily = undef;
  my $better_than_winning = 0;
  foreach my $family (keys %{$one_model_HR}) { 
    # determine if this hit is better than our winning clan
    if(! defined $wfamily) { 
      $better_than_winning = 1; 
    }
    elsif($use_evalues) { 
      if(($one_evalue_HR->{$family} < $one_evalue_HR->{$wfamily}) || # this E-value is better than (less than) our current winning E-value
         ($one_evalue_HR->{$family} eq $one_evalue_HR->{$wfamily} && $one_score_HR->{$family} > $one_score_HR->{$wfamily})) { # this E-value equals current 'one' E-value, but this score is better than current winning score
        $better_than_winning = 1;
      }
    }
    else { # we don't have E-values
      if($one_score_HR->{$family} > $one_score_HR->{$wfamily}) { # score is better than current winning score
        $better_than_winning = 1;
      }
    }
    if($better_than_winning) { 
      $wfamily = $family;
    }
  }
  my $nhits_fail_str = $wfamily; # used only if we FAIL because there's 
                                 # more than one hit to different families for this sequence

  # build up 'extra information' about other hits in other clans, if any
  my $extra_string = "";
  my $nhits = 1;
  foreach my $family (keys %{$one_model_HR}) { 
    if($family ne $wfamily) { 
      if(exists($one_model_HR->{$family})) { 
        if($extra_string ne "") { $extra_string .= ","; }
        if($use_evalues) { 
          $extra_string .= sprintf("%s:%s:%g:%.1f/%d-%d:%s",
                                   $family, $one_model_HR->{$family}, $one_evalue_HR->{$family}, $one_score_HR->{$family}, 
                                   $one_start_HR->{$family}, $one_stop_HR->{$family}, $one_strand_HR->{$family});
        }
        else { # we don't have E-values
          $extra_string .= sprintf("%s:%s:%.1f/%d-%d:%s",
                                   $family, $one_model_HR->{$family}, $one_score_HR->{$family}, 
                                   $one_start_HR->{$family}, $one_stop_HR->{$family}, $one_strand_HR->{$family});
        }
        $nhits++;
        $nhits_fail_str .= "+" . $family;
      }
    }
  }
  my $coverage = (abs($one_stop_HR->{$wfamily} - $one_start_HR->{$wfamily}) + 1) / $seqlen;
  my $one_evalue2print = ($use_evalues) ? sprintf("%8g  ", $one_evalue_HR->{$wfamily}) : "";
  my $two_evalue2print = undef;
  if(defined $two_model_HR->{$wfamily}) { 
    $two_evalue2print = ($use_evalues) ? sprintf("%8g  ", $two_evalue_HR->{$wfamily}) : "";
  }
  
  # if we have a second-best model, determine score difference between best and second-best model
  my $score_diff  = undef;
  my $diff_thresh = undef;
  my $diff_str    = undef;
  if(exists $two_score_HR->{$wfamily}) { 
    $score_diff = ($one_score_HR->{$wfamily} - $two_score_HR->{$wfamily});
    # determine score difference threshold
    if(opt_IsUsed("--absdiff", $opt_HHR)) { 
      # absolute score difference, regardless of length of hit
      $diff_thresh = opt_Get("--absdiff", $opt_HHR); 
      $diff_str    = $diff_thresh . "_total_bits";
    }
    else { 
      # default: per position score difference, dependent on length of hit
      $diff_thresh = opt_Get("--posdiff", $opt_HHR) * abs($one_stop_HR->{$wfamily} - $one_start_HR->{$wfamily}) + 1;
      $diff_str    = $diff_thresh . "_bits_per_posn";
    }
  }

  # does the sequence pass or fail? 
  # FAILs if: 
  # - no hits (THIS WILL NEVER HAPPEN HERE, THEY'RE HANDLED BY output_one_hitless_target())
  # - winning hit is to unacceptable model
  # - on negative strand
  # - score difference between top two models is below $diff_thresh AND top two models are different domains 
  # - number of hits to different families is higher than one (e.g. SSU and LSU hit)
  my $pass_fail = "PASS";
  my $reason_for_failure = "";

  if($accept_HR->{$one_model_HR->{$wfamily}} != 1) { 
    $pass_fail = "FAIL";
    $reason_for_failure .= "unacceptable_model"
  }
  if($one_strand_HR->{$wfamily} eq "-") { 
    $pass_fail = "FAIL";
    if($reason_for_failure ne "") { $reason_for_failure .= ";"; }
    $reason_for_failure .= "opposite_strand"
  }
  if((defined $score_diff)        && 
     ($score_diff < $diff_thresh) && 
     ($domain_HR->{$one_model_HR->{$wfamily}} ne $domain_HR->{$two_model_HR->{$wfamily}})) { 
    $pass_fail = "FAIL";
    if($reason_for_failure ne "") { $reason_for_failure .= ";"; }
    $reason_for_failure .= "score_difference_between_top_two_models_below_threshold($score_diff<$diff_str)";
  }
  if($nhits > 1) { 
    $pass_fail = "FAIL";
    if($reason_for_failure ne "") { $reason_for_failure .= ";"; }
    $reason_for_failure .= "hits_to_more_than_one_family($nhits_fail_str)";
  }
  if($reason_for_failure eq "") { $reason_for_failure = "-"; }

  if($do_short) { 
    printf $FH ("%-*s  %-*s  %-*s  %3s  %s  %s\n", 
                $width_HR->{"index"}, $seqidx,
                $width_HR->{"target"}, $target, 
                $width_HR->{"classification"}, $wfamily . "." . $domain_HR->{$one_model_HR->{$wfamily}}, 
                $one_strand_HR->{$wfamily}, $pass_fail, $reason_for_failure);
  }
  else { 
    printf $FH ("%-*s  %-*s  %4s  %*d  %3d  %-*s  %-*s  %-*s  %6.1f  %s%s  %5.3f  %*d  %*d  ", 
                $width_HR->{"index"}, $seqidx,
                $width_HR->{"target"}, $target, 
                $pass_fail, 
                $width_HR->{"length"}, $seqlen, 
                $nhits, 
                $width_HR->{"family"}, $wfamily, 
                $width_HR->{"domain"}, $domain_HR->{$one_model_HR->{$wfamily}}, 
                $width_HR->{"model"}, $one_model_HR->{$wfamily}, 
                $one_score_HR->{$wfamily}, 
                $one_evalue2print, 
                $one_strand_HR->{$wfamily}, 
                $coverage, 
                $width_HR->{"length"}, $one_start_HR->{$wfamily}, 
                $width_HR->{"length"}, $one_stop_HR->{$wfamily});
    
    if(defined $two_model_HR->{$wfamily}) { 
      printf $FH ("%6.1f  %-*s  %6.1f  %s", 
                  $one_score_HR->{$wfamily} - $two_score_HR->{$wfamily}, 
                  $width_HR->{"model"}, $two_model_HR->{$wfamily}, 
                  $two_score_HR->{$wfamily},
                  $two_evalue2print);
    }
    else { 
      printf $FH ("%6s  %-*s  %6s  %s", 
                  "-" , 
                  $width_HR->{"model"}, "-", 
                  "-", 
                  ($use_evalues) ? "       -  " : "");
    }
    
    if($extra_string eq "") { 
      $extra_string = "-";
    }
    
    print $FH ("$extra_string\n");
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
#   $FH:            file handle to output to
#   $do_short:      TRUE to output in 'short' concise mode, else do long mode
#   $opt_HHR:       reference to 2D hash of cmdline options
#   $width_HR:      hash, key is "model" or "target", value 
#                   is width (maximum length) of any target/model
#   $target:        target name
#   $seqidx:        index of target sequence
#   $seqlen:        length of target sequence
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_one_hitless_target { 
  my $nargs_expected = 7;
  my $sub_name = "output_one_hitless_target";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $do_short, $opt_HHR, $width_HR, $target, $seqidx, $seqlen) = @_;

  my $pass_fail = "FAIL";
  my $reason_for_failure = "no_hits";
  my $nhits = 0;

  my $use_evalues = opt_Get("--evalues", $opt_HHR);

  if($do_short) { 
    printf $FH ("%-*s  %-*s  %-*s  %3s  %s  %s\n", 
                $width_HR->{"index"}, $seqidx,
                $width_HR->{"target"}, $target, 
                $width_HR->{"classification"}, "-",
                "?", $pass_fail, $reason_for_failure);
  }
  else { 
    printf $FH ("%-*s  %-*s  %4s  %*d  %3d  %-*s  %-*s  %-*s  %6s  %s%s  %5s  %*s  %*s  ", 
                $width_HR->{"index"}, $seqidx,
                $width_HR->{"target"}, $target, 
                $pass_fail, 
                $width_HR->{"length"}, $seqlen, 
                $nhits,
                $width_HR->{"family"}, "-",
                $width_HR->{"domain"}, "-", 
                $width_HR->{"model"}, "-", 
                "-", 
                ($use_evalues) ? "       -  " : "",
                "?",
                "-", 
                $width_HR->{"length"}, "-", 
                $width_HR->{"length"}, "-");
    printf $FH ("%6s  %-*s  %6s  %s%s\n", 
                "-" , 
                $width_HR->{"model"}, "-", 
                "-", 
                ($use_evalues) ? "       -  " : "", "-");
    
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
#   $width_HR:  maximum length of any target name
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

  my $index_dash_str  = "#" . get_monocharacter_string($width_HR->{"index"}-1, "-");
  my $target_dash_str = get_monocharacter_string($width_HR->{"target"}, "-");
  my $class_dash_str  = get_monocharacter_string($width_HR->{"classification"}, "-");

  printf $FH ("%-*s  %-*s  %-*s  %3s  %4s  %s\n", 
              $width_HR->{"index"}, "#idx", 
              $width_HR->{"target"}, "target", 
              $width_HR->{"classification"}, "classification", 
              "str", "p/f", "reason-for-failure");
  printf $FH ("%-*s  %-*s  %-*s  %3s  %4s  %s\n", 
              $width_HR->{"index"},          $index_dash_str, 
              $width_HR->{"target"},         $target_dash_str, 
              $width_HR->{"classification"}, $class_dash_str, 
              "---", "----", "------------------");

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
#   $opt_HHR:   ref to 2D options hash
#   $width_HR:  ref to hash, key is "model" or "target", value 
#               is width (maximum length) of any target/model
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output_long_headers { 
  my $nargs_expected = 3;
  my $sub_name = "output_long_headers";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $opt_HHR, $width_HR) = (@_);

  my $index_dash_str   = "#" . get_monocharacter_string($width_HR->{"index"}-1, "-");
  my $target_dash_str  = get_monocharacter_string($width_HR->{"target"}, "-");
  my $model_dash_str   = get_monocharacter_string($width_HR->{"model"},  "-");
  my $family_dash_str  = get_monocharacter_string($width_HR->{"family"}, "-");
  my $domain_dash_str  = get_monocharacter_string($width_HR->{"domain"}, "-");
  my $length_dash_str  = get_monocharacter_string($width_HR->{"length"}, "-");

  my $use_evalues = opt_Get("--evalues", $opt_HHR);

  my $best_model_group_width   = $width_HR->{"model"} + 2 + 6 + 2 + 1 + 2 + 5 + 2 + $width_HR->{"length"} + 2 + $width_HR->{"length"};
  my $second_model_group_width = $width_HR->{"model"} + 2 + 6 ;
  if($use_evalues) { 
    $best_model_group_width   += 2 + 8;
    $second_model_group_width += 2 + 8;
  }

  if(length("best-scoring model")        > $best_model_group_width)   { $best_model_group_width   = length("best-scoring model"); }
  if(length("second-best-scoring model") > $second_model_group_width) { $second_model_group_width = length("second-best-scoring model"); } 

  my $best_model_group_dash_str   = get_monocharacter_string($best_model_group_width, "-");
  my $second_model_group_dash_str = get_monocharacter_string($second_model_group_width, "-");
  
  # line 1
  printf $FH ("%-*s  %-*s  %4s  %*s  %3s  %*s  %*s  %-*s  %6s  %-*s  %s\n", 
              $width_HR->{"index"},  "#",
              $width_HR->{"target"}, "",
              "", 
              $width_HR->{"length"}, "", 
              "", 
              $width_HR->{"family"}, "", 
              $width_HR->{"domain"}, "", 
              $best_model_group_width, center_string($best_model_group_width, "best-scoring model"), 
              "", 
              $second_model_group_width, center_string($second_model_group_width, "second-best-scoring model"), 
              "");
  # line 2
  printf $FH ("%-*s  %-*s  %4s  %*s  %3s  %*s  %*s  %-*s  %6s  %-*s  %s\n", 
              $width_HR->{"index"},  "#",
              $width_HR->{"target"}, "",
              "", 
              $width_HR->{"length"}, "", 
              "", 
              $width_HR->{"family"}, "", 
              $width_HR->{"domain"}, "", 
              $best_model_group_width, $best_model_group_dash_str, 
              "", 
              $second_model_group_width, $second_model_group_dash_str, 
              "");
  # line 3
  printf $FH ("%-*s  %-*s  %4s  %*s  %3s  %*s  %*s  %-*s  %6s  %s%s  %5s  %*s  %*s  %6s  %-*s  %6s  %s%s\n",  
              $width_HR->{"index"},  "#idx", 
              $width_HR->{"target"}, "target",
              "p/f", 
              $width_HR->{"length"}, "length", 
              "#ht", 
              $width_HR->{"family"}, "fam", 
              $width_HR->{"domain"}, "domain", 
              $width_HR->{"model"},  "model", 
              "score", 
              ($use_evalues) ? "  evalue  " : "", 
              "s",
              "cov",
              $width_HR->{"length"}, "start",
              $width_HR->{"length"}, "stop",
              "scdiff",
              $width_HR->{"model"},  "model", 
              "score", 
              ($use_evalues) ? "  evalue  " : "", 
              "extra");

  # line 4
  printf $FH ("%-*s  %-*s  %4s  %*s  %3s  %*s  %*s  %-*s  %6s  %s%s  %5s  %*s  %*s  %6s  %-*s  %6s  %s%s\n", 
              $width_HR->{"index"},  $index_dash_str,
              $width_HR->{"target"}, $target_dash_str, 
              "----", 
              $width_HR->{"length"}, $length_dash_str,
              "---", 
              $width_HR->{"family"}, $family_dash_str,
              $width_HR->{"domain"}, $domain_dash_str, 
              $width_HR->{"model"},  $model_dash_str,
              "------", 
              ($use_evalues) ? "--------  " : "",
              "-",
              "-----",
              $width_HR->{"length"}, $length_dash_str,
              $width_HR->{"length"}, $length_dash_str,
              "------", 
              $width_HR->{"model"},  $model_dash_str, 
              "------", 
              ($use_evalues) ? "--------  " : "",
              "-----");
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
# Subroutine: get_monocharacter_string()
# Incept:     EPN, Thu Mar 10 21:02:35 2016 [dnaorg.pm]
#
# Purpose:    Return a string of length $len of repeated instances
#             of the character $char.
#
# Arguments:
#   $len:   desired length of the string to return
#   $char:  desired character
#
# Returns:  A string of $char repeated $len times.
# 
# Dies:     if $len is not a positive integer
#
#################################################################
sub get_monocharacter_string {
  my $sub_name = "get_monocharacter_string";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($len, $char) = @_;

  if(! verify_integer($len)) { 
    die "ERROR in $sub_name, passed in length ($len) is not a non-negative integer";
  }
  if($len < 0) { 
    die "ERROR in $sub_name, passed in length ($len) is a negative integer";
  }
    
  my $ret_str = "";
  for(my $i = 0; $i < $len; $i++) { 
    $ret_str .= $char;
  }

  return $ret_str;
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

  return get_monocharacter_string($nspaces_to_prepend, " ") . $str; 
}
