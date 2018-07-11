#!/usr/bin/perl
use strict;
use warnings;
#
# ribo.pm
# Eric Nawrocki
# EPN, Fri May 12 09:48:21 2017
# 
# Perl module used by ribotyper.pl, ribolengthchecker.pl and 
# ribodbcreate.pl which contains subroutines called by 
# those scripts.
#
# List of subroutines:
#
# Parsing files:
# ribo_CountAmbiguousNucleotidesInSequenceFile
# ribo_ParseSeqstatFile 
# ribo_ParseSeqstatCompTblFile
# ribo_ParseRLCModelinfoFile
# ribo_ParseQsubFile
# ribo_ProcessSequenceFile 
#
# Validating, creating or removing files
# ribo_ValidateExecutableHash
# ribo_VerifyEnvVariableIsValidDir
# ribo_CheckIfFileExistsAndIsNonEmpty
# ribo_ConcatenateListOfFiles
# ribo_WriteArrayToFile
# ribo_RemoveFileUsingSystemRm
# ribo_FastaFileSplitRandomly
# ribo_FastaFileReadAndOutputNextSeq
# ribo_WriteAcceptFile
#
# String manipulation or stats:
# ribo_GetMonoCharacterString
# ribo_NumberOfDigits
# ribo_GetTimeString
# ribo_GetDirPath
# ribo_RemoveDirPath
# ribo_ConvertFetchedNameToAccVersion
#
# Infernal-related functions
# ribo_RunCmsearchOrCmalign
# ribo_RunCmsearchOrCmalignWrapper
# ribo_MergeAlignmentsAndReorder
# ribo_WaitForFarmJobsToFinish
# 
# Miscellaneous utility functions:
# ribo_RunCommand
# ribo_SecondsSinceEpoch
# ribo_FindNonNumericValueInArray
# ribo_SumSeqlenGivenArray
# ribo_InitializeHashToEmptyString
# ribo_InitializeHashToZero
#
#################################################################
# Subroutine : ribo_CountAmbiguousNucleotidesInSequenceFile()
# Incept:      EPN, Tue May 29 14:51:35 2018
#
# Purpose:     Use esl-seqstat to determine the number of ambiguous
#              nucleotides in each sequence in a sequence file.
#              
# Arguments: 
#   $seqstat_exec: path to esl-seqstat executable
#   $seq_file:     sequence file to process
#   $seqstat_file: path to esl-seqstat output to create
#   $seqnambig_HR: ref to hash of number of ambiguous nucleotides per sequence, filled here
#   $opt_HHR:      reference to 2D hash of cmdline options
#   $FH_HR:        REF to hash of file handles, including "cmd"
# 
# Returns:     number of sequences with 1 or more ambiguous nucleotides
#              fills %{$seqnambig_HR}.
#
# Dies:        If esl-seqstat call fails
#
################################################################# 
sub ribo_CountAmbiguousNucleotidesInSequenceFile { 
  my $nargs_expected = 6;
  my $sub_name = "ribo_CountAmbiguousNucleotidesInSequenceFile()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($seqstat_exec, $seq_file, $seqstat_file, $seqnambig_HR, $opt_HHR, $FH_HR) = (@_);

  ribo_RunCommand($seqstat_exec . " --dna --comptbl $seq_file > $seqstat_file", opt_Get("-v", $opt_HHR), $FH_HR);

  # parse esl-seqstat file to get lengths
  return ribo_ParseSeqstatCompTblFile($seqstat_file, $seqnambig_HR, $FH_HR);
}

#################################################################
# Subroutine : ribo_ParseSeqstatFile()
# Incept:      EPN, Wed Dec 14 16:16:22 2016
#
# Purpose:     Parse an esl-seqstat -a output file.
#              
# Arguments: 
#   $seqstat_file:            file to parse
#   $max_targetname_length_R: REF to the maximum length of any target name, updated here, can be undef
#   $max_length_length_R:     REF to the maximum length of string-ized length of any target seq, updated here, can be undef
#   $nseq_R:                  REF to the number of sequences read, updated here
#   $seqidx_HR:               REF to hash of sequence indices to fill here
#   $seqlen_HR:               REF to hash of sequence lengths to fill here
#   $FH_HR:                   REF to hash of file handles, including "cmd"
#
# Returns:     Total number of nucleotides read (summed length of all sequences). 
#              Fills %{$seqidx_HR} and %{$seqlen_HR} and updates 
#              $$max_targetname_length_R, $$max_length_length_R, and $$nseq_R.
# 
# Dies:        If the sequence file has two sequences with identical names.
#              Error message will list all duplicates.
#              If no sequences were read.
#
################################################################# 
sub ribo_ParseSeqstatFile { 
  my $nargs_expected = 7;
  my $sub_name = "ribo_ParseSeqstatFile";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seqstat_file, $max_targetname_length_R, $max_length_length_R, $nseq_R, $seqidx_HR, $seqlen_HR, $FH_HR) = @_;

  open(IN, $seqstat_file) || ofile_FileOpenFailure($seqstat_file, "RIBO", $sub_name, $!, "reading", $FH_HR);

  my $nread = 0;            # number of sequences read
  my $tot_length = 0;       # summed length of all sequences
  my $targetname_length;    # length of a target name
  my $seqlength_length;     # length (number of digits) of a sequence length
  my $targetname;           # a target name
  my $length;               # length of a target
  my %seqdups_H = ();       # key is a sequence name that exists more than once in seq file, value is number of occurences
  my $at_least_one_dup = 0; # set to 1 if we find any duplicate sequence names

  # parse the seqstat -a output 
  # sequences must have non-empty names (else esl-seqstat call would have failed)
  # lengths must be >= 0 (lengths of 0 are okay)
  while(my $line = <IN>) { 
    # = lcl|dna_BP331_0.3k:467     1232 
    # = lcl|dna_BP331_0.3k:10     1397 
    # = lcl|dna_BP331_0.3k:1052     1414 
    chomp $line;
    #print $line . "\n";
    if($line =~ /^\=\s+(\S+)\s+(\d+)/) { 
      $nread++;
      ($targetname, $length) = ($1, $2);
      if(exists($seqidx_HR->{$targetname})) { 
        if(exists($seqdups_H{$targetname})) { 
          $seqdups_H{$targetname}++;
        }
        else { 
          $seqdups_H{$targetname} = 2;
        }
        $at_least_one_dup = 1;
      }
        
      $seqidx_HR->{$targetname} = $nread;
      $seqlen_HR->{$targetname} = $length;
      $tot_length += $length;

      $targetname_length = length($targetname);
      if((defined $max_targetname_length_R) && ($targetname_length > $$max_targetname_length_R)) { 
        $$max_targetname_length_R = $targetname_length;
      }

      $seqlength_length  = length($length);
      if((defined $max_length_length_R) && ($seqlength_length > $$max_length_length_R)) { 
        $$max_length_length_R = $seqlength_length;
      }

    }
  }
  close(IN);
  if($nread == 0) { 
    ofile_FAIL("ERROR in $sub_name, did not read any sequence lengths in esl-seqstat file $seqstat_file, did you use -a option with esl-seqstat", "RIBO", 1, $FH_HR);
  }
  if($at_least_one_dup) { 
    my $i = 1;
    my $die_string = "\nERROR, not all sequences in input sequence file have a unique name. They must.\nList of sequences that occur more than once, with number of occurrences:\n";
    foreach $targetname (sort keys %seqdups_H) { 
      $die_string .= "\t($i) $targetname $seqdups_H{$targetname}\n";
      $i++;
    }
    $die_string .= "\n";
    ofile_FAIL($die_string, "RIBO", 1, $FH_HR);
  }

  $$nseq_R = $nread;

  return $tot_length;
}

#################################################################
# Subroutine : ribo_ParseSeqstatCompTblFile()
# Incept:      EPN, Tue May 29 14:55:18 2018
#
# Purpose:     Parse an esl-seqstat --comptbl output file.
#              
# Arguments: 
#   $seqstat_file:  file to parse
#   $seqnambig_HR:  REF to hash of number of ambiguities in each sequence, to fill here 
#
# Returns:     Total number of sequences with >= 1 ambiguous nucleotide.
# 
# Dies:        Never
#
################################################################# 
sub ribo_ParseSeqstatCompTblFile { 
  my $nargs_expected = 3;
  my $sub_name = "ribo_ParseSeqstatCompTblFile";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seqstat_file, $seqnambig_HR, $FH_HR) = @_;

  open(IN, $seqstat_file) || ofile_FileOpenFailure($seqstat_file, "RIBO", $sub_name, $!, "reading", $FH_HR);

  my $nread = 0;            # number of sequences read
  my $nread_w_ambig = 0;    # summed length of all sequences
  my $seqname = undef;      # a sequence name
  my $nA;                   # number of As
  my $nC;                   # number of Cs
  my $nG;                   # number of Gs
  my $nT;                   # number of Ts
  my $L;                    # length of the sequence
  my $nambig;               # number of ambiguities           
  my %seqdups_H = ();       # key is a sequence name that exists more than once in seq file, value is number of occurences
  my $at_least_one_dup = 0; # set to 1 if we find any duplicate sequence names

  # parse the seqstat --comptbl output 
  while(my $line = <IN>) { 
    ## Sequence name                Length      A      C      G      T
    ##----------------------------- ------ ------ ------ ------ ------
    #gi|675602128|gb|KJ925573.1|       500    148     98    112    142
    #gi|219812015|gb|FJ552229.1|       796    193    209    244    150
    #gi|675602352|gb|KJ925797.1|       500    149    103    126    122

    chomp $line;
    #print $line . "\n";
    if($line =~ /^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/) { 
      $nread++;
      ($seqname, $L, $nA, $nC, $nG, $nT) = ($1, $2, $3, $4, $5, $6);
      $nambig = $L - ($nA + $nC + $nG + $nT);
      if($nambig > 0) { $nread_w_ambig++; }
      $seqnambig_HR->{$seqname} = $nambig;
    }
    elsif($line !~ m/^\#/) { 
      ofile_FAIL("ERROR in $sub_name, unable to parse esl-seqstat --comptbl line $line from file $seqstat_file", "RIBO", 1, $FH_HR);
    }
  }
  close(IN);

  return $nread_w_ambig;
}

#################################################################
# Subroutine : ribo_ParseRLCModelinfoFile()
# Incept:      EPN, Fri Oct 20 14:17:53 2017
#
# Purpose:     Parse a ribolengthchecker.pl modelinfo file, and 
#              fill information in @{$family_order_AR}, %{$family_modelname_HR}.
# 
#              
# Arguments: 
#   $modelinfo_file:       file to parse
#   $env_ribo_dir:         directory in which CM files should be found, if undef, should be full path
#   $family_order_AR:      reference to array of family names, in order read from file, FILLED HERE
#   $family_modelfile_HR:  reference to hash, key is family name, value is path to model, FILLED HERE 
#   $family_modellen_HR:   reference to hash, key is family name, value is consensus model length, FILLED HERE
#   $family_rtname_HAR     reference to hash, key is family name, value is array of ribotyper model 
#                          names to align with this model, FILLED HERE
#   $FH_HR:                ref to hash of file handles
#
# Returns:     void; 
#
################################################################# 
sub ribo_ParseRLCModelinfoFile { 
  my $nargs_expected = 7;
  my $sub_name = "ribo_ParseRLCModelinfoFile";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($modelinfo_file, $env_ribo_dir, $family_order_AR, $family_modelfile_HR, $family_modellen_HR, $family_rtname_HAR, $FH_HR) = @_;

  open(IN, $modelinfo_file) || ofile_FileOpenFailure($modelinfo_file, "RIBO", $sub_name, $!, "reading", $FH_HR);

  while(my $line = <IN>) { 
    ## each line has information on 1 family and at least 4 tokens: 
    ## token 1: Name for output files for this family
    ## token 2: CM file name for this familyn
    ## token 3: integer, consensus length for the CM for this family
    ## token 4 to N: names of ribotyper models (e.g. SSU_rRNA_archaea) for which we'll use this model to align
    #SSU.Archaea RF01959.cm SSU_rRNA_archaea
    #SSU.Bacteria RF00177.cm SSU_rRNA_bacteria SSU_rRNA_cyanobacteria
    chomp $line; 
    if($line !~ /^\#/ && $line =~ m/\w/) { 
      $line =~ s/^\s+//; # remove leading whitespace
      $line =~ s/\s+$//; # remove trailing whitespace
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) < 4) { 
        ofile_FAIL("ERROR in $sub_name, less than 4 tokens found on line $line of $modelinfo_file", "RIBO", 1, $FH_HR);  
      }
      my $family    = $el_A[0];
      my $modelfile = $el_A[1];
      my $modellen  = $el_A[2];
      my @rtname_A = ();
      for(my $i = 3; $i < scalar(@el_A); $i++) { 
        push(@rtname_A, $el_A[$i]);
      }
      push(@{$family_order_AR}, $family);
      $family_modelfile_HR->{$family}  = $env_ribo_dir . "/" . $modelfile;
      $family_modellen_HR->{$family}   = $modellen;
      @{$family_rtname_HAR->{$family}} = (@rtname_A);
    }
  }
  close(IN);

  return;
}

#################################################################
# Subroutine : ribo_ParseQsubFile()
# Incept:      EPN, Mon Jul  9 10:30:41 2018
#
# Purpose:     Parse a file that specifies the qsub command to use
#              when submitting jobs to the farm. The file should 
#              have exactly 2 non-'#' prefixed lines. Chomp each
#              and return them.
#              
# Arguments: 
#   $qsub_file:  file to parse
#   $FH_HR:      REF to hash of file handles
#
# Returns:     2 values:
#              $qsub_prefix: string that is the qsub command prior to the 
#                            actual cmsearch/cmalign command
#              $qsub_suffix: string that is the qsub command after the 
#                            actual cmsearch/cmalign command
# 
# Dies:        If we can't parse the qsub file because it is not
#              in the correct format.
#
################################################################# 
sub ribo_ParseQsubFile { 
  my $nargs_expected = 2;
  my $sub_name = "ribo_ParseQsubFile";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($qsub_file, $FH_HR) = @_;

  open(IN, $qsub_file) || ofile_FileOpenFailure($qsub_file, "RIBO", $sub_name, $!, "reading", $FH_HR);

  my $qsub_prefix_line = undef;
  my $qsub_suffix_line = undef;
  while(my $line = <IN>) { 
    if($line !~ m/^\#/) { 
      chomp $line;
      if   (! defined $qsub_prefix_line) { $qsub_prefix_line = $line; }
      elsif(! defined $qsub_suffix_line) { $qsub_suffix_line = $line; }
      else { # both $qsub_prefix_line and $qsub_suffix_line are defined, this shouldn't happen
        ofile_FAIL("ERROR in $sub_name, read more than 2 non-# prefixed lines in file $qsub_file:\n$line\n", "RIBO", $?, $FH_HR);
      }
    }
  }
  close(IN);
  
  if(! defined $qsub_prefix_line) { 
    ofile_FAIL("ERROR in $sub_name, read zero non-# prefixed lines in file $qsub_file, but expected 2", "RIBO", $?, $FH_HR);
  }
  if(! defined $qsub_suffix_line) { 
    ofile_FAIL("ERROR in $sub_name, read only one non-# prefixed lines in file $qsub_file, but expected 2", "RIBO", $?, $FH_HR);
  }

  return($qsub_prefix_line, $qsub_suffix_line);
}

#################################################################
# Subroutine : ribo_ProcessSequenceFile()
# Incept:      EPN, Fri May 12 10:08:47 2017
#
# Purpose:     Use esl-seqstat to get the lengths of all sequences in a
#              FASTA or Stockholm formatted sequence file and fill
#              %{$seqidx_HR} and %{$seqlen_HR} where key is sequence
#              name, and value is index in file or sequence
#              length. Also update %{$width_HR} with maximum length of
#              sequence name (key: "target"), index (key: "index") and
#              length (key: "length").
#              
# Arguments: 
#   $seqstat_exec:   path to esl-seqstat executable
#   $seq_file:       sequence file to process
#   $seqstat_file:   path to esl-seqstat output to create
#   $seqidx_HR:      ref to hash of sequence indices to fill here
#   $seqlen_HR:      ref to hash of sequence lengths to fill here
#   $width_HR:       ref to hash to fill with max widths (see Purpose), can be undef
#   $opt_HHR:        reference to 2D hash of cmdline options
#   $ofile_info_HHR: ref to the ofile info 2D hash
# 
# Returns:     total number of nucleotides in all sequences read, 
#              fills %{$seqidx_HR}, %{$seqlen_HR}, and 
#              %{$width_HR} (partially)
#
# Dies:        If the sequence file has two sequences with identical names.
#              Error message will list all duplicates.
#              If no sequences were read.
#
################################################################# 
sub ribo_ProcessSequenceFile { 
  my $nargs_expected = 8;
  my $sub_name = "ribo_ProcessSequenceFile()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($seqstat_exec, $seq_file, $seqstat_file, $seqidx_HR, $seqlen_HR, $width_HR, $opt_HHR, $ofile_info_HHR) = (@_);

  my $FH_HR = $ofile_info_HHR->{"FH"}; # for convenience

  ribo_RunCommand($seqstat_exec . " --dna -a $seq_file > $seqstat_file", opt_Get("-v", $opt_HHR), $FH_HR);
  ofile_AddClosedFileToOutputInfo($ofile_info_HHR, "RIBO", "seqstat", $seqstat_file, 0, "esl-seqstat -a output for $seq_file");

  # parse esl-seqstat file to get lengths
  my $max_targetname_length = length("target"); # maximum length of any target name
  my $max_length_length     = length("length"); # maximum length of the string-ized length of any target
  my $nseq                  = 0; # number of sequences read
  my $tot_length = ribo_ParseSeqstatFile($seqstat_file, \$max_targetname_length, \$max_length_length, \$nseq, $seqidx_HR, $seqlen_HR, $FH_HR); 

  if(defined $width_HR) { 
    $width_HR->{"target"} = $max_targetname_length;
    $width_HR->{"length"} = $max_length_length;
    $width_HR->{"index"}  = length($nseq);
    if($width_HR->{"index"} < length("#idx")) { $width_HR->{"index"} = length("#idx"); }
  }

  return $tot_length;
}

#################################################################
# Subroutine : ribo_ValidateExecutableHash()
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
sub ribo_ValidateExecutableHash { 
  my $nargs_expected = 1;
  my $sub_name = "ribo_ValidateExecutableHash()";
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
    die "ERROR in $sub_name(),\n$fail_str"; # it's okay this isn't ofile_FAIL because this is called before ofile_info_HH is set-up
  }

  return;
}

#################################################################
# Subroutine : ribo_VerifyEnvVariableIsValidDir()
# Incept:      EPN, Wed Oct 25 10:09:28 2017
#
# Purpose:     Verify that the environment variable $envvar exists 
#              and that it is a valid directory. Return directory path.
#              
# Arguments: 
#   $envvar:  environment variable
#
# Returns:    directory path $ENV{'$envvar'}
#
################################################################# 
sub ribo_VerifyEnvVariableIsValidDir
{
  my $nargs_expected = 1;
  my $sub_name = "ribo_VerifyEnvVariableIsValidDir()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($envvar) = $_[0];

  if(! exists($ENV{"$envvar"})) { 
    die "ERROR, the environment variable $envvar is not set";
    # it's okay this isn't ofile_FAIL because this is called before ofile_info_HH is set-up
  }
  my $envdir = $ENV{"$envvar"};
  if(! (-d $envdir)) { 
    die "ERROR, the directory specified by your environment variable $envvar does not exist.\n"; 
    # it's okay this isn't ofile_FAIL because this is called before ofile_info_HH is set-up
  }    

  return $envdir;
}

#################################################################
# Subroutine : ribo_CheckIfFileExistsAndIsNonEmpty()
# Incept:      EPN, Thu May  4 09:30:32 2017 [dnaorg.pm:validateFileExistsAndIsNonEmpty]
#
# Purpose:     Check if a file exists and is non-empty. 
#
# Arguments: 
#   $filename:         file that we are checking on
#   $filedesc:         description of file
#   $calling_sub_name: name of calling subroutine (can be undef)
#   $do_die:           '1' if we should die if it does not exist.  
#   $FH_HR:            ref to hash of file handles, can be undef
# 
# Returns:     Return '1' if it does and is non empty, '0' if it does
#              not exist, or '-1' if it exists but is empty.
#
# Dies:        If file does not exist or is empty and $do_die is 1.
# 
################################################################# 
sub ribo_CheckIfFileExistsAndIsNonEmpty { 
  my $nargs_expected = 5;
  my $sub_name = "ribo_CheckIfFileExistsAndIsNonEmpty()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($filename, $filedesc, $calling_sub_name, $do_die, $FH_HR) = @_;

  if(! -e $filename) { 
    if($do_die) { 
      ofile_FAIL(sprintf("ERROR in $sub_name, %sfile $filename%s does not exist.", 
                         (defined $calling_sub_name ? "called by $calling_sub_name," : ""),
                         (defined $filedesc         ? " ($filedesc)" : "")),
                 "RIBO", 1, $FH_HR); 
    }
    return 0;
  }
  elsif(! -s $filename) { 
    if($do_die) { 
      ofile_FAIL(sprintf("ERROR in $sub_name, %sfile $filename%s exists but is empty.", 
                         (defined $calling_sub_name ? "called by $calling_sub_name," : ""),
                         (defined $filedesc         ? " ($filedesc)" : "")),
                 "RIBO", 1, $FH_HR); 
    }
    return -1;
  }
  
  return 1;
}

#################################################################
# Subroutine : ribo_ConcatenateListOfFiles()
# Incept:      EPN, Sun Apr 24 08:08:15 2016 [dnaorg_scripts]
#
# Purpose:     Concatenate a list of files into one file.
#              If the list has more than 500 files, split
#              up job into concatenating 500 at a time.
# 
#              We remove all files that we concatenate unless
#              --keep option is on in %{$opt_HHR}.
#
# Arguments: 
#   $file_AR:          REF to array of all files to concatenate
#   $outfile:          name of output file to create by concatenating
#                      all files in @{$file_AR}.
#   $caller_sub_name:  name of calling subroutine (can be undef)
#   $opt_HHR:          REF to 2D hash of option values, see top of epn-options.pm for description
#   $FH_HR:            ref to hash of file handles
# 
# Returns:     Nothing.
# 
# Dies:        If one of the cat commands fails.
#              If $outfile is in @{$file_AR}
#              If @{$file_AR} contains more than 800*800 files
#              (640K) if so, we may need to call this function
#              recursively twice (that is, recursive call will
#              also call itself recursively) and we don't have 
#              a sophisticated enough temporary file naming
#              strategy to handle that robustly.
################################################################# 
sub ribo_ConcatenateListOfFiles { 
  my $nargs_expected = 5;

  my $sub_name = "ribo_ConcatenateListOfFiles()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($file_AR, $outfile, $caller_sub_name, $opt_HHR, $FH_HR) = @_;

  if(ribo_FindNonNumericValueInArray($file_AR, $outfile, $FH_HR) != -1) { 
    ofile_FAIL(sprintf("ERROR in $sub_name%s, output file name $outfile exists in list of files to concatenate", 
                       (defined $caller_sub_name) ? " called by $caller_sub_name" : ""), 1, $FH_HR);
  }

  # first, convert @{$file_AR} array into a 2D array of file names, each of which has 
  # a max of 800 elements, we'll concatenate each of these lists separately
  my $max_nfiles = 800;
  my $nfiles = scalar(@{$file_AR});

  if($nfiles > ($max_nfiles * $max_nfiles)) { 
    ofile_FAIL(sprintf("ERROR in $sub_name%s, trying to concatenate %d files, our limit is %d", 
                       (defined $caller_sub_name) ? " called by $caller_sub_name" : "", $nfiles, $max_nfiles * $max_nfiles), 
               1, $FH_HR);
  }
    
  my ($idx1, $idx2); # indices in @{$file_AR}, and of secondary files
  my @file_AA = ();
  $idx2 = -1; # get's incremented to 0 in first loop iteration
  for($idx1 = 0; $idx1 < $nfiles; $idx1++) { 
    if(($idx1 % $max_nfiles) == 0) { 
      $idx2++; 
      @{$file_AA[$idx2]} = (); # initialize
    }
    push(@{$file_AA[$idx2]}, $file_AR->[$idx1]);
  }
  
  my $nconcat = scalar(@file_AA);
  my @tmp_outfile_A = (); # fill this with names of temporary files we create
  my $tmp_outfile; # name of an output file we'll create
  for($idx2 = 0; $idx2 < $nconcat; $idx2++) { 
    if($nconcat == 1) { # special case, we don't need to create any temporary files
      $tmp_outfile = $outfile;
    }
    else { 
      $tmp_outfile = $outfile . ".tmp" . ($idx2+1); 
      # make sure this file does not exist in @{$file_AA[$idx2]} to avoid klobbering
      # if it does, continue to append .tmp($idx2+1) until it doesn't
      while(ribo_FindNonNumericValueInArray($file_AA[$idx2], $tmp_outfile, $FH_HR) != -1) { 
        $tmp_outfile .= ".tmp" . ($idx2+1); 
      }
    }
    # create the concatenate command
    my $cat_cmd = "cat ";
    foreach my $tmp_file (@{$file_AA[$idx2]}) {
      $cat_cmd .= $tmp_file . " ";
    }
    $cat_cmd .= "> $tmp_outfile";

    # execute the command
    ribo_RunCommand($cat_cmd, opt_Get("-v", $opt_HHR), $FH_HR);

    # add it to the array of temporary files
    push(@tmp_outfile_A, $tmp_outfile); 
  }

  if(scalar(@tmp_outfile_A) > 1) { 
    # we created more than one temporary output file, concatenate them
    # by calling this function again
    ribo_ConcatenateListOfFiles(\@tmp_outfile_A, $outfile, (defined $caller_sub_name) ? $caller_sub_name . ":" . $sub_name : $sub_name, $opt_HHR, $FH_HR);
  }

  if(! opt_Get("--keep", $opt_HHR)) { 
    # remove all of the original files, be careful to not remove @tmp_outfile_A
    # because the recursive call will handle that
    foreach my $file_to_remove (@{$file_AR}) { 
      ribo_RemoveFileUsingSystemRm($file_to_remove, 
                                   (defined $caller_sub_name) ? $caller_sub_name . ":" . $sub_name : $sub_name, 
                                   $opt_HHR, $FH_HR);
    }
  }

  return;
}

#################################################################
# Subroutine : ribo_WriteArrayToFile()
# Incept:      EPN, Thu May  4 14:11:03 2017
#
# Purpose:     Create a file with each element in an array on 
#              a different line.
#              
# Arguments: 
#   $AR:    reference to array 
#   $file:  name of file to create
#   $FH_HR: ref to hash of file handles, including "cmd"
#
# Returns:  Nothing.
# 
# Dies:     If $AR is empty or we can't write to $file.
#
################################################################# 
sub ribo_WriteArrayToFile {
  my $nargs_expected = 3;
  my $sub_name = "ribo_WriteArrayToFile";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($AR, $file, $FH_HR) = @_;

  if((! defined $AR) || (scalar(@{$AR}) == 0)) { 
    ofile_FAIL("ERROR in $sub_name, array is empty or not defined", "RIBO", 1, $FH_HR);
  }

  open(OUT, ">", $file) || ofile_FileOpenFailure($file, "RIBO", $sub_name, $!, "reading", $FH_HR);

  foreach my $el (@{$AR}) { 
    print OUT $el . "\n"; 
  }
  close(OUT);

  return;
}

#################################################################
# Subroutine: ribo_RemoveFileUsingSystemRm
# Incept:     EPN, Fri Mar  4 15:57:25 2016 [dnaorg_scripts]
#
# Purpose:    Remove a file from the filesystem by using
#             the system rm command.
# Arguments:
#   $file:            file to remove
#   $caller_sub_name: name of caller, can be undef
#   $opt_HHR:         REF to 2D hash of option values, see top of epn-options.pm for description
#   $FH_HR:           REF to hash of file handles, including "log" and "cmd"
# 
# Returns: void
#
# Dies:    - if the file does not exist
#
#################################################################
sub ribo_RemoveFileUsingSystemRm { 
  my $sub_name = "ribo_RemoveFileUsingSystemRm";
  my $nargs_expected = 4;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
 
  my ($file, $caller_sub_name, $opt_HHR, $FH_HR) = (@_);
  
  if(! -e $file) { 
    DNAORG_FAIL(sprintf("ERROR in $sub_name, %s trying to remove file $file but it does not exist", 
                (defined $caller_sub_name) ? "called by $caller_sub_name," : 0), 1, $FH_HR); 
  }

  ribo_RunCommand("rm $file", opt_Get("-v", $opt_HHR), $FH_HR);

  return;
}

#################################################################
# Subroutine: ribo_FastaFileSplitRandomly
# Incept:     EPN, Fri Jul  6 09:56:37 2018
#
# Purpose:    Given a fasta file and a hash with sequence lengths
#             for all sequences in the file, split the file into
#             <n> files randomly, such that each sequence is randomly
#             placed in one of the <n> files with the exception that
#             the first i=1 to <n> sequences are placed in files 
#             1 to <n> (so that each file gets at least one sequence).
#
# Arguments:
#   $fa_file:     the fasta file
#   $seqlen_HR:   ref to hash, key is sequence name, value is sequence length
#   $out_dir:     output directory for placing sequence files
#   $tot_nseq:    total number of sequences
#   $tot_nres:    total number of nucleotides in all sequences
#   $targ_nres:   target number of residues per file
#   $rng_seed:    seed for srand(), to seed RNG, undef to not seed it
#   $FH_HR:       ref to hash of file handles, including "cmd"
# 
# Returns:  Number of files created.
# 
# Dies:     If we trouble parsing/splitting the fasta file
#################################################################
sub ribo_FastaFileSplitRandomly { 
  my $sub_name = "ribo_FastaFileSplitRandomly";
  my $nargs_expected = 8;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  #my $random_number = int(rand(100));
  my ($fa_file, $seqlen_HR, $out_dir, $tot_nseq, $tot_nres, $targ_nres, $rng_seed, $FH_HR) = @_;

  my $do_debug = 0;

  my $in_FH = undef;
  open($in_FH, $fa_file) || ofile_FileOpenFailure($fa_file, "RIBO", $sub_name, $!, "reading", $FH_HR);
  
  if(defined $rng_seed) { srand($rng_seed); }

  # determine number of files to create
  my $nfiles = int($tot_nres / $targ_nres);
  if($nfiles < 1) { $nfiles = 1; }
  # nfiles must be less than or equal to: $nseq and 300
  if($nfiles > $tot_nseq) { $nfiles = $tot_nseq; }
  if($nfiles > 300)       { $nfiles = 300; }
  if($nfiles <= 0) { 
    ofile_FAIL("ERROR in $sub_name, trying to make $nfiles files", "RIBO", 1, $FH_HR);
  }
  $targ_nres = int($tot_nres / $nfiles);


  # We need to open up all output file handles at once, we'll randomly
  # choose which one to print each sequence to. We need to keep track
  # of total length of all sequences output to each file so we know
  # when to close them. Once a file is closed, we won't choose to
  # write to it anymore, using the @map_A array as follows:
  #
  # We define an array @r2f_map_A with an element for each of the $nfiles
  # output files. For each sequence, we randomly choose a number
  # between 0 and $nfiles-1 to pick which output file to write the
  # sequence to. Initially $r2f_map_A[$i] == $i, but when if we close file
  # $i we set $r2f_map_A[$i] to $r2f_map_A[$nremaining-1], then choose a
  # random int between 0 and $nremaining-1. This gets us a random
  # sample without replacement. 
  #
  # @f2r_map_A is the inverse of @r2f_mapA, which we need only so that
  # we can guarantee that each file gets at least 1 sequence.
  # 
  my @r2f_map_A = ();  # map of random index to file number, $r2f_map_A[$ridx] = file number that random choice $ridx pertains to
  my @f2r_map_A = ();  # map of file number to random index, $f2r_map_A[$fidx] = random choice $ridx that file number $fidx pertains to
  my @nres_per_out_A = ();
  my $nres_tot_out = 0;  # total number of sequences output thus far
  my @nseq_per_out_A = ();
  my @out_filename_A = (); # array of file names
  my @out_FH_A = (); # [0..$nfiles-1], the actual open file handles
  my @isopen_A = (); # [0..$i..$nfiles-1], '1' if file $i is open, '0' if it has been closed
  my $nopen = 0; # number of files that are still open
  my $checkpoint_fraction_step = 0.05; # if($do_randomize) we will output update each time this fraction of total sequence has been output
  my $checkpoint_fraction = $checkpoint_fraction_step;
  my $checkpoint_nres = $checkpoint_fraction * $tot_nres;
  my $fidx; # file index of current file in @out_filename_A and file handle in @out_FH_A
  my $nres_this_seq = 0; # number of residues in current file
  
  # variables only used if $do_randomize
  my $ridx; # randomly selected index in @map_A for current sequence
  my $FH; # pointer to current file handle to print to
  my $nseq_remaining = $tot_nseq;
  my $nseq_output    = 0;
  my $fa_file_tail = ribo_RemoveDirPath($fa_file);

  for($fidx = 0; $fidx < $nfiles; $fidx++) { $r2f_map_A[$fidx] = $fidx; }
  for($fidx = 0; $fidx < $nfiles; $fidx++) { $f2r_map_A[$fidx] = $fidx; }
  for($fidx = 0; $fidx < $nfiles; $fidx++) { $nres_per_out_A[$fidx] = 0; }
  for($fidx = 0; $fidx < $nfiles; $fidx++) { $nseq_per_out_A[$fidx] = 0; }
  for($fidx = 0; $fidx < $nfiles; $fidx++) { $out_filename_A[$fidx] = $out_dir . "/." . $fa_file_tail . "." . ($fidx+1); } 

  # open up all output file handles, else open only the first
  for($fidx = 0; $fidx < $nfiles; $fidx++) { 
    open($out_FH_A[$fidx], ">", $out_filename_A[$fidx]) || ofile_FileOpenFailure($out_filename_A[$fidx], "RIBO", $sub_name, $!, "writing", $FH_HR);
    $isopen_A[$fidx] = 1;
  }
  $nopen = $nfiles; # will be decremented as we close files

  # read file until we see the first header line
  my ($next_header_line, $next_seqname) = ribo_FastaFileReadAndOutputNextSeq($in_FH, undef, $FH_HR); 
  # this will die if any non-whitespace characters exist before first header line

  while($nseq_remaining > 0) { 
    if(! defined $next_header_line) { 
      ofile_FAIL("ERROR in $sub_name, read too few sequences in $fa_file, read expected $tot_nseq", "RIBO", 1, $FH_HR); 
    }
    if(! exists $seqlen_HR->{$next_seqname}) { 
      ofile_FAIL("ERROR in $sub_name, no sequence length information exists for $next_seqname", "RIBO", 1, $FH_HR);
    }
    $nres_this_seq = $seqlen_HR->{$next_seqname};

    # first $nfiles sequences go to file $nseq_output so we guarantee we have >= 1 seq per file, 
    # remaining seqs are randomly placed
    if($nseq_output < $nfiles) { 
      $fidx = $nseq_output;
      $ridx = $f2r_map_A[$fidx];
    }
    else { 
      $ridx = int(rand($nopen)); 
      $fidx = $r2f_map_A[$ridx];
    }
    $FH = $out_FH_A[$fidx];

    # output seq
    print $FH $next_header_line; 
    ($next_header_line, $next_seqname) = ribo_FastaFileReadAndOutputNextSeq($in_FH, $FH, $FH_HR);
    
    $nseq_remaining--;
    $nseq_output++;
    
    # update counts of sequences and residues for the file we just printed to
    $nres_per_out_A[$fidx] += $nres_this_seq;
    $nseq_per_out_A[$fidx]++;
    $nres_tot_out += $nres_this_seq;

    # if we've reached our checkpoint output update
    if($do_debug && ($nres_tot_out > $checkpoint_nres)) { 
      my $nfiles_above_fract = 0;
      for(my $tmp_fidx = 0; $tmp_fidx < $nfiles; $tmp_fidx++) { 
        if($nres_per_out_A[$tmp_fidx] > ($checkpoint_fraction * $targ_nres)) { $nfiles_above_fract++; }
      }
      $checkpoint_fraction += $checkpoint_fraction_step;
      $checkpoint_nres = $checkpoint_fraction * $tot_nres;
    }

    # check if we need to close this file now, if so close it and open a new one (if nec)
    if(($nres_per_out_A[$fidx] >= $targ_nres) || ($nseq_remaining == 0)) { 
      if(($nopen > 1) || ($nseq_remaining == 0)) { 
        # don't close the final file unless we have zero sequences left
        close($out_FH_A[$fidx]);
        $isopen_A[$fidx] = 0;
        if($do_debug) { printf("$out_filename_A[$fidx] finished (%d seqs, %d residues)\n", $nseq_per_out_A[$fidx], $nres_per_out_A[$fidx]); }
        # update r2f_map_A so we can no longer choose the file handle we just closed 
        if($ridx != ($nopen-1)) { # edge case
          $r2f_map_A[$ridx] = $r2f_map_A[($nopen-1)];
        }
        $f2r_map_A[$r2f_map_A[($nopen-1)]] = $ridx; 
        $r2f_map_A[($nopen-1)] = -1; # this random index is now invalid
        $f2r_map_A[$fidx]      = -1; # this file is now closed
        $nopen--;
      }
    }
  }

  # go through and close any files that are still open
  for($fidx = 0; $fidx < $nfiles; $fidx++) { 
    if($isopen_A[$fidx] == 1) { 
      # file still open, close it
      close($out_FH_A[$fidx]);
      if($do_debug) { printf("$out_filename_A[$fidx] finished (%d seqs, %d residues)\n", $nseq_per_out_A[$fidx], $nres_per_out_A[$fidx]); }
    }
  }

  return $nfiles;
}

#################################################################
# Subroutine: ribo_FastaFileReadAndOutputNextSeq
# Incept:     EPN, Fri Jul  6 11:04:52 2018
#
# Purpose:    Given an open input file handle for a fasta sequence
#             and an open output file handle, read the next sequence and
#             and output it to the output file, by outputting all lines
#             we read until the next header line. Then return the
#             header line we stopped reading on.
#             If $out_FH is undef, do not output, which allows this
#             function to be called to return the first header line
#             of the file, but if $out_FH is undef, then require
#             that all lines read before the header line are empty,
#             else die.
#
# Arguments:
#   $in_FH:       input file handle
#   $out_FH:      output file handle, can be undef
#   $FH_HR:       ref to hash of file handles, for printing errors if we die"
# 
# Returns:  2 values:
#           $next_header_line: next header line in the file, undef 
#                              if we do not read one before end of the file
#           $next_seqname:     sequence name on next header line
#
# Dies:     If $out_FH is undef and there are non-whitespace characters
#           prior to the first header line read.
#           If $next_header_line is defined and we can't parse it to get the
#           sequence name.
#################################################################
sub ribo_FastaFileReadAndOutputNextSeq { 
  my $sub_name = "ribo_FastaFileReadAndOutputNextSeq";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_FH, $out_FH, $FH_HR) = @_;

  my $line = undef;
  $line = <$in_FH>;
  while((defined $line) && ($line !~ m/^\>/)) { 
    # does this line have any nonwhitespace characters? 
    if(! defined $out_FH) { 
      chomp $line;
      if($line =~ m/\S/) { 
        ofile_FAIL("ERROR in $sub_name, read line with non-whitespace character when none were expected:\n$line", "RIBO", 1, $FH_HR);
      }
    }
    else { 
      print $out_FH $line;
    }
    $line = <$in_FH>; 
  }
  my $seqname = undef;
  if(defined $line) { 
    if($line =~ m/^\>(\S+)/) { 
      $seqname = $1;
    }
    else { 
      ofile_FAIL("ERROR in $sub_name, unable to parse sequence name from header line: $line", "RIBO", 1, $FH_HR);
    }
  }
  
  return ($line, $seqname);
}

#################################################################
# Subroutine: ribo_WriteAcceptFile
# Incept:     EPN, Wed Jul 11 11:18:31 2018
#
# Purpose:    Given an array of acceptable models, create a ribotyper
#             input --accept file defining those models as acceptable.
#              
# Arguments: 
#   $AR:    reference to array of acceptable models
#   $file:  name of file to create
#   $FH_HR: ref to hash of file handles, including "cmd"
#
# Returns:  Nothing.
# 
# Dies:     If $AR is empty or we can't write to $file.
#
################################################################# 
sub ribo_WriteAcceptFile { 
  my $sub_name = "ribo_WriteAcceptFile()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($AR, $file, $FH_HR) = @_;
  
  my @accept_A = ();

  foreach my $el (@{$AR}) { 
    push (@accept_A, $el . " acceptable\n");
  }

  ribo_WriteArrayToFile(\@accept_A, $file, $FH_HR); # this will die if @accept_A is empty or we can't write to $file
  
  return;
}

#################################################################
# Subroutine: ribo_GetMonoCharacterString()
# Incept:     EPN, Thu Mar 10 21:02:35 2016 [dnaorg.pm]
#
# Purpose:    Return a string of length $len of repeated instances
#             of the character $char.
#
# Arguments:
#   $len:   desired length of the string to return
#   $char:  desired character
#   $FH_HR: ref to hash of file handles
#
# Returns:  A string of $char repeated $len times.
# 
# Dies:     if $len is not a positive integer
#
#################################################################
sub ribo_GetMonoCharacterString {
  my $sub_name = "ribo_GetMonoCharacterString";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($len, $char, $FH_HR) = @_;

  if(! verify_integer($len)) { 
    ofile_FAIL("ERROR in $sub_name, passed in length ($len) is not a non-negative integer", "RIBO", 1, $FH_HR);
  }
  if($len < 0) { 
    ofile("ERROR in $sub_name, passed in length ($len) is a negative integer", "RIBO", 1, $FH_HR);
  }
    
  my $ret_str = "";
  for(my $i = 0; $i < $len; $i++) { 
    $ret_str .= $char;
  }

  return $ret_str;
}

#################################################################
# Subroutine : ribo_NumberOfDigits()
# Incept:      EPN, Tue May  9 11:33:50 2017
#              EPN, Fri Nov 13 06:17:25 2009 [ssu-align:ssu.pm:NumberOfDigits()]
# 
# Purpose:     Return the number of digits in a number before
#              the decimal point. (ex: 1234.56 would return 4).
# Arguments:
# $num:        the number
# 
# Returns:     the number of digits before the decimal point
#
################################################################# 
sub ribo_NumberOfDigits { 
    my $nargs_expected = 1;
    my $sub_name = "ribo_NumberOfDigits()";
    if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

    my ($num) = (@_);

    my $ndig = 1; 
    while($num > 10) { $ndig++; $num /= 10.; }

    return $ndig;
}

#####################################################################
# Subroutine: ribo_GetTimeString()
# Incept:     EPN, Tue May  9 11:09:12 2017 
#             EPN, Tue Jun 16 08:52:08 2009 [ssu-align:ssu.pm:PrintTiming]
# 
# Purpose:    Print a timing in hhhh:mm:ss format.
# 
# Arguments:
# $inseconds: number of seconds
#
# Returns:    Nothing.
# 
####################################################################
sub ribo_GetTimeString { 
    my $nargs_expected = 1;
    my $sub_name = "ribo_GetTimeString()";
    if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
    
    my ($inseconds) = @_;

    my ($i, $hours, $minutes, $seconds, $thours, $tminutes, $tseconds, $ndig_hours);

    $hours = int($inseconds / 3600);
    $inseconds -= ($hours * 3600);
    $minutes = int($inseconds / 60);
    $inseconds -= ($minutes * 60);
    $seconds = $inseconds;
    $thours   = sprintf("%02d", $hours);
    $tminutes = sprintf("%02d", $minutes);
    $ndig_hours = ribo_NumberOfDigits($hours);
    if($ndig_hours < 2) { $ndig_hours = 2; }
    $tseconds = sprintf("%05.2f", $seconds);

    return sprintf("%*s:%2s:%5s  (hh:mm:ss)", $ndig_hours, $thours, $tminutes, $tseconds);
}

#################################################################
# Subroutine : ribo_GetDirPath()
# Incept:      EPN, Thu May  4 09:39:06 2017
#              EPN, Mon Mar 15 10:17:11 2010 [ssu.pm:ReturnDirPath()]
#
# Purpose:     Given a file name return the directory path, with the final '/'
#              For example: "foodir/foodir2/foo.stk" becomes "foodir/foodir2/".
#
# Arguments: 
#   $orig_file: name of original file
# 
# Returns:     The string $orig_file with actual file name removed 
#              or "./" if $orig_file is "".
#
################################################################# 
sub ribo_GetDirPath {
  my $narg_expected = 1;
  my $sub_name = "ribo_GetDirPath()";
  if(scalar(@_) != $narg_expected) { printf STDERR ("ERROR, in $sub_name, entered with %d != %d input arguments.\n", scalar(@_), $narg_expected); exit(1); } 
  my $orig_file = $_[0];
  
  $orig_file =~ s/[^\/]+$//; # remove final string of non '/' characters
  
  if($orig_file eq "") { return "./";       }
  else                 { return $orig_file; }
}

#################################################################
# Subroutine : ribo_RemoveDirPath()
# Incept:      EPN, Mon Nov  9 14:30:59 2009 [ssu-align]
#
# Purpose:     Given a full path of a file remove the directory path.
#              For example: "foodir/foodir2/foo.stk" becomes "foo.stk".
#
# Arguments: 
#   $fullpath: name of original file
# 
# Returns:     The string $fullpath with dir path removed.
#
################################################################# 
sub ribo_RemoveDirPath {
  my $sub_name = "ribo_RemoveDirPath()";
  my $nargs_expected = 1;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my $fullpath = $_[0];
  
  $fullpath =~ s/^.+\///;

  return $fullpath;
}

#################################################################
# Subroutine : ribo_ConvertFetchedNameToAccVersion()
# Incept:      EPN, Tue May 29 11:12:58 2018
#
# Purpose:     Given a 'fetched' GenBank sequence name, e.g.
#              gi|675602128|gb|KJ925573.1|, convert it to 
#              just accession version.
#
# Arguments: 
#   $fetched_name: name of sequence
#   $do_die:       '1' to die if the $fetch_name doesn't match the 
#                  expected format
#   $FH_HR:        ref to hash of file handles
#
# Returns: $accver_name: accession version format of the name
#          or $fetched_name if $fetched_name doesn't match 
#          expected format and $do_die is '0'.
# 
# Dies: if $do_die and expected name doesn't match the expected format
#
################################################################# 
sub ribo_ConvertFetchedNameToAccVersion {
  my $sub_name = "ribo_ConvertFetchedNameToAccVersion()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($fetched_name, $do_die, $FH_HR) = (@_);
  
  # example: gi|675602128|gb|KJ925573.1|
  my $accver_name = undef;
  if($fetched_name =~ /^gi\|\d+\|\S+\|(\S+\.\d+)\|.*/) { 
    $accver_name = $1;
  }
  else { 
    if($do_die) { 
      ofile_FAIL("ERROR, in $sub_name, $fetched_name did not match the expected format for a fetched sequence, expect something like: gi|675602128|gb|KJ925573.1|", "RIBO", 1, $FH_HR); 
    }
    $accver_name = $fetched_name;
  }
     
  return $accver_name;
}

#################################################################
# Subroutine: ribo_RunCmsearchOrCmalign
# Incept:     EPN, Thu Jul  5 15:05:53 2018
#
# Purpose:    Perform a search using cmsearch and store information 
#             on the output files
#
# Arguments:
#   $executable:     path to cmsearch or cmalign executable
#   $qsub_prefix:    qsub command prefix to use when submitting to farm, undef to run locally
#   $qsub_suffix:    qsub command suffix to use when submitting to farm, undef to run locally
#   $model_file:     path to model file to use 
#   $seq_file:       sequence file to search against
#   $opts:           options to provide to cmsearch or cmalign
#   $file_HR:        ref to hash, 
#                    if $executable eq "cmsearch", keys must be "tblout" and "cmsearch"
#                    if $executable eq "cmalign",  keys must be "ifile", "elfile", "stk", "cmalign", and "seqlist"
#   $opt_HHR:        ref to 2D hash of cmdline options
#   $ofile_info_HHR: ref to the ofile info 2D hash
#
# Returns:  void
# 
# Dies:     Never
#
#################################################################
sub ribo_RunCmsearchOrCmalign { 
  my $sub_name = "ribo_RunCmsearchOrCmalign()";
  my $nargs_expected = 9;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($executable, $qsub_prefix, $qsub_suffix, $model_file, $seq_file, $opts, $file_HR, $opt_HHR, $ofile_info_HHR) = @_;

  # we can only pass $FH_HR to ofile_FAIL if that hash already exists
  my $FH_HR = (defined $ofile_info_HHR->{"FH"}) ? $ofile_info_HHR->{"FH"} : undef;
  my @reqd_file_keys = (); # array of required outfile_HR keys for this executable program
  my $file_key = undef;    # a single outfile key

  ribo_CheckIfFileExistsAndIsNonEmpty($seq_file,   undef, $sub_name, 1, $FH_HR); 
  ribo_CheckIfFileExistsAndIsNonEmpty($model_file, undef, $sub_name, 1, $FH_HR); 

  # determine if we have the appropriate paths defined in %{$file_HR} 
  # depending on if $executable is "cmalign" or "cmsearch"
  if($executable =~ /cmsearch$/) { 
    @reqd_file_keys = ("cmsearch", "tblout");
  }
  elsif($executable =~ /cmalign$/) { 
    @reqd_file_keys = ("cmalign", "stk", "ifile", "elfile", "seqlist");
  }
  else { 
    ofile_FAIL("ERROR in $sub_name, chosen executable $executable is not cmsearch or cmalign", "RIBO", 1, $FH_HR);
  }
  foreach $file_key (@reqd_file_keys) { 
    if(! exists $file_HR->{$file_key})  { ofile_FAIL("ERROR in $sub_name, executable is $executable but $file_key file not set", "RIBO", 1, $FH_HR); }
    # remove this file if it already exists
    if(-e $file_HR->{$file_key}) { ribo_RemoveFileUsingSystemRm($file_HR->{$file_key}, $sub_name, $opt_HHR, $ofile_info_HHR); }
  } 

  # determine if we are running on the farm or locally
  my $cmd = "";
  my $do_local = 1;
  my $cmd_suffix = "";
  if((defined $qsub_prefix) && (defined $qsub_suffix)) { 
    $cmd = $qsub_prefix;
    $cmd_suffix = $qsub_suffix;
    # replace ![errfile]! with $errfile
    # replace ![jobname]! with $jobname
    my $jobname = "j" . ribo_RemoveDirPath($seq_file);
    my $errfile = $seq_file . ".err";
    if(-e $errfile) { ribo_RemoveFileUsingSystemRm($errfile, $sub_name, $opt_HHR, $ofile_info_HHR); }
    $cmd =~ s/\!\[errfile\]\!/$errfile/g;
    $cmd =~ s/\!\[jobname\]\!/$jobname/g;
    $do_local = 0;
  }

  # determine if we have the appropriate paths defined in %{$file_HR} 
  # depending on if $executable is "cmalign" or "cmsearch"
  # and run the program
  if($executable =~ /cmsearch$/) { 
    $cmd .= "$executable $opts --tblout " . $file_HR->{"tblout"} . " $model_file $seq_file > " . $file_HR->{"cmsearch"} . $cmd_suffix;
  }
  elsif($executable =~ /cmalign$/) { 
    $cmd .= "$executable $opts --ifile " . $file_HR->{"ifile"} . " --elfile " . $file_HR->{"elfile"} . " -o " . $file_HR->{"stk"} . " $model_file $seq_file > " . $file_HR->{"cmalign"} . $cmd_suffix;
  }

  # either run command locally and wait for it to complete (if ! defined $qsub_prefix)
  # else submit it to the farm and return, caller will deal with monitoring it
  ribo_RunCommand($cmd, opt_Get("-v", $opt_HHR), $FH_HR);

  return;
}

#################################################################
# Subroutine:  ribo_RunCmsearchOrCmalignWrapper()
# Incept:      EPN, Thu Jul  5 15:24:19 2018
#
# Purpose:     Run one or more cmsearch jobs on the farm
#              or locally, after possibly splitting up the input
#              sequence file. 
#              The following must all be valid options in opt_HHR:
#              -p, --nkb, -s, --wait, --errcheck, --keep, -v
#              See ribotyper.pl for examples of these options.
#
# Arguments: 
#  $execs_HR:        ref to hash with paths to executables
#  $program_choice:  "cmalign" or "cmsearch"
#  $qsub_prefix:     qsub command prefix to use when submitting to farm, if -p
#  $qsub_suffix:     qsub command suffix to use when submitting to farm, if -p
#  $seqlen_HR:       ref to hash of sequence lengths, key is sequence name, value is length
#  $progress_w:      width for outputProgressPrior output
#  $out_root:        output root for naming sequence files
#  $model_file:      path to model file to use 
#  $seq_file:        name of sequence file with all sequences to run against
#  $tot_nseq:        number of sequences in $seq_file
#  $tot_len_nt:      total length of all nucleotides in $seq_file
#  $opts:            string of cmsearch or cmalign options
#  $file_HR:         ref to hash, 
#                    if $executable eq "cmsearch", keys must be "tblout" and "cmsearch"
#                    if $executable eq "cmalign",  keys must be "ifile", "elfile", "stk", "cmalign", and "seqlist"
#  $opt_HHR:         REF to 2D hash of option values, see top of epn-options.pm for description
#  $ofile_info_HHR:  REF to 2D hash of output file information
#
# Returns:     void
# 
# Dies: If an executable doesn't exist, or cmsearch command fails if we're running locally
################################################################# 
sub ribo_RunCmsearchOrCmalignWrapper { 
  my $sub_name = "ribo_RunCmsearchOrCmalignWrapper";
  my $nargs_expected = 15;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($execs_HR, $program_choice, $qsub_prefix, $qsub_suffix, $seqlen_HR, $progress_w, $out_root, $model_file, $seq_file, $tot_nseq, $tot_len_nt, $opts, $file_HR, $opt_HHR, $ofile_info_HHR) = @_;

  my $FH_HR  = $ofile_info_HHR->{"FH"}; # for convenience
  my $log_FH = $ofile_info_HHR->{"FH"}{"log"}; # for convenience
  my $start_secs; # timing start
  my $out_dir = ribo_GetDirPath($out_root);
  my $executable = undef;     # path to the cmsearch or cmalign executable
  my @reqd_file_keys = (); # array of required file_HR keys for this executable program
  my $file_key = undef;    # a single outfile key
  my $wait_key = undef;       # outfile key that ribo_WaitForFarmJobsToFinish will use to check if jobs are done
  my $wait_str = undef;       # string in output file that ribo_WaitForFarmJobsToFinish will check for to see if jobs are done

  # determine if we have the appropriate paths defined in %{$file_HR} 
  # depending on if $executable is "cmalign" or "cmsearch"
  if($program_choice eq "cmsearch") { 
    $executable = $execs_HR->{"cmsearch"};
    @reqd_file_keys = ("cmsearch", "tblout");
    $wait_key = "tblout";
    $wait_str = "[ok]";
  }
  elsif($program_choice eq "cmalign") { 
    $executable = $execs_HR->{"cmalign"};
    @reqd_file_keys = ("cmalign", "stk", "ifile", "elfile", "seqlist");
    $wait_key = "cmalign";
    $wait_str = "# CPU time:";
  }
  else { 
    ofile_FAIL("ERROR in $sub_name, chosen executable $executable is not cmsearch or cmalign", "RIBO", 1, $FH_HR);
  }
  foreach $file_key (@reqd_file_keys) { 
    if(! exists $file_HR->{$file_key})  { ofile_FAIL("ERROR in $sub_name, executable is $executable but $file_key file not set", "RIBO", 1, $FH_HR); }
  } 

  if(! opt_Get("-p", $opt_HHR)) { 
    # run job locally
    ribo_RunCmsearchOrCmalign($executable, undef, undef, $model_file, $seq_file, $opts, $file_HR, $opt_HHR, $ofile_info_HHR); # undefs: run locally
  }
  else { 
    my %tmp_outfile_HA = (); # hash of arrays of temporary files for all jobs to concatenate or otherwise combine, and then remove
    my %tmp_outfile_H  = (); # hash of temporary files for one job

    # we need to split up the sequence file, and submit a separate set of cmsearch/cmalign jobs for each file
    my $nfasta_created = ribo_FastaFileSplitRandomly($seq_file, $seqlen_HR, $out_dir, $tot_nseq, $tot_len_nt, opt_Get("--nkb", $opt_HHR) * 1000, opt_Get("-s", $opt_HHR), $ofile_info_HHR->{"FH"});

    # submit all jobs to the farm
    for(my $f = 1; $f <= $nfasta_created; $f++) { 
      %tmp_outfile_H = ();
      my $seq_file_tail = ribo_RemoveDirPath($seq_file);
      my $tmp_seq_file  = $out_dir . "/." . $seq_file_tail . "." . $f;
      foreach $file_key ((@reqd_file_keys), "err") { 
        $tmp_outfile_H{$file_key} = $tmp_seq_file . "." . $file_key;
        push(@{$tmp_outfile_HA{$file_key}}, $tmp_outfile_H{$file_key});
      }
      ribo_RunCmsearchOrCmalign($executable, $qsub_prefix, $qsub_suffix, $model_file, $tmp_seq_file, $opts, \%tmp_outfile_H, $opt_HHR, $ofile_info_HHR); 
    }
    
    # wait for the jobs to finish
    ofile_OutputString($log_FH, 0, sprintf("\n"));
    print STDERR "\n";
    $start_secs = ofile_OutputProgressPrior(sprintf("Waiting a maximum of %d minutes for all $nfasta_created $program_choice farm jobs to finish", opt_Get("--wait", $opt_HHR)), 
                                           $progress_w, $log_FH, *STDERR);
    my $njobs_finished = ribo_WaitForFarmJobsToFinish($tmp_outfile_HA{$wait_key}, $tmp_outfile_HA{"err"}, $wait_str, opt_Get("--wait", $opt_HHR), opt_Get("--errcheck", $opt_HHR), $ofile_info_HHR->{"FH"});
    if($njobs_finished != $nfasta_created) { 
      ofile_FAIL(sprintf("ERROR in $sub_name only $njobs_finished of the $nfasta_created are finished after %d minutes. Increase wait time limit with --wait", opt_Get("--wait", $opt_HHR)), 1, $ofile_info_HHR->{"FH"});
    }
    ofile_OutputString($log_FH, 1, "# "); # necessary because waitForFarmJobsToFinish() creates lines that summarize wait time and so we need a '#' before 'done' printed by outputProgressComplete()

    # concatenate/merge files into one 
    foreach $file_key (@reqd_file_keys) { 
      if($file_key eq "stk") { # special case
        ribo_MergeAlignmentsAndReorder($execs_HR, $tmp_outfile_HA{$file_key}, $file_HR->{$file_key}, $file_HR->{"seqlist"}, $opt_HHR, $ofile_info_HHR);
      }
      elsif($file_key ne "seqlist") { # another special case, don't concatenate seqlist files
        ribo_ConcatenateListOfFiles($tmp_outfile_HA{$file_key}, $file_HR->{$file_key}, $sub_name, $opt_HHR, $ofile_info_HHR->{"FH"});
      }
    }

    # remove temporary files if --keep not enabled
    if(! opt_Get("--keep", $opt_HHR)) { 
      foreach $file_key ((@reqd_file_keys), "err") { 
        foreach my $tmp_file (@{$tmp_outfile_HA{$file_key}}) {
          if(-e $tmp_file) { 
            ribo_RemoveFileUsingSystemRm($tmp_file, $sub_name, $opt_HHR, $ofile_info_HHR->{"FH"});
          }
        }
      }
    }
  } # end of 'else' entered if -p used

  return;
}

#################################################################
# Subroutine:  ribo_MergeAlignmentsAndReorder()
# Incept:      EPN, Tue Jul 10 09:14:49 2018
#
# Purpose:     Given an array of alignment files, merge them into one
#              and reorder all sequences to the order in the file 
#              $seqlist.
#
# Arguments: 
#  $execs_HR:        ref to hash with paths to executables
#  $AR:              ref to array of files to merge
#  $merged_stk_file: path to merged stk file to create
#  $seqlist_file:    file with list of all sequences in the correct order
#  $opt_HHR:         REF to 2D hash of option values, see top of epn-options.pm for description
#  $ofile_info_HHR:  REF to 2D hash of output file information
#
# Returns:     void
# 
# Dies: If esl-alimerge fails
################################################################# 
sub ribo_MergeAlignmentsAndReorder { 
  my $sub_name = "ribo_MergeAlignmentsAndReorder";
  my $nargs_expected = 6;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($execs_HR, $AR, $merged_stk_file, $seqlist_file, $opt_HHR, $ofile_info_HHR) = @_;

  my $FH_HR  = $ofile_info_HHR->{"FH"}; # for convenience
  my $log_FH = $ofile_info_HHR->{"FH"}{"log"}; # for convenience

  # create list file 
  my $list_file = $merged_stk_file . ".list";
  ribo_WriteArrayToFile($AR, $list_file, $FH_HR);

  # merge the alignments with esl-alimerge
  ribo_RunCommand($execs_HR->{"esl-alimerge"} . " --list $list_file | " . $execs_HR->{"esl-alimanip"} . " --seq-k $seqlist_file --k-reorder --outformat pfam - > $merged_stk_file", opt_Get("-v", $opt_HHR), $FH_HR);

  if(opt_Get("--keep", $opt_HHR)) { 
    ofile_AddClosedFileToOutputInfo($ofile_info_HHR, "RIBO", "$merged_stk_file.list", $merged_stk_file, 0, "list of alignment files merged to create " . ribo_RemoveDirPath($merged_stk_file));
  }
  else { 
    ribo_RemoveFileUsingSystemRm($list_file, $sub_name, $opt_HHR, $FH_HR);
  }

  # caller is responsible for adding merged_stk_file to OutputInfo

  return;
}
#################################################################
# Subroutine : ribo_WaitForFarmJobsToFinish()
# Incept:      EPN, Thu Jul  5 14:45:46 2018
#              EPN, Mon Feb 29 16:20:54 2016 [dnaorg_scripts:waitForFarmJobsToFinish()]
#
# Purpose: Wait for jobs on the farm to finish by checking the final
#          line of their output files (in @{$outfile_AR}) to see
#          if the final line is exactly the string
#          $finished_string. We'll wait a maximum of $nmin
#          minutes, then return the number of jobs that have
#          finished. If all jobs finish before $nmin minutes we
#          return at that point.
#
#          A job is considered 'finished in error' if it outputs
#          anything to its err file in @{$errfile_AR}. (We do not kill
#          the job, although for the jobs we are monitoring with this
#          subroutine, it should already have died (though we don't
#          guarantee that in anyway).) If any jobs 'finish in error'
#          this subroutine will continue until all jobs have finished
#          or we've waited $nmin minutes and then it will cause the
#          program to exit in error and output an error message
#          listing the jobs that have 'finished in error'
#          
#          When $do_errcheck is 1, this function considers any output
#          written to stderr output files in @{$errfile_AR} to mean
#          that the corresponding job has 'failed' and should be
#          considered to have finished. When $do_errchecks is 0
#          we don't look at the err files.
# 
#
# Arguments: 
#  $outfile_AR:      ref to array of output files that will be created by jobs we are waiting for
#  $errfile_AR:      ref to array of err files that will be created by jobs we are waiting for if 
#                    any stderr output is created
#  $finished_str:    string that indicates a job is finished e.g. "[ok]"
#  $nmin:            number of minutes to wait
#  $do_errcheck:     '1' to consider output to an error file a 'failure' of a job, '0' not to.
#  $FH_HR:           REF to hash of file handles
#
# Returns:     Number of jobs (<= scalar(@{$outfile_AR})) that have
#              finished.
# 
# Dies: never.
#
################################################################# 
sub ribo_WaitForFarmJobsToFinish { 
  my $sub_name = "ribo_WaitForFarmJobsToFinish()";
  my $nargs_expected = 6;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($outfile_AR, $errfile_AR, $finished_str, $nmin, $do_errcheck, $FH_HR) = @_;

  my $log_FH = $FH_HR->{"log"};

  my $njobs = scalar(@{$outfile_AR});
  if($njobs != scalar(@{$errfile_AR})) { 
    ofile_FAIL(sprintf("ERROR in $sub_name, number of elements in outfile array ($njobs) differ from number of jobs in errfile array (%d)", scalar(@{$errfile_AR})), 1, $FH_HR);
  }
  my @is_finished_A  = ();  # $is_finished_A[$i] is 1 if job $i is finished (either successfully or having failed), else 0
  my @is_failed_A    = ();  # $is_failed_A[$i] is 1 if job $i has finished and failed (all failed jobs are considered 
                            # to be finished), else 0. We only use this array if the --errcheck option is enabled.
  my $nfinished      = 0;   # number of jobs finished
  my $nfail          = 0;   # number of jobs that have failed
  my $cur_sleep_secs = 15;  # number of seconds to wait between checks, we'll double this until we reach $max_sleep, every $doubling_secs seconds
  my $doubling_secs  = 120; # number of seconds to wait before doublign $cur_sleep
  my $max_sleep_secs = 120; # maximum number of seconds we'll wait between checks
  my $secs_waited    = 0;   # number of total seconds we've waited thus far

  # initialize @is_finished_A to all '0's
  for(my $i = 0; $i < $njobs; $i++) { 
    $is_finished_A[$i] = 0;
    $is_failed_A[$i] = 0;
  }

  my $keep_going = 1;  # set to 0 if all jobs are finished
  ofile_OutputString($log_FH, 0, "\n");
  print STDERR "\n";
  while(($secs_waited < (($nmin * 60) + $cur_sleep_secs)) && # we add $cur_sleep so we check one final time before exiting after time limit is reached
        ($keep_going)) { 
    # check to see if jobs are finished, every $cur_sleep seconds
    sleep($cur_sleep_secs);
    $secs_waited += $cur_sleep_secs;
    if($secs_waited >= $doubling_secs) { 
      $cur_sleep_secs *= 2;
      if($cur_sleep_secs > $max_sleep_secs) { # reset to max if we've exceeded it
        $cur_sleep_secs = $max_sleep_secs;
      }
    }

    for(my $i = 0; $i < $njobs; $i++) { 
      if(! $is_finished_A[$i]) { 
        if(-s $outfile_AR->[$i]) { 
          my $final_line = `tail -n 1 $outfile_AR->[$i]`;
          chomp $final_line;
          if($final_line =~ m/\r$/) { chop $final_line; } # remove ^M if it exists
          if($final_line =~ m/\Q$finished_str\E/) { 
            $is_finished_A[$i] = 1;
            $nfinished++;
          }
        }
        if(($do_errcheck) && (-s $errfile_AR->[$i])) { # errfile exists and is non-empty, this is a failure, even if we saw $finished_str above
          if(! $is_finished_A[$i]) { 
            $nfinished++;
          }
          $is_finished_A[$i] = 1;
          $is_failed_A[$i] = 1;
          $nfail++;
        }
      }
    }

    # output update
    ofile_OutputString($log_FH, 0, sprintf("#\t%4d of %4d jobs finished (%.1f minutes spent waiting)\n", $nfinished, $njobs, $secs_waited / 60.));
    printf STDERR ("#\t%4d of %4d jobs finished (%.1f minutes spent waiting)\n", $nfinished, $njobs, $secs_waited / 60.);

    if($nfinished == $njobs) { 
      # we're done break out of it
      $keep_going = 0;
    }
  }

  if($nfail > 0) { 
    # construct error message
    my $errmsg = "ERROR in $sub_name, $nfail of $njobs finished in error (output to their respective error files).\n";
    $errmsg .= "Specifically the jobs that were supposed to create the following output and err files:\n";
    for(my $i = 0; $i < $njobs; $i++) { 
      if($is_failed_A[$i]) { 
        $errmsg .= "\t$outfile_AR->[$i]\t$errfile_AR->[$i]\n";
      }
    }
    ofile_FAIL($errmsg, 1, $FH_HR);
  }

  # if we get here we have no failures
  return $nfinished;
}

#################################################################
# Subroutine:  ribo_RunCommand()
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
sub ribo_RunCommand {
  my $sub_name = "ribo_RunCommand()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmd, $be_verbose, $FH_HR) = @_;
  
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
    ofile_FAIL("ERROR in $sub_name, the following command failed:\n$cmd\n", "RIBO", $?, $FH_HR);
  }

  return ($stop_time - $start_time);
}

#################################################################
# Subroutine : ribo_SecondsSinceEpoch()
# Incept:      EPN, Sat Feb 13 06:17:03 2016
#
# Purpose:     Return the seconds and microseconds since the 
#              Unix epoch (Jan 1, 1970) using 
#              Time::HiRes::gettimeofday().
#
# Arguments:   NONE
# 
# Returns:     Number of seconds and microseconds
#              since the epoch.
#
################################################################# 
sub ribo_SecondsSinceEpoch { 
  my $nargs_expected = 0;
  my $sub_name = "ribo_SecondsSinceEpoch()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seconds, $microseconds) = gettimeofday();
  return ($seconds + ($microseconds / 1000000.));
}

#################################################################
# Subroutine : ribo_FindNonNumericValueInArray()
# Incept:      EPN, Tue Feb 16 10:40:57 2016
#
# Purpose:     Returns (first) index in @{$AR} that has the 
#              nonnumeric value $value. Returns -1 
#              if it does not exist.
#
# Arguments: 
#   $AR:       REF to array 
#   $value:    the value we're checking exists in @{$AR}
#   $FH_HR:    REF to hash of file handles, including "log" and "cmd"
# 
# Returns:     index ($i) '1' if $value exists in @{$AR}, '-1' if not
#
# Dies:        if $value is numeric, or @{$AR} is not defined.
################################################################# 
sub ribo_FindNonNumericValueInArray { 
  my $nargs_expected = 3;
  my $sub_name = "findNonNumericValueInArray()";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 
  my ($AR, $value, $FH_HR) = @_;

  if(verify_real($value)) { 
    ofile_FAIL("ERROR in $sub_name, value $value seems to be numeric, we can't compare it for equality", 1, $FH_HR);
  }

  if(! defined $AR) { 
    ofile_FAIL("ERROR in $sub_name, array reference is not defined", 1, $FH_HR);
  }

  for(my $i = 0; $i < scalar(@{$AR}); $i++) {
    if($AR->[$i] eq $value) { 
      return $i; 
    }
  }

  return -1; # did not find it
}

#################################################################
# Subroutine: ribo_SumSeqlenGivenArray
# Incept:     EPN, Fri Jul  6 09:30:43 2018
#
# Purpose:    Given an array of sequence names and a hash with 
#             lengths for each, return total length for all 
#             sequences.
#
# Arguments:
#   $seqname_AR:  ref to array of sequence names
#   $seqlen_HR:   ref to hash, key is sequence name, 
#                 value is length
#   $FH_HR:       ref to hash of file handles, including "cmd"
#
# Returns:  void
# 
# Dies:     If sequence listed in @{$seqname_AR} is not in %{$seqlen_HR}
#
#################################################################
sub ribo_SumSeqlenGivenArray { 
  my $sub_name = "ribo_SumSeqlenGivenArray()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seqname_AR, $seqlen_HR, $FH_HR) = @_;
  
  my $tot_seqlen = 0;
  foreach my $seqname (@{$seqname_AR}) { 
    if(! exists $seqlen_HR->{$seqname}) { 
      ofile_FAIL("ERROR in $sub_name, $seqname does not exist in the seqlen_H hash", "RIBO", 1, $FH_HR);
    }
    $tot_seqlen += abs($seqlen_HR->{$seqname}); # ribotyper.pl multiplies lengths by -1 after round 1
  }

  return $tot_seqlen;
}
#################################################################
# Subroutine:  ribo_InitializeHashToEmptyString()
# Incept:      EPN, Wed Jun 20 14:29:28 2018
#
# Purpose:     Initialize all values of a hash to the empty string.
#
# Arguments:
#   $HR:  ref to hash to fill with empty string values for all keys in @{$AR}
#   $AR:  ref to array with all keys to create for $HR
#
# Returns:    void
#
# Dies: void
# 
#################################################################
sub ribo_InitializeHashToEmptyString {
  my $sub_name = "ribo_InitializeHashToEmptyString()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($HR, $AR) = (@_);

  %{$HR} = (); 
  foreach my $key (@{$AR}) { 
    $HR->{$key} = "";
  }

  return;
}

#################################################################
# Subroutine:  ribo_InitializeHashToZero()
# Incept:      EPN, Wed Jun 27 12:28:04 2018
#
# Purpose:     Initialize all values of a hash to 0
#
# Arguments:
#   $HR:  ref to hash to fill with empty string values for all keys in @{$AR}
#   $AR:  ref to array with all keys to create for $HR
#
# Returns:    void
#
# Dies: void
# 
#################################################################
sub ribo_InitializeHashToZero { 
  my $sub_name = "ribo_InitializeHashToZero()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($HR, $AR) = (@_);

  %{$HR} = (); 
  foreach my $key (@{$AR}) { 
    $HR->{$key} = 0;
  }

  return;
}

###########################################################################
# the next line is critical, a perl module must return a true value
return 1;
###########################################################################

