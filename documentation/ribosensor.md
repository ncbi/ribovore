# <a name="top"></a> `ribosensor` example usage, command-line options and length classes

* [`ribosensor` example usage](#exampleusage)
* [Example usage](#exampleusage)
* [rRNA_sensor errors in ribosensor]
* [ribotyper errors in ribosensor]
* [GenBank errors in ribosensor]

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
# date:              Tue Dec 29 09:37:20 2020
# $RIBOBLASTDIR:     /usr/local/src/ribovore-install/ncbi-blast/bin
# $RIBOEASELDIR:     /usr/local/src/ribovore-install/infernal/binaries
# $RIBOINFERNALDIR:  /usr/local/src/ribovore-install/infernal/binaries
# $RIBOSCRIPTSDIR:   /usr/local/src/ribovore-install/ribovore
# $RIBOTIMEDIR:      /usr/bin
# $RRNASENSORDIR:    /usr/local/src/ribovore-install/rRNA_sensor
#
# target sequence input file:   /Users/nawrockie/tmp/ribovore-install/ribovore/testfiles/example-16.fa
# output directory name:        test-rs
# forcing directory overwrite:  yes [-f]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Partitioning sequence file based on sequence lengths         ... done. [    0.0 seconds]
# Running ribotyper on full sequence file                      ... done. [    3.6 seconds]
# Running rRNA_sensor on seqs of length 351..600               ... done. [    0.2 seconds]
# Running rRNA_sensor on seqs of length 601..inf               ... done. [    1.7 seconds]
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
#
#
# Timing statistics:
#
# stage      num seqs  seq/sec      nt/sec  nt/sec/cpu  total time             
# ---------  --------  -------  ----------  ----------  -----------------------
  ribotyper        16      4.5      5968.5      5968.5              00:00:03.56
  sensor           16      8.4     11221.3     11221.3              00:00:01.89
  total            16      2.8      3654.0      3654.0              00:00:05.82
#
#
# Human readable error-based output saved to file test-rs/test-rs.ribosensor.out
# GENBANK error-based output saved to file test-rs/test-rs.ribosensor.gbank
#
# List and description of all output files saved in:                                  test-rs.ribosensor.list
# Output printed to screen saved in:                                                  test-rs.ribosensor.log
# List of executed commands saved in:                                                 test-rs.ribosensor.cmd
# summary of rRNA_sensor results saved in:                                            test-rs.ribosensor.sensor.out
# summary of ribotyper results saved in:                                              test-rs.ribosensor.ribo.out
# summary of combined rRNA_sensor and ribotyper results (original errors) saved in:   test-rs.ribosensor.out
# summary of combined rRNA_sensor and ribotyper results (GENBANK errors) saved in:    test-rs.ribosensor.gbank
#
# All output files created in directory ./test-rs/
#
# Elapsed time:  00:00:05.82
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

* RPSP: passes both ribotyper and rRNA_sensor
* RPSF: passes ribotyper and fails rRNA_sensor
* RFSP: fails ribotyper and passes rRNA_sensor
* RFSF: fails both ribotyper and rRNA_sensor

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


## rRNA_sensor errors

For this example there will be two rRNA_sensor output files:
```
test-rs/sensor-2-out/sensor-class.2.out
test-rs/sensor-3-out/sensor-class.3.out
```

(If any sequences 350 nucleotides or less existed in the input file,
there would be a third file `test-rs/sensor-1-out/sensor-class.1.out`.)
The format of these files is explained in the rRNA_sensor [README
file](https://github.com/aaschaffer/rRNA_sensor/blob/master/README),
but briefly:

```
Column 1 is the sequence name

Column 2 is the classification.

Column 3 is the strand of the sequence relative to the strand of the
matching database 16S/18S sequence, or NA if there is no match.

Column 4 is the number of local alignments between the sequence and
the best matching database 16S/18S sequence, or NA if there is no
match.

Column 5 is the query coverage percentage of the best alignment
between sequence and the best matching database 16S/1
8S sequence, or NA if there is no match.
```

Per-sequence errors are then determined based on the values in these 5
columns as shown in the table below:

| rRNA_sensor error    | associated GenBank error |  cause/explanation  |
|----------------------|--------------------------|---------------------|
|S_NoHits*             | SEQ_HOM_NotSSUOrLSUrRNA  | no hits reported ('no' in column 2) | 
|S_NoSimilarity*       | SEQ_HOM_LowSimilarity    | coverage (column 5) of best blast hit is < 10% |
|S_LowSimilarity*      | SEQ_HOM_LowSimilarity    | coverage (column 5) of best blast hit is < 80% (is seq len <= 350 nt) or < 86% (if seq len > 350 nt) |
|S_LowScore*           | SEQ_HOM_LowSimilarity    | either id percentage below length-dependent threshold (75%,80%,86%) or E-value above 1e-40 ('imperfect_match` in column 2) |
|S_BothStrands         | SEQ_HOM_MisAsBothStrands | hits on both strands ('mixed' in column 2) |
|S_MultipleHits        | SEQ_HOM_MultipleHits     | more than 1 hit reported (column 4 value > 1) |

Note that the first four rRNA_sensor errors (labelled with '*') do not trigger a GenBank error
 GenBank errors and are
    ignored by ribosensor if either (a) the
    sequence is 'RPSF' (passes ribotyper and fails rRNA\_sensor) and
    the {\tt -c} option is \emph{not} used with ribosensor.pl or (b)
    the sequence is 'RFSF' (fails both ribotyper and rRNA\_sensor) and
    R\_UnacceptableModel or R\_QuestionableModel ribotyper errors are
    also reported.}

passes or fails rRNA_sensor as follows:



As mentioned above, riboaligner runs ribotyper. The following two lines of the riboaligner output
indicate the output file and output directory of that ribotyper run:
```
# ribotyper output saved as test-ra/test-ra.riboaligner.ribotyper.out
# ribotyper output directory saved as test-ra/test-ra.riboaligner-rt
```

For each family/domain pair (e.g. SSU.Bacteria) all sequences that
were classified to that family/domain by ribotyper are further classified into different length classes by ribotyper.
For each length class, five files are created. These are listed in the output, for example:
```
# List file          for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.list
# Alignment          for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.stk
# Insert file        for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.ifile
# EL file            for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.elfile
# cmalign output     for      1 SSU.Bacteria full-ambig-more sequences saved in:   test-ra.riboaligner.SSU.Bacteria.full-ambig-more.cmalign
```

The 'list' file simply lists all files for this length class and
family/domain.  The alignment file is a
[Stockholm](https://en.wikipedia.org/wiki/Stockholm_format) format
alignment also described in http://eddylab.org/infernal/Userguide.pdf
(section 9: "File and output formats"). The Insert and EL files are
special output files from Infernal `cmalign` program each with
comments at the top of the file explaining its format.  Finally, the
cmalign output is the standard output from `cmalign` which is
explained in the [Infernal user
guide](http://eddylab.org/infernal/Userguide.pdf).

---

###<a name="modelinfo"></a> riboaligner modelinfo files

The default riboaligner modelinfo file is in `$RIBOSCRIPTSDIR/models/riboaligner.modelinfo`:

```
> cat $RIBOSCRIPTSDIR/models/riboaligner.modelinfo 
# each line has information on 1 family and has 4 or more tokens:
# token 1: Name of ribotyper classifications in short file for passing sequences that should be aligned with this model 
# token 2: CM file name for this family
# token 3: integer, consensus length for the CM for this family
# tokens 4 to N: model name(s) in the CM file, must also match 'model' name for
#                corresponding model in the ribotyper modelinfo file to be used
#
SSU.Bacteria          ra.SSU_rRNA_bacteria.edf.cm                   1533 SSU_rRNA_bacteria SSU_rRNA_cyanobacteria
SSU.Archaea           ra.SSU_rRNA_archaea.edf.cm                    1477 SSU_rRNA_archaea
SSU.Eukarya           ra.SSU_rRNA_eukarya.edf.cm                    1851 SSU_rRNA_eukarya
LSU.Archaea           ra.LSU_rRNA_archaea.edf.cm                    2990 LSU_rRNA_archaea
LSU.Bacteria          ra.LSU_rRNA_bacteria.edf.cm                   2925 LSU_rRNA_bacteria
SSU.Euk-Microsporidia ra.SSU_rRNA_microsporidia.edf.cm              1312 SSU_rRNA_microsporidia
LSU.Eukarya           ra.LSU_rRNA_eukarya.edf.cm                    3401 LSU_rRNA_eukarya 
SSU.Chloroplast       ra.SSU_rRNA_chloroplast.edf.cm                1488 SSU_rRNA_chloroplast SSU_rRNA_chloroplast_pilostyles
SSU.Mito-Metazoa      ra.SSU_rRNA_mitochondria_metazoa.edf.cm        955 SSU_rRNA_mitochondria_metazoa
SSU.Euk-Apicoplast    ra.SSU_rRNA_apicoplast.edf.cm                 1463 SSU_rRNA_apicoplast
SSU.Mito-Amoeba       ra.SSU_rRNA_mitochondria_amoeba.edf.cm        1956 SSU_rRNA_mitochondria_amoeba
SSU.Mito-Chlorophyta  ra.SSU_rRNA_mitochondria_chlorophyta.edf.cm   1376 SSU_rRNA_mitochondria_chlorophyta
SSU.Mito-Fungi        ra.SSU_rRNA_mitochondria_fungi.edf.cm         1589 SSU_rRNA_mitochondria_fungi
SSU.Mito-Kinetoplast  ra.SSU_rRNA_mitochondria_kinetoplast.edf.cm    624 SSU_rRNA_mitochondria_kinetoplast
SSU.Mito-Plant        ra.SSU_rRNA_mitochondria_plant.edf.cm         1951 SSU_rRNA_mitochondria_plant
SSU.Mito-Protist      ra.SSU_rRNA_mitochondria_protist.edf.cm       1669 SSU_rRNA_mitochondria_protist
```

The comment (`#`-prefixed) lines at the top of the file explain the
format.  The first token corresponds to a concatenation of columns 2
and 3 (`family` and `domain`) in the ribotyper modelinfo file, which
is the family and domain of each model. Sequences with output in the
`classification` column of ribotyper [output files with the suffix
`.short.out`](#ribotyper.md#short) that match the value in this first
token will be aligned to the CM in the file listed as the second token
of this riboaligner modelinfo file.

Any sequences in the riboaligner input sequence file that are
classified to any family/domain in ribotyper that is not listed in the
modelinfo file will not be aligned. The default riboaligner modelinfo
file includes all models from the ribotyper modelinfo file. You can
make your own riboaligner modelinfo files with fewer or different
family/domains and models than those listed in the default file.

For example, the file `$RIBOSCRIPTSDIR/models/riboaligner.ssu-arc-bac.modelinfo` only
includes information for SSU rRNA for bacteria and archaea:

```
> cat $RIBOSCRIPTSDIR/models/riboaligner.ssu-arc-bac.modelinfo 
# each line has information on 1 family and has 4 or more tokens:
# token 1: Name of ribotyper classifications in short file for passing sequences that should be aligned with this model 
# token 2: CM file name for this family
# token 3: integer, consensus length for the CM for this family
# tokens 4 to N: model name(s) in the CM file, must also match 'model' name for
#                corresponding model in the ribotyper modelinfo file to be used
#
SSU.Bacteria          ra.SSU_rRNA_bacteria.edf.cm                   1533 SSU_rRNA_bacteria SSU_rRNA_cyanobacteria
SSU.Archaea           ra.SSU_rRNA_archaea.edf.cm                    1477 SSU_rRNA_archaea
```

You can use this file with riboaligner with the `-i` option like this:
```
riboaligner -i $RIBOSCRIPTSDIR/models/riboaligner.ssu-arc-bac.modelinfo -f $RIBOSCRIPTSDIR/testfiles/example-ra-11.fa test-ra2
```







---

### <a name="options"></a>List of all command-line options

You can see all the available command line options to ribotyper by
calling it at the command line with the -h option:

```
> riboaligner -h
# riboaligner :: classify lengths of ribosomal RNA sequences
# Ribovore 1.0 (Jan 2021)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Wed Dec 23 13:30:57 2020
#
Usage: riboaligner [-options] <fasta file to annotate> <output file name root>

basic options:
  -f     : force; if <output directory> exists, overwrite it
  -b <n> : number of positions <n> to look for indels at the 5' and 3' boundaries [10]
  -v     : be verbose; output commands to stdout as they're run
  -n <n> : use <n> CPUs [1]
  -i <s> : use model info file <s> instead of default
  --keep : keep all intermediate files that are removed by default

options related to the internal call to ribotyper:
  --riboopts <s> : read command line options to supply to ribotyper from file <s>
  --noscfail     : do not fail sequences in ribotyper with low scores
  --nocovfail    : do not fail sequences in ribotyper with low coverage

options for parallelizing cmsearch and cmalign on a compute farm:
  -p         : parallelize ribotyper and cmalign on a compute farm
  -q <s>     : use qsub info file <s> instead of default
  -s <n>     : seed for random number generator is <n> [181]
  --nkb <n>  : number of KB of sequence for each farm job is <n> [100]
  --wait <n> : allow <n> wall-clock minutes for jobs on farm to finish, including queueing time [500]
  --errcheck : consider any farm stderr output as indicating a job failure

---

#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.
