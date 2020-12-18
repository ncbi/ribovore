#/bin/bash

set -e 

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
    perl scrub-model.pl rt.$m.enone.cm > tmp.cm
    mv tmp.cm rt.$m.enone.cm
    perl scrub-model.pl ra.$m.edf.cm > tmp.cm
    mv tmp.cm ra.$m.edf.cm
done
