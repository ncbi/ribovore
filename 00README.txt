EPN, Wed Feb 22 15:59:00 2017

Organization of this file:

INTRO
SETTING UP ENVIRONMENT VARIABLES
SAMPLE RUN
OUTPUT
UNEXPECTED FEATURES AND REASONS FOR FAILURE
RECOMMENDED MODEL FILES
RIBOTYPER'S TWO ROUND SEARCH STRATEGY
EXAMPLE EXPLANATION OF RIBOTYPER FOR A SUBMITTER
DEFINING ACCEPTABLE MODELS
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

ribotyper.pl $RIBODIR/testfiles/seed-15.fa test

The script takes 2 command line arguments:

The first argument is the sequence file you want to annotate.

The second argument is the name of the output directory that you would
like ribotyper to create. Output files will be placed in this output
directory. If this directory already exists, the program will exit
with an error message indicating that you need to either (a) remove
the directory before rerunning, or (b) use the -f option with
ribotyper.pl, in which case the directory will be overwritten.

The $RIBODIR environment variable is used here. That is
a hard-coded path that was set in the 'Setting up environment
variables for Ribotyper:' section above. 

In an older version of ribotyper additional command line arguments
were required to specify the locations the model files to use and the
model info file. These are no longer needed unless you want to use a
non-default model, which you can do with the -i option. Email 
nawrocke@ncbi.nlm.nih.gov if you want to do this. 

##############################################################################
OUTPUT

Example output of the script from the above command
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ribotyper.pl :: detect and classify ribosomal RNA sequences
# ribotyper 0.02 (May 2017)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Wed May 10 13:06:06 2017
#
# target sequence input file:    /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/testfiles/seed-15.fa                     
# output directory name:         test                                                                                                     
# model information input file:  /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ribo.0p02.modelinfo
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Validating input files                           ... done. [0.5 seconds]
# Determining target sequence lengths              ... done. [0.0 seconds]
# Classifying sequences                            ... done. [1.4 seconds]
# Sorting classification results                   ... done. [0.1 seconds]
# Processing classification results                ... done. [0.1 seconds]
# Fetching per-model sequence sets                 ... done. [0.0 seconds]
# Searching sequences against best-matching models ... done. [1.6 seconds]
# Concatenating tabular round 2 search results     ... done. [0.1 seconds]
# Sorting search results                           ... done. [0.1 seconds]
# Processing tabular round 2 search results        ... done. [0.1 seconds]
# Creating final output files                      ... done. [0.0 seconds]
#
# Summary statistics:
#
#                number  fraction  average   average   fraction     number
# class         of seqs  of total   length  coverage  that PASS  that FAIL
# ------------  -------  --------  -------  --------  ---------  ---------
  *input*            16    1.0000  1328.69    1.0000          -          -
#
  SSU.Archaea         5    0.3125  1303.60    0.9662     1.0000          0
  SSU.Bacteria        5    0.3125  1295.40    0.9798     1.0000          0
  SSU.Eukarya         5    0.3125  1452.80    0.9590     1.0000          0
#
  *all*              16    1.0000  1328.69    0.9078     0.9375          1
  *none*              1    0.0625  1000.00    0.0000     0.0000          1
#
# Unexpected feature statistics:
#
#                                  causes     number  fraction
# unexpected feature               failure?  of seqs   of seqs
# -------------------------------  --------  -------  --------
  CLEAN(zero_unexpected_features)  no             11     0.688
  *no_hits                         yes             1     0.062
  opposite_strand                  no              3     0.188
  low_total_coverage               no              1     0.062
#
#
# Timing statistics:
#
# stage           num seqs  seq/sec      nt/sec  nt/sec/cpu  total_time
# --------------  --------  -------  ----------  ----------  ----------
  classification        16     11.6     15391.0     15391.0  00:00:01.38  (hh:mm:ss)
  search                15      9.5     12825.9     12825.9  00:00:01.58  (hh:mm:ss)
  total                 16      3.9      5168.5      5168.5  00:00:04.11  (hh:mm:ss)
#
#
# Short (6 column) output saved to file test/test.ribotyper.short.out
# Long (25 column) output saved to file test/test.ribotyper.long.out
#
#[RIBO-SUCCESS]

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
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus   PASS  low_total_coverage:(0.835<0.880)
5     random                                         -                          -  FAIL  *no_hits
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
# Column 4 [strnd]:               strand ('plus' or 'minus') of best-scoring hit
# Column 5 [p/f]:                 PASS or FAIL (reasons for failure begin with '*' in final column)
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

There are 12 possible unexpected features that get reported, some of
which are related to each other. Six of these will always cause a
sequence to fail. The other six *can* cause a sequence to fail but only
if specific command line options are used. 

You can tell which unexpected features cause sequences to FAIL for a
particular ribotyper run by looking unexpected feature column (final
column) of the short or long output files: those that cause failures
will begin with the '*' character (e.g. "*no_hits") and those that do
not cause failures will not begin with a "*". You can control which
unexpected features cause failures using command line options as
explained below in the descriptions of each unexpected feature.

List of unexpected features:

1: "no_hits": No hits to any models above the minimum score threshold
were found. The minimum score threshold is 20 bits, which should find
all legitimate SSU/LSU sequences, but this minimum score threshold is
changeable to <x> with the --minbit <x>. ALWAYS CAUSES FAILURE.

2: "hits_to_more_than_one_family": hit to two or more 'families'
(e.g. SSU or LSU) exists for the same sequence. This would happen, for
example, if a single sequence had a fragment of an SSU sequence and a
fragment of an LSU sequence on it. ALWAYS CAUSES FAILURE.

3. "hits_on_both_strands": At least 1 hit above minimum score
threshold to best model exists on both strands. ALWAYS CAUSES FAILURE.

4. "duplicate_model_region": At least two hits overlap in model
coordinates by X positions or more. X is 10 by default but can be
changed to <x> with the --maxoverlap <x> option. ALWAYS CAUSES
FAILURE.

5. "inconsistent_hit_order": The hits to the best model are
inconsistent in that they are not in the same order in the sequence
and the model, possibly indicating a misassembly. ALWAYS CAUSES
FAILURE.

6. "unacceptable_model": Best hit is to a model that is
'unacceptable'. By default, all models are acceptable, but the user
can specify only certain top-scoring models are 'acceptable' using the
--inaccept <s> option. An example of using this file is given below 
in the DEFINING ACCEPTABLE MODELS section. ALWAYS CAUSES FAILURE.

7. "opposite_strand": The best hit is on the minus strand. ONLY CAUSES
FAILURE IF THE --minusfail OPTION IS ENABLED.

8. "low_score_per_posn": the bits per nucleotide
statistic (total bit score divided by length of total sequence (not
just length of hit)) is below threshold. By default the threshold is
0.5 bits per position, but this can be changed to <x> with the
"--lowppossc <x>" option. ONLY CAUSES FAILURE IF THE --scfail OPTION
IS ENABLED.

9. "low_total_coverage": the total coverage of all hits to the best
model (summed length of all hits divided by total sequence length) is
below threshold. By default the threshold is 0.88, but can be changed
to <x> with the --tcov <x> option. ONLY CAUSES FAILURE IF THE
--covfail OPTION IS ENABLED.

10. "low_score_difference_between_top_two_domains": the score
difference between the top two domains is below the 'low'
threshold. By default this is the score per position difference, and
the 'low' threshold is 0.10 bits per position, but this is changeable
to <x> bits per position with the --lowpdiff option. The difference
can be changed from bits per position to total bits with the --absdiff
option. If --absdiff is used, the threshold is 100 bits, but
changeable to <x> with the --lowadiff <x> option. ONLY CAUSES FAILURE
IF THE --difffail OPTION IS ENABLED.

11. "very_low_score_difference_between_top_two_domains": the score
difference between the top two domains is below the 'very low'
threshold. By default this is the score per position difference, and
the 'very low' threshold is 0.04 bits per position, but this is
changeable to <x> bits per position with the --vlowpdiff option. The
difference can be changed from bits per position to total bits with
the --absdiff option. If --absdiff is used, the threshold is 40 bits,
but changeable to <x> with the --vlowadiff <x> option. ONLY CAUSES
FAILURE IF THE --difffail OPTION IS ENABLED.

12. "multiple_hits_to_best_model": there are more than one hits to the
best scoring model. ONLY CAUSES FAILURE IF THE --multfail OPTION IS
ENABLED.

##############################################################################
THE DEFAULT MODEL FILE

The default model file used by ribotyper is here:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ribo.0p02.cm

This model includes 7 SSU rRNA profiles and 3 LSU rRNA profiles.

The 'modelinfo' file for this model file lists the models and some
additional information. That file is:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ribo.0p02.modelinfo

Here is the modelinfo file:
$ cat /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ribo0.0p02.modelinfo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Each non-# prefixed line should have 4 white-space delimited tokens: 
#<modelname> <family> <domain> <CM-file-with-only-this-model>
# The first line is special, it indicates the name of the master CM file
# with all the models in it
#model                     family domain             cmfile
*all*                         -   -                  ribo.0p02.cm
SSU_rRNA_archaea              SSU Archaea            ribo.0p02.SSU_rRNA_archaea.cm
SSU_rRNA_bacteria             SSU Bacteria           ribo.0p02.SSU_rRNA_bacteria.cm
SSU_rRNA_eukarya              SSU Eukarya            ribo.0p02.SSU_rRNA_eukarya.cm
SSU_rRNA_microsporidia        SSU Euk-Microsporidia  ribo.0p02.SSU_rRNA_microsporidia.cm
SSU_rRNA_chloroplast          SSU Chloroplast        ribo.0p02.SSU_rRNA_chloroplast.cm
SSU_rRNA_mitochondria_metazoa SSU Mito-Metazoa       ribo.0p02.SSU_rRNA_mitochondria_metazoa.cm
SSU_rRNA_cyanobacteria        SSU Bacteria           ribo.0p02.SSU_rRNA_cyanobacteria.cm
LSU_rRNA_archaea              LSU Archaea            ribo.0p02.LSU_rRNA_archaea.cm
LSU_rRNA_bacteria             LSU Bacteria           ribo.0p02.LSU_rRNA_bacteria.cm
LSU_rRNA_eukarya              LSU Eukarya            ribo.0p02.LSU_rRNA_eukarya.cm
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Using this file will classify sequences SSU and LSU sequences from any
of the listed domains. 

##############################################################################
RIBOTYPER'S TWO ROUND SEARCH STRATEGY

Ribotyper proceeds in two rounds. The first round is called the
classification stage. In this round, all models are compared against
all sequences using a fast profile HMM algorithm that does not do a
good job at defining boundaries of SSU sequences, but is good at
determining if a sequence is a SSU sequence or not. For each
comparison, a bit score is reported. For each sequence, the model that
gives that sequence the highest bit score is defined as the
'best-matching' model for that sequence. 
 
In the second round, each model that is the best-matching model to at
least one sequence is searched again against only the set of sequences
that have it as their best-matching model. This time, a slower but
more powerful profile HMM algorithm is used that is better at defining
sequence boundaries. This round takes about as much time as the first
round even though the algorithm is slower because only 1 model is
compared against each sequence. The results of this comparison are
reported to the short and long output files. Ribotyper also attempts
to detect certain 'unexpected features' for each sequence, as listed
in the 'UNEXPECTED FEATURES AND REASONS FOR FAILURE' section. Some of
these unexpected features, if they are detected for a sequence will
cause that sequence to be designated as a FAIL. If a sequence has 0
unexpected features, or only unexpected features that do not cause a
FAIL, it will be designated as a PASS (see the UNEXPECTED FEATURES AND
REASONS FOR FAILURE section for details).

##############################################################################
EXAMPLE EXPLANATION OF RIBOTYPER FOR A SUBMITTER

Here is an example paragraph that could be sent to a submitter
explaining what Ribotyper does:

~~~~~~~~~~~~~~~~~~~~
We compared each of your sequences against a set of profile HMMs built
from representative alignments of SSU rRNA sequences.  Each profile
HMM is a statistical model of the family it models (e.g. bacterial SSU
rRNA) built from a multiple alignment of 50-100 representative
sequences from the family. The source of several of the alignments,
including the bacterial model, is the Rfam database (rfam.xfam.org). 
Each profile HMM has position specific scores at each position of the
model, which means that positions of the family that are highly
conserved have a higher impact on the final score than do positions
that are not as well conserved (unlike BLAST for which each position
is treated identically). Each sequence is aligned to each profile and
a score is computed based on well the sequence matches the
profile. Each sequence is classified by the model that gave it the
highest score. 
~~~~~~~~~~~~~~~~~~~~

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

$ perl ribotyper.pl -f --inaccept testfiles/ssu.bac.accept testfiles/seed-15.fa test

Now the short output file will set any family that was classified as a
model other than SSU_rRNA_bacteria or SSU_rRNA_cyanobacteria as FAILs,
and the string "*unacceptable_model" will be present in the
'unexpected_features' column.

$ cat test/test.ribotyper.short.out 
#idx  target                                         classification         strnd   p/f  unexpected_features
#---  ---------------------------------------------  ---------------------  -----  ----  -------------------
1     00052::Halobacterium_sp.::AE005128             SSU.Archaea            plus   FAIL  *unacceptable_model
2     00013::Methanobacterium_formicicum::M36508     SSU.Archaea            plus   FAIL  *unacceptable_model
3     00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea            plus   FAIL  *unacceptable_model
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus   FAIL  *unacceptable_model;low_total_coverage:(0.835<0.880)
5     random                                         -                          -  FAIL  *no_hits
6     00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea            minus  FAIL  *unacceptable_model;opposite_strand
7     00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria           plus   PASS  -
8     01106::Bacillus_subtilis::K00637               SSU.Bacteria           plus   PASS  -
9     00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria           plus   PASS  -
10    01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria           minus  PASS  opposite_strand
11    00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria           plus   PASS  -
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus   FAIL  *unacceptable_model
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus   FAIL  *unacceptable_model
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus   FAIL  *unacceptable_model
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  FAIL  *unacceptable_model;opposite_strand
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus   FAIL  *unacceptable_model

##############################################################################
ALL COMMAND LINE OPTIONS

You can see all the available command line options to ribotyper.pl by
calling it at the command line with the -h option:

$ ./ribotyper.pl -h
# ribotyper.pl :: detect and classify ribosomal RNA sequences
# ribotyper 0.02 (May 2017)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Wed May 10 13:14:19 2017
#
Usage: ribotyper.pl [-options] <fasta file to annotate> <model file> <fam/domain info file> <output directory>


basic options:
  -f     : force; if <output directory> exists, overwrite it
  -v     : be verbose; output commands to stdout as they're run
  -n <n> : use <n> CPUs [0]
  -i <s> : use model info file <s> instead of default

options for controlling the first round search algorithm:
  --1hmm  : run first round in slower HMM mode
  --1slow : run first round in slow CM mode

options for controlling the second round search algorithm:
  --2slow : run second round in slow CM mode

options related to bit score REPORTING thresholds:
  --minsc <x> : set minimum bit score cutoff for hits to include to <x> bits [20.]
  --nominsc   : turn off minimum bit score cutoff for hits

options for controlling which sequences PASS/FAIL (turning on optional failure criteria):
  --minusfail : hits on negative (minus) strand defined as FAILures
  --scfail    : seqs that fall below low score threshold FAIL
  --difffail  : seqs that fall below low score difference threshold FAIL
  --covfail   : seqs that fall below low coverage threshold FAIL
  --multfail  : seqs that have more than one hit to best model FAIL

options for controlling thresholds for failure/warning criteria:
  --lowppossc <x>  : set minimum bit per position threshold for reporting suspiciously low scores to <x> bits [0.5]
  --tcov <x>       : set low total coverage threshold to <x> fraction of target sequence [0.88]
  --lowpdiff <x>   : set 'low'      per-posn score difference threshold to <x> bits [0.10]
  --vlowpdiff <x>  : set 'very low' per-posn score difference threshold to <x> bits [0.04]
  --absdiff        : use total score difference thresholds instead of per-posn
  --lowadiff <x>   : set 'low'      total score difference threshold to <x> bits [100.]
  --vlowadiff <x>  : set 'very low' total score difference threshold to <x> bits [40.]
  --maxoverlap <n> : set maximum allowed number of model positions to overlap before failure to <n> [10]

optional input files:
  --inaccept <s> : read acceptable domains/models from file <s>

options that modify the behavior of --1slow or --2slow:
  --mid         : with --1slow/--2slow use cmsearch --mid option instead of --rfam
  --max         : with --1slow/--2slow use cmsearch --max option instead of --rfam
  --smxsize <x> : with --max also use cmsearch --smxsize <x>

advanced options:
  --evalues    : rank hits by E-values, not bit scores
  --skipsearch : skip search stage, use results from earlier run
  --noali      : no alignments in output with --1hmm, --1slow, or --2slow
  --samedomain : top two hits can be to models in the same domain
  --keep       : keep all intermediate files that are removed by default

Last updated: EPN, Wed May 10 13:02:58 2017

--------------------------------------
