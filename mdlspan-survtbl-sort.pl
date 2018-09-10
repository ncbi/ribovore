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
$usage .= "\t\t-l: 2nd arg is not a list file but a comma-separated list of 1 or more taxids\n";
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
my @orig_explanation_A = ();
open(TBL, $tbl_file) || die "ERROR unable to open $tbl_file for reading";
while(my $line = <TBL>) { 
  chomp $line;
  if($line =~ /^\#\s+\d+\.\s+(.+)/) { 
    #  1. 'length': length of model span
    #  2. '5' pos': maximum allowed 5' start position <max_lpos>
    push(@orig_explanation_A, $1); 
  }
  elsif($line !~ m/^\#/) { 
    #length	5'pos	3'pos	num-surviving-seqs	num-seqs-not-surviving	num-seqs-within-range	num-seqs-not-considered(failed)	num-surviving-species	num-surviving-orders	num-missing-orders	num-surviving-classes	num-missing-classes	num-surviving-phyla	num-missing-phyla	surviving-orders	missing-orders	surviving-classes	missing-classes	surviving-phyla	missing-phyla
    #1731	61	1791	18	0	0	82	18	11	20	10	7	4	5	4892,5042,5185,5258,5338,37989,47162,61421,134362,214509,452343	-1,-4805,-4827,-5014,-5125,-5178,-5234,-34395,-34478,-36750,-62914,-68889,-92860,-107465,-139380,-292491,-451869,-452342,-1133283,-1302181	4891,147541,147545,147548,147549,147550,155619,162484,214506,2219693	-1,-147547,-155616,-451435,-451460,-452283,-2212703	4890,5204,1913637,1913638	-1,-4761,-6029,-451459,-1031332
    #1721	61	1781	18	0	0	82	18	11	20	10	7	4	5	4892,5042,5185,5258,5338,37989,47162,61421,134362,214509,452343	-1,-4805,-4827,-5014,-5125,-5178,-5234,-34395,-34478,-36750,-62914,-68889,-92860,-107465,-139380,-292491,-451869,-452342,-1133283,-1302181	4891,147541,147545,147548,147549,147550,155619,162484,214506,2219693	-1,-147547    #length	5'pos	3'pos	num-surviving-seqs	num-seqs-not-surviving	num-seqs-within-range	num-seqs-not-considered(failed)	num-surviving-species	num-surviving-orders	num-survivi
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 20) { 
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
    if   ($do_class)  { $list_str = $el_A[16]; }
    elsif($do_phylum) { $list_str = $el_A[18]; }
    else              { $list_str = $el_A[14]; } # order

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
        $cur_missing_str .= "-" . $taxid; 
      }
    }
    if($cur_missing_str  eq "") { $cur_missing_str  = "-"; }
    if($cur_included_str eq "") { $cur_included_str = "-"; }

    # store in @out_AH
    $out_AH[$nout]{"output"} = sprintf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                                        $ncur_included, $ncur_missing, 
                                        $el_A[0], $el_A[1], $el_A[2], 
                                        $cur_missing_str, $cur_included_str, 
                                        $el_A[3], $el_A[4], $el_A[5], $el_A[6], $el_A[7], $el_A[8], $el_A[9], 
                                        $el_A[10], $el_A[11], $el_A[12], $el_A[13], $el_A[14], $el_A[15], 
                                        $el_A[16], $el_A[17], $el_A[18], $el_A[19]);

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
my $ocidx = 0;
print ("#  1. 'num-listed-surviving-$key': number of listed $key that survive for this model span [ADDED COLUMN]\n");
print ("#  2. 'num-listed-missing-$key':   number of listed $key that do not survive for this model span [ADDED COLUMN]\n");
my $cidx = 3;
for(my $ocidx = 0; $ocidx < 3; $ocidx++) { 
  printf("# %2d. %s\n", $cidx++, $orig_explanation_A[$ocidx]); 
}
print ("#  6. listed-surviving-$key: comma-separated list of $key taxids with >= 1 sequence that survives this span [ADDED COLUMN]\n");
print ("#  7. listed-missing-$key:   comma-separated list of $key taxids with 0 sequences that survive this span [ADDED COLUMN]\n");
$cidx = 8;
for(my $ocidx = 3; $ocidx < scalar(@orig_explanation_A); $ocidx++) { 
  printf("# %2d. %s\n", $cidx++, $orig_explanation_A[$ocidx]); 
}
print ("#\n");
print "#num-listed-surviving-$key\tnum-listed-missing-$key\tlength\t5'pos\t3'pos\tlisted-surviving-$key\tlisted-missing-$key\tnum-surviving-seqs\tnum-seqs-not-surviving\tnum-seqs-within-range\tnum-seqs-not-considered(failed)\tnum-surviving-species\tnum-surviving-orders\tnum-surviving-classes\tnum-surviving-phyla\tsurviving-orders\tsurviving-classes\tsurviving-phyla\n";
print "#num-listed-surviving-$key\tnum-listed-missing-$key\tlength\t5'pos\t3'pos\tlisted-surviving-$key\tlisted-missing-$key\tnum-surviving-seqs\tnum-seqs-not-surviving\tnum-seqs-within-range\tnum-seqs-not-considered(failed)\tnum-surviving-species\tnum-surviving-orders\tnum-missing-orders\tnum-surviving-classes\tnum-missing-classes\tnum-surviving-phyla\tnum-missing-phyla\tsurviving-orders\tmissing-orders\tsurviving-classes\tmissing-classes\tsurviving-phyla\tmissing-phyla\n";

@out_AH = sort { 
  $b->{"nin"} <=> $a->{"nin"} or 
  $b->{"length"} <=> $a->{"length"} or
  $a->{"lpos"}   <=> $b->{"lpos"}
} @out_AH;
  
for(my $i = 0; $i < $nout; $i++) { 
  print $out_AH[$i]{"output"};
}

exit 0;


