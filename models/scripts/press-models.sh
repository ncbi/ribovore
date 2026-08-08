#/bin/bash

set -e
cp $RIBOINFERNALDIR/cmpress .

# models with both a ribotyper (rt.*.enone.cm) and riboaligner (ra.*.edf.cm) CM
for m in \
    LSU_rRNA_archaea \
    LSU_rRNA_bacteria \
    LSU_rRNA_eukarya \
    SSU_rRNA_archaea \
    SSU_rRNA_bacteria \
    SSU_rRNA_eukarya \
    SSU_rRNA_microsporidia \
    SSU_rRNA_chloroplast \
    SSU_rRNA_cyanobacteria \
    SSU_rRNA_mito_metazoa \
    SSU_rRNA_apicoplast \
    SSU_rRNA_chloroplast_pilostyles \
    SSU_rRNA_mito_amoebozoa \
    SSU_rRNA_mito_chlorophyta \
    SSU_rRNA_mito_fungi \
    SSU_rRNA_mito_kinetoplastea \
    SSU_rRNA_mito_embryophyta \
    ; do
    ./cmpress rt.$m.enone.cm
    ./cmpress ra.$m.edf.cm
done

# SSU mito models with only a ribotyper (rt.*.enone.cm) CM -- no riboaligner
# (edf-filter) CM has been built for these (brief 26_0518-137)
for m in \
    SSU_rRNA_mito_ciliophora \
    SSU_rRNA_mito_bigyra \
    SSU_rRNA_mito_oomycota \
    SSU_rRNA_mito_cryptophyceae \
    SSU_rRNA_mito_choanoflagellata \
    SSU_rRNA_mito_protist_other \
    SSU_rRNA_mito_protostomia \
    ; do
    ./cmpress rt.$m.enone.cm
done

# LSU models, ribotyper-only (rt.*.cm, no ".enone" suffix, no riboaligner CM)
for m in \
    LSU_rRNA_microsporidia \
    LSU_rRNA_mito_vertebrata \
    LSU_rRNA_mito_bilateria \
    LSU_rRNA_mito_arthropoda \
    LSU_rRNA_mito_eukaryote \
    LSU_rRNA_mito_embryophyta \
    LSU_rRNA_mito_nematoda \
    LSU_rRNA_mito_kinetoplastea \
    LSU_rRNA_chloroplast \
    LSU_rRNA_apicoplast \
    ; do
    ./cmpress rt.$m.cm
done

./cmpress ribotyper.cm
