# <a name="top"></a> `riboaligner` example usage, command-line options and length classes

* [`riboaligner` example usage](#exampleusage)
* [Length classes](#lengthclasses)
* [Example usage](#exampleusage)
* [`riboaligner` modelinfo files](#modelinfo)
* [List of all command-line options](#options)

---

`riboaligner` extends [`ribotyper`](ribotyper.md#top). It was designed
to help GenBank indexers evaluate whether rRNA sequences are partial,
full length, or extend past the rRNA gene boundaries. `riboaligner`
runs `ribotyper` and then aligns all the sequences that `ribotyper`
has determined as belonging to certain groups (by default SSU.archaea
and SSU.bacteria) and then determines the `length class` of each of
those sequences. Each 'group' is defined as the combination of a
`family` and `domain` from the [default `ribotyper` modelinfo
file](ribotyper.md#library).  The default set of family/domain pairs
can be changed using the `-i` option to specify an alternative
modelinfo file as demonstrated [below](#modelinfo). `riboaligner` also
creates multiple alignments of the input sequences; one alignment per
length class. [Example usage](#usage), [command-line
options](#options) and a [description of length
classes](#lengthclasses) are included below.

---

## <a name="lengthclasses"></a> Length classes determined by `riboaligner`

Each of the CMs and profile HMMs used by Ribovore have a predefined
set of reference positions, each of which corresponds to a position in
the *consensus* sequence for that model. When alignment of a sequence
to a CM or profile HMM has a gap in a reference model position
(reference model nucleotide aligned to a gap in the sequence being
aligned), this is called a *deletion*. When alignment of a sequence to
a CM or profile HMM has an extra nucleotide relative to the reference
model (gap in the reference model aligned to a nucleotide in the
sequence being aligned), this is called an *insertion*.  More
discussion of reference positions and insertions and deletions in CMs
can be found in the Background section of the [SSU-ALIGN user
guide](http://eddylab.org/software/ssu-align/Userguide.pdf).

There are 11 possible length classes defined by `riboaligner` based on
whether the alignment of each sequence extends to or past the first
and final model reference position as well as by how many insertion and
deletions occur in the first and final ten model reference
positions. 

The 11 length classes are:

* **partial**: does not extend to first model position or final model position
* **full-exact**: spans full model with zero insertions 5' of
  first model position and zero insertions 3' of the final
  model position and no insertions or deletions in the first or final 10 model positions
* **full-extra**: spans full model but has at least one insertion
  5' of the first model position and/or 3' of the final model position
* **full-ambig-more**: spans full model and has zero insertions 5' of
  the first model position but has insertions and/or deletions in the
  first and/or final 10 model positions and the insertions outnumber
  the deletions within those 10 model positions at the 5' and 3' ends.
* **full-ambig-less**: spans full model and zero insertions 5' of
  the first model position but has insertions and/or deletions in the
  first and/or final 10 model positions and the deletions are equal to or outnumber
  the insertions at the 5' and 3' ends. 
* **5flush-exact**: alignment extends to first but not final model
  position, and has zero insertions 5' of first model position
* **5flush-extra**: alignment extends to first but not final model
  position and has at least one insertion 5' of the first model position
* **5flush-ambig-more**: alignment extends to first but not final model
  position and has zero insertions 5' of the first model position but
  has insertions and/or deletions in the first 10 model positions and
  the insertions outnumber the deletions within those 10 model
  positions at the 5' end.
* **5flush-ambig-less**: alignment extends to first but not final model
  position and has zero insertions 5' of the first model position but
  has insertions and/or deletions in the first 10 model positions and
  the deletions are equal to or outnumber the insertions within those 10 model
  positions at the 5' end.
* **3flush-exact**: alignment extends to final but not first model
  position, and has zero insertions 3' of final model position
* **3flush-extra**: alignment extends to final but not first model
  position and has at least one insertion 3' of the final model position
* **3flush-ambig-more**: alignment extends to final but not first model
  position and has zero insertions 3' of the final model position but
  has insertions and/or deletions in the final 10 model positions and
  the insertions outnumber the deletions within those 10 model
  positions at the 3' end.
* **3flush-ambig-less**: alignment extends to final but not first model
  position and has zero insertions 3' of the final model position but
  has insertions and/or deletions in the final 10 model positions and
  the deletions are equal to or outnumber the insertions within those 10 model
  positions at the 3' end.

---

## `riboaligner` example usage <a name="exampleusage"></a>

This example runs the script `riboaligner` on a sample file of 11
sequences.

Move into a directory in which you have write permission and execute
the following command:

```
> riboaligner $RIBOSCRIPTSDIR/testfiles/example-ra-11.fa test-ra
```

Like other Ribovore scripts, `riboaligner` takes two required command
line arguments. Optional arguments are explained [below](#options).

The first required argument is the sequence file you want to annotate.
The $RIBOSCRIPTSDIR environment variable should be defined in your
`.bashrc` or `.cshrc` as explained in the [installation
documentation](install.md#environment).

The second required argument is the name of the output subdirectory
that you would like `riboaligner` to create. Output files will be placed
in this output directory. If this directory already exists, the
program will exit with an error message indicating that you need to
either (a) remove the directory before rerunning, or (b) use the -f
option, in which case the directory will be
overwritten.  The command adding `-f` is:

```
> riboaligner -f $RIBOSCRIPTSDIR/testfiles/example-ra-11.fa test-ra
```

You should see something like the following output:
```
# riboaligner :: classify lengths of ribosomal RNA sequences
# Ribovore 1.0 (Feb 2021)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:              Wed Dec 23 10:30:05 2020
# $RIBOEASELDIR:     /usr/local/src/ribovore-install/infernal/binaries
# $RIBOINFERNALDIR:  /usr/local/src/ribovore-install/infernal/binaries
# $RIBOSCRIPTSDIR:   /usr/local/src/ribovore-install/ribovore
#
# target sequence input file:  /Users/nawrockie/tmp/ribovore-install/ribovore/testfiles/example-ra-11.fa
# output directory name:       test-ra
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Validating input files                           ... done. [    0.0 seconds]
# Running ribotyper                                ... done. [    3.8 seconds]
# Running cmalign and classifying sequence lengths ... done. [    4.5 seconds]
# Extracting alignments for each length class      ... done. [    0.2 seconds]
#
# All input sequences passed ribotyper and were aligned.
#
# ribotyper output saved as test-ra/test-ra.riboaligner.ribotyper.out
# ribotyper output directory saved as test-ra/test-ra.riboaligner-rt
#
# Tabular output saved to file test-ra/test-ra.riboaligner.tbl
#
# List and description of all output files saved in:                               test-ra.riboaligner.list
# Output printed to screen saved in:                                               test-ra.riboaligner.log
# List of executed commands saved in:                                              test-ra.riboaligner.cmd
# insert file for SSU.Bacteria saved in:                                           test-ra.riboaligner.SSU.Bacteria.cmalign.ifile
# EL file for SSU.Bacteria saved in:                                               test-ra.riboaligner.SSU.Bacteria.cmalign.elfile
# stockholm alignment file for SSU.Bacteria saved in:                              test-ra.riboaligner.SSU.Bacteria.cmalign.stk
# cmalign output file for SSU.Bacteria saved in:                                   test-ra.riboaligner.SSU.Bacteria.cmalign.out
# insert file for SSU.Archaea saved in:                                            test-ra.riboaligner.SSU.Archaea.cmalign.ifile
# EL file for SSU.Archaea saved in:                                                test-ra.riboaligner.SSU.Archaea.cmalign.elfile
# stockholm alignment file for SSU.Archaea saved in:                               test-ra.riboaligner.SSU.Archaea.cmalign.stk
# cmalign output file for SSU.Archaea saved in:                                    test-ra.riboaligner.SSU.Archaea.cmalign.out
# insert file for SSU.Eukarya saved in:                                            test-ra.riboaligner.SSU.Eukarya.cmalign.ifile
# EL file for SSU.Eukarya saved in:                                                test-ra.riboaligner.SSU.Eukarya.cmalign.elfile
# stockholm alignment file for SSU.Eukarya saved in:                               test-ra.riboaligner.SSU.Eukarya.cmalign.stk
# cmalign output file for SSU.Eukarya saved in:                                    test-ra.riboaligner.SSU.Eukarya.cmalign.out
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
# List file          for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.list
# Alignment          for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.stk
# Insert file        for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.ifile
# EL file            for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.elfile
# cmalign output     for      8 SSU.Archaea  full-exact sequences saved in:        test-ra.riboaligner.SSU.Archaea.full-exact.cmalign
# List file          for      1 SSU.Eukarya  full-extra sequences saved in:        test-ra.riboaligner.SSU.Eukarya.full-extra.list
# Alignment          for      1 SSU.Eukarya  full-extra sequences saved in:        test-ra.riboaligner.SSU.Eukarya.full-extra.stk
# Insert file        for      1 SSU.Eukarya  full-extra sequences saved in:        test-ra.riboaligner.SSU.Eukarya.full-extra.ifile
# EL file            for      1 SSU.Eukarya  full-extra sequences saved in:        test-ra.riboaligner.SSU.Eukarya.full-extra.elfile
# cmalign output     for      1 SSU.Eukarya  full-extra sequences saved in:        test-ra.riboaligner.SSU.Eukarya.full-extra.cmalign
#
# All output files created in directory ./test-ra/
#
# Elapsed time:  00:00:08.43
#                hh:mm:ss
# 
[ok]
```

`riboaligner` outputs information on each step and how long it takes,
followed by a list of output files.

As mentioned above, `riboaligner` runs `ribotyper`. The following two lines of the `riboaligner` output
indicate the output file and output directory of that `ribotyper` run:
```
# ribotyper output saved as test-ra/test-ra.riboaligner.ribotyper.out
# ribotyper output directory saved as test-ra/test-ra.riboaligner-rt
```

For each family/domain pair (e.g. SSU.Bacteria) all sequences that
were classified to that family/domain by `ribotyper` are further classified into different length classes by `ribotyper`.
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

## <a name="modelinfo"></a> `riboaligner` modelinfo files

The default `riboaligner` modelinfo file is in `$RIBOSCRIPTSDIR/models/riboaligner.ssu-arc-bac.modelinfo`:

```
> cat $RIBOSCRIPTSDIR/models/riboaligner.ssu-arc-bac.modelinfo 
# each line has information on 1 family and has 4 or more tokens:
# token 1: Name of ribotyper classification <f>.<d> for family <f> (e.g. 'SSU') and domain <d> (e.g. Bacteria) in
#          ribotyper output short file for passing sequences that should be aligned with this model 
# token 2: CM file name for this family
# token 3: integer, consensus length for the CM for this family
# tokens 4 to N: model name(s) from the ribotyper modelinfo file (column 1 in that file)
#                corresponding to this ribotyper classification, these models should
#                be all (or a subset) of the models from the ribotyper modelinfo file
#                that have <f>.<d> (from token 1) for family and domain
#
SSU.Bacteria          ra.SSU_rRNA_bacteria.edf.cm                   1533 SSU_rRNA_bacteria SSU_rRNA_cyanobacteria
SSU.Archaea           ra.SSU_rRNA_archaea.edf.cm                    1477 SSU_rRNA_archaea
```

The comment (`#`-prefixed) lines at the top of the file explain the
format.  The first token corresponds to a concatenation of columns 2
and 3 (`family` and `domain`) in the `ribotyper` modelinfo file, which
is the family and domain of each model. Sequences with output in the
`classification` column of `ribotyper` [output files with the suffix
`.short.out`](#ribotyper.md#short) that match the value in this first
token will be aligned to the CM in the file listed as the second token
of this `riboaligner` modelinfo file.

Any sequences in the `riboaligner` input sequence file that are
classified to any family/domain in `ribotyper` that is not listed in the
modelinfo file will not be aligned. The default `riboaligner` modelinfo
file includes only SSU.Bacteria and SSU.archaea, so, for example eukaryotic
SSU sequences in the input sequence file will *not* be aligned.

Ribovore also includes `riboaligner.modelinfo`, a riboaligner
modelinfo file with all 15 family/domain pairs from the default
`ribotyper` modelinfo file. all models from the default `ribotyper`
modelinfo file. You can also make your own `riboaligner` modelinfo files
with fewer or different family/domains and models than those listed in
the these two modelinfo files.

The file `$RIBOSCRIPTSDIR/models/riboaligner.modelinfo` file is shown below:

```
> cat $RIBOSCRIPTSDIR/models/riboaligner.modelinfo 
# each line has information on 1 family and has 4 or more tokens:
# token 1: Name of ribotyper classification <f>.<d> for family <f> (e.g. 'SSU') and domain <d> (e.g. Bacteria) in
#          ribotyper output short file for passing sequences that should be aligned with this model 
# token 2: CM file name for this family
# token 3: integer, consensus length for the CM for this family
o# tokens 4 to N: model name(s) from the ribotyper modelinfo file (column 1 in that file)
#                corresponding to this ribotyper classification, these models should
#                be all (or a subset) of the models from the ribotyper modelinfo file
#                that have <f>.<d> (from token 1) for family and domain
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

You can use this file with `riboaligner` with the `-i` option like this:
```
riboaligner -i $RIBOSCRIPTSDIR/models/riboaligner.modelinfo -f $RIBOSCRIPTSDIR/testfiles/example-ra-11.fa test-ra2
```

---

## <a name="options"></a>List of all command-line options

You can see all the available command line options to ribotyper by
calling it at the command line with the -h option:

```
> riboaligner -h
# riboaligner :: classify lengths of ribosomal RNA sequences
# Ribovore 1.0.5 (Sep 2023)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Thu Sep 21 16:39:35 2023
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

options for modifying cmalign behavior:
  --glocal           : use -g with cmalign for glocal alignment mode
  --noflank          : do not use --flank* options to improve alns at ends
  --flanktoins <x>   : set transition probs to ROOT_IL/IR for cmalign to <x> [0.1]
  --flankselfins <x> : set self-transit probs in ROOT_IL/IR for cmalign to <x> [0.8]

options for parallelizing cmsearch and cmalign on a compute farm:
  -p         : parallelize ribotyper and cmalign on a compute farm
  -q <s>     : use qsub info file <s> instead of default
  -s <n>     : seed for random number generator is <n> [181]
  --nkb <n>  : number of KB of sequence for each farm job is <n> [100]
  --wait <n> : allow <n> wall-clock minutes for jobs on farm to finish, including queueing time [500]
  --errcheck : consider any farm stderr output as indicating a job failure
```

---

#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.
