#!/usr/bin/env perl
use strict;

my $usage = "perl alipid-taxinfo-analyze.pl\n\t<alipid file>\n\t<list file with seqs expected in alipid file>\n\t<tax_info file with group as 4th column>\n\t<output root>";
if(scalar(@ARGV) != 4) { 
  die $usage; 
}
my ($alipid_file, $list_file, $taxinfo_file, $out_root) = (@ARGV);

# read the taxinfo file
my $out_n = 0;
my %in_seq_H = ();
my %out_seq_H = ();
my $in_seq;
my $out_seq;

open(IN, $list_file) || die "ERROR unable to open $list_file for reading";
my $line;
my %list_H       = (); # hash, key is sequence name read in list file, value is always 1
my $nseq         = 0; # total number of sequences
my $nseq_wgroup  = 0; # total number of sequences where group taxid is not 1
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

my $max_seqname_length = length("#sequence");
my $max_spec_length = length("species");
my %seq_group_H = (); # key: sequence name, value is group (taxid) that sequence belongs in
my %seq_taxid_H = (); # key: sequence name, value is taxid for the sequence
my %seq_spec_H  = (); # key: sequence name, value is genus species information for the sequence
my %group_ct_H  = (); # key: group name, value is number of seqs in the group

open(TAXINFO, $taxinfo_file) || die "ERROR unable to open $taxinfo_file";
##seq        seq-taxid  seq-genus-species               seq-group-taxid
#AB024594.1	89796	Sagenomella verticillata	4890
#AB024593.1	89795	Sagenomella oligospora	4890
while($line = <TAXINFO>) { 
  chomp $line;
  my @el_A = split(/\t+/, $line);
  if(scalar(@el_A) != 4) { die sprintf("ERROR, could not parse taxinfo file line (%d elements): $line\n", scalar(@el_A)); }
  my ($seq, $seq_taxid, $seq_spec, $group_taxid) = ($el_A[0], $el_A[1], $el_A[2], $el_A[3]);
  if(exists $list_H{$seq}) { 
    if(! exists $group_ct_H{$group_taxid}) {  
      $group_ct_H{$group_taxid} = 1;
    }
    else { 
      $group_ct_H{$group_taxid}++;
    }
    $seq_group_H{$seq} = $group_taxid;
    $seq_taxid_H{$seq} = $seq_taxid;
    $seq_spec_H{$seq}  = $seq_spec;
    
    if(length($seq) > $max_seqname_length) { 
      $max_seqname_length = length($seq);
    }
    if(length($seq_spec) > $max_spec_length) { 
      $max_spec_length = length($seq_spec);
    }
  }
}

# per group data, 1D hashes, key is group
my %in_all_pid_H    = ();   # average percent id for all pairs within a group
my %in_all_denom_H  = ();   # denominator for converting in_all_pid_H values to averages
my %in_all_max_H    = ();   # maximum percent id for any pair within a group
my %in_all_min_H    = ();   # minimum percent id for any pair within a group

my %out_all_pid_H   = ();  # average percent id for all pairs in separate groups
my %out_all_denom_H = ();  # denominator for converting out_all_pid_H values to averages
my %out_all_max_H   = ();  # maximum percent id for any pair in separate groups
my %out_all_min_H   = ();  # minimum percent id for any pair in separate groups

# per seq data, 2D hashes, 1D key is group, 2D key is sequence name
my %in_pid_avg_HH     = (); # average percent id for this seq to all other seqs in its group
my %in_pid_denom_HH   = (); # denominator for converting in_pid_avg_HH values to averages
my %in_pid_max_HH     = (); # maximum percent id for this seq to any other seq in its group
my %in_pid_sargmax_HH = (); # sequence in this sequence's group that has pid in in_pid_max_HH
my %in_pid_min_HH     = (); # minimum percent id for this seq to any other seq in its group
my %in_pid_sargmin_HH = (); # sequence in this sequence's group that has pid in in_pid_min_HH

my %out_pid_avg_HH     = (); # average percent id for this seq to all other seqs outside its group
my %out_pid_denom_HH   = (); # denominator for converting out_pid_avg_HH values to averages
my %out_pid_max_HH     = (); # maximum percent id for this seq to any other seq outside its group 
my %out_pid_sargmax_HH = (); # sequence outside this sequence's group that has pid in out_pid_max_HH
my %out_pid_gargmax_HH = (); # group that $out_pid_sargmax_HH belongs to
my %out_pid_min_HH     = (); # minimum percent id for this seq to any other seq outside its group
my %out_pid_sargmin_HH = (); # sequence in this sequence's group that has pid in out_pid_min_HH
my %out_pid_gargmin_HH = (); # group that $out_pid_sargmin_HH belongs to 

my %seq_counted_H = (); # so we don't overcount sequences that have group in $nseq_wgroup;
my $group;
foreach $group (sort keys (%group_ct_H)) { 
  if($group ne "1") { 
    %{$in_pid_avg_HH{$group}}    = ();
    %{$in_pid_denom_HH{$group}}  = ();
    %{$in_pid_max_HH{$group}}    = ();
    %{$in_pid_sargmax_HH{$group}} = ();
    %{$in_pid_min_HH{$group}}    = ();
    %{$in_pid_sargmin_HH{$group}} = ();
    
    %{$out_pid_avg_HH{$group}}    = ();
    %{$out_pid_denom_HH{$group}}  = ();
    %{$out_pid_max_HH{$group}}    = ();
    %{$out_pid_sargmax_HH{$group}} = ();
    %{$out_pid_gargmax_HH{$group}} = ();
    %{$out_pid_min_HH{$group}}    = ();
    %{$out_pid_sargmin_HH{$group}} = ();
    %{$out_pid_gargmin_HH{$group}} = ();
  }
}

my ($group1, $group2);
open(ALIPID, $alipid_file) || die "ERROR unable to open $alipid_file";
while($line = <ALIPID>) { 
  ## seqname1 seqname2 %id nid denomid %match nmatch denommatch
  #AB024594.1 AB024593.1  91.36   1576   1725  99.48   1722   1731
  #AB024594.1 AB024591.1  99.94   1727   1728 100.00   1728   1728
  chomp $line;
  if($line !~ m/^\#/) { 
    my @el_A = split(/\s+/, $line);
    my ($seq1, $seq2, $pid) = ($el_A[0], $el_A[1], $el_A[2]);

    if(! exists $seq_group_H{$seq1}) { 
      die "ERROR didn't read taxinfo for $seq1\n"; 
    }
    if(! exists $seq_group_H{$seq2}) { 
      die "ERROR didn't read taxinfo for $seq1\n"; 
    }

    $group1 = $seq_group_H{$seq1};
    $group2 = $seq_group_H{$seq2};

    if((! exists $seq_counted_H{$seq1}) && ($group1 eq "1")) { 
      $nseq_wgroup++;
      $seq_counted_H{$seq1} = 1;
    }
    if((! exists $seq_counted_H{$seq2}) && ($group2 eq "1")) { 
      $nseq_wgroup++;
      $seq_counted_H{$seq2} = 1;
    }

    # only continue if both seqs have taxonomic groups
    if(($group1 != 1) &&
       ($group2 != 1)) { 

      # check if both sequences are in the same group
      if($group1 == $group2) { 
        # both seqs are in the group
        $in_all_pid_H{$group1} += $pid;
        $in_all_denom_H{$group1}++; 
        
        # update seq1 in min and max
        if(! exists $in_pid_avg_HH{$group1}{$seq1}) { 
          $in_pid_avg_HH{$group1}{$seq1}     = $pid;
          $in_pid_denom_HH{$group1}{$seq1}   = 1;
          $in_pid_max_HH{$group1}{$seq1}     = $pid;
          $in_pid_sargmax_HH{$group1}{$seq1} = $seq2;
          $in_pid_min_HH{$group1}{$seq1}     = $pid;
          $in_pid_sargmin_HH{$group1}{$seq1} = $seq2;
        }
        else { 
          $in_pid_avg_HH{$group1}{$seq1}      += $pid;
          $in_pid_denom_HH{$group1}{$seq1}++;
          if($pid > $in_pid_max_HH{$group1}{$seq1}) { 
            $in_pid_max_HH{$group1}{$seq1}     = $pid;
            $in_pid_sargmax_HH{$group1}{$seq1} = $seq2;
          }
          if($pid < $in_pid_min_HH{$group1}{$seq1}) { 
            $in_pid_min_HH{$group1}{$seq1}     = $pid;
            $in_pid_sargmin_HH{$group1}{$seq1} = $seq2;
          }
        }

        # update seq2 in min and max
        if(! exists $in_pid_avg_HH{$group1}{$seq2}) { 
          $in_pid_avg_HH{$group1}{$seq2}     = $pid;
          $in_pid_denom_HH{$group1}{$seq2}   = 1;
          $in_pid_max_HH{$group1}{$seq2}     = $pid;
          $in_pid_sargmax_HH{$group1}{$seq2} = $seq1;
          $in_pid_min_HH{$group1}{$seq2}     = $pid;
          $in_pid_sargmin_HH{$group1}{$seq2} = $seq1;
        }
        else { 
          $in_pid_avg_HH{$group1}{$seq2}      += $pid;
          $in_pid_denom_HH{$group1}{$seq2}++;
          if($pid > $in_pid_max_HH{$group1}{$seq2}) { 
            $in_pid_max_HH{$group1}{$seq2}     = $pid;
            $in_pid_sargmax_HH{$group1}{$seq2} = $seq1;
          }
          if($pid < $in_pid_min_HH{$group1}{$seq2}) { 
            $in_pid_min_HH{$group1}{$seq2}     = $pid;
            $in_pid_sargmin_HH{$group1}{$seq2} = $seq1;
          }
        }
        
        if($pid > $in_all_max_H{$group1}) { $in_all_max_H{$group} = $pid; }
        if($pid < $in_all_min_H{$group1}) { $in_all_min_H{$group} = $pid; }
      }
      elsif($group1 ne $group2) { 
        $out_all_pid_H{$group1} += $pid;
        $out_all_denom_H{$group1}++;
        
        $out_all_pid_H{$group2} += $pid;
        $out_all_denom_H{$group2}++;
        
        # update out seq min and max for sequence 1
        if(! exists $out_pid_avg_HH{$group1}{$seq1}) { 
          $out_pid_avg_HH{$group1}{$seq1}     = $pid;
          $out_pid_denom_HH{$group1}{$seq1}   = 1;
          $out_pid_max_HH{$group1}{$seq1}     = $pid;
          $out_pid_sargmax_HH{$group1}{$seq1} = $seq2;
          $out_pid_gargmax_HH{$group1}{$seq1} = $group2;
          $out_pid_min_HH{$group1}{$seq1}     = $pid;
          $out_pid_sargmin_HH{$group1}{$seq1} = $seq2;
          $out_pid_gargmin_HH{$group1}{$seq1} = $group2;
        }
        else { 
          $out_pid_avg_HH{$group1}{$seq1}     += $pid;
          $out_pid_denom_HH{$group1}{$seq1}++;
          if($pid > $out_pid_max_HH{$group1}{$seq1}) { 
            $out_pid_max_HH{$group1}{$seq1}     = $pid;
            $out_pid_sargmax_HH{$group1}{$seq1} = $seq2;
            $out_pid_gargmax_HH{$group1}{$seq1} = $group2;
          }
          if($pid < $out_pid_min_HH{$group1}{$seq1}) { 
            $out_pid_min_HH{$group1}{$seq1}     = $pid;
            $out_pid_sargmin_HH{$group1}{$seq1} = $seq2;
            $out_pid_gargmin_HH{$group1}{$seq1} = $group2;
          }
        }
        
        # update out seq min and max for sequence 2
        if(! exists $out_pid_avg_HH{$group2}{$seq2}) { 
          $out_pid_avg_HH{$group2}{$seq2}     = $pid;
          $out_pid_denom_HH{$group2}{$seq2}   = 1;
          $out_pid_max_HH{$group2}{$seq2}     = $pid;
          $out_pid_sargmax_HH{$group2}{$seq2} = $seq1;
          $out_pid_gargmax_HH{$group2}{$seq2} = $group1;
        $out_pid_min_HH{$group2}{$seq2}     = $pid;
          $out_pid_sargmin_HH{$group2}{$seq2} = $seq1;
          $out_pid_gargmin_HH{$group2}{$seq2} = $group1;
        }
        else { 
          $out_pid_avg_HH{$group2}{$seq2}      += $pid;
          $out_pid_denom_HH{$group2}{$seq2}++;
          if($pid > $out_pid_max_HH{$group2}{$seq2}) { 
            $out_pid_max_HH{$group2}{$seq2}     = $pid;
            $out_pid_sargmax_HH{$group2}{$seq2} = $seq1;
            $out_pid_gargmax_HH{$group2}{$seq2} = $group1;
          }
          if($pid < $out_pid_min_HH{$group2}{$seq2}) { 
            $out_pid_min_HH{$group2}{$seq2}     = $pid;
            $out_pid_sargmin_HH{$group2}{$seq2} = $seq1;
            $out_pid_gargmin_HH{$group2}{$seq2} = $group1;
          }
        }
        if($pid > $out_all_max_H{$group1}) { $out_all_max_H{$group1} = $pid; }
        if($pid > $out_all_max_H{$group2}) { $out_all_max_H{$group2} = $pid; }
        if($pid < $out_all_min_H{$group1}) { $out_all_min_H{$group1} = $pid; }
        if($pid < $out_all_min_H{$group2}) { $out_all_min_H{$group2} = $pid; }
      }
    }
  }
}
close(ALIPID);

my @column_explanation_A = (); # array of strings that explain columns to write to output files and stdout

push(@column_explanation_A, "Explanation of tab-delimited column headings [RIBO v0.24]:\n");
push(@column_explanation_A, "1. sequence: sequence accession.version\n");
push(@column_explanation_A, "2. seq-taxid: sequence taxid read from input file: $taxinfo_file\n");
push(@column_explanation_A, "3. species: sequence genus and species\n");
push(@column_explanation_A, "4. group-taxid: taxid of group this sequence belongs to, read from input file: $taxinfo_file\n");
push(@column_explanation_A, "5. group-nseq: number of sequences in group group-taxid\n");
push(@column_explanation_A, "6. type: type of sequence\n");
push(@column_explanation_A, "          'I1': maxpid-in-group (col 8) >= maxpid-out-group (col 13) and minpid_in_group  (col 10) >= maxpid-out-group (col 13)\n"); 
push(@column_explanation_A, "          'I2': maxpid-in-group (col 8) >= maxpid-out-group (col 13) and minpid_in_group  (col 10) >= avgpid-out-group (col 12)\n");
push(@column_explanation_A, "          'I3': maxpid-in-group (col 8) >= maxpid-out-group (col 13) and avgpid-in-group  (col 7)  >= avgpid-out-group (col 12)\n");
push(@column_explanation_A, "          'I4': maxpid-in-group (col 8) >= maxpid-out-group (col 13) and avgpid-in-group  (col 7)  <  avgpid-out-group (col 12)\n");
push(@column_explanation_A, "          'O1': maxpid-in-group (col 8) <  maxpid-out-group (col 13) and minpid-out-group (col 16) >= maxpid-in-group  (col 8)\n"); 
push(@column_explanation_A, "          'O2': maxpid-in-group (col 8) <  maxpid-out-group (col 13) and minpid-out-group (col 16) >= avgpid-in-group  (col 7)\n");
push(@column_explanation_A, "          'O3': maxpid-in-group (col 8) <  maxpid-out-group (col 13) and avgpid-out-group (col 12) >= avgpid-in-group  (col 7)\n");
push(@column_explanation_A, "          'O4': maxpid-in-group (col 8) <  maxpid-out-group (col 13) and avgpid-out-group (col 12) <  avgpid-in-group  (col 7)\n");
push(@column_explanation_A, "7. avgpid-in-group: average percent identity b/t this sequence and all other sequences in its group\n");
push(@column_explanation_A, "8. maxpid-in-group: maximum percent identity b/t this sequence and all other sequences in its group\n");
push(@column_explanation_A, "9. maxpid-seq-in-group: other sequence in group that has maxpid-in-group percent identity with this sequence\n");
push(@column_explanation_A, "10. minpid-in-group: minimum percent identity b/t this sequence and all other sequences in its group\n");
push(@column_explanation_A, "11. minpid-seq-in-group: other sequence in group that has minpid_in_group percent identity with this sequence\n");
push(@column_explanation_A, "12. avgpid-out-group: average percent identity b/t this sequence and all other sequences in a group that is not this sequence's group\n");
push(@column_explanation_A, "13. maxpid-out-group: maximum percent identity b/t this sequence and all other sequences in a group that is not this sequence's group\n");
push(@column_explanation_A, "14. maxpid-seq-out-group: other sequence outside group that has maxpid-out-group percent identity with this\n");
push(@column_explanation_A, "15. maxpid-group-out-group: taxid of group that out-maxseq is in\n");
push(@column_explanation_A, "16. minpid-out-group: minimum percent identity b/t this sequence and all other sequences in a group that is not this sequence's group\n");
push(@column_explanation_A, "17. minpid-seq-out-group: other sequence outside group that has minpid-out-group percent identity with this\n");
push(@column_explanation_A, "18. minpid-group-out-group: taxid of group that out-minseq is in\n");
push(@column_explanation_A, "19. avgdiff-in-minus-out: avgpid-in-group - avgpid-out-group\n");
push(@column_explanation_A, "20. maxdiff-in-minus-out: maxpid-in-group - maxpid-out-group\n");
push(@column_explanation_A, "21. mindiff-in-minus-out: minpid-in-group - minpid-out-group\n");
push(@column_explanation_A, "Columns 6-21 will be '-' for sequences that have group-taxid (column 4) of '1' OR group-neq (column 5) of '1'\n");
push(@column_explanation_A, "Columns 6 and 12-21 will be '-' for sequences that have group-nseq equal to total number of sequences (no sequences outside of group)\n");

my $column_explanation_line = "";
foreach $column_explanation_line (@column_explanation_A) { 
  print RDB $column_explanation_line;
}
my $in_category_length  = 6 + 2 + 6 + 2 + $max_seqname_length + 2 + 6 + 2 + $max_seqname_length;
my $out_category_length = $in_category_length + 7 + 7 + 2 + 2;

printf RDB ("%-*s  %7s  %-*s  %7s  %7s  %3s  %*s    %*s\n", 
            $max_seqname_length, "#", "", $max_spec_length, "", "", "", "", $in_category_length,
            "compared with seqs within group        ",
            $out_category_length, "compared with seqs outside group                  ");

my $in_category_uline  = ""; for(my $i = 0; $i < $in_category_length; $i++)  { $in_category_uline .= "-"; }
my $out_category_uline = ""; for(my $i = 0; $i < $out_category_length; $i++) { $out_category_uline .= "-"; }
printf RDB ("%-*s  %7s  %-*s  %7s  %7s  %3s  %s    %s\n", 
            $max_seqname_length, "#", "seq", $max_spec_length, "", "group", "group", "", $in_category_uline, $out_category_uline);


printf RDB ("%-*s  %7s  %-*s  %7s  %7s  %3s  %6s  %6s  %-*s  %6s  %-*s    %6s  %6s  %-*s  %7s  %6s  %-*s  %7s    %7s  %7s  %7s\n", 
            $max_seqname_length, "#sequence", "taxid", $max_spec_length, "species", "taxid", "nseq", "typ", 
            "avgpid", "maxpid", $max_seqname_length, "max-seq", "minpid", $max_seqname_length, "min-seq", 
            "avgpid", "maxpid", $max_seqname_length, "max-seq", "max-grp", "minpid",$max_seqname_length, "min-seq", "min-grp",
            "avgdiff", "maxdiff", "mindiff");

my $seqname_uline        = "";  for(my $i = 0; $i < $max_seqname_length;     $i++) { $seqname_uline .= "-"; }
my $seqname_uline_minus1 = "#"; for(my $i = 0; $i < ($max_seqname_length-1); $i++) { $seqname_uline_minus1 .= "-"; }
my $spec_uline           = "";  for(my $i = 0; $i < $max_spec_length;        $i++) { $spec_uline .= "-"; }
printf RDB ("%s  %7s  %s  %7s  %7s  %3s  %6s  %6s  %s  %6s  %s    %6s  %6s  %s  %7s  %6s  %s  %7s    %7s  %7s  %7s\n", 
            $seqname_uline_minus1, "-------", $spec_uline, "-------", "-------", "---" ,
            "------", "------", $seqname_uline, "------", $seqname_uline,
            "------", "------", $seqname_uline, "-------", "------", $seqname_uline, "-------", 
            "-------", "-------", "-------"); 

printf TAB ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
            "sequence", "seq-taxid", "species", "group-taxid", "group-nseq", "type", 
            "avgpid-in-group", "maxpid-in-group", "maxpid-seq-in-group", "minpid-in-group", "minpid-seq-in-group", 
            "avgpid-out-group", "maxpid-out-group", "maxpid-seq-out-group", "maxpid-group-out-group", "minpid-out-group", "minpid-seq-out-group", "minpid-group-out-group",
            "avgdiff-in-minus-out", "maxdiff-in-minus-out", "mindiff-in-minus-out");

foreach my $seq (@seq_order_A) { 
  if(! exists $seq_group_H{$seq}) { 
    die "ERROR no group for seq $seq";
  }
  $group = $seq_group_H{$seq};
  if(($group == 1) || ($group_ct_H{$group} == 1)) { 
    printf RDB ("%-*s  %7d  %-*s  %7d  %7d  %3s  %6s  %6s  %-*s  %6s  %-*s    %6s  %6s  %-*s  %7s  %6s  %-*s  %7s    %7s  %7s  %7s \n", 
                $max_seqname_length, $seq, $seq_taxid_H{$seq}, $max_spec_length, $seq_spec_H{$seq}, $group, $group_ct_H{$group}, "-", 
                "-", 
                "-", $max_seqname_length, "-",
                "-", $max_seqname_length, "-", 
                "-",
                "-", $max_seqname_length, "-", "-",
                "-", $max_seqname_length, "-", "-", 
                "-", 
                "-",
                "-");
    printf TAB ("%s\t%d\t%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                $seq, $seq_taxid_H{$seq}, $seq_spec_H{$seq}, $group, $group_ct_H{$group}, "-",
                "-",
                "-", "-",
                "-", "-",
                "-",
                "-", "-", "-",
                "-", "-", "-",
                "-",
                "-",
                "-");
  }
  elsif($out_pid_denom_HH{$group}{$seq} == 0) { # no sequences are outside the group (some may have group of 1)
    $in_pid_avg_HH{$group}{$seq} /= $in_pid_denom_HH{$group}{$seq};
    printf RDB ("%-*s  %7d  %-*s  %7d  %7d  %3s  %6.3f  %6.3f  %-*s  %6.3f  %-*s    %6s  %6s  %-*s  %7s  %6s  %-*s  %7s    %7s  %7s  %7s \n", 
                $max_seqname_length, $seq, $seq_taxid_H{$seq}, $max_spec_length, $seq_spec_H{$seq}, $group, $group_ct_H{$group}, "-", 
                $in_pid_avg_HH{$group}{$seq}, 
                $in_pid_max_HH{$group}{$seq}, $max_seqname_length, $in_pid_sargmax_HH{$group}{$seq}, 
                $in_pid_min_HH{$group}{$seq}, $max_seqname_length, $in_pid_sargmin_HH{$group}{$seq}, 
                "-",
                "-", $max_seqname_length, "-", "-",
                "-", $max_seqname_length, "-", "-", 
                "-", 
                "-",
                "-");
    printf TAB ("%s\t%d\t%s\t%d\t%s\t%s\t%.3f\t%.3f\t%s\t%.3f\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                $seq, $seq_taxid_H{$seq}, $seq_spec_H{$seq}, $group, $group_ct_H{$group}, "-",
                $in_pid_avg_HH{$group}{$seq}, 
                $in_pid_max_HH{$group}{$seq}, $in_pid_sargmax_HH{$group}{$seq}, 
                $in_pid_min_HH{$group}{$seq}, $in_pid_sargmin_HH{$group}{$seq}, 
                "-",
                "-", "-", "-",
                "-", "-", "-",
                "-",
                "-",
                "-");
  }
  else { # group != 1 && group_ct_H{$group} != 1 && out_pid_denom_HH{$group}{$seq} > 0
    if($in_pid_denom_HH{$group}{$seq} == 0) { 
      die "ERROR in_pid_denom_HH{$group}{$seq} is 0\n";
    }
    if(($out_pid_denom_HH{$group}{$seq} == 0) && ($in_pid_denom_HH{$group}{$seq} != ($nseq_wgroup-1))) { 
      die "ERROR out_pid_denom_HH{$group}{$seq} is 0 and in_pid_denom_HH{$group}{$seq} is not " . ($nseq_wgroup-1) . " but $in_pid_denom_HH{$group}{$seq}\n";
    }

    $in_pid_avg_HH{$group}{$seq} /= $in_pid_denom_HH{$group}{$seq};
    $out_pid_avg_HH{$group}{$seq} /= $out_pid_denom_HH{$group}{$seq};

    my $nn_within_group = ($in_pid_max_HH{$group}{$seq} >= $out_pid_max_HH{$group}{$seq}) ? 1 : 0;
    
    # determine type
    my $type = "?";  
    # 'I1': in_max_pid (col 8) >= out_max_pid (col 13) and in_min_pid  (col 10) >= out_max_pid (col 13)\n"); 
    # 'I2': in_max_pid (col 8) >= out_max_pid (col 13) and in_min_pid  (col 10) >= out_avg_pid (col 12)\n");
    # 'I3': in_max_pid (col 8) >= out_max_pid (col 13) and in_avg_pid  (col 9)  >= out_avg_pid (col 12)\n");
    # 'I4': in_max_pid (col 8) >= out_max_pid (col 13) and in_avg_pid  (col 9)  <  out_avg_pid (col 12)\n");
    # 
    # 'O1': in_max_pid (col 8) <  out_max_pid (col 13) and out_min_pid (col 16) >= in_max_pid  (col 8)\n"); 
    # 'O2': in_max_pid (col 8) <  out_max_pid (col 13) and out_min_pid (col 16) >= in_avg_pid  (col 7)\n");
    # 'O3': in_max_pid (col 8) <  out_max_pid (col 13) and out_avg_pid (col 12) >= in_avg_pid  (col 7)\n");
    # 'O4': in_max_pid (col 8) <  out_max_pid (col 13) and out_avg_pid (col 12) <  in_avg_pid  (col 7)\n");
    
    if($nn_within_group) { 
      if($in_pid_min_HH{$group}{$seq} >= $out_pid_max_HH{$group}{$seq}) { 
        $type = "I1";
      }
      elsif($in_pid_min_HH{$group}{$seq} >= $out_pid_avg_HH{$group}{$seq}) { 
        $type = "I2";
      }
      elsif($in_pid_avg_HH{$group}{$seq} >= $out_pid_avg_HH{$group}{$seq}) { 
        $type = "I3";
      }
      else { 
        $type = "I4";
      }
    }
    else { 
      if($out_pid_min_HH{$group}{$seq} >= $in_pid_max_HH{$group}{$seq}) { 
        $type = "O1";
      }
      elsif($out_pid_min_HH{$group}{$seq} >= $in_pid_avg_HH{$group}{$seq}) { 
        $type = "O2";
      }
      elsif($out_pid_avg_HH{$group}{$seq} >= $in_pid_avg_HH{$group}{$seq}) { 
        $type = "O3";
      }
      else { 
        $type = "O4";
      }
    }
    printf RDB ("%-*s  %7d  %-*s  %7d  %7d  %3s  %6.3f  %6.3f  %-*s  %6.3f  %-*s    %6.3f  %6.3f  %-*s  %7d  %6.3f  %-*s  %7d    %7.3f  %7.3f  %7.3f \n", 
                $max_seqname_length, $seq, $seq_taxid_H{$seq}, $max_spec_length, $seq_spec_H{$seq}, $group, $group_ct_H{$group}, $type, 
                $in_pid_avg_HH{$group}{$seq}, 
                $in_pid_max_HH{$group}{$seq}, $max_seqname_length, $in_pid_sargmax_HH{$group}{$seq}, 
                $in_pid_min_HH{$group}{$seq}, $max_seqname_length, $in_pid_sargmin_HH{$group}{$seq}, 
                $out_pid_avg_HH{$group}{$seq}, 
                $out_pid_max_HH{$group}{$seq}, $max_seqname_length, $out_pid_sargmax_HH{$group}{$seq}, $out_pid_gargmax_HH{$group}{$seq}, 
                $out_pid_min_HH{$group}{$seq}, $max_seqname_length, $out_pid_sargmin_HH{$group}{$seq}, $out_pid_gargmin_HH{$group}{$seq}, 
                ($in_pid_avg_HH{$group}{$seq} - $out_pid_avg_HH{$group}{$seq}),
                ($in_pid_max_HH{$group}{$seq} - $out_pid_max_HH{$group}{$seq}),
                ($in_pid_min_HH{$group}{$seq} - $out_pid_min_HH{$group}{$seq}));
    printf TAB ("%s\t%d\t%s\t%d\t%s\t%s\t%.3f\t%.3f\t%s\t%.3f\t%s\t%.3f\t%.3f\t%s\t%d\t%.3f\t%s\t%d\t%.3f\t%.3f\t%.3f\n",
                $seq, $seq_taxid_H{$seq}, $seq_spec_H{$seq}, $group, $group_ct_H{$group}, $type, 
                $in_pid_avg_HH{$group}{$seq}, 
                $in_pid_max_HH{$group}{$seq}, $in_pid_sargmax_HH{$group}{$seq}, 
                $in_pid_min_HH{$group}{$seq}, $in_pid_sargmin_HH{$group}{$seq}, 
                $out_pid_avg_HH{$group}{$seq}, 
                $out_pid_max_HH{$group}{$seq}, $out_pid_sargmax_HH{$group}{$seq}, $out_pid_gargmax_HH{$group}{$seq}, 
                $out_pid_min_HH{$group}{$seq}, $out_pid_sargmin_HH{$group}{$seq}, $out_pid_gargmin_HH{$group}{$seq}, 
                ($in_pid_avg_HH{$group}{$seq} - $out_pid_avg_HH{$group}{$seq}),
                ($in_pid_max_HH{$group}{$seq} - $out_pid_max_HH{$group}{$seq}),
                ($in_pid_min_HH{$group}{$seq} - $out_pid_min_HH{$group}{$seq}));
  }
}
close(RDB);
close(TAB);
print("Output in tab-delimited format saved to $tabdelimited_out.\n");
print("Output in more readable format saved to $readable_out.\n\n");
foreach $column_explanation_line (@column_explanation_A) { 
  print $column_explanation_line;
}
