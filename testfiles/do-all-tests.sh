# non-parallel 16 sequence test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.example-16 test1
# parallel 16 sequence test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.p.example-16 test2

# non-parallel 100 sequence test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.r100 test3
# parallel 100 sequence test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.p.r100 test4

# non-parallel ribodbmaker.pl test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.db test5 
# parallel ribodbmaker.pl test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.p.db test6

# optionally remove all test directories
#for d in test-16 test-p-16 test-100 test-p-100 test-db test-p-db; do 
# rm -rf $d
#done
