#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

require "epn-options.pm";
require "ribo.pm";

# make sure the RIBODIR variable is set
my $env_ribotyper_dir     = ribo_VerifyEnvVariableIsValidDir("RIBODIR");
#my $env_infernal_exec_dir = ribo_VerifyEnvVariableIsValidDir("INFERNALDIR");
#my $env_easel_exec_dir    = ribo_VerifyEnvVariableIsValidDir("EASELDIR");
my $df_model_dir          = $env_ribotyper_dir . "/models/";

# make sure the required executables are executable
my %execs_H = (); # key is name of program, value is path to the executable
$execs_H{"ribotyper"}  = $env_ribotyper_dir     . "/ribotyper.pl";
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
opt_Add("-b",           "integer", 10,                       1,    undef, undef,      "number of positions <n> to look for indels",       "number of positions <n> to look for indels at the 5' and 3' boundaries",  \%opt_HH, \@opt_order_A);
opt_Add("-v",           "boolean", 0,                        1,    undef, undef,      "be verbose",                                       "be verbose; output commands to stdout as they're run", \%opt_HH, \@opt_order_A);
opt_Add("-n",           "integer", 1,                        1,    undef, undef,      "use <n> CPUs",                                     "use <n> CPUs", \%opt_HH, \@opt_order_A);
opt_Add("-i",           "string",  undef,                    1,    undef, undef,      "use model info file <s> instead of default",       "use model info file <s> instead of default", \%opt_HH, \@opt_order_A);
# options related to the ribotyper call
$opt_group_desc_H{"2"} = "options related to the internal call to ribotyper.pl";
opt_Add("--riboopts",   "string",  undef,                    2,    undef, undef,      "read command line options for ribotyper from <s>",     "read command line options to supply to ribotyper from file <s>", \%opt_HH, \@opt_order_A);
opt_Add("--noscfail",   "boolean", 0,                        2,    undef, undef,      "do not fail sequences in ribotyper with low scores",   "do not fail sequences in ribotyper with low scores", \%opt_HH, \@opt_order_A);
opt_Add("--nocovfail",  "boolean", 0,                        2,    undef, undef,      "do not fail sequences in ribotyper with low coverage", "do not fail sequences in ribotyper with low coverage", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: ribolengthchecker.pl [-options] <fasta file to annotate> <output file name root>\n";
$usage      .= "\n";
my $synopsis = "ribolengthchecker.pl :: classify lengths of ribosomal RNA sequences";
my $options_okay = 
    &GetOptions('h'            => \$GetOptions_H{"-h"}, 
                'b=s'          => \$GetOptions_H{"-b"},
                'n=s'          => \$GetOptions_H{"-n"},
                'v'            => \$GetOptions_H{"-v"},
                'i=s'          => \$GetOptions_H{"-i"},
                'riboopts=s'   => \$GetOptions_H{"--riboopts"},
                'noscfail'     => \$GetOptions_H{"--noscfail"},
                'nocovfail'    => \$GetOptions_H{"--nocovfail"});

my $total_seconds     = -1 * ribo_SecondsSinceEpoch(); # by multiplying by -1, we can just add another ribo_SecondsSinceEpoch call at end to get total time
my $executable        = $0;
my $date              = scalar localtime();
my $version           = "0.10";
my $model_version_str = "0p08"; 
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
  print "\nTo see more help on available options, enter ribolengthchcker.pl -h\n\n";
  exit(1);
}
my ($seq_file, $out_root) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

my $cmd         = undef; # a command to be run by ribo_RunCommand()
my @to_remove_A = ();    # array of files to remove at end
my $r1_secs     = undef; # number of seconds required for round 1 search
my $r2_secs     = undef; # number of seconds required for round 2 search
my $ncpu        = opt_Get("-n", \%opt_HH); # number of CPUs to use with search command (default 0: --cpu 0)
my $nbound      = opt_Get("-b", \%opt_HH); # number of positions to check for indels at 5' and 3' boundaries
if($ncpu == 1) { $ncpu = 0; } # prefer --cpu 0 to --cpu 1

my $df_modelinfo_file = $df_model_dir . "ribolengthchecker." . $model_version_str . ".modelinfo";
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
# we check for the existence of model files after we parse the model info file, below

# read command line options for ribotyper from file if --riboopts used
my $extra_ribotyper_options = "";
if(opt_IsUsed("--riboopts", \%opt_HH)) { 
  my $ribotyper_file = opt_Get("--riboopts", \%opt_HH);
  if(! -e $ribotyper_file) { 
    die "ERROR, $ribotyper_file supplied with the --riboopts option does not exist"; 
  }
  if(! -s $ribotyper_file) { 
    die "ERROR, $ribotyper_file supplied with the --riboopts option exists but is empty";
  }
  open(RIBO, $ribotyper_file) || die "ERROR, unable to open file $ribotyper_file for reading ribotyper options";
  $extra_ribotyper_options = <RIBO>;
  chomp $extra_ribotyper_options;
  while(<RIBO>) { 
    if($_ =~ m/\w/) { 
      die "ERROR, expected exactly one line in $ribotyper_file, with command line options for ribotyper, but read more than one line";
    }
  }
  if($extra_ribotyper_options =~ m/\s*\-f/)          { die "ERROR with --riboopts, command-line options for ribotyper cannot include -f, it will be used anyway"; }
  if($extra_ribotyper_options =~ m/\s*\--keep/)      { die "ERROR with --riboopts, command-line options for ribotyper cannot include --keep, it will be used anyway"; }
  if($extra_ribotyper_options =~ m/\s*\-n/)          { die "ERROR with --riboopts, command-line options for ribotyper cannot include -n, use -n option with ribolengthchecker.pl instead"; }
  if($extra_ribotyper_options =~ m/\s*\--scfail/)    { die "ERROR with --riboopts, command-line options for ribotyper cannot include --scfail, it will be used anyway"; }
  if($extra_ribotyper_options =~ m/\s*\--covfail/)   { die "ERROR with --riboopts, command-line options for ribotyper cannot include --covfail, it will be used anyway"; }
  if($extra_ribotyper_options =~ m/\s*\--minusfail/) { die "ERROR with --riboopts, command-line options for ribotyper cannot include --minusfail, it will be used anyway"; }
  close(RIBO);
}

#############################################
# output program banner and open output files
#############################################
# output preamble
my @arg_desc_A = ();
my @arg_A      = ();

push(@arg_desc_A, "target sequence input file");
push(@arg_A, $seq_file);

push(@arg_desc_A, "output file name root");
push(@arg_A, $out_root);

push(@arg_desc_A, "model information input file");
push(@arg_A, $modelinfo_file);

ribo_OutputBanner(*STDOUT, $package_name, $version, $releasedate, $synopsis, $date);
opt_OutputPreamble(*STDOUT, \@arg_desc_A, \@arg_A, \%opt_HH, \@opt_order_A);

###########################################################################
# Step 1: Parse/validate input files
###########################################################################
my $progress_w = 48; # the width of the left hand column in our progress output, hard-coded
my $start_secs = ribo_OutputProgressPrior("Validating input files", $progress_w, undef, *STDOUT);

# parse the modelinfo file, this tells us where the CM files are
my @family_order_A     = (); # family names, in order
my %family_modelname_H = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is CM file for that family
my %family_modellen_H  = (); # key is family name (e.g. "SSU.Archaea") from @family_order_A, value is consensus length for that family
parse_modelinfo_file($modelinfo_file, $df_model_dir, \@family_order_A, \%family_modelname_H, \%family_modellen_H);

# verify the CM files listed in $modelinfo_file exist
my $family;
foreach $family (@family_order_A) { 
  if(! -s $family_modelname_H{$family}) { 
    die "Model file $family_modelname_H{$family} specified in $modelinfo_file does not exist or is empty";
  }
}

# index the fasta file, the index will be used later to fetch with esl-sfetch
my $ssi_file = $seq_file . ".ssi";
# remove it if it already exists
if(-e $ssi_file) { 
  unlink $ssi_file; 
}
ribo_RunCommand("esl-sfetch --index $seq_file > /dev/null", opt_Get("-v", \%opt_HH));
if(! -s $ssi_file) { 
  die "ERROR, tried to create $ssi_file, but failed"; 
} 
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

####################################################
# Step 2: Run ribotyper on the sequence file
####################################################
$start_secs = ribo_OutputProgressPrior("Running ribotyper", $progress_w, undef, *STDOUT);

my $ribotyper_outdir     = $out_root . "-rt";
my $ribotyper_outfile    = $out_root . ".ribotyper.out";
my $ribotyper_short_file = $ribotyper_outdir . "/" . $ribotyper_outdir . ".ribotyper.short.out";
my $ribotyper_long_file = $ribotyper_outdir . "/" . $ribotyper_outdir . ".ribotyper.long.out";
my $found_family_match;  # set to '1' if a sequence matches one of the families we are aligning for
my @fail_str_A    = (); # array of strings of FAIL sequences to output 
my @nomatch_str_A = (); # array of strings of FAIL sequences to output 

# run ribotyper
my $ribotyper_options = " -f --keep --minusfail -n " . opt_Get("-n", \%opt_HH);
if(! opt_IsUsed("--noscfail", \%opt_HH))  { $ribotyper_options .= " --scfail"; }
if(! opt_IsUsed("--nocovfail", \%opt_HH)) { $ribotyper_options .= " --covfail"; }
$ribotyper_options .= " " . $extra_ribotyper_options . " ";
ribo_RunCommand($execs_H{"ribotyper"} . " " . $ribotyper_options . " $seq_file $ribotyper_outdir > $ribotyper_outfile", opt_Get("-v", \%opt_HH));
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

# parse ribotyper output and create sfetch input files for sequences to fetch
my %family_sfetch_filename_H = ();  # key: family name, value: sfetch input file name
my %family_sfetch_FH_H = ();        # key: family name, value: output file handle for sfetch input file
foreach $family (@family_order_A) { 
  $family_sfetch_filename_H{$family} = $out_root . ".ribolengthchecker." . $family . ".sfetch";
  open($family_sfetch_FH_H{$family}, ">", $family_sfetch_filename_H{$family});
}

open(RIBO, $ribotyper_short_file) || die "ERROR unable to open ribotyper short file $ribotyper_short_file for reading";
while(my $line = <RIBO>) { 
  if($line !~ m/^\#/) { 
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 6) { 
      die "ERROR, unable to parse ribotyper short output file, expected 6 tokens on line:\n$line\n"; 
    }
    my ($seqname, $class, $passfail) = ($el_A[1], $el_A[2], $el_A[4]);
    $found_family_match = 0;
    foreach $family (@family_order_A) { 
      if($class eq $family) { 
        $found_family_match = 1;
        if($passfail eq "PASS") { 
          print { $family_sfetch_FH_H{$family} } ($seqname . "\n");
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
}

####################################################
# Step 3: Run cmalign on full sequence file
####################################################
$start_secs = ribo_OutputProgressPrior("Running cmalign and classifying sequence lengths", $progress_w, undef, *STDOUT);
# for each family to align, run cmalign:
my $nfiles = 0;               # number of fasta files that exist for this sequence directory
my $rtkey_seq_file = undef; # a ribotyper key fasta file
my $cat_cmd;                  # a cat command used to pipe the fasta files into cmalign
my $cmalign_stk_file;         # cmalign output alignment
my $cmalign_out_file;         # cmalign output 
my %family_length_class_HHA;  # key 1D is family, key 2D is length class (e.g. 'partial'), value is an array of sequences that 
                              # for this family that belong to this length class
my %out_tbl_HH = ();          # hash of hashes with information for output file
                              # key 1 is sequence name, key 2 is a column name, e.g. pred_cmfrom
my @stkfile_str_A     = (); # list of output alignment files we create
my @cmalignfile_str_A = (); # list of output cmalign files we create
my @listfile_str_A    = (); # list of output list files we create
my $cmalign_opts = " --mxsize 4096. --outformat pfam --cpu $ncpu "; # cmalign options that are consistently used in all cmalign calls

foreach $family (@family_order_A) { 
  if(-s $family_sfetch_filename_H{$family}) { 
    $cmalign_stk_file = $out_root . ".ribolengthchecker." . $family . ".cmalign.stk";
    $cmalign_out_file = $out_root . ".ribolengthchecker." . $family . ".cmalign.out";
    #ribo_RunCommand("$cat_cmd | " . $execs_H{"cmalign"} . " --outformat pfam --cpu $ncpu -o $cmalign_stk_file $family_modelname_H{$family} - > $cmalign_out_file", opt_Get("-v", \%opt_HH));
#AAS: Two issues here and at other cmalign calls: 1) the 4096 should not be hardcoded; 2) it is unclear whether correctness depends on the sequence of cmalign calls having identical or similar arguments, in which case the consistentcy of arguments between calls should be enforced more abstractly   
    ribo_RunCommand("esl-sfetch -f $seq_file $family_sfetch_filename_H{$family} | cmalign $cmalign_opts -o $cmalign_stk_file $family_modelname_H{$family} - > $cmalign_out_file", opt_Get("-v", \%opt_HH));
    push(@stkfile_str_A,     sprintf("# %-18s %6s %-12s sequences saved as $cmalign_stk_file\n", "Alignment of", "all", $family));
    push(@cmalignfile_str_A, sprintf("# %-18s %6s %-12s sequences saved as $cmalign_stk_file\n", "cmalign output for", "all", $family));
    # parse cmalign file
    parse_cmalign_file($cmalign_out_file, \%out_tbl_HH);
    # parse alignment file
    parse_stk_file($cmalign_stk_file, $family_modellen_H{$family}, $nbound, \%out_tbl_HH, \%{$family_length_class_HHA{$family}});
  }
}
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

####################################################
# Step 5: Realigning all seqs in per-class files
####################################################
$start_secs = ribo_OutputProgressPrior("Running cmalign again for each length class", $progress_w, undef, *STDOUT);
my $length_class_list_file = undef; # file name for list file for this length class and family
foreach $family (@family_order_A) { 
  foreach my $length_class ("partial", "full-exact", "full-extra", "full-ambig") { 
    if((exists $family_length_class_HHA{$family}{$length_class}) && 
       (scalar(@{$family_length_class_HHA{$family}{$length_class}}) > 0)) { 
      $length_class_list_file = $out_root . ".ribolengthchecker." . $family . "." . $length_class . ".list";
      $cmalign_stk_file       = $out_root . ".ribolengthchecker." . $family . "." . $length_class . ".stk";
      $cmalign_out_file       = $out_root . ".ribolengthchecker." . $family . "." . $length_class . ".cmalign";
      open(OUT, ">", $length_class_list_file) || die "ERROR, unable to open $length_class_list_file for writing";
      push(@listfile_str_A, sprintf("# %-18s %6d %-12s %10s sequences saved as $length_class_list_file\n", "List of", scalar(@{$family_length_class_HHA{$family}{$length_class}}), $family, $length_class));
      push(@stkfile_str_A, sprintf("# %-18s %6d %-12s %10s sequences saved as $cmalign_stk_file\n", "Alignment of", scalar(@{$family_length_class_HHA{$family}{$length_class}}), $family, $length_class));
      push(@cmalignfile_str_A, sprintf("# %-18s %6d %-12s %10s sequences saved as $cmalign_out_file\n", "cmalign output for", scalar(@{$family_length_class_HHA{$family}{$length_class}}), $family, $length_class));
      foreach my $seqname (@{$family_length_class_HHA{$family}{$length_class}}) { 
        print OUT $seqname . "\n";
      }
      close(OUT);
      #ribo_RunCommand($execs_H{"esl-sfetch"} . " -f $seq_file $length_class_list_file | " . $execs_H{"cmalign"} . " --outformat pfam --cpu $ncpu -o $cmalign_stk_file $family_modelname_H{$family} - > $cmalign_out_file", opt_Get("-v", \%opt_HH));
      ribo_RunCommand("esl-sfetch -f $seq_file $length_class_list_file | cmalign $cmalign_opts -o $cmalign_stk_file $family_modelname_H{$family} - > $cmalign_out_file", opt_Get("-v", \%opt_HH));
    }
  }
}
ribo_OutputProgressComplete($start_secs, undef, undef, *STDOUT);

##############################
# Create output file and exit.
##############################
my $output_file = $out_root . ".ribolengthchecker.tbl.out";
output_tabular_file($output_file, $ribotyper_short_file, $nbound, \%out_tbl_HH);

print("#\n");
my $str;
foreach $str (@listfile_str_A)    { print $str; }
print("#\n");
foreach $str (@stkfile_str_A)     { print $str; }
print("#\n");
foreach $str (@cmalignfile_str_A) { print $str; }

if((scalar(@fail_str_A) == 0) && (scalar(@nomatch_str_A) == 0)) { 
  printf("#\n# All input sequences passed ribotyper and were aligned.\n#\n");
}
else { 
  if(scalar(@fail_str_A) > 0) { 
    printf("#\n# WARNING: %d sequence(s) classified as one of:", scalar(@fail_str_A)); 
    foreach $family (@family_order_A) { 
      print " $family";
    }
    print(", but FAILed ribotyper:\n");
    foreach my $str (@fail_str_A) { 
      print "#  " . $str;
    }
  }
  else { 
    printf("#\n# No sequences failed ribotyper.\n");
  }
  if(scalar(@nomatch_str_A) > 0) {
    printf("#\n# WARNING: %d sequence(s) were not aligned because they were not classified by ribotyper into one of:", scalar(@nomatch_str_A)); 
    foreach $family (@family_order_A) { 
      print " $family";
    }
    print("\n");
    foreach my $str (@nomatch_str_A) { 
      print "#  " . $str;
    }
  }
  else { 
    printf("#\n# All sequences that passed ribotyper were aligned.\n");
  }
  print("#\n# See details in:\n#  $ribotyper_short_file\n#  and\n#  $ribotyper_long_file\n#\n");
}

print("#\n# ribotyper output saved as $ribotyper_outfile\n");
print("# ribotyper output directory saved as $ribotyper_outdir\n");

print("#\n# Tabular output saved to file $output_file\n");
print("#\n#[RIBO-SUCCESS]\n");

#################################################################
# SUBROUTINES
#################################################################
#################################################################
# Subroutine : parse_modelinfo_file()
# Incept:      EPN, Fri Oct 20 14:17:53 2017
#
# Purpose:     Parse the modelinfo file, and fill information in
#              @{$family_order_AR}, %{$family_modelname_HR}.
# 
#              
# Arguments: 
#   $modelinfo_file:       file to parse
#   $env_ribo_dir:    directory in which CM files should be found
#   $family_order_AR:      reference to array of family names, in order read from file, FILLED HERE
#   $family_modelname_HR:  reference to hash, key is family name, value is path to model, FILLED HERE 
#   $family_modellen_HR:   reference to hash, key is family name, value is consensus model length, FILLED HERE
#
# Returns:     void; 
#
################################################################# 
sub parse_modelinfo_file { 
  my $nargs_expected = 5;
  my $sub_name = "parse_modelinfo_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($modelinfo_file, $env_ribo_dir, $family_order_AR, $family_modelname_HR, $family_modellen_HR) = @_;

  open(IN, $modelinfo_file) || die "ERROR unable to open model info file $modelinfo_file for reading";

  while(my $line = <IN>) { 
    ## each line has information on 1 family and has at least 4 tokens: 
    ## token 1: Name for output files for this family
    ## token 2: CM file name for this family
    ## token 3: integer, consensus length for the CM for this family
    ## tokens 4 to N: name of ribotyper files with sequences that should be aligned with this model
    #SSU.Archaea RF01959.cm SSU_rRNA_archaea
    #SSU.Bacteria RF00177.cm SSU_rRNA_bacteria SSU_rRNA_cyanobacteria
    chomp $line; 
    if($line !~ /^\#/ && $line =~ m/\w/) { 
      $line =~ s/^\s+//; # remove leading whitespace
      $line =~ s/\s+$//; # remove trailing whitespace
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 3) { 
        die "ERROR in $sub_name, not exactly 3 tokens found on line $line of $modelinfo_file";  
      }
      my ($family, $modelname, $modellen) = @el_A;
      push(@{$family_order_AR}, $family);
      $family_modelname_HR->{$family} = $env_ribo_dir . "/" . $modelname;
      $family_modellen_HR->{$family}  = $modellen;
    }
  }
  close(IN);
  return;
}

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
# Returns:     void
#
################################################################# 
sub output_tabular_file { 
  my $sub_name = "output_tabular_file()";
  my $nargs_expected = 4;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($out_tbl_file, $ribo_short_file, $nbound, $out_tbl_HHR) = @_; 

  # open the ribotyper short output file for input and output file for output
  open(IN, $ribo_short_file)    || die "ERROR unable to open $ribo_short_file for reading";
  open(OUT, ">", $out_tbl_file) || die "ERROR unable to open $out_tbl_file for writing";

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
          printf OUT ("$prefix  %6s  %6s  %12s  $suffix\n", "mstart", "mstop", "length_class");
        }
        elsif($line_ctr == 2) { 
          printf OUT ("$prefix  %6s  %6s  %12s  $suffix\n", "------", "------", "------------");
        }
        elsif(exists $out_tbl_HHR->{$seqname}) { 
          printf OUT ("$prefix  %6d  %6d  %12s  $suffix\n", $out_tbl_HHR->{$seqname}{"pred_cmfrom"}, $out_tbl_HHR->{$seqname}{"pred_cmto"}, $out_tbl_HHR->{$seqname}{"length_class"}); 
        }
        else { # this sequence must not have been aligned
          printf OUT ("$prefix  %6s  %6s  %12s  $suffix\n", "-", "-", "-");
        }
      }
      else { 
        die "ERROR unable to parse non-comment line of $ribo_short_file:\n$line\n";
      }
    }
    else { # comment line
      if($line =~ m/Column 6 \[unexpected\_features\]/) { 
        # special case, add the descriptions of the 3 columns that we added:
        printf OUT ("%-33s %s\n", "# Column 6 [mstart]:",       "model start position");
        printf OUT ("%-33s %s\n", "# Column 7 [mstop]:",        "model stop position");
        printf OUT ("%-33s %s\n", "# Column 8 [length_class]:", "classification of length, one of:");
        printf OUT ("%-33s %s\n", "#",                          "'full-exact': spans full model and no 5' or 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "              and no indels in first or final $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "'full-extra': spans full model but has 5' and/or 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "'full-ambig': spans full model and no 5' or 3' inserts");
        printf OUT ("%-33s %s\n", "#",                          "              but has indel(s) in first and/or final $nbound model positions");
        printf OUT ("%-33s %s\n", "#",                          "'partial:'    does not span full model");
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
# subroutine : debug_print_hash
# sub class  : general
# 
# EPN 03.08.05
# 
# purpose : Print to standard output the keys and values of a 
#           given hash
#
# args : (1) $hash_ref 
#            reference to hash to print
#        (2) $hash_name
#            name of hash to print
################################################################# 

sub debug_print_hash
{
  my ($hash_ref, $hash_name) = @_;
    
  print("IN DEBUG PRINT HASH\n");
  print("printing hash : $hash_name\n");
  my $i = 1;
  foreach my $header (sort keys (%{$hash_ref}))
  {
    print("$i KEY    : $header\n");
    print("$i VALUE : $hash_ref->{$header}\n");
    $i++;
  }
  print("finished printing hash : $hash_name\n");
  print("LEAVING DEBUG PRINT HASH\n");
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
#
# Returns:     void; 
#
################################################################# 
sub parse_cmalign_file { 
  my $nargs_expected = 2;
  my $sub_name = "parse_cmalign_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmalign_file, $out_tbl_HHR) = @_;

  open(IN, $cmalign_file) || die "ERROR unable to open cmalign file $cmalign_file for reading";

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
      if(scalar(@el_A) != 12) { die "ERROR in $sub_name, unexpected number of tokens on cmalign output file line: $line";  }
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
#
# Returns:     void; 
#
################################################################# 
sub parse_stk_file { 
  my $nargs_expected = 5;
  my $sub_name = "parse_stk_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($stk_file, $modellen, $nbound, $out_tbl_HHR, $lenclass_HAR) = @_;

  # initialize lenclass_HAR for each length class:
  @{$lenclass_HAR->{"partial"}}    = ();
  @{$lenclass_HAR->{"full-exact"}} = ();
  @{$lenclass_HAR->{"full-extra"}} = ();
  @{$lenclass_HAR->{"full-ambig"}} = ();

  # first pass through the file to get the RF line:
  my $line;
  my $rfstr = "";
  open(IN, $stk_file) || die "ERROR unable to open cmalign file $stk_file for reading";
  while($line = <IN>) { 
    if($line =~ m/^#=GC RF\s+(\S+)/) { 
      if($rfstr ne "") { 
        die "ERROR in $sub_name, more than one RF line, alignment is not in Pfam format"; 
      }
      $rfstr = $1;
    }
  }
  close(IN);
  if($rfstr eq "") { 
    die "ERROR in $sub_name, no RF line found, alignment is not in Pfam format"; 
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
  open(IN, $stk_file) || die "ERROR unable to open cmalign file $stk_file for reading";
  while($line = <IN>) { 
    if($line !~ m/^#/ && $line =~ m/\w/) { 
      # a sequence line
      if($line =~ /(\S+)\s+(\S+)/) { 
        my ($seqname, $seqstr) = ($1, $2);
        if(! exists $out_tbl_HHR->{$seqname}) { 
          die "ERROR found sequence in alignment $stk_file without an entry in the output table"; 
        }
        if(($out_tbl_HHR->{$seqname}{"pred_cmfrom"} == 1) &&
           ($out_tbl_HHR->{$seqname}{"pred_cmto"}   == $modellen)) { 
          # spans the full model, classify further as:
          # 'exact': has 0 indels in first and final $nbound RF positions 
          # 'extra': has >=1 inserts before first RF position or after final RF position
          # 'ambig': has 0 inserts before first RF position or after final RF position, but
          #          has >= 1 indel in first or final $nbound RF positions
          my @seqstr_A = split("", $seqstr);
          my $i_before_first_rfpos = 0; # number of insertions before RF position 1
          my $i_early              = 0; # number of insertions between RF position 1 and $nbound
          my $d_early              = 0; # number of deletions  between RF position 1 and $nbound
          my $i_after_final_rfpos  = 0; # number of insertions after RF position $modellen
          my $i_late               = 0; # number of insertions between RF position $modellen-$nbound+1 and $modellen
          my $d_late               = 0; # number of insertions between RF position $modellen-$nbound+1 and $modellen
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
          # count number of deletions and insertions between RF position ($modellen-$nbound+1) and $modellen
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
          # classify
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
            $out_tbl_HHR->{$seqname}{"length_class"} = "full-ambig";
            push(@{$lenclass_HAR->{"full-ambig"}}, $seqname);
          }
        } # end of if(($out_tbl_HHR->{$seqname}{"pred_cmfrom"} == 1) &&
          # ($out_tbl_HHR->{$seqname}{"pred_cmto"}   == $modellen)) { 
        else { 
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
