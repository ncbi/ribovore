use strict;
# expects sorted output, sorted by column 1, the 'target name' column
# will detect if file is not sorted

my $one_model;
my $one_score;
my $one_evalue;
my $one_start;
my $one_stop;
my $one_strand;
my $two_model;
my $two_score;
my $two_evalue;
my $two_start;
my $two_stop;
my $two_strand;

my %already_output_H = ();
my $prv_target = undef; # initialize 

init_vars(\$one_model, \$one_score, \$one_evalue, \$one_start, \$one_stop, \$one_strand);
init_vars(\$two_model, \$two_score, \$two_evalue, \$two_start, \$two_stop, \$two_strand);

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

  # make sure we haven't output information for this sequence already
  if(exists $already_output_H{$target}) { 
    die "ERROR found line with target previously output, did you sort by first column?";
  }

  # Are we now finished with the previous sequence? Yes, if target sequence we just read is different from it
  if((defined $prv_target) && ($prv_target ne $target)) { 
    # if so, output its current info
    output($prv_target, $one_model, $one_score, $one_evalue, $one_start, $one_stop, $one_strand, 
           $two_model, $two_score, $two_evalue, $two_start, $two_stop, $two_strand);
    $already_output_H{$prv_target} = 1;
    # reset vars
    init_vars(\$one_model, \$one_score, \$one_evalue, \$one_start, \$one_stop, \$one_strand);
    init_vars(\$two_model, \$two_score, \$two_evalue, \$two_start, \$two_stop, \$two_strand);
  }
  
  # is this a new 'one' hit (top scoring model)?
  if((! defined $one_evalue) || # we don't yet have a 'one' model, use this one
     ($evalue < $one_evalue) || # this E-value is better than (less than) our current 'one' E-value
     ($evalue eq $one_evalue && $score > $one_score)) { # this E-value equals current 'one' E-value, but this score is better than current 'one' score
    # new 'one' hit, update 'one' variables, 
    # but first copy existing 'one' hit values to 'two', if 'one' hit is defined and it's a different model than current $model
    if(defined $one_model && $one_model ne $model) { 
      set_vars(\$two_model, \$two_score, \$two_evalue, \$two_start, \$two_stop, \$two_strand, 
               $one_model,   $one_score,  $one_evalue,  $one_start,  $one_stop,  $one_strand);
    }
    # now set new 'one' hit values
    set_vars(\$one_model, \$one_score, \$one_evalue, \$one_start, \$one_stop, \$one_strand, 
             $model,       $score,      $evalue,      $seqfrom,    $seqto,     $strand);
  }
  else { # not a new 'one' hit
    # is this a new 'two' hit (second-best scoring model)?
    if(($model ne $one_model) &&   # this is not the same model as model one
       (($evalue < $two_evalue) || # this E-value is better than (less than) our current 'two' E-value
        ($evalue eq $two_evalue && $score > $two_score))) { # this E-value equals current 'two' E-value, but this score is better than current 'two' score
      # new 'two' hit, set it
      set_vars(\$two_model, \$two_score, \$two_evalue, \$two_start, \$two_stop, \$two_strand, 
               $model,       $score,      $evalue,      $seqfrom,    $seqto,     $strand);
    }
  }
  $prv_target = $target;

  # sanity check
  if((defined $one_model && defined $two_model) && ($one_model eq $two_model)) { 
    die "ERROR, coding error, one_model and two_model are identical for $target";
  }
}
# output data for final sequence
output($prv_target, $one_model, $one_score, $one_evalue, $one_start, $one_stop, $one_strand, 
       $two_model, $two_score, $two_evalue, $two_start, $two_stop, $two_strand);
$already_output_H{$prv_target} = 1;

#################################################################
# Subroutine : init_vars()
# Incept:      EPN, Tue Dec 13 14:53:37 2016
#
# Purpose:     Initialize variables to undefined 
#              given references to them.
#              
# Arguments: 
#   $model_R:   REF to $model variable, a model name
#   $score_R:   REF to $score variable, a bit score
#   $evalue_R:  REF to $evalue variable, an E-value
#   $start_R:   REF to $start variable, a start position
#   $stop_R:    REF to $stop variable, a stop position
#   $strand_R:  REF to $strand variable, a strand
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

  my ($model_R, $score_R, $evalue_R, $start_R, $stop_R, $strand_R) = @_;

  $$model_R  = undef;
  $$score_R  = undef;
  $$evalue_R = undef;
  $$start_R  = undef;
  $$stop_R   = undef;
  $$strand_R = undef;

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
#   $model_R:   REF to $model variable, a model name
#   $score_R:   REF to $score variable, a bit score
#   $evalue_R:  REF to $evalue variable, an E-value
#   $start_R:   REF to $start variable, a start position
#   $stop_R:    REF to $stop variable, a stop position
#   $strand_R:  REF to $strand variable, a strand
#   $model:     value to set $$model_R to 
#   $score:     value to set $$score_R to 
#   $evalue:    value to set $$evalue_R to 
#   $start:     value to set $$start_R to 
#   $stop:      value to set $$stop_R to 
#   $strand:    value to set $$strand_R to 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub set_vars { 
  my $nargs_expected = 12;
  my $sub_name = "set_vars";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($model_R, $score_R, $evalue_R, $start_R, $stop_R, $strand_R, 
      $model,   $score,   $evalue,   $start,   $stop,   $strand) = @_;

  $$model_R  = $model;
  $$score_R  = $score;
  $$evalue_R = $evalue;
  $$start_R  = $start;
  $$stop_R   = $stop;
  $$strand_R = $strand;

  return;
}

#################################################################
# Subroutine : output()
# Incept:      EPN, Tue Dec 13 15:30:12 2016
#
# Purpose:     Output current infromation. 
#              
# Arguments: 
#   $target:     target name
#   $one_model:  'one' model
#   $one_score:  'one' bit score
#   $one_evalue: 'one' E-value
#   $one_start:  'one' start position
#   $one_stop:   'one' stop position
#   $one_strand: 'one' strand 
#   $two_model:  'two' model
#   $two_score:  'two' bit score
#   $two_evalue: 'two' E-value
#   $two_start:  'two' start position
#   $two_stop:   'two' stop position
#   $two_strand: 'two' strand 
#
# Returns:     Nothing.
# 
# Dies:        Never.
#
################################################################# 
sub output { 
  my $nargs_expected = 13;
  my $sub_name = "output";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($target, $one_model, $one_score, $one_evalue, $one_start, $one_stop, $one_strand, 
      $two_model, $two_score, $two_evalue, $two_start, $two_stop, $two_strand) = @_;

  if(! defined $one_model) { 
    die "ERROR in $sub_name, one_model is undefined, this shouldn't happen";
  }

  printf("%-30s  %-15s %10g  %10.2f  %10d  %10d  %s  ", 
         $target, $one_model, $one_evalue, $one_score, $one_start, $one_stop, $one_strand);

  if(defined $two_model) { 
    printf("%10.2f  %-15s  %10g  %10.2f\n", 
           $one_score - $two_score, $two_model, $two_evalue, $two_score);
  }
  else { 
    printf("%10s  %-15s  %10s  %10.2s\n", 
           "-" , "-", "-", "-");
  }

  return;
}
