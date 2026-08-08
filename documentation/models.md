# <a name="top"></a> Ribovore model information

* [Model naming convention](#naming)
* [Covariance model (CM) files that include a single CM and profile HMM](#table)
* [`ribotyper` versus `riboaligner` models](#versus)
* [`ribotyper.cm` a multi-model CM library file](#cmlibrary)
* [Getting model statistics using Infernal's `cmstat` program](#cmstat)
* [CRW database reference](#crwref)

---

## <a name="naming"></a>Model naming convention

Every model has a two-layer name: a machine-facing **model name** and a
human-facing **domain/family label**. Both layers name the same underlying
clade, just rendered differently.

**Layer 1 — model name** (`ribotyper.modelinfo`/`riboaligner.modelinfo`
column 1, the `.cm` file's internal `NAME` field, CM filenames, `.accept`
files, and the model-name lists in `models/scripts/*.sh`):

```
<MOL>_rRNA_<compartment>_<clade>          # organellar models
<MOL>_rRNA_<clade>                        # cytoplasmic/domain models (no compartment infix)
```
- `<MOL>` is `SSU` or `LSU`.
- `<compartment>` is `mito` for mitochondrial models — always lowercase,
  always abbreviated (not `mitochondria`). Chloroplast/apicoplast models are
  left bare (`SSU_rRNA_chloroplast`, `SSU_rRNA_apicoplast`, no `plastid_`
  infix): `chloroplast`/`apicoplast` are themselves already-recognized
  compartment identifiers, unlike `kinetoplast`, which stood in for a taxon.
- `<clade>` is the current NCBI-valid scientific taxon name, lowercase,
  matched to the model's actual seed composition at the tightest rank the
  seed genuinely supports.
- Residual/wastebasket models get an explicit `_other` suffix rather than
  reusing a bare clade word that is no longer taxonomically accurate (e.g.
  `mito_protist_other`, not a bare `mito_protist`).

**Layer 2 — domain/family label** (shown in `ribotyper`/`ribosensor` output,
`.accept` files, and `riboaligner.modelinfo` classification tokens):

```
<OriginPrefix>-<Clade>[-<Clade2>...]
```
- Hyphen-delimited, `TitleCase` per word, no camelCase, no underscores.
- `<OriginPrefix>` is `Mito` or `Plast` for organellar models; unprefixed
  only for the 3 true domain-rank cytoplasmic models (`Archaea`/`Bacteria`/
  `Eukarya`); `Euk-` is reserved for cytoplasmic/nuclear divergent-lineage
  models that are **not** organellar (currently only `Euk-Microsporidia`).
- `<Clade>` uses the same taxon-accuracy rule as Layer 1, in TitleCase.
- Double-hyphen compounds are used for genuinely compound/derived cases
  (e.g. `Plast-Chloroplast-Pilostyles`, `Mito-Protist-Other`).

---

## <a name="table"></a>Covariance model (CM) files that include a single CM and profile HMM

Ribovore includes 34 models: 21 SSU and 13 LSU. Seven derive from Rfam; the
rest were created or expanded during Ribovore development, several from CRW
database ([reference below](#crwref)) alignments. `nseq`/`eff_nseq`/`clen`/`W`
are from [`cmstat`](#cmstat) on the current `ribotyper.cm`; `ra.*.edf.cm`
column is `-` where no riboaligner (`edf`-filter) CM exists for that model.

### SSU models (21)

| model name | label | `rt.*` CM | `ra.*` CM | nseq | clen | Rfam accession |
|---|---|---|---|---|---|---|
| `SSU_rRNA_archaea` | Archaea | `rt.SSU_rRNA_archaea.enone.cm` | `ra.SSU_rRNA_archaea.edf.cm` | 86 | 1477 | RF01959 |
| `SSU_rRNA_bacteria` | Bacteria | `rt.SSU_rRNA_bacteria.enone.cm` | `ra.SSU_rRNA_bacteria.edf.cm` | 99 | 1533 | RF00177 |
| `SSU_rRNA_eukarya` | Eukarya | `rt.SSU_rRNA_eukarya.enone.cm` | `ra.SSU_rRNA_eukarya.edf.cm` | 91 | 1851 | RF01960 |
| `SSU_rRNA_microsporidia` | Euk-Microsporidia | `rt.SSU_rRNA_microsporidia.enone.cm` | `ra.SSU_rRNA_microsporidia.edf.cm` | 46 | 1312 | RF02542 |
| `SSU_rRNA_cyanobacteria` | Bacteria | `rt.SSU_rRNA_cyanobacteria.enone.cm` | `ra.SSU_rRNA_cyanobacteria.edf.cm` | 49 | 1487 | - |
| `SSU_rRNA_chloroplast` | Plast-Chloroplast | `rt.SSU_rRNA_chloroplast.enone.cm` | `ra.SSU_rRNA_chloroplast.edf.cm` | 94 | 1488 | - |
| `SSU_rRNA_apicoplast` | Plast-Apicoplast | `rt.SSU_rRNA_apicoplast.enone.cm` | `ra.SSU_rRNA_apicoplast.edf.cm` | 29 | 1463 | - |
| `SSU_rRNA_chloroplast_pilostyles` | Plast-Chloroplast-Pilostyles | `rt.SSU_rRNA_chloroplast_pilostyles.enone.cm` | `ra.SSU_rRNA_chloroplast_pilostyles.edf.cm` | 4 | 1531 | - |
| `SSU_rRNA_mito_metazoa` | Mito-Metazoa | `rt.SSU_rRNA_mito_metazoa.enone.cm` | `ra.SSU_rRNA_mito_metazoa.edf.cm` | 83 | 954 | - |
| `SSU_rRNA_mito_amoebozoa` | Mito-Amoebozoa | `rt.SSU_rRNA_mito_amoebozoa.enone.cm` | `ra.SSU_rRNA_mito_amoebozoa.edf.cm` | 16 | 1861 | - |
| `SSU_rRNA_mito_chlorophyta` | Mito-Chlorophyta | `rt.SSU_rRNA_mito_chlorophyta.enone.cm` | `ra.SSU_rRNA_mito_chlorophyta.edf.cm` | 47 | 1282 | - |
| `SSU_rRNA_mito_fungi` | Mito-Fungi | `rt.SSU_rRNA_mito_fungi.enone.cm` | `ra.SSU_rRNA_mito_fungi.edf.cm` | 90 | 1454 | - |
| `SSU_rRNA_mito_kinetoplastea` | Mito-Kinetoplastea | `rt.SSU_rRNA_mito_kinetoplastea.enone.cm` | `ra.SSU_rRNA_mito_kinetoplastea.edf.cm` | 17 | 624 | - |
| `SSU_rRNA_mito_embryophyta` | Mito-Embryophyta | `rt.SSU_rRNA_mito_embryophyta.enone.cm` | `ra.SSU_rRNA_mito_embryophyta.edf.cm` | 88 | 1649 | - |
| `SSU_rRNA_mito_ciliophora` | Mito-Ciliophora | `rt.SSU_rRNA_mito_ciliophora.enone.cm` | `ra.SSU_rRNA_mito_ciliophora.edf.cm` | 15 | 1669 | - |
| `SSU_rRNA_mito_bigyra` | Mito-Bigyra | `rt.SSU_rRNA_mito_bigyra.enone.cm` | `ra.SSU_rRNA_mito_bigyra.edf.cm` | 5 | 1662 | - |
| `SSU_rRNA_mito_oomycota` | Mito-Oomycota | `rt.SSU_rRNA_mito_oomycota.enone.cm` | `ra.SSU_rRNA_mito_oomycota.edf.cm` | 70 | 1503 | - |
| `SSU_rRNA_mito_cryptophyceae` | Mito-Cryptophyceae | `rt.SSU_rRNA_mito_cryptophyceae.enone.cm` | `ra.SSU_rRNA_mito_cryptophyceae.edf.cm` | 10 | 1483 | - |
| `SSU_rRNA_mito_choanoflagellata` | Mito-Choanoflagellata | `rt.SSU_rRNA_mito_choanoflagellata.enone.cm` | `ra.SSU_rRNA_mito_choanoflagellata.edf.cm` | 1 | 1596 | - |
| `SSU_rRNA_mito_protist_other` | Mito-Protist-Other | `rt.SSU_rRNA_mito_protist_other.enone.cm` | `ra.SSU_rRNA_mito_protist_other.edf.cm` | 88 | 1588 | - |
| `SSU_rRNA_mito_protostomia` | Mito-Protostomia | `rt.SSU_rRNA_mito_protostomia.enone.cm` | `ra.SSU_rRNA_mito_protostomia.edf.cm` | 90 | 711 | - |

> `SSU_rRNA_mito_jakobea` (`rt.SSU_rRNA_mito_jakobea.enone.cm` /
> `ra.SSU_rRNA_mito_jakobea.edf.cm`) is built and retained on disk in
> `models/` (for the Rfam submission / standalone jakobid-mito use), but is
> **excluded from the production `ribotyper`/`riboaligner` library** as of
> brief 26_0518-140: its bacterial-scaffolded CM proved promiscuous
> (false-flagged bacterial 16S fragments and near-noise sequences as
> Mito-Jakobea). Not counted in the 21 SSU above. Exclusion is reversible,
> pending a possible future re-inclusion.

### LSU models (13)

| model name | label | `rt.*` CM | nseq | clen | Rfam accession |
|---|---|---|---|---|---|
| `LSU_rRNA_archaea` | Archaea | `rt.LSU_rRNA_archaea.enone.cm` | 91 | 2990 | RF02540 |
| `LSU_rRNA_bacteria` | Bacteria | `rt.LSU_rRNA_bacteria.enone.cm` | 102 | 2925 | RF02541 |
| `LSU_rRNA_eukarya` | Eukarya | `rt.LSU_rRNA_eukarya.enone.cm` | 88 | 3401 | RF02543 |
| `LSU_rRNA_microsporidia` | Euk-Microsporidia | `rt.LSU_rRNA_microsporidia.cm` | 6 | 2593 | - |
| `LSU_rRNA_chloroplast` | Plast-Chloroplast | `rt.LSU_rRNA_chloroplast.cm` | 20 | 2929 | - |
| `LSU_rRNA_apicoplast` | Plast-Apicoplast | `rt.LSU_rRNA_apicoplast.cm` | 6 | 2701 | - |
| `LSU_rRNA_mito_vertebrata` | Mito-Vertebrata | `rt.LSU_rRNA_mito_vertebrata.cm` | 20 | 1570 | - |
| `LSU_rRNA_mito_bilateria` | Mito-Bilateria | `rt.LSU_rRNA_mito_bilateria.cm` | 11 | 1285 | - |
| `LSU_rRNA_mito_arthropoda` | Mito-Arthropoda | `rt.LSU_rRNA_mito_arthropoda.cm` | 5 | 1393 | - |
| `LSU_rRNA_mito_nematoda` | Mito-Nematoda | `rt.LSU_rRNA_mito_nematoda.cm` | 3 | 972 | - |
| `LSU_rRNA_mito_kinetoplastea` | Mito-Kinetoplastea | `rt.LSU_rRNA_mito_kinetoplastea.cm` | 4 | 1172 | - |
| `LSU_rRNA_mito_embryophyta` | Mito-Embryophyta | `rt.LSU_rRNA_mito_embryophyta.cm` | 2 | 2803 | - |
| `LSU_rRNA_mito_eukaryote` | Mito-Eukaryote | `rt.LSU_rRNA_mito_eukaryote.cm` | 9 | 2644 | - |

> `LSU_rRNA_mito_eukaryote` is a known wastebasket-shaped model (broad,
> unverified seed) that has deliberately **not** been renamed/split as of
> this table — a candidate for a future split similar to the SSU
> `mito_protist` -> `mito_protist_other` + 7-way split done here.

All CM files listed above are in the `ribovore/models` directory
(`$RIBOSCRIPTSDIR/models` following installation).

---

## <a name="versus"></a>`ribotyper` versus `riboaligner` models

The model files that begin with `rt.` contain `ribotyper` models and
those that begin with `ra.` contain `riboaligner` models. These models
were built differently. `ribotyper` models are built using the
`cmbuild` program from [Infernal](http://eddylab.org/infernal/)
with command line options `--p7ml --enone` (entropy weighting turned off,
profile HMM filter built to be maximally similar to the CM). `riboaligner`
models are built with `cmbuild`'s entropy weighting feature turned on
(the `edf` naming) and no `--p7ml`. These options were selected because
they increased classification accuracy (`ribotyper`) or alignment-endpoint
accuracy (`riboaligner`) in internal testing, respectively.

Every one of the 21 production SSU `ribotyper` models has a corresponding
`riboaligner.modelinfo` row (1-to-1 SSU coverage). `mito_jakobea` also has an
`edf`-filter CM built, but is excluded from the production library entirely
(no `ribotyper.modelinfo` or `riboaligner.modelinfo` row), per the note
above. No LSU model has a `riboaligner` counterpart.

---

## <a name="cmlibrary"></a> `ribotyper.cm` a multi-model CM library file

The `ribotyper.cm` file is a CM library of all models that begin with
`rt` in the tables [above](#table) (currently 34: 21 SSU + 13 LSU). This
file is used in the first stage of `ribotyper` to classify sequences.

---

## <a name="cmstat"></a> Getting model statistics using [Infernal](http://eddylab.org/infernal/)'s `cmstat` program

The program `cmstat` that is installed as part of the Infernal package
with Ribovore installation can be used to output information on the
model or models in a CM file. For example, below is the output of
`cmstat` on the current `ribotyper.cm` file:

```
> $RIBOINFERNALDIR/cmstat $RIBOINSTALLDIR/models/ribotyper.cm
# cmstat :: display summary statistics for CMs
# INFERNAL 1.1.5 (Sep 2023)
# Copyright (C) 2023 Howard Hughes Medical Institute.
# Freely distributed under the BSD open source license.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#                                                                                              rel entropy
#                                                                                             ------------
# idx   name                  accession      nseq  eff_nseq   clen      W   bps  bifs  model     cm    hmm
# ----  --------------------  ---------  --------  --------  -----  -----  ----  ----  -----  -----  -----
     1  LSU_rRNA_apicoplast   -                 6      6.00   2701   6327   721    63     cm  1.163  0.993
     2  LSU_rRNA_archaea      RF02540          91     91.00   2990   6270   786    68     cm  1.323  1.133
     3  LSU_rRNA_bacteria     RF02541         102    102.00   2925   5920   846    70     cm  1.352  1.153
     4  LSU_rRNA_chloroplast  -                20     20.00   2929   3526   812    68     cm  1.567  1.475
     5  LSU_rRNA_eukarya      RF02543          88     88.00   3401   8019   872    71     cm  1.122  0.994
     6  LSU_rRNA_microsporidia  -                 6      6.00   2593   2881   648    61     cm  1.268  1.132
     7  LSU_rRNA_mito_arthropoda  -                 5      5.00   1393   1477   305    32     cm  1.042  0.887
     8  LSU_rRNA_mito_bilateria  -                11     11.00   1285   1720   280    31     cm  0.846  0.680
     9  LSU_rRNA_mito_embryophyta  -                 2      2.00   2803   6947   706    63     cm  0.960  0.780
    10  LSU_rRNA_mito_eukaryote  -                 9      9.00   2644   3875   665    62     cm  0.972  0.768
    11  LSU_rRNA_mito_kinetoplastea  -                 4      4.00   1172   1202   160    16     cm  1.048  0.980
    12  LSU_rRNA_mito_nematoda  -                 3      3.00    972   1159   212    20     cm  0.791  0.622
    13  LSU_rRNA_mito_vertebrata  -                20     20.00   1570   1740   355    39     cm  1.315  1.223
    14  SSU_rRNA_apicoplast   -                29     29.00   1463   1987   398    28     cm  1.304  1.165
    15  SSU_rRNA_archaea      RF01959          86     86.00   1477   2998   457    30     cm  1.496  1.315
    16  SSU_rRNA_bacteria     RF00177          99     99.00   1533   1866   462    31     cm  1.415  1.231
    17  SSU_rRNA_chloroplast  -                94     94.00   1488   2288   446    31     cm  1.602  1.514
    18  SSU_rRNA_chloroplast_pilostyles  -                 4      4.00   1531   2621   440    30     cm  1.015  0.821
    19  SSU_rRNA_cyanobacteria  -                49     49.00   1487   1576   445    31     cm  1.748  1.668
    20  SSU_rRNA_eukarya      RF01960          91     91.00   1851   2879   447    30     cm  1.004  0.888
    21  SSU_rRNA_microsporidia  RF02542          46     46.00   1312   1974   366    26     cm  1.231  1.083
    22  SSU_rRNA_mito_amoebozoa  -                16     16.00   1861   2630   311    25     cm  1.096  1.006
    23  SSU_rRNA_mito_bigyra  -                 5      5.00   1662   2276   437    27     cm  1.070  0.897
    24  SSU_rRNA_mito_chlorophyta  -                47     47.00   1282   4536   223    19     cm  0.965  0.828
    25  SSU_rRNA_mito_choanoflagellata  -                 1      1.00   1596   1622   405    26     cm  0.668  0.436
    26  SSU_rRNA_mito_ciliophora  -                15     15.00   1669   1940   395    27     cm  1.075  0.935
    27  SSU_rRNA_mito_cryptophyceae  -                10     10.00   1483   1793   435    28     cm  1.279  1.125
    28  SSU_rRNA_mito_embryophyta  -                88     88.00   1649   7937   446    29     cm  1.632  1.575
    29  SSU_rRNA_mito_fungi   -                90     90.00   1454   9725   334    26     cm  1.038  0.860
    30  SSU_rRNA_mito_kinetoplastea  -                17     17.00    624   1154    68     5     cm  1.316  1.289
    31  SSU_rRNA_mito_metazoa  -                83     83.00    954   1406   254    20     cm  1.089  0.971
    32  SSU_rRNA_mito_oomycota  -                70     70.00   1503   2110   451    30     cm  1.821  1.791
    33  SSU_rRNA_mito_protist_other  -                88     88.00   1588   2266   232    20     cm  1.061  0.969
    34  SSU_rRNA_mito_protostomia  -                90     90.00    711   2033   191    13     cm  0.855  0.652
```

For more information on `cmstat` see the [Infernal user's guide](http://eddylab.org/infernal/Userguide.pdf)

---

## CRW database reference <a name="crwref"></a>

Cannone J.J., Subramanian S., Schnare M.N., Collett J.R., D'Souza L.M., Du Y., Feng B., Lin N., Madabusi L.V., MÜller K.M., Pande N., Shang Z., Yu N., and Gutell R.R. (2002). The Comparative RNA Web (CRW) Site: An Online Database of Comparative Sequence and Structure Information for Ribosomal, Intron, and Other RNAs. BioMed Central Bioinformatics, 3:2. [Correction: BioMed Central Bioinformatics. 3:15.]

---

#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.
