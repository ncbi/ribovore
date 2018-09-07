#!/usr/bin/env perl
# EPN, Fri May 25 12:55:03 2018
# mdlspan-survtbl-sort.pl
# Sort a mdlspan table to prioritize listed orders, classes or phyla
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl mdlspan-survtbl-sort.pl <mdlspan.survtbl file> <list of orders to prioritize>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-s: 2nd arg is not a list file but a comma-separated list of 1 or more taxids\n";
$usage .= "\t\t-c: 2nd arg <list file> is list of classes not orders\n";
$usage .= "\t\t-p: 2nd arg <list file> is list of phyla not orders\n";

my $do_list   = 0; # '1' if list file is not a file but a comma separated list of taxids
my $do_class  = 0; # '1' if list file is classes
my $do_phylum = 0; # '1' if list file is phyla
&GetOptions( "l" => \$do_list,
             "c" => \$do_class,
             "p" => \$do_phylum);

if(scalar(@ARGV) != 2) { die $usage; }

my ($tbl_file, $list_file) = (@ARGV);

if($do_class && $do_phylum) { die "ERROR pick one of --class or --phylum"; }

# parse list file
my $taxid;
my %in_H = (); # key is taxid read from input file or (if -l) 2nd cmdline arg

if($do_list) { 
  my $list_str = $list_file;
  my @list_A = split(",", $list_str);
  foreach $taxid (@list_A) { 
    if($taxid !~ m/^\d+$/) { 
      die "ERROR, with -l, 2nd cmdline argument should be comma-separated list of taxids, got $taxid after splitting by commas";
    }
    $in_H{$taxid} = 1;
  }
}
else { # -l not selected, read file
  my $line_ctr = 0;
  open(LIST, $list_file) || die "ERROR unable to open $list_file for reading";
  while(my $line = <LIST>) { 
    if($line !~ m/^\#/ && $line =~ m/\w/) { 
      chomp $line;
      if($line =~ m/^\d+$/) { 
        if(exists $in_H{$line}) { 
          die "ERROR, read $line twice in input file $list_file";
        }
        $in_H{$line} = 1;
        $line_ctr++;
      }
      else { 
        die "ERROR, in list file $list_file, expected one taxid per line, read $line";
      }
    }
  }
  close(LIST);
  if($line_ctr == 0) { die "ERROR, didn't read any taxid lines in $list_file"; }
}

my @sorted_in_keys = sort {$a <=> $b} keys (%in_H);

# parse tbl_file
my $nout = 0; 
my @out_AH = (); # [0..$nout-1], each element is hash, key is "output", "nin", "length", "lpos"
                 # hash is used to sort output lines by norder, then length, then lpos
open(TBL, $tbl_file) || die "ERROR unable to open $tbl_file for reading";
while(my $line = <TBL>) { 
  chomp $line;
  if($line !~ m/^\#/) { 
    #length	5'pos	3'pos	num-surviving-seqs	num-seqs-not-surviving	num-seqs-within-range	num-seqs-not-considered(failed)	num-surviving-species	num-surviving-orders	num-surviving-classes	num-surviving-phyla	surviving-orders	surviving-classes	surviving-phyla
    #101	451	551	8558	72	0	538	6486	151	44	8	1,4810,4827,4857,4861,4869,4892,5008,5014,5042,5114,5120,5125,5135,5139,5151,5178,5185,5197,5226,5234,5244,5258,5267,5303,5338,5404,5592,28997,29006,33183,34346,34395,34478,36064,36750,37989,38074,39677,45676,47166,48846,55070,56487,62910,62912,62913,62914,62916,62921,66275,68804,68889,78899,79272,88639,90883,90886,92860,93808,100121,105989,107465,134362,135652,139380,146291,148099,152641,152647,157608,162474,162475,189479,191554,204043,214503,214509,231212,231213,252166,261460,291611,292491,292576,297313,388450,432006,432026,432027,451442,451869,452227,452228,452281,452334,452336,452337,452338,452339,452342,452343,545373,603422,639021,642598,642607,642610,654833,716585,721927,721947,742846,1028384,1051672,1055547,1111111,1127803,1134056,1264872,1298590,1339693,1385564,1429051,1484953,1500419,1518855,1538066,1572707,1588757,1618100,1619909,1665694,1775898,1804766,1809179,1809182,1809228,1809229,1809278,1809280,1851469,1895403,1913639,1961800,1963390,1985647,2081776,2126967,2219773,2231465	1,4891,5257,62907,147539,147541,147545,147547,147548,147549,147550,147554,147555,155616,155619,162480,162481,162484,189478,214506,315355,432005,432025,451435,451454,451455,452283,452332,663566,1055546,1217819,1399768,1399770,1538065,1538075,1708517,1798830,2202803,2212702,2212703,2212704,2212732,2219690,2233521	4761,4890,5204,451459,1031332,1696033,1913637,1913638

    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 14) { 
      die sprintf("ERROR, unable to parse line in mdlspan.survtbl, expected 14 tab-delimited tokens, but read %d on line\n$line\n", scalar(@el_A));
    }
    
    # initialize %cur_H which keeps track of which taxids in the input list we have in this line
    my %cur_H = ();
    my $ncur_missing  = scalar(@sorted_in_keys);
    my $ncur_included = 0;
    foreach $taxid (@sorted_in_keys) { 
      $cur_H{$taxid} = 0; 
    }

    # parse the relevant list of taxids
    my $list_str;
    if   ($do_class)  { $list_str = $el_A[11]; }
    elsif($do_phylum) { $list_str = $el_A[12]; }
    else              { $list_str = $el_A[10]; } # class

    my @taxid_A = split(",", $list_str); 
    foreach $taxid (@taxid_A) { 
      if(exists $in_H{$taxid}) { 
        $cur_H{$taxid} = 1;
        $ncur_missing--;
        $ncur_included++;
      }
    }
    
    # create strings of included and missing taxids from input list
    my $cur_included_str = "";
    my $cur_missing_str  = "";
    foreach $taxid (@sorted_in_keys) { 
      if($cur_H{$taxid}) { 
        if($cur_included_str ne "") { $cur_included_str .= ","; }
        $cur_included_str .= $taxid; 
      }
      else { 
        if($cur_missing_str ne "") { $cur_missing_str .= ","; }
        $cur_missing_str .= $taxid; 
      }
    }
    if($cur_missing_str  eq "") { $cur_missing_str  = "-"; }
    if($cur_included_str eq "") { $cur_included_str = "-"; }

    # store in @out_AH
    $out_AH[$nout]{"output"} = sprintf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
                                        $ncur_included, $ncur_missing, 
                                        $el_A[0], $el_A[1], $el_A[2], 
                                        $cur_missing_str, $cur_included_str, 
                                        $el_A[3], $el_A[4], $el_A[5], $el_A[6], $el_A[7], $el_A[8], $el_A[9], 
                                        $el_A[10], $el_A[11], $el_A[12], $el_A[13]);

    $out_AH[$nout]{"nin"}    = $ncur_included;
    $out_AH[$nout]{"length"} = $el_A[0];
    $out_AH[$nout]{"lpos"}   = $el_A[1];
    $nout++;
  }
} 

# sort output and print it
my $key;
if   ($do_class)  { $key = "classes"; }
elsif($do_phylum) { $key = "phyla"; }
else              { $key = "orders"; }

print ("# This file was created using mdlspan-survtbl-sort.pl\n");
print ("# input file: $tbl_file\n");
print ("# 2nd arg:    $list_file\n");
if($do_list || $do_class || $do_phylum) { 
  print ("# The following options were used:\n");
  if($do_list)   { print ("# -l\n"); }
  if($do_class)  { print ("# -c\n"); }
  if($do_phylum) { print ("# -p\n"); }
}
else { 
  print ("# No command line options were used.\n");
}
print ("#\n");
print ("# The lines are sorted by the following columns: 'num-listed-surviving-$key', 'length', and '5'pos'.\n");
print ("# See comments in $tbl_file for more possibly relevant information.\n");
print ("#\n");
print ("# Explanation of columns:\n");
print ("#  1. 'num-listed-surviving-$key': number of listed $key that survive for this model span\n");
print ("#  2. 'num-listed-missing-$key':   number of listed $key that do not survive for this model span\n");
print ("#  3. 'length': length of model span\n");
print ("#  4. '5' pos': maximum allowed 5' start position <max_lpos>\n");
print ("#  5. '3' pos': minimum allowed 3' end   position <min_rpos>\n");
print ("#  6. 'listed-surviving-$key': comma-separated list of $key taxids with >= 1 sequence that survives this span\n");
print ("#  7. 'listed-missing-$key':   comma-separated list of $key taxids with 0 sequences that survive this span\n");
print ("#  8. num-surviving-seqs:      number of sequences that span <max_lpos..min_rpos>\n");
print ("#  9. num-seqs-not-surviving:  number of sequences that do not span <max_lpos..min_rpos>\n");
print ("# 10. num-seqs-within-range:   number of sequences that that span <max_lpos>..<min_rpos> but\n");
print ("#     do not span <max_lpos + $pstep> .. <min_rpos + $pstep>\n");
print ("# 11. num-seqs-not-considered: number of sequences that FAILED for some reason and were not evaluated\n");
print ("# 12. num-surviving-species:   number of species taxids with at least 1 sequence that survives this span\n");
print ("# 13. num-surviving-orders:    number of order taxids with >= 1 sequence that survives this span\n");
print ("# 14. num-surviving-classes:   number of class taxids with >= 1 sequence that survives this span\n");
print ("# 15. num-surviving-phyla:     number of phylum taxids with >= 1 sequence that survives this span\n");
print ("# 16. surviving-orders:        comma-separated list of order taxids with >= 1 sequence that survives this span\n");
print ("# 17. surviving-classes:       comma-separated list of class taxids with >= 1 sequence that survives this span\n");
print ("# 18. surviving-phyla:         comma-separated list of phyla taxids with >= 1 sequence that survives this span\n");
print ("#\n");
print "#num-listed-surviving-$key\tnum-listed-missing-$key\tlength\t5'pos\t3'pos\tlisted-surviving-$key\tlisted-missing-$key\tnum-surviving-seqs\tnum-seqs-not-surviving\tnum-seqs-within-range\tnum-seqs-not-considered(failed)\tnum-surviving-species\tnum-surviving-orders\tnum-surviving-classes\tnum-surviving-phyla\tsurviving-orders\tsurviving-classes\tsurviving-phyla\n";

@out_AH = sort { 
  $b->{"nin"} <=> $a->{"nin"} or 
  $b->{"length"} <=> $a->{"length"} or
  $a->{"lpos"}   <=> $b->{"lpos"}
} @out_AH;
  
for(my $i = 0; $i < $nout; $i++) { 
  print $out_AH[$i]{"output"};
}

exit 0;


