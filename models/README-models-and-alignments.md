# Ribovore model information <a name="top"></a>
#### Version 1.0; January 2021
#### https://github.com/ncbi/ribovore.git

### Sequence and structure-based ribosomal RNA alignments included with Ribovore 

Ribovore includes models built from 18 different alignments. 7 of
these derive from Rfam, and 11 were created during the course of
Ribovore development.

These alignments were created using 1 of 2 strategies:

'Build strategy 1': alignment and consensus secondary structure was
determined using 'Strategy 1' the CRW conversion strategy described in
the [SSU-ALIGN 0.1](http://eddylab.org/software/ssu-align/) user's
guide using tools/scripts available on
[GitHub](https://github.com/nawrockie/crw-conversion-tools). Sequences
in that alignment derive from the [CRW
website/database](http://www.rna.icmb.utexas.edu/) (reference [below](#crwref])).

'Build strategy 2' below means: initial version of the alignment and
consensus secondary structure and model was determined using 'Strategy
1', but that model was used to create a new alignment and model using
the Rfam model building pipeline as of version 12.0, to search the
Rfam database sequence database `Rfamseq` (a large database consisting
of much of the GenBank nucleotide database) to find hits and removing
highly similar sequences to get a more representative alignment than
the initial alignment.

As you can see in the table below, the 7 Rfam alignments and 3 of the
other alignments were created with build strategy 2. The other 7
alignments that used build strategy 1 have very few (< 5) sequences in
them and should and will be updated in future versions. Models built
from these 7 build strategy 1 alignments are less trustworthy and
generally less useful than the other models built from build strategy
2 alignments. 

---

## Covariance model (CM) files that include a single CM and profile HMM<a name="table"></a>

| alignment file name | alignment build strategy | model files built from alignment | \# seqs | model length | Rfam accession | Rfam DB release |
|---------------------|--------------------------|----------------------------------|---------|--------------|----------------|-----------------|
| `SSU_rRNA_archaea.RF01959.stk`          | 2 | `rt.SSU\_rRNA\_archaea.enone.cm`,                      `ra.SSU\_rRNA\_archaea.edf.cm`                     |      86 |       1477 | RF01959  | 12.2 |
| `SSU_rRNA_bacteria.RF00177.stk`         | 2 | `rt.SSU\_rRNA\_bacteria.enone.cm`,                     `ra.SSU\_rRNA\_bacteria.edf.cm`                    |      99 |       1533 | RF00177  | 12.2 |
| `SSU_rRNA_eukarya.RF01960.stk`          | 2 | `rt.SSU\_rRNA\_eukarya.enone.cm`,                      `ra.SSU\_rRNA\_eukarya.edf.cm`                     |      91 |       1851 | RF01960  | 12.2 |
| `SSU_rRNA_microsporidia.RF02542.stk`    | 2 | `rt.SSU\_rRNA\_microsporidia.enone.cm`,                `ra.SSU\_rRNA\_microsporidia.edf.cm`               |      46 |       1312 | RF02542  | 12.2 |
| `LSU_rRNA_archaea.RF02540.stk`          | 2 | `rt.LSU\_rRNA\_archaea.enone.cm`,                      `ra.LSU\_rRNA\_archaea.edf.cm`                     |      91 |       2990 | RF02540  | 12.2 |
| `LSU_rRNA_bacteria.RF02541.stk`         | 2 | `rt.LSU\_rRNA\_bacteria.enone.cm`,                     `ra.LSU\_rRNA\_bacteria.edf.cm`                    |     102 |       2925 | RF02541  | 12.2 |
| `LSU_rRNA_eukarya.RF02543.stk`          | 2 | `rt.LSU\_rRNA\_eukarya.enone.cm`,                      `ra.LSU\_rRNA\_eukarya.edf.cm`                     |      88 |       3401 | RF02543  | 12.2 |
| `SSU_rRNA_mitochondria_metazoa.stk`     | 2 | `rt.SSU\_rRNA\_mitochondria\_metazoa.enone.cm`,        `ra.SSU\_rRNA\_mitochondria\_metazoa.edf.cm`       |      83 |        954 |       -  |    - |
| `SSU_rRNA_mitochondria_amoeba.stk`      | 1 | `rt.SSU\_rRNA\_mitochondria\_amoeba.enone.cm`,         `ra.SSU\_rRNA\_mitochondria\_amoeba.edf.cm`        |       2 |       1861 |       -  |    - |
| `SSU_rRNA_mitochondria_chlorophyta.stk` | 1 | `rt.SSU\_rRNA\_mitochondria\_chlorophyta.enone.cm`,    `ra.SSU\_rRNA\_mitochondria\_chlorophyta.edf.cm`   |       2 |       1200 |       -  |    - |
| `SSU_rRNA_mitochondria_fungi.stk`       | 1 | `rt.SSU\_rRNA\_mitochondria\_fungi.enone.cm`,          `ra.SSU\_rRNA\_mitochondria\_fungi.edf.cm`         |       4 |       1603 |       -  |    - |
| `SSU_rRNA_mitochondria_kinetoplast.stk` | 1 | `rt.SSU\_rRNA\_mitochondria\_kinetoplast.enone.cm`,    `ra.SSU\_rRNA\_mitochondria\_kinetoplast.edf.cm`   |       3 |        624 |       -  |    - |
| `SSU_rRNA_mitochondria_plant.stk`       | 1 | `rt.SSU\_rRNA\_mitochondria\_plant.enone.cm`,          `ra.SSU\_rRNA\_mitochondria\_plant.edf.cm`         |       4 |       1951 |       -  |    - |
| `SSU_rRNA_mitochondria_protist.stk`     | 1 | `rt.SSU\_rRNA\_mitochondria\_protist.enone.cm`,        `ra.SSU\_rRNA\_mitochondria\_protist.edf.cm`       |       2 |       1677 |       -  |    - |
| `SSU_rRNA_chloroplast.stk`              | 2 | `rt.SSU\_rRNA\_chloroplast.enone.cm`,                  `ra.SSU\_rRNA\_chloroplast.edf.cm`                 |      94 |       1488 |       -  |    - |
| `SSU_rRNA_chloroplast_pilostyles.stk`   | 1 | `rt.SSU\_rRNA\_chloroplast\_pilostyles.enone.cm`,      `ra.SSU\_rRNA\_chloroplast\_pilostyles.edf.cm`     |       1 |       1531 |       -  |    - |
| `SSU_rRNA_cyanobacteria.stk`            | 2 | `rt.SSU\_rRNA\_cyanobacteria.enone.cm`,                `ra.SSU\_rRNA\_cyanobacteria.edf.cm`               |      49 |       1487 |       -  |    - |
| `SSU_rRNA_apicoplast.stk`               | 1 | `rt.SSU\_rRNA\_apicoplast.enone.cm`,                   `ra.SSU\_rRNA\_apicoplast.edf.cm`                  |       3 |       1463 |       -  |    - |

---

### ribotyper versus riboaligner models

The model files that begin with `rt.` contain ribotyper models and
those that begin with `ra.` contain riboaligner models.  These models
were built differently. All ribotyper models were built using the
`cmbuild` program from [Infernal](https://eddylab.org/infernal/)
version 1.1.3 with command line options `--p7ml --enone` using the
alignment files listed in the [table](#table) above. All riboaligner
models were built using the `cmbuild` program from
[Infernal](https://eddylab.org/infernal/) version 1.1.2 with default
parameters (no command line options) using the aligment files listed
in the [table](#table) above. The riboaligner models were built with
`cmbuild`'s entropy weighting feature that controls the average
entropy per model position~\cite{Karplus98,Nawrocki09b}, and the
ribotyper models were built with this feature turned off. Additionally
the ribotyper models were built such that the profile HMM used for
filtering was built to be maximally similar to the CM (the `--p7ml`
option). These options were selected because they increased
classification accuracy on our internal testing for ribotyper. Default
`cmbuild` built models are provided for riboaligner because those
models were more accurate on prediction alignment endpoints correctly
in our testing.

---

### `ribotyper.cm` a multi-model CM file

The `ribotyper.cm` file is a CM library of all models that begin with
`rt` in the above [table](#table). This file is used in the first
stage of ribotyper to classify sequences.

---

### Getting model statistics using Infernal's `cmstat` program

The program `cmstat` that is installed as part of the Infernal package
with Ribovore installation can be used to output information on the
model or models in CM file. For example, below is the output of
`cmstat` on the `ribotyper.cm` file:

```
> $RIBOINFERNALDIR/cmstat $RIBOINSTALLDIR/models/ribotyper.cm
# cmstat :: display summary statistics for CMs
# INFERNAL 1.1.4 (Dec 2020)
# Copyright (C) 2020 Howard Hughes Medical Institute.
# Freely distributed under the BSD open source license.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                                                                                                               rel entropy
#                                                                                                              ------------
# idx   name                                   accession      nseq  eff_nseq   clen      W   bps  bifs  model     cm    hmm
# ----  -------------------------------------  ---------  --------  --------  -----  -----  ----  ----  -----  -----  -----
     1  SSU_rRNA_archaea                       RF01959          86     86.00   1477   2998   457    30     cm  1.496  1.315
     2  SSU_rRNA_bacteria                      RF00177          99     99.00   1533   1866   462    31     cm  1.415  1.231
     3  SSU_rRNA_eukarya                       RF01960          91     91.00   1851   2879   447    30     cm  1.004  0.888
     4  SSU_rRNA_microsporidia                 RF02542          46     46.00   1312   1974   366    26     cm  1.231  1.083
     5  SSU_rRNA_chloroplast                   -                94     94.00   1488   2288   446    31     cm  1.602  1.514
     6  SSU_rRNA_mitochondria_metazoa          -                83     83.00    954   1406   254    20     cm  1.089  0.971
     7  SSU_rRNA_cyanobacteria                 -                49     49.00   1487   1576   445    31     cm  1.748  1.668
     8  LSU_rRNA_archaea                       RF02540          91     91.00   2990   6270   786    68     cm  1.323  1.133
     9  LSU_rRNA_bacteria                      RF02541         102    102.00   2925   5920   846    70     cm  1.352  1.153
    10  LSU_rRNA_eukarya                       RF02543          88     88.00   3401   8019   872    71     cm  1.122  0.994
    11  SSU_rRNA_apicoplast                    -                 3      3.00   1463   1685   398    28     cm  0.926  0.721
    12  SSU_rRNA_chloroplast_pilostyles        -                 1      1.00   1531   1557   440    30     cm  0.656  0.399
    13  SSU_rRNA_mitochondria_amoeba           -                 2      2.00   1861   2004   311    25     cm  0.725  0.593
    14  SSU_rRNA_mitochondria_chlorophyta      -                 2      2.00   1200   1549   224    19     cm  0.674  0.509
    15  SSU_rRNA_mitochondria_fungi            -                 4      4.00   1603   2455   334    26     cm  0.908  0.764
    16  SSU_rRNA_mitochondria_kinetoplast      -                 3      3.00    624    652    68     5     cm  0.978  0.910
    17  SSU_rRNA_mitochondria_plant            -                 4      4.00   1951   2211   446    29     cm  1.353  1.256
    18  SSU_rRNA_mitochondria_protist          -                 2      2.00   1677   2051   318    24     cm  0.732  0.582
```

For more information on `cmstat` see the [Infernal](https://eddylab.infernal.org) user guide.

---

### CRW Reference <a name="crwref"></a>
Cannone J.J., Subramanian S., Schnare M.N., Collett J.R., D'Souza L.M., Du Y., Feng B., Lin N., Madabusi L.V., MÜller K.M., Pande N., Shang Z., Yu N., and Gutell R.R. (2002). The Comparative RNA Web (CRW) Site: An Online Database of Comparative Sequence and Structure Information for Ribosomal, Intron, and Other RNAs. BioMed Central Bioinformatics, 3:2. [Correction: BioMed Central Bioinformatics. 3:15.]


#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.
                
