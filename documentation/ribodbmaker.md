# <a name="top"></a> `ribodbmaker` example usage, command-line options and customizability

* [Limitations on Mac/OSX](#macosx)
* [Example usage on Linux](#exampleusagelinux)
* [Example usage on Mac/OSX](#exampleusagemacosx)
* [Customizing ribodbmaker](#customize)
  * [Customizing ribotyper runs within ribodbmaker](#ribotyper)
  * [Customizing riboaligner runs within ribodbmaker](#riboaligner)
* [Special considerations for large input datasets](#large)
* [List of all command-line options](#options)
* [Parallelizing with the -p option](#parallelize)

---

ribodbmaker is designed to create high quality sequence datasets of
rRNA sequences by performing a series of tests or checks and only
sequences that survive all tests will pass ribodbmaker and be part of
the final dataset. The tests are customizable in that they can be skipped and
in many cases the pass/fail criteria for each test can be modified via
command-line options. The example usage section below demonstrates the
default set of tests performed by ribodbmaker.

---

##  <a name="macosx"></a> Limitations on Mac/OSX

One of the programs that ribodbmaker uses, vecscreen_plus_taxonomy, is
not available for Mac/OSX. ribodbmaker still runs on Mac/OSX but in a
limited capacity and specific command-line options are required. 
See the [example Mac/OSX usage below](#exampleusagemacosx) for more information.

---

## ribodbmaker example usage on Linux <a name="exampleusagelinux"></a>

This example runs ribodbmaker on a sample file of 10 fungal 18S SSU
rRNA sequences.

This command will only work if you've installed Ribovore on Linux
because the vecscreen_plus_taxonomy program is only installed for
Linux as it is not available for Mac/OSX. For example usage on Mac/OSX
see [below](#exampleusagemacosx)

Move into a directory in which you have write permission and execute
the following command:

```
> ribodbmaker --model SSU.Eukarya fungi-ssu.r10.fa db10
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
> ribodbmaker -f --model SSU.Eukarya fungi-ssu.r10.fa db10
```

The `--model SSU.Eukarya` part of the command informs ribodbmaker that
the goal of this run is to create a high quality dataset of eukaryotic
SSU rRNA sequences. Any sequences that do not match best to a model in
the SSU family and eukaryotic domain will fail.  This classification
is accomplished by the ribotyper program, and any pair of values from
columns 3 and 4 of the [default model info
file](#ribotyper.md:library) can be used with the `--model` option.

ribodbmaker will proceed over several steps as indicated in its output:

```
# ribodbmaker :: create representative database of ribosomal RNA sequences
# Ribovore 1.0 (Jan 2020)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:             Tue Dec 29 17:15:11 2020
# $RIBOBLASTDIR:    /home/nawrocke/tmp/ribovore-install/ncbi-blast/bin
# $RIBOEASELDIR:    /home/nawrocke/tmp/ribovore-install/infernal/binaries
# $RIBOSCRIPTSDIR:  /home/nawrocke/tmp/ribovore-install/ribovore
# $VECPLUSDIR:      /home/nawrocke/tmp/ribovore-install/vecscreen_plus_taxonomy
#
# input sequence file:    /home/nawrocke/tmp/ribovore-install/ribovore/testfiles/fungi-ssu.r10.fa
# output directory name:  db10
# model to use is <s>:    SSU.Eukarya [--model]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# [Stage: prelim] Validating input files                                            ... done. [    0.0 seconds]
# [Stage: prelim] Copying input fasta file                                          ... done. [    0.0 seconds]
# [Stage: prelim] Reformatting names of sequences                                   ... done. [    0.0 seconds]
# [Stage: prelim] Determining target sequence lengths                               ... done. [    0.1 seconds]
# [Stage: prelim] Running srcchk for all sequences                                  ... done. [   37.4 seconds]
# [Stage: fambig] Filtering based on ambiguous nucleotides                          ... done. [    0.0 seconds,      9 pass;      1 fail;]
# [Stage: ftaxid] Filtering for specified species                                   ... done. [    4.1 seconds,      5 pass;      5 fail;]
# [Stage: fvecsc] Identifying vector sequences with VecScreen                       ... done. [    0.8 seconds,     10 pass;      0 fail;]
# [Stage: fblast] Identifying repeats by BLASTing against self                      ... done. [    0.3 seconds,     10 pass;      0 fail;]
# [Stage: fribo1] Running ribotyper                                                 ... done. [    5.4 seconds,      9 pass;      1 fail;]
# [Stage: fribo2] Running riboaligner                                               ... done. [   38.7 seconds,      9 pass;      1 fail;]
# [Stage: fribo2] Filtering out seqs riboaligner identified as too long             ... done. [    0.0 seconds,      9 pass;      0 fail;]
# [Stage: fmspan] Filtering out seqs based on model span                            ... done. [    0.0 seconds,      5 pass;      4 fail;]
# [***Checkpoint] Creating lists that survived all filter stages                    ... done. [    0.0 seconds,      1 pass;      9 fail; ONLY PASSES ADVANCE]
# [Stage: ingrup] Determining percent identities in alignments                      ... done. [    0.0 seconds]
# [Stage: ingrup] Performing ingroup analysis                                       ... done. [    0.8 seconds,      1 pass;      0 fail;]
# [Stage: ingrup] Identifying phyla lost in ingroup analysis                        ... done. [    0.0 seconds, 0 phyla lost]
# [Stage: ingrup] Identifying classes lost in ingroup analysis                      ... done. [    0.0 seconds, 0 classes lost]
# [Stage: ingrup] Identifying orders lost in ingroup analysis                       ... done. [    0.0 seconds, 0 orders lost]
# [***Checkpoint] Creating lists that survived ingroup analysis                     ... done. [    0.0 seconds,      1 pass;      0 fail; ONLY PASSES ADVANCE]
# [***OutputFile] Generating model span survival tables for all seqs                ... done. [    1.9 seconds]
# [***OutputFile] Generating model span survival tables for PASSing seqs            ... done. [    1.0 seconds]
# [Stage: clustr] Clustering surviving sequences                                    ... done. [    0.0 seconds]
# [***Checkpoint] Creating lists of seqs that survived clustering                   ... done. [    0.0 seconds,      1 pass;      0 fail;]
#
# Number of input sequences:                                                 10  [listed in db10/db10.ribodbmaker.full.seqlist]
# Number surviving all filter stages:                                         1  [listed in db10/db10.ribodbmaker.surv_filters.pass.seqlist]
# Number surviving ingroup analysis:                                          1  [listed in db10/db10.ribodbmaker.surv_ingrup.pass.seqlist]
# Number surviving clustering (number of clusters):                           1  [listed in db10/db10.ribodbmaker.surv_clustr.pass.seqlist]
# Number in final set of surviving sequences:                                 1  [listed in db10/db10.ribodbmaker.final.pass.seqlist]
# Number of phyla   represented in final set of surviving sequences:          1  [listed in final line of db10/db10.ribodbmaker.phylum.ct]
# Number of classes represented in final set of surviving sequences:          1  [listed in final line of db10/db10.ribodbmaker.class.ct]
# Number of orders  represented in final set of surviving sequences:          1  [listed in final line of db10/db10.ribodbmaker.order.ct]
#
# Output printed to screen saved in:                                                          db10.ribodbmaker.log
# List of executed commands saved in:                                                         db10.ribodbmaker.cmd
# List and description of all output files saved in:                                          db10.ribodbmaker.list
# list of 0 phyla lost in the ingroup analysis saved in:                                      db10.ribodbmaker.ingrup.phylum.lost.list
# list of 0 classes lost in the ingroup analysis saved in:                                    db10.ribodbmaker.ingrup.class.lost.list
# list of 0 orders lost in the ingroup analysis saved in:                                     db10.ribodbmaker.ingrup.order.lost.list
# table summarizing number of sequences (all) for different model position spans saved in:    db10.ribodbmaker.all.mdlspan.survtbl
# table summarizing number of sequences (pass) for different model position spans saved in:   db10.ribodbmaker.pass.mdlspan.survtbl
# fasta file with final set of surviving sequences saved in:                                  db10.ribodbmaker.final.fa
# tab-delimited file listing number of sequences per phylum taxid saved in:                   db10.ribodbmaker.phylum.ct
# tab-delimited file listing number of sequences per class taxid saved in:                    db10.ribodbmaker.class.ct
# tab-delimited file listing number of sequences per order taxid saved in:                    db10.ribodbmaker.order.ct
# tab-delimited tabular output summary file saved in:                                         db10.ribodbmaker.tab.tbl
# whitespace-delimited, more readable output summary file saved in:                           db10.ribodbmaker.rdb.tbl
#
# All output files created in directory ./db10/
#
# Elapsed time:  00:01:30.80
#                hh:mm:ss
# 
[ok]
```

You may see one or more lines like this:

```
Warning: (1306.8) SAccGuide::AddRule: 25: ignoring refinement of E?? from gb_wgs_prot to unrecognized accession type gb_wgsv_prot
```

after the `# [Stage: prelim] Running srcchk for all sequences` line.
These warnings do not indicate a showstopping problem and can be ignored. 

ribodbmaker outputs information on each stage as it progresses. The
first 5 lines are for the preliminary (`prelim`) stage prior to any of the test stages:
```
# [Stage: prelim] Validating input files                                            ... done. [    0.0 seconds]
# [Stage: prelim] Copying input fasta file                                          ... done. [    0.0 seconds]
# [Stage: prelim] Reformatting names of sequences                                   ... done. [    0.0 seconds]
# [Stage: prelim] Determining target sequence lengths                               ... done. [    0.1 seconds]
# [Stage: prelim] Running srcchk for all sequences                                  ... done. [   37.4 seconds]
```

After the preliminary stage, each filter stage is carried out and the number of 
sequences that pass and fail each stage is output to the screen:

```
# [Stage: fambig] Filtering based on ambiguous nucleotides                          ... done. [    0.0 seconds,      9 pass;      1 fail;]
# [Stage: ftaxid] Filtering for specified species                                   ... done. [    4.1 seconds,      5 pass;      5 fail;]
# [Stage: fvecsc] Identifying vector sequences with VecScreen                       ... done. [    0.8 seconds,     10 pass;      0 fail;]
# [Stage: fblast] Identifying repeats by BLASTing against self                      ... done. [    0.3 seconds,     10 pass;      0 fail;]
# [Stage: fribo1] Running ribotyper                                                 ... done. [    5.4 seconds,      9 pass;      1 fail;]
# [Stage: fribo2] Running riboaligner                                               ... done. [   38.7 seconds,      9 pass;      1 fail;]
# [Stage: fribo2] Filtering out seqs riboaligner identified as too long             ... done. [    0.0 seconds,      9 pass;      0 fail;]
# [Stage: fmspan] Filtering out seqs based on model span                            ... done. [    0.0 seconds,      5 pass;      4 fail;]
# [***Checkpoint] Creating lists that survived all filter stages                    ... done. [    0.0 seconds,      1 pass;      9 fail; ONLY PASSES ADVANCE]
```


For each of these filter stages, each sequence is analyzed
independently of all other sequences, and each sequence is analyzed at
each stage (regardless of whether it passes or fails any previous
stage) with the exception of the second part of the `fribo2` stage and
the `fmspan` stage which require an alignment of the sequence being
analyzed and so will only work on sequences that passed the riboaligner
stage (first part of the `fribo2` stage).

After the filter stages, any sequence that failed one or more filter
stages is excluded from further analysis. The remaining analysis is based on 
a multiple sequence alignment created by riboaligner and each sequence
is no longer analyzed independently. In this 'ingroup analysis' (`Stage: ingrup`), 
sequence pairwise percent identities are computed based on the alignment and used
along with taxonomic information to detect sequences that may be misclassified
taxonomically. Sequences detected as possibly anomalous in this way will fail.

```
# [Stage: ingrup] Determining percent identities in alignments                      ... done. [    0.0 seconds]
# [Stage: ingrup] Performing ingroup analysis                                       ... done. [    0.8 seconds,      1 pass;      0 fail;]
# [Stage: ingrup] Identifying phyla lost in ingroup analysis                        ... done. [    0.0 seconds, 0 phyla lost]
# [Stage: ingrup] Identifying classes lost in ingroup analysis                      ... done. [    0.0 seconds, 0 classes lost]
# [Stage: ingrup] Identifying orders lost in ingroup analysis                       ... done. [    0.0 seconds, 0 orders lost]
# [***Checkpoint] Creating lists that survived ingroup analysis                     ... done. [    0.0 seconds,      1 pass;      0 fail; ONLY PASSES ADVANCE]
```

In this example, only 1 sequence survives to the ingroup analysis stage so 
there are no other sequences to compare it with and so it cannot fail at this stage, but in a larger dataset, 
it is possible that sequences will fail here.

```
# [***OutputFile] Generating model span survival tables for all seqs                ... done. [    1.9 seconds]
# [***OutputFile] Generating model span survival tables for PASSing seqs            ... done. [    1.0 seconds]
```

Next, a model span surivival table is created. This file may be useful for 
users that are attempting to determine what model span to use for filtering.
The model span is the minimum required start and stop model positions
that each aligned sequence must satisfy. By default, these are positions 
60 and L-59 where L is the model length. They can be changed with the `--fmpos` or
`--fmlpos` and `--fmrpos` [command-line options](#options).


# [Stage: clustr] Clustering surviving sequences                                    ... done. [    0.0 seconds]
# [***Checkpoint] Creating lists of seqs that survived clustering                   ... done. [    0.0 seconds,      1 pass;      0 fail;]
#
```


Sequences that pass all stages are
then further analyzed.

| stage  | brief description | option to skip/include | 
|--------|-------------------|------------------------|
| fambig | sequences with too many ambiguous nucleotides fail | `--skipfambig` |
| ftaxid | sequences without a specified species fail | `--skipfaxid` |
| fvecsc | sequences with a non-weak VecScreen match fail |  `--skipfvecsc` |
| fblast | sequences with a unexpected blastn hits against self fail |  `--skipfblast` |

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
