# <a name="top"></a> `ribosensor` example usage, command-line options and pass/fail criteria

* [Example usage](#exampleusage)
* [rRNA_sensor errors in ribosensor](#rrnasensorerrors)
* [ribotyper errors in ribosensor](#ribotypererrors)
* [GenBank errors in ribosensor](#genbankerrors)
* [Using ribosensor for 18S eukaryotic SSU rRNA sequences](#18S)
* [rRNA_sensor blastn databases](#blastdb)
* [List of all command-line options](#options)
---

ribosensor combines ribotyper and another program, rRNA_sensor,
together to classify and validate ribosomal RNA (rRNA) sequences. It
was designed for screening incoming rRNA sequence submissions to
GenBank. ribotyper (documentation [here](ribotyper.md)) uses profile
HMMs to analyze sequences and
[rRNA_sensor](https://github.com/aaschaffer/rRNA_sensor) uses the
single-sequence based blastn program to analyze sequences. The results
of both programs are then combined to determine if a sequence *pass*es
or *fail*s.

---

## `ribosensor` example usage <a name="exampleusage"></a>

This example runs ribosensor on a sample file of 16 
sequences.

Move into a directory in which you have write permission and execute
the following command:

```
> ribosensor $RIBOSCRIPTSDIR/testfiles/example-16.fa test-rs
```

Like other Ribovore scripts, ribosensor takes 2 required command
line arguments. Optional arguments are explained [below](#options).

The first required argument is the sequence file you want to annotate.
The $RIBOSCRIPTSDIR environment variable should be defined in your
`.bashrc` or `.cshrc` as explained in the [installation
documentation](install.md#environment).

The second required argument is the name of the output subdirectory
that you would like ribosensor to create. Output files will be placed
in this output directory. If this directory already exists, the
program will exit with an error message indicating that you need to
either (a) remove the directory before rerunning, or (b) use the -f
option with riboaligner, in which case the directory will be
overwritten.  The command adding `-f` is:

```
> ribosensor -f $RIBOSCRIPTSDIR/testfiles/example-16.fa test-rs
```

You should see something like the following output:
```
# ribosensor :: analyze ribosomal RNA sequences with profile HMMs and BLASTN
# Ribovore 1.0 (Jan 2021)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:              Tue Dec 29 17:00:04 2020
# $RIBOBLASTDIR:     /usr/local/src/ribovore-install/ncbi-blast/bin
# $RIBOEASELDIR:     /usr/local/src/ribovore-install/infernal/binaries
# $RIBOINFERNALDIR:  /usr/local/src/ribovore-install/infernal/binaries
# $RIBOSCRIPTSDIR:   /usr/local/src/ribovore-install/ribovore
# $RIBOTIMEDIR:      /usr/bin
# $RRNASENSORDIR:    /usr/local/src/ribovore-install/rRNA_sensor
#
# target sequence input file:   /usr/local/src/ribovore-install/ribovore/testfiles/example-16.fa
# output directory name:        test-rs
# forcing directory overwrite:  yes [-f]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Partitioning sequence file based on sequence lengths         ... done. [    0.0 seconds]
# Running ribotyper on full sequence file                      ... done. [    3.9 seconds]
# Running rRNA_sensor on seqs of length 351..600               ... done. [    0.3 seconds]
# Running rRNA_sensor on seqs of length 601..inf               ... done. [    1.9 seconds]
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
  ribotyper        16      4.1      5402.0      5402.0              00:00:03.94
  sensor           16      7.4      9872.4      9872.4              00:00:02.15
  total            16      2.5      3329.6      3329.6              00:00:06.38
#
#
# Human readable error-based output saved to file test-rs/test-rs.ribosensor.out
# GPIPE error-based output saved to file test-rs/test-rs.ribosensor.gpipe
#
# List and description of all output files saved in:                                  test-rs.ribosensor.list
# Output printed to screen saved in:                                                  test-rs.ribosensor.log
# List of executed commands saved in:                                                 test-rs.ribosensor.cmd
# summary of rRNA_sensor results saved in:                                            test-rs.ribosensor.sensor.out
# summary of ribotyper results saved in:                                              test-rs.ribosensor.ribo.out
# summary of combined rRNA_sensor and ribotyper results (original errors) saved in:   test-rs.ribosensor.out
# summary of combined rRNA_sensor and ribotyper results (GPIPE errors) saved in:      test-rs.ribosensor.gpipe
#
# All output files created in directory ./test-rs/
#
# Elapsed time:  00:00:06.38
#                hh:mm:ss
# 
[ok]
```

ribosensor outputs information on each step and how long it takes,
followed by a list of output files.

ribosensor first runs ribotyper as reported in the output:
```
# Running ribotyper on full sequence file                      ... done. [    3.6 seconds]
```

Next, rRNA_sensor is executed, up to three times, once for sequences
350 nucleotides or shorter, once for sequences of length between 351
and 600 nucleotides and once for sequences more than 600
nucleotides. For each length range, different rRNA_sensor parameters
are used determined to work well for that length range. For this
example, there are zero sequences less than 351 nucleotides so
rRNA_sensor is run only twice, as reported in the output:

```
# Running rRNA_sensor on seqs of length 351..600               ... done. [    0.2 seconds]
# Running rRNA_sensor on seqs of length 601..inf               ... done. [    1.7 seconds]
```

Finally, the ribotyper and rRNA_sensor output is parsed to determine
if each sequence passes or fails each program. Each sequence fails
ribotyper if it receives one or more ribotyper errors (explained more
[here](#ribotypererrors)) and otherwise passes ribotyper.  Each
sequence fails rRNA_sensor if it receives one or more rRNA_sensor
errors (explained more [here](#rrnasensorerrors)) and otherwise passes
rRNA_sensor.

Based on whether it passes or fails each of the two programs, each sequence is assigned
one of four possible 'outcomes':

| outcome | ribotyper pass/fail | rRNA_sensor pass/fail |
|---------|---------------------|-----------------------|
| RPSP    | PASS                | PASS                  |
| RPSF    | PASS                | FAIL                  |
| RFSP    | FAIL                | PASS                  |
| RFSF    | FAIL                | FAIL                  |

The counts of sequences for each outcome are output. For the above example the outcome counts are:
```
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
```

The 'pass' column indicates how many sequences in each outcome class 'pass' ribosensor.
All RPSP sequences pass ribosensor. Some RPSF and RFSP sequences also pass ribosensor
as explained more below. All RFSF sequences fail ribosensor.

The ribosensor output also includes `Per-program error counts:`:
```
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
```

The `CLEAN` row pertains to the RPSP sequences which had zero errors
in both ribotyper and rRNA_sensor. The remaining rows are for
ribotyper errors (those beginning with `R_`) or rRNA_sensor errors
(those beginning with `S_`), and are explained in the sections below
on [ribotyper errors](#ribotypererrors) and [rRNA_sensor
errors](#rrnasensorerrors).

Finally, information on the number of GenBank errors is output
```
# GENBANK error counts:
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
```

GenBank errors are determined by combining the ribotyper and rRNA_sensor errors as explained [here](#genbankerrors).

## rRNA_sensor errors in ribosensor <a name="rrnasensorerrors"></a>

Any sequence that receives one or more rRNA_sensor errors will be considered to have failed rRNA_sensor.

The possible rRNA_sensor errors are listed in the table below, along with the [GenBank errors](#genbankerrors) they associate with.

| rRNA_sensor error    | associated GenBank error |  cause/explanation  |
|----------------------|--------------------------|---------------------|
|S_NoHits*             | SEQ_HOM_NotSSUOrLSUrRNA  | no hits reported ('no' in column 2) | 
|S_NoSimilarity*       | SEQ_HOM_LowSimilarity    | coverage (column 5) of best blast hit is < 10% |
|S_LowSimilarity*      | SEQ_HOM_LowSimilarity    | coverage (column 5) of best blast hit is < 80% (is seq len <= 350 nt) or < 86% (if seq len > 350 nt) |
|S_LowScore*           | SEQ_HOM_LowSimilarity    | either id percentage below length-dependent threshold (75%,80%,86%) or E-value above 1e-40 ('imperfect_match` in column 2) |
|S_BothStrands         | SEQ_HOM_MisAsBothStrands | hits on both strands ('mixed' in column 2) |
|S_MultipleHits        | SEQ_HOM_MultipleHits     | more than 1 hit reported (column 4 value > 1) |

As an exception, the first four rRNA_sensor errors (labelled with '*') do not trigger a GenBank error
and so are ignored by ribosensor (and so do not cause a sequence to fail ribosensor)
if either (a) the sequence is 'RPSF' (passes ribotyper and fails rRNA_sensor) and
the `-c` option is *not* used with ribosensor or (b)
the sequence is 'RFSF' (fails both ribotyper and rRNA_sensor) and
R_UnacceptableModel or R_QuestionableModel ribotyper errors are also reported.

## ribotyper errors in ribosensor <a name="ribotypererrors"></a>

ribotyper detects and reports up to 15 different types (depending on
command-line arguments) of 'unexpected_features' for each sequence, as
explained more [here](#ribotyper.md:unexpectedfeatures). In the
context of ribosensor, 10 of these 15 types are detected by ribosensor
and cause a sequence to fail ribotyper. They are listed below along
with the [GenBank errors](#genbankerrors) they associate with.

| ribotyper error          | associated GenBank error         | cause/explanation | 
|--------------------------|----------------------------------|-------------------|
| R_NoHits                 | SEQ_HOM_NotSSUOrLSUrRNA          | no hits reported |
| R_MultipleFamilies       | SEQ_HOM_SSUAndLSUrRNA            | SSU and LSU hits |
| R_LowScore               | SEQ_HOM_LowSimilarity            | bits/position score is < 0.5 |
| R_BothStrands            | SEQ_HOM_MisAsBothStrands         | hits on both strands |
| R_InconsistentHits       | SEQ_HOM_MisAsHitOrder            | hits are in different order in sequence and model |
| R_DuplicateRegion        | SEQ_HOM_MisAsDupRegion           | hits overlap by 10 or more model positions |
| R_UnacceptableModel      | SEQ_HOM_TaxNotExpectedSSUrRNA    | best hit is to model other than expected set; 16S expected set: SSU.Archaea, SSU.Bacteria, SSU.Cyanobacteria, SSU.Chloroplast; 18S expected set: SSU.Eukarya; |
| R_LowCoverage            | SEQ_HOM_LowCoverage              | coverage of all hits is < 0.80 (if <= 350nt) or 0.86 (if > 350nt) |
| R_QuestionableModel+    | SEQ_HOM_TaxQuestionableSSUrRNA   | best hit is to a 'questionable' model (if mode is 16S: SSU.Chloroplast, if mode is 18S, does not apply) | 
| R_MultipleHits+         | SEQ_HOM_MultipleHits             | more than 1 hit reported | 

As an exception, the final two errors (labelled with '+') do not trigger a GenBank error
and so are ignored by ribosensor (and so do not cause a sequence to fail ribosensor) 
if the sequence is 'RFSP' (fails ribotyper but passes rRNA\_sensor).

## GenBank errors in ribosensor <a name="genbankerrors"></a>

A sequence fails ribosensor if it has one or more GenBank errors. Each GenBank error is
triggered by one or more rRNA_sensor and/or ribotyper errors as shown in the table below:

| GenBank error                   | fails to  |  triggering rRNA_sensor/ribotyper errors | 
|---------------------------------|-----------|------------------------------------------|
| SEQ_HOM_NotSSUOrLSUrRNA         | submitter | S_NoHits*, R_NoHits |
| SEQ_HOM_LowSimilarity           | submitter | S_NoSimilarity*, S_LowSimilarity*, S_LowScore*, R_LowScore |
| SEQ_HOM_SSUAndLSUrRNA           | submitter | R_MultipleFamilies |
| SEQ_HOM_MisAsBothStrands        | submitter | S_BothStrands, R_BothStrands |
| SEQ_HOM_MisAsHitOrder           | submitter | R_InconsistentHits |
| SEQ_HOM_MisAsDupRegion          | submitter | R_DuplicateRegion |
| SEQ_HOM_TaxNotExpectedSSUrRNA   | submitter | R_UnacceptableModel |
| SEQ_HOM_TaxQuestionableSSUrRNA  | indexer   | R_QuestionableModel+ |
| SEQ_HOM_LowCoverage             | indexer   | R_LowCoverage |
| SEQ_HOM_MultipleHits            | indexer   | S_MultipleHits, R_MultipleHits+ |

There are two classes of exceptions marked by two different
superscripts in the table: '*': these rRNA_sensor errors do not
trigger a GenBank error if: (a) the sequence is 'RPSF' (passes
ribotyper and fails rRNA_sensor) and the `-c` option is
*not* used with ribosensor or (b) the sequence is 'RFSF'
(fails both ribotyper and rRNA_sensor) and R_UnacceptableModel or
R_QuestionableModel are also reported. '+': these ribotyper errors do
not trigger a GenBank error if sequence is 'RFSP' (fails ribotyper and
passes rRNA_sensor);

---

### <a name="options"></a>Using ribosensor for 18S eukaryotic SSU rRNA sequences

The above example run on the `example-16.fa` file runs ribosensor in
its default *mode* for validation of 16S SSU rRNA sequences from
bacteria or archaea. Alterntatively, ribosensor can be run in 18S mode
to validate 18S SSU rRNA eukaryotic sequences using the command line
option `-m 18S`. For example, we can run ribosensor on the same input file
in 18S mode with the following command:

```
> ribosensor -m 18S $RIBOSCRIPTSDIR/testfiles/example-16.fa test-rs
```

In this case, only 4 sequences pass. These are 4 of the 16 sequences in the input
file which are eukaryotic SSU sequences:

```
# GPIPE error counts:
#
#                                number   fraction
# error                          of seqs   of seqs
# -----------------------------  -------  --------
  CLEAN                                4   0.25000
  SEQ_HOM_NotSSUOrLSUrRNA              1   0.06250
  SEQ_HOM_LengthLong                   1   0.06250
  SEQ_HOM_TaxNotExpectedSSUrRNA       10   0.62500
  SEQ_HOM_LowCoverage                  1   0.06250
```

Currently, 16S (default) and 18S are the only two available modes, but we hope to
add additional modes in the future.

---

---

### <a name="options"></a>rRNA_sensor blastn databases

rRNA_sensor includes two blastn databases: one with 1267 sequences for
16S SSU rRNA (archaeal and bacterial) and one with 1091 sequences for
eukaryotic 18S SSU rRNA. These were created by clustering larger
datasets and only keeping one sequence from each cluster as described
more in the Ribovore 1.0 paper. Following Ribovore installation, the
FASTA files for these databases will be available here:

```
$RIBOINSTALLDIR/rRNA_sensor/16S_centroids.fa
$RIBOINSTALLDIR/rRNA_sensor/18S_centroids.1091.fa 
```

---

### <a name="options"></a>List of all command-line options

You can see all the available command line options to ribosensor by
calling it at the command line with the -h option:

```
> ribosensor -h
# ribosensor :: analyze ribosomal RNA sequences with profile HMMs and BLASTN
# Ribovore 1.0 (Jan 2021)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Tue Dec 29 14:56:08 2020
#
Usage: ribosensor [-options] <fasta file to annotate> <output directory>

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

options for parallelizing cmsearch on a compute farm:
  -p         : parallelize ribotyper and rRNA_sensor on a compute farm
  -q <s>     : use qsub info file <s> instead of default
  -s <n>     : seed for random number generator is <n> [181]
  --nkb <n>  : number of KB of sequence for each farm job is <n> [100]
  --wait <n> : allow <n> wall-clock minutes for jobs on farm to finish, including queueing time [500]
  --errcheck : consider any farm stderr output as indicating a job failure

---

#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.
