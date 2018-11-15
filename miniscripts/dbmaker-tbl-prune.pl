#!/usr/bin/env perl
# EPN, Thu Nov 15 09:40:44 2018
# dbmaker-tbl-prune.pl
# Parse a ribodbmaker.pl output table based on sequence length and failure string.
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl dbmaker-tbl-prune.pl [OPTIONS] <ribodbmaker .rdb.tbl output file>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t--tab         : input file is .tab.tbl file not .rdb.tbl\n";
$usage .= "\t\t--seqonly     : only output sequence names\n";
$usage .= "\t\t--minlen  <n> : set minimum length sequence to keep as <n>\n";
$usage .= "\t\t--maxlen  <n> : set maximum length sequence to keep as <n>\n";
$usage .= "\t\t--onlypass    : only keep PASSing seqs\n";
$usage .= "\t\t--onlyfail    : only keep FAILing seqs\n";
$usage .= "\t\t--reqfail <s> : only keep FAILing seqs w/>=1 token in <s> (tokens in <s> are comma separated)\n";
$usage .= "\t\t--reqfailall  : only keep FAILing seqs w/all tokens in <s> from --reqfail <s>\n";
$usage .= "\t\t--reqfailonly : only keep FAILing seqs w/ONLY the tokens in <s> from --reqfail <s>\n";

my $minlen = undef;
my $maxlen = undef;
my $do_tab         = 0;
my $do_seqonly     = 0;
my $do_onlypass    = 0;
my $do_onlyfail    = 0;
my $do_reqfail     = 0;
my $do_reqfailstr  = undef;
my $do_reqfailall  = undef;
my $do_reqfailonly = undef;

my $opt_tab         = undef;
my $opt_seqonly     = undef;
my $opt_minlen      = undef;
my $opt_maxlen      = undef;
my $opt_onlypass    = undef;
my $opt_onlyfail    = undef;
my $opt_reqfail     = undef;
my $opt_reqfailall  = undef;
my $opt_reqfailonly = undef;

&GetOptions( "tab"         => \$opt_tab,
             "seqonly"     => \$opt_seqonly,
             "minlen=s"    => \$opt_minlen,
             "maxlen=s"    => \$opt_maxlen,
             "onlypass"    => \$opt_onlypass,
             "onlyfail"    => \$opt_onlyfail,
             "reqfail=s"   => \$opt_reqfail,
             "reqfailall"  => \$opt_reqfailall,
             "reqfailonly" => \$opt_reqfailonly);

if(scalar(@ARGV) != 1) { die $usage; }
my ($tbl_file) = (@ARGV);

# handle options
if(defined $opt_tab) { 
  $do_tab = 1;
}
if(defined $opt_seqonly) { 
  $do_seqonly = 1;
}
if(defined $opt_minlen) { 
  $minlen = $opt_minlen;
}
if(defined $opt_maxlen) { 
  $maxlen = $opt_maxlen;
}
if(defined $opt_onlypass) { 
  $do_onlypass = $opt_onlypass;
}
if(defined $opt_reqfail) { 
  $do_reqfail = 1;
  $do_reqfailstr = $opt_reqfail;
}
if(defined $opt_reqfailall) { 
  $do_reqfailall = 1;
}
if(defined $opt_reqfailonly) { 
  $do_reqfailonly = 1;
}

# check for option incompatibility
if((defined $minlen) && (defined $maxlen) && ($minlen > $maxlen)) { 
  die "ERROR with --minlen <n1> and --maxlen <n2>, <n1> must be <= <n2>";
}
if((defined $opt_onlypass) && ((defined $opt_reqfail) || (defined $opt_reqfailall))) { 
  die "ERROR --onlypass is incompatible with --reqfail and --reqfailall";
}
if((defined $opt_reqfailall) && (! defined $opt_reqfail)) { 
  die "ERROR, --reqfailall requires --reqfail";
}
if((defined $opt_reqfailonly) && (! defined $opt_reqfailall)) { 
  die "ERROR, --reqfailonly requires --reqfailall";
}

# parse the --reqfail option, if necessary
my @reqfail_A = ();
if($do_reqfail) { 
  @reqfail_A = split(",", $do_reqfailstr);
}
my $nreqfail = scalar(@reqfail_A);

# parse file, outputting sequences we want to keep as we go
open(TBL, $tbl_file) || die "ERROR unable to open $tbl_file for reading";
while(my $line = <TBL>) { 
  if($line =~ /^\#/) { 
    if(! $do_seqonly) { 
      print $line;
    }
  }
  else { 
    chomp $line;
    my @el_A = ();
    if($do_tab) { 
      @el_A = split(/\t/, $line);
    }
    else { 
      @el_A = split(/\s+/, $line);
    }
    if(scalar(@el_A) != 11) { 
      die "ERROR did not find 11 tokens on a line (use --tab for tab.tbl files):\n$line\n";
    }
    my $seqname  = $el_A[1];
    my $seqlen   = $el_A[2];
    my $passfail = $el_A[7];
    my $failstr  = $el_A[10];

    if($seqlen !~ /^\d+$/) { die "ERROR unable to parse length (token 3) out of line:\n$line\n"; }
    if($passfail ne "PASS" && $passfail ne "FAIL") { die "ERROR unable to parse PASS/FAIL (token 8) out of line:\n$line\n"; }
                             
    my $output_line = 1; # set to 0 below if nec
    if($do_onlypass) { 
      # only output PASSing seqs
      if($passfail ne "PASS") { 
        $output_line = 0; 
      }
    }
    elsif($do_onlyfail) { 
      # only output FAILing seqs
      if($passfail ne "FAIL") { 
        $output_line = 0; 
      }
    }

    if($do_reqfail) { 
      # only output FAILing seqs that have specific substrings in their fail strings
      if($passfail eq "PASS") { 
        $output_line = 0;
      }
      else { 
        my @cur_fail_A = split(";;", $failstr);
        my $ncur = scalar(@cur_fail_A);
        my $nmatch = 0;
        foreach my $cur_fail (@cur_fail_A) { 
          my $found_match = 0;
          foreach my $req_fail (@reqfail_A) { 
            if($cur_fail =~ m/$req_fail/) { 
              $found_match = 1; 
            }
          }
          if($found_match) { $nmatch++; }
        }
        if($nmatch == 0) { 
          $output_line = 0; 
        }
        elsif($do_reqfailall) { 
          if($nmatch < $nreqfail) { 
            # --reqfailall used, but not all required fails found
            $output_line = 0; 
          }
          if($do_reqfailonly && ($nmatch != $ncur)) { 
            # --reqfailonly used, but not all current fail strings are in <s> from --reqfail
            $output_line = 0;
          }
        }
      }
    }

    # only output sequences in a specific length range
    if((defined $minlen) && ($seqlen < $minlen)) { 
      $output_line = 0;
    }
    if((defined $maxlen) && ($seqlen > $maxlen)) { 
      $output_line = 0;
    }

    # output line, if nec
    if($output_line) { 
      if($do_seqonly) { 
        print $seqname . "\n";
      }
      else { 
        print $line . "\n";
      }
    }
  }
}
