use strict;
# expects sorted output, sorted by column 1, the 'target name' column
# will detect if file is not sorted

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

my @clan_names_A = ("SSU", "LSU");
my %clan_H = ();
$clan_H{"SSU_rRNA_archaea"}  = "SSU";
$clan_H{"SSU_rRNA_bacteria"} = "SSU";
$clan_H{"SSU_rRNA_eukarya"}  = "SSU";
$clan_H{"LSU_rRNA_archaea"}  = "LSU";
$clan_H{"LSU_rRNA_bacteria"} = "LSU";
$clan_H{"LSU_rRNA_eukarya"}  = "LSU";

my %domain_H = ();
$domain_H{"SSU_rRNA_archaea"}  = "Archaea";
$domain_H{"SSU_rRNA_bacteria"} = "Bacteria";
$domain_H{"SSU_rRNA_eukarya"}  = "Eukarya";

my %already_output_H = ();
my $prv_target = undef; # initialize 
my $clan = undef;

init_vars(\%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H);
init_vars(\%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);

while(my $line = <>) { 
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

  # make sure we haven't output information for this sequence already
  if(exists $already_output_H{$target}) { 
    die "ERROR found line with target previously output, did you sort by first column?";
  }

  # Are we now finished with the previous sequence? Yes, if target sequence we just read is different from it
  if((defined $prv_target) && ($prv_target ne $target)) { 
    # if so, output its current info
    output(\%domain_H, $prv_target, 
           \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
           \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
    $already_output_H{$prv_target} = 1;
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
output(\%domain_H, $prv_target, \%one_model_H, \%one_score_H, \%one_evalue_H, \%one_start_H, \%one_stop_H, \%one_strand_H, 
       \%two_model_H, \%two_score_H, \%two_evalue_H, \%two_start_H, \%two_stop_H, \%two_strand_H);
$already_output_H{$prv_target} = 1;

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
# Purpose:     Output current infromation. 
#              
# Arguments: 
#   $domain_HR:     reference to domain hash
#   $target:        target name
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
  my $nargs_expected = 14;
  my $sub_name = "output";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($domain_HR, $target, $one_model_HR, $one_score_HR, $one_evalue_HR, $one_start_HR, $one_stop_HR, $one_strand_HR, 
      $two_model_HR, $two_score_HR, $two_evalue_HR, $two_start_HR, $two_stop_HR, $two_strand_HR) = @_;

  # determine the winning clan
  my $winning_clan = undef;
  foreach my $clan (keys %{$one_model_HR}) { 
    if((! defined $winning_clan) || # we don't yet have a winning clan, set it to this one
       ($one_model_HR->{$clan} < $one_model_HR->{$winning_clan}) || # this E-value is better than (less than) our current winning E-value
       ($one_evalue_HR->{$clan} eq $one_evalue_HR->{$winning_clan} && $one_score_HR->{$clan} > $one_score_HR->{$winning_clan})) { # this E-value equals current 'one' E-value, but this score is better than current winning score
      $winning_clan = $clan;
    }
  }

  # build up 'extra information' about other hits in other clans, if any
  my $extra_string = "";
  my $nhits = 1;
  foreach my $clan (keys %{$one_model_HR}) { 
    if($clan ne $winning_clan) { 
      if(exists($one_model_HR->{$clan})) { 
        if($extra_string ne "") { $extra_string .= ","; }
        $extra_string .= sprintf("%s:%10g:%10.2f/%d-%d:%s",
                                 $clan, $one_model_HR->{$clan}, $one_evalue_HR->{$clan}, $one_score_HR->{$clan}, 
                                 $one_start_HR->{$clan}, $one_stop_HR->{$clan}, $one_strand_HR->{$clan});
        $nhits++;
      }
    }
  }

  my $seqlen = "?";
  my $coverage = "?";

  printf("%-30s  %10s  %3d  %3s  %-15s  %-15s  %10g  %10.2f  %10d  %s  %5s  %10d  %10d  ", 
         $target, $seqlen, $nhits, $clan, $domain_HR->{$one_model_HR->{$clan}}, $one_model_HR->{$clan}, 
         $one_evalue_HR->{$clan}, $one_score_HR->{$clan}, $one_strand_HR->{$clan}, $coverage, 
         $one_start_HR->{$clan}, $one_stop_HR->{$clan});

  if(defined $two_model_HR->{$winning_clan}) { 
    printf("%10.2f  %-15s  %10g  %10.2f  ", 
           $one_score_HR->{$clan} - $two_score_HR->{$clan}, $two_model_HR->{$clan}, $two_evalue_HR->{$clan}, $two_score_HR->{$clan});
  }
  else { 
    printf("%10s  %-15s  %10s  %10.2s  ", 
           "-" , "-", "-", "-");
  }

  if($extra_string eq "") { 
    $extra_string = "-";
  }
  
  print("$extra_string\n");

  return;
}
