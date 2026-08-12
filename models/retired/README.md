# Retired seed alignments

Seed alignments for models that are **no longer part of the shipped registry**, kept here so their
deprecated status is visible rather than buried in git history.

**Nothing in this directory is loaded at runtime.** No `*.modelinfo` references these files, and
`ribotyper`/`riboaligner`/`ribosensor` never read them. They are provenance records only.

Files keep the model name they had when retired, so they can be matched against older releases and
against the commit history.

---

## `SSU_rRNA_mitochondria_protist.stk`

**Retired:** 2026-08 · **Replaced by:** 7 models

The `mito_protist` model was a taxonomic wastebasket rather than a coherent family — only a small
fraction of its base pairs were structurally distinct from the rest of the registry, and its membership
spanned ~21 unrelated eukaryotic groups. It was split into taxon-resolved models, each built on a
genuine structural anchor:

`SSU_rRNA_mito_bigyra` · `SSU_rRNA_mito_choanoflagellata` · `SSU_rRNA_mito_ciliophora` ·
`SSU_rRNA_mito_cryptophyceae` · `SSU_rRNA_mito_oomycota` · `SSU_rRNA_mito_protist_other` (a residual
covering lineages with no better home) · plus `SSU_rRNA_mito_protostomia`.

⚠ **This file carries pseudoknot annotation** and is worth reading before any Rfam submission of the
replacement models. The annotation was added separately from the model build and represents work that
may be reusable for the split models — the replacements recovered from build inputs do **not** carry it.

## `SSU_rRNA_mitochondria_fungi.stk`

**Retired:** 2026-08 · **Replaced by:** `SSU_rRNA_mito_fungi.stk`

Pre-rebuild seed, 94 sequences. The model was rebuilt to 90 sequences under the project's corrected
fragment-aware methodology; the current seed is the exact build input for the shipped model. Also
carries pseudoknot annotation (see above).

## `SSU_rRNA_mitochondria_plant.stk`

**Retired:** 2026-08 · **Replaced by:** `SSU_rRNA_mito_embryophyta.stk`

Pre-rebuild seed, 51 sequences, and a pre-rename name. The model was rebuilt to 88 sequences and
renamed for taxonomic accuracy (`plant` → `embryophyta`). Also carries pseudoknot annotation.

## `SSU_rRNA_mitochondria_chlorophyta.stk`

**Retired:** 2026-08 · **Replaced by:** `SSU_rRNA_mito_chlorophyta.stk`

Pre-rebuild seed, 32 sequences. The model was regrown from a structurally-clean core to 47 sequences.
Also carries pseudoknot annotation.
