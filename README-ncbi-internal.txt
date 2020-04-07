EPN, Fri Apr  3 15:23:40 2020

ribovore v0.39 README-ncbi-internal.txt

Organization of this file:

INTRODUCTION
SETTING UP ENVIRONMENT VARIABLES
VERIFYING YOU CAN RUN RIBOVORE SCRIPTS
EXAMPLE EXPLANATION OF RIBOTYPER FOR A SUBMITTER
UPDATING THE NCBI TAXONOMY TREE FILE

Questions:
email Eric Nawrocki: eric.nawrocki@nih.gov
##############################################################################
INTRODUCTION

ribovore version 0.39 is installed in system-wide directories for
internal use at NCBI. The top-level directory is:

/panfs/pan1/dnaorg/ssudetection/code/ribovore

You will need to update your environment variables as described below
in order to run the ribovore scripts. Additionally if you want to run
ribovore jobs in parallel on the Sun Grid Engine (SGE) compute farm 
you will need access to the farm. See the SGE quick start confluence
page for help on this:
https://confluence.ncbi.nlm.nih.gov/pages/viewpage.action?spaceKey=UGE&title=Grid+Engine+Quick+Start

The README.txt for ribovore includes example runs of each of the
scripts. It is here:

/panfs/pan1/dnaorg/ssudetection/code/ribovore/ribovore-0.39/README.txt

Git repository for ribovore:
https://github.com/nawrockie/ribovore.git

##############################################################################
SETTING UP ENVIRONMENT VARIABLES

Before you can run any ribovore scripts, you will need to update some of your
environment variables. To do this, add the following lines to
your .bashrc file (if you use bash shell) or .cshrc file (if you use C
shell or tcsh). The .bashrc or .cshrc file is in your home
directory. To determine what shell you use, type
> echo $SHELL
If this command returns '/bin/bash', then update your .bashrc file.
If this command returns'/bin/csh' or '/bin/tcsh' then update your .cshrc file.

The lines to add to your .bashrc file:
-----------
export RIBODIR="/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/ribovore"
export RIBOINFERNALDIR="/usr/local/infernal/1.1.2/bin"
export RIBOEASELDIR="/usr/local/infernal/1.1.2/bin"
export RIBOTIMEDIR="/usr/bin"
export SENSORDIR="/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/rRNA_sensor"
export EPNOPTDIR="/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/epn-options"
export EPNOFILEDIR="/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/epn-ofile"
export EPNTESTDIR="/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/epn-test"
export PERL5LIB="$RIBODIR:$EPNOPTDIR:$EPNOFILEDIR:$EPNTESTDIR:$PERL5LIB"
export PATH="$RIBODIR:$SENSORDIR:$PATH"
export BLASTDB="$SENSORDIR:$BLASTDB"
export RIBOBLASTDIR="/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/ncbi-blast-2.8.1+/bin"
export VECPLUSDIR="/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/vecscreen_plus_taxonomy"
-------------

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The analogous lines to add to your .cshrc file:
-----------
setenv RIBODIR "/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/ribovore"
setenv RIBOINFERNALDIR "/usr/local/infernal/1.1.2/bin"
setenv RIBOEASELDIR "/usr/local/infernal/1.1.2/bin"
setenv RIBOTIMEDIR "/usr/bin"
setenv SENSORDIR "/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/rRNA_sensor"
setenv EPNOPTDIR "/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/epn-options"
setenv EPNOFILEDIR "/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/epn-ofile"
setenv EPNTESTDIR "/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/epn-test"
setenv PERL5LIB "$RIBODIR":"$EPNOPTDIR":"$EPNOFILEDIR":"$EPNTESTDIR":"$PERL5LIB"
setenv PATH "$RIBODIR":"$SENSORDIR":"$PATH"
setenv BLASTDB "$SENSORDIR":"$BLASTDB"
setenv RIBOBLASTDIR "/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/ncbi-blast-2.8.1+/bin"
setenv VECPLUSDIR "/panfs/pan1/dnaorg/ssudetection/code/ribovore-install/vecscreen_plus_taxonomy"
-----------

After adding the lines specified above, execute the command:
> source ~/.bashrc
or
> source ~/.cshrc

If you get an error about PERL5LIB being undefined, change the PERL5LIB
line to add to:
export PERL5LIB="$RIBODIR:$EPNOPTDIR:$EPNOFILEDIR:$EPNTESTDIR"
for .bashrc, OR
setenv PERL5LIB "$RIBODIR":"$EPNOPTDIR":"$EPNOFILEDIR":"$EPNTESTDIR"
for .cshrc. And then do
> source ~/.bashrc
or
> source ~/.cshrc
again.

Similarly, if you get an error about BLASTDB being undefined, 
change the BLASTDB line to add to:
export BLASTDB="$SENSORDIR"
for .bashrc, OR
setenv BLASTDB "$SENSORDIR"
for .cshrc. And then do
> source ~/.bashrc
or
> source ~/.cshrc
again.

###########################################################################
VERIFYING SUCCESSFUL INSTALLATION WITH TEST RUNS

The ribotest.pl script is included in the ribotyper package for
testing scripts to make sure your installation was successful.
It runs the ribovore scripts on small datasets and compares the
output with expected outputs. It is also used during development for
regression testing.

To run all tests, create a temporary directory and move into it, like
this:
> mkdir testing-ribovore
> cd testing-ribovore

And then run the script 'do-all-tests.sh'

> cat $RIBODIR/testfiles/do-ribotyper-tests.sh
<[(ribotyper-v1)]> cat $INF/notebook/19_0117_ribo_doc_update/ribovore/testfiles/do-all-tests.sh 
sh $RIBODIR/testfiles/do-ribotyper-tests.sh
sh $RIBODIR/testfiles/do-riboaligner-tests.sh
sh $RIBODIR/testfiles/do-ribosensor-tests.sh
sh $RIBODIR/testfiles/do-ribodbmaker-tests.sh

sh $RIBODIR/testfiles/do-ribotyper-parallel-tests.sh
sh $RIBODIR/testfiles/do-riboaligner-parallel-tests.sh
sh $RIBODIR/testfiles/do-ribosensor-parallel-tests.sh
sh $RIBODIR/testfiles/do-ribodbmaker-parallel-tests.sh

Here is the beginning of the output when you run that script:
> sh $RIBODIR/testfiles/do-all-tests.sh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ribotest.pl :: test ribotyper scripts [TEST SCRIPT]
# ribotyper 0.36 (Jan 2019)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:      Wed Jan 23 10:14:53 2019
# $RIBODIR:  /panfs/pan1/infernal/notebook/19_0117_ribo_doc_update/test-install/ribovore-0.36
#
# test file:                    /panfs/pan1/infernal/notebook/19_0117_ribo_doc_update/test-install/ribovore-0.36/testfiles/ribotyper.testin
# output directory name:        rt-test
# forcing directory overwrite:  yes [-f]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Running command  1 [      ribotyper-1-16]          ... done. [    8.0 seconds]
#	checking test-16/test-16.ribotyper.short.out                 ... pass
#	checking test-16/test-16.ribotyper.long.out                  ... pass
#	removing directory test-16                                   ... done
# Running command  2 [     ribotyper-2-100]          ... done. [   26.6 seconds]
#	checking r100/r100.ribotyper.short.out                       ... pass
#	checking r100/r100.ribotyper.long.out                        ... pass
#	removing directory r100                                      ... done
#
#
# PASS: all 4 files were created correctly.
#
#
# List and description of all output files saved in:   rt-test.ribotest.list
# Output printed to screen saved in:                   rt-test.ribotest.log
# List of executed commands saved in:                  rt-test.ribotest.cmd
#
# All output files created in directory ./rt-test/
#
# Elapsed time:  00:00:35.13
#                hh:mm:ss
# 
# RIBO-SUCCESS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The most important line is the line that begins with "# PASS"

# PASS: all 4 files were created correctly.

This means that the test has passed. You should see 7 additional
lines like this when you run the other tests. If you do not, 
email me at eric.nawrocki@nih.gov.

###########################################################################

##############################################################################
EXAMPLE EXPLANATION OF RIBOTYPER FOR A SUBMITTER

Here is an example paragraph that could be sent to a submitter
explaining what Ribotyper does:

~~~~~~~~~~~~~~~~~~~
We compared each of your sequences against a set of profile HMMs built
from representative alignments of SSU and LSU rRNA sequences.  Each
profile HMM is a statistical model of the family it models
(e.g. bacterial SSU rRNA) built from a multiple alignment of 50-100
representative sequences from the family. The source of several of the
alignments, including the bacterial model, is the Rfam database
(rfam.xfam.org).  Each profile HMM has position specific scores at
each position of the model, which means that positions of the family
that are highly conserved have a higher impact on the final score than
do positions that are not as well conserved (unlike BLAST for which
each position is treated identically). Each sequence is aligned to
each profile and a score is computed based on well the sequence
matches the profile. Each sequence is classified by the model that
gave it the highest score.
~~~~~~~~~~~~~~~~~~~

##############################################################################
UPDATING THE NCBI TAXONOMY TREE FILE

A specialized copy of the NCBI taxonomy tree file is included with
ribovore. That file is here:

ribovore/taxonomy/ncbi-taxonomy-tree.ribodbmaker.txt

That file is static for a given ribodbmaker release, but can be
updated *on NCBI computer systems* using a different git repo
available here:

https://github.com/nawrockie/ncbi-rrna-project

To clone that repo do:
git clone https://github.com/nawrockie/ncbi-rrna-project.git

You can then update the tree file as follows:
> mv ncbi-rrna-project/taxonomy-files
> update-for-ribodbmaker.sh

Then, to use this updated taxonomy tree file with ribodbmaker.pl, use
the --taxin option, like this:

> ribodbmaker.pl --taxin PATH-TO-NCBI-RRNA-PROJECT/taxonomy-files/ncbi-taxonomy-tree.ribodbmaker.txt <fasta> <outdir>

##############################################################################

For additional documentation on ribovore, see README.txt

###########################################################################
