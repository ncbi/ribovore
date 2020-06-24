#!/usr/bin/env perl
# EPN, Fri May 25 12:55:03 2018
# ali-apos-to-uapos.pl
# Given an alignment position return the unaligned position that aligns to that alignment column
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl ali-apos-to-uapos.pl [OPTIONS] <alignment file> <alignment RF position (or just alignment position if --notrf)\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t--notrf:        alignment position is overall position, not nongap RF (reference) position\n";
$usage .= "\t\t--after:        for sequences in which requested positions is a gap, output information\n";
$usage .= "\t\t                about first nongap alignment position *after* requested position [default: *before*]\n";
$usage .= "\t\t--protein:      alignment is protein (default DNA/RNA)\n";
$usage .= "\t\t--easeldir <s>: specify easel miniapps are in directory <s>\n";

my $do_notrf   = 0; # '1' to not operate in RF coordinate space
my $do_protein = 0; # '1' to specify protein alignment
my $do_after   = 0; # '1' if --after, changes output
my $easeldir   = "";
&GetOptions( "notrf"      => \$do_notrf, 
             "protein"    => \$do_protein,
             "after"      => \$do_after, 
             "easeldir=s" => \$easeldir);

if(scalar(@ARGV) != 2) { die $usage; }

if(($easeldir ne "") && 
   ($easeldir !~ m/\/$/)) { 
  $easeldir .= "/";
}

my $eslalistat_cmd = $easeldir . "esl-alistat";
my $eslalimask_cmd = $easeldir . "esl-alimask";
my $eslseqstat_cmd = $easeldir . "esl-seqstat";

my ($aln_file, $pos) = (@ARGV);

# run esl-alistat --list to get list of all sequences:
my $line;
my $list_file = $aln_file . ".list";
runCommand($eslalistat_cmd . " --list $list_file $aln_file > /dev/null", 0);
open(IN, "$list_file") || die "ERROR unable to open $list_file"; 
my @seq_A = ();
my $seq_width = length("#seqname");
while($line = <IN>) { 
  chomp $line;
  push(@seq_A, $line);
  if(length($line) > $seq_width) { 
    $seq_width = length($line);
  }
}
close(IN);
unlink "$list_file";
my $nseq = scalar(@seq_A);

my @len_A = ();
my $alphabet_option = ($do_protein) ? "--amino" : "--dna";
my $rf_option       = ($do_notrf)   ? ""        : "--t-rf";
my $i;

# get full lengths of all sequences (actually only used if --after)
my $seqstat_file = $aln_file . ".a.seqstat.0";
my @full_len_A = ();
runCommand(sprintf($eslseqstat_cmd . " -a --informat stockholm $alphabet_option $aln_file | grep ^\= > $seqstat_file", $pos-1), 0);
parse_seqstat_a_file($seqstat_file, \@seq_A, \@full_len_A);
unlink $seqstat_file;

# run esl-alimask to truncate alignment ending at postion $pos-1
if($pos == 1) { # special case
  for($i = 0; $i < $nseq; $i++) { 
    $len_A[$i] = 0;
  }
}
else { 
  $seqstat_file = $aln_file . ".a.seqstat.1";
  runCommand(sprintf($eslalimask_cmd . " -t $rf_option $alphabet_option $aln_file 1..%d | grep -v ^#\=GC | " . $eslseqstat_cmd . " -a --informat stockholm $alphabet_option - | grep ^\= > $seqstat_file", $pos-1), 0);
  parse_seqstat_a_file($seqstat_file, \@seq_A, \@len_A);
  unlink $seqstat_file;
}

# run esl-alimask to truncate alignment to only one position $pos-1 to determine if it is a gap or not
my @nongap_A = ();
$seqstat_file = $aln_file . ".a.seqstat.2";
runCommand($eslalimask_cmd . " -t $rf_option $alphabet_option $aln_file $pos..$pos | grep -v ^\#\=GC | " . $eslseqstat_cmd . " -a --informat stockholm $alphabet_option - | grep ^\= > $seqstat_file", 0);
parse_seqstat_a_file($seqstat_file, \@seq_A, \@nongap_A);
unlink $seqstat_file;

# output 
printf("# Explanation of columns [RIBO v0.40]:\n");
printf("# seqname: name of sequence\n");
printf("# uapos:   unaligned sequence position that aligns at alignment %s %d\n", ($do_notrf ? "position" : "RF position"), $pos);
printf("#          if 'gap?' column is 'gap' then alignment is a gap for this sequence at position $pos\n");
if($do_after) { 
    printf("#          and so 'uapos' column is the first sequence position aligned after position $pos\n");
    printf("#          or '-' if no residues exist after position $pos\n");
}
else { 
    printf("#          and so 'uapos' column is the final sequence position aligned before position $pos\n");
    printf("#          or '-' if no residues exist before position $pos\n");
}
printf("# gap?:    'nongap' if position $pos is not a gap in sequence, 'gap' if it is\n");
printf("%-*s  %6s  %-6s\n", $seq_width, "#seqname", "uapos", "gap?");

for($i = 0; $i < $nseq; $i++) { 
  my $posn2print = undef;
  if(($do_after) && ($len_A[$i] == $full_len_A[$i])) { 
    if($nongap_A[$i]) { die "ERROR found nongap after full sequence for sequence $seq_A[$i]\n"; }
    $posn2print = "-";
  }
  elsif((! $do_after) && ($len_A[$i] == 0) && ($nongap_A[$i] == 0)) { 
    $posn2print = "-";
  }
  else { 
    $posn2print = $len_A[$i] + $nongap_A[$i];
  }
  printf("%-*s  %6s  %-6s\n", $seq_width, $seq_A[$i], $posn2print, ($nongap_A[$i] ? "nongap" : "gap")); 
}

#################################################################
# Subroutine:  runCommand()
# Incept:      EPN, Thu Feb 11 13:32:34 2016
#
# Purpose:     Runs a command using system() and exits in error 
#              if the command fails. If $be_verbose, outputs
#              the command to stdout.
#
# Arguments:
#   $cmd:         command to run, with a "system" command;
#   $be_verbose:  '1' to output command to stdout before we run it, '0' not to
#
# Returns:    void
#
# Dies:       if $cmd fails
#################################################################
sub runCommand {
  my $sub_name = "runCommand()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmd, $be_verbose) = @_;
  
  if($be_verbose) { 
    print ("Running cmd: $cmd\n"); 
  }

  system($cmd);

  if($? != 0) { 
    die "ERROR, the following command failed:\n$cmd\n"; 
  }

  return;
}

#################################################################
# Subroutine:  parse_seqstat_a_file()
# Incept:      EPN, Fri May 25 14:04:48 2018
#
# Purpose:     Parses a esl-seqstat -a output file.
#
# Arguments:
#   $seqstat_file:  command to run, with a "system" command;
#   $name2check_AR: ref to array to check names against
#   $len_AR:        ref to array of sequence lengths to fill
#
# Returns:    void
#
# Dies:       if $cmd fails
#################################################################
sub parse_seqstat_a_file {
  my $sub_name = "parse_seqstat_a_file()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seqstat_file, $name2check_AR, $len_AR) = @_;

  open(IN, "$seqstat_file") || die "ERROR unable to open $seqstat_file";
  #= SSU_rRNA_bacteria-sample8        1 
  my $i = 0;
  my ($equal, $seqname, $length);
  while($line = <IN>) { 
    chomp $line;
    if($line =~ /^\=\s+\S+\s+\d+\s*.*$/) { 
      ($equal, $seqname, $length) = split(/\s+/, $line);
    }
    elsif($line =~ /^\=\s+0\s*$/) { 
      # length 0 
      ($equal, $length) = split(/\s+/, $line);
    }
    else { 
      die "ERROR unable to parse esl-seqstat -a line $line"; 
    }
    if($length ne "0") { 
      # esl-seqstat -a does not print sequence names for sequences of length 0
      if($name2check_AR->[$i] ne $seqname) { die sprintf("ERROR dealing with sequence #%d, name mismatch %s != %s\n", ($i+1), $name2check_AR->[$i], $seqname); }
    }
    $len_AR->[$i] = $length;
    $i++;
  }
  close(IN);
  
  return;
}
