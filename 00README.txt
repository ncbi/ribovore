EPN, Wed Feb 22 15:59:00 2017

Organization of this file:

INTRO
SETTING UP ENVIRONMENT VARIABLES
SAMPLE RUN
OUTPUT
RECOMMENDED MODEL FILES
DEFINING ACCEPTABLE MODELS

##############################################################################
INTRO

Preliminary documentation for ribotyper, a tool for detecting and
classifying SSU rRNA and LSU rRNA sequences.
Author: Eric Nawrocki

Current location of code and other relevant files:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/

##############################################################################
SETTING UP ENVIRONMENT VARIABLES

Before you can run ribotyper.pl you will need to update some of your
command line variables. To do this, add the following three lines to
your .bashrc file (if you use bash shell) or .cshrc file (if you use C
shell or tcsh). The .bashrc or .cshrc file will be in your home
directory. To determine what shell you use type 'echo $SHELL', if it
returns '/bin/bash', then update your .bashrc file, if it returns
'/bin/csh' or '/bin/tcsh' then update your .cshrc file.

The 3 lines to add to your .bashrc file:
-----------
export RIBODIR="/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1"
export PERL5LIB="$RIBODIR:$PERL5LIB"
export PATH="$RIBODIR:$PATH"
-----------

The 3 lines to add to your .cshrc file:
-----------
setenv RIBODIR "/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1"
setenv PERL5LIB "$RIBODIR":"$PERL5LIB"
setenv PATH "$RIBODIR":"$PATH"
-----------

Then, after adding those 3 lines, execute this command:
source ~/.bashrc
OR
source ~/.cshrc

If you get an error about PERL5LIB being undefined, change the second
line to add to:
export PERL5LIB="$RIBODIR"
for .bashrc, OR
setenv PERL5LIB "$RIBODIR"
for .cshrc. And then do 'source ~/.bashrc' or 'source ~/.cshrc' again.

To check that your environment variables are properly set up do the
following three commands:
echo $RIBODIR
echo $PERL5LIB
echo $PATH

The first command should return only:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1

And the other two echo commands should return potentially longer
strings that begin with the same path:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1

If that is not the case, please email Eric Nawrocki
(nawrocke@ncbi.nlm.nih.gov). If you do see the expected output, the
following sample run should work.

##############################################################################
SAMPLE RUN

This example runs the script on a sample file of 15 sequences. Go into
a new directory and execute:

ribotyper.pl $RIBODIR/testfiles/seed-15.fa $RIBODIR/models/ssu.7.enone.lsu.3.170306.cm $RIBODIR/models/ssu.7.enone.lsu.3.170306.modelinfo test

The script takes 4 command line arguments:

The first argument is the sequence file you want to annotate.

The second argument is the model file which includes the profiles used
to do the search.

The third argument is a text file with information on the taxonomic
classifications that each profile pertains to.

The fourth argument is the name of the output directory that you would
like ribotyper to create. Output files will be placed in this output
directory. If this directory already exists, the program will exit
with an error message indicating that you need to either (a) remove
the directory before rerunning, or (b) use the -f option with
ribotyper.pl, in which case the directory will be overwritten.

The $RIBODIR environment variable is used several times here. That is
a hard-coded path that was set in the 'Setting up environment
variables for Ribotyper:' section above. 

##############################################################################
OUTPUT

Example output of the script from the above command
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ribotyper.pl :: detect and classify ribosomal RNA sequences
# dnaorg 0.01 (Dec 2016)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Tue Mar  7 15:57:56 2017
#
# target sequence input file:    /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/testfiles/seed-15.fa                     
# query model input file:        /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.7.enone.lsu.3.170306.cm       
# model information input file:  /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.7.enone.lsu.3.170306.modelinfo
# output directory name:         test                                                                                       
# forcing directory overwrite:   yes [-f]                                                                                   
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parsing and validating input files and determining target sequence lengths ... done. [0.0 seconds]
# Performing cmsearch-fast search                                            ... done. [1.2 seconds]
# Sorting tabular search results                                             ... done. [0.0 seconds]
# Parsing tabular search results                                             ... done. [0.0 seconds]
# Sorting and finalizing output files                                        ... done. [0.0 seconds]
#
# Short (6 column) output saved to file test/test.ribotyper.short.out.
# Long (17 column) output saved to file test/test.ribotyper.long.out.
#
#[RIBO-SUCCESS]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-----------------
Output files:

Currently, there are two output files. Both are tabular output files
with one line per sequence with fields separated by whitespace (spaces,
not tabs). They will both be in the new directory 'test' that was
created by the example run above.

A 'short' file of 6 columns, and a 'long' file with 17 columns with
more information.

Here is a description of the columns in the short file:

Column 1: index of sequence in input file and ribotyper output.
Column 2: target name (name of sequence)
Column 3: classification (e.g. SSU.Bacteria)
Column 4: strand ('plus' or 'minus')
Column 5: pass/fail, either "PASS" or "FAIL"
Column 6: explanation of any "FAIL" values in column 5 ("-" for PASSing
          sequences

Short file:
$ cat test/test.ribotyper.short.out
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#idx  target                                         classification         strnd   p/f  reason-for-failure
#---  ---------------------------------------------  ---------------------  -----  ----  ------------------
1     00052::Halobacterium_sp.::AE005128             SSU.Archaea            plus   PASS  -
2     00013::Methanobacterium_formicicum::M36508     SSU.Archaea            plus   PASS  -
3     00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea            plus   PASS  -
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus   PASS  -
5     random                                         -                          -  FAIL  no_hits
6     00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea            minus  PASS  -
7     00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria           plus   PASS  -
8     01106::Bacillus_subtilis::K00637               SSU.Bacteria           plus   PASS  -
9     00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria           plus   PASS  -
10    01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria           minus  PASS  -
11    00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria           plus   PASS  -
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus   PASS  -
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus   PASS  -
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus   PASS  -
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  PASS  -
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus   PASS  -
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Long file is not shown because it is so wide. 
An example is in testfiles/test.ribotyper.long.out 

Currently, there are five possible reasons that a sequence can
"FAIL". Reasons 1 and 2 are possible in all runs of the
program. However, users will never see Reasons 3, 4 or 5 unless they
use command line options as explained below in the explanations of
those Reasons.

Reason 1: "no_hits": No hits to any models above the minimum score
          threshold were found. The minimum score threshold is 
          20 bits, which should find all legitimate SSU/LSU sequences,
          but this minimum score threshold is changeable to <x> with
          the --minbit <x>.

Reason 2: "hits_to_more_than_one_family": A hit to two or more
           'families' (e.g. SSU or LSU) exists for the same sequence. 
           This would happen, for example, if a single sequence had
           a fragment of an SSU sequence and a fragment of an LSU
           sequence on it.

Reason 3: "unacceptable_model": Best hit is to a model that is
          'unacceptable'. By default, all models are acceptable, but
          the user can specify only certain top-scoring models are
          'acceptable' using the --inaccept <s> option. See the
          'DEFINING ACCEPTABLE MODELS" section for an example.

Reason 4: "score_difference_between_top_two_models_below_threshold"
          The score difference between the top scoring model and the
          second top scoring model is less than the minimum threshold
          allowed. By default, the minimum threshold is 0 bits, so
          this failure will never occur, but this threshold can be
          changed with the --posdiff and --absdiff options. 

Reason 5: "opposite_strand": The best hit is on the minus strand and
          the --minusfail option was used. 
        

##############################################################################
RECOMMENDED MODEL FILES

There are currently two model files available for ribotyper:

-------------
Model file 1. 
-------------
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.7.enone.lsu.3.170306.cm

This model includes 7 SSU rRNA profiles and 3 LSU rRNA profiles.

The 'modelinfo' file for this model file lists the models and some
additional information. That file is:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.7.enone.lsu.3.170306.modelinfo

Here is the modelinfo file:
$ cat /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.7.enone.lsu.3.170306.modelinfo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Each non-# prefixed line should have 3 white-space delimited tokens: 
#<modelname> <family> <domain>
#model                     family domain
SSU_rRNA_archaea              SSU Archaea
SSU_rRNA_bacteria             SSU Bacteria
SSU_rRNA_eukarya              SSU Eukarya
SSU_rRNA_microsporidia        SSU Euk-Microsporidia
SSU_rRNA_chloroplast          SSU Chloroplast
SSU_rRNA_mitochondria_metazoa SSU Mito-Metazoa
SSU_rRNA_cyanobacteria        SSU Bacteria
LSU_rRNA_archaea              LSU Archaea
LSU_rRNA_bacteria             LSU Bacteria
LSU_rRNA_eukarya              LSU Eukarya
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Using this file will classify sequences SSU and LSU sequences from any
of the listed domains. 

-------------
Model file 2.

/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.3.enone.170306.cm

This model includes a subset of the models in model file 1. It
includes only the SSU archaea, SSU bacteria and SSU eukarya models.

It also has a modelinfo file:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.3.enone.170306.modelinfo

$ cat /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.3.enone.170306.modelinfo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Each non-# prefixed line should have 3 white-space delimited tokens: 
#<modelname> <family> <domain>
#model                     family domain
SSU_rRNA_archaea              SSU Archaea
SSU_rRNA_bacteria             SSU Bacteria
SSU_rRNA_eukarya              SSU Eukarya
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You would use model file 2 instead of model file 1 if you were only
interested in identifying/classifying SSU archaeal, SSU bacterial and SSU
eukaryotic sequences. Because it has about 1/3 the number of models as
model info file 1, runs of ribotyper using model file 2 will be
roughly 3 times as fast as those using model file 1.

##############################################################################
DEFINING ACCEPTABLE MODELS

The user can provide an additional input file that specifies which
models are 'acceptable'. All sequences for which the top hit is NOT
one of these acceptable models, will FAIL for Reason 4 above. 
This is done using the --inaccept option as shown below. 

**If the --inaccept option is not used, then ALL models will be
  considered acceptable.

An example input file that specifies that only the SSU_rRNA_bacteria
and SSU_rRNA_cyanobacteria as 'acceptable' from model file 1 is:

/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/testfiles/ssu.bac.accept

$ cat testfiles/ssu.bac.accept
~~~~~~~~~~~~~~~~~~~~~~~
SSU_rRNA_bacteria
SSU_rRNA_cyanobacteria
~~~~~~~~~~~~~~~~~~~~~~~

To use this on the example run from above, you will use the --inaccept
option, like this:

$ perl ribotyper.pl -f --inaccept testfiles/ssu.bac.accept testfiles/seed-15.fa models/ssu.7.enone.lsu.3.170306.cm models/ssu.7.enone.lsu.3.170306.modelinfo test

Now the short output file will set any family that was classified as a
model other than SSU_rRNA_bacteria or SSU_rRNA_cyanobacteria as FAILs:

$ cat test/test.ribotyper.short.out 
#idx  target                                         classification         strnd   p/f  reason-for-failure
#---  ---------------------------------------------  ---------------------  -----  ----  ------------------
1     00052::Halobacterium_sp.::AE005128             SSU.Archaea            plus   FAIL  unacceptable_model
2     00013::Methanobacterium_formicicum::M36508     SSU.Archaea            plus   FAIL  unacceptable_model
3     00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea            plus   FAIL  unacceptable_model
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus   FAIL  unacceptable_model
5     random                                         -                          -  FAIL  no_hits
6     00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea            minus  FAIL  unacceptable_model;opposite_strand
7     00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria           plus   PASS  -
8     01106::Bacillus_subtilis::K00637               SSU.Bacteria           plus   PASS  -
9     00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria           plus   PASS  -
10    01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria           minus  FAIL  opposite_strand
11    00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria           plus   PASS  -
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus   FAIL  unacceptable_model
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus   FAIL  unacceptable_model
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus   FAIL  unacceptable_model
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  FAIL  unacceptable_model;opposite_strand
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus   FAIL  unacceptable_model


Last updated: Mon Mar  6 16:11:35 2017

