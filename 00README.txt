Ribotyper v0.07 README

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

This is preliminary documentation for ribotyper, a tool for detecting
and classifying SSU rRNA and LSU rRNA sequences.  

Author: Eric Nawrocki

Current location of code and other relevant files:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/

##############################################################################
SETTING UP ENVIRONMENT VARIABLES

Before you can run ribotyper.pl you will need to update some of your
environment variables. To do this, add the following four lines to
your .bashrc file (if you use bash shell) or .cshrc file (if you use C
shell or tcsh). The .bashrc or .cshrc file will be in your home
directory. To determine what shell you use type 'echo $SHELL', if it
returns '/bin/bash', then update your .bashrc file, if it returns
'/bin/csh' or '/bin/tcsh' then update your .cshrc file.

The 4 lines to add to your .bashrc file:
-----------
export RIBODIR="/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1"
export EPNOPTDIR="/panfs/pan1/dnaorg/ssudetection/code/epn-options"
export PERL5LIB="$RIBODIR:$PERL5LIB"
export PATH="$RIBODIR:$PATH"
-----------

The 4 lines to add to your .cshrc file:
-----------
setenv RIBODIR "/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1"
setenv EPNOPTDIR "/panfs/pan1/dnaorg/ssudetection/code/epn-options"
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
following four commands:
echo $RIBODIR
echo $EPNOPTDIR
echo $PERL5LIB
echo $PATH

The first command should return only:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1

The second command should return only:
/panfs/pan1/dnaorg/ssudetection/code/epn-options

The third command should return a potentially longer string that
begins with:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1:/panfs/pan1/dnaorg/ssudetection/code/epn-options

The fourth command should return a potentially longer string that
begins with:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1

If any of these commands do not return what they are supposed to,
please email Eric Nawrocki (nawrocke@ncbi.nlm.nih.gov). If you do see
the expected output, and you have the prequisite programs installed as
explained below, the sample run below should work.

##############################################################################
PREREQUISITE PROGRAMS

The Infernal v1.1.2 software package must be installed prior to
running ribotyper.pl, and its executables must be in your $PATH.
Further, the easel 'miniapps' that are installed with Infernal must be
in your $PATH. You can download Infernal from
http://eddylab.org/infernal/.

*****************************************
Internal NCBI-specific instructions:
The v1.1.2 Infernal executables and the easel miniapps are already
installed system wide at NCBI. You'll need to login into a node that
runs CentOS 7. Add 'infernal' to the facilities line of your
.ncbi_hints file. And add the following line to your .ncbi_hints file:
option infernal_version 1.1.2
*****************************************

To check if you have Infernal and the executables installed and in
your path. Execute the following two commands:

$ cmsearch -h 
$ esl-sfetch -h

The first command should return the usage for cmsearch with a line
that says: INFERNAL 1.1.2 (July 2016).
And the second command should return the usage for esl-sfetch with a
line that says: Easel 0.43 (July 2016).

If this is true, and you were able to set your environment variables
as explained above, then the sample run 
explained below, the sample run below should work.

##############################################################################
SAMPLE RUN

This example runs the script on a sample file of 16 sequences. 

You can only run ribotyper on sequence files that are in directories
to which you have write permission. So the first step is to copy the
example sequence file into a new directory you have write permission
to. Move into that directory and copy the example file with this
command: 

> cp $RIBODIR/testfiles/example-16.fa ./

Then execute the following command:

> ribotyper.pl example-16.fa test

The script takes 2 command line arguments:

The first argument is the sequence file you want to annotate.

The second argument is the name of the output directory that you would
like ribotyper to create. Output files will be placed in this output
directory. If this directory already exists, the program will exit
with an error message indicating that you need to either (a) remove
the directory before rerunning, or (b) use the -f option with
ribotyper.pl, in which case the directory will be overwritten.

The $RIBODIR environment variable is used here. That is
a hard-coded path that was set in the 'SETTING UP ENVIRONMENT
VARIABLES:' section above. 

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
# ribotyper 0.07 (June 2017)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Fri Jun 30 10:47:55 2017
#
# target sequence input file:    example-16.fa                                                               
# output directory name:         test                                                                        
# model information input file:  /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ribo.0p02.modelinfo
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Validating input files                           ... done. [0.1 seconds]
# Determining target sequence lengths              ... done. [0.0 seconds]
# Classifying sequences                            ... done. [1.9 seconds]
# Sorting classification results                   ... done. [0.0 seconds]
# Processing classification results                ... done. [0.0 seconds]
# Fetching per-model sequence sets                 ... done. [0.0 seconds]
# Searching sequences against best-matching models ... done. [1.4 seconds]
# Concatenating tabular round 2 search results     ... done. [0.0 seconds]
# Sorting search results                           ... done. [0.0 seconds]
# Processing tabular round 2 search results        ... done. [0.0 seconds]
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
#                     causes     number  fraction
# unexpected feature  failure?  of seqs   of seqs
# ------------------  --------  -------  --------
  CLEAN               no             11   0.68750
  *NoHits             yes             1   0.06250
  MinusStrand         no              3   0.18750
  LowCoverage         no              1   0.06250
#
#
# Timing statistics:
#
# stage           num seqs  seq/sec      nt/sec  nt/sec/cpu  total time             
# --------------  --------  -------  ----------  ----------  -----------------------
  classification        16      8.3     11039.7     11039.7  00:00:01.93  (hh:mm:ss)
  search                15     10.4     14108.6     14108.6  00:00:01.44  (hh:mm:ss)
  total                 16      4.3      5731.8      5731.8  00:00:03.71  (hh:mm:ss)
#
#
# Short (6 column) output saved to file test/test.ribotyper.short.out
# Long (25 column) output saved to file test/test.ribotyper.long.out
#
#[RIBO-SUCCESS]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Output files:

Currently, there are two output files. Both are tabular output files
with one line per sequence with fields separated by whitespace (spaces,
not tabs). They will both be in the new directory 'test' that was
created by the example run above.

The two file types are a 'short' file of 6 columns, and a 'long' file
with 20 columns with more information. Each file includes a
description of the columns at the end of the file.

Short file:
$ cat test/test.ribotyper.short.out
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#idx  target                                         classification         strnd   p/f  unexpected_features
#---  ---------------------------------------------  ---------------------  -----  ----  -------------------
1     00052::Halobacterium_sp.::AE005128             SSU.Archaea            plus   PASS  -
2     00013::Methanobacterium_formicicum::M36508     SSU.Archaea            plus   PASS  -
3     00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea            plus   PASS  -
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus   PASS  LowCoverage:(0.835<0.860);
5     random                                         -                      -      FAIL  *NoHits;
6     00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea            minus  PASS  MinusStrand;
7     00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria           plus   PASS  -
8     01106::Bacillus_subtilis::K00637               SSU.Bacteria           plus   PASS  -
9     00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria           plus   PASS  -
10    01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria           minus  PASS  MinusStrand;
11    00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria           plus   PASS  -
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus   PASS  -
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus   PASS  -
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus   PASS  -
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  PASS  MinusStrand;
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus   PASS  -
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Explanation of columns:
#
# Column 1 [idx]:                 index of sequence in input sequence file
# Column 2 [target]:              name of target sequence
# Column 3 [classification]:      classification of sequence
# Column 4 [strnd]:               strand ('plus' or 'minus') of best-scoring hit
# Column 5 [p/f]:                 PASS or FAIL (reasons for failure begin with '*' in final column)
# Column 6 [unexpected_features]: unexpected/unusual features of sequence (see below)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
#
# Explanation of possible values in unexpected_features column:
#
# This column will include a '-' if none of the features listed below are detected.
# Or it will contain one or more of the following types of messages. There are no
# whitespaces in this field, to make parsing easier.
#
# Values that begin with "*" automatically cause a sequence to FAIL.
# Values that do not begin with "*" do not cause a sequence to FAIL.
#
#  1.  *NoHits                 No primary hits to any models above the minimum primary score
#                              threshold of 20 bits (--minpsc) were found.
#  2.  *MultipleFamilies       One or more primary hits to two or more "families" (e.g. SSU
#                              or LSU) exists for the same sequence.
#  3.  *BothStrands            One or more primary hits above the minimum primary score threshold
#                              of 20 bits (--minpsc) were found on each strand.
#  4.  *DuplicateRegion        At least two hits (primary or secondary) on the same strand overlap
#                              in model coordinates by 10 (--maxoverlap) positions or more
#  5.  *InconsistentHits       Not all hits (primary or secondary) are in the same order in the
#                              sequence and in the model.
#  6.  MinusStrand             Best hit is on the minus strand.
#  7.  LowScore                The bits per nucleotide (total bit score divided by total length
#                              of sequence) is below threshold of 0.5 (--lowppossc).
#  8.  LowCoverage             The total coverage of all hits (primary and secondary) to the best
#                              model (summed length of all hits divided by total length of sequence)
#                              is below threshold of 0.86 (--tcov).
#  9.  LowScoreDifference      The bits per nucleotide (total bit score divided by total length
#                              of sequence) is below threshold of 0.5 (--lowppossc).
# 10.  VeryLowScoreDifference  The bits per nucleotide (total bit score divided by total length
#                              of sequence) is below threshold of 0.5 (--lowppossc).
# 11.  MultipleHits            There is more than one hit to the best scoring model on the same strand.
#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The Long file is not shown because it is so wide. 
An example is in testfiles/test.ribotyper.long.out 

##############################################################################
UNEXPECTED FEATURES AND REASONS FOR FAILURE

There are several 'unexpected features' of sequences that are detected
and reported in the final column of both the short and long output
files. These unexpected features can cause a sequence to FAIL, as
explained below. 

There are 15 possible unexpected features that get reported, some of
which are related to each other. Eight of these will always cause a
sequence to fail. The other seven *can* cause a sequence to fail but only
if specific command line options are used. 

You can tell which unexpected features cause sequences to FAIL for a
particular ribotyper run by looking unexpected feature column (final
column) of the short or long output files: those that cause failures
will begin with the '*' character (e.g. "*no_hits") and those that do
not cause failures will not begin with a "*". You can control which
unexpected features cause failures using command line options as
explained below in the descriptions of each unexpected feature.

List of unexpected features:

1: "NoHits": No hits to any models above the minimum score threshold
were found. The minimum score threshold is 20 bits, which should find
all legitimate SSU/LSU sequences, but this minimum score threshold is
changeable to <x> with the --minbit <x>. ALWAYS CAUSES FAILURE.

2: "MultipleFamilies": hit to two or more 'families'
(e.g. SSU or LSU) exists for the same sequence. This would happen, for
example, if a single sequence had a fragment of an SSU sequence and a
fragment of an LSU sequence on it. ALWAYS CAUSES FAILURE.

3. "BothStrands": At least 1 hit above minimum score
threshold to best model exists on both strands. ALWAYS CAUSES FAILURE.

4. "DuplicateRegion": At least two hits overlap in model
coordinates by X positions or more. X is 10 by default but can be
changed to <x> with the --maxoverlap <x> option. ALWAYS CAUSES
FAILURE.

5. "InconsistentHits": The hits to the best model are
inconsistent in that they are not in the same order in the sequence
and the model, possibly indicating a misassembly. ALWAYS CAUSES
FAILURE.

6. "UnacceptableModel": Best hit is to a model that is
'unacceptable'. By default, all models are acceptable, but the user
can specify only certain top-scoring models are 'acceptable' using the
--inaccept <s> option. An example of using this file is given below 
in the DEFINING ACCEPTABLE MODELS section. ALWAYS CAUSES FAILURE.

7. "QuestionableModel": Best hit is to a model that is
'questionable'. By default, no models are questionable, but the user
can specify certain top-scoring models are 'questionable' using the
--inaccept <s> option. An example of using this file is given below 
in the DEFINING ACCEPTABLE/QUESTIONABLE MODELS section. ONLY CAUSES
FAILURE IF THE --questfail OPTION IS ENABLED.

8. "MinusStrand": The best hit is on the minus strand. ONLY CAUSES
FAILURE IF THE --minusfail OPTION IS ENABLED.

9. "LowScore": the bits per nucleotide
statistic (total bit score divided by length of total sequence (not
just length of hit)) is below threshold. By default the threshold is
0.5 bits per position, but this can be changed to <x> with the
"--lowppossc <x>" option. ONLY CAUSES FAILURE IF THE --scfail OPTION
IS ENABLED.

10. "LowCoverage": the total coverage of all hits to the best
model (summed length of all hits divided by total sequence length) is
below threshold. By default the threshold is 0.86, but can be changed
to <x> with the --tcov <x> option. Additionally, you can set a
different threshold for 'short' sequences using the --tshortcov <x1>
option, which must be used in combination with the --tshortlen <n>
option which specifies that sequences less than or equal to <n>
nucleotides will use the coverage threshold <x1> from --tshortcov
<x1>. ONLY CAUSES FAILURE IF THE --covfail OPTION IS ENABLED.

11. "LowScoreDifference": the score
difference between the top two domains is below the 'low'
threshold. By default this is the score per position difference, and
the 'low' threshold is 0.10 bits per position, but this is changeable
to <x> bits per position with the --lowpdiff option. The difference
can be changed from bits per position to total bits with the --absdiff
option. If --absdiff is used, the threshold is 100 bits, but
changeable to <x> with the --lowadiff <x> option. ONLY CAUSES FAILURE
IF THE --difffail OPTION IS ENABLED.

12. "VeryLowScoreDifference": the score
difference between the top two domains is below the 'very low'
threshold. By default this is the score per position difference, and
the 'very low' threshold is 0.04 bits per position, but this is
changeable to <x> bits per position with the --vlowpdiff option. The
difference can be changed from bits per position to total bits with
the --absdiff option. If --absdiff is used, the threshold is 40 bits,
but changeable to <x> with the --vlowadiff <x> option. ONLY CAUSES
FAILURE IF THE --difffail OPTION IS ENABLED.

13. "MultipleHits": there are more than one hits to the
best scoring model. ONLY CAUSES FAILURE IF THE --multfail OPTION IS
ENABLED.

14. "TooShort": the sequence is too short, less than <n1>. ALWAYS
CAUSES FAILURE WHEN REPORTED BUT ONLY REPORTED IF THE --shortfail <n1>
OPTION IS ENABLED.

15. "TooLong": the sequence is too long, more than <n2>. ALWAYS
CAUSES FAILURE WHEN REPORTED BUT ONLY REPORTED IF THE --longfail <n2>
OPTION IS ENABLED.

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
DEFINING ACCEPTABLE/QUESTIONABLE MODELS

The user can provide an additional input file that specifies which
models are 'acceptable' or 'questionable'. All sequences for which the
top hit is NOT one of the acceptable or questionable models, will FAIL
for Reason 6 above. All sequences for which the top hit is one of the
questionable models will be reported with 'questionable_model' in
their unusual feature string (and will FAIL if the --questfail option
is enabled) (Reason 7 above).

**If the --inaccept option is not used, then ALL models will be
  considered acceptable and none will be considered questionable.

An example input file that specifies that only the SSU_rRNA_bacteria
and SSU_rRNA_cyanobacteria as 'acceptable' from model file 1 is:

/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/testfiles/ssu.bac.accept

<[(ribotyper-v1)]> cat testfiles/ssu.arc.quest.bac.accept
~~~~~~~~~~~~~~~~~~~~~~~
# A list of 'acceptable' and 'questionable' models.
# Each non-# prefixed line has 2 tokens, separated by a space.
# First token is the name of a model. 
# Second token is either 'acceptable' or 'questionable'.
#
# 'acceptable' means that this model is allowed and no 'unusual
# features' will be reported for sequences for which this model is the
# best-scoring model
#
# 'questionable' means that this model will have the
# 'questionable_model' unusual feature reported for it.
#
# Any model not listed here will have the 'UnacceptableModel'
# unusual feature reported for it.
SSU_rRNA_archaea questionable
SSU_rRNA_bacteria acceptable
SSU_rRNA_cyanobacteria acceptable
~~~~~~~~~~~~~~~~~~~~~~~

To use this on the example run from above, you will use the --inaccept
option, like this:

$ ribotyper.pl -f --inaccept testfiles/ssu.arc.quest.bac.accept example-16.fa test

Now the short output file will set any family that was classified as a
model other than SSU_rRNA_bacteria or SSU_rRNA_cyanobacteria as FAILs,
and the string "*UnacceptableModel" will be present in the
'unexpected_features' column.

$ cat test/test.ribotyper.short.out 
#idx  target                                         classification         strnd   p/f  unexpected_features
#---  ---------------------------------------------  ---------------------  -----  ----  -------------------
1     00052::Halobacterium_sp.::AE005128             SSU.Archaea            plus   PASS  QuestionableModel:(SSU_rRNA_archaea);
2     00013::Methanobacterium_formicicum::M36508     SSU.Archaea            plus   PASS  QuestionableModel:(SSU_rRNA_archaea);
3     00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea            plus   PASS  QuestionableModel:(SSU_rRNA_archaea);
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus   PASS  QuestionableModel:(SSU_rRNA_archaea);LowCoverage:(0.835<0.860);
5     random                                         -                      -      FAIL  *NoHits;
6     00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea            minus  PASS  QuestionableModel:(SSU_rRNA_archaea);MinusStrand;
7     00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria           plus   PASS  -
8     01106::Bacillus_subtilis::K00637               SSU.Bacteria           plus   PASS  -
9     00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria           plus   PASS  -
10    01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria           minus  PASS  MinusStrand;
11    00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria           plus   PASS  -
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus   FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus   FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus   FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);MinusStrand;
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus   FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);
#
##############################################################################
ALL COMMAND LINE OPTIONS

You can see all the available command line options to ribotyper.pl by
calling it at the command line with the -h option:

$ ribotyper.pl -h
# ribotyper.pl :: detect and classify ribosomal RNA sequences
# ribotyper 0.07 (June 2017)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Fri Jun 30 10:50:13 2017
#
Usage: ribotyper.pl [-options] <fasta file to annotate> <output directory>


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
  --minpsc <x> : set minimum bit score cutoff for primary hits to include to <x> bits [20.]
  --minssc <x> : set minimum bit score cutoff for secondary hits to include to <x> bits [10.]

options for controlling which sequences PASS/FAIL (turning on optional failure criteria):
  --minusfail     : hits on negative (minus) strand defined as FAILures
  --scfail        : seqs that fall below low score threshold FAIL
  --difffail      : seqs that fall below low score difference threshold FAIL
  --covfail       : seqs that fall below low coverage threshold FAIL
  --multfail      : seqs that have more than one hit to best model FAIL
  --questfail     : seqs that score best to questionable models FAIL
  --shortfail <n> : seqs that are shorter than <n> nucleotides FAIL [0]
  --longfail <n>  : seqs that are longer than <n> nucleotides FAIL [0]

options for controlling thresholds for failure/warning criteria:
  --lowppossc <x>  : set minimum bit per position threshold for reporting suspiciously low scores to <x> bits [0.5]
  --tcov <x>       : set low total coverage threshold to <x> fraction of target sequence [0.86]
  --tshortcov <x>  : set low total coverage threshold for short seqs to <x> fraction of target sequence
  --tshortlen <n>  : set maximum length for short seq coverage threshold to <n> nucleotides
  --lowpdiff <x>   : set 'low'      per-posn score difference threshold to <x> bits [0.10]
  --vlowpdiff <x>  : set 'very low' per-posn score difference threshold to <x> bits [0.04]
  --absdiff        : use total score difference thresholds instead of per-posn
  --lowadiff <x>   : set 'low'      total score difference threshold to <x> bits [100.]
  --vlowadiff <x>  : set 'very low' total score difference threshold to <x> bits [40.]
  --maxoverlap <n> : set maximum allowed number of model positions to overlap before failure to <n> [10]

optional input files:
  --inaccept <s> : read acceptable/questionable domains/models from file <s>

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

--------------------------------------
