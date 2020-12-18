#/bin/bash

set -e 
cp $RIBOINFERNALDIR/cmpress .

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
    SSU_rRNA_mitochondria_metazoa \
    SSU_rRNA_apicoplast \
    SSU_rRNA_chloroplast_pilostyles \
    SSU_rRNA_mitochondria_amoeba \
    SSU_rRNA_mitochondria_chlorophyta \
    SSU_rRNA_mitochondria_fungi \
    SSU_rRNA_mitochondria_kinetoplast \
    SSU_rRNA_mitochondria_plant \
    SSU_rRNA_mitochondria_protist \
    ; do
    ./cmpress rt.$m.enone.cm > tmp.cm
    ./cmpress ra.$m.edf.cm > tmp.cm
done
./cmpress ribotyper.cm
