use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;

# make sure the RIBOSCRIPTSDIR, RIBOINFERNALDIR, RIBOEASELDIR env variables are set
my $env_ok = exists $ENV{"RIBOSCRIPTSDIR"} ? 1 : 0;
is($env_ok, 1, "RIBOSCRIPTSDIR env variable set");

$env_ok = exists $ENV{"RIBOINFERNALDIR"} ? 1 : 0;
is($env_ok, 1, "RIBOINFERNALDIR env variable set");

$env_ok = exists $ENV{"RIBOEASELDIR"} ? 1 : 0;
is($env_ok, 1, "RIBOEASELDIR env variable set");

# test that entoy100a-parantheses.minfo should fail

my @cmd_A     = ();
my @desc_A    = ();
my @fail_A    = ();
my @errfile_A = ();
my @rmdir_A   = ();

push(@cmd_A,  "\$RIBOSCRIPTSDIR/ribotyper.pl -i \$RIBOSCRIPTSDIR/t/data/ribo.parantheses.modelinfo -f \$RIBOSCRIPTSDIR/testfiles/example-16.fa rt-16 > /dev/null 2> rt-16.err");
push(@errfile_A, "rt-16.err");
push(@desc_A, "ribotyper model name with parantheses");
push(@fail_A, "1");
push (@rmdir_A, "rt-16");

push(@cmd_A,  "\$RIBOSCRIPTSDIR/riboaligner.pl -i \$RIBOSCRIPTSDIR/t/data/riboaligner.parantheses.modelinfo -f \$RIBOSCRIPTSDIR/testfiles/example-16.fa ra-16 > /dev/null 2> ra-16.err");
push(@errfile_A, "ra-16.err");
push(@desc_A, "riboaligner model name with parantheses");
push(@fail_A, "1");
push (@rmdir_A, "ra-16");

my $ncmd = scalar(@cmd_A);
my $retval = undef;
for(my $i = 0; $i < $ncmd; $i++) { 
  $retval = system($cmd_A[$i]);
  if($retval != 0) { $retval = 1; }
  is($retval, $fail_A[$i], sprintf("%s: expected %s", $desc_A[$i], ($fail_A[$i] ? "fail" : "return code 0 (pass)")));
  my $errmsg = `cat $errfile_A[$i]`;
  my $errmatch = 0;
  if($errmsg =~ /not allowed in model names/) { $errmatch = 1; }
  is($errmatch, 1, "error message as expected");
}

my $dir;
foreach $dir (@rmdir_A) { 
  system("rm -rf $dir");
}
my $errfile;
foreach $errfile (@errfile_A) { 
  system("rm $errfile");
}
