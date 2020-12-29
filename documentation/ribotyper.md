# <a name="top"></a> `ribotyper` example usage, command-line options and unexpected feature information

* [`ribotyper` example usage](#exampleusage)
* [Unexpected features and reasons for a sequence to _FAIL_](#unexpectedfeatures)
* [The ribotyper default model library](#library)
* [ribotyper's two round search strategy](#strategy)
* [Defining acceptable/questionable models](#acceptable)
* [List of all command-line options](#options)

---

ribotyper is a tool for classifying and validating SSU and/or LSU
rRNA sequences in an input. A central assumption of the script is that
 each input sequence is a SSU or LSU rRNA sequence (either full length
or partial). Therefore, it is not well suited for identifying rRNAs in
genome sequences or metagenomic datasets.

ribotyper compares each sequence to a library of profile HMMs built
from representative alignments of SSU and LSU rRNA sequences.  Each
profile HMM is a statistical model of the family it models
(e.g. bacterial SSU rRNA) built from a multiple alignment of 50-100
representative sequences from the family. The source of several of the
alignments, including the bacterial model, is the [Rfam](rfam.xfam.org) database
Each profile HMM has position specific scores at
each position of the model, which means that positions of the family
that are highly conserved have a higher impact on the final score than
do positions that are not as well conserved (unlike BLAST for which
each position is treated identically). Each sequence is aligned to
each profile and a score is computed based on how well the sequence
matches the profile. Each sequence is classified by the model that
gave it the highest score. See [models.md](models.md#top) for more
information on the models ribotyper uses.


## `ribotyper` example usage <a name="exampleusage"></a>

This example runs the script ribotyper on a sample file of 16
sequences.

Move into a directory in which you have write permission and execute the following command:

```
> ribotyper $RIBOSCRIPTSDIR/testfiles/example-16.fa test
```

Like other Ribovore scripts, ribotyper takes 2 required command
line arguments. Optional arguments are explained [below](#options).

The first required argument is the sequence file you want to annotate.
The $RIBOSCRIPTSDIR environment variable should be defined in your
`.bashrc` or `.cshrc` as explained in the [installation
documentation](install.md#environment).

The second required argument is the name of the output subdirectory
that you would like ribotyper to create. Output files will be placed
in this output directory. If this directory already exists, the
program will exit with an error message indicating that you need to
either (a) remove the directory before rerunning, or (b) use the -f
option with ribotyper, in which case the directory will be
overwritten.  The command adding `-f` is:

```
> ribotyper -f $RIBOSCRIPTSDIR/testfiles/example-16.fa test
```

You should see something like the following output:
```
# ribotyper :: detect and classify ribosomal RNA sequences
# Ribovore 1.0 (Jan 2021)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:              Tue Dec 22 16:04:25 2020
# $RIBOEASELDIR:     /usr/local/src/ribovore-install/infernal/binaries
# $RIBOINFERNALDIR:  /usr/local/src/ribovore-install/infernal/binaries
# $RIBOSCRIPTSDIR:   /usr/local/src/ribovore-install/ribovore
#
# target sequence input file:   /usr/local/src/ribovore-install/ribovore/testfiles/example-16.fa
# output directory name:        test
# forcing directory overwrite:  yes [-f]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Validating input files                                                           ... done. [    0.6 seconds]
# Determining target sequence lengths                                              ... done. [    0.1 seconds]
# Classifying sequences                                                            ... done. [    2.2 seconds]
# Sorting classification results                                                   ... done. [    0.0 seconds]
# Processing classification results                                                ... done. [    0.0 seconds]
# Fetching per-model sequence sets                                                 ... done. [    0.0 seconds]
# Searching sequences against best-matching models                                 ... done. [    1.0 seconds]
# Concatenating tabular round 2 search results                                     ... done. [    0.0 seconds]
# Sorting search results                                                           ... done. [    0.0 seconds]
# Processing tabular round 2 search results                                        ... done. [    0.0 seconds]
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
  classification        16      7.2      9550.9      9550.9              00:00:02.23
  search                15     14.7     19828.3     19828.3              00:00:01.02
  total                 16      3.9      5219.0      5219.0              00:00:04.07
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
# Elapsed time:  00:00:04.07
#                hh:mm:ss
# 
[ok]
```

ribotyper outputs information on each step and how long it takes,
followed by `Summary statistics` that show how many sequences were
classified to each class (e.g. `SSU.Archaea`). After this comes the
`Unexpected feature statistics`, which are explained more below, and
`Timing statistics`, and a list of important output files.

The two output files that end in `.out` include per-sequence tabular
data, with one line per sequence with fields separated by whitespace
(spaces, not tabs). These two files, along with all output files, will
both be in the new directory 'test' that was created by the example
run above.

The two file types are a 'short' file of 6 columns, and a 'long' file
with 20 columns with more information. Each file includes a
description of the columns at the end of the file.

<a name="short"></a> The short file is included below. Note that the meaning of the columns are briefly explained
in comment lines (prefixed with `#`) after the tabular output, along with explanations of
possible values in the `unexpected_features` column. These are explained more [below](#unexpectedfeatures).
```
> cat test/test.ribotyper.short.out
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

```
The `test/test.ribotyper.long.out` file is not shown because its lines are so wide, but it
also includes brief descriptions of each column. An example is in testfiles/test.ribotyper.long.out

## <a name="unexpectedfeatures"></a> Unexpected features and reasons for a sequence to _FAIL_

There are several 'unexpected features' of sequences that are detected
and reported in the rightmost column of both the short and long output
files. These unexpected features can cause a sequence to FAIL, as
explained below.  

There are 15 possible unexpected features that get reported, some of
which are related to each other. 11 of the 15 can arise when
ribotyper is used with default arguments, and therefore appear in
the example above; the other four can arise only when specific
additional non-default arguments are used, as explained
below. Therefore, the list of 15 feaures below, with long
descriptions, subsumes the list of 11 features given above with
shorter descriptions.  Eight of the unexpected features will always
cause a sequence to fail. The other seven unexpected features *can*
cause a sequence to fail, but only if specific command line options
are used.

You can tell which unexpected features cause sequences to FAIL for a
particular ribotyper run by looking unexpected feature column (final
column) of the short or long output files: those that cause failures
will begin with the '*' character (e.g. `*NoHits`) and those that do
not cause failures will not begin with a "*". You can control which
unexpected features cause failures using command line options as
explained below in the descriptions of each unexpected feature.

List of unexpected features:

1. "NoHits": No hits to any models above the minimum score threshold
were found. The minimum score threshold is 20 bits, which should find
all legitimate SSU/LSU sequences, but this minimum score threshold is
changeable to `<x>` with the `--minbit <x>`. ALWAYS CAUSES FAILURE.

2. "MultipleFamilies": hit to two or more 'families'
(e.g. SSU or LSU) exists for the same sequence. This would happen, for
example, if a single sequence had a fragment of an SSU sequence and a
fragment of an LSU sequence on it. ALWAYS CAUSES FAILURE.

3. "BothStrands": At least 1 hit above minimum score
threshold to best model exists on both strands. ALWAYS CAUSES FAILURE.

4. "DuplicateRegion": At least two hits overlap in model coordinates
by `P` positions or more. The threshold `P` is 10 by default but can be
changed to `<n>` with the `--maxoverlap <n>` option. ALWAYS CAUSES
FAILURE.

5. "InconsistentHits": The hits to the best model are
inconsistent in that they are not in the same order in the sequence
and the model, possibly indicating a misassembly. ALWAYS CAUSES
FAILURE.

6. "UnacceptableModel": Best hit is to a model that is
'unacceptable'. By default, all models are acceptable, but the user
can specify only certain top-scoring models are 'acceptable' using the
`--inaccept <s>` option. If `--inaccept` is not used, this unexpected
feature will never be reported. An example of using `--inaccept` is
given [below](#acceptable). ALWAYS CAUSES FAILURE.

7. "QuestionableModel": Best hit is to a model that is
'questionable'. By default, no models are questionable, but the user
can specify certain top-scoring models are 'questionable' using the
`--inaccept <s>` option. If `--inaccept` is not used, this unexpected
feature will never be reported. An example of using `--inaccept` is
given [below](#acceptable). ONLY CAUSES FAILURE IF THE `--questfail`
OPTION IS ENABLED.

8. "MinusStrand": The best hit is on the minus strand. ONLY CAUSES
FAILURE IF THE `--minusfail` OPTION IS ENABLED.

9. "LowScore": the bits per nucleotide
statistic (total bit score divided by length of total sequence (not
just length of hit)) is below threshold. By default the threshold is
0.5 bits per position, but this can be changed to `<x>` with the
`--lowppossc <x>` option. ONLY CAUSES FAILURE IF THE `--scfail` OPTION
IS ENABLED.

10. "LowCoverage": the total coverage of all hits to the best model
(summed length of all hits divided by total sequence length) is below
threshold. By default the threshold is 0.86, but it can be changed to
`<x>` with the `--tcov <x>` option; `<x>` should be between 0 and 1.
Additionally, one can set a different coverage threshold for 'short'
sequences using the `--tshortcov <x1>` option, which must be used in
combination with the `--tshortlen <n>` option which specifies that
sequences less than or equal to `<n>` nucleotides in length will be
subject to the coverage threshold `<x1>` from `--tshortcov <x1>`. ONLY
CAUSES FAILURE IF THE `--covfail` OPTION IS ENABLED.

11. "LowScoreDifference": the score
difference between the top two domains is below the 'low'
threshold. By default this is the score per position difference, and
the 'low' threshold is 0.10 bits per position, but this is changeable
to <x> bits per position with the `--lowpdiff` option. The difference
can be changed from bits per position to total bits with the `--absdiff`
option. If `--absdiff` is used, the threshold is 100 bits, but
changeable to <x> with the `--lowadiff` <x> option. ONLY CAUSES FAILURE
IF THE `--difffail` OPTION IS ENABLED.

12. "VeryLowScoreDifference": the score
difference between the top two domains is below the 'very low'
threshold. By default this is the score per position difference, and
the 'very low' threshold is 0.04 bits per position, but this is
changeable to `<x>` bits per position with the `--vlowpdiff` option. The
difference can be changed from bits per position to total bits with
the `--absdiff` option. If `--absdiff` is used, the threshold is 40 bits,
but changeable to <x> with the `--vlowadiff <x>` option. ONLY CAUSES
FAILURE IF THE `--difffail` OPTION IS ENABLED.

13. "MultipleHits": there are more than one hits to the
best scoring model. ONLY CAUSES FAILURE IF THE `--multfail` OPTION IS
ENABLED.

14. "TooShort": the sequence is too short, less than `<n1>` nucleotides
in length. ALWAYS CAUSES FAILURE WHEN REPORTED BUT ONLY REPORTED IF
THE `--shortfail <n1>` OPTION IS ENABLED.

15. "TooLong": the sequence is too long, more than `<n2>` nucleotides in
length. ALWAYS CAUSES FAILURE WHEN REPORTED BUT ONLY REPORTED IF THE
`--longfail <n2>` OPTION IS ENABLED.

### <a name="library"></a> The ribotyper default model library

By default, ribotyper will use its default model library (installed in
`$RIBOSCRIPTSDIR/models/ribotyper.cm`) which includes 15 SSU rRNA
profiles and 3 LSU rRNA profiles. More information on the model library
can be found [here](models.md#library).

ribotyper requires a `modelinfo` file that includes information on the
model library it uses. The `modelinfo` file that goes along with the
default model library is `$RIBOSCRIPTSDIR/models/ribotyper.modelinfo`.

That file is included below:
```
> cat $RIBOSCRIPTSDIR/models/ribotyper.modelinfo
# Each non-# prefixed line should have 4 white-space delimited tokens: 
#<modelname> <family> <domain> <CM-file-with-only-this-model>
# The first line is special, it indicates the name of the master CM file
# with all the models in it
#model                         family domain             cmfile
*all*                             -   -                  ribotyper.cm
SSU_rRNA_archaea                  SSU Archaea            rt.SSU_rRNA_archaea.enone.cm
SSU_rRNA_bacteria                 SSU Bacteria           rt.SSU_rRNA_bacteria.enone.cm
SSU_rRNA_eukarya                  SSU Eukarya            rt.SSU_rRNA_eukarya.enone.cm
SSU_rRNA_microsporidia            SSU Euk-Microsporidia  rt.SSU_rRNA_microsporidia.enone.cm
SSU_rRNA_chloroplast              SSU Chloroplast        rt.SSU_rRNA_chloroplast.enone.cm
SSU_rRNA_mitochondria_metazoa     SSU Mito-Metazoa       rt.SSU_rRNA_mitochondria_metazoa.enone.cm
SSU_rRNA_cyanobacteria            SSU Bacteria           rt.SSU_rRNA_cyanobacteria.enone.cm
LSU_rRNA_archaea                  LSU Archaea            rt.LSU_rRNA_archaea.enone.cm
LSU_rRNA_bacteria                 LSU Bacteria           rt.LSU_rRNA_bacteria.enone.cm
LSU_rRNA_eukarya                  LSU Eukarya            rt.LSU_rRNA_eukarya.enone.cm
SSU_rRNA_apicoplast               SSU Euk-Apicoplast     rt.SSU_rRNA_apicoplast.enone.cm
SSU_rRNA_chloroplast_pilostyles   SSU Chloroplast        rt.SSU_rRNA_chloroplast_pilostyles.enone.cm
SSU_rRNA_mitochondria_amoeba      SSU Mito-Amoeba        rt.SSU_rRNA_mitochondria_amoeba.enone.cm
SSU_rRNA_mitochondria_chlorophyta SSU Mito-Chlorophyta   rt.SSU_rRNA_mitochondria_chlorophyta.enone.cm  
SSU_rRNA_mitochondria_fungi       SSU Mito-Fungi         rt.SSU_rRNA_mitochondria_fungi.enone.cm  
SSU_rRNA_mitochondria_kinetoplast SSU Mito-Kinetoplast   rt.SSU_rRNA_mitochondria_kinetoplast.enone.cm  
SSU_rRNA_mitochondria_plant       SSU Mito-Plant         rt.SSU_rRNA_mitochondria_plant.enone.cm  
SSU_rRNA_mitochondria_protist     SSU Mito-Protist       rt.SSU_rRNA_mitochondria_protist.enone.cm  
```

Using this file will classify sequences SSU and LSU sequences from any
of the listed domains. 

You can create your own `modelinfo` and CM files and use them with ribotyper, with the `-i` option.

###<a name="strategy"></a> ribotyper's two round search strategy

ribotyper proceeds in two rounds. The first round is called the
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

### <a name="acceptable"></a> Defining acceptable/questionable models

The user can provide an additional input file that specifies which
models are 'acceptable' or 'questionable'. For GenBank, this usage can
be relevant when the submitter has made claims about which types of
SSU or LSU sequences are being submitted. In that situation, the
models consistent with the submitter's claims should be acceptable and
all other models should be questionable. All sequences for which the
highest ranked (by bit score unless the option `--evalues` is used)
hit is _not_ one of the acceptable or questionable models, will FAIL for
Reason 6 above. All sequences for which the top hit is one of the
questionable models will be reported with 'questionable_model' in
their `unexpected_feature` string (and will FAIL if the `--questfail` option
is enabled) (Reason 7 above).

*If the `--inaccept` option is not used, then _all_ models listed in the
`.modelinfo` file will be considered acceptable and none will be
considered questionable.*

An example input file that specifies that only the SSU_rRNA_bacteria
and SSU_rRNA_cyanobacteria as 'acceptable' from model file 1 is:
`$RIBOSCRIPTSDIR/models/ribotyper.ssu-arc-bac.accept`:

```
> cat $RIBOSCRIPTSDIR/models/ribosensor.ssu-arc-bac.accept
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
# Any model not listed here will have the 'unacceptable_model'
# unusual feature reported for it.
SSU_rRNA_archaea acceptable
SSU_rRNA_bacteria acceptable
SSU_rRNA_cyanobacteria acceptable
SSU_rRNA_chloroplast questionable
```

To use this on the example run from above, use the `--inaccept`
option:

```
> ribotyper -f --inaccept $RIBOSCRIPTSDIR/models/ribosensor.ssu-arc-bac.accept $RIBOSCRIPTSDIR/testfiles/example-16.fa test2
```

Now, the short output file will set any family that was classified as
a model other than SSU_rRNA_archaea, SSU_rRNA_bacteria,
SSU_rRNA_cyanobacteria, or SSU_rRNA_chloroplast as FAILs, and the
string `*UnacceptableModel` will be present in the
`unexpected_features` column.

```
> cat test2/test2.ribotyper.short.out 
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
12    01223::Audouinella_hermannii.::AF026040        SSU.Eukarya            plus   FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);
13    01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya            plus   FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);
14    00220::Euplotes_aediculatus.::M14590           SSU.Eukarya            plus   FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);
15    00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya            minus  FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);MinusStrand;
16    01710::Oryza_sativa.::X00755                   SSU.Eukarya            plus   FAIL  *UnacceptableModel:(SSU_rRNA_eukarya);
#
```

### <a name="options"></a>List of all command-line options

You can see all the available command line options to ribotyper by
calling it at the command line with the -h option:

```
> ribotyper -h
# ribotyper :: detect and classify ribosomal RNA sequences
# Ribovore 1.0 (Jan 2021)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Tue Dec 22 16:56:29 2020
#
Usage: ribotyper [-options] <fasta file to annotate> <output directory>

basic options:
  -f     : force; if <output directory> exists, overwrite it
  -v     : be verbose; output commands to stdout as they're run
  -n <n> : use <n> CPUs [0]
  -i <s> : use model info file <s> instead of default

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
  -s <n>     : seed for random number generator is <n> [181]
  --nkb <n>  : number of KB of sequence for each cmsearch farm job is <n> [100]
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
  --skipval    : skip validation of CM and model info files
  --onlyval    : validate CM and model info files and exit
```

---

#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.
