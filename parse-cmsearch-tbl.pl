use strict;

my $usage = "perl ribotyper-parse.pl <esl-seqstat file> <clan/domain info input file> <tabular search results> <output file name>";
if(scalar(@ARGV) != 4) { 
  die $usage;
}

my ($seqstat_file, $clan_file, $tbl_file, $out_file) = (@ARGV);

my %one_model_H;
my %one_score_H;
my %one_evalue_H;
my %one_start_H;
my %one_stop_H;
my %one_strand_H;
my %two_model_H;
my %two_score_H;
my %two_evalue_H;
my %two_start_H;
my %two_stop_H;
my %two_strand_H;

my @clan_names_A = ();   # array of clan names,   all values in clan_H,   in order they are read from $clan_file
my @domain_names_A = (); # array of domain names, all values in domain_H, in order they are read from $clan_file
my %clan_H = ();   # hash of clans,   key: model name, value: name of clan model belongs to (e.g. SSU)
my %domain_H = (); # hash of domains, key: model name, value: name of domain model belongs to (e.g. Archaea)

parse_clan_file($clan_file, \@clan_names_A, \%clan_H, \@domain_names_A, \%domain_H);

my $prv_target = undef; # initialize 
my $clan = undef;

my %seqlen_H = (); # key: sequence name, value: length of sequence, 
                   # value set to -1 after we output info for this sequence
                   # and then serves as flag for: "we output this sequence 
                   # already, if we see it again we know the tbl file was not
                   # sorted properly.
parse_seqstat_file($seqstat_file, \%seqlen_H); 

# expects sorted output, sorted by column 1, the 'target name' column
# will detect if file is not sorted
open(IN, $tbl_file) || die "ERROR unable to open $tbl_file for reading";
my $longout_FH;
open($longout_FH, ">", $out_file) || die "ERROR unable to open $out_file for writing";
my $shortout_FH = \*STDOUT;

init_vars(\%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H);
init_vars(\%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);

while(my $line = <IN>) { 
  chomp $line;
##target name             accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
##----------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#lcl|dna_BP444_24.8k:251  -         SSU_rRNA_archaea     RF01959   hmm        3     1443        2     1436      +     -    6 0.53   6.0 1078.9         0 !   -

  if($line =~ m/^\#/) { 
    die "ERROR, found line that begins with #, input should have these lines removed and be sorted by the first column:$line.";
  }
  my @el_A = split(/\s+/, $line);
  if(scalar(@el_A) < 18) { 
    die "ERROR found less than 18 columns at line: $line";
  }
  my ($target, $model, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue) = 
      ($el_A[0], $el_A[2], $el_A[5], $el_A[6], $el_A[7], $el_A[8], $el_A[9],  $el_A[14], $el_A[15]);

  $clan = $clan_H{$model};
  if(! defined $clan) { 
    die "ERROR unrecognized model $model";
  }

  # two sanity checks:
  # make sure we have sequence length information for this sequence
  if(! exists $seqlen_H{$target}) { 
    die "ERROR found sequence $target we didn't read length information for in $seqstat_file";
  }
  # make sure we haven't output information for this sequence already
  if($seqlen_H{$target} == -1) { 
    die "ERROR found line with target previously output, did you sort by first column?";
  }

  # Are we now finished with the previous sequence? Yes, if target sequence we just read is different from it
  if((defined $prv_target) && ($prv_target ne $target)) { 
    # if so, output its current info
    output($longout_FH, 0, \%domain_H, $prv_target, $seqlen_H{$prv_target}, 
           \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
           \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
    output($shortout_FH, 1, \%domain_H, $prv_target, $seqlen_H{$prv_target}, 
           \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
           \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
    $seqlen_H{$prv_target} = -1; # serves as a flag that we output info for this sequence
    # reset vars
    init_vars(\%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H);
    init_vars(\%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
  }
  
  # is this a new 'one' hit (top scoring model)?
  if((! defined $one_evalue_H{$clan}) || # we don't yet have a 'one' model, use this one
     ($evalue < $one_evalue_H{$clan}) || # this E-value is better than (less than) our current 'one' E-value
     ($evalue eq $one_evalue_H{$clan} && $score > $one_score_H{$clan})) { # this E-value equals current 'one' E-value, but this score is better than current 'one' score
    # new 'one' hit, update 'one' variables, 
    # but first copy existing 'one' hit values to 'two', if 'one' hit is defined and it's a different model than current $model
    if(defined $one_model_H{$clan} && $one_model_H{$clan} ne $model) { 
      set_vars($clan, \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H, 
               $one_model_H{$clan},   $one_score_H{$clan},  $one_evalue_H{$clan},  $one_start_H{$clan},  $one_stop_H{$clan},  $one_strand_H{$clan});
    }
    # now set new 'one' hit values
    set_vars($clan, \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
             $model,       $score,      $evalue,      $seqfrom,    $seqto,     $strand);
  }
  else { # not a new 'one' hit
    # is this a new 'two' hit (second-best scoring model)?
    if(($model ne $one_model_H{$clan}) &&   # this is not the same model as model one
       (($evalue < $two_evalue_H{$clan}) || # this E-value is better than (less than) our current 'two' E-value
        ($evalue eq $two_evalue_H{$clan} && $score > $two_score_H{$clan}))) { # this E-value equals current 'two' E-value, but this score is better than current 'two' score
      # new 'two' hit, set it
      set_vars($clan, \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H, 
               $model,       $score,      $evalue,      $seqfrom,    $seqto,     $strand);
    }
  }
  $prv_target = $target;

  # sanity check
  if((defined $one_model_H{$clan} && defined $two_model_H{$clan}) && ($one_model_H{$clan} eq $two_model_H{$clan})) { 
    die "ERROR, coding error, one_model and two_model are identical for $clan $target";
  }
}
# output data for final sequence
output($longout_FH, 0, \%domain_H, $prv_target, $seqlen_H{$prv_target},
       \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
       \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
output($shortout_FH, 1, \%domain_H, $prv_target, $seqlen_H{$prv_target},
       \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
       \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);


$seqlen_H{$prv_target} = -1; # not really necessary, since we're done

close $longout_FH;

#################################################################
# Subroutine : init_vars()
# Incept:      EPN, Tue Dec 13 14:53:37 2016
#
# Purpose:     Initialize variables to undefined 
#              given references to them.
#              
# Arguments: 
#   $model_HR:   REF to $model variable hash, a model name
#   $score_HR:   REF to $score variable hash, a bit score
#   $evalue_HR:  REF to $evalue variable hash, an E-value
#   $start_HR:   REF to $start variable hash, a start position
#   $stop_HR:    REF to $stop variable hash, a stop position
#   $strand_HR:  REF to $strand variable hash, a strand
# 
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub init_vars { 
  my $nargs_expected = 6;
  my $sub_name = "init_vars";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($model_HR, $score_HR, $evalue_HR, $start_HR, $stop_HR, $strand_HR) = @_;

  foreach my $key (keys %{$model_HR}) { 
    $model_HR->{$key}  = undef;
    $score_HR->{$key}  = undef;
    $evalue_HR->{$key} = undef;
    $start_HR->{$key}  = undef;
    $stop_HR->{$key}   = undef;
    $strand_HR->{$key} = undef;
  }

  return;
}

#################################################################
# Subroutine : set_vars()
# Incept:      EPN, Tue Dec 13 14:53:37 2016
#
# Purpose:     Set variables defining the top-scoring 'one' 
#              model. If necessary switch the current
#              'one' variable values to 'two' variables.
#              
# Arguments: 
#   $clan:      clan, key to hashes
#   $model_HR:  REF to hash of $model variables, a model name
#   $score_HR:  REF to hash of $score variables, a bit score
#   $evalue_HR: REF to hash of $evalue variables, an E-value
#   $start_HR:  REF to hash of $start variables, a start position
#   $stop_HR:   REF to hash of $stop variables, a stop position
#   $strand_HR: REF to hash of $strand variables, a strand
#   $model:     value to set $model_HR{$clan} to 
#   $score:     value to set $score_HR{$clan} to 
#   $evalue:    value to set $evalue_HR{$clan} to 
#   $start:     value to set $start_HR{$clan} to 
#   $stop:      value to set $stop_HR{$clan} to 
#   $strand:    value to set $strand_HR{$clan} to 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub set_vars { 
  my $nargs_expected = 13;
  my $sub_name = "set_vars";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($clan, 
      $model_HR, $score_HR, $evalue_HR, $start_HR, $stop_HR, $strand_HR, 
      $model,    $score,    $evalue,    $start,    $stop,    $strand) = @_;

  $model_HR->{$clan}  = $model;
  $score_HR->{$clan}  = $score;
  $evalue_HR->{$clan} = $evalue;
  $start_HR->{$clan}  = $start;
  $stop_HR->{$clan}   = $stop;
  $strand_HR->{$clan} = $strand;

  return;
}

#################################################################
# Subroutine : output()
# Incept:      EPN, Tue Dec 13 15:30:12 2016
#
# Purpose:     Output information for current sequence in either
#              long or short mode. Short mode if $do_short is true.
#              
# Arguments: 
#   $FH:            file handle to output to
#   $do_short:      TRUE to output in 'short' concise mode, else do long mode
#   $domain_HR:     reference to domain hash
#   $target:        target name
#   $seqlen:        length of target sequence
#   %one_model_HR:  'one' model
#   %one_score_HR:  'one' bit score
#   %one_evalue_HR: 'one' E-value
#   %one_start_HR:  'one' start position
#   %one_stop_HR:   'one' stop position
#   %one_strand_HR: 'one' strand 
#   %two_model_HR:  'two' model
#   %two_score_HR:  'two' bit score
#   %two_evalue_HR: 'two' E-value
#   %two_start_HR:  'two' start position
#   %two_stop_HR:   'two' stop position
#   %two_strand_HR: 'two' strand 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output { 
  my $nargs_expected = 17;
  my $sub_name = "output";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($FH, $do_short, $domain_HR, $target, $seqlen, $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
      $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR) = @_;

  my $diff_thresh = 100.;

  # determine the winning clan
  my $wclan = undef;
  foreach my $clan (keys %{$one_model_HR}) { 
    if((! defined $wclan) || # we don't yet have a winning clan, set it to this one
       ($one_model_HR->{$clan} < $one_model_HR->{$wclan}) || # this E-value is better than (less than) our current winning E-value
       ($one_evalue_HR->{$clan} eq $one_evalue_HR->{$wclan} && $one_score_HR->{$clan} > $one_score_HR->{$wclan})) { # this E-value equals current 'one' E-value, but this score is better than current winning score
      $wclan = $clan;
    }
  }

  # build up 'extra information' about other hits in other clans, if any
  my $extra_string = "";
  my $nhits = 1;
  foreach my $clan (keys %{$one_model_HR}) { 
    if($clan ne $wclan) { 
      if(exists($one_model_HR->{$clan})) { 
        if($extra_string ne "") { $extra_string .= ","; }
        $extra_string .= sprintf("%s:%10g:%10.2f/%d-%d:%s",
                                 $clan, $one_model_HR->{$clan}, $one_evalue_HR->{$clan}, $one_score_HR->{$clan}, 
                                 $one_start_HR->{$clan}, $one_stop_HR->{$clan}, $one_strand_HR->{$clan});
        $nhits++;
      }
    }
  }
  my $coverage = (abs($one_stop_H{$wclan} - $one_start_H{$wclan}) + 1) / $seqlen;
  
  my $score_diff = (exists $two_score_HR->{$wclan}) ? ($one_score_HR->{$wclan} - $two_score_HR->{$wclan}) : $one_score_HR->{$wclan};
  my $pass_fail = (($score_diff > $diff_thresh) && ($nhits == 1)) ? "PASS" : "FAIL";

  if($do_short) { 
    printf $FH ("%-30s  %10s  %s\n", 
           $target, $clan . "." . $domain_HR->{$one_model_HR->{$wclan}}, $pass_fail);
  }
  else { 
    printf $FH ("%-30s  %10d  %3d  %3s  %-15s  %-15s  %10g  %10.2f  %s  %5.3f  %10d  %10d  ", 
           $target, $seqlen, $nhits, $clan, $domain_HR->{$one_model_HR->{$wclan}}, $one_model_HR->{$wclan}, 
           $one_evalue_HR->{$wclan}, $one_score_HR->{$wclan}, $one_strand_HR->{$wclan}, $coverage, 
           $one_start_HR->{$wclan}, $one_stop_HR->{$wclan});
    
    if(defined $two_model_HR->{$wclan}) { 
      printf $FH ("%10.2f  %-15s  %10g  %10.2f  ", 
             $one_score_HR->{$wclan} - $two_score_HR->{$wclan}, $two_model_HR->{$wclan}, $two_evalue_HR->{$wclan}, $two_score_HR->{$wclan});
    }
    else { 
      printf $FH ("%10s  %-15s  %10s  %10.2s  ", 
             "-" , "-", "-", "-");
    }
    
    if($extra_string eq "") { 
      $extra_string = "-";
    }
    
    print $FH ("$extra_string\n");
  }

  return;
}

#################################################################
# Subroutine : parse_seqstat_file()
# Incept:      EPN, Wed Dec 14 16:16:22 2016
#
# Purpose:     Parse an esl-seqstat -a output file.
#              
# Arguments: 
#   $seqstat_file:  file to parse
#   $seqlen_HR:     REF to hash of sequence lengths to fill here
#
# Returns:     Nothing. Fills %{$seqlen_HR}.
# 
# Dies:        Never.
#
################################################################# 
sub parse_seqstat_file { 
  my $nargs_expected = 2;
  my $sub_name = "parse_seqstat_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seqstat_file, $seqlen_HR) = @_;

  open(IN, $seqstat_file) || die "ERROR unable to open esl-seqstat file $seqstat_file for reading";

  my $nread = 0;

  while(my $line = <IN>) { 
  # = lcl|dna_BP331_0.3k:467     1232 
  # = lcl|dna_BP331_0.3k:10     1397 
  # = lcl|dna_BP331_0.3k:1052     1414 
    chomp $line;
    #print $line . "\n";
    if($line =~ /^\=\s+(\S+)\s+(\d+)\s*$/) { 
      $seqlen_HR->{$1} = $2;
      $nread++;
    }
  }
  close(IN);
  if($nread == 0) { 
    die "ERROR did not read any sequence lengths in esl-seqstat file $seqstat_file, did you use -a option with esl-seqstat";
  }

  return;
}

#################################################################
# Subroutine : parse_clan_file()
# Incept:      EPN, Mon Dec 19 10:01:32 2016
#
# Purpose:     Parse a clan input file.
#              
# Arguments: 
#   $clan_file:       file to parse
#   $clan_names_AR:   ref to array of clan names, values in %{$clan_H} in order read
#   $clan_HR:         ref to hash of clan names, key is model name, value is clan name
#   $domain_names_AR: ref to array of domain names, values in %{$clan_H} in order read
#   $domain_HR:       ref to hash of domain names, key is model name, value is domain name
#
# Returns:     Nothing. Fills @{$clan_names_AR}, %{$clan_H}, @{$domain_names_AR}, %{$domain_HR}
# 
# Dies:        Never.
#
################################################################# 
sub parse_clan_file { 
  my $nargs_expected = 5;
  my $sub_name = "parse_clan_file";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($clan_file, $clan_names_AR, $clan_HR, $domain_names_AR, $domain_HR) = @_;

  open(IN, $clan_file) || die "ERROR unable to open esl-seqstat file $seqstat_file for reading";

# example line:
# SSU_rRNA_archaea SSU Archaea

  my %clan_exists_H   = ();
  my %domain_exists_H = ();

  open(IN, $clan_file) || die "ERROR unable to open $clan_file for reading"; 
  while(my $line = <IN>) { 
    chomp $line;
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 3) { 
      die "ERROR didn't read 3 tokens in clan input file $clan_file, line $line"; 
    }
    my($model, $clan, $domain) = (@el_A);

    if(! exists $clan_exists_H{$clan}) { 
      push(@{$clan_names_AR}, $clan); 
      $clan_exists_H{$clan} = 1;
    }
    if(! exists $domain_exists_H{$domain}) { 
      push(@{$domain_names_AR}, $domain); 
      $domain_exists_H{$domain} = 1;
    }
    if(exists $clan_HR->{$model}) { 
      die "ERROR read model $model twice in $clan_file"; 
    }
    $clan_HR->{$model}   = $clan;
    $domain_HR->{$model} = $domain;
  }
  close(IN);

  return;
}
