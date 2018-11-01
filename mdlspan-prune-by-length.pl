#!/usr/bin/env perl
# EPN, Fri May 25 12:55:03 2018
# mdlspan-prune-by-length.pl
# Remove lines in a mdlspan table that are below a minimum length
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl mdlspan-prune-by-length.pl <mdlspan.survtbl file> <minimum length span to keep>\n\n";

# kept to facilitate addition of options later
#my $do_list   = 0; # '1' if list file is not a file but a comma separated list of taxids
#&GetOptions( "l" => \$do_list);

if(scalar(@ARGV) != 2) { die $usage; }

my ($tbl_file, $minlen) = (@ARGV);

# go through tbl_file outputting only lines corresponding to spans >= $minlen
open(TBL, $tbl_file) || die "ERROR unable to open $tbl_file for reading";
while(my $line = <TBL>) { 
  chomp $line;
  if($line =~ /^\#/) { 
    print $line . "\n";
  }
  elsif($line !~ m/^\#/) { 
    #length	5'pos	3'pos	num-surviving-seqs	num-seqs-not-surviving	num-seqs-within-range	num-seqs-not-considered(failed)	num-surviving-species	num-surviving-orders	num-missing-orders	num-surviving-classes	num-missing-classes	num-surviving-phyla	num-missing-phyla	surviving-orders	missing-orders	surviving-classes	missing-classes	surviving-phyla	missing-phyla
    #1731	61	1791	18	0	0	82	18	11	20	10	7	4	5	4892,5042,5185,5258,5338,37989,47162,61421,134362,214509,452343	-1,-4805,-4827,-5014,-5125,-5178,-5234,-34395,-34478,-36750,-62914,-68889,-92860,-107465,-139380,-292491,-451869,-452342,-1133283,-1302181	4891,147541,147545,147548,147549,147550,155619,162484,214506,2219693	-1,-147547,-155616,-451435,-451460,-452283,-2212703	4890,5204,1913637,1913638	-1,-4761,-6029,-451459,-1031332
    #1721	61	1781	18	0	0	82	18	11	20	10	7	4	5	4892,5042,5185,5258,5338,37989,47162,61421,134362,214509,452343	-1,-4805,-4827,-5014,-5125,-5178,-5234,-34395,-34478,-36750,-62914,-68889,-92860,-107465,-139380,-292491,-451869,-452342,-1133283,-1302181	4891,147541,147545,147548,147549,147550,155619,162484,214506,2219693	-1,-147547    #length	5'pos	3'pos	num-surviving-seqs	num-seqs-not-surviving	num-seqs-within-range	num-seqs-not-considered(failed)	num-surviving-species	num-surviving-orders	num-survivi
    my @el_A = split(/\t/, $line);
    if(scalar(@el_A) != 20) { 
      die sprintf("ERROR, unable to parse line in mdlspan.survtbl, expected 14 tab-delimited tokens, but read %d on line\n$line\n", scalar(@el_A));
    }
    my $len = $el_A[0];
    if($len >= $minlen) { 
      print $line . "\n";
    }
  }
} 

