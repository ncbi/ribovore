#!/usr/bin/env perl
# EPN, Fri May 25 12:55:03 2018
# ali-apos-to-uapos.pl
# Given an alignment position return the unaligned position that aligns to that alignment column
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
  open(LIST, $list_file) || die "ERROR unable to open $list_file for reading";
  while(my $line = <LIST>) { 
    chomp $line;
    if($line =~ m/^\d+$/) { 
      if(exists $in_H{$line}) { 
        die "ERROR, read $line twice in input file $list_file";
      }
      $in_H{$line} = 1;
    }
    else { 
      die "ERROR, in list file $list_file, expected one taxid per line, read $line";
    }
  }
  close(LIST);
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
    #length	5'pos	3'pos	nseq-survive	nseq-do-not-survive	nseq-not-considered(failed)	nspecies-survive	norder-survive	nclass-survive	nphylum-survive	surviving-orders	surviving-classes	surviving-phyla
    #51	701	751	31965	8426	48836	23200	104	19	1	1,6659,6683,6816,6833,6839,6845,6855,6893,6935,6961,6993,7020,7041,7088,7147,7399,7504,7509,7516,7524,27412,27420,27434,29979,29993,29994,30073,30259,30261,30262,30263,30264,30265,30266,30267,34634,37903,37905,37910,41212,41356,41360,41361,41362,41448,43267,43271,50482,50553,50622,50657,51799,52425,58139,58151,58364,58557,58774,60152,60154,61977,65651,71419,72033,75394,75395,75396,75398,75399,75402,79705,79708,83136,83137,84308,84310,84311,84313,84314,84318,84322,84332,84337,85819,85823,88344,91340,116166,116167,116170,116171,116175,116564,116573,118449,178836,192413,319670,373319,730330,730331,1652079,2082948	1,6658,6670,6681,6844,6854,7540,7553,29997,29999,30001,50557,57294,61986,63448,72037,72040,84343,217

    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 13) { 
      die sprintf("ERROR, unable to parse line in mdlspan.survtbl, expected 13 tab-delimited tokens, but read %d on line\n$line\n", scalar(@el_A));
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
    $out_AH[$nout]{"output"} = sprintf ("%d\t%d\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%s\n", 
                                        $ncur_included, $ncur_missing, 
                                        $el_A[0], $el_A[1], $el_A[2], 
                                        $cur_missing_str, $cur_included_str, 
                                        $el_A[3], $el_A[4], $el_A[5], $el_A[6], $el_A[7], $el_A[8], $el_A[9], 
                                        $el_A[10], $el_A[11], $el_A[12]);

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

print "#num-listed-surviving-$key\tnum-listed-missing-$key\tlength\t5'pos\t3'pos\tlisted-surviving-$key\tlisted-missing-$key\tnum-surviving-seqs\tnum-seqs-not-surviving\tnum-seqs-not-considered(failed)\tnum-surviving-species\tnum-surviving-orders\tnum-surviving-classes\tnum-surviving-phyla\tsurviving-orders\tsurviving-classes\tsurviving-phyla\n";

@out_AH = sort { 
  $b->{"nin"} <=> $a->{"nin"} or 
  $b->{"length"} <=> $a->{"length"} or
  $a->{"lpos"}   <=> $b->{"lpos"}
} @out_AH;
  
for(my $i = 0; $i < $nout; $i++) { 
  print $out_AH[$i]{"output"};
}

exit 0;


