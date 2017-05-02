EPN, Wed Feb 22 15:59:00 2017

Organization of this file:

INTRO
SETTING UP ENVIRONMENT VARIABLES
SAMPLE RUN
OUTPUT
UNEXPECTED FEATURES AND REASONS FOR FAILURE
RECOMMENDED MODEL FILES
DEFINING ACCEPTABLE MODELS
RUNNING TWO SUCCESSIVE ROUNDS OF RIBOTYPER
ALL COMMAND LINE OPTIONS

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

A 'short' file of 6 columns, and a 'long' file with 20 columns with
more information. Each file includes a description of the columns at
the end of the file. 

Short file:
$ cat test/test.ribotyper.short.out
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#idx  target                                         classification         strnd   p/f  unexpected_features
#---  ---------------------------------------------  ---------------------  -----  ----  -------------------
1     00052::Halobacterium_sp.::AE005128             SSU.Archaea            plus   PASS  -
2     00013::Methanobacterium_formicicum::M36508     SSU.Archaea            plus   PASS  -
3     00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea            plus   PASS  -
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus   PASS  -
5     random                                         -                          -  FAIL  no_hits
6     00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea            minus  PASS  opposite_strand
7     00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria           plus   PASS  -
8     01106::Bacillus_subtilis::K00637               SSU.Bacteria           plus   PASS  -
9     00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria           plus   PASS  -
10    01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria           minus  PASS  opposite_strand
11    00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria           plus   PASS  -
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus   PASS  -
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus   PASS  -
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus   PASS  -
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  PASS  opposite_strand
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus   PASS  -
#
# Explanation of columns:
#
# Column 1 [idx]:                 index of sequence in input sequence file
# Column 2 [target]:              name of target sequence
# Column 3 [classification]:      classification of sequence
# Column 4 [strnd]:               strand ('plus' or 'minus') of sequence
# Column 5 [p/f]:                 PASS or FAIL
# Column 6 [unexpected_features]: unexpected/unusual features of sequence (see 00README.txt)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Long file is not shown because it is so wide. 
An example is in testfiles/test.ribotyper.long.out 

##############################################################################
UNEXPECTED FEATURES AND REASONS FOR FAILURE

There are several 'unexpected features' of sequences that are detected
and reported in the final column of both the short and long output
files. These unexpected features can cause a sequence to FAIL, as
explained below.

There are 13 possible unexpected features that get reported, some of
which are related to each other. Seven of these will always cause a
sequence to fail. The other 6 *can* cause a sequence to fail but only
if specific command line options are used.

List of unexpected features:

1: "no_hits": No hits to any models above the minimum score threshold
were found. The minimum score threshold is 20 bits, which should find
all legitimate SSU/LSU sequences, but this minimum score threshold is
changeable to <x> with the --minbit <x>. ALWAYS CAUSES FAILURE.

2: "hits_to_more_than_one_family": hit to two or more 'families'
(e.g. SSU or LSU) exists for the same sequence. This would happen, for
example, if a single sequence had a fragment of an SSU sequence and a
fragment of an LSU sequence on it. ALWAYS CAUSES FAILURE.

3. "other_family_hits": ALWAYS (AND ONLY) OCCURS IN TANDEM WITH (2)
"hits_to_more_than_one_family", details hits to other families. ALWAYS
CAUSES FAILURE.

4. "hits_on_both_strands": At least 1 hit above minimum score
threshold to best model exists on both strands. ALWAYS CAUSES FAILURE.

5. "duplicate_model_region": At least two hits overlap in model
coordinates by X positions or more. X is 10 by default but can be
changed to <x> with the --maxoverlap <x> option. ALWAYS CAUSES
FAILURE.

6. "inconsistent_hit_order": The hits to the best model are
inconsistent in that they are not in the same order in the sequence
and the model, possibly indicating a misassembly. ALWAYS CAUSES
FAILURE.

7. "unacceptable_model": Best hit is to a model that is
'unacceptable'. By default, all models are acceptable, but the user
can specify only certain top-scoring models are 'acceptable' using the
--inaccept <s> option. An example of using this file is given below 
in the DEFINING ACCEPTABLE MODELS section. ALWAYS CAUSES FAILURE.

8. "opposite_strand": The best hit is on the minus strand. ONLY CAUSES
FAILURE IF THE --minusfail OPTION IS ENABLED.

9. "low_score_per_posn": the bits per nucleotide
statistic (total bit score divided by length of total sequence (not
just length of hit)) is below threshold. By default the threshold is
0.5 bits per position, but this can be changed to <x> with the
"--lowppossc <x>" option. ONLY CAUSES FAILURE IF THE --scfail OPTION
IS ENABLED.

10. "low_total_coverage": the total coverage of all hits to the best
model (summed length of all hits divided by total sequence length) is
below threshold. By default the threshold is 0.88, but can be changed
to <x> with the --tcov <x> option. ONLY CAUSES FAILURE IF THE
--covfail OPTION IS ENABLED.

11. "low_score_difference_between_top_two_domains": the score
difference between the top two domains is below the 'low'
threshold. By default this is the score per position difference, and
the 'low' threshold is 0.10 bits per position, but this is changeable
to <x> bits per position with the --lowpdiff option. The difference
can be changed from bits per position to total bits with the --absdiff
option. If --absdiff is used, the threshold is 100 bits, but
changeable to <x> with the --lowadiff <x> option. ONLY CAUSES FAILURE
IF THE --difffail OPTION IS ENABLED.

12. "very_low_score_difference_between_top_two_domains": the score
difference between the top two domains is below the 'very low'
threshold. By default this is the score per position difference, and
the 'very low' threshold is 0.04 bits per position, but this is
changeable to <x> bits per position with the --vlowpdiff option. The
difference can be changed from bits per position to total bits with
the --absdiff option. If --absdiff is used, the threshold is 40 bits,
but changeable to <x> with the --vlowadiff <x> option. ONLY CAUSES
FAILURE IF THE --difffail OPTION IS ENABLED.

13. "multiple_hits_to_best_model": there are more than one hits to the
best scoring model. ONLY CAUSES FAILURE IF THE --multfail OPTION IS
ENABLED.

##############################################################################
RECOMMENDED MODEL FILES

There are currently four model files included with ribotyper:

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
Model files 2-4.

/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.arc.170306.cm
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.bac.170306.cm
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.cyb.170306.cm

Each of these files includes a single model from the
ssu.7.enone.lsu.3.170306.cm file. The archaeal SSU, bacterial SSU, and
cyanobacterial SSU models, respectively. Each file has a corresponding
modelinfo file
(e.g. /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.arc.170306.modelinfo).

These are used in the RUNNING TWO SUCCESSIVE ROUNDS OF RIBOTYPER
example below. 

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

##############################################################################
RUNNING TWO SUCCESSIVE ROUNDS OF RIBOTYPER

If you are interested in running ribotyper in slow mode, but want to
do it as efficiently as possible, you can try the following:

1. Run ribotyper in fast mode with a large set of models
2. Extract the hits to each model you are interested in into a 
   separate sequence file.
3. For each sequence file from step 2, run ribotyper again in a slower
   mode with a smaller model file.

This is faster than running the slower mode for all sequences because
step 1 defines the best model for each sequence, and only that model
is used in the slow mode in step 3.

Here's an example. Imagine you are only interested in bacterial and
archaeal SSU sequences. First run ribotyper in default mode except use
the --inaccept option with the file models/ssu.arc.bac.accept file
which lists the 3 SSU models for archaea and bacteria. Also use the
--scfail option which causes sequences with low 'bits per position'
values to fail. (There are other options for specifying which
unexpected features cause sequences to fail. See the ALL COMMAND LINE
OPTIONS section below. This one is just used as an example.)

$ perl ribotyper.pl -f --inaccept models/ssu.arc.bac.accept --scfail testfiles/seed-15.fa models/ssu.7.enone.lsu.3.170306.cm models/ssu.7.enone.lsu.3.170306.modelinfo test2

Then extract the sequences that match each of the following three
models into separate sequence files and run ribotyper a second time on
each of those using a single model for each of those three runs.

First, we want to extract the sequences that match the archaea model
that PASS. The next command will count those sequences:

$ grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_archaea | awk '{ print $1 }' | wc -l
5

The output of '5' indicates there are 5 such sequences.

Now, we want to extract only these 5 sequences from the input sequence
file (testfiles/seed-15.fa), but first we need to 'index' that file
with the 'esl-sfetch' program. This program is installed with Infernal
1.1.2 which is a requirement for ribotyper to run.

$ esl-sfetch --index testfiles/seed-15.fa 
Creating SSI index for testfiles/seed-15.fa...    done.
Indexed 16 sequences (16 names).
SSI index written to file testfiles/seed-15.fa.ssi

Now we can extract the 5 archaeal sequences like this:
$ grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_archaea | awk '{ print $1 }' | esl-sfetch -f testfiles/seed-15.fa - > arc.fa

Now we want to run ribotyper on only the arc.fa file, but this time
using only the archaeal SSU model (we already know these are all
archaeal SSU sequences) and using the --hmm option and --covfail
options. The --hmm option makes ribotyper to use a slower algorithm
that calculates more accurate coverage values. The --covfail options
tells ribotyper to have any sequence with a low coverage value (below
the default threshold of 0.88) to FAIL.

$ perl ribotyper.pl -f --scfail --covfail arc.fa models/ssu.arc.170306.cm models/ssu.arc.170306.modelinfo test2-arc

Next, we want to repeat those same steps for the SSU_rRNA_bacteria hits.
First, are there any sequences? 

$ grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_archaea | awk '{ print $1 }' | wc -l
5

Yes, there are 5. Now, extract them:
$ grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_bacteria | awk '{ print $1 }' | esl-sfetch -f testfiles/seed-15.fa - > bac.fa

This time, we do not need to run the esl-sfetch --index command
again. That only needs to be done once per sequence file.

Next, we run ribotyper.pl again, with the bacterial SSU model only:
$ perl ribotyper.pl -f --scfail --covfail bac.fa models/ssu.bac.170306.cm models/ssu.bac.170306.modelinfo test2-bac

Finally, we repeat the above steps for the final model
SSU_rRNA_cyanobacteria:

<[(ribotyper-v1)]> grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_cyanobacteria | awk '{ print $1 }' | wc -l
0

This means there are 0 cyanobacterial SSU sequences, so we do not need
to go any further. If this number was greater than 0, we would proceed
with the same steps we did above for archaea and bacteria.

--------

Here are all of the steps above written again, in a slightly different
order, with comment lines (prefixed with '#') explaining what each
step does:

# run first round pass of ribotyper in fast mode:
perl ribotyper.pl -f --inaccept models/ssu.arc.bac.accept --scfail testfiles/seed-15.fa models/ssu.7.enone.lsu.3.170306.cm models/ssu.7.enone.lsu.3.170306.modelinfo test2

# check if we have any PASSing sequences to the 3 models of interest:
# SSU_rRNA_archaea, SSU_rRNA_bacteria and SSU_rRNA_cyanobacteria
grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_archaea       | awk '{ print $1 }' | wc -l
grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_bacteria      | awk '{ print $1 }' | wc -l
grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_cyanobacteria | awk '{ print $1 }' | wc -l

# for any of the 3 previous commands that returned a number above 0, fetch the sequences
# first index the sequence file so we can fetch from it
esl-sfetch --index testfiles/seed-15.fa 

# and fetch the sequences into new files arc.fa and bac.fa 
grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_archaea  | awk '{ print $1 }' | esl-sfetch -f testfiles/seed-15.fa - > arc.fa
grep PASS test2/test2.ribotyper.long.out | awk '{ printf("%s %s\n", $2, $8); }' | grep SSU\_rRNA\_bacteria | awk '{ print $1 }' | esl-sfetch -f testfiles/seed-15.fa - > bac.fa

# run a second round of ribotyper on archaeal sequences and bacterial sequences separately
perl ribotyper.pl -f --scfail --covfail arc.fa models/ssu.arc.170306.cm models/ssu.arc.170306.modelinfo test2-arc
perl ribotyper.pl -f --scfail --covfail bac.fa models/ssu.bac.170306.cm models/ssu.bac.170306.modelinfo test2-bac

# there's no need to fetch sequences or rerun ribotyper for cyanobacteria because there
# were not any hits to that model in this example

##############################################################################
ALL COMMAND LINE OPTIONS

You can see all the available command line options to ribotyper.pl by
calling it at the command line with the -h option:

<[(ribotyper-v1)]> ./ribotyper.pl -h
# ribotyper.pl :: detect and classify ribosomal RNA sequences
# dnaorg 0.01 (Dec 2016)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Tue Apr 18 11:51:48 2017
#
Usage: ribotyper.pl [-options] <fasta file to annotate> <model file> <fam/domain info file> <output directory>


basic options:
  -f : force; if <output directory> exists, overwrite it
  -v : be verbose; output commands to stdout as they're run

options for controlling the search algorithm:
  --nhmmer      : using nhmmer for annotation
  --cmscan      : using cmscan for annotation
  --ssualign    : using SSU-ALIGN for annotation
  --hmm         : run in slower HMM mode
  --slow        : run in slow CM mode, maximize boundary accuracy
  --mid         : with --slow use cmsearch --mid option instead of --rfam
  --max         : with --slow use cmsearch --max option instead of --rfam
  --smxsize <x> : with --max also use cmsearch --smxsize <x>

options related to bit score REPORTING thresholds:
  --minsc <x> : set minimum bit score cutoff for hits to include to <x> bits [20.]
  --nominsc   : turn off minimum bit score cutoff for hits

options for controlling which sequences PASS/FAIL (turning on optional failure criteria):
  --minusfail : hits on negative (minus) strand defined as FAILures
  --scfail    : seqs that fall below low score difference FAIL
  --difffail  : seqs that fall below low score difference FAIL
  --covfail   : seqs that fall below low coverage threshold FAIL
  --multfail  : seqs that have more than one hit to best model FAIL

options for controlling the bit score WARNING threshold:
  --lowppossc <x> : set minimum bit per position threshold for reporting suspiciously low scores to <x> bits [0.5]

options for controlling the coverage threshold:
  --tcov <x> : set low total coverage threshold to <x> fraction of target sequence [0.88]

	options for controlling the score difference threshold to report/fail sequences:
  --lowpdiff <x>  : set 'low'      per-posn score difference threshold to <x> bits [0.10]
  --vlowpdiff <x> : set 'very low' per-posn score difference threshold to <x> bits [0.04]
  --absdiff       : use total score difference thresholds instead of per-posn
  --lowadiff <x>  : set 'low'      total score difference threshold to <x> bits [100.]
  --vlowadiff <x> : set 'very low' total score difference threshold to <x> bits [40.]

optional input files:
  --inaccept <s> : read acceptable domains/models from file <s>

advanced options:
  --evalues    : rank hits by E-values, not bit scores
  --skipsearch : skip search stage, use results from earlier run
  --noali      : no alignments in output with --slow, --hmm, or --nhmmer
  --samedomain : top two hits can be to models in the same domain

Last updated: EPN, Tue Apr 18 11:52:47 2017

--------------------------------------
