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

---

# ADDENDUM — grown **v7** `--p7ml --enone` LSU models (added 2026-08-13, built 2026-06-24)

**Status: ARCHIVE ONLY. Calibrated, decided-to-ship, and NEVER INTEGRATED.**

★ **Read this before assuming these are, or ever were, the shipped models.** On 2026-06-24 a
ship decision selected this grown v7 library as the ribosensor classification library,
superseding the v5 organellar LSU models. **That decision was never executed at the
git-integration step.** The v7 CMs were built, calibrated, and assembled into a collaborator
package, but were never committed to any branch of this repository until now, and `develop`
has always carried — and still carries — the **v5** organellar LSU CMs.

Two log entries elsewhere in the project record this library as "live on develop." Both are
incorrect; the discrepancy was found and root-caused on 2026-08-13 (brief `26_0518-153`) by
`CKSUM` comparison plus a repo-wide content search confirming none of these blobs had ever
been committed. **They are archived here so the work is recoverable, not because it shipped.**

## Provenance

- **Base commit:** `befb9a4` (same as the rest of this archive) — the v5 state these were
  built to replace.
- **Briefs:** `26_0518-050`–`26_0518-056` (seed growth, build, calibrate), `26_0518-057`
  (collaborator package assembly), `26_0518-153` (the audit that established non-integration).
- **Build binary:** Infernal 1.1.5.
- **Recipe:** `cmbuild -F --p7ml --enone --hand -n LSU_rRNA_<clade> CM SEED`, then
  `cmcalibrate --ptot 160` (split into partitions, then `--merge`).
- **`COM` lines in `v7-enone/cms/` have been genericized** (binary paths and file arguments
  replaced with `CM`/`SEED`) to match the convention used in `models/`. **Model parameters are
  byte-identical to the original build products** — verified: zero non-`COM` diff lines, and
  `CKSUM` preserved on every model.

## Layout (`lsu-iteration-models/v7-enone/`)

```
cms/     10 calibrated v7 enone LSU CMs (rt.LSU_rRNA_<clade>.v7.enone.cm)
seeds/   10 grown v7 seed alignments (LSU_rRNA_<clade>.v7.seed.stk)
```

`cmpress` indices (`.i1f/.i1i/.i1m/.i1p`) are **deliberately not archived** — they are pure
`cmpress` output and regenerate in seconds.

## Model table — v7 vs the v5 models it would have replaced

★ **`clen` is identical across v5 and v7 for all 10 clades.** v7 grew the *seed*, not the
model length — so `nseq` is the discriminator, not `clen`. `CKSUM` distinguishes them
definitively.

| clade | v5 nseq | **v7 nseq** | clen (both) | v7 CKSUM |
|---|---:|---:|---:|---:|
| apicoplast       | 6  | **36**  | 2701 | 749884992  |
| chloroplast      | 20 | **102** | 2929 | 474321144  |
| microsporidia    | 6  | **12**  | 2593 | 3713967036 |
| mito_arthropod   | 5  | **92**  | 1393 | 450093886  |
| mito_bilateria   | 11 | **139** | 1285 | 4124679594 |
| mito_eukaryote   | 9  | **96**  | 2644 | 1920271390 |
| mito_kinetoplast | 4  | **13**  | 1172 | 2398245183 |
| mito_nematode    | 3  | **35**  | 972  | 1227147237 |
| mito_plant       | 2  | **62**  | 2803 | 4014517016 |
| mito_vertebrate  | 20 | **86**  | 1570 | 3509053924 |

## The trade recorded at ship time (NOT re-measured since)

The 2026-06-24 decision recorded claimed generalization gains (apicoplast 59%→100%;
Cnidaria/Porifera coverage in bilateria; jakobid coverage in eukaryote) against an accepted
**−3** regression on a CRW2-derived benchmark (651 vs 654/657), attributed to 4 sequences at
the arthropod↔bilateria boundary, all review-flagged rather than silent.

⚠ **Both halves of that trade were priced against a 28-model registry.** The shipped registry
is now 34 models with a different composition. **Neither the gains nor the cost has been
measured against what is actually shipped**, so these figures are historical context, not a
current recommendation. Anyone considering adopting this library needs a fresh system-level
old-vs-new differential across the whole registry — per-model checks cannot see cross-model
interference in a shared argmax library.

## Clade naming

These use the **pre-2026-08 clade names** (`mito_arthropod`, `mito_kinetoplast`,
`mito_nematode`, `mito_plant`, `mito_vertebrate`). The shipped registry has since renamed
these to `mito_arthropoda`, `mito_kinetoplastea`, `mito_nematoda`, `mito_embryophyta`,
`mito_vertebrata`. Names here are left at their as-built values.
