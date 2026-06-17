# LSU iteration models — archive manifest

**Status: INTERMEDIATE ITERATION MODELS — NOT A RELEASE.**

These are the LSU rRNA models from the current model-iteration phase of the
ribosensor LSU/SSU expansion project. They are preserved here so the exact
models used to search RefSeq genomes (to discover the sequences that will seed
the **next** seed iteration) are recoverable later. **Calibration of the final
models is deferred** — the `edf` models archived here are *uncalibrated* (see
briefs 040/039). The classification/search `enone` models in `models/` on this
branch are calibrated.

## Provenance

- **Project:** `/net/intdev/oblast01/infernal/notebook/26_0518_ribo_sensor_expansion`
- **Archive branch:** `lsu-iteration-archive-impl`
- **Base commit:** `befb9a4` — *"ribosensor: add first-gen 16S_LSU/23S_LSU/28S/12S modes"*
  (tip of `lsu-integration-v5-impl`, the v5 Phase-4 commit).
- **Briefs:** 038 (v5 build / enone organellar models), 039 (LSU extraction
  pipeline), 040 (edf LSU models), 041 (this archive).
- **Build binary:** Infernal 1.1.5 `cmbuild` (`/home/nawrocke/src/infernal-1.1.5/src/cmbuild`).

## Layout of this archive (`lsu-iteration-models/`)

```
edf/                       10 uncalibrated edf-flavor LSU CMs (cmbuild -F --fraggiven)
seeds/                     10 fragmentized seed alignments the models were built from
extraction-pipeline/       copy of brief 039/040 lsu-extraction tooling
  extract_lsu.sh             raw-Infernal driver (enone/calibrated CMs)
  extract_lsu_edf.sh         edf-flavor driver (brief 040)
  cand-cms/                  prebuilt candidate CMs for extraction (ch/cy/mf/mm + ssu_metazoa)
  README.md                  pipeline documentation (brief 039)
MANIFEST.md                this file
```

The **enone organellar LSU classification models are NOT duplicated here** — they
are already committed on this branch in `models/` (and in the 28-model
`models/ribotyper.cm` library). Referenced below by path.

## Model table (10 organellar LSU clades)

Each clade has two model flavors built from the **same seed**:
- **enone** (`models/rt.LSU_rRNA_<clade>.cm`, this branch) — ribotyper
  classification flavor, `cmbuild -F --p7ml --enone --fraggiven`, **calibrated**.
- **edf** (`edf/ra.LSU_rRNA_<clade>.edf.cm`, this archive) — riboaligner
  alignment flavor, `cmbuild -F --fraggiven` (default entropy weighting),
  **uncalibrated**.

`clen` and `nseq` are identical across both flavors (same seed); listed once.

| clade | nseq | clen | enone (models/, calibrated) | edf (edf/, uncalibrated) | seed |
|---|---:|---:|---|---|---|
| apicoplast       | 6  | 2701 | `models/rt.LSU_rRNA_apicoplast.cm`       | `edf/ra.LSU_rRNA_apicoplast.edf.cm`       | `seeds/LSU_rRNA_apicoplast.seed.stk`       |
| chloroplast      | 20 | 2929 | `models/rt.LSU_rRNA_chloroplast.cm`      | `edf/ra.LSU_rRNA_chloroplast.edf.cm`      | `seeds/LSU_rRNA_chloroplast.seed.stk`      |
| microsporidia    | 6  | 2593 | `models/rt.LSU_rRNA_microsporidia.cm`    | `edf/ra.LSU_rRNA_microsporidia.edf.cm`    | `seeds/LSU_rRNA_microsporidia.seed.stk`    |
| mito_arthropod   | 5  | 1393 | `models/rt.LSU_rRNA_mito_arthropod.cm`   | `edf/ra.LSU_rRNA_mito_arthropod.edf.cm`   | `seeds/LSU_rRNA_mito_arthropod.seed.stk`   |
| mito_bilateria   | 11 | 1285 | `models/rt.LSU_rRNA_mito_bilateria.cm`   | `edf/ra.LSU_rRNA_mito_bilateria.edf.cm`   | `seeds/LSU_rRNA_mito_bilateria.seed.stk`   |
| mito_eukaryote   | 9  | 2644 | `models/rt.LSU_rRNA_mito_eukaryote.cm`   | `edf/ra.LSU_rRNA_mito_eukaryote.edf.cm`   | `seeds/LSU_rRNA_mito_eukaryote.seed.stk`   |
| mito_kinetoplast | 4  | 1172 | `models/rt.LSU_rRNA_mito_kinetoplast.cm` | `edf/ra.LSU_rRNA_mito_kinetoplast.edf.cm` | `seeds/LSU_rRNA_mito_kinetoplast.seed.stk` |
| mito_nematode    | 3  | 972  | `models/rt.LSU_rRNA_mito_nematode.cm`    | `edf/ra.LSU_rRNA_mito_nematode.edf.cm`    | `seeds/LSU_rRNA_mito_nematode.seed.stk`    |
| mito_plant       | 2  | 2803 | `models/rt.LSU_rRNA_mito_plant.cm`       | `edf/ra.LSU_rRNA_mito_plant.edf.cm`       | `seeds/LSU_rRNA_mito_plant.seed.stk`       |
| mito_vertebrate  | 20 | 1570 | `models/rt.LSU_rRNA_mito_vertebrate.cm`  | `edf/ra.LSU_rRNA_mito_vertebrate.edf.cm`  | `seeds/LSU_rRNA_mito_vertebrate.seed.stk`  |

## Build `COM` lines (from CM headers)

### edf flavor (this archive) — `cmbuild -F --fraggiven`
All 10 share the identical recipe (paths relative to the project dir):
```
cmbuild -F --fraggiven -n LSU_rRNA_<clade> \
  cm-build/edf-lsu/ra.LSU_rRNA_<clade>.edf.cm \
  ribovore-LSU-modes-for-aaron-2026-06-15/seeds/LSU_rRNA_<clade>.seed.stk
```

### enone flavor (models/, this branch) — `cmbuild -F --p7ml --enone --fraggiven`
Built earlier (brief 038) from per-clade expanded/refragmentized seeds; exact
input paths vary by clade. Representative header lines:
```
apicoplast:    cmbuild -F --p7ml --enone --fraggiven cm-build/CM_apicoplast/expanded6/CM_apicoplast.p7ml.cm cm-build/CM_apicoplast/expanded6/combined.frag.stk
chloroplast:   cmbuild -F --p7ml --enone --fraggiven .../CM_plastid.outdir/CM_plastid.nosymfrac.cm .../CM_plastid.refrag.stk
microsporidia: cmbuild -F -n LSU_rRNA_microsporidia --p7ml --enone --fraggiven CM_microsporidia.cm seed.frag.stk
mito_arthropod:.../CM3_arthropod.outdir/CM3_arthropod.{nosymfrac.cm,refrag.stk}
mito_bilateria:.../CM2_bilaterian-invert.outdir/CM2_bilaterian-invert.{nosymfrac.cm,refrag.stk}
mito_eukaryote:.../CM4_eukaryote-core.outdir/CM4_eukaryote-core.{nosymfrac.cm,refrag.stk}
mito_kinetoplast:.../CM7_kinetoplastid.outdir/CM7_kinetoplastid.{nosymfrac.cm,refrag.stk}
mito_nematode: .../CM6_nematode.outdir/CM6_nematode.{nosymfrac.cm,refrag.stk}
mito_plant:    .../CM5_plant.outdir/CM5_plant.{nosymfrac.cm,refrag.stk}
mito_vertebrate:.../CM1_vertebrate.outdir/CM1_vertebrate.{nosymfrac.cm,refrag.stk}
```
(All under `/net/intdev/oblast01/infernal/notebook/26_0518_ribo_sensor_expansion/`.)

## Not archived here (flagged for awareness)

- **noFG edf variants:** brief 040 also built a no-`--fraggiven` flavor,
  `cm-build/edf-lsu/ab/ra.LSU_rRNA_<clade>.edf.noFG.cm` (10 models) plus per-clade
  `*.{fraggiven,nofraggiven}.cmbuild.log`. These are a build comparison and were
  **out of scope** for this archive (brief 041 scoped the 10 main fraggiven edf
  models). They remain only in the notebook dir.
- **Extraction run outputs / scratch:** `lsu-extraction/{edf-ab,dry-run,genomes,
  ssu-spotcheck,acc-lists-dryrun}` (run outputs, ~130 MB) were intentionally not
  archived — only the tooling (drivers, cand-cms, README) is captured here.
- **CM calibration:** none of the edf models is calibrated; deferred to a later
  step once the next seed iteration is finalized.
