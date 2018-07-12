# non-parallel 16 sequence test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.example-16 test-16
# parallel 16 sequence test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.p.example-16 test-p-16

# non-parallel 100 sequence test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.r100 test-100
# parallel 100 sequence test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.p.r100 test-p-100

# non-parallel ribodbcreate.pl test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.p.db test-db 
# parallel ribodbcreate.pl test
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.p.db test-p-db

# optionally remove all test directories
#for d in test-16 test-p-16 test-100 test-p-100 test-db test-p-db; do 
# rm -rf $d
#done
