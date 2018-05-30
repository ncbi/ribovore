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
my $env_vecplus_dir       = ribo_VerifyEnvVariableIsValidDir("VECPLUSDIR");
#my $env_infernal_exec_dir = ribo_VerifyEnvVariableIsValidDir("INFERNALDIR");
#my $env_easel_exec_dir    = ribo_VerifyEnvVariableIsValidDir("EASELDIR");
my $df_model_dir          = $env_ribotyper_dir . "/models/";

# make sure the required executables are executable
my %execs_H = (); # key is name of program, value is path to the executable
$execs_H{"ribotyper"}            = $env_ribotyper_dir  . "/ribotyper.pl";
$execs_H{"ribolengthchecker"}    = $env_ribotyper_dir  . "/ribolengthchecker.pl";
$execs_H{"parse_vecscreen.pl"}   = $env_vecplus_dir    . "/scripts/parse_vecscreen.pl";
$execs_H{"combine_summaries.pl"} = $env_vecplus_dir    . "/scripts/combine_summaries.pl";
$execs_H{"vecscreen"}            = $env_vecplus_dir    . "/scripts/vecscreen";
$execs_H{"srcchk"}               = $env_vecplus_dir    . "/scripts/srcchk";
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
opt_Add("--fetch",      "string",  undef,                    1,    undef, "--fasta",  "fetch sequences using seqfetch query in <s>",      "fetch sequences using seqfetch query in <s>",                                  \%opt_HH, \@opt_order_A);
opt_Add("--fasta",      "string",  undef,                    1,    undef, "--fetch",  "sequences provided as fasta input in <s>",         "don't fetch sequences, <s> is fasta file of input sequences",                  \%opt_HH, \@opt_order_A);
opt_Add("--maxnambig",  "integer", 0,                        1,    undef, undef,      "set maximum number of allowed ambiguous nts to <n>",  "set maximum number of allowed ambiguous nts to <n>",                        \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"2"} = "options related to the internal call to ribotyper.pl";
# THESE OPTIONS SHOULD BE MANUALLY KEPT IN SYNC WITH THE CORRESPONDING OPTION GROUP IN ribolengthchecker.pl
opt_Add("-i",           "string",  undef,                    2,    undef, undef,      "use rlc model info file <s> instead of default",   "use ribolengthchecker.pl model info file <s> instead of default", \%opt_HH, \@opt_order_A);
opt_Add("--riboopts",   "string",  undef,                    2,    undef, undef,      "read command line options for ribotyper from <s>",     "read command line options to supply to ribotyper from file <s>", \%opt_HH, \@opt_order_A);
opt_Add("--noscfail",   "boolean", 0,                        2,    undef, undef,      "do not fail sequences in ribotyper with low scores",   "do not fail sequences in ribotyper with low scores", \%opt_HH, \@opt_order_A);
opt_Add("--nocovfail",  "boolean", 0,                        2,    undef, undef,      "do not fail sequences in ribotyper with low coverage", "do not fail sequences in ribotyper with low coverage", \%opt_HH, \@opt_order_A);

$opt_group_desc_H{"3"} = "options related to model boundaries at model span step:";
opt_Add("--pos",         "integer",  undef,                  3,    undef, undef,      "aligned sequences must span from <n> to L - <n> + 1",   "aligned sequences must span from <n> to L - <n> + 1 for model of length L", \%opt_HH, \@opt_order_A);
opt_Add("--lpos",        "integer",  undef,                  3,  "--rpos","--pos",    "aligned sequences must extend from position <n>",       "aligned sequences must extend from position <n> for model of length L", \%opt_HH, \@opt_order_A);
opt_Add("--rpos",        "integer",  undef,                  3,  "--lpos","--pos",    "aligned sequences must extend to position L - <n> + 1", "aligned sequences must extend to <n> to L - <n> + 1 for model of length L", \%opt_HH, \@opt_order_A);


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
                'fasta=s'      => \$GetOptions_H{"--fasta"},
                'maxnambig=s'  => \$GetOptions_H{"--maxnambig"},
                'riboopts=s'   => \$GetOptions_H{"--riboopts"},
                'noscfail'     => \$GetOptions_H{"--noscfail"},
                'nocovfail'    => \$GetOptions_H{"--nocovfail"},
                'pos=s'        => \$GetOptions_H{"--pos"},
                'lpos=s'       => \$GetOptions_H{"--lpos"},
                'rpos=s'       => \$GetOptions_H{"--rpos"});

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
# either --pos or both of --lpos and --rpos are required
my $in_pos  = undef;
my $in_lpos = undef;
my $in_rpos = undef;
if(opt_IsUsed("--pos",  \%opt_HH)) { $in_pos  = opt_Get("--pos", \%opt_HH); }
if(opt_IsUsed("--lpos", \%opt_HH)) { $in_lpos = opt_Get("--lpos", \%opt_HH); }
if(opt_IsUsed("--rpos", \%opt_HH)) { $in_rpos = opt_Get("--rpos", \%opt_HH); }
if((! defined $in_pos) && (! defined $in_lpos) && (! defined $in_rpos)) { 
  die "ERROR, either --pos, or both --lpos and --rpos are required.";
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
my $out_root = $dir . "/" . $dir_tail . ".ribodbcreate";

my $in_riboopts_file = undef;
if(! opt_IsUsed("--riboopts", \%opt_HH)) {
  die "ERROR, --riboopts is a required option";
}
$in_riboopts_file = opt_Get("--riboopts", \%opt_HH);
# make sure the riboinfo file exists
ribo_CheckIfFileExistsAndIsNonEmpty($in_riboopts_file, "riboopts file specified with --riboopts", undef, 1); # last argument as 1 says: die if it doesn't exist or is empty

my $df_rlc_modelinfo_file = $df_model_dir . "ribolengthchecker." . $model_version_str . ".modelinfo";
my $rlc_modelinfo_file = undef;
if(! opt_IsUsed("-i", \%opt_HH)) {
  $rlc_modelinfo_file = $df_rlc_modelinfo_file;
}
else { 
  $rlc_modelinfo_file = opt_Get("-i", \%opt_HH);
}
# make sure the ribolengthchecker modelinfo files exists
if(! opt_IsUsed("-i", \%opt_HH)) {
  ribo_CheckIfFileExistsAndIsNonEmpty($rlc_modelinfo_file, "default ribolengthchecker model info file", undef, 1); # 1 says: die if it doesn't exist or is empty
}
else { # -i used on the command line
  ribo_CheckIfFileExistsAndIsNonEmpty($rlc_modelinfo_file, "ribolengthchecker model info file specified with -i", undef, 1); # 1 says: die if it doesn't exist or is empty
}

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

###########################################################################
# Step 0: Parse/validate input files
###########################################################################
my $progress_w = 60; # the width of the left hand column in our progress output, hard-coded
my $start_secs;
$start_secs = ofile_OutputProgressPrior("Validating input files", $progress_w, $log_FH, *STDOUT);

# parse the modelinfo file, this tells us where the CM files are
my @family_order_A     = (); # family names, in order
my %family_modelname_H = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is CM file for that family
my %family_modellen_H  = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is consensus length for that family
ribo_ParseRLCModelinfoFile($rlc_modelinfo_file, $df_model_dir, \@family_order_A, \%family_modelname_H, \%family_modellen_H);

# verify the CM files listed in $rlc_modelinfo_file exist
my $family;
foreach $family (@family_order_A) { 
  if(! -s $family_modelname_H{$family}) { 
    die "Model file $family_modelname_H{$family} specified in $rlc_modelinfo_file does not exist or is empty";
  }
}
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

##############################################################################
# Step 1. Fetch the sequences (if --fetch) or copy the fasta file (if --fasta)
##############################################################################
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
my %seqfailstr_H = (); # hash that keeps track of failure strings for each sequence, will be "" for a passing sequence
$start_secs = ofile_OutputProgressPrior("Determining target sequence lengths", $progress_w, $log_FH, *STDOUT);
ribo_ProcessSequenceFile("esl-seqstat", $full_fasta_file, $seqstat_file, \%seqidx_H, \%seqlen_H, undef, \%opt_HH);
ribo_CountAmbiguousNucleotidesInSequenceFile("esl-seqstat", $full_fasta_file, $comptbl_file, \%seqnambig_H, \%opt_HH);
my $nseq = scalar(keys %seqidx_H);
my $full_list_file = $out_root . ".full.list";
new_ribo_RunCommand("grep ^\= $seqstat_file | awk '{ print \$2 }' > $full_list_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "fulllist", "$full_list_file", 1, "File with list of all $nseq input sequences");

ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

# initialize %seqfailstr_H
foreach my $seqname (%seqlen_H) { 
  $seqfailstr_H{$seqname} = "";
}
my $maxnambig = opt_Get("--maxnambig", \%opt_HH);
my $seqname;
foreach $seqname (keys %seqnambig_H) { 
  if($seqnambig_H{$seqname} > $maxnambig) { 
    $seqfailstr_H{$seqname} .= "ambig[" . $seqnambig_H{$seqname} . "];"; 
  }
}

##############################################################################
# Step 2. Run srcchk and filter for formal names and uncultured
##############################################################################
$start_secs = ofile_OutputProgressPrior("Running srcchk for all sequences ", $progress_w, $log_FH, *STDOUT);
my $full_srcchk_file = $out_root . ".full.srcchk";
new_ribo_RunCommand($execs_H{"srcchk"} . " -i $full_list_file -f \'taxid,organism\' > $full_srcchk_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "fullsrcchk", "$full_srcchk_file", 1, "srcchk output for all $nseq input sequences");
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

$start_secs = ofile_OutputProgressPrior("Filtering for formal names ", $progress_w, $log_FH, *STDOUT);
# creating a new file 
#my $formal_list_file = $out_root . ".formal.list";
#new_ribo_RunCommand("tail -n +2 $full_srcchk_file | grep -v -P \" sp\.|cf\.|aff\. \" | cut -f 1 > $formal_list_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
#ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "formallist", "$formal_list_file", 1, "list of sequences with formal names");

parse_srcchk_file_for_names($full_srcchk_file, "formalname", "uncultured", \%seqfailstr_H, \%opt_HH, $ofile_info_HH{"FH"});
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

##############################################################################
## Step 3. Filter seqs with too many ambiguities
##############################################################################
#$start_secs = ofile_OutputProgressPrior(sprintf("Filtering sequences with < %d ambiguous nucleotides ", opt_Get("--maxnambig", \%opt_HH) + 1), $progress_w, $log_FH, *STDOUT);
#my $noambig_list_file = $out_root . ".noambig.list";
#filter_list_file($formal_list_file, $noambig_list_file, opt_Get("--maxnambig", \%opt_HH), \%seqnambig_H, $ofile_info_HH{"FH"});
#ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "noambiglist", "$noambig_list_file", 1, sprintf("list of sequences with < %d ambiguous nucleotides", opt_Get("--maxnambig", \%opt_HH)));
#ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

##############################################################################
# Step 4. Remove seqs with non-weak VecScreen matches 
##############################################################################
$start_secs = ofile_OutputProgressPrior("Identifying vector sequences with VecScreen ", $progress_w, $log_FH, *STDOUT);
my $vecscreen_output_file = $out_root . ".vecscreen";
my $vecscreen_cmd  = $execs_H{"vecscreen"} . " -text_output -query $full_fasta_file > $vecscreen_output_file";
new_ribo_RunCommand($vecscreen_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "vecout", "$vecscreen_output_file", 1, "vecscreen output file");
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

# parse vecscreen 
$start_secs = ofile_OutputProgressPrior("Parsing VecScreen output ", $progress_w, $log_FH, *STDOUT);
my $parse_vecscreen_terminal_file = $out_root . ".terminal.parse_vecscreen";
my $parse_vecscreen_internal_file = $out_root . ".internal.parse_vecscreen";
my $parse_vecscreen_combined_file = $out_root . ".combined.parse_vecscreen";
my $parse_vecscreen_cmd   = $execs_H{"parse_vecscreen.pl"} . " --verbose --input $vecscreen_output_file --outfile_terminal $parse_vecscreen_terminal_file --outfile_internal $parse_vecscreen_internal_file";
my $combine_summaries_cmd = $execs_H{"combine_summaries.pl"} . " --input_internal $parse_vecscreen_internal_file --input_terminal $parse_vecscreen_terminal_file --outfile $parse_vecscreen_combined_file";
new_ribo_RunCommand($parse_vecscreen_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
new_ribo_RunCommand($combine_summaries_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "parsevec", "$parse_vecscreen_combined_file", 1, "combined parse_vecscreen.pl output file");

# get list of accessions in combined parse_vecscreen output that have non-Weak matches
my $vecscreen_fails_list_file = $out_root . ".vecscreen-fails.list";
my $get_vecscreen_fails_list_cmd = "cat $parse_vecscreen_combined_file | awk -F \'\\t\' '{ printf(\"%s %s\\n\", \$1, \$7); }' | grep -i -v weak | awk '{ printf(\"%s\\n\", \$1); }' | sort | uniq > $vecscreen_fails_list_file";
new_ribo_RunCommand($get_vecscreen_fails_list_cmd, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "vecfails", "$vecscreen_fails_list_file", 1, "list of sequences that had non-Weak VecScreen matches");
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

##############################################################################
# Step 5. Run ribolengthchecker.pl 
##############################################################################
# copy the riboopts file to the output directory
$start_secs = ofile_OutputProgressPrior("Analyzing sequences with ribolengthchecker ", $progress_w, $log_FH, *STDOUT);
my $riboopts_file = $out_root . ".riboopts";
new_ribo_RunCommand("cp $in_riboopts_file $riboopts_file", $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});

my $rlc_options = "";
if(opt_IsUsed("-i",          \%opt_HH)) { $rlc_options .= " -i " . opt_Get("-i", \%opt_HH);  }
if(opt_IsUsed("--noscfail",  \%opt_HH)) { $rlc_options .= " --noscfail "; }
if(opt_IsUsed("--nocovfail", \%opt_HH)) { $rlc_options .= " --nocovfail "; }
my $rlc_out_file       = $out_root . ".ribolengthchecker";
my $rlc_tbl_out_file   = $out_root . ".ribolengthchecker.tbl.out";
my $local_fasta_file   = ribo_RemoveDirPath($full_fasta_file);
my $rlc_command = $execs_H{"ribolengthchecker"} . " --riboopts $riboopts_file $rlc_options $full_fasta_file $out_root > $rlc_out_file";
new_ribo_RunCommand($rlc_command, $pkgstr, opt_Get("-v", \%opt_HH), $ofile_info_HH{"FH"});
ofile_AddClosedFileToOutputInfo(\%ofile_info_HH, $pkgstr, "rlcout", "$rlc_out_file", 1, "output of ribolengthchecker");
ofile_OutputProgressComplete($start_secs, undef, $log_FH, *STDOUT);

# parse ribolengthchecker tbl file
parse_ribolengthchecker_tbl_file($rlc_tbl_out_file, \%family_modellen_H, "ribotyper", "ribolengthchecker", "alnbounds", \%seqfailstr_H, \%opt_HH, $ofile_info_HH{"FH"});

# output tabular output file
my $out_tbl = $out_root . ".tbl";
my $pass_fail = undef;
my $seqfailstr = undef;
foreach $seqname (sort keys (%seqidx_H)) { 
  if($seqfailstr_H{$seqname} eq "") { 
    $pass_fail = "PASS";
    $seqfailstr = "-";
  }
  else { 
    $pass_fail = "FAIL";
    $seqfailstr = $seqfailstr_H{$seqname};
  }
  printf("%-5d  %-30s  %4s  %s\n", $seqidx_H{$seqname}, $seqname, $pass_fail, $seqfailstr);
}

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

  open(IN,       $in_file)  || ofile_FileOpenFailure($in_file,  "RIBO", "ribodbcreate.pl:main()", $!, "reading", $FH_HR);
  open(OUT, ">", $out_file) || ofile_FileOpenFailure($out_file, "RIBO", "ribodbcreate.pl:main()", $!, "writing", $FH_HR);

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
# Subroutine:  parse_srcchk_file_for_names()
# Incept:      EPN, Wed May 30 15:44:03 2018
#
# Purpose:     Parse a tab delimited srcchk output file
#              and keep track of those sequences that 
#              do not have a formal name or have uncultured
#              in their name, saving that information to 
#              %{$failstr_HR}.
#
# Arguments:
#   $in_file:      name of input srcchk file to parse
#   $fml_failstr:  string to add to $failstr_H{$seqname} for seqs that failed ribotyper
#   $unc_failstr:  string to add to $failstr_H{$seqname} for seqs that failed ribolengthchecker
#   $failstr_HR:   ref to hash of failure string to add to here
#   $opt_HHR:      reference to 2D hash of cmdline options
#   $FH_HR:        REF to hash of file handles, including "cmd"
#
# Returns:    void
#
# Dies:       if a sequence name read in $in_file does not exist in %{$value_HR}
#################################################################
sub parse_srcchk_file_for_names { 
  my $sub_name = "parse_srcchk_file_for_names()";
  my $nargs_expected = 6;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_file, $fml_failstr, $unc_failstr, $failstr_HR, $opt_HHR, $FH_HR) = (@_);

  # parse each line of the output file
  open(IN, $in_file)  || ofile_FileOpenFailure($in_file,  "RIBO", $sub_name, $!, "reading", $FH_HR);
  my $nlines = 0;

  # first line is header
  my $line = <IN>;
  while($line = <IN>) { 
    #accession	taxid	organism	
    #KJ925573.1	100272	uncultured eukaryote	
    #FJ552229.1	221169	uncultured Gemmatimonas sp.	
    chomp $line;
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 3) { 
      ofile_FAIL("ERROR in $sub_name, srcchk file line did not have exactly 3 tab-delimited tokens: $line\n", "RIBO", $?, $FH_HR);
    }
    my ($accver, $taxid, $organism) = @el_A;
    if(! exists $failstr_HR->{$accver}) { 
      ofile_FAIL("ERROR in $sub_name, srcchk file line has unexpected sequence $accver", "RIBO", $?, $FH_HR);
    }
    my $extra_str = "";
    if($organism =~ m/ sp\./)  { $extra_str .= "sp.;" };
    if($organism =~ m/ cf\./)  { $extra_str .= "cf.;" };
    if($organism =~ m/ aff\./) { $extra_str .= "aff.;" };
    if($extra_str ne "") { 
      $failstr_HR->{$accver} .= $fml_failstr . "[" . $extra_str . "]";
    }

    $extra_str = "";
    foreach my $badword ("uncultured", "parasite", "symbiont", "unident", "environment", "undetermined", "marine", "nclassified", "dinoflagellate") { 
      if($organism =~ m/$badword/)  { $extra_str .= $badword . ";" };
    }
    if($extra_str ne "") { 
      $failstr_HR->{$accver} .= $unc_failstr . "[" . $extra_str . "]";
    }
  }
  close(IN);

  return;
}

#################################################################
# Subroutine:  parse_ribolengthchecker_tbl_file()
# Incept:      EPN, Wed May 30 14:11:47 2018
#
# Purpose:     Parse a tbl output file from ribolengthchecker.pl
#
# Arguments:
#   $in_file:      name of input tbl file to parse
#   $mlen_HR:      ref to hash of model lengths, key is value in classification
#                  column of $in_file
#   $rt_failstr:   string to add to $failstr_H{$seqname} for seqs that failed ribotyper
#   $rlc_failstr:  string to add to $failstr_H{$seqname} for seqs that failed ribolengthchecker
#                  (classified as 'full-extra' or 'full-ambig')
#   $bnd_failstr:  string to add to $failstr_H{$seqname} for seqs that failed boundary test
#                  (do not span required region)
#   $failstr_HR:   ref to hash of failure string to add to here
#   $opt_HHR:      reference to 2D hash of cmdline options
#   $FH_HR:        REF to hash of file handles, including "cmd"
#
# Returns:    void
#
# Dies:       if options are unexpected
#             if unable to parse a tabular line
#             in there's no model length for an observed classification
# 
#################################################################
sub parse_ribolengthchecker_tbl_file { 
  my $sub_name = "parse_ribolengthchecker_tbl_file()";
  my $nargs_expected = 8;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_file, $mlen_HR, $rt_failstr, $rlc_failstr, $bnd_failstr, $failstr_HR, $opt_HHR, $FH_HR) = (@_);

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
        $failstr_HR->{$target} .= $rt_failstr . "[" . $ufeatures . "]";
      }
      if(($lclass eq "full-extra") || ($lclass eq "full-ambig")) { 
        $failstr_HR->{$target} .= $rlc_failstr . "[" . $lclass . "]";
      }
      if($passfail eq "PASS") { 
        if((! exists $max_lpos_H{$class}) || (! exists $min_rpos_H{$class})) { 
          ofile_FAIL("ERROR in $sub_name, unexpected classification $class", "RIBO", $?, $FH_HR);
        }
        if(($mstart > $max_lpos_H{$class}) || ($mstop < $min_rpos_H{$class})) { 
          $failstr_HR->{$target} .= $bnd_failstr . "[" . $mstart . "-" . $mstop . "]";
        }
      }
    }
  }
  close(IN);

  return;
}
