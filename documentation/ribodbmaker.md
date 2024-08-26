# <a name="top"></a> `ribodbmaker` example usage and command-line options

* [Limitations on Mac/OSX](#macosx)
* [Example usage on Linux](#exampleusagelinux)
* [Example usage on Mac/OSX](#exampleusagemacosx)
* [List of all command-line options](#options)
* [Fungal SSU/LSU rRNA model boundaries for candidate RefSeq dataset creation](#spans)
* [Special considerations for large input datasets](#large)
* [Creating an updated NCBI taxonomy tree file for `ribodbmaker`](#updatetaxonomy)
* [If `vecscreen` or `srcchk` commands fail](#execpaths)

---

`ribodbmaker` is designed to create high quality sequence datasets of
rRNA sequences by performing a series of tests or checks and only
sequences that survive all tests will pass `ribodbmaker` and be part of
the final dataset. These tests include runs of both [`ribotyper`](ribotyper.md#top) and 
[`riboaligner`](riboaligner.md#top).
The tests are customizable in that they can be skipped and
in many cases the pass/fail criteria for each test can be modified via
command-line options. The example usage section below demonstrates the
default set of tests performed by `ribodbmaker`.

---

##  <a name="macosx"></a> Limitations on Mac/OSX

One of the programs that `ribodbmaker` uses, `vecscreen_plus_taxonomy`, is
not available for Mac/OSX. `ribodbmaker` still runs on Mac/OSX but in a
limited capacity and specific command-line options are required. 
See the [example Mac/OSX usage below](#exampleusagemacosx) for more information.

---

## `ribodbmaker` example usage on Linux <a name="exampleusagelinux"></a>

This example runs `ribodbmaker` on a sample file of 10 fungal 18S SSU
rRNA sequences.

This command will only work if you've installed Ribovore on Linux
because the `vecscreen_plus_taxonomy` program is only installed for
Linux as it is not available for Mac/OSX. For example usage on Mac/OSX
see [below.](#exampleusagemacosx)

Move into a directory in which you have write permission and execute
the following command:

```
> ribodbmaker --model SSU.Eukarya fungi-ssu.r10.fa db10
```

Like other Ribovore scripts, `ribodbmaker` takes two required command
line arguments. Optional arguments are explained [below](#options).

The first required argument is the sequence file you want to annotate.
The $RIBOSCRIPTSDIR environment variable should be defined in your
`.bashrc` or `.cshrc` as explained in the [installation
documentation](install.md#environment).

The second required argument is the name of the output subdirectory
that you would like `ribodbmaker` to create. Output files will be placed
in this output directory. If this directory already exists, the
program will exit with an error message indicating that you need to
either (a) remove the directory before rerunning, or (b) use the -f
option, in which case the directory will be
overwritten.  The command adding `-f` is:

```
> ribodbmaker -f --model SSU.Eukarya fungi-ssu.r10.fa db10
```

The `--model SSU.Eukarya` part of the command informs `ribodbmaker`
that the goal of this run is to create a high quality dataset of
eukaryotic SSU rRNA sequences. Any sequences that do not match best to
a model in the SSU family and eukaryotic domain will fail.  This
classification is accomplished by the `ribotyper` program, and any
pair of values from columns 2 and 3 of the
[default model info file](ribotyper.md#library) can be used with the `--model` option.

`ribodbmaker` will proceed over several steps as indicated in its output:

```
# ribodbmaker :: create representative database of ribosomal RNA sequences
# Ribovore 1.0 (Jan 2020)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:             Tue Dec 29 17:15:11 2020
# $RIBOBLASTDIR:    /usr/local/src/ribovore-install/ncbi-blast/bin
# $RIBOEASELDIR:    /usr/local/src/ribovore-install/infernal/binaries
# $RIBOSCRIPTSDIR:  /usr/local/src/ribovore-install/ribovore
# $VECPLUSDIR:      /usr/local/src/ribovore-install/vecscreen_plus_taxonomy
# $VECSCREENDIR:    /usr/local/src/ribovore-install/vecscreen_plus_taxonomy/scripts
# $SRCCHKDIR:       /usr/local/src/ribovore-install/vecscreen_plus_taxonomy/scripts
#
# input sequence file:    /usr/local/src/ribovore-install/ribovore/testfiles/fungi-ssu.r10.fa
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

`ribodbmaker` outputs information on each stage as it progresses. The
first 5 lines are for the preliminary (`prelim`) stage prior to any of the test stages:
```
# [Stage: prelim] Validating input files                                            ... done. [    0.0 seconds]
# [Stage: prelim] Copying input fasta file                                          ... done. [    0.0 seconds]
# [Stage: prelim] Reformatting names of sequences                                   ... done. [    0.0 seconds]
# [Stage: prelim] Determining target sequence lengths                               ... done. [    0.1 seconds]
# [Stage: prelim] Running srcchk for all sequences                                  ... done. [   37.4 seconds]
```

After the preliminary stage, each filter stage is carried out and the number of 
sequences that pass and fail each stage is output to the screen. (Most of these
stages can be skipped using [command line options](#options).)

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
analyzed and so are only carried out on sequences that passed the
`riboaligner` stage (first part of the `fribo2` stage).

After the filter stages, any sequence that failed one or more filter
stages is excluded from further analysis. The remaining analysis is based on 
a multiple sequence alignment created by `riboaligner` and each sequence
is no longer analyzed independently. In this *ingroup analysis* (`Stage: ingrup`), 
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

Next, a model span survival table is created. This file may be useful
for users that are attempting to determine what model span to use for
filtering.  It includes comment (`#`-prefixed) lines explaining the
file format at the top of the page.  The model span is the minimum
required start and stop model positions that each aligned sequence
must satisfy. By default, these are positions 60 and L-59 where L is
the model length. They can be changed with the `--fmpos` or `--fmlpos`
and `--fmrpos` [command-line options](#options). For an example, see
the section below on [model-specific boundaries used for fungal rRNA
RefSeq creation](#spans). If you are not concerned about setting the
model span parameters, then you can ignore the model span survival
table.

Finally, the surviving sequences are clustered based on sequence identity given the alignment.
Again, with only 1 sequence this stage is irrelevant for this example but with larger 
datasets, some sequences will be removed in this stage. As with most of the stages,
the clustering stage can be skipped as explained below.

```
# [Stage: clustr] Clustering surviving sequences                                    ... done. [    0.0 seconds]
# [***Checkpoint] Creating lists of seqs that survived clustering                   ... done. [    0.0 seconds,      1 pass;      0 fail;]
#
```

After all stages are complete some summary statistics are output explaining how many 
sequences have survived and how many taxonomic groups are represented by those sequences:

```
# Number of input sequences:                                                 10  [listed in db10/db10.ribodbmaker.full.seqlist]
# Number surviving all filter stages:                                         1  [listed in db10/db10.ribodbmaker.surv_filters.pass.seqlist]
# Number surviving ingroup analysis:                                          1  [listed in db10/db10.ribodbmaker.surv_ingrup.pass.seqlist]
# Number surviving clustering (number of clusters):                           1  [listed in db10/db10.ribodbmaker.surv_clustr.pass.seqlist]
# Number in final set of surviving sequences:                                 1  [listed in db10/db10.ribodbmaker.final.pass.seqlist]
# Number of phyla   represented in final set of surviving sequences:          1  [listed in final line of db10/db10.ribodbmaker.phylum.ct]
# Number of classes represented in final set of surviving sequences:          1  [listed in final line of db10/db10.ribodbmaker.class.ct]
# Number of orders  represented in final set of surviving sequences:          1  [listed in final line of db10/db10.ribodbmaker.order.ct]
```

And a list of output files with brief descriptions is output, note
that these have all been created in a new directory `db10/`:

```
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
```

To see a list of all output files see the `db10/db10.ribodbmaker.list` file.
To keep all intermediate files, many of which are normally deleted, use the `--keep` option.

---

## <a name="exampleusagemacosx"></a> Example usage on Mac/OSX

As mentioned above, `ribodbmaker` can only be run using special
command-line options on Mac/OSX because the `vecscreen_plus_taxonomy`
program is not available for Mac/OSX. Specifically, the options
`--skipftaxid`, `--skipfvecsc`, `--skipingrup` and `--skipfmstbl` must
be used to skip the taxid, vecscreen, and ingroup stages, all of which
require executables from the `vecscreen_plus_taxonomy` package.

Execute the following command to perform an example run on Mac/OSX that uses these options:

```
> ribodbmaker -f --model SSU.Eukarya --skipftaxid --skipfvecsc --skipingrup --skipmstbl $RIBOSCRIPTSDIR/testfiles/fungi-ssu.r10.fa db10novec 
```

The output is similar to that above for the Linux example run but
with the taxid, vecscreen and ingroup stages skipped. See the [Linux
example run](#exampleusagelinux) above for more details.

---

## <a name="options"></a>List of all command-line options

You can see all the available command line options to `ribodbmaker` by
calling it at the command line with the -h option, as shown below.

There are many options, and they are split by category. Categories include:

* basic options

* options for skipping stages

* options for excluding seqs based on taxid pre-clustering, but after filter and ingroup stages

* options for controlling the stage that filters based on ambiguous nucleotides

* options for controlling the stage that filters by taxid

* options for controlling the stage that filters based on self-BLAST hits

* options for controlling both ribotyper/riboaligner stages

* options for controlling the first stage that filters based on ribotyper

* options for controlling the second stage that filters based on ribotyper/riboaligner

* options for controlling the stage that filters based on model span of hits

* options for controlling clustering stage

* options that affect the alignment from which percent identities are calculated

* options for reducing the number of passing sequences per taxid

* options for modifying the ingroup stage

* options for controlling model span survival table output file

* options for changing sequence descriptions (deflines)

* options for controlling maximum number of sequences to calculate percent identities for

* options for parallelizing ribotyper/riboaligner's calls to cmsearch and cmalign on a compute farm

* advanced options for debugging and testing

```
> ribodbmaker -h
# ribodbmaker :: create representative database of ribosomal RNA sequences
# Ribovore 1.0 (Feb 2021)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Wed Dec 30 10:52:23 2020
#
Usage: ribodbmaker [-options] <input fasta sequence file> <output directory>

basic options:
  -f            : force; if <output directory> exists, overwrite it
  -v            : be verbose; output commands to stdout as they're run
  -n <n>        : use <n> CPUs [1]
  --keep        : keep all intermediate files that are removed by default
  --special <s> : read list of special species taxids from <s>
  --taxin <s>   : use taxonomy tree file <s> instead of default

options for skipping stages:
  --skipfambig : skip stage that filters based on ambiguous nucleotides
  --skipftaxid : skip stage that filters by taxid
  --skipfvecsc : skip stage that filters based on VecScreen
  --skipfblast : skip stage that filters based on BLAST hits to self
  --skipfribo1 : skip 1st stage that filters based on ribotyper
  --skipfribo2 : skip 2nd stage that filters based on ribotyper/riboaligner
  --skipfmspan : skip stage that filters based on model span of hits
  --skipingrup : skip stage that performs ingroup analysis
  --skipclustr : skip stage that clusters sequences surviving all filters
  --skiplistms : skip stage that lists missing taxids
  --skipmstbl  : skip stage that outputs model span tables

options for excluding seqs based on taxid pre-clustering, but after filter and ingroup stages:
  --exclist <s> : exclude any seq w/a seq taxid listed in file <s>, post-filters/ingroup

options for controlling the stage that filters based on ambiguous nucleotides:
  --famaxn <n> : set maximum number of allowed ambiguous nts to <n> [5]
  --famaxf <x> : set maximum fraction of allowed ambiguous nts to <x> [0.005]
  --faonlyn    : enforce only max number of ambiguous nts
  --faonlyf    : enforce only max fraction of ambiguous nts

options for controlling the stage that filters by taxid:
  --ftstrict : require all taxids for sequences exist in input NCBI taxonomy tree

options for controlling the stage that filters based on self-BLAST hits:
  --fbcsize <n>    : set num seqs for each BLAST run to <n> [20]
  --fbcall         : do single BLAST run with all N seqs (CAUTION: slow for large N)
  --fbword <n>     : set word_size for BLAST to <n> [20]
  --fbevalue <x>   : set BLAST E-value cutoff to <x> [1]
  --fbdbsize <n>   : set BLAST dbsize value to <n> [200000000]
  --fbnominus      : do not consider BLAST self hits to minus strand
  --fbmdiagok      : consider on-diagonal BLAST self hits to minus strand
  --fbminuslen <n> : minimum length of BLAST self hit to minus strand is <n> [50]
  --fbminuspid <x> : minimum percent id of BLAST self hit to minus strand is <x> [95]

options for controlling both ribotyper/riboaligner stages:
  --model <s>     : model to use is <s> (e.g. SSU.Eukarya)
  --noscfail      : do not fail sequences in ribotyper with low scores
  --lowppossc <x> : set --lowppossc <x> option for ribotyper to <x> [0.5]

options for controlling the first stage that filters based on ribotyper:
  --riboopts1 <s> : use ribotyper options listed in <s>
  --ribodir1 <s>  : use pre-computed ribotyper dir <s>

options for controlling the second stage that filters based on ribotyper/riboaligner:
  --rainfo <s>       : use riboaligner model info file <s> instead of default
  --nomultfail       : do not fail sequences in ribotyper with multiple hits
  --nocovfail        : do not fail sequences in ribotyper with low coverage
  --nodifffail       : do not fail sequences in ribotyper with low score difference
  --tcov <x>         : set --tcov <x> option for ribotyper to <x> [0.99]
  --ribo2hmm         : run ribotyper stage 2 in HMM-only mode (do not use --2slow)
  --riboopts2 <s>    : use ribotyper options listed in <s>
  --ribodir2 <s>     : use pre-computed riboaligner dir <s>
  --max5pins <n>     : FAIL seqs with > <n> inserts before first model position
  --max3pins <n>     : FAIL seqs with > <n> inserts after final model position
  --passlenclass <s> : PASS seqs in riboaligner length classes in comma separated string <s>
  --faillenclass <s> : FAIL seqs in riboaligner length classes in comma separated string <s>

options for controlling the stage that filters based on model span of hits:
  --fmpos <n>  : aligned sequences must span from <n> to L - <n> + 1 for model of length L [60]
  --fmlpos <n> : aligned sequences must begin at or 5' of position <n>
  --fmrpos <n> : aligned sequences must end at or 3' of position <n>
  --fmnogap    : require sequences do not have a gap at lpos and rpos

options for controlling clustering stage:
  --cfid <x>     : set esl-cluster fractional identity to cluster at to <x> [0.995]
  --cdthresh <x> : representative is longest seq within <x> distance of min distance seq [0.0025]
  --cmaxlen      : representative is longest seq within cluster
  --ccentroid    : representative is centroid (min distance seq)

options that affect the alignment from which percent identities are calculated:
  --fullaln     : do not trim alignment to minimum required span before pid calculations
  --noprob      : do not trim alignment based on post probs before pid calculations
  --pthresh <x> : posterior probability threshold for alnment trimming is <x> [0.95]
  --pfract <x>  : seq fraction threshold for post prob alnment trimming is <x> [0.95]

options for reducing the number of passing sequences per taxid:
  --fione        : only allow 1 sequence per (species) taxid to survive ingroup filter
  --fimin <n>    : w/--fione, remove all sequences from species with < <n> sequences [1]
  --figroup      : w/--fione, keep winner (len/avg pid) in group (order,class,phyla), not in taxid
  --fithresh <x> : w/--fione, winning seq is longest seq within <x> percent id of max percent id [0.2]

options for modifying the ingroup stage:
  --indiffseqtax   : only consider sequences from different seq taxids when computing averages and maxes
  --inminavgid <x> : fail any sequence with average percent identity within species taxid below <x> [99.8]
  --innominavgid   : do not fail sequences with avg percent identity within species taxid below a minimum

options for controlling model span survival table output file:
  --msstep <n>     : for model span output table, set step size to <n> [10]
  --msminlen <n>   : for model span output table, set min length span to <n> [200]
  --msminstart <n> : for model span output table, set min start position to <n>
  --msmaxstart <n> : for model span output table, set max start position to <n>
  --msminstop <n>  : for model span output table, set min stop position to <n>
  --msmaxstop <n>  : for model span output table, set max stop position to <n>
  --mslist <s>     : re-sort model span table to prioritize taxids (orders) in file <s>
  --msclass        : w/--mslist, taxids in --mslist file are classes not orders
  --msphylum       : w/--mslist, taxids in --mslist file are phyla not orders

options for changing sequence descriptions (deflines):
  --def : standardize sequence descriptions/deflines

options for controlling maximum number of sequences to calculate percent identities for:
  --pidmax <n> : set maximum number of seqs to compute percent identities for to <n> [40000]
  --pidforce   : force calculation of percent identities for any number of sequences

options for parallelizing ribotyper/riboaligner's calls to cmsearch and cmalign on a compute farm:
  -p         : parallelize ribotyper and riboaligner on a compute farm
  -q <s>     : use qsub info file <s> instead of default
  -s <n>     : seed for random number generator is <n> [181]
  --nkb <n>  : number of KB of sequence for each farm job is <n> [100]
  --wait <n> : allow <n> wall-clock minutes for jobs on farm to finish, including queueing time [1440]
  --errcheck : consider any farm stderr output as indicating a job failure

advanced options for debugging and testing:
  --prvcmd     : do not execute commands; use output from previous run
  --pcreclustr : w/--prvcmd, recluster seqs (--cfid) and/or rechoose representatives (--cdthresh or --cmaxlen)
```

---

## <a name="spans"></a>Fungal SSU/LSU rRNA model boundaries for candidate RefSeq dataset creation

`ribodbmaker` has been used by NCBI to create datasets of candidate
fungal SSU and LSU rRNA sequences. Because studies that target fungal
SSU rRNA frequently attempt to obtain sequences spanning most of the V4
and part of the V5 variable regions, and sometimes only these regions,
`ribodbmaker` is used with the `--fmlpos 604 --fmrpos 1070` options
because the eukaryotic SSU (Rfam RF01960) model positions 604 to 1070 span
those regions. Similarly, for fungal LSU the D1 and D2 variable regions
are frequently targetted and so `--fmlpos 124 --fmrpos 627` are used.

The full commands used for fungal SSU and LSU rRNA candidate RefSeq dataset creation are:

SSU:
```
ribodbmaker --fione --fmnogap --fmlpos 604 --fmrpos 1070 -f --model SSU.Eukarya --skipclustr <fasta> <outdir>
```

LSU:
```
ribodbmaker --fione --fmnogap --fmlpos 124 --fmrpos 627 -f --model LSU.Eukarya --skipclustr <fasta> <outdir>
```

---

## <a name="large"></a>Special considerations for large datasets

The running time of the ingroup and clustering stages scale with the
square of the number of input sequences, and as a result `ribodbmaker` may be
very slow for datasets with more than 25,000 sequences.

One way around this is to perform two runs of `ribodbmaker` on an input sequence dataset `S`.
In the first run, skip the ingroup and clustering stages with the
`--skipingrup` and `--skipclustr` options. Then for the second run change the input sequence
dataset to only those sequences from `S` that survived the first run, call this set `S'`.
For this second run, do not use the
`--skipingrup` and `--skipclustr` options. If `S'` has significantly fewer sequences than `S`
then this two-step approach may be significantly faster, and will result in the same
final dataset of surviving sequences from the second run that you would have obtained from just a
single run using all stages (no command-line `--skip` options) on `S`.

Further, if there are multiple CPUs available, then you can speed-up
the suggested first run can by splitting the input FASTA file into
multiple disjoint files, and running `ribodbmaker` on each subfile
separately and in parallel. Then, you can concatenate all the passing
sequences from the separate runs into one input file for the second
run. This parallel approach is valid because if the options
`--skipingrup` and `--skipcluster` are used, the outcome of whether a
sequence passes or fails depends only on that sequence and not on any
other sequences in the input sequence file.

---

## <a name="updatetaxonomy"></a>Creating an updated NCBI taxonomy tree file for `ribodbmaker`

Ribovore includes a special formatted version of the NCBI taxonomy tree in the file:

```
ribovore/taxonomy/ncbi-taxonomy-tree.ribodbmaker.txt
```

This tree was created using the procedure described below on September 21, 2023.

You can update your local copy of this tree by following the steps below. If you are on Mac/OSX, you'll need to first
download `vecscreen_plus_taxonomy` with the following commands:
```
curl -k -L -o vecscreen_plus_taxonomy-ribovore-1.0.5.zip https://github.com/aaschaffer/vecscreen_plus_taxonomy/archive/ribovore-1.0.5.zip; 
unzip vecscreen_plus_taxonomy-ribovore-1.0.5.zip; 
mv vecscreen_plus_taxonomy-ribovore-1.0.5 vecscreen_plus_taxonomy
rm vecscreen_plus_taxonomy-ribovore-1.0.5.zip
```

And then modify the `$VECPLUSDIR` and `$PERL5LIB` environment variables in your `.bashrc` file as follows:
```
export VECPLUSDIR="/path/to/vecscreen_plus_taxonomy"
export PERL5LIB="$VECPLUSDIR":"$PERL5LIB"
```
or in your `.cshrc` file:
```
setenv VECPLUSDIR "/path/to/vecscreen_plus_taxonomy"
setenv PERL5LIB "$VECPLUSDIR":"$PERL5LIB"
```

***If you are on Linux, `vecscreen_plus_taxonomy` will have already been
installed with Ribovore but you will still need to modify your `$PERL5LIB`
environment variable using the second `export` or `setenv` line above in
your `.bashrc` or `.cshrc` files.***

Then you'll need to source your `.bashrc` or `.cshrc` files with the command:

```
source ~/.bashrc
```

or

```
source ~/.cshrc
```

---

Steps to create an updated NCBI taxonomy tree file:

1. Move into a newly created directory - these steps will generate about a dozen files in that new directory.

2. Download `new_taxdump.tar.gz` from [https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/)

```
curl -k -L -o new_taxdump.tar.gz  https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz
```

3. Execute the following commands:

```
tar xfz new_taxdump.tar.gz
cut -f1,3,5 nodes.dmp > taxonomy_tree.txt
cut -f31 nodes.dmp > specified_column.txt
```

4. Run the `assign_levels_to_taxonomy.pl` script from
`vecscreen_plus_taxonomy`. If you have installed Ribovore on Linux, do
this by executing the following command:

```
$VECPLUSDIR/scripts/assign_levels_to_taxonomy.pl --input_taxa taxonomy_tree.txt --outfile taxonomy_tree_wlevels.txt
```

5. Create the final file with the command:

```
paste taxonomy_tree_wlevels.txt specified_column.txt > updated-ncbi-taxonomy-tree.ribodbmaker.txt
```

6. Use the new taxonomy tree file you created with `ribodbmaker` using the `--taxin /path/to/updated-ncbi-taxonomy-tree.ribodbmaker.txt`.

---

## <a name="execpaths"></a>If `vecscreen` or `srcchk` commands fail: changing paths to `vecscreen` and `srcchk` executables

The Ribovore installation (on Linux systems) script installs the [`vecscreen_plus_taxonomy`](https://github.com/aaschaffer/vecscreen_plus_taxonomy) software package which includes binary executable programs `vecscreen` and `srcchk`. It is possible that those binaries will not run on your machine. If you see an error like his:

```
ERROR in utl_RunCommand(), the following command failed:                                                                                                                                                                         

/usr/local/src/ribovore-install/ribovore/vecscreen_plus_taxonomy/scripts/srcchk -i outdir/outdir.ribodbmaker.full.seqlist -f 'taxid,organism,strain' > outdir/outdir ribodbmaker.full.srcchk
```

Or a similar one indicating that a `vecscreen` command failed, then it may be that the binaries do not work on your machine. If this happens, if you are able to download the NCBI C++ toolkit following instructions[here](https://ncbi.github.io/cxx-toolkit/pages/release_notes#release_notes.Download), you can change two environment variables to point to the location of the new `vecscreen` and `srcchk` executable files with commands like:

```
export VECSCREENDIR="/path/to/vecscreen"
export SRCCHKDIR="/path/to/srcchk"
```
if you use bash or zsh, or 
```
setenv VECSCREENDIR "/path/to/vecscreen"
setenv SRCCHKDIR "/path/to/srcchk"
```
if you use C shell.

(You may want to put these commands in your `.bashrc`, `.zshrc` or `.cshrc` file.) After redefining the `VECSCREENDIR` and `SRCCHKDIR` directories to point to the new binary directories, retry the `ribodbmaker` command that failed.

---

#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.
