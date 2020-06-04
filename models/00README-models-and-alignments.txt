EPN, Mon Oct 15 10:53:32 2018

Source of alignments for ribotyper models:

Individual model files (second token is file size):
<[(models)]> ls -ltr *cm | awk '{ printf("%s %s\n", $9, $5); }'

List:
riboaligner.0p15.RF02543.cm 2241362
riboaligner.0p15.RF02542.cm 865745
riboaligner.0p15.RF02541.cm 1938871
riboaligner.0p15.RF02540.cm 1976325
riboaligner.0p15.RF01960.cm 1212436
riboaligner.0p15.RF01959.cm 976377
riboaligner.0p15.RF00177.cm 1012808
ribo.0p20.extra.cm 20623154
ribo.0p20.SSU_rRNA_mitochondria_protist.cm 1093487
ribo.0p20.SSU_rRNA_mitochondria_plant.cm 1275015
ribo.0p20.SSU_rRNA_mitochondria_kinetoplast.cm 403516
ribo.0p20.SSU_rRNA_mitochondria_fungi.cm 1048963
ribo.0p20.SSU_rRNA_mitochondria_chlorophyta.cm 784737
ribo.0p20.SSU_rRNA_mitochondria_amoeba.cm 1210433
ribo.0p20.SSU_rRNA_chloroplast_pilostyles.cm 1010321
ribo.0p20.SSU_rRNA_apicoplast.cm 964205
ribo.0p15.cm 12832477
ribo.0p15.SSU_rRNA_mitochondria_metazoa.cm 631187
ribo.0p15.SSU_rRNA_microsporidia.cm 866462
ribo.0p15.SSU_rRNA_eukarya.cm 1213133
ribo.0p15.SSU_rRNA_cyanobacteria.cm 984688
ribo.0p15.SSU_rRNA_chloroplast.cm 985151
ribo.0p15.SSU_rRNA_bacteria.cm 1013847
ribo.0p15.SSU_rRNA_archaea.cm 977437
ribo.0p15.LSU_rRNA_eukarya.cm 2242610
ribo.0p15.LSU_rRNA_bacteria.cm 1940299
ribo.0p15.LSU_rRNA_archaea.cm 1977663
riboaligner.0p40.SSU_rRNA_apicoplast.cm 963759
riboaligner.0p40.SSU_rRNA_chloroplast.cm 983703
riboaligner.0p40.SSU_rRNA_chloroplast_pilostyles.cm 1009875
riboaligner.0p40.SSU_rRNA_cyanobacteria.cm 983048
riboaligner.0p40.SSU_rRNA_mitochondria_amoeba.cm 1270048
riboaligner.0p40.SSU_rRNA_mitochondria_chlorophyta.cm 895529
riboaligner.0p40.SSU_rRNA_mitochondria_fungi.cm 1039693
riboaligner.0p40.SSU_rRNA_mitochondria_kinetoplast.cm 403076
riboaligner.0p40.SSU_rRNA_mitochondria_metazoa.cm 631244
riboaligner.0p40.SSU_rRNA_mitochondria_plant.cm 1274593
riboaligner.0p40.SSU_rRNA_mitochondria_protist.cm 1088003

Short description of each including name of alignment file used to
build them.

[To verify an alignment file was used to build a CM use 
cm-alignment-check.pl, available here
https://github.com/nawrockie/jiffy-infernal-hmmer-scripts]

These alignments were created using 1 of 2 strategies. (Actually
strategy 2 is just an extension of strategy 1.)

'Strategy 1' below means: alignment and consensus secondary structure was
determined using 'Strategy 1' the CRW conversion strategy described in
the SSU-ALIGN 0.1 user's guide
(http://eddylab.org/software/ssu-align/) using tools/scripts available
here: (https://github.com/nawrockie/crw-conversion-tools). Sequences
in that alignment derive from the CRW website/database.
http://www.rna.icmb.utexas.edu/

'Strategy 2' below means: initial version of the alignment and consensus
secondary structure and model was determined using 'Strategy 1', 
but that model was used to create a new alignment and model using 
the Rfam model building pipeline as of version 12.0, to search Rfamseq
to find hits and removing highly similar sequences to get a
more representative alignment than the initial alignment.

-------------------
Multi-CM files:

- ribo.0p20.extra.cm
    Multi-CM file containing 18 CMs. Concatenation of 
    ribo.0p15.SSU_rRNA_archaea.cm
    ribo.0p15.SSU_rRNA_bacteria.cm
    ribo.0p15.SSU_rRNA_eukarya.cm
    ribo.0p15.SSU_rRNA_microsporidia.cm
    ribo.0p15.SSU_rRNA_chloroplast.cm
    ribo.0p15.SSU_rRNA_mitochondria_metazoa.cm
    ribo.0p15.SSU_rRNA_cyanobacteria.cm
    ribo.0p15.LSU_rRNA_archaea.cm
    ribo.0p15.LSU_rRNA_bacteria.cm
    ribo.0p15.LSU_rRNA_eukarya.cm
    ribo.0p20.SSU_rRNA_apicoplast.cm
    ribo.0p20.SSU_rRNA_chloroplast_pilostyles.cm
    ribo.0p20.SSU_rRNA_mitochondria_amoeba.cm
    ribo.0p20.SSU_rRNA_mitochondria_chlorophyta.cm
    ribo.0p20.SSU_rRNA_mitochondria_fungi.cm
    ribo.0p20.SSU_rRNA_mitochondria_kinetoplast.cm
    ribo.0p20.SSU_rRNA_mitochondria_plant.cm
    ribo.0p20.SSU_rRNA_mitochondria_protist.cm

- ribo.0p15.cm
    Multi-CM file containing 10 CMs. Concatenation of 
    ribo.0p15.SSU_rRNA_archaea.cm
    ribo.0p15.SSU_rRNA_bacteria.cm
    ribo.0p15.SSU_rRNA_eukarya.cm
    ribo.0p15.SSU_rRNA_microsporidia.cm
    ribo.0p15.SSU_rRNA_chloroplast.cm
    ribo.0p15.SSU_rRNA_mitochondria_metazoa.cm
    ribo.0p15.SSU_rRNA_cyanobacteria.cm
    ribo.0p15.LSU_rRNA_archaea.cm
    ribo.0p15.LSU_rRNA_bacteria.cm
    ribo.0p15.LSU_rRNA_eukarya.cm
--------------------------------
Individual ribotyper CM files:

- ribo.0p15.LSU_rRNA_archaea.cm: 
    Alignment file: RF02540.12p2.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from Rfam 12.2 RF02540
    alignment, which was built using 'strategy 2' (defined above).
    
- ribo.0p15.LSU_rRNA_bacteria.cm:
    Alignment file: RF02541.12p2.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from Rfam 12.2 RF02541
    alignment, which was built using 'strategy 2' (defined above).

- ribo.0p15.LSU_rRNA_eukarya.cm
    Alignment file: RF02543.12p2.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from Rfam 12.2 RF02543
    alignment, which was built using 'strategy 2' (defined above).

- ribo.0p15.SSU_rRNA_archaea.cm
    Alignment file: RF01959.12p2.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from Rfam 12.2 RF01959
    alignment, which was built using 'strategy 2' (defined above).

- ribo.0p15.SSU_rRNA_bacteria.cm
    Alignment file: RF00177.12p2.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from Rfam 12.2 RF00177
    alignment, which was built using 'strategy 2' (defined above).
    
- ribo.0p15.SSU_rRNA_chloroplast.cm
    Alignment file: ribo.0p15.SSU_rRNA_chloroplast.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 2' (defined above).

- ribo.0p15.SSU_rRNA_cyanobacteria.cm
    Alignment file: ribo.0p15.SSU_rRNA_cyanobacteria.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 2' (defined above).

- ribo.0p15.SSU_rRNA_eukarya.cm 
    Alignment file: RF01960.12p2.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from Rfam 12.2 RF01960
    alignment, which was built using 'strategy 2' (defined above).

- ribo.0p15.SSU_rRNA_microsporidia.cm
    Alignment file: RF02542.12p2.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from Rfam 12.2 RF02542,
    alignment, which was built using 'strategy 2' (defined above).

- ribo.0p15.SSU_rRNA_mitochondria_metazoa.cm 631187
    Alignment file: ribo.0p15.SSU_rRNA_mitochondria_metazoa.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 2' (defined above).

- ribo.0p20.SSU_rRNA_apicoplast.cm
    Alignment file: ribo.0p20.SSU_rRNA_apicoplast.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 1' (defined above).

- ribo.0p20.SSU_rRNA_chloroplast_pilostyles.cm
    Alignment file: ribo.0p20.SSU_rRNA_chloroplast_pilostyles.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 1' (defined above).

- ribo.0p20.SSU_rRNA_mitochondria_amoeba.cm
    Alignment file: ribo.0p20.SSU_rRNA_mitochondria_amoeba.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 1' (defined above).

- ribo.0p20.SSU_rRNA_mitochondria_chlorophyta.cm
    Alignment file: ribo.0p20.SSU_rRNA_mitochondria_chlorophyta.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 1' (defined above).

- ribo.0p20.SSU_rRNA_mitochondria_fungi.cm
    Alignment file: ribo.0p20.SSU_rRNA_mitochondria_fungi.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 1' (defined above).

- ribo.0p20.SSU_rRNA_mitochondria_kinetoplast.cm
    Alignment file: ribo.0p20.SSU_rRNA_mitochondria_kinetoplast.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 1' (defined above).

- ribo.0p20.SSU_rRNA_mitochondria_plant.cm
    Alignment file: ribo.0p20.SSU_rRNA_mitochondria_plant.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from a non-Rfam 
    alignment, which was built using 'strategy 1' (defined above).

- ribo.0p20.SSU_rRNA_mitochondria_protist.cm
    Alignment file: ribo.0p20.SSU_rRNA_mitochondria_protist.stk
    built with Infernal v1.1.3 cmbuild --p7ml --enone from Rfam 12.2 RF02542,
    alignment, which was built using 'strategy 1' (defined above).

---------------------------------
Riboaligner models: 
Built without --enone option to cmbuild.

- riboaligner.0p15.RF00177.cm
  Alignment file: RF00177.12p2.stk
  built with Infernal v1.1.2 cmbuild default from Rfam 12.2 RF00177
  alignment, which was built using 'strategy 2' (defined above).

- riboaligner.0p15.RF01959.cm
  Alignment file: RF01959.12p2.stk
  built with Infernal v1.1.2 cmbuild default from Rfam 12.2 RF01959
  alignment, which was built using 'strategy 2' (defined above).

- riboaligner.0p15.RF01960.cm
  Alignment file: RF01960.12p2.stk
  built with Infernal v1.1.2 cmbuild default from Rfam 12.2 RF01960
  alignment, which was built using 'strategy 2' (defined above).

- riboaligner.0p15.RF02540.cm
  Alignment file: RF02540.12p2.stk
  built with Infernal v1.1.2 cmbuild default from Rfam 12.2 RF02540
  alignment, which was built using 'strategy 2' (defined above).

- riboaligner.0p15.RF02541.cm
  Alignment file: RF02541.12p2.stk
  built with Infernal v1.1.2 cmbuild default from Rfam 12.2 RF02541
  alignment, which was built using 'strategy 2' (defined above).

- riboaligner.0p15.RF02542.cm
  Alignment file: RF02542.12p2.stk
  built with Infernal v1.1.2 cmbuild default from Rfam 12.2 RF02542
  alignment, which was built using 'strategy 2' (defined above).

- riboaligner.0p15.RF02543.cm
  Alignment file: RF02543.12p2.stk
  built with Infernal v1.1.2 cmbuild default from Rfam 12.2 RF02543
  alignment, which was built using 'strategy 2' (defined above).

[added for 0.40 release]:
And 11 CM files named 
riboaligner.0p40.<s>.cm
with <s> equal to one of
SSU_rRNA_apicoplast
SSU_rRNA_chloroplast
SSU_rRNA_chloroplast_pilostyles
SSU_rRNA_cyanobacteria
SSU_rRNA_mitochondria_amoeba
SSU_rRNA_mitochondria_chlorophyta
SSU_rRNA_mitochondria_fungi
SSU_rRNA_mitochondria_kinetoplast
SSU_rRNA_mitochondria_metazoa
SSU_rRNA_mitochondria_plant
SSU_rRNA_mitochondria_protist

Alignment file: 
ribo.0p15.<s>.stk OR
ribo.0p20.<s>.stk
built with Infernal v1.1.3 cmbuild with default parameters from a
non-Rfam alignment which was built using 'strategy 1' (defined above).

                
