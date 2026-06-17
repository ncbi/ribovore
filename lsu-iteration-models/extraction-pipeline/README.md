# LSU extraction pipeline (mirror of Aaron Dickey's SSU recipe, LSU side)

Brief 039. Extracts full-length LSU rRNA genes from RefSeq genomes, mirroring
Aaron's SSU extraction so we get **matched SSU+LSU organellar datasets** to
iterate the SSU and LSU models in parallel.

## Method decision (STEP 0)

**`edf` = riboaligner alignment-flavor CM build.** Each Ribovore rRNA model ships
as two CMs (see `documentation/models.md`): `rt.*.enone.cm` (ribotyper
*classification* flavor, built `cmbuild -F --p7ml --enone`) and `ra.*.edf.cm`
(riboaligner *alignment* flavor, built with plain `cmbuild -F`, default entropy
weighting). Confirmed from the CM `COM` header lines. "edf" is the alignment
model riboaligner uses; Aaron cmsearches/cmaligns against the published SSU
`*.edf.cm`.

**Implementation chosen: (B) raw Infernal**, not (A) riboaligner. Reason:
**edf-flavor organellar LSU models do not exist.** In the v5 library only the
three *generic* LSU models have an `ra.*.edf.cm` (archaea/bacteria/eukarya);
the 10 organellar LSU models exist only as `rt.*.cm` (calibrated,
`cmbuild -F --p7ml --enone --fraggiven`). Building/calibrating edf-flavor LSU
models was out of scope for this brief, so we reproduce Aaron's five steps with
raw Infernal 1.1.5 (`cmsearch` → `esl-sfetch` → `cmalign` → trunc filter), which
gives byte-identical operations to his recipe modulo the entropy-weighting flavor
of the model.

**The five steps (per genome, per model):**
1. `cmsearch <model> <genome>` → locate LSU hit(s), coords, strand, score.
2. greedy non-overlapping locus selection (handles multi-copy operons).
3. `esl-sfetch -c from..to` → extract predicted gene (auto revcomp if from>to).
4. size filter: keep length within **±25% of the CM consensus length** (`clen`
   from `cmstat`), i.e. `[0.75·clen, 1.25·clen]`.
5. `cmalign <model> <extract>` → read the per-seq **`trunc`** column; keep
   `trunc == no` (full-length, untruncated).

**`trunc` determination:** the `trunc` field (column 6) of `cmalign`'s per-seq
output table. Values: `no` (full), `5'`, `3'`, `5'&3'`. NOTE: `cmalign`'s trunc
call on an *isolated extract* is **stricter** than `cmsearch`'s envelope — a hit
`cmsearch` reports as spanning model 1..clen can still be `cmalign` `trunc=5'`
if its extracted 5' end does not cleanly reach the first consensus position.
This is exactly the filter Aaron applies, so our behavior matches his.

**±25% band** = `[0.75·clen, 1.25·clen]`, clen per model (from `cmstat`):

| model | clen | band (nt) |
|---|---:|---|
| LSU_rRNA_chloroplast    | 2929 | 2197–3661 |
| LSU_rRNA_bacteria       | 2925 | 2194–3656 |
| LSU_rRNA_mito_eukaryote | 2644 | 1983–3305 |
| LSU_rRNA_mito_plant     | 2803 | 2102–3504 |
| LSU_rRNA_mito_vertebrate| 1570 | 1178–1962 |
| LSU_rRNA_mito_arthropod | 1393 | 1045–1741 |
| LSU_rRNA_mito_bilateria | 1285 |  964–1606 |
| LSU_rRNA_mito_kinetoplast| 1172|  879–1465 |
| LSU_rRNA_mito_nematode  |  972 |  729–1215 |

## Which model per genome ("the correct CM")

Single-model sets: chloroplast→`LSU_rRNA_chloroplast`; fungi/algae/protist
mito→`LSU_rRNA_mito_eukaryote` (CM4); plant mito→`LSU_rRNA_mito_plant`;
cyano/rickettsia→`LSU_rRNA_bacteria`.

**Animal mito is ambiguous** (vertebrate/bilateria/arthropod/nematode). The
driver handles this by accepting a **multi-model candidate CM** (all 4 animal-mito
LSU models concatenated) and letting the best-scoring model win each locus —
a built-in mini-classification step. Verified: turtle→vertebrate, fish→vertebrate,
bee→arthropod.

## The driver: `extract_lsu.sh`

```
./extract_lsu.sh <acc-list.txt> <candidate.cm> <outdir> [bandfrac]
```
- `acc-list.txt` : one RefSeq accession per line (version-less OK; efetch resolves).
- `candidate.cm` : one or more **calibrated 1.1.5** CMs (the matched model, or a
  concatenation of candidates for ambiguous sets). Index with
  `cmfetch --index` once.
- `outdir`       : holds `genomes/`, `<acc>.cmsearch.*`, `<acc>.locusN.*`,
  `kept_lsu.fasta`, and `per_acc.log`.
- `bandfrac`     : size half-band (default 0.25).
- env: `CPU` (default 4).

**Output FASTA header = `versionedACC|strand|seqfrom`** (join key; strip version
to match Aaron's `acc-lists/*.txt` and his SSU records). Aaron's own SSU headers
use `versionedACC<strand><seqstart>` with no pipes, e.g. `NC_007700.1+2089` — same
fields, recoverable accession.

`per_acc.log` columns: `acc locus model strand seqfrom seqto len clen in_band trunc kept`.

Candidate CMs prebuilt in `cand-cms/` (ch, mf, cy single-model; mm = 4 animal-mito
models concatenated). Build a new one with:
```
cmfetch <library.cm> <MODELNAME> > cand-cms/<set>.cm   # pinned 1.1.5 cmfetch
cmfetch --index cand-cms/<set>.cm
```

## Binaries used
- Infernal **1.1.5** (`/home/nawrocke/src/infernal-1.1.5/src/`): cmsearch, cmalign,
  cmstat, cmfetch — matches the 1.1.5-built v5 CMs.
- Easel (`/home/nawrocke/src/infernal-1.1.5/easel/miniapps/`): esl-sfetch.
- `efetch` (`/am/ncbiapdata/bin/efetch`, EDirect 25.9) for genome fetch.

## Dry-run evidence
See `dry-run/` (per-set `per_acc.log`, `kept_lsu.fasta`, alignments) and
`ssu-spotcheck/` (STEP 2b). Summary table in
`../subagent-summaries/039_2026-06-16_lsu-extraction-pipeline_summary.md`.
</content>
