EPN, Tue Mar 20 06:30:22 2018

Ribosensor v0.27 00README.txt

Organization of this file:

INTRO
SETTING UP ENVIRONMENT VARIABLES
PREREQUISITE PROGRAMS
WHAT RIBOSENSOR DOES
SAMPLE RUN
OUTPUT
EXPLANATION OF ERRORS
ALL COMMAND LINE OPTIONS
GETTING MORE INFORMATION

##############################################################################
INTRO

This is documentation for ribosensor, a tool for detecting and
classifying small subunit (SSU) and large subunit (LSU) rRNA
sequences.  ribosensor uses profile hidden markov models (HMMs) and
BLASTN.

Authors: Eric Nawrocki and Alejandro Schaffer
National Center for Biotechnology Information 

Current location of code and other relevant files within NCBI:
/panfs/pan1/dnaorg/ssudetection/code/ribosensor_wrapper/

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


##############################################################################
SETTING UP ENVIRONMENT VARIABLES

Before running ribosensor, the user must update environment
variables. To do this, add the following seven lines to either the
file .bashrc (for users of bash shell) or the file .cshrc file (for
users of C shell or tcsh). The .bashrc or .cshrc file is in the user's
home directory. To determine what shell is in use, enter the command

> echo $SHELL

If this command returns '/bin/bash', then update the file .bashrc.  If
this command returns '/bin/csh' or '/bin/tcsh', then update the file
.cshrc.

Before updating the pertinent shell file, it is necessary to know
whether the environment variable PERL5LIB is already defined or
not. To determine this information, enter the command:

> echo $PERL5LIB

If this command returns one or more directories, then PERL5LIB is
already defined.

Similarly, it is necessary to know whether the environment variable
BLASTDB is already defined. To determine this information, enter the
command:

> echo $BLASTDB

If this command returns one or more directories, then BLASTDB is
already defined.

The seven lines to add to the file .bashrc, if PERL5LIB and BLASTDB are
already defined:
-----------
export RIBOSENSORDIR="/panfs/pan1/dnaorg/ssudetection/code/ribosensor_wrapper"
export EPNOPTDIR="/panfs/pan1/dnaorg/ssudetection/code/epn-options"
export RIBODIR="/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1"
export SENSORDIR="/panfs/pan1/dnaorg/ssudetection/code/16S_sensor"
export PERL5LIB="$RIBODIR:$EPNOPTDIR:$PERL5LIB"
export PATH="$RIBOSENSORDIR:$SENSORDIR:$PATH"
export BLASTDB="$SENSORDIR:$BLASTDB"
-----------

The seven lines to add to the file .cshrc, if PERL5LIB and BLASTDB are
already defined:
-----------
setenv RIBOSENSORDIR "/panfs/pan1/dnaorg/ssudetection/code/ribosensor_wrapper"
setenv RIBODIR "/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1"
setenv SENSORDIR "/panfs/pan1/dnaorg/ssudetection/code/16S_sensor"
setenv EPNOPTDIR "/panfs/pan1/dnaorg/ssudetection/code/epn-options"
setenv PERL5LIB "$RIBODIR":"$EPNOPTDIR":"$PERL5LIB"
setenv PATH "$RIBOSENSORDIR":"$SENSORDIR":"$PATH"
setenv BLASTDB "$SENSORDIR":"$BLASTDB"
-----------

If PERL5LIB was not already defined: 
use instead
export PERL5LIB="$RIBODIR:$EPNOPTDIR"
for .bashrc, OR
setenv PERL5LIB "$RIBODIR":"$EPNOPTDIR"
for .cshrc.
at line 5 out of 7. 

If BLASTDB was not already defined: 
use instead
export BLASTDB="$SENSORDIR"
for .bashrc, OR
setenv BLASTDB "$SENSORDIR"
for .cshrc.
at line 7 out of 7. 

After adding the appropriate seven lines to the appropriate shell file, execute this command:
> source ~/.bashrc
OR
> source ~/.cshrc

To check that your environment variables have been properly adjusted,
try the following commands:

Command 1. 
> echo $RIBOSENSORDIR
This should return only
/panfs/pan1/dnaorg/ssudetection/code/ribosensor_wrapper

Command 2. 
> echo $RIBODIR
This should return only
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1

Command 3. 
> echo $SENSORDIR
This should return only
/panfs/pan1/dnaorg/ssudetection/code/16S_sensor

Command 4. 
> echo $EPNOPTDIR
This should return only
/panfs/pan1/dnaorg/ssudetection/code/epn-options

Command 5. 
> echo $PERL5LIB
This should return a (potentially longer) string that begins with 
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1:/panfs/pan1/dnaorg/ssudetection/code/epn-options

Command 6.
> echo $PATH
This should return a (potentially longer) string that includes:
/panfs/pan1/dnaorg/ssudetection/code/ribosensor_wrapper
AND
/panfs/pan1/dnaorg/ssudetection/code/16S_sensor

Command 7.
> echo $BLASTDB
This should return a (potentially longer) string that includes:
/panfs/pan1/dnaorg/ssudetection/code/16S_sensor

If any of these commands do not return what they are supposed to,
please email Eric Nawrocki (nawrocke@ncbi.nlm.nih.gov). If you do see
the expected output, and you have the prerequisite programs installed
as explained below, the sample run below should work.

##############################################################################
PREREQUISITE PROGRAMS

The Infernal v1.1.2 software package must be installed prior to
running ribotyper.pl, and its executables must be in your $PATH.
Further, the easel 'miniapps' that are installed with Infernal must be
in your $PATH. You can download Infernal from
http://eddylab.org/infernal/.

Additionally, the 'blastn' program from the BLAST suite must be
installed and in your $PATH. Our testing was done with BLAST version
2.6.0+.

*****************************************
Internal NCBI-specific instructions:

The v1.1.2 Infernal executables and the easel miniapps are already
installed system-wide at NCBI. Login into a Linux computer that
runs CentOS 7.

Add the single token
infernal
to the facilities line of your .ncbi_hints file.

Do not delete any tokens on the line; it does not matter where within
the facilities token you add the new token infernal.

Also, add the following line to your .ncbi_hints file, near the bottom:
option infernal_version 1.1.2

Do not delete any option lines that exist, unless they refer to an
earlier version of infernal. The placement of the new option line
among all existing option lines is probably unimportant.

*****************************************

To check if you have Infernal, BLAST and the required executables
installed and in your path. Execute the following three commands:

> cmsearch -h 
> esl-sfetch -h
> blastn -h

As of July 2017, the first command should return the usage for cmsearch with a line
that says:
INFERNAL 1.1.2 (July 2016).

The second command should return the usage for esl-sfetch with a
line that says:
Easel 0.43 (July 2016).

The third command should return blastn usage with a line at the end
that says
BLAST 2.6.0+.

It is possible that versions of any of these three programs would
advance past three version numbers shown above. If all three
prerequisite programs are present, and you were able to set your
environment variables as explained above, the sample run below should
work.

##############################################################################
WHAT RIBOSENSOR DOES

Ribosensor is a wrapper program that calls two other programs:
ribotyper and 16S_sensor (henceforth, called 'sensor') and combines
their output together. Ribotyper uses profile HMMs to identify and
classify small subunit (SSU) ribosomal RNA sequences (archaeal,
bacterial, eukaryotic) and large subunit (LSU) ribosomal RNA
sequences. Sensor uses BLASTN to identify bacterial and archaeal 16S
SSU rRNA sequences using a library of type strain archaeal and
bacterial 16S sequences. Sensor is limited to 16S sequences because
that is the only category for which NCBI currently has a sufficiently
large and representative database that is of high enough quality to be
trustworthy. Based on the output of both programs, ribosensor decides
if each input sequence "passes" or "fails". When ribosensor is used to
evaluate candidate submissions to GenBank, the intent is that
sequences that pass should be accepted for submission to GenBank as
archaeal or bacterial 16S SSU rRNA sequences, and sequences that fail
should not.

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

For more information on ribotyper, see its 00README.txt:
https://github.com/nawrockie/ribotyper-v1/blob/master/00README.txt

For more information on 16S_sensor, see its README: 
https://github.com/aaschaffer/16S_sensor/blob/master/README

##############################################################################
SAMPLE RUN

This example runs the script on a sample file of 16 sequences. 

One can run ribotyper only on sequence files that are in directories
to which you have write permission. So, the first step is to copy the
example sequence file into a new directory to which you have write permission.
Move into that directory and copy the example file with this
command: 

> cp $RIBOSENSORDIR/testfiles/example-16.fa ./

Then execute the following command:

> ribosensor.pl example-16.fa test

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

> ribosensor.pl -f example-16.fa test

The $RIBOSENSORDIR environment variable is used here. That is
a hard-coded path that was set in the 'SETTING UP ENVIRONMENT
VARIABLES:' section above. 

##############################################################################
OUTPUT

Example output of the script from the above command
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ribosensor.pl :: analyze ribosomal RNA sequences with profile HMMs and BLASTN
# ribosensor 0.27 (Mar 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Tue Mar 20 06:31:02 2018
#
# target sequence input file:  example-16.fa
# output directory name:       test
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Partitioning sequence file based on sequence lengths  ... done. [0.1 seconds]
# Running ribotyper on full sequence file               ... done. [4.0 seconds]
# Running 16S_sensor on seqs of length 351..600         ... done. [1.2 seconds]
# Running 16S_sensor on seqs of length 601..inf         ... done. [1.1 seconds]
# Parsing and combining 16S_sensor and ribotyper output ... done. [0.0 seconds]
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
  S_NoHits                   2   0.12500
  S_TooLong                  1   0.06250
  S_LowScore                 4   0.25000
  S_LowSimilarity            4   0.25000
  R_NoHits                   1   0.06250
  R_UnacceptableModel        5   0.31250
  R_LowCoverage              1   0.06250
#
#
# GPIPE error counts:
#
#                                 number   fraction
# error                           of seqs   of seqs
# ------------------------------  -------  --------
  CLEAN                                 9   0.56250
  SEQ_HOM_NotSSUOrLSUrRNA               1   0.06250
  SEQ_HOM_LowSimilarity                 1   0.06250
  SEQ_HOM_LengthLong                    1   0.06250
  SEQ_HOM_TaxNotArcBacChlSSUrRNA        5   0.31250
  SEQ_HOM_LowCoverage                   1   0.06250
#
#
# Timing statistics:
#
# stage      num seqs  seq/sec      nt/sec  nt/sec/cpu  total time             
# ---------  --------  -------  ----------  ----------  -----------------------
  ribotyper        16      4.0      5312.6      5312.6  00:00:04.00  (hh:mm:ss)
  sensor           16      6.8      9059.4      9059.4  00:00:02.35  (hh:mm:ss)
  total            16      2.5      3278.7      3278.7  00:00:06.48  (hh:mm:ss)
#
#
# Human readable error-based output saved to file test/test.ribosensor.out
# GPIPE error-based output saved to file test/test.ribosensor.gpipe
#
#[RIBO-SUCCESS]
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
$ cat testfiles/test.ribosensor.out 
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
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus               RFSF  submitter  S_NoHits;R_UnacceptableModel:(SSU_rRNA_eukarya);
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus              RFSF  submitter  S_LowScore;S_LowSimilarity;R_UnacceptableModel:(SSU_rRNA_eukarya);
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus               RFSF  submitter  S_TooLong;R_UnacceptableModel:(SSU_rRNA_eukarya);
#
# Explanation of columns:
#
# Column 1 [idx]:      index of sequence in input sequence file
# Column 2 [target]:   name of target sequence
# Column 3 [taxonomy]: inferred taxonomy and LSU/SSU type of sequence
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
$ cat testfiles/test.ribosensor.gpipe
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
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus               RFSF  SEQ_HOM_TaxNotArcBacChlSSUrRNA;
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus               RFSF  SEQ_HOM_TaxNotArcBacChlSSUrRNA;
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus               RFSF  SEQ_HOM_TaxNotArcBacChlSSUrRNA;
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus              RFSF  SEQ_HOM_TaxNotArcBacChlSSUrRNA;
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus               RFSF  SEQ_HOM_LengthLong;SEQ_HOM_TaxNotArcBacChlSSUrRNA;
#
# Explanation of columns:
#
# Column 1 [idx]:      index of sequence in input sequence file
# Column 2 [target]:   name of target sequence
# Column 3 [taxonomy]: inferred taxonomy and SSU?LSU type of sequence
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
R7.  R_UnacceptableModel SEQ_HOM_TaxNotArcBacChlSSUrRNA  N/A         no          no  best hit is to model other than SSU.Archaea, SSU.Bacteria,
                                                                                     SSU.Cyanobacteria, or SSU.Chloroplast
R8.  R_QuestionableModel SEQ_HOM_TaxChloroplastSSUrRNA   N/A         no          no  best hit is to SSU.Chloroplast
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
G7.  SEQ_HOM_TaxNotArcBacChlSSUrRNA  submitter     R_UnacceptableModel
G8.  SEQ_HOM_TaxChloroplastSSUrRNA   indexer       R_QuestionableModel
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
https://github.com/aaschaffer/16S_sensor/blob/master/README


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
# ribosensor 0.27 (Mar 2018)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Tue Mar 20 06:34:46 2018
#
Usage: ribosensor.pl [-options] <fasta file to annotate> <output directory>


basic options:
  -f           : force; if <output directory> exists, overwrite it
  -c           : assert that sequences are from cultured organisms
  -n <n>       : use <n> CPUs [0]
  -v           : be verbose; output commands to stdout as they're run
  --keep       : keep all intermediate files that are removed by default
  --skipsearch : skip search stages, use results from earlier run

16S_sensor related options:
  --Sminlen <n>    : set 16S_sensor minimum sequence length to <n> [100]
  --Smaxlen <n>    : set 16S_sensor minimum sequence length to <n> [2000]
  --Smaxevalue <x> : set 16S_sensor maximum E-value to <x> [1e-40]
  --Sminid1 <n>    : set 16S_sensor minimum percent id for seqs <= 350 nt to <n> [75]
  --Sminid2 <n>    : set 16S_sensor minimum percent id for seqs [351..600] nt to <n> [80]
  --Sminid3 <n>    : set 16S_sensor minimum percent id for seqs > 600 nt to <n> [86]
  --Smincovall <n> : set 16S_sensor minimum coverage for all sequences to <n> [10]
  --Smincov1 <n>   : set 16S_sensor minimum coverage for seqs <= 350 nt to <n> [80]
  --Smincov2 <n>   : set 16S_sensor minimum coverage for seqs  > 350 nt to <n> [86]

options for saving sequence subsets to files:
  --psave : save passing sequences to a file

##############################################################################
GETTING MORE INFORMATION

Both ribotyper and 16S_sensor have their own README files, with
additional information about those programs and their outputs:

https://github.com/nawrockie/ribotyper-v1/blob/master/00README.txt
https://github.com/aaschaffer/16S_sensor/blob/master/README

