EPN, Thu Jan 17 11:23:11 2019

ribovore v0.35 README

Organization of this file:

INTRO
SETTING UP ENVIRONMENT VARIABLES
PREREQUISITE PROGRAMS
SAMPLE RUN
OUTPUT
UNEXPECTED FEATURES AND REASONS FOR FAILURE
THE DEFAULT MODEL FILE
RIBOTYPER'S TWO ROUND SEARCH STRATEGY
EXAMPLE EXPLANATION OF RIBOTYPER FOR A SUBMITTER
DEFINING ACCEPTABLE/QUESTIONABLE MODELS
ALL COMMAND LINE OPTIONS
ADDITIONAL SCRIPT: riboaligner.pl
ADDITIONAL SCRIPT: ribodbmaker.pl
PARALLELIZING ON A SGE COMPUTE FARM
TESTING SCRIPTS

##############################################################################
INTRO

This is documentation for ribovore, a suite of tools for detecting, 
classifying and analyzing small subunit (SSU) rRNA and large subunit
(LSU) rRNA sequences.  

The possible classifications are explained in the section entitled
THE DEFAULT MODEL FILE

Author: Eric Nawrocki

Current location of code and other relevant files at NCBI:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/

Git repository for ribovore:
https://github.com/nawrockie/ribovore.git

##############################################################################
INSTALLATION

The file 'install.sh' is an executable file for installing ribovore
and its dependencies.

That file will download and install the software packages ribovore,
Infernal 1.1.2, and rRNA_sensor, as well as the required perl modules
epn-options, epn-ofile and epn-test. It will *not* download and
install blastn or vecscreen_plus_taxonomy, which are optional
programs. 

There are commands in install.sh to download and install
vecscreen_plus_taxonomy and blastn but they are commented out. To
download and install those programs, uncomment the lines, and
importantly download the version of blastn that is appropriate for
your system/OS.

##############################################################################
PREREQUISITE PROGRAMS AND FILES

ribovore scripts require several other software packages to run. Some
of these packages are only necessary for running certain ribovore
scripts, as listed below.

Package/files             version         required for ribovore script(s)
-------------             -------------   -------------------------------
Infernal                  1.1.2           all
epn-options               ribovore-0.35   all
epn-ofile                 ribovore-0.35   all
epn-test                  ribovore-0.35   ribotest.pl
blastn                    2.8.1+          ribosensor.pl, ribodbmaker.pl
vecscreen_plus_taxonomy   ribovore-0.35   ribodbmaker.pl
rRNA_sensor               ribovore-0.35   ribosensor.pl
time*                      N/A             all

* 'time' should be installed on your system, usually as 
/usr/bin/time. You can verify your path with 'which time'. Set the
directory returned by that which command as the RIBOTIMEDIR in the
SETTING UP ENVIRONMENT VARIABLES section below.

How to get these software packages:

Package/files             available for download from
-------------             ---------------------------
Infernal                  http://eddylab.org/infernal/infernal-1.1.2.tar.gz
epn-options               https://github.com/nawrockie/epn-options/archive/ribovore-0.35.zip
epn-ofile                 https://github.com/nawrockie/epn-ofile/archive/ribovore-0.35.zip
epn-test                  https://github.com/nawrockie/epn-test/archive/ribovore-0.35.zip
blastn                    ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/
vecscreen_plus_taxonomy   https://github.com/aaschaffer/vecscreen_plus_taxonomy/archive/ribovore-0.35.zip
rRNA_sensor               https://github.com/aaschaffer/rRNA_sensor/archive/ribovore-0.35.zip

##############################################################################
SETTING UP ENVIRONMENT VARIABLES

Once all the required programs listed above are installed, you will
need to update some of your environment variables before you can run
the ribovore scripts. To do this, add the following lines to
your .bashrc file (if you use bash shell) or .cshrc file (if you use C
shell or tcsh). The .bashrc or .cshrc file is in your home
directory. To determine what shell you use, type

> echo $SHELL
If this command returns '/bin/bash', then update your .bashrc file.
If this command returns'/bin/csh' or '/bin/tcsh' then update your .cshrc file.

The lines to add to your .bashrc file:
-----------
export RIBODIR="<full path to directory in which you have the ribovore code>"
export RIBOINFERNALDIR="<full path to directory with infernal binaries (e.g. usr/local/bin)>"
export RIBOEASELDIR="<full path to directory with infernal's easel miniapp binaries (e.g. usr/local/bin)>"
export RIBOBLASTDIR="<full path to directory with blastn binary>"
export RIBOTIMEDIR="<full path to time binary (usually /usr/bin)>"
export VECPLUSDIR="<full path where vecscreen_plus_taxonomy git repo was downloaded>"
export SENSORDIR="<full path where rRNA_sensor git repo was downloaded>"
export EPNOPTDIR="<full path where epn-options git repo was downloaded>"
export EPNOFILEDIR="<full path where epn-file git repo was downloaded>"
export EPNTESTDIR="<full path where epn-test git repo was downloaded>"
export PERL5LIB="$RIBODIR:$EPNOPTDIR:$EPNOFILEDIR:$EPNTESTDIR:$PERL5LIB"
export PATH="$RIBODIR:$PATH"
export BLASTDB="$SENSORDIR:$BLASTDB"
-----------

The lines to add to your .cshrc file:
-----------
setenv RIBODIR "<full path to directory in which you have the ribovore code>"
setenv RIBOINFERNALDIR "<full path to directory with infernal binaries (e.g. usr/local/bin)>"
setenv RIBOEASELDIR "<full path to directory with infernal's easel miniapp binaries (e.g. usr/local/bin)>"
setenv RIBOBLASTDIR "<full path to directory with blastn binary>"
setenv RIBOTIMEDIR "<full path to time binary (usually /usr/bin)>"
setenv VECPLUSDIR "<full path where vecscreen_plus_taxonomy git repo was downloaded>"
setenv SENSORDIR "<full path where rRNA_sensor git repo was downloaded>
setenv EPNOPTDIR "<full path where epn-options git repo was downloaded>"
setenv EPNOFILEDIR "<full path where epn-file git repo was downloaded>"
setenv EPNTESTDIR "<full path where epn-test git repo was downloaded>"
setenv PERL5LIB "$RIBODIR":$EPNOPTDIR":"$EPNOFILEDIR":"$EPNTESTDIR":"$PERL5LIB"
setenv PATH "$RIBODIR":"$PATH"
setenv BLASTDB "$SENSORDIR":"$BLASTDB"
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
setenv BLASTDB="$SENSORDIR"
for .cshrc. And then do
> source ~/.bashrc
or
> source ~/.cshrc
again.

###########################################################################
SAMPLE RUN

This example runs the script ribotyper.pl on a sample file of 16 sequences. 

You can run ribotyper only on sequence files that are in directories
to which you have write permission. Therefore, the first step is to copy the
example sequence file into a new directory. Move into that directory
and copy the example file with this command: 

> cp $RIBODIR/testfiles/example-16.fa ./

Then, execute the following command:

> ribotyper.pl example-16.fa test

The script takes 2 required command line arguments. Optional arguments are
explained later in this file.

The first required argument is the sequence file you want to annotate.

The second required argument is the name of the output subdirectory that you would
like ribotyper to create. Output files will be placed in this output
directory. If this directory already exists, the program will exit
with an error message indicating that you need to either (a) remove
the directory before rerunning, or (b) use the -f option with
ribotyper.pl, in which case the directory will be overwritten.
The command adding -f is
> ribotyper.pl -f example-16.fa test

The $RIBODIR environment variable is used implicitly in this
command. That is a hard-coded path that was set in the 'SETTING UP
ENVIRONMENT VARIABLES:' section above.

In an older version of ribotyper, additional command line arguments
were required to specify the locations the model files to use and the
model info file. These are no longer needed unless you want to use a
non-default model, which you can do with the -i option, as listed
below in the ALL COMMAND LINE OPTIONS section. Email
nawrocke@ncbi.nlm.nih.gov if you need help doing this.

##############################################################################
OUTPUT

Example output of the script from the above command
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
<[(ribotyper-v1)]> ./ribotyper.pl example-16.fa test
# ribotyper.pl :: detect and classify ribosomal RNA sequences
# ribotyper 0.29 (Oct 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:              Mon Oct 15 14:43:30 2018
# $RIBODIR:          /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1
# $RIBOEASELDIR:     /usr/local/infernal/1.1.2/bin
# $RIBOINFERNALDIR:  /usr/local/infernal/1.1.2/bin
#
# target sequence input file:  example-16.fa
# output directory name:       test         
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Validating input files                                                           ... done. [    0.3 seconds]
# Determining target sequence lengths                                              ... done. [    0.0 seconds]
# Classifying sequences                                                            ... done. [    2.3 seconds]
# Sorting classification results                                                   ... done. [    0.0 seconds]
# Processing classification results                                                ... done. [    0.0 seconds]
# Fetching per-model sequence sets                                                 ... done. [    0.0 seconds]
# Searching sequences against best-matching models                                 ... done. [    1.2 seconds]
# Concatenating tabular round 2 search results                                     ... done. [    0.0 seconds]
# Sorting search results                                                           ... done. [    0.0 seconds]
# Processing tabular round 2 search results                                        ... done. [    0.1 seconds]
# Creating final output files                                                      ... done. [    0.0 seconds]
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
  classification        16      7.1      9420.5      9420.5  00:00:02.26  (hh:mm:ss)
  search                15     13.0     17521.8     17521.8  00:00:01.16  (hh:mm:ss)
  total                 16      3.8      5039.4      5039.4  00:00:04.22  (hh:mm:ss)
#
#
# List and description of all output files saved in:   test.ribotyper.list
# Output printed to screen saved in:                   test.ribotyper.log
# List of executed commands saved in:                  test.ribotyper.cmd
# Short (6 column) output saved in:                    test.ribotyper.short.out
# Long (25 column) output saved in:                    test.ribotyper.long.out
#
# All output files created in directory ./test/
#
# Elapsed time:  00:00:04.22
#            hh:mm:ss
# 
# RIBO-SUCCESS
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
# Column 5 [p/f]:                 PASS or FAIL (reasons for failure begin with '*' in rightmost column)
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
#                              in model coordinates by 20 (--maxoverlap) positions or more
#  5.  *InconsistentHits       Not all hits (primary or secondary) are in the same order in the
#                              sequence and in the model.
#  6.  MinusStrand             Best hit is on the minus strand.
#  7.  LowScore                The bits per nucleotide (total bit score divided by total length
#                              of sequence) is below threshold of 0.5 (--lowppossc).
#  8.  LowCoverage             The total coverage of all hits (primary and secondary) to the best
#                              model (summed length of all hits divided by total length of sequence)
#                              is below threshold of 0.86 (--tcov).
#  9.  LowScoreDifference      The difference between the top two domains is below the 'low'
#                              threshold of 0.10 (--lowpdiff) bits per position (total bit score
#                              divided by summed length of all hits).
# 10.  VeryLowScoreDifference  The difference between the top two domains is below the 'very low'
#                              threshold of 0.04 (--vlowpdiff) bits per position (total bit score
#                              divided by summed length of all hits).
# 11.  MultipleHits            There is more than one hit to the best scoring model on the same strand.
#
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The Long file is not shown because it is so wide. 
An example is in testfiles/test.ribotyper.long.out 

##############################################################################
UNEXPECTED FEATURES AND REASONS FOR FAILURE

There are several 'unexpected features' of sequences that are detected
and reported in the rightmost column of both the short and long output
files. These unexpected features can cause a sequence to FAIL, as
explained below.  In this context, 'unexpected feature' is a euphemism for
'symptom of a likely problem'. A single problem can cause several features
to be reported. It is important to remember that the unexpected features
are symptoms, not root causes of problems.

There are 15 possible unexpected features that get reported, some of
which are related to each other. 11 of the 15 can arise when
ribotyper.pl is used with default arguments, and therefore appear in
the example above; the other four can arise only when specific
additional non-default arguments are used, as explained
below. Therefore, the list of 15 feaures below, with long
descriptions, subsumes the list of 11 features given above with
shorter descriptions.  Eight of the unexpectd features will always
cause a sequence to fail. The other seven unexpected features *can*
cause a sequence to fail, but only if specific command line options
are used.

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

4. "DuplicateRegion": At least two hits overlap in model coordinates
by P positions or more. The threshold P is 10 by default but can be
changed to <n> with the --maxoverlap <n> option. ALWAYS CAUSES
FAILURE.

5. "InconsistentHits": The hits to the best model are
inconsistent in that they are not in the same order in the sequence
and the model, possibly indicating a misassembly. ALWAYS CAUSES
FAILURE.

6. "UnacceptableModel": Best hit is to a model that is
'unacceptable'. By default, all models are acceptable, but the user
can specify only certain top-scoring models are 'acceptable' using the
--inaccept <s> option. If --inaccept is not used, this unexpected
feature will never be reported. An example of using --inaccept is
given below in the DEFINING ACCEPTABLE/QUESTIONABLE MODELS
section. ALWAYS CAUSES FAILURE.

7. "QuestionableModel": Best hit is to a model that is
'questionable'. By default, no models are questionable, but the user
can specify certain top-scoring models are 'questionable' using the
--inaccept <s> option. If --inaccept is not used, this unexpected
feature will never be reported. An example of using --inaccept is
given below in the DEFINING ACCEPTABLE/QUESTIONABLE MODELS
section. ONLY CAUSES FAILURE IF THE --questfail OPTION IS ENABLED.

8. "MinusStrand": The best hit is on the minus strand. ONLY CAUSES
FAILURE IF THE --minusfail OPTION IS ENABLED.

9. "LowScore": the bits per nucleotide
statistic (total bit score divided by length of total sequence (not
just length of hit)) is below threshold. By default the threshold is
0.5 bits per position, but this can be changed to <x> with the
"--lowppossc <x>" option. ONLY CAUSES FAILURE IF THE --scfail OPTION
IS ENABLED.

10. "LowCoverage": the total coverage of all hits to the best model
(summed length of all hits divided by total sequence length) is below
threshold. By default the threshold is 0.86, but it can be changed to
<x> with the --tcov <x> option; <x> should be between 0 and 1.
Additionally, one can set a different coverage threshold for 'short'
sequences using the --tshortcov <x1> option, which must be used in
combination with the --tshortlen <n> option which specifies that
sequences less than or equal to <n> nucleotides in length will be
subject to the coverage threshold <x1> from --tshortcov <x1>. ONLY
CAUSES FAILURE IF THE --covfail OPTION IS ENABLED.

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

14. "TooShort": the sequence is too short, less than <n1> nucleotides
in length. ALWAYS CAUSES FAILURE WHEN REPORTED BUT ONLY REPORTED IF
THE --shortfail <n1> OPTION IS ENABLED.

15. "TooLong": the sequence is too long, more than <n2> nucleotides in
length. ALWAYS CAUSES FAILURE WHEN REPORTED BUT ONLY REPORTED IF THE
--longfail <n2> OPTION IS ENABLED.

##############################################################################
THE DEFAULT MODEL FILE

The default model file used by ribotyper is here:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ribo.0p20.extra.cm

This model file includes 15 SSU rRNA profiles and 3 LSU rRNA profiles.

The 'modelinfo' file for this model file lists the models and some
additional information. That file is:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ribo.0p20.modelinfo

Here is the modelinfo file:
$ cat $RIBODIR/models/ribo.0p20.modelinfo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Each non-# prefixed line should have 4 white-space delimited tokens: 
#<modelname> <family> <domain> <CM-file-with-only-this-model>
# The first line is special, it indicates the name of the master CM file
# with all the models in it
#model                         family domain             cmfile
*all*                             -   -                  ribo.0p20.extra.cm
SSU_rRNA_archaea                  SSU Archaea            ribo.0p15.SSU_rRNA_archaea.cm
SSU_rRNA_bacteria                 SSU Bacteria           ribo.0p15.SSU_rRNA_bacteria.cm
SSU_rRNA_eukarya                  SSU Eukarya            ribo.0p15.SSU_rRNA_eukarya.cm
SSU_rRNA_microsporidia            SSU Euk-Microsporidia  ribo.0p15.SSU_rRNA_microsporidia.cm
SSU_rRNA_chloroplast              SSU Chloroplast        ribo.0p15.SSU_rRNA_chloroplast.cm
SSU_rRNA_mitochondria_metazoa     SSU Mito-Metazoa       ribo.0p15.SSU_rRNA_mitochondria_metazoa.cm
SSU_rRNA_cyanobacteria            SSU Bacteria           ribo.0p15.SSU_rRNA_cyanobacteria.cm
LSU_rRNA_archaea                  LSU Archaea            ribo.0p15.LSU_rRNA_archaea.cm
LSU_rRNA_bacteria                 LSU Bacteria           ribo.0p15.LSU_rRNA_bacteria.cm
LSU_rRNA_eukarya                  LSU Eukarya            ribo.0p15.LSU_rRNA_eukarya.cm
SSU_rRNA_apicoplast               SSU Euk-Apicoplast     ribo.0p20.SSU_rRNA_apicoplast.cm
SSU_rRNA_chloroplast_pilostyles   SSU Chloroplast        ribo.0p20.SSU_rRNA_chloroplast_pilostyles.cm
SSU_rRNA_mitochondria_amoeba      SSU Mito-Amoeba        ribo.0p20.SSU_rRNA_mitochondria_amoeba.cm
SSU_rRNA_mitochondria_chlorophyta SSU Mito-Chlorophyta   ribo.0p20.SSU_rRNA_mitochondria_chlorophyta.cm  
SSU_rRNA_mitochondria_fungi       SSU Mito-Fungi         ribo.0p20.SSU_rRNA_mitochondria_fungi.cm  
SSU_rRNA_mitochondria_kinetoplast SSU Mito-Kinetoplast   ribo.0p20.SSU_rRNA_mitochondria_kinetoplast.cm  
SSU_rRNA_mitochondria_plant       SSU Mito-Plant         ribo.0p20.SSU_rRNA_mitochondria_plant.cm  
SSU_rRNA_mitochondria_protist     SSU Mito-Protist       ribo.0p20.SSU_rRNA_mitochondria_protist.cm~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Using this file will classify sequences SSU and LSU sequences from any
of the listed domains. 

##############################################################################
RIBOTYPER'S TWO ROUND SEARCH STRATEGY

Ribotyper proceeds in two rounds. The first round is called the
classification stage. In this round, all models are compared against
all sequences using a fast profile HMM algorithm that does not do a
good job at defining boundaries of SSU/LSU sequences, but is good at
determining if a sequence is a SSU/LSU sequence or not. For each
comparison, a bit score is reported. For each sequence, the model that
gives that sequence the highest bit score is defined as the
'best-matching' model for that sequence.
 
In the second round, each model that is the best-matching model to at
least one sequence is searched again against only the set of sequences
that have it as their best-matching model. This time, a slower but
more powerful profile HMM algorithm is used that is better at defining
sequence boundaries. This round takes about as much time as the first
round even though the algorithm is slower because at most one model is
compared against each sequence. The results of this comparison are
reported to the short and long output files. Ribotyper also attempts
to detect certain 'unexpected features' for each sequence, as listed
in the 'UNEXPECTED FEATURES AND REASONS FOR FAILURE' section. Some of
these unexpected features, when they are detected for a sequence will
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
~~~~~~~~~~~~~~~~~~~~

##############################################################################
DEFINING ACCEPTABLE/QUESTIONABLE MODELS

The user can provide an additional input file that specifies which
models are 'acceptable' or 'questionable'. Within NCBI, this usage is
relevant when the submitter has made claims about which types of SSU
or LSU sequences are being submitted. In that situation, the models
consistent with the submitter's claims should be acceptable and all
other models should be questionable. All sequences for which the
highest ranked (by bit score unless the argument --evalues is used)
hit is NOT one of the acceptable or questionable models, will FAIL for
Reason 6 above. All sequences for which the top hit is one of the
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

To use this on the example run from above, try the --inaccept
option, like this:

$ ribotyper.pl -f --inaccept $RIBODIR/testfiles/ssu.arc.quest.bac.accept example-16.fa test

Now, the short output file will set any family that was classified as a
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

# ribotyper.pl :: detect and classify ribosomal RNA sequences
# ribotyper 0.29 (Oct 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Mon Oct 15 14:48:36 2018
#
Usage: ribotyper.pl [-options] <fasta file to annotate> <output directory>


basic options:
  -f     : force; if <output directory> exists, overwrite it
  -v     : be verbose; output commands to stdout as they're run
  -n <n> : use <n> CPUs [0]
  -i <s> : use model info file <s> instead of default
  -s <n> : seed for random number generator is <n> [181]

options for controlling the first round search algorithm:
  --1hmm  : run first round in slower HMM mode
  --1slow : run first round in slow CM mode that scores structure+sequence

options for controlling the second round search algorithm:
  --2slow : run second round in slow CM mode that scores structure+sequence

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
  --esdfail       : seqs in which second best hit by E-value has better bit score above threshold FAIL

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
  --maxoverlap <n> : set maximum allowed number of model positions to overlap b/t 2 hits before failure to <n> [20]
  --esdmaxsc <x>   : set maximum allowed bit score difference for E-value/score discrepancies to <x> [0.001]

optional input files:
  --inaccept <s> : read acceptable/questionable domains/models from file <s>

options that modify the behavior of --1slow or --2slow:
  --mid         : with --1slow/--2slow use cmsearch --mid option instead of --rfam
  --max         : with --1slow/--2slow use cmsearch --max option instead of --rfam
  --smxsize <x> : with --max also use cmsearch --smxsize <x>

options for parallelizing cmsearch on a compute farm:
  -p         : parallelize cmsearch on a compute farm
  -q <s>     : use qsub info file <s> instead of default
  --nkb <n>  : number of KB of sequence for each cmsearch farm job is <n> [10]
  --wait <n> : allow <n> wall-clock minutes for cmsearch jobs on farm to finish, including queueing time [500]
  --errcheck : consider any farm stderr output as indicating a job failure

options for controlling gap type definitions:
  --mgap <n> : maximum size of a 'small' gap in model coordinates is <n> [10]
  --sgap <n> : maximum size of a 'small' gap in sequence coordinates is <n> [10]

options for creating additional output files:
  --outseqs      : save per-model pass/fail sequences to files
  --outhits      : save per-model pass/fail sequences to files
  --outgaps      : save gap sequences between hits to a file
  --outxgaps <n> : save gap sequence file with <n> added nts [20]
  --keep         : keep all intermediate files that are removed by default

advanced options:
  --evalues    : rank hits by E-values, not bit scores
  --skipsearch : skip search stage, use results from earlier run
  --noali      : no alignments in output, requires --keep
  --samedomain : top two hits can be to models in the same domain

##############################################################################
ADDITIONAL SCRIPT: riboaligner.pl

The script 'riboaligner.pl' is also included in the ribotyper
distribution. It is a 'wrapper' script for ribotyper.pl. It runs
ribotyper.pl and does some additional post-processing. Specifically,
it aligns all the sequences that ribotyper.pl has defined as belonging
to certain categories (by default SSU.archaea and SSU.bacteria) and
classifies the length of those sequences. (The default set of
categories can be changed using the -i option.) This script can be
useful if you are trying to determine which sequences are full length
or partial in your dataset.

Setup: if you followed the instructions above and can
successfully run ribotyper.pl you should be able to also run
riboaligner.pl.

Following, is an example run using the file example-rlc-11.fa in the
testfiles/ directory, with output. In the example, the command given is: 
> riboaligner.pl $RIBODIR/testfiles/example-rlc-11.fa test-rlc

If you did not fully copy or clone the ribotyper files and set $RIBODIR to
a directory in which you have write permission, then you should run instead
> riboaligner.pl <user directory>/testfiles/example-rlc-11.fa test-rlc

where <user directory> is the directory in which riboaligner.pl is installed.

> riboaligner.pl $RIBODIR/testfiles/example-rlc-11.fa test-ra
--------------
# riboaligner.pl :: classify lengths of ribosomal RNA sequences
# ribotyper 0.29 (Oct 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:              Mon Oct 15 14:49:05 2018
# $RIBODIR:          /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1
# $RIBOEASELDIR:     /usr/local/infernal/1.1.2/bin
# $RIBOINFERNALDIR:  /usr/local/infernal/1.1.2/bin
#
# Validating input files                           ... done. [    0.0 seconds]
# Running ribotyper                                ... done. [    5.2 seconds]
# Running cmalign and classifying sequence lengths ... done. [    5.4 seconds]
# Extracting alignments for each length class      ... done. [    0.3 seconds]
#
# WARNING: 1 sequence(s) were not aligned because they were not classified by ribotyper into one of: SSU.Archaea SSU.Bacteria
#  01223::Audouinella_hermannii.::AF026040
#
# See details in:
#  test-ra/test-ra.riboaligner-rt/test-ra.riboaligner-rt.ribotyper.short.out
#  and
#  test-ra/test-ra.riboaligner-rt/test-ra.riboaligner-rt.ribotyper.long.out
#
#
# ribotyper output saved as test-ra/test-ra.riboaligner.ribotyper.out
# ribotyper output directory saved as test-ra/test-ra.riboaligner-rt
#
# Tabular output saved to file test-ra/test-ra.riboaligner.tbl
#
# List and description of all output files saved in:                               test-ra.riboaligner.list
# Output printed to screen saved in:                                               test-ra.riboaligner.log
# List of executed commands saved in:                                              test-ra.riboaligner.cmd
# insert file for SSU.Archaea saved in:                                            test-ra.riboaligner.SSU.Archaea.cmalign.ifile
# EL file for SSU.Archaea saved in:                                                test-ra.riboaligner.SSU.Archaea.cmalign.elfile
# stockholm alignment file for SSU.Archaea saved in:                               test-ra.riboaligner.SSU.Archaea.cmalign.stk
# cmalign output file for SSU.Archaea saved in:                                    test-ra.riboaligner.SSU.Archaea.cmalign.out
# insert file for SSU.Bacteria saved in:                                           test-ra.riboaligner.SSU.Bacteria.cmalign.ifile
# EL file for SSU.Bacteria saved in:                                               test-ra.riboaligner.SSU.Bacteria.cmalign.elfile
# stockholm alignment file for SSU.Bacteria saved in:                              test-ra.riboaligner.SSU.Bacteria.cmalign.stk
# cmalign output file for SSU.Bacteria saved in:                                   test-ra.riboaligner.SSU.Bacteria.cmalign.out
# List file          for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.list
# Alignment          for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.stk
# Insert file        for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.ifile
# EL file            for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.elfile
# cmalign output     for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.cmalign
# List file          for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.list
# Alignment          for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.stk
# Insert file        for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.ifile
# EL file            for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.elfile
# cmalign output     for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.cmalign
# List file          for      1 SSU.Bacteria full-exact sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-exact.list
# Alignment          for      1 SSU.Bacteria full-exact sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-exact.stk
# Insert file        for      1 SSU.Bacteria full-exact sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-exact.ifile
# EL file            for      1 SSU.Bacteria full-exact sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-exact.elfile
# cmalign output     for      1 SSU.Bacteria full-exact sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-exact.cmalign
# List file          for      1 SSU.Bacteria full-extra sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-extra.list
# Alignment          for      1 SSU.Bacteria full-extra sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-extra.stk
# Insert file        for      1 SSU.Bacteria full-extra sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-extra.ifile
# EL file            for      1 SSU.Bacteria full-extra sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-extra.elfile
# cmalign output     for      1 SSU.Bacteria full-extra sequences saved in:        test-ra.riboaligner.SSU.Bacteria.full-extra.cmalign
#
# All output files created in directory ./test-ra/
#
# Elapsed time:  00:00:10.90
#            hh:mm:ss
# 
# RIBO-SUCCESS
--------------

The output of the program (above) lists all of the files that were
created, including a ribotyper output directory (test-ra-rt) and
ribotyper standard output file (test-ra.ribotyper.out). The tabular
output file created by riboaligner.pl
(ra-test.riboaligner.tbl) is the same as the 'short' output
format of ribotyper.pl with three additional columns pertaining to the
length of each sequence including a classification of that length. The
end of the tabular output file has comments explaining those columns
as well as the definitions of each length classification.

The alignment files
(e.g. test-ra.riboaligner.SSU.Bacteria.full-ambig-more.stk)
are in 'Stockholm' format created by Infernal's cmalign program. There
is a wiki page describing the Stockholm format:
https://en.wikipedia.org/wiki/Stockholm_format, but a more helpful
resource is the Infernal v1.1.2 user's guide, pages 29 and 30, which
is available here:
http://eddylab.org/infernal/Userguide.pdf.

Here, are the relevant lines from the file ra-test.riboaligner.tbl
created by the above command:

> cat test-ra/test-ra.riboaligner.tbl
-----------------------
# Column 6 [mstart]:              model start position
# Column 7 [mstop]:               model stop position
# Column 8 [length_class]:        classification of length, one of:
#                                 'partial:'             does not extend to first model position or final model position
#                                 'full-exact':          spans full model and no 5' or 3' inserts
#                                                        and no indels in first or final 10 model positions
#                                 'full-extra':          spans full model but has 5' and/or 3' inserts
#                                 'full-ambig-more':     spans full model and no 5' or 3' inserts
#                                                        but has indel(s) in first and/or final 10 model positions
#                                                        and insertions outnumber deletions at 5' and/or 3' end
#                                 'full-ambig-less':     spans full model and no 5' or 3' inserts
#                                                        but has indel(s) in first and/or final 10 model positions
#                                                        and insertions do not outnumber deletions at neither 5' nor 3' end
#                                 '5flush-exact':        extends to first but not final model position, has no 5' inserts
#                                                        and no indels in first 10 model positions
#                                 '5flush-extra':        extends to first but not final model position and has 5' inserts
#                                 '5flush-ambig-more':   extends to first but not final model position and has no 5' inserts
#                                                        but has indel(s) in first 10 model positions
#                                                        and insertions outnumber deletions at 5' end
#                                 '5flush-ambig-less':   extends to first but not final model position and has no 5' inserts
#                                                        but has indel(s) in first 10 model positions
#                                                        and insertions do not outnumber deletions at 5' end
#                                 '3flush-exact':        extends to final but not first model position, has no 3' inserts
#                                                        and no indels in final 10 model positions
#                                 '3flush-extra':        extends to final but not first model position and has 3' inserts
#                                 '3flush-ambig-more':   extends to final but not first model position and has no 3' inserts
#                                                        but has indel(s) in final 10 model positions
#                                                        and insertions outnumber deletions at 3' end
#                                 '3flush-ambig-less':   extends to final but not first model position and has no 3' inserts
#                                                        but has indel(s) in final 10 model positions
#                                                        and insertions do not outnumber deletions at 3' end
-----------------------
Columns 1-5 and 9 are redundant with columns 1-6 in the 'short' format
output file from ribotyper.pl. 

You can see the command-line options for riboaligner.pl using
the -h option, just as with ribotyper.pl:

> riboaligner.pl -h
# riboaligner.pl :: classify lengths of ribosomal RNA sequences
# ribotyper 0.29 (Oct 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Mon Oct 15 14:50:35 2018
#
Usage: riboaligner.pl [-options] <fasta file to annotate> <output file name root>


basic options:
  -f     : force; if <output directory> exists, overwrite it
  -b <n> : number of positions <n> to look for indels at the 5' and 3' boundaries [10]
  -v     : be verbose; output commands to stdout as they're run
  -n <n> : use <n> CPUs [1]
  -i <s> : use model info file <s> instead of default
  -s <n> : seed for random number generator is <n> [181]
  --keep : keep all intermediate files that are removed by default

options related to the internal call to ribotyper.pl:
  --riboopts <s> : read command line options to supply to ribotyper from file <s>
  --noscfail     : do not fail sequences in ribotyper with low scores
  --nocovfail    : do not fail sequences in ribotyper with low coverage

options for parallelizing cmsearch and cmalign on a compute farm:
  -p         : parallelize cmsearch on a compute farm
  -q <s>     : use qsub info file <s> instead of default
  --nkb <n>  : number of KB of sequence for each farm job is <n> [10]
  --wait <n> : allow <n> wall-clock minutes for jobs on farm to finish, including queueing time [500]
  --errcheck : consider any farm stderr output as indicating a job failure

One important command line option to riboaligner.pl is 
the -b option. This controls how many model positions are examined at
the 5' and 3' ends when classifying the lengths of sequences,
especially 'full-ambig' sequences. The default value is 10, but this
can be changed to <n> with '-b <n>'.

Another important option is --riboopts <s> which allows you to
pass options to ribotyper. To use this option, create a file called
<s>, with a single line with all the options you want passed to
ribotyper, and use --riboopts <s> when you call riboaligner.pl.
Not all ribotyper options can appear in this file <s>. The -f and
--keep options are not allowed (the program will die with an error
message if you include them) because they are used automatically when
riboaligner.pl calls ribotyper.pl. Additionally, -n <d> is not
allowed to control the number of CPUs that ribotyper uses. If you want
to control the number of CPUs, pass -n <d> to riboaligner.pl
instead. 

-----------------------------
##############################################################################
ADDITIONAL SCRIPT: ribodbmaker.pl

The script 'ribodbmaker.pl' is also included in the ribotyper
distribution. This script is designed to start from an input file of
many candidate ribosomal RNA sequences and to subject them to various
tests/filters to produce a high quality subset of those sequences.

This script performs the following tests:

 - fail sequences with too many ambiguous nucleotides
 - fail sequences that do not have a specified species taxid
 - fail sequences that have non-Weak VecScreen hits
 - fail sequences that have repetitive sequences revealed by
   self-BLAST
 - fail sequences that fail ribotyper
 - fail sequences that fail riboaligner
 - fail sequences that do cover a specified span of model positions
   (are too short)

Sequences that pass all these tests are subjected to a 'ingroup
analysis' taxonomic test, and any sequences that do not cluster with
other sequences in their taxonomic group are removed.

Sequences that survive that are then (optionally) clustered and
centroids for each cluster are selected.

Setup: if you followed the instructions above and can
successfully run ribotyper.pl you should be able to also run
ribodbmaker.pl.

There are two common usage cases for ribodbmaker.pl:

Usage 1: create a representative database of high quality sequences 
Usage 2: create a subset of high quality sequences

Below is an example of a run for each usage case, using a randomly
selected set of 100 fungal SSU rRNA sequences - the
testfiles/fungi-ssu.r100.fa file.

Usage 1: create a representative database of high quality sequences 
> ribodbmaker.pl -f --model SSU.Eukarya --skipfribo1 --ribo2hmm $RIBODIR/testfiles/fungi-ssu.r100.fa u1-r100

-------------
# ribodbmaker.pl :: create representative database of ribosomal RNA sequences
# ribotyper 0.29 (Oct 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:           Mon Oct 15 14:50:54 2018
# $RIBOBLASTDIR:  /usr/bin
# $RIBODIR:       /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1
# $RIBOEASELDIR:  /usr/local/infernal/1.1.2/bin
# $RIBOTAXDIR:    /panfs/pan1/dnaorg/rrna/git-ncbi-rrna-project/taxonomy-files
# $VECPLUSDIR:    /panfs/pan1/dnaorg/ssudetection/code/vecscreen_plus_taxonomy
#
# input sequence file:                                          /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1/testfiles/fungi-ssu.r100.fa
# output directory name:                                        u1-r100                                                                                         
# forcing directory overwrite:                                  yes [-f]                                                                                        
# skip 1st stage that filters based on ribotyper:               yes [--skipfribo1]                                                                              
# model to use is <s>:                                          SSU.Eukarya [--model]                                                                           
# run ribotyper stage 2 in HMM-only mode (do not use --2slow):  yes [--ribo2hmm]                                                                                
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# [Stage: prelim] Validating input files                                           ... done. [    0.0 seconds]
# [Stage: prelim] Copying input fasta file                                         ... done. [    0.1 seconds]
# [Stage: prelim] Reformatting names of sequences                                  ... done. [    0.0 seconds]
# [Stage: prelim] Determining target sequence lengths                              ... done. [    0.1 seconds]
# [Stage: prelim] Running srcchk for all sequences                                 ... done. [   35.5 seconds]
# [Stage: fambig] Filtering based on ambiguous nucleotides                         ... done. [    0.0 seconds,     95 pass;      5 fail;]
# [Stage: ftaxid] Filtering for specified species                                  ... done. [    3.9 seconds,     61 pass;     39 fail;]
# [Stage: fvecsc] Identifying vector sequences with VecScreen                      ... done. [    4.4 seconds,     99 pass;      1 fail;]
# [Stage: fblast] Identifying repeats by BLASTing against self                     ... done. [    2.4 seconds,    100 pass;      0 fail;]
# [Stage: fribo2] Running riboaligner.pl                                           ... done. [   66.1 seconds,     70 pass;     30 fail;]
# [Stage: fribo2] Filtering out seqs riboaligner identified as too long            ... done. [    0.0 seconds,     70 pass;      0 fail;]
# [Stage: fmspan] Filtering out seqs based on model span                           ... done. [    0.0 seconds,     32 pass;     38 fail;]
# [***Checkpoint] Creating lists that survived all filter stages                   ... done. [    0.0 seconds,     18 pass;     82 fail; ONLY PASSES ADVANCE]
# [Stage: ingrup] Determining percent identities in alignments                     ... done. [    0.1 seconds]
# [Stage: ingrup] Performing ingroup analysis                                      ... done. [    1.2 seconds,     18 pass;      0 fail;]
# [Stage: ingrup] Identifying phyla lost in ingroup analysis                       ... done. [    0.0 seconds, 0 phyla lost]
# [Stage: ingrup] Identifying classes lost in ingroup analysis                     ... done. [    0.0 seconds, 0 classes lost]
# [Stage: ingrup] Identifying orders lost in ingroup analysis                      ... done. [    0.0 seconds, 0 orders lost]
# [***Checkpoint] Creating lists that survived ingroup analysis                    ... done. [    0.0 seconds,     18 pass;      0 fail; ONLY PASSES ADVANCE]
# [***OutputFile] Generating model span survival tables for all seqs               ... done. [    6.5 seconds]
# [***OutputFile] Generating model span survival tables for PASSing seqs           ... done. [    4.4 seconds]
# [Stage: clustr] Clustering surviving sequences                                   ... done. [    0.1 seconds]
# [***Checkpoint] Creating lists of seqs that survived clustering                  ... done. [    0.0 seconds,      9 pass;      9 fail;]
#
# Number of input sequences:                                                100  [listed in u1-r100/u1-r100.ribodbmaker.full.seqlist]
# Number surviving all filter stages:                                        18  [listed in u1-r100/u1-r100.ribodbmaker.surv_filters.pass.seqlist]
# Number surviving ingroup analysis:                                         18  [listed in u1-r100/u1-r100.ribodbmaker.surv_ingrup.pass.seqlist]
# Number surviving clustering (number of clusters):                           9  [listed in u1-r100/u1-r100.ribodbmaker.surv_clustr.pass.seqlist]
# Number in final set of surviving sequences:                                 9  [listed in u1-r100/u1-r100.ribodbmaker.final.pass.seqlist]
# Number of phyla   represented in final set of surviving sequences:          4  [listed in final line of u1-r100/u1-r100.ribodbmaker.phylum.ct]
# Number of classes represented in final set of surviving sequences:          8  [listed in final line of u1-r100/u1-r100.ribodbmaker.class.ct]
# Number of orders  represented in final set of surviving sequences:          9  [listed in final line of u1-r100/u1-r100.ribodbmaker.order.ct]
#
# Output printed to screen saved in:                                                          u1-r100.ribodbmaker.log
# List of executed commands saved in:                                                         u1-r100.ribodbmaker.cmd
# List and description of all output files saved in:                                          u1-r100.ribodbmaker.list
# list of 0 phyla lost in the ingroup analysis saved in:                                      u1-r100.ribodbmaker.ingrup.phylum.lost.list
# list of 0 classes lost in the ingroup analysis saved in:                                    u1-r100.ribodbmaker.ingrup.class.lost.list
# list of 0 orders lost in the ingroup analysis saved in:                                     u1-r100.ribodbmaker.ingrup.order.lost.list
# table summarizing number of sequences (all) for different model position spans saved in:    u1-r100.ribodbmaker.all.mdlspan.survtbl
# table summarizing number of sequences (pass) for different model position spans saved in:   u1-r100.ribodbmaker.pass.mdlspan.survtbl
# fasta file with final set of surviving sequences saved in:                                  u1-r100.ribodbmaker.final.fa
# tab-delimited file listing number of sequences per phylum taxid saved in:                   u1-r100.ribodbmaker.phylum.ct
# tab-delimited file listing number of sequences per class taxid saved in:                    u1-r100.ribodbmaker.class.ct
# tab-delimited file listing number of sequences per order taxid saved in:                    u1-r100.ribodbmaker.order.ct
# tab-delimited tabular output summary file saved in:                                         u1-r100.ribodbmaker.tab.tbl
# whitespace-delimited, more readable output summary file saved in:                           u1-r100.ribodbmaker.rdb.tbl
#
# All output files created in directory ./u1-r100/
#
# Elapsed time:  00:02:04.97
#            hh:mm:ss
# 
# RIBO-SUCCESS
-------------

The output indicates how many sequences pass and fail each test. In
this example, only 16 of the 100 sequences pass all the filter stages. Of
these, 15 survive the 'ingroup analysis'. And 5 survive the clustering
step.

Many output files are created. For a complete list see
u1-r100/u1-r100.ribodbmaker.list. But, the most important output files
are listed in the main output. The .tab.tbl and .rdb.tbl files are the
summary output files. They contain the same information, but the
.tab.tbl file is tab-delimited, and the .rdb.tbl is more human
readable.

Here is the output for the first 10 sequences from the .rdb.tbl
file. The beginning of the file explains the information in each column:

# Explanation of columns:
# Column  1: 'idx':     index of sequence in input file
# Column  2: 'seqname': name of sequence
# Column  3: 'seqlen':  length of sequence
# Column  4: 'staxid':  taxid of sequence (species level), '-' if all taxid related steps were skipped
# Column  5: 'otaxid':  taxid of sequence (order level), '-' if all taxid related steps were skipped
# Column  6: 'ctaxid':  taxid of sequence (class level), '-' if all taxid related steps were skipped
# Column  7: 'ptaxid':  taxid of sequence (phylum level), '-' if all taxid related steps were skipped
# Column  8: 'p/f':     PASS if sequence passed all filters and ingroup analysis else FAIL
# Column  9: 'clust':   'C' if sequence selected as centroid of a cluster, 'NC' if not
# Column 10: 'special': '-' for all sequences because --special not used
# Column 11: 'failstr': '-' for PASSing sequences, else list of reasons for FAILure, see below
#
# Possible substrings in 'failstr' column 11, each substring separated by ';;':
# 'ambig[<d>]':            contains <d> ambiguous nucleotides, which exceeds maximum allowed
# 'not-in-tax-tree':       sequence taxid is not present in the input NCBI taxonomy tree
# 'not-specified-species': sequence does not belong to a specified species according to NCBI taxonomy
# 'vecscreen-match[<s>]':  vecscreen reported match to vector of strength <s>
# 'blastrepeat[<s>]':      repetitive sequence identified by blastn
#                          <s> = <s1>,<s2>,...<sI>...<sN> for N >= 1, where
#                          <sI> = <c1>|e=<g1>|len=<d1>|<d2>..<d3>/<d4>..<d5>|pid=<f1>|ngap=<d6>
#                          <c1> = + for positive strand, - for negative strand
#                          <g1> = E-value of hit
#                          <d1> = maximum of query length and subject length in hit alignment
#                          <d2>..<d3> = query coordinates of hit
#                          <d4>..<d5> = subject coordinates of hit
#                          <f1> = fractional identity of hit alignment
#                          <d6> = number of gaps in hit alignment
# 'ribotyper2[<s>]:        ribotyper (riboaligner) failure with unexpected features listed in <s>
#                          see u1-r100/u1-r100.ribodbmaker-ra/u1-r100-ra.ribotyper.long.out
#                          for explanation of unexpected features
# 'riboaligner[<s>]:       riboaligner failure because sequence is too long or potentially too long
#                          <s>=full-extra:        alignment spans full model with >= 1 nt extra on 5' or 3' end
#                          <s>=full-ambig-more:   alignment spans full model with 0 nt extra on 5' or 3' end but
#                                                 has indels in first and/or final 10 model positions and
#                                                 insertions outnumber deletions at 5' and/or 3' end
#                          <s>=5flush-extra:      alignment extends to first but not final model position
#                                                 with >= 1 nt extra before first model position
#                          <s>=5flush-ambig-more: alignment extends to first but not final model position
#                                                 and has indels in first 10 model positions and
#                                                 insertions outnumber deletions at 5' end
#                          <s>=3flush-extra:      alignment extends to final but not first model position
#                                                 with >= 1 nt extra after final model position
#                          <s>=3flush-ambig-more: alignment extends to final but not first model position
#                                                 and has indels in final 10 model positions and
#                                                 insertions outnumber deletions at 3' end
# 'mdlspan[<d1>-<d2>]:     alignment of sequence does not span required model positions, model span is <d1> to <d2>
# 'ingroup-analysis[<s>]:  sequence failed ingroup analysis
#                          if <s> includes 'type=<s1>', sequence was classified as type <s1>
#                          see u1-r100/u1-r100.ribodbmaker.ingrup.order.alipid_analyze.out for explanation of types
#idx  seqname     seqlen   staxid   otaxid   ctaxid   ptaxid   p/f  clust  special  failstr
1     KC674542.1    1809   175245        1        1        1  FAIL      -        -  not-specified-species;;vecscreen-match[None];;ribotyper2[*LowCoverage:(0.972<0.990);];;
2     EU278606.1    1737   209559     5042   147545     4890  FAIL      -        -  ribotyper2[*LowCoverage:(0.990<0.990);];;
3     AB034910.1    1763    36909     4892     4891     4890  PASS      C        -  -
4     KC670242.1    1741   175245        1        1        1  FAIL      -        -  not-specified-species;;
5     MG520986.1    1063  1821266    92860   147541     4890  FAIL      -        -  ribotyper2[*LowCoverage:(0.678<0.990);*MultipleHits:(2:SI[M:-1(568..568),S:338(510..847)]);];;
6     DQ677995.1    1644    45130    92860   147541     4890  FAIL      -        -  mdlspan[86-1781];;
7     KX352732.1    1280   586133        1        1     6029  FAIL      -        -  ribotyper2[*UnacceptableModel:(SSU_rRNA_microsporidia);*LowCoverage:(0.981<0.990);];;
8     AB220232.1    1723   112178    37989   147550     4890  PASS     NC        -  -
9     KC674843.1    1736   175245        1        1        1  FAIL      -        -  not-specified-species;;
10    JX644478.1    1042   443158     4827  2212703  1913637  FAIL      -        -  mdlspan[68-1117];;

-------------------------------
Usage 2: create a subset of high quality sequences
> ribodbmaker.pl -f --model SSU.Eukarya --skipclustr $RIBODIR/testfiles/fungi-ssu.r100.fa u2-r100
# ribodbmaker.pl :: create representative database of ribosomal RNA sequences
# ribotyper 0.28 (Sep 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:           Mon Oct 15 14:54:42 2018
# $RIBOBLASTDIR:  /usr/bin
# $RIBODIR:       /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1
# $RIBOEASELDIR:  /usr/local/infernal/1.1.2/bin
# $RIBOTAXDIR:    /panfs/pan1/dnaorg/rrna/git-ncbi-rrna-project/taxonomy-files
# $VECPLUSDIR:    /panfs/pan1/dnaorg/ssudetection/code/vecscreen_plus_taxonomy
#
# input sequence file:                           /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1/testfiles/fungi-ssu.r100.fa
# output directory name:                         u2-r100                                                                                         
# forcing directory overwrite:                   yes [-f]                                                                                        
# skip stage that clusters surviving sequences:  yes [--skipclustr]                                                                              
# model to use is <s>:                           SSU.Eukarya [--model]                                                                           
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# [Stage: prelim] Validating input files                                           ... done. [    0.0 seconds]
# [Stage: prelim] Copying input fasta file                                         ... done. [    0.0 seconds]
# [Stage: prelim] Reformatting names of sequences                                  ... done. [    0.0 seconds]
# [Stage: prelim] Determining target sequence lengths                              ... done. [    0.1 seconds]
# [Stage: prelim] Running srcchk for all sequences                                 ... done. [   35.9 seconds]
# [Stage: fambig] Filtering based on ambiguous nucleotides                         ... done. [    0.0 seconds,     95 pass;      5 fail;]
# [Stage: ftaxid] Filtering for specified species                                  ... done. [    4.2 seconds,     61 pass;     39 fail;]
# [Stage: fvecsc] Identifying vector sequences with VecScreen                      ... done. [    2.8 seconds,     99 pass;      1 fail;]
# [Stage: fblast] Identifying repeats by BLASTing against self                     ... done. [    2.9 seconds,    100 pass;      0 fail;]
# [Stage: fribo1] Running ribotyper.pl                                             ... done. [   21.2 seconds,     94 pass;      6 fail;]
# [Stage: fribo2] Running riboaligner.pl                                           ... done. [  339.9 seconds,     92 pass;      8 fail;]
# [Stage: fribo2] Filtering out seqs riboaligner identified as too long            ... done. [    0.0 seconds,     92 pass;      0 fail;]
# [Stage: fmspan] Filtering out seqs based on model span                           ... done. [    0.0 seconds,     44 pass;     48 fail;]
# [***Checkpoint] Creating lists that survived all filter stages                   ... done. [    0.0 seconds,     19 pass;     81 fail; ONLY PASSES ADVANCE]
# [Stage: ingrup] Determining percent identities in alignments                     ... done. [    0.0 seconds]
# [Stage: ingrup] Performing ingroup analysis                                      ... done. [    1.2 seconds,     19 pass;      0 fail;]
# [Stage: ingrup] Identifying phyla lost in ingroup analysis                       ... done. [    0.0 seconds, 0 phyla lost]
# [Stage: ingrup] Identifying classes lost in ingroup analysis                     ... done. [    0.0 seconds, 0 classes lost]
# [Stage: ingrup] Identifying orders lost in ingroup analysis                      ... done. [    0.0 seconds, 0 orders lost]
# [***Checkpoint] Creating lists that survived ingroup analysis                    ... done. [    0.0 seconds,     19 pass;      0 fail; ONLY PASSES ADVANCE]
# [***OutputFile] Generating model span survival tables for all seqs               ... done. [    9.7 seconds]
# [***OutputFile] Generating model span survival tables for PASSing seqs           ... done. [    3.2 seconds]
#
# Number of input sequences:                                                100  [listed in u2-r100/u2-r100.ribodbmaker.full.seqlist]
# Number surviving all filter stages:                                        19  [listed in u2-r100/u2-r100.ribodbmaker.surv_filters.pass.seqlist]
# Number surviving ingroup analysis:                                         19  [listed in u2-r100/u2-r100.ribodbmaker.surv_ingrup.pass.seqlist]
# Number in final set of surviving sequences:                                19  [listed in u2-r100/u2-r100.ribodbmaker.final.pass.seqlist]
# Number of phyla   represented in final set of surviving sequences:          4  [listed in final line of u2-r100/u2-r100.ribodbmaker.phylum.ct]
# Number of classes represented in final set of surviving sequences:         10  [listed in final line of u2-r100/u2-r100.ribodbmaker.class.ct]
# Number of orders  represented in final set of surviving sequences:         11  [listed in final line of u2-r100/u2-r100.ribodbmaker.order.ct]
#
# Output printed to screen saved in:                                                          u2-r100.ribodbmaker.log
# List of executed commands saved in:                                                         u2-r100.ribodbmaker.cmd
# List and description of all output files saved in:                                          u2-r100.ribodbmaker.list
# list of 0 phyla lost in the ingroup analysis saved in:                                      u2-r100.ribodbmaker.ingrup.phylum.lost.list
# list of 0 classes lost in the ingroup analysis saved in:                                    u2-r100.ribodbmaker.ingrup.class.lost.list
# list of 0 orders lost in the ingroup analysis saved in:                                     u2-r100.ribodbmaker.ingrup.order.lost.list
# table summarizing number of sequences (all) for different model position spans saved in:    u2-r100.ribodbmaker.all.mdlspan.survtbl
# table summarizing number of sequences (pass) for different model position spans saved in:   u2-r100.ribodbmaker.pass.mdlspan.survtbl
# fasta file with final set of surviving sequences saved in:                                  u2-r100.ribodbmaker.final.fa
# tab-delimited file listing number of sequences per phylum taxid saved in:                   u2-r100.ribodbmaker.phylum.ct
# tab-delimited file listing number of sequences per class taxid saved in:                    u2-r100.ribodbmaker.class.ct
# tab-delimited file listing number of sequences per order taxid saved in:                    u2-r100.ribodbmaker.order.ct
# tab-delimited tabular output summary file saved in:                                         u2-r100.ribodbmaker.tab.tbl
# whitespace-delimited, more readable output summary file saved in:                           u2-r100.ribodbmaker.rdb.tbl
#
# All output files created in directory ./u2-r100/
#
# Elapsed time:  00:07:01.61
#            hh:mm:ss
# 
# RIBO-SUCCESS

The main difference with usage 2 is the lack of the clustering step,
and a longer fribo2 stage due to the lack of the --ribo2hmm
option. This makes riboaligner use a slower algorithm that
incorporates sequence and structure conservation when it examines
sequences. 

You can speed up this script (and ribotyper.pl and riboaligner.pl)
using the -p option. See the PARALLELIZING ON A SGE COMPUTE FARM
section below.

##############################################################################
ADDITIONAL SCRIPT: ribosensor.pl

This is documentation for ribosensor, a tool for detecting and
classifying small subunit (SSU) and large subunit (LSU) rRNA
sequences.  ribosensor uses profile hidden markov models (HMMs) and
BLASTN.

Authors: Eric Nawrocki and Alejandro Schaffer
National Center for Biotechnology Information 

The initial setup of ribosensor is intended for internal NCBI usage in
evaluating submissions. It is expected that ribosensor will be
incorporated into the internal National Center for Biotechnology
Information (NCBI) software architecture called gpipe. Therefore, at
this time, some of the documentation is on internal Confluence pages,
some of the instructions below are specifically for usage within NCBI,
and some of the error reporting is structured in a manner that
conforms to established gpipe practices for error reporting. The
intended usage of ribosensor will be more effective if submitters of
SSU/LSU rRNA sequences can also use ribosensor in a manner that is
consistent with the expected usage within NCBI. Therefore, the
instructions below are general enough that ribosensor should be usable
outside NCBI.

----------------------------------------------------------------------------
WHAT RIBOSENSOR DOES

Ribosensor is a wrapper program that calls two other programs:
ribotyper and rRNA_sensor (henceforth, called 'sensor') and combines
their output together. Ribotyper uses profile HMMs to identify and
classify small subunit (SSU) ribosomal RNA sequences (archaeal,
bacterial, eukaryotic) and large subunit (LSU) ribosomal RNA
sequences. Ribosensor uses BLASTN to identify bacterial and archaeal
16S SSU rRNA sequences using a library of type strain archaeal and
bacterial 16S sequences. Alternatively, Ribosensor can be used to
identify eukaryotic 18S SSU rRNA sequences. It is limited to 16S and
18S rRNAs because those are the only rRNA genes for which NCBI currently
has a sufficiently large and representative database that is of high
enough quality to be trustworthy. Based on the output of both
programs, ribosensor decides if each input sequence "passes" or
"fails". When ribosensor is used to evaluate candidate submissions to
GenBank, the intent is that sequences that pass should be accepted for
submission to GenBank as archaeal or bacterial 16S SSU rRNA sequences
(or 18S SSU rRNA sequences), and sequences that fail should not.

For sequences that fail, reasons for failure are reported in the form
of sensor, ribotyper, and/or gpipe errors. These errors and their
relationship are described in the section EXPLANATION OF ERRORS,
below. The present structure of handling submissions in gpipe encodes
the principle that some errors are more serious and basic and "fail to
the submitter" who is expected to make repairs before trying to revise
the GenBank submission. Other errors "fail to an indexer", meaning
that the GenBank indexer handling the submission is expected to make
the repairs or to do further in-house evaluation of the sequence
before returning it to the submitter. Hopefully, the error diagnostics
are sufficiently informative to aid the submitter and indexer in
correcting those problems that are correctable.

For more information on rRNA_sensor, see its README: 
https://github.com/aaschaffer/rRNA_sensor/blob/master/README

----------------------------------------------------------------------------
SAMPLE RUN

This example runs the script on a sample file of 16 sequences. 

One can run ribotyper only on sequence files that are in directories
to which you have write permission. So, the first step is to copy the
example sequence file into a new directory to which you have write permission.
Move into that directory and copy the example file with this
command: 

> cp $RIBODIR/testfiles/example-16.fa ./

Then execute the following command:

> ribosensor.pl example-16.fa rs-test

The script ribosensor.pl takes two command-line arguments:

The first argument is the sequence file to annotate.

The second argument is the name of the output subdirectory that
ribotyper should create. Output files will be placed in this output
directory. If this directory already exists, the program will exit
with an error message indicating that you need to either (a) remove
the directory before rerunning, or (b) use the -f option with
ribosensor.pl, in which case the directory will be overwritten.
E.g., if the subdirectory 'test' already exists, replace the above
command with

> ribosensor.pl -f example-16.fa rs-test

The $RIBODIR environment variable is used here. That is
a hard-coded path that was set in the 'SETTING UP ENVIRONMENT
VARIABLES:' section above. 

-------------------------------------------------------------
OUTPUT

Example output of the script from the above command
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ribosensor.pl :: analyze ribosomal RNA sequences with profile HMMs and BLASTN
# ribotyper 0.30 (Oct 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:              Tue Oct 16 21:07:12 2018
# $RIBOBLASTDIR:     /usr/bin
# $RIBODIR:          /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1
# $RIBOEASELDIR:     /usr/local/infernal/1.1.2/bin
# $RIBOINFERNALDIR:  /usr/local/infernal/1.1.2/bin
# $SENSORDIR:        /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/rRNA_sensor
#
# target sequence input file:  example-16.fa
# output directory name:       rs-test      
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Partitioning sequence file based on sequence lengths         ... done. [    0.1 seconds]
# Running ribotyper on full sequence file                      ... done. [    8.7 seconds]
# Running rRNA_sensor on seqs of length 351..600               ... done. [    0.4 seconds]
# Running rRNA_sensor on seqs of length 601..inf               ... done. [    1.6 seconds]
# Parsing and combining rRNA_sensor and ribotyper output       ... done. [    0.0 seconds]
#
# Outcome counts:
#
# type   total  pass  indexer  submitter  unmapped
# -----  -----  ----  -------  ---------  --------
  RPSP       8     8        0          0         0
  RPSF       1     1        0          0         0
  RFSP       0     0        0          0         0
  RFSF       7     0        0          7         0
#
  *all*     16     9        0          7         0
#
# Per-program error counts:
#
#                      number   fraction
# error                of seqs   of seqs
# -------------------  -------  --------
  CLEAN                      8   0.50000
  S_NoHits                   1   0.06250
  S_TooLong                  1   0.06250
  S_LowScore                 5   0.31250
  S_LowSimilarity            5   0.31250
  R_NoHits                   1   0.06250
  R_UnacceptableModel        5   0.31250
  R_LowCoverage              1   0.06250
#
#
# GPIPE error counts:
#
#                                number   fraction
# error                          of seqs   of seqs
# -----------------------------  -------  --------
  CLEAN                                9   0.56250
  SEQ_HOM_NotSSUOrLSUrRNA              1   0.06250
  SEQ_HOM_LowSimilarity                1   0.06250
  SEQ_HOM_LengthLong                   1   0.06250
  SEQ_HOM_TaxNotExpectedSSUrRNA        5   0.31250
  SEQ_HOM_LowCoverage                  1   0.06250
#
#
# Timing statistics:
#
# stage      num seqs  seq/sec      nt/sec  nt/sec/cpu  total time             
# ---------  --------  -------  ----------  ----------  -----------------------
  ribotyper        16      1.8      2446.7      2446.7  00:00:08.69  (hh:mm:ss)
  sensor           16      8.1     10755.0     10755.0  00:00:01.98  (hh:mm:ss)
  total            16      1.5      1931.6      1931.6  00:00:11.01  (hh:mm:ss)
#
#
# Human readable error-based output saved to file rs-test/rs-test.ribosensor.out
# GPIPE error-based output saved to file rs-test/rs-test.ribosensor.gpipe
#
# List and description of all output files saved in:                                  rs-test.ribosensor.list
# Output printed to screen saved in:                                                  rs-test.ribosensor.log
# List of executed commands saved in:                                                 rs-test.ribosensor.cmd
# summary of rRNA_sensor results saved in:                                            rs-test.ribosensor.sensor.out
# summary of ribotyper results saved in:                                              rs-test.ribosensor.ribo.out
# summary of combined rRNA_sensor and ribotyper results (original errors) saved in:   rs-test.ribosensor.out
# summary of combined rRNA_sensor and ribotyper results (GPIPE errors) saved in:      rs-test.ribosensor.gpipe
#
# All output files created in directory ./rs-test/
#
# Elapsed time:  00:00:11.01
#            hh:mm:ss
# 
# RIBO-SUCCESS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-----------------
Output files:

Currently, there are two output files. Both are tabular output files
with one line per sequence with fields separated by whitespace
(spaces, not tabs). They will both be in the new directory 'test' that
was created by the example run above.

The first file type is a 'human readable error-based' output file, and
includes the errors reported from both ribotyper and sensor.  An
example is below.

Human readable file:
$ cat testfiles/rs-test.ribosensor.out 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#idx  sequence                                       taxonomy               strand             type    failsto  error(s)
#---  ---------------------------------------------  ---------------------  -----------------  ----  ---------  --------
1     00052::Halobacterium_sp.::AE005128             SSU.Archaea            plus               RPSP       pass  -
2     00013::Methanobacterium_formicicum::M36508     SSU.Archaea            plus               RPSP       pass  -
3     00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea            plus               RPSF       pass  S_LowScore;
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus               RFSF  submitter  S_LowSimilarity;R_LowCoverage:(0.835<0.860);
5     random                                         -                      NA                 RFSF  submitter  S_NoHits;R_NoHits;
6     00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea            minus              RPSP       pass  -
7     00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria           plus               RPSP       pass  -
8     01106::Bacillus_subtilis::K00637               SSU.Bacteria           plus               RPSP       pass  -
9     00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria           plus               RPSP       pass  -
10    01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria           minus              RPSP       pass  -
11    00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria           plus               RPSP       pass  -
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus               RFSF  submitter  S_LowScore;S_LowSimilarity;R_UnacceptableModel:(SSU_rRNA_eukarya);
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus               RFSF  submitter  S_LowScore;S_LowSimilarity;R_UnacceptableModel:(SSU_rRNA_eukarya);
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus               RFSF  submitter  S_LowScore;S_LowSimilarity;R_UnacceptableModel:(SSU_rRNA_eukarya);
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus              RFSF  submitter  S_LowScore;S_LowSimilarity;R_UnacceptableModel:(SSU_rRNA_eukarya);
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus               RFSF  submitter  S_TooLong;R_UnacceptableModel:(SSU_rRNA_eukarya);
#
# Explanation of columns:
#
# Column 1 [idx]:      index of sequence in input sequence file
# Column 2 [target]:   name of target sequence
# Column 3 [taxonomy]: inferred taxonomy of sequence
# Column 4 [strnd]:    strand ('plus' or 'minus') of best-scoring hit
# Column 5 [type]:     "R<1>S<2>" <1> is 'P' if passes ribotyper, 'F' if fails; <2> is same, but for sensor
# Column 6 [failsto]:  'pass' if sequence passes
#                      'indexer'   to fail to indexer
#                      'submitter' to fail to submitter
#                      '?' if situation is not covered in the code
# Column 7 [error(s)]: reason(s) for failure (see 00README.txt)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In the example, the sequence names in column 2 also have taxonomy
information as Genus_species, but this information is neither used
nor expected by ribosensor. In particular, if the reported inferred
category in column 3 is not consistent with the Genus_species in
column 2, this inconsistency is not detected by ribosensor. One
particularly important taxonomy issue is whether a sequence comes from
Homo sapiens, because human samples need informed consent. Detecting
whether a sequence comes from Homo sapiens is outside the scope of
ribosensor because gpipe already has another tool for this purpose.

The second file type is a 'GPIPE error-based' output file. It includes
much of the same information as the human readable file, with the main
difference being that the ribotyper and sensor errors have been
replaced with their corresponding 'GPIPE' errors.  An example is
below.

GPIPE output file:
$ cat testfiles/rs-test.ribosensor.gpipe
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#idx  sequence                                       taxonomy               strand              p/f  error(s)
#---  ---------------------------------------------  ---------------------  -----------------  ----  --------
1     00052::Halobacterium_sp.::AE005128             SSU.Archaea            plus               RPSP  -
2     00013::Methanobacterium_formicicum::M36508     SSU.Archaea            plus               RPSP  -
3     00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea            plus               RPSF  -
4     00121::Thermococcus_celer::M21529              SSU.Archaea            plus               RFSF  SEQ_HOM_LowSimilarity;SEQ_HOM_LowCoverage;
5     random                                         -                      NA                 RFSF  SEQ_HOM_NotSSUOrLSUrRNA;
6     00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea            minus              RPSP  -
7     00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria           plus               RPSP  -
8     01106::Bacillus_subtilis::K00637               SSU.Bacteria           plus               RPSP  -
9     00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria           plus               RPSP  -
10    01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria           minus              RPSP  -
11    00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria           plus               RPSP  -
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus               RFSF  SEQ_HOM_TaxNotExpectedSSUrRNA;
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus               RFSF  SEQ_HOM_TaxNotExpectedSSUrRNA;
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus               RFSF  SEQ_HOM_TaxNotExpectedSSUrRNA;
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus              RFSF  SEQ_HOM_TaxNotExpectedSSUrRNA;
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus               RFSF  SEQ_HOM_LengthLong;SEQ_HOM_TaxNotExpectedSSUrRNA;
#
# Explanation of columns:
#
# Column 1 [idx]:      index of sequence in input sequence file
# Column 2 [target]:   name of target sequence
# Column 3 [taxonomy]: inferred taxonomy of sequence
# Column 4 [strnd]:    strand ('plus' or 'minus') of best-scoring hit
# Column 5 [type]:     "R<1>S<2>" <1> is 'P' if passes ribotyper, 'F' if fails; <2> is same, but for sensor
# Column 6 [error(s)]: reason(s) for failure (see 00README.txt)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

##############################################################################
EXPLANATION OF ERRORS

(The text and tables below were taken from
https://confluence.ncbi.nlm.nih.gov/display/GEN/Ribosensor%3A+proposed+criteria+and+names+for+errors
on May 26, 2017)

List of Sensor and Ribotyper errors (listed in Ribosensor 'human
readable output file'):

---------
                                                                         ignored if
                                                                         RFSF and 
                                                   ignored if            errors R7
     Ribotyper (R_) or                             RPSF and     ignored  or R8 also
idx  Sensor (S_) error   associated GPIPE error    uncultured   if RFSP  exist       cause/explanation
---  -----------------   ------------------------  ----------   -------  ----------  -------------------
S1.  S_NoHits            SEQ_HOM_NotSSUOrLSUrRNA         yes        N/A         yes  no hits reported ('no' column 2)
S2.  S_NoSimilarity      SEQ_HOM_LowSimilarity           yes        N/A         yes  coverage (column 5) of best blast hit is < 10%
S3.  S_LowSimilarity     SEQ_HOM_LowSimilarity           yes        N/A         yes  coverage (column 5) of best blast hit is < 80%
                                                                                     (<=350nt) or 86% (>350nt)
S4.  S_LowScore          SEQ_HOM_LowSimilarity           yes        N/A         yes  either id percentage below length dependent threshold (75,80,86)
                                                                                     OR E-value above 1e-40 ('imperfect_match' column 2)
S5.  S_BothStrands       SEQ_HOM_MisAsBothStrands         no        N/A          no  hits on both strands ('mixed' column 2)
S6.  S_MultipleHits      SEQ_HOM_MultipleHits             no        N/A          no  more than 1 hit reported (column 4 > 1)
------------------------------------------------------------------------------------------------------------------------------
R1.  R_NoHits            SEQ_HOM_NotSSUOrLSUrRNA         N/A         no          no  no hits reported
R2.  R_MultipleFamilies  SEQ_HOM_SSUAndLSUrRNA           N/A         no          no  SSU and LSU hits
R3.  R_LowScore          SEQ_HOM_LowSimilarity           N/A         no          no  bits/position score is < 0.5
R4.  R_BothStrands       SEQ_HOM_MisAsBothStrands        N/A         no          no  hits on both strands
R5.  R_InconsistentHits  SEQ_HOM_MisAsHitOrder           N/A         no          no  hits are in different order in sequence and model
R6.  R_DuplicateRegion   SEQ_HOM_MisAsDupRegion          N/A         no          no  hits overlap by 10 or more model positions
R7.  R_UnacceptableModel SEQ_HOM_TaxNotExpectedSSUrRNA   N/A         no          no  best hit is to model other than expected set
                                                                                     16S expected set: SSU.Archaea, SSU.Bacteria, SSU.Cyanobacteria, SSU.Chloroplast
                                                                                     18S expected set: SSU.Eukarya
R8.  R_QuestionableModel SEQ_HOM_TaxQuestionableSSUrRNA  N/A         no          no  best hit is to a 'questionable' model (if mode is 16S: SSU.Chloroplast)
R9.  R_LowCoverage       SEQ_HOM_LowCoverage             N/A         no          no  coverage of all hits is < 0.80 (<=350nt) or 0.86 (>350nt)
R10. R_MultipleHits      SEQ_HOM_MultipleHits            N/A        yes          no  more than 1 hit reported
---------

The following list of GPIPE errors (listed in Ribosensor 'GPIPE output
file') is relevant in the expected gpipe usage. One possible
difference is that each sequence may be assigned one or more errrors,
but gpipe determines whether an entire submission (typically
comprising multiple sequences) succeeds or fails. At present, a
submission fails if any of the sequences in the submission fails.

---------
idx  GPIPE error                     fails to      triggering Sensor/Ribotyper errors
---  ------------------------------  ---------     ----------------------------------
G1.  SEQ_HOM_NotSSUOrLSUrRNA         submitter     S_NoHits*^, R_NoHits
G2.  SEQ_HOM_LowSimilarity           submitter     S_NoSimilarity*^, S_LowSimilarity*^, S_LowScore*^, R_LowScore
G3.  SEQ_HOM_SSUAndLSUrRNA           submitter     R_MultipleFamilies
G4.  SEQ_HOM_MisAsBothStrands        submitter     S_BothStrands, R_BothStrands
G5.  SEQ_HOM_MisAsHitOrder           submitter     R_InconsistentHits
G6.  SEQ_HOM_MisAsDupRegion          submitter     R_DuplicateRegion
G7.  SEQ_HOM_TaxNotExpectedSSUrRNA   submitter     R_UnacceptableModel
G8.  SEQ_HOM_TaxQuestionableSSUrRNA  indexer       R_QuestionableModel
G9.  SEQ_HOM_LowCoverage             indexer       R_LowCoverage
G10. SEQ_HOM_MultipleHits            indexer       S_MultipleHits, R_MultipleHits+

* these Sensor errors do not trigger a GPIPE error if sequence is 'RPSF'
  (ribotyper pass, sensor fail) and sample is uncultured (-c option not
  used with ribosensor_wrapper.pl).

+ this Ribotyper error (R_MultipleHits) does not trigger a GPIPE error
  if sequence is 'RFSP' (ribotyper fail, sensor pass).

^ these Sensor errors (S_NoHits, S_NoSimilarity, S_LowSimilarity,
  S_LowScore) do not trigger a GPIPE error if sequence is 'RFSF'
  (ribotyper fail, sensor fail) and R_UnacceptableModel or
  R_QuestionableModel also exists.

---------

For more information on ribotyper errors which are reported prefixed
with 'R_' in column 7 of the human readable output file, see
ribotyper's 00README.txt:
https://github.com/nawrockie/ribotyper-v1/blob/master/00README.txt

For more information on sensor errors, all of which are reported
prefixed with 'S_' in column 7 of the human readable output file, see
sensor's README file:
https://github.com/aaschaffer/rRNA_sensor/blob/master/README

A few important points for users within NCBI about the lists of errors above:

- A GPIPE error is triggered by one or more occurrences of its
  triggering Sensor/Ribotyper errors (with the exception listed above
  for '*', '+', and '^').

- The definition above of Sensor/Ribotyper errors and the GPIPE errors
  they trigger is slightly different from the most recent Confluence
  'Analysis3-20170515' word document. Eric made changes where he
  thought it made sense with the following goals in mind:

  A) simplifying the 'Outcomes' section of the Analysis document,
  which explained how to determine whether sequences pass or fail to
  submitter or fail to indexer based on the ribotyper and sensor
  output.  
  
  B) reporting GPIPE errors in the format that Alex Kotliarov asked for
  at the May 15, 2017 gpipe/Foosh meeting.

##############################################################################
ALL COMMAND LINE OPTIONS

To see all the available command-line options to ribosensor.pl, call
it with the -h option:

> ribosensor.pl -h
# ribosensor.pl :: analyze ribosomal RNA sequences with profile HMMs and BLASTN
# ribotyper 0.30 (Oct 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Tue Oct 16 21:14:47 2018
#
Usage: ribosensor.pl [-options] <fasta file to annotate> <output directory>


basic options:
  -f           : force; if <output directory> exists, overwrite it
  -m <s>       : set mode to <s>, possible <s> values are "16S" and "18S" [16S]
  -c           : assert that sequences are from cultured organisms
  -n <n>       : use <n> CPUs [0]
  -v           : be verbose; output commands to stdout as they're run
  -i <s>       : use model info file <s> instead of default
  --keep       : keep all intermediate files that are removed by default
  --skipsearch : skip search stages, use results from earlier run

rRNA_sensor related options:
  --Sminlen <n>    : set rRNA_sensor minimum sequence length to <n> [100]
  --Smaxlen <n>    : set rRNA_sensor minimum sequence length to <n> [2000]
  --Smaxevalue <x> : set rRNA_sensor maximum E-value to <x> [1e-40]
  --Sminid1 <n>    : set rRNA_sensor minimum percent id for seqs <= 350 nt to <n> [75]
  --Sminid2 <n>    : set rRNA_sensor minimum percent id for seqs [351..600] nt to <n> [80]
  --Sminid3 <n>    : set rRNA_sensor minimum percent id for seqs > 600 nt to <n> [86]
  --Smincovall <n> : set rRNA_sensor minimum coverage for all sequences to <n> [10]
  --Smincov1 <n>   : set rRNA_sensor minimum coverage for seqs <= 350 nt to <n> [80]
  --Smincov2 <n>   : set rRNA_sensor minimum coverage for seqs  > 350 nt to <n> [86]

options for saving sequence subsets to files:
  --psave : save passing sequences to a file

== END OF SECTION ON ribosensor.pl ==
##############################################################################
PARALLELIZING ON A SGE COMPUTE FARM

The ribotyper.pl, riboaligner.pl, and ribodbmaker.pl scripts can be
parallelized using an SGE compute farm using the -p command line
option.

The options related to parallelization are the same for all of the
scripts:

options for parallelizing ribotyper/ribolengthchecker's calls to cmsearch and cmalign on a compute farm:
  -p         : parallelize cmsearch on a compute farm
  -q <s>     : use qsub info file <s> instead of default
  --nkb <n>  : number of KB of sequence for each farm job is <n> [10]
  --wait <n> : allow <n> wall-clock minutes for jobs on farm to finish, including queueing time [500]
  --errcheck : consider any farm stderr output as indicating a job failure

By default SGE 'qsub' command line options that will work at NCBI are
used, but you can change the default qsub 'prefix' and 'suffix' using
the -q <s> option. The prefix is the string that occurs before the
command that is being submitted to SGE, and the suffix is the string
that occurs after it. The file that specifies the default prefix and
suffix values is $RIBODIR/models/ribo.0p20.qsubinfo:

> cat $RIBODIR/models/ribo.0p20.qsubinfo
-----------
# ribo.0p20.qsubinfo
# This file must have exactly 2 non-'#' prefixed
# lines. 
#
# Line 1: a string that is the qsub command and flags for submitting
# jobs to the compute farm *prior* to the actual cmsearch/cmalign command.
#
# This line may have up to two special values that will be
# replaced: 
# (a) "![errfile]!": will be replaced by an error file name
#     automatically determined by the ribotyper script(s)
# (b) "![jobname]!": will be replaced by a job name
#     automatically determined by the ribotyper script(s)
#
# Line 2: the remainder of the qsub cmsearch/cmalign command 
#
qsub -N ![jobname]! -b y -v SGE_FACILITIES -P unified -S /bin/bash -cwd -V -j n -o /dev/null -e ![errfile]! -m n -l h_rt=288000,h_vmem=16G,mem_free=16G,reserve_mem=16G,m_mem_free=16G "
"
-----------
As explained in the top of that file, the first non-comment (non-#
prefixed) line is the qsub prefix and second is the qsub suffix.

So with this file a command $COMMAND would be submitted to the farm
like this:

qsub -N ![jobname]! -b y -v SGE_FACILITIES -P unified -S /bin/bash -cwd -V -j n -o /dev/null -e ![errfile]! -m n -l h_rt=288000,h_vmem=16G,mem_free=16G,reserve_mem=16G,m_mem_free=16G "$COMMAND"

Where ![jobname]! and ![errfile]! will be automatically replaced by
the ribotyper script being used.

You can create your own file with different qsub prefix and suffix
lines and use them using the option '-q <PATH-TO-YOUR-FILE>'.

The --nkb option controls how big each job will be. By default, each
job will contain about 10Kb of sequence. So if the input fasta file is
1Mb, it will be split into 100 smaller files and each will get its own
farm job. There will never be more than a maximum of 300 smaller files
created. You can change this to <n>Kb instead of 10Kb with the --nkb
<n> option.

The --wait <n> option controls how many minutes the script will wait
for jobs to finish before giving up and exiting in error. By default
<n> is 500.

The --errcheck option makes it so that if any job outputs any data to
an error file then the ribotyper script will exit in error.

##############################################################################
TESTING SCRIPTS 

The ribodbmaker.pl script is included in the ribotyper package for
testing scripts and is used during development for regression
testing. 

The testfiles/do-all-tests.sh shell script will perform all the
tests. It includes 3 non-parallel and 3 parallel tests.

That file:
> cat $RIBODIR/testfiles/do-all-tests.sh
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

To do all tests and save output to the file 'test.out', do:

> sh $RIBODIR/testfiles/do-all-tests.sh > test.out

Here is the output for the first test performed by that script
($RIBODIR/ribotest.pl -f $RIBODIR/testfiles/testin.example-16 test1)
# ribotest.pl :: test ribotyper scripts [TEST SCRIPT]
# ribotyper 0.29 (Oct 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:      Mon Oct 15 15:29:40 2018
# $RIBODIR:  /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1
#
# test file:                    /panfs/pan1/infernal/notebook/18_1004_ribosensor_update/ribotyper-v1/testfiles/testin.example-16
# output directory name:        test1                                                                                           
# forcing directory overwrite:  yes [-f]                                                                                        
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Running command  1 [      ribotyper-1-16]          ... done. [    4.6 seconds]
#	checking test-16/test-16.ribotyper.short.out                 ... pass
#	checking test-16/test-16.ribotyper.long.out                  ... pass
#	removing directory test-16                                   ... done
# Running command  2 [    riboaligner-1-16]          ... done. [    8.7 seconds]
#	checking test-16-2/test-16-2.riboaligner.tbl                 ... pass
#	checking test-16-2/test-16-2.riboaligner.SSU.Bacteria.partial.stk ... pass
#	checking test-16-2/test-16-2.riboaligner.SSU.Bacteria.partial.list ... pass
#	checking test-16-2/test-16-2.riboaligner.SSU.Bacteria.partial.ifile ... pass
#	checking test-16-2/test-16-2.riboaligner.SSU.Bacteria.partial.elfile ... pass
#	removing directory test-16-2                                 ... done
#
#
# PASS: all 7 files were created correctly.
#
#
# List and description of all output files saved in:   test1.ribotest.list
# Output printed to screen saved in:                   test1.ribotest.log
# List of executed commands saved in:                  test1.ribotest.cmd
#
# All output files created in directory ./test1/
#
# Elapsed time:  00:00:13.70
#            hh:mm:ss
# 
# RIBO-SUCCESS

The most important line is the line that begins with "# PASS"

# PASS: all 7 files were created correctly.

This means that the test has passed. If all tests run succesfully,
then there will 6 such lines in the test.out output file when the
tests finish. If any tests fail, it will have a line that begins with
'# FAIL' instead of this line.


