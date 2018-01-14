use strict;
use warnings;
use Getopt::Long;
use Time::HiRes qw(gettimeofday);

require "epn-options.pm";

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
#     option   type       default group   requires incompat    preamble-output                    help-output    
opt_Add("-h",  "boolean", 0,          1,  undef,   undef,      undef,                             "display this help",              \%opt_HH, \@opt_order_A);
opt_Add("-l",  "boolean", 0,          1,  undef,   undef,      "compare long output, not short",  "compare long output, not short", \%opt_HH, \@opt_order_A);

# This section needs to be kept in sync (manually) with the opt_Add() section above
my %GetOptions_H = ();
my $usage    = "Usage: compare-ribotyper-output.pl [-options] <ribotyper output directory 1> <ribotyper output directory 2>\n";
$usage      .= "\n";
my $synopsis = "compare-ribotyper-output.pl :: compare output from two runs of ribotyper";
my $options_okay = 
    &GetOptions('h' => \$GetOptions_H{"-h"}, 
                'l' => \$GetOptions_H{"-l"});

my $executable    = $0;
my $date          = scalar localtime();
my $version       = "0.14";
my $releasedate   = "Jan 2018";

# print help and exit if necessary
if((! $options_okay) || ($GetOptions_H{"-h"})) { 
  output_banner(*STDOUT, $version, $releasedate, $synopsis, $date);
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
my ($dir1, $dir2) = (@ARGV);

# set options in opt_HH
opt_SetFromUserHash(\%GetOptions_H, \%opt_HH);

# validate options (check for conflicts)
opt_ValidateSet(\%opt_HH, \@opt_order_A);

# determine file names we are going to compare
my $dir_out_tail1   = $dir1;
$dir_out_tail1      =~ s/^.+\///; # remove all but last dir
my $out_root1       = $dir1 . "/" . $dir_out_tail1 . ".ribotyper";
my $short_out_file1 = $out_root1 . ".short.out";
my $long_out_file1  = $out_root1 . ".long.out";

my $dir_out_tail2   = $dir2;
$dir_out_tail2      =~ s/^.+\///; # remove all but last dir
my $out_root2       = $dir2 . "/" . $dir_out_tail2 . ".ribotyper";
my $short_out_file2 = $out_root2 . ".short.out";
my $long_out_file2  = $out_root2 . ".long.out";

my $file1 = $short_out_file1; 
my $file2 = $short_out_file2; 
my $do_long = 0;
if(opt_Get("-l", \%opt_HH)) { 
  $file1 = $long_out_file1; 
  $file2 = $long_out_file2; 
  $do_long = 1;
}

open(IN1, $file1) || die "ERROR unable to open file $file1 for reading";
open(IN2, $file2) || die "ERROR unable to open file $file2 for reading";

# make sure files have the same number of lines, they should
my $line1;
my $line2;
my $n1 = 0;
my $n2 = 0;
while($line1 = <IN1>) { 
  if($line1 =~ m/\w/) { $n1++; }
}
close(IN1);
while($line2 = <IN2>) { 
  if($line2 =~ m/\w/) { $n2++; }
}
close(IN2);

if($n1 != $n2) { die "ERROR different number of lines in $file1 ($n1) and $file2 ($n2)"; }

open(IN1, $file1) || die "ERROR unable to open file $file1 for second reading";
open(IN2, $file2) || die "ERROR unable to open file $file2 for second reading";

# line by line comparison
my $ndiff = 0;
while(my $line1 = <IN1>) { 
  $line2 = <IN2>;
  chomp $line1;
  chomp $line2;
  if($line1 =~ m/^\#/) { 
    if($line2 !~ m/^\#/) { die "ERROR line1 starts with # but line2 does not:\nline1:$line1\nline2:$line2\n"; }
  }
  else { 
    if($do_long) { 
      #1     lcl|dna_BP331_0.3k:467    PASS    1232    1  SSU  Bacteria  SSU_rRNA_bacteria               978.3  +  1.000       1    1232    97.1  SSU_rRNA_chloroplast            881.2  -
      #1     lcl|dna_BP331_0.3k:467    PASS    1232    1  SSU  Bacteria  SSU_rRNA_bacteria               974.2  +  0.997       1    1228    97.6  SSU_rRNA_chloroplast            876.6  -
      #0     1                         2       3       4  5    6         7                               8      9  10          11   12      13    14                              15     16
      my @elA1 = split(/\s+/, $line1);
      my @elA2 = split(/\s+/, $line2);
      if(scalar(@elA1) != 17) { die "ERROR didn't read 17 tokens in $file1 line:\n$line1\n"; }
      if(scalar(@elA2) != 17) { die "ERROR didn't read 17 tokens in $file1 line:\n$line1\n"; }
      
      $line1  = $elA1[0] . " " . $elA1[1] . " " . $elA1[2] . " " . $elA1[3] . " " . $elA1[4] . " " . $elA1[5] . " " . $elA1[6] . " ";
      $line1 .= $elA1[7] . " " . $elA1[9] . " " . $elA1[14];
      
      $line2  = $elA2[0] . " " . $elA2[1] . " " . $elA2[2] . " " . $elA2[3] . " " . $elA2[4] . " " . $elA2[5] . " " . $elA2[6] . " ";
      $line2 .= $elA2[7] . " " . $elA2[9] . " " . $elA2[14];
    }
    
    if($line1 ne $line2) { 
      $ndiff++;
      printf("\n$line1\n$line2\n");
    }
  }
}
printf("$ndiff/$n1 lines differ\n");
