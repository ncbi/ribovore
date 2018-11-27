#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;

# variables related to options, in their default state, changed if options are used
my $min_grp_size = 5;      # default minimum size of a group to include it
my $hard_min_grp_size = 3; # hard-coded minimum allowed for --gs
my %olist_H = ();          # filled if --olist
my $o1avgthresh = 2;
my $o1maxthresh = 3; 
my $o2avgthresh = 0.5;
my $o2maxthresh = 1.0; 
my $do_o3fail   = 0;    # set to '1' if --o3fail used;
my $do_o4       = 0;    # set to '1' if --o4on is used;
my $o4avgthresh = 3.5;  
my $do_diffseqtax = 0;  # set to '1' if --diffseqtax used;
my $do_s1       = 1;    # set to '0' if --s1off used;
my $s1minthresh = 99.8; 

my $usage = "perl alipid-taxinfo-analyze4.pl [OPTIONS]\n\t<alipid file>\n\t<seqlist file with seqs expected in alipid file>\n\t<tax_info file with group as 4th column>\n\t<output root>\n\n";

$usage .= "\tOPTIONS:\n";
$usage .= sprintf("\t\t--gs <n>     : minimum number of sequences in a group to include group in analysis [df: %d]\n", $min_grp_size);
$usage .= sprintf("\t\t--diffseqtax : require sequences have different sequence taxids to be included considered for max/avg b/t groups\n");
$usage .= sprintf("\t\t--olist <s>  : read sequences to output information on from <s> [df: output all listed in seqlist]\n");
$usage .= sprintf("\t\t--s1off      : do not identify s1 seqs (sequences with average percent identity within taxid < <f> from --s1min <f> [df: do identify S1 seqs]\n");
$usage .= sprintf("\t\t--s1min <f>  : S1 threshold for minimum percent identity within taxid to not be a S1                                [df: %.3f%%]\n",   $s1minthresh);
$usage .= sprintf("\t\t--o1avg <f>  : O1 threshold for percent difference between averages of best and assigned group to create a O1       [df: %.1f%%]\n",   $o1avgthresh);
$usage .= sprintf("\t\t--o1max <f>  : O1 threshold for percent difference between maxes of best and assigned group to create a O1          [df: %.1f%%]\n",   $o1maxthresh);
$usage .= sprintf("\t\t--o2avg <f>  : O2 threshold for percent difference between averages of best and assigned group to create a O2       [df: %.1f%%]\n",   $o2avgthresh);
$usage .= sprintf("\t\t--o2max <f>  : O2 threshold for percent difference between maxes of best and assigned group to create a O2          [df: %.1f%%]\n",   $o2maxthresh);
$usage .= sprintf("\t\t--o3fail     : fail O3 seqs (seqs w/maxavg and maxmax groups != assigned but w/diffs below O2 threshold)            [df: PASS O3 seqs]\n");
$usage .= sprintf("\t\t--o4on       : identify O4 seqs as non-O1,O2 seqs with (avg best group - avg assigned group) > <f> from --o4avg <f> [df: do not identify O4 seqs]\n");
$usage .= sprintf("\t\t--o4avg <f>  : O4 threshold for percent difference between averages of best and assigned group, requires --o4on     [df: %.1f%%]\n\n", $o4avgthresh);

# values filled when we call &GetOptions
my $opt_gs         = undef;     
my $opt_diffseqtax = undef;     
my $opt_imm        = undef;
my $opt_olist      = undef;
my $opt_s1off      = undef;
my $opt_s1min      = undef;
my $opt_o1avg      = undef;
my $opt_o1max      = undef;
my $opt_o2avg      = undef;
my $opt_o2max      = undef;
my $opt_o3fail     = undef;
my $opt_o4on       = undef;
my $opt_o4avg      = undef;

&GetOptions( "gs=s"       => \$opt_gs,
             "diffseqtax" => \$opt_diffseqtax,
             "olist=s"    => \$opt_olist, 
             "s1off"      => \$opt_s1off,
             "s1min=s"    => \$opt_s1min,
             "o1avg=s"    => \$opt_o1avg,
             "o1max=s"    => \$opt_o1max,
             "o2avg=s"    => \$opt_o2avg,
             "o2max=s"    => \$opt_o2max, 
             "o3fail"     => \$opt_o3fail, 
             "o4on"       => \$opt_o4on,
             "o4avg=s"    => \$opt_o4avg);


if(scalar(@ARGV) != 4) { die $usage; }

my ($alipid_file, $list_file, $taxinfo_file, $out_root) = (@ARGV);

# handle options
if(defined $opt_gs)         { $min_grp_size = $opt_gs; if($min_grp_size < $hard_min_grp_size) { die "ERROR with --gs <n> minimum allowed <n> is 3"; } }
if(defined $opt_diffseqtax) { $do_diffseqtax = 1; }
if(defined $opt_s1off)      { $do_s1       = 0;   };
if(defined $opt_s1min)      { $s1minthresh = $opt_s1min; }
if(defined $opt_o1avg)      { $o1avgthresh = $opt_o1avg; }
if(defined $opt_o1max)      { $o1maxthresh = $opt_o1max; }
if(defined $opt_o2avg)      { $o2avgthresh = $opt_o2avg; }
if(defined $opt_o2max)      { $o2maxthresh = $opt_o2max; }
if(defined $opt_o3fail)     { $do_o3fail   = 1; }
if(defined $opt_o4on)       { $do_o4       = 1; }
if(defined $opt_o4avg)      { $o4avgthresh = $opt_o4avg; }
if(defined $opt_olist) { 
  open(IN, $opt_olist) || die "ERROR unable to open $opt_olist for reading"; 
  while(my $line = <IN>) { 
    chomp $line;
    if($line !~ m/^\#/ && $line =~ m/\w/) { 
      $olist_H{$line} = 1; 
    }
  }
  close(IN);
}
  

if(defined $opt_o1avg || defined $opt_o2avg) { 
  if($o1avgthresh < $o2avgthresh) { 
    die "ERROR with --o1avg <f1> and/or --o2avg <f2>, <f1> must be >= <f2> (<f1> = $o1avgthresh, <f2> = $o2avgthresh)\n"; 
  }
  if($o1maxthresh < $o2maxthresh) { 
    die "ERROR with --o1avg <f1> and/or --o2avg <f2>, <f1> must be >= <f2> (<f1> = $o1avgthresh, <f2> = $o2avgthresh)\n"; 
  }
}
                          
# parse the list file
open(IN, $list_file) || die "ERROR unable to open $list_file for reading";
my $line;
my %list_H       = (); # hash, key is sequence name read in list file, value is always 1
my $nseq         = 0;  # total number of sequences
my @seq_order_A  = (); # array, sequence names in order
while($line = <IN>) { 
  chomp $line;
  $list_H{$line} = 1;
  push(@seq_order_A, $line);
  $nseq++;
}
close(IN);

# open the output files
my $tabdelimited_out = $out_root . ".alipid.sum.tab.txt";
my $readable_out     = $out_root . ".alipid.sum.rdb.txt";
open(TAB, ">", $tabdelimited_out) || die "ERROR unable to open $tabdelimited_out for writing";
open(RDB, ">", $readable_out)     || die "ERROR unable to open $readable_out for writing";

# parse taxinfo file
my $max_seqname_length = length("#sequence");
my $max_spec_length = length("species");
my %seq_grp_H   = (); # key: sequence name, value is group (taxid) that sequence belongs in
my %seq_taxid_H = (); # key: sequence name, value is taxid for the sequence
my %seq_spec_H  = (); # key: sequence name, value is genus species information for the sequence
my %grp_ct_H    = (); # key: group name, value is number of seqs in the group
my %tax_ct_H    = (); # key: species name, value is number of seqs in the genus species
# per-taxid average, 
my %seq_taxid_pid_avg_H   = (); # key is sequence name, value is percent identity between this sequence and all other sequences in its sequence tax id
my %seq_taxid_pid_denom_H = (); # key is sequence name, value is number of sequences in the taxid for this sequence that we are computing average for


open(TAXINFO, $taxinfo_file) || die "ERROR unable to open $taxinfo_file";
##seq        seq-taxid  seq-genus-species               seq-group-taxid
#AB024594.1	89796	Sagenomella verticillata	4890
#AB024593.1	89795	Sagenomella oligospora	4890
while($line = <TAXINFO>) { 
  chomp $line;
  my @el_A = split(/\t+/, $line);
  if(scalar(@el_A) != 4) { die sprintf("ERROR, could not parse taxinfo file line (%d elements): $line\n", scalar(@el_A)); }
  my ($seq, $seq_taxid, $seq_spec, $group_taxid) = ($el_A[0], $el_A[1], $el_A[2], $el_A[3]);
  if(exists $list_H{$seq}) { # only count sequences that were in our list file
    if(! exists $grp_ct_H{$group_taxid}) {  
      $grp_ct_H{$group_taxid} = 1;
    }
    else { 
      $grp_ct_H{$group_taxid}++;
    }
    if(! exists $tax_ct_H{$seq_taxid}) {  
      $tax_ct_H{$seq_taxid} = 1;
    }
    else { 
      $tax_ct_H{$seq_taxid}++;
    }
    $seq_grp_H{$seq} = $group_taxid;
    $seq_taxid_H{$seq} = $seq_taxid;
    $seq_spec_H{$seq}  = $seq_spec;

    # initialize average pid between this seq and every other one in its taxid 
    $seq_taxid_pid_avg_H{$seq}   = 0.;
    $seq_taxid_pid_denom_H{$seq} = 0;
    
    if(length($seq) > $max_seqname_length) { 
      $max_seqname_length = length($seq);
    }
    if(length($seq_spec) > $max_spec_length) { 
      $max_spec_length = length($seq_spec);
    }
  }
}

my $grp; # a group
# per seq data, 2D hashes, 1D key is sequence name, 2D key is group
my %seq_grp_pid_avg_HH     = (); # average percent id for this sequence to each group
my %seq_grp_pid_denom_HH   = (); # denominator for converting seq_grp_pid_avg_HH values to averages
my %seq_grp_pid_max_HH     = (); # maximum percent id for this sequence to a sequence in each group
my %seq_grp_pid_sargmax_HH = (); # sequence responsible for %seq_grp_pid_max_HH
my %seq_grp_pid_min_HH     = (); # minimum percent id for this sequence to a sequence in each group
my %seq_grp_pid_sargmin_HH = (); # sequence responsible for %seq_grp_pid_min_HH

# per seq 1D hashes, keep track of avg, max, min to sequences within own group
# we only fill these for sequences in groups that are in %grp_not1_H but that are
# not in %grp_bigenough_H
my %cur_grp_pid_avg_H     = (); # average percent id for this sequence to each group
my %cur_grp_pid_denom_H   = (); # denominator for converting seq_grp_pid_avg_HH values to averages
my %cur_grp_pid_max_H     = (); # maximum percent id for this sequence to a sequence in each group
my %cur_grp_pid_sargmax_H = (); # sequence responsible for %seq_grp_pid_max_HH
my %cur_grp_pid_min_H     = (); # minimum percent id for this sequence to a sequence in each group
my %cur_grp_pid_sargmin_H = (); # sequence responsible for %seq_grp_pid_min_HH

# group data
my @grp_bigenough_A = (); # the groups with at least the minimum number of sequences
my %grp_bigenough_H = (); # key is group id, value is '1' if grp is in @grp_bigenough_A
my @grp_not1_A      = (); # the groups that are not '1' AND have > 1 sequence in them
my %grp_not1_H      = (); # key is group id, value is '1' if grp is in @grp_not1_A

# determine which groups are 'bigenough' to allow sequences within them to possibly
# fail based on the outgroup test
# and determine which groups have at least 2 seqs and are 'not1'
# we need to keep track of these because we still want their avg,min,max within
# their group to be printed.
foreach $grp (sort keys (%grp_ct_H)) { 
  if(($grp ne "1") && ($grp_ct_H{$grp} >= $min_grp_size)) { 
    push(@grp_bigenough_A, $grp);
    $grp_bigenough_H{$grp} = 1;
  }
  if(($grp ne "1") && ($grp_ct_H{$grp} > 1)) { 
    push(@grp_not1_A, $grp);
    $grp_not1_H{$grp} = 1;
  }
}

# parse alipid file, keeping track of avg,min,max values in 
# %seq_grp_*_HH and %cur_grp_H
my ($grp1, $grp2);
my ($tax1, $tax2);
my $i;
my $j;
my ($seqi, $seqj, $grpi, $grpj, $taxi, $taxj); 
open(ALIPID, $alipid_file) || die "ERROR unable to open $alipid_file";
while($line = <ALIPID>) { 
  ## seqname1 seqname2 %id nid denomid %match nmatch denommatch
  #AB024594.1 AB024593.1  91.36   1576   1725  99.48   1722   1731
  #AB024594.1 AB024591.1  99.94   1727   1728 100.00   1728   1728
  chomp $line;
  if($line !~ m/^\#/) { 
    my @el_A = split(/\s+/, $line);
    my ($seq1, $seq2, $pid) = ($el_A[0], $el_A[1], $el_A[2]);

    if(! exists $seq_grp_H{$seq1}) { 
      die "ERROR didn't read taxinfo for $seq1 (sequence may not have been listed in seqlist file)\n"; 
    }
    if(! exists $seq_grp_H{$seq2}) { 
      die "ERROR didn't read taxinfo for $seq2 (sequence may not have been listed in seqlist file)\n"; 
    }
    $grp1 = $seq_grp_H{$seq1};
    $grp2 = $seq_grp_H{$seq2};
    $tax1 = $seq_taxid_H{$seq1};
    $tax2 = $seq_taxid_H{$seq2};

    # update intra-taxid average percent identity values
    if($tax1 eq $tax2) { 
      $seq_taxid_pid_avg_H{$seq1} += $pid;
      $seq_taxid_pid_avg_H{$seq2} += $pid;
      $seq_taxid_pid_denom_H{$seq1}++;
      $seq_taxid_pid_denom_H{$seq2}++;
    }      
          
    # first deal with small (< $min_grp_size) groups with at least 2 seqs that are not group '1':
    # count pairs that are in groups that are in grp_not1_H but are not in
    # grp_bigenough_H, we only care about within group avg, max and min for
    # these guys
    # further if --diffseqtax was used, we also include here any sequence in a 
    # group for which all sequences have the same sequence taxid
    if(($grp1 eq $grp2) && 
       (exists $grp_not1_H{$grp1}) && 
       (! exists $grp_bigenough_H{$grp1}) && # group is big enough
       ((! $do_diffseqtax) || (($grp_ct_H{$grp1} - $tax_ct_H{$tax1}) > 0))) { # --diffseqtax not used, or at least one sequence of diff taxid in this group
      my @cur_seq_A = ($seq1, $seq2);

      # (I only do this for loop to avoid dup'ing code for seq1 and seq2)
      for($i = 0; $i < 2; $i++) { 
        $j = ($i == 0) ? 1 : 0;
        $seqi = $cur_seq_A[$i];
        $seqj = $cur_seq_A[$j];
        if(! exists $cur_grp_pid_avg_H{$seqi}) { 
          $cur_grp_pid_avg_H{$seqi}     = $pid; 
          $cur_grp_pid_denom_H{$seqi}   = 1;
          $cur_grp_pid_max_H{$seqi}     = $pid; 
          $cur_grp_pid_sargmax_H{$seqi} = $seqj;
          $cur_grp_pid_min_H{$seqi}     = $pid; 
          $cur_grp_pid_sargmin_H{$seqi} = $seqj;
        }
        else { 
          $cur_grp_pid_avg_H{$seqi} += $pid;
          $cur_grp_pid_denom_H{$seqi}++;
          if($pid > $cur_grp_pid_max_H{$seqi}) { 
            $cur_grp_pid_max_H{$seqi}     = $pid;
            $cur_grp_pid_sargmax_H{$seqi} = $seqj;
          }
          if($pid < $cur_grp_pid_min_H{$seqi}) { 
            $cur_grp_pid_min_H{$seqi}     = $pid;
            $cur_grp_pid_sargmin_H{$seqi} = $seqj;
          }
        }
      }
    } # end of block entered for sequences in small groups but not with taxids of 1

    # elsif sequences are both from groups that are 'bigenough' update 
    # 2D hash that keep seq/grp pair stats
    elsif((exists $grp_bigenough_H{$grp1}) && (exists $grp_bigenough_H{$grp2})) { 
      # set up tmp arrays that prevent required duplication of code blocks for
      # each $seq1 and $seq2
      my @cur_seq_A = ($seq1, $seq2);
      my @cur_grp_A = ($grp1, $grp2);
      my @cur_tax_A = ($tax1, $tax2);

      if((! $do_diffseqtax) || ($tax1 ne $tax2)) { # if --diffseqtax was enabled, skip this couplet if they are the same species
        # initialize (I only do this for loop to avoid dup'ing code for seq1 and seq2)
        for($i = 0; $i < 2; $i++) { 
          $seqi = $cur_seq_A[$i];
          $grpi = $cur_grp_A[$i];
          if(! exists $seq_grp_pid_avg_HH{$seqi}) { 
            %{$seq_grp_pid_avg_HH{$seqi}}     = ();
            %{$seq_grp_pid_denom_HH{$seqi}}   = ();
            %{$seq_grp_pid_max_HH{$seqi}}     = ();
            %{$seq_grp_pid_sargmax_HH{$seqi}} = ();
            %{$seq_grp_pid_min_HH{$seqi}}     = ();
            %{$seq_grp_pid_sargmin_HH{$seqi}} = ();
          }
        }
        
        for($i = 0; $i < 2; $i++) { 
          $j = ($i == 0) ? 1 : 0;
          $seqi = $cur_seq_A[$i];
          $seqj = $cur_seq_A[$j];
          $grpi = $cur_grp_A[$i];
          $grpj = $cur_grp_A[$j];
          
          if(! exists $seq_grp_pid_avg_HH{$seqi}{$grpj}) { 
            $seq_grp_pid_avg_HH{$seqi}{$grpj}      = $pid;
            $seq_grp_pid_denom_HH{$seqi}{$grpj}    = 1;
            $seq_grp_pid_max_HH{$seqi}{$grpj}     = $pid;
            $seq_grp_pid_sargmax_HH{$seqi}{$grpj} = $seqj;
            $seq_grp_pid_min_HH{$seqi}{$grpj}     = $pid;
            $seq_grp_pid_sargmin_HH{$seqi}{$grpj} = $seqj;
          }
          else { 
            $seq_grp_pid_avg_HH{$seqi}{$grpj} += $pid;
            $seq_grp_pid_denom_HH{$seqi}{$grpj}++;
            if($pid > $seq_grp_pid_max_HH{$seqi}{$grpj}) { 
              $seq_grp_pid_max_HH{$seqi}{$grpj}     = $pid;
              $seq_grp_pid_sargmax_HH{$seqi}{$grpj} = $seqj;
            }
            if($pid < $seq_grp_pid_min_HH{$seqi}{$grpj}) { 
              $seq_grp_pid_min_HH{$seqi}{$grpj}     = $pid;
              $seq_grp_pid_sargmin_HH{$seqi}{$grpj} = $seqj;
            }
          }
        }
      } # end of 'if((! $do_diffseqtax) || ($tax1 ne $tax2))'
    } # end of elsif((exists $grp_bigenough_H{$grp1}) && (exists $grp_bigenough_H{$grp2})) { 
  } # end of if($line !~ m/^#
}
close(ALIPID);

# go back through and calculate averages
foreach my $seq (@seq_order_A) { 
  if(! exists $seq_grp_H{$seq}) { 
    die "ERROR no group for seq $seq";
  }
  if($seq_taxid_pid_denom_H{$seq} > 0) { 
    $seq_taxid_pid_avg_H{$seq} /= $seq_taxid_pid_denom_H{$seq};
  }

  my $cur_group = $seq_grp_H{$seq};
  my $cur_tax   = $seq_taxid_H{$seq};
  if((exists $grp_bigenough_H{$cur_group}) && 
     ((! $do_diffseqtax) || (($grp_ct_H{$cur_group} - $tax_ct_H{$cur_tax}) > 0))) { # --diffseqtax not used, or at least one sequence of diff taxid in this group
    foreach $grp (@grp_bigenough_A) { 
      $seq_grp_pid_avg_HH{$seq}{$grp} /= $seq_grp_pid_denom_HH{$seq}{$grp};
    }
  }
  if(exists $cur_grp_pid_avg_H{$seq}) { 
    $cur_grp_pid_avg_H{$seq} /= $cur_grp_pid_denom_H{$seq};
  }
}

# define column explanations
my $prt_s1minthresh = sprintf("%.2f", $s1minthresh);
my $prt_o1avgthresh = sprintf("%.2f", $o1avgthresh);
my $prt_o2avgthresh = sprintf("%.2f", $o2avgthresh);
my $prt_o1maxthresh = sprintf("%.2f", $o1maxthresh);
my $prt_o2maxthresh = sprintf("%.2f", $o2maxthresh);
my $prt_o4avgthresh = sprintf("%.2f", $o4avgthresh);
my $pass_type_str = ($do_o3fail) ? "{I1,I2,I3,NA}" : "{I1,I2,I3,O3,O4NA}";
my $fail_type_str = "";
if($do_o4) { 
  $fail_type_str = ($do_o3fail) ? "{O1,O2,O3,O4}" : "{O1,O2,O4}";
}
else { 
  $fail_type_str = ($do_o3fail) ? "{O1,O2,O3}" : "{O1,O2}";
}

my @column_explanation_A = (); # array of strings that explain columns to write to output files and stdout
push(@column_explanation_A, "# Explanation of columns [RIBO v0.34]:\n");
push(@column_explanation_A, "# 1.  sequence:    sequence accession.version\n");
push(@column_explanation_A, "# 2.  seq-taxid:   sequence taxid read from input file: $taxinfo_file\n");
push(@column_explanation_A, "# 3.  taxid-nseq:  number of sequences with seq-taxid\n");
push(@column_explanation_A, "# 4.  taxid-avgid: average percent identity between this sequence and all other sequences with same seq-taxid (or '-' if seqtaxid is '1' or taxid-nseq is 1)\n");
push(@column_explanation_A, "# 5.  species: sequence genus and species\n");
push(@column_explanation_A, "# 6.  type: type of sequence, one of (in order of priority):\n");
if($do_s1) { 
  push(@column_explanation_A, "#           'S1': sequence average percent id within taxid (col 4) is below $prt_s1minthresh% (changeable with --s1min <f>)\n");
}
push(@column_explanation_A, "#           'I1': in-avgid (col 10) >= avgpid-other-group and in-maxid >= maxpid-other-group\n");
push(@column_explanation_A, "#           'I2': in-avgid (col 10) <  avgpid-other-group and in-maxid >= maxpid-other-group\n");
push(@column_explanation_A, "#           'I3': in-avgid (col 10) >= avgpid-other-group and in-maxid <  maxpid-other-group\n");
push(@column_explanation_A, "#           'O1': in-avgid (col 10) <  avgpid-other-group and in-maxid <  maxpid-other-group and\n");
push(@column_explanation_A, "#                 avgpid-other-group - in-avgid >  $prt_o1avgthresh% (changeable with --o1avg <f>) and\n"); 
push(@column_explanation_A, "#                 maxpid-other-group - in-maxid >  $prt_o1maxthresh% (changeable with --o1max <f>)\n");
push(@column_explanation_A, "#           'O2': in-avgpid (col 10) <  avgpid-other-group and in-maxid <  maxpid-other-group and\n");
push(@column_explanation_A, "#                 avgpid-other-group - in-avgid >  $prt_o2avgthresh% (changeable with --o2avg <f>) and\n"); 
push(@column_explanation_A, "#                 maxpid-other-group - in-maxid >  $prt_o2maxthresh% (changeable with --o2max <f>)\n");
push(@column_explanation_A, "#           'O3': in-avgpid (col 10) <  avgpid-other-group and in-maxid <  maxpid-other-group and\n");
push(@column_explanation_A, "#                 avgpid-other-group - in-avgid <= $prt_o2avgthresh% (changeable with --o2avg <f>) OR\n"); 
push(@column_explanation_A, "#                 maxpid-other-group - in-maxid <= $prt_o2maxthresh% (changeable with --o2max <f>)\n");
if($do_o4) { 
  push(@column_explanation_A, "#           'O4': sequence is not O1 or O2 and\n");
  push(@column_explanation_A, "#                 in-avgid (col 10) <  avgpid-other-group and\n");
  push(@column_explanation_A, "#                 avgpid-other-group - in-avgid <= $prt_o4avgthresh% (changeable with --o4avg <f>)\n");
  push(@column_explanation_A, "#                 in-maxid and maxpid-other-group values are irrelevant\n");
}
push(@column_explanation_A, "#           'NA': if sequence's group (in-group column) equals 1 or has fewer than $min_grp_size sequences\n");
push(@column_explanation_A, "# 7.  p/f:        'PASS' if sequence is of type $pass_type_str\n");
push(@column_explanation_A, "#                 'FAIL' if sequence is of type $fail_type_str\n");
push(@column_explanation_A, "# 8.  in-group:   taxid of group this sequence belongs to, read from input file: $taxinfo_file\n");
push(@column_explanation_A, "# 9.  in-gnseq:   number of sequences in group in-group\n");
push(@column_explanation_A, "# 10. in-avgid:   average percent identity b/t this sequence and all other sequences in its group\n");
push(@column_explanation_A, "# 11. in-maxid:   maximum percent identity b/t this sequence and all other sequences in its group\n");
push(@column_explanation_A, "# 12. in-maxseq:  sequence in group 'in-group' with max id (of 'in-maxid') to this sequence\n");
push(@column_explanation_A, "# 13. in-minid:   minimum percent identity b/t this sequence and all other sequences in its group\n");
push(@column_explanation_A, "# 14. in-minseq:  sequence in group 'in-group' with min id (of 'in-minid') to this sequence\n");
push(@column_explanation_A, "# 15. maxavg-string: 'avg:same' if group to which this sequence has maximum average percent identity is assigned group (col 5)\n");
push(@column_explanation_A, "#                    'avg:diff' if group to which this sequence has maximum average percent identity is another group (col 12)\n");
push(@column_explanation_A, "# 16. maxavg-group:  if col 15 is 'avg:same': group to which this sequence has 2nd highest average percent identity\n");
push(@column_explanation_A, "#                    if col 15 is 'avg:diff': group to which this sequence has maximum average percent identity\n");
push(@column_explanation_A, "# 17. maxavg-nseq:   number of sequences in group 'maxavg-group' (listed in col 16)\n");
push(@column_explanation_A, "# 18. maxavg-avgid:  average percent identity b/t this sequence and all other sequences in group 'maxavg-group'\n");
push(@column_explanation_A, "# 19. maxavg-maxid:  maximum percent identity b/t this sequence and all other sequences in group 'maxavg-group'\n");
push(@column_explanation_A, "# 20. maxavg-maxseq: sequence in group 'maxavg-group' with max id (of 'maxavg-max') to this sequence\n");
push(@column_explanation_A, "# 21. maxavg-minid:  minimum percent identity b/t this sequence and all other sequences in group 'maxavg-group'\n");
push(@column_explanation_A, "# 22. maxavg-minseq: sequence in group 'maxavg-group' with min id (of 'maxavg-min') to this sequence\n");
push(@column_explanation_A, "# 23. maxmax-string: 'max:same' if group to which this sequence has maximum maximum percent identity is assigned group (col 5)\n");
push(@column_explanation_A, "#                    'max:diff' if group to which this sequence has maximum maximum percent identity is another group (col 12)\n");
push(@column_explanation_A, "# 24. maxmax-group:  if col 23 is 'max:same': group to which this sequence has 2nd maximum maximum percent identity\n");
push(@column_explanation_A, "#                    if col 23 is 'max:diff': group to which this sequence has maximum maximum percent identity\n");
push(@column_explanation_A, "# 25. maxmax-nseq:   number of sequences in group 'maxmax-group' (listed in col 24)\n");
push(@column_explanation_A, "# 26. maxmax-avgid:  average percent identity b/t this sequence and all other sequences in group 'maxmax-group'\n");
push(@column_explanation_A, "# 27. maxmax-maxid:  maximum percent identity b/t this sequence and all other sequences in group 'maxmax-group'\n");
push(@column_explanation_A, "# 28. maxmax-maxseq: sequence in group 'maxmax-group' with max id (of 'maxmax-maxid') to this sequence\n");
push(@column_explanation_A, "# 29. maxmax-minid:  minimum percent identity b/t this sequence and all other sequences in group 'maxmax-group' (listed in col 12)\n");
push(@column_explanation_A, "# 30. maxavg-minseq: sequence in group 'maxmax-group' with min id (of 'maxmax-minid' to this sequence\n");
push(@column_explanation_A, "# 31. avgdiff:       difference in this sequence's average percent id to sequences in assigned group and group 'maxavg-group'\n");
push(@column_explanation_A, "#                    value in 'in-avgid' column minus value in maxavg-avgid (negative for O types)\n");
push(@column_explanation_A, "# 32. maxdiff:       difference in this sequence's maximum percent id to sequences in assigned group and group 'maxmax-group'\n");
push(@column_explanation_A, "#                    value in 'in-maxid' column minus value in maxmax-maxid (negative for O types)\n");
push(@column_explanation_A, "# Columns 10-32 will be '-' for sequences that have in-group-taxid (column 8) of '1' OR in-gnseq (column 9) of '1'\n");
if($do_diffseqtax) { 
  push(@column_explanation_A, "#                           OR (due to --diffseqtax) have all sequences in their group in the same sequence taxid,\n");
  push(@column_explanation_A, "#                              which occurs if taxid-nseq (column 3) is equal to in-gnseq (column 9)\n");
}
push(@column_explanation_A, "# Columns 15-32 will be '-' for sequences that have in-gnseq (column 9) of < $min_grp_size and\n");
push(@column_explanation_A, "#                           for sequences that have in-gnseq equal to total number of sequences (no sequences outside of group)\n");
# output headers to both files
my $column_explanation_line = "";
foreach $column_explanation_line (@column_explanation_A) { 
  print RDB $column_explanation_line;
  print TAB $column_explanation_line;
}
my $in_category_length  = 7 + 2 + 6 + 2 + 6 + 2 + 6 + 2 + $max_seqname_length + 2 + 6 + 2 + $max_seqname_length;
my $oth_category_length = $in_category_length + 8 + 2;

print RDB ("#\n");

printf RDB ("%-*s  %7s  %-*s  %4s  %4s  ", 
            $max_seqname_length, "#", "", $max_spec_length, "", "", "");
printf RDB ("%-*s  %-*s  %-*s\n", 
            $in_category_length,  "               compared with seqs within group", 
            $oth_category_length, "                    compared with seqs in maxavg-group", 
            $oth_category_length, "                    compared with seqs in maxmax-group");

my $in_category_uline  = ""; for(my $i = 0; $i < $in_category_length; $i++)  { $in_category_uline .= "-"; }
my $oth_category_uline = ""; for(my $i = 0; $i < $oth_category_length; $i++) { $oth_category_uline .= "-"; }
printf RDB ("%-*s  %7s  %6s  %6s  %-*s  %4s  %4s  ", 
            $max_seqname_length, "#", "seq", "", "taxid", $max_spec_length, "", "", "");
printf RDB ("%s  %s  %s\n", $in_category_uline, $oth_category_uline, $oth_category_uline);

printf RDB ("%-*s  %7s  %6s  %6s  %-*s  %4s  %4s  ",
            $max_seqname_length, "#sequence", "taxid", "ntaxid", "avgid", $max_spec_length, "species", "type", "p/f");
printf RDB ("%7s  %6s  %6s  %6s  %-*s  %6s  %-*s  ", 
            "group", "nseq", "avgid", "maxid", $max_seqname_length, "maxseq", "minid", $max_seqname_length, "minseq");
printf RDB ("%8s  %7s  %6s  %6s  %6s  %-*s  %6s  %-*s  ", 
            "string", "group", "nseq", "avgid", "maxid", $max_seqname_length, "maxseq", "minid", $max_seqname_length, "minseq");
printf RDB ("%8s  %7s  %6s  %6s  %6s  %-*s  %6s  %-*s  ", 
            "string", "group", "nseq", "avgid", "maxid", $max_seqname_length, "maxseq", "minid", $max_seqname_length, "minseq");
printf RDB ("%6s  %6s\n", 
            "avgdif", "maxdif"); 


my $seqname_uline        = "";  for(my $i = 0; $i < $max_seqname_length;     $i++) { $seqname_uline .= "-"; }
my $seqname_uline_minus1 = "#"; for(my $i = 0; $i < ($max_seqname_length-1); $i++) { $seqname_uline_minus1 .= "-"; }
my $spec_uline           = "";  for(my $i = 0; $i < $max_spec_length;        $i++) { $spec_uline .= "-"; }
printf RDB ("%s  %7s  %6s  %6s  %s  %4s  %4s  ",
            $seqname_uline_minus1, "-------", "------", "------", $spec_uline, "----", "----");
printf RDB ("%7s  %6s  %6s  %6s  %s  %6s  %s  ", 
            "-------", "------", "------", "------", $seqname_uline, "------", $seqname_uline);
printf RDB ("%8s  %7s  %6s  %6s  %6s  %s  %6s  %s  ", 
            "--------", "-------", "------", "------", "------", $seqname_uline, "------", $seqname_uline);
printf RDB ("%8s  %7s  %6s  %6s  %6s  %s  %6s  %s  ", 
            "--------", "-------", "------", "------", "------", $seqname_uline, "------", $seqname_uline);
printf RDB ("%6s  %6s\n", 
            "------", "------"); 

printf TAB ("#%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
            "sequence", "seq-taxid", "ntaxid", "taxid-avgid","species", "type", "p/f", 
            "in-group", "in-nseq", "in-avgid", "in-maxid", "in-maxseq", "in-minid", "in-minseq", 
            "maxavg-string", "maxavg-group", "maxavg-nseq", "maxavg-avgid", "maxavg-maxid", "maxavg-maxseq", "maxavg-minid", "maxavg-minseq", 
            "maxmax-string", "maxmax-group", "maxmax-nseq", "maxmax-avgid", "maxmax-maxid", "maxmax-maxseq", "maxmax-minid", "maxmax-minseq", 
            "avgdiff", "maxdiff");

# for each sequence, determine group that has 'max max' and 'max avg'
# and output the relevant information
my $small_value =  0.000001; # small value to use when dealing with precision of floats
foreach my $seq (@seq_order_A) { 
  if((! defined $opt_olist) || (exists $olist_H{$seq})) { 
    if(! exists $seq_grp_H{$seq}) { 
      die "ERROR no group for seq $seq";
    }
    my $cur_group = $seq_grp_H{$seq};
    my $cur_tax   = $seq_taxid_H{$seq};
    my $pf = undef;
    my $type = undef;
    my $rdb_oth_blank_str = sprintf ("%8s  %7s  %6s  %6s  %6s  %-*s  %6s  %-*s  ", 
                                     "-", "-", "-", "-", 
                                     "-", $max_seqname_length, "-", 
                                     "-", $max_seqname_length, "-");
    my $tab_oth_blank_str = sprintf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t", 
                                     "-", "-", "-", "-", 
                                     "-", "-", 
                                     "-", "-");
    my $taxid_avgid2print_rdb = "";
    my $taxid_avgid2print_tab = "";

    # first, if we're identifying type S1, check for it
    $type = "NA";
    $pf   = "PASS";

    # get the printf formatted avgid we will output
    if($seq_taxid_pid_denom_H{$seq} > 0) { 
      $taxid_avgid2print_rdb = sprintf("%6.2f", $seq_taxid_pid_avg_H{$seq});
      $taxid_avgid2print_tab = sprintf("%.2f",  $seq_taxid_pid_avg_H{$seq});
      if($do_s1) { 
        # check if average percent identity within seq_taxid is above our minimum
        if($seq_taxid_pid_avg_H{$seq} < ($s1minthresh - $small_value)) { 
          # this will be true if $seq_taxid_pid_avg_H{$seq} < $s1minthresh, we use $small_value for precision reasons
          $type = "S1";
          $pf   = "FAIL";
        }
      }
    }
    else {
      $taxid_avgid2print_rdb = sprintf("%6s", "-");
      $taxid_avgid2print_tab = "-";
      # type stays as "NA"
    }

    # deal with seqs in groups that are not big enough
    if((! exists $grp_bigenough_H{$cur_group}) || 
       (($do_diffseqtax) && (($grp_ct_H{$cur_group} - $tax_ct_H{$cur_tax}) == 0))) { # --diffseqtax was used and all seqs in this group are same taxid
      printf RDB ("%-*s  %7d  %6s  %6s  %-*s  %4s  $pf  ", 
                  $max_seqname_length, $seq, $seq_taxid_H{$seq}, $tax_ct_H{$cur_tax}, $taxid_avgid2print_rdb, $max_spec_length, $seq_spec_H{$seq}, $type);
      printf TAB ("%s\t%s\t%s\t%s\t%s\t%s\t$pf\t", 
                  $seq, $seq_taxid_H{$seq}, $tax_ct_H{$cur_tax}, $taxid_avgid2print_tab, $seq_spec_H{$seq}, $type);

      if((! exists $grp_not1_H{$cur_group}) || # sequence is in group 1
         (($do_diffseqtax) && (($grp_ct_H{$cur_group} - $tax_ct_H{$cur_tax}) == 0))) { # --diffseqtax was used and all seqs in this group are same taxid
        # group is 1 or sequence count is 1, we didn't even keep track for this sequence
        printf RDB ("%7s  %6s  %6s  %6s  %-*s  %6s  %-*s  ", 
                    $cur_group, $grp_ct_H{$cur_group}, "-",  # $type is "NA"
                    "-", $max_seqname_length, "-", 
                    "-", $max_seqname_length, "-");
        printf TAB ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t", 
                    $cur_group, $grp_ct_H{$cur_group}, "-", # $type is "NA"
                    "-", "-", 
                    "-", "-");
      }
      else { 
        # group is not 1 and sequence count > 1, we kept track of avg, max, min within group
        # in cur_grp_*_H hashes
        printf RDB ("%7s  %6s  %6.2f  %6.2f  %-*s  %6.2f  %-*s  ", 
                    $cur_group, $grp_ct_H{$cur_group}, $cur_grp_pid_avg_H{$seq}, 
                    $cur_grp_pid_max_H{$seq}, $max_seqname_length, $cur_grp_pid_sargmax_H{$seq},
                    $cur_grp_pid_min_H{$seq}, $max_seqname_length, $cur_grp_pid_sargmin_H{$seq});
        printf TAB ("%s\t%s\t%.2f\t%.2f\t%s\t%.2f\t%s\t", 
                    $cur_group, $grp_ct_H{$cur_group}, $cur_grp_pid_avg_H{$seq}, 
                    $cur_grp_pid_max_H{$seq}, $cur_grp_pid_sargmax_H{$seq},
                    $cur_grp_pid_min_H{$seq}, $cur_grp_pid_sargmin_H{$seq});
      }
      print  RDB $rdb_oth_blank_str;
      print  TAB $tab_oth_blank_str;
      print  RDB $rdb_oth_blank_str;
      print  TAB $tab_oth_blank_str;
      printf RDB ("%6s  %6s\n", "-", "-");
      printf TAB ("%s\t%s\n", "-", "-");
    }       
    else { 
      # there is enough sequences in this group to PASS/FAIL based on a comparison with other groups
      my @sorted_grp_avg_A = (sort {$seq_grp_pid_avg_HH{$seq}{$b} <=> $seq_grp_pid_avg_HH{$seq}{$a}} keys %{$seq_grp_pid_avg_HH{$seq}});
      my @sorted_grp_max_A = (sort {$seq_grp_pid_max_HH{$seq}{$b} <=> $seq_grp_pid_max_HH{$seq}{$a}} keys %{$seq_grp_pid_max_HH{$seq}});
      
      my $win_avg_group = $sorted_grp_avg_A[0];
      my $win_max_group = $sorted_grp_max_A[0];
      # if max or avg is identical (within 0.01 percent) to $cur_group, set $cur_group as winner
      if(($win_avg_group ne $cur_group) && 
         (sprintf("%.2f", $seq_grp_pid_avg_HH{$seq}{$win_avg_group})) eq 
         (sprintf("%.2f", $seq_grp_pid_avg_HH{$seq}{$cur_group}))) { 
        $win_avg_group = $cur_group;
      }
      if(($win_max_group ne $cur_group) && 
         (sprintf("%.2f", $seq_grp_pid_max_HH{$seq}{$win_max_group})) eq 
         (sprintf("%.2f", $seq_grp_pid_max_HH{$seq}{$cur_group}))) { 
        $win_max_group = $cur_group;
      }
      my $prt_avg_group = undef;
      my $prt_max_group = undef;
      my $avg_str  = "";
      my $max_str  = "";
      my $avg_diff = undef;
      my $max_diff = undef;
      my $prt_avg_diff = undef;
      my $prt_max_diff = undef;
      
      # if --o4on used, determine if this could be an O4 sequence
      my $satisfies_o4 = 0;
      if(($do_o4) && 
         (($seq_grp_pid_avg_HH{$seq}{$win_avg_group} - $seq_grp_pid_avg_HH{$seq}{$cur_group}) > $o4avgthresh)) { 
        $satisfies_o4 = 1;
      }
      
      # determine type
      if(($cur_group eq $win_avg_group) && 
         ($cur_group eq $win_max_group)) { 
        if($type ne "S1") { 
          $type = "I1";
          $pf   = "PASS";
        }
        $prt_avg_group = (scalar(@sorted_grp_avg_A) > 1) ? $sorted_grp_avg_A[1] : undef;
        $prt_max_group = (scalar(@sorted_grp_max_A) > 1) ? $sorted_grp_max_A[1] : undef;
        $avg_str = "avg:same";
        $max_str = "max:same";
      }
      elsif(($cur_group ne $win_avg_group) && 
            ($cur_group eq $win_max_group)) { 
        if($type ne "S1") { 
          $type = "I2"; 
          $pf = "PASS";
        }
        $prt_avg_group  = $win_avg_group;
        $prt_max_group = (scalar(@sorted_grp_max_A) > 1) ? $sorted_grp_max_A[1] : undef;
        $avg_str = "avg:diff";
        $max_str = "max:same";

        # special case, check if this really should be an O4
        if(($type ne "S1") && ($satisfies_o4)) { 
          $type = "O4";
          $pf = "FAIL";
        }
      }
      elsif(($cur_group eq $win_avg_group) && 
            ($cur_group ne $win_max_group)) { 
        if($type ne "S1") { 
          $type = "I3"; 
          $pf = "PASS";
        }
        $prt_avg_group  = (scalar(@sorted_grp_avg_A) > 1) ? $sorted_grp_avg_A[1] : undef;
        $prt_max_group = $win_max_group;
        $avg_str = "avg:same";
        $max_str = "max:diff";
      }
      else { 
        if((($seq_grp_pid_avg_HH{$seq}{$win_avg_group} - $seq_grp_pid_avg_HH{$seq}{$cur_group}) > $o1avgthresh) && 
           (($seq_grp_pid_max_HH{$seq}{$win_max_group} - $seq_grp_pid_max_HH{$seq}{$cur_group}) > $o1maxthresh)) { 
          if($type ne "S1") { 
            $type = "O1";
            $pf = "FAIL";
          }
        }
        elsif((($seq_grp_pid_avg_HH{$seq}{$win_avg_group} - $seq_grp_pid_avg_HH{$seq}{$cur_group}) > $o2avgthresh) && 
              (($seq_grp_pid_max_HH{$seq}{$win_max_group} - $seq_grp_pid_max_HH{$seq}{$cur_group}) > $o2maxthresh)) { 
          if($type ne "S1") { 
            $type = "O2";
            $pf = "FAIL";
          }
        }
        else { 
          if($type ne "S1") { 
            if($satisfies_o4) { 
              $type = "O4";
              $pf = "FAIL";
            }
            else { 
              $type = "O3";
              $pf = $do_o3fail ? "FAIL" : "PASS";
            }
          }
        }
        $prt_avg_group  = $win_avg_group;
        $prt_max_group = $win_max_group;
        $avg_str = "avg:diff";
        $max_str = "max:diff";
      }

      printf RDB ("%-*s  %7d  %6d  %6s  %-*s  %4s  $pf  ", 
                  $max_seqname_length, $seq, $seq_taxid_H{$seq}, $tax_ct_H{$cur_tax}, $taxid_avgid2print_rdb, $max_spec_length, $seq_spec_H{$seq}, $type);
      printf TAB ("%s\t\%s\t%s\t%s\t%s\t%s\t$pf\t", 
                  $seq, $seq_taxid_H{$seq}, $tax_ct_H{$cur_tax}, $taxid_avgid2print_tab, $seq_spec_H{$seq}, $type);
      
      printf RDB ("%7s  %6s  %6.2f  %6.2f  %-*s  %6.2f  %-*s  ", 
                  $cur_group, $grp_ct_H{$cur_group}, $seq_grp_pid_avg_HH{$seq}{$cur_group}, 
                  $seq_grp_pid_max_HH{$seq}{$cur_group}, $max_seqname_length, $seq_grp_pid_sargmax_HH{$seq}{$cur_group},
                  $seq_grp_pid_min_HH{$seq}{$cur_group}, $max_seqname_length, $seq_grp_pid_sargmin_HH{$seq}{$cur_group});
      printf TAB ("%s\t%s\t%.2f\t%.2f\t%s\t%.2f\t%s\t", 
                  $cur_group, $grp_ct_H{$cur_group}, $seq_grp_pid_avg_HH{$seq}{$cur_group}, 
                  $seq_grp_pid_max_HH{$seq}{$cur_group}, $seq_grp_pid_sargmax_HH{$seq}{$cur_group},
                  $seq_grp_pid_min_HH{$seq}{$cur_group}, $seq_grp_pid_sargmin_HH{$seq}{$cur_group});

      if(defined $prt_avg_group) { 
        printf RDB ("%8s  %7s  %6s  %6.2f  %6.2f  %-*s  %6.2f  %-*s  ", 
                    $avg_str, 
                    $prt_avg_group, $grp_ct_H{$prt_avg_group}, $seq_grp_pid_avg_HH{$seq}{$prt_avg_group}, 
                    $seq_grp_pid_max_HH{$seq}{$prt_avg_group}, $max_seqname_length, $seq_grp_pid_sargmax_HH{$seq}{$prt_avg_group}, 
                    $seq_grp_pid_min_HH{$seq}{$prt_avg_group}, $max_seqname_length, $seq_grp_pid_sargmin_HH{$seq}{$prt_avg_group});
        printf TAB ("%s\t%s\t%s\t%.2f\t%.2f\t%s\t%.2f\t%s\t", 
                    $avg_str, 
                    $prt_avg_group, $grp_ct_H{$prt_avg_group}, $seq_grp_pid_avg_HH{$seq}{$prt_avg_group}, 
                    $seq_grp_pid_max_HH{$seq}{$prt_avg_group}, $seq_grp_pid_sargmax_HH{$seq}{$prt_avg_group}, 
                    $seq_grp_pid_min_HH{$seq}{$prt_avg_group}, $seq_grp_pid_sargmin_HH{$seq}{$prt_avg_group});
        $avg_diff     = $seq_grp_pid_avg_HH{$seq}{$cur_group} - $seq_grp_pid_avg_HH{$seq}{$prt_avg_group};
        $prt_avg_diff = sprintf("%6.2f", $avg_diff);
      }
      else { 
        print RDB $rdb_oth_blank_str;
        print TAB $tab_oth_blank_str;
      }
      
      if(defined $prt_max_group) { 
        printf RDB ("%8s  %7s  %6s  %6.2f  %6.2f  %-*s  %6.2f  %-*s  ", 
               $max_str, 
               $prt_max_group, $grp_ct_H{$prt_max_group}, $seq_grp_pid_avg_HH{$seq}{$prt_max_group}, 
               $seq_grp_pid_max_HH{$seq}{$prt_max_group}, $max_seqname_length, $seq_grp_pid_sargmax_HH{$seq}{$prt_max_group}, 
               $seq_grp_pid_min_HH{$seq}{$prt_max_group}, $max_seqname_length, $seq_grp_pid_sargmin_HH{$seq}{$prt_max_group});
        printf TAB ("%s\t%s\t%s\t%.2f\t%.2f\t%s\t%.2f\t%s\t", 
               $max_str, 
               $prt_max_group, $grp_ct_H{$prt_max_group}, $seq_grp_pid_avg_HH{$seq}{$prt_max_group}, 
               $seq_grp_pid_max_HH{$seq}{$prt_max_group}, $seq_grp_pid_sargmax_HH{$seq}{$prt_max_group}, 
               $seq_grp_pid_min_HH{$seq}{$prt_max_group}, $seq_grp_pid_sargmin_HH{$seq}{$prt_max_group});
        $max_diff     = $seq_grp_pid_max_HH{$seq}{$cur_group} - $seq_grp_pid_max_HH{$seq}{$prt_max_group};
        $prt_max_diff = sprintf("%6.2f", $max_diff);
      }
      else { 
        print RDB $rdb_oth_blank_str;
        print TAB $tab_oth_blank_str;
      }
      # print diff values
      printf RDB ("%6s  %6s\n", 
                  (defined $prt_avg_diff) ? $prt_avg_diff : "-", 
                  (defined $prt_max_diff) ? $prt_max_diff : "-");
      printf TAB ("%s\t%s\n", 
                  (defined $prt_avg_diff) ? $prt_avg_diff : "-", 
                  (defined $prt_max_diff) ? $prt_max_diff : "-");
    }
  }
}
close(RDB);
close(TAB);

print ("# Tab delimited  output saved to $tabdelimited_out\n");
print ("# Human readable output saved to $readable_out\n");


