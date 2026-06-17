#!/bin/bash
# extract_lsu_edf.sh -- LSU extraction pipeline, edf-for-align variant (brief 040).
#
# Identical to extract_lsu.sh EXCEPT the cmalign (truncation) step can use a
# SEPARATE model file from the cmsearch (locate) step:
#
#   - cmsearch (locate)  : always uses $CANDCM  (the enone search models)
#   - cmalign  (trunc)   : uses $ALIGNCM if set, else $CANDCM
#                          (set ALIGNCM=<edf-candidate.cm> for edf-for-align;
#                           leave unset to reproduce 039's enone-for-both baseline)
#
# The model NAME assigned by cmsearch (from $CANDCM) is used to cmfetch the
# alignment model from $ALIGNCM, so the edf candidate file MUST contain models
# with the SAME NAMEs as the enone search models (edf models in brief 040 were
# built with -n LSU_rRNA_<clade> to guarantee this).
#
# Usage:
#   ALIGNCM=<edf.cm> extract_lsu_edf.sh <acc-list.txt> <search.cm> <outdir> [bandfrac]
#
# Binaries: Infernal 1.1.5 (matches the 1.1.5-built v5 CMs) + pinned cmfetch.
set -u

INFDIR=/home/nawrocke/src/infernal-1.1.5/src
ESLDIR=/home/nawrocke/src/infernal-1.1.5/easel/miniapps
CMSEARCH=$INFDIR/cmsearch
CMALIGN=$INFDIR/cmalign
CMSTAT=$INFDIR/cmstat
CMFETCH=$INFDIR/cmfetch          # pinned 1.1.5 cmfetch (per project memory)
SFETCH=$ESLDIR/esl-sfetch
EFETCH=/am/ncbiapdata/bin/efetch
CPU=${CPU:-4}

if [ $# -lt 3 ]; then
  echo "usage: ALIGNCM=<edf.cm> $0 <acc-list.txt> <search.cm> <outdir> [bandfrac]" >&2; exit 1
fi
ACCLIST=$1; CANDCM=$2; OUT=$3; BAND=${4:-0.25}
ALIGNCM=${ALIGNCM:-$CANDCM}      # align/trunc model source (edf); default = search CM (enone-for-both)
mkdir -p "$OUT/genomes"
KEPTFA=$OUT/kept_lsu.fasta;  : > "$KEPTFA"
LOG=$OUT/per_acc.log;        echo -e "acc\tlocus\tmodel\tstrand\tseqfrom\tseqto\tlen\tclen\tin_band\ttrunc\tkept" > "$LOG"
echo "# search model (cmsearch): $CANDCM"
echo "# align  model (cmalign) : $ALIGNCM"

# ---- clen lookup per model from the SEARCH candidate CM file (band keyed on enone clen) ----
declare -A CLEN
while read -r name clen; do CLEN[$name]=$clen; done < <(
  $CMSTAT "$CANDCM" 2>/dev/null | grep -v '^#' | awk '{print $2, $6}')
echo "# search models / clen:"; for k in "${!CLEN[@]}"; do echo "#   $k ${CLEN[$k]}"; done

while read -r acc; do
  acc=$(echo "$acc" | tr -d '[:space:]'); [ -z "$acc" ] && continue
  G=$OUT/genomes/$acc.fa
  if [ ! -s "$G" ]; then
    $EFETCH -db nuccore -id "$acc" -format fasta > "$G" 2>"$OUT/genomes/$acc.efetch.err"
  fi
  if [ ! -s "$G" ]; then echo -e "$acc\t-\tFETCH_FAIL\t-\t-\t-\t-\t-\t-\t-\tno" >> "$LOG"; continue; fi
  [ -s "$G.ssi" ] || $SFETCH --index "$G" >/dev/null 2>&1
  vacc=$(head -1 "$G" | sed 's/^>//; s/ .*//')   # versioned accession

  TBL=$OUT/$acc.cmsearch.tbl
  $CMSEARCH --cpu $CPU --noali --tblout "$TBL" "$CANDCM" "$G" > "$OUT/$acc.cmsearch.out" 2>"$OUT/$acc.cmsearch.err"

  # passing hits ('!'), sorted by score desc: model from to strand score
  mapfile -t HITS < <(grep -v '^#' "$TBL" | awk '$17=="!"{print $3, $8, $9, $10, $15}' | sort -k5,5gr)
  locus=0
  declare -a TAKEN_LO=() TAKEN_HI=()
  for h in "${HITS[@]}"; do
    set -- $h; model=$1; from=$2; to=$3; strand=$4; score=$5
    lo=$from; hi=$to; [ "$from" -gt "$to" ] && { lo=$to; hi=$from; }
    # skip if overlaps an already-taken locus
    skip=0
    for i in "${!TAKEN_LO[@]}"; do
      if [ "$lo" -le "${TAKEN_HI[$i]}" ] && [ "$hi" -ge "${TAKEN_LO[$i]}" ]; then skip=1; break; fi
    done
    [ "$skip" -eq 1 ] && continue
    TAKEN_LO+=($lo); TAKEN_HI+=($hi)
    locus=$((locus+1))
    len=$((hi-lo+1))
    clen=${CLEN[$model]:-0}
    loband=$(awk "BEGIN{printf \"%d\", $clen*(1-$BAND)}")
    hiband=$(awk "BEGIN{printf \"%d\", $clen*(1+$BAND)}")
    inband=no; [ "$len" -ge "$loband" ] && [ "$len" -le "$hiband" ] && inband=yes

    sid="$vacc|$strand|$from"
    sfa=$OUT/$acc.locus$locus.fa
    echo ">$sid" > "$sfa"
    $SFETCH -c "$from..$to" "$G" "$vacc" 2>/dev/null | grep -v '^>' >> "$sfa"

    # cmalign vs the winning model only (fetched from ALIGNCM = edf) -> trunc
    mcm=$OUT/.alnmodel.$model.cm
    [ -s "$mcm" ] || $CMFETCH "$ALIGNCM" "$model" > "$mcm" 2>"$OUT/.cmfetch.$model.err"
    $CMALIGN --cpu $CPU -o "$OUT/$acc.locus$locus.stk" "$mcm" "$sfa" > "$OUT/$acc.locus$locus.cmalign.out" 2>"$OUT/$acc.locus$locus.cmalign.err"
    trunc=$(grep -v '^#' "$OUT/$acc.locus$locus.cmalign.out" | awk '{print $6}' | head -1)
    [ -z "$trunc" ] && trunc=ERR

    kept=no
    if [ "$inband" = yes ] && [ "$trunc" = no ]; then
      kept=yes; cat "$sfa" >> "$KEPTFA"
    fi
    echo -e "$acc\t$locus\t$model\t$strand\t$from\t$to\t$len\t$clen\t$inband\t$trunc\t$kept" >> "$LOG"
  done
  unset TAKEN_LO TAKEN_HI
  [ "$locus" -eq 0 ] && echo -e "$acc\t0\tNO_HIT\t-\t-\t-\t-\t-\t-\t-\tno" >> "$LOG"
done < "$ACCLIST"

echo "# done. kept LSU records: $(grep -c '^>' "$KEPTFA")  -> $KEPTFA"
echo "# per-accession log: $LOG"
