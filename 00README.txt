EPN, Wed Feb 22 15:59:00 2017

Preliminary documentation for ribotyper, a tool for detecting and
classifying SSU rRNA and LSU rRNA sequences.
Author: Eric Nawrocki

Current location of code and other relevant files:
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/

Sample run:
From: 
/panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/

This example runs the script on a sample file of 15 sequences:
perl ribotyper.pl testfiles/seed-15.fa models/ssu.7.lsu.3.170222.cm models/ssu.7.lsu.3.170222.clans test

The script takes 3 command line arguments:

The first argument is the sequence file you want to annotate.

The second argument is the model file which includes the profiles used
to do the search.

The third argument is a text file with information on the taxonomic
classifications that each profile pertains to.

Example output:
# ribotyper.pl :: detect and classify ribosomal RNA sequences
# dnaorg 0.01 (Dec 2016)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Thu Feb 23 15:35:44 2017
#
# target sequence input file:   /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/testfiles/seed-15.fa           
# query model input file:       /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.7.lsu.3.170222.cm   
# clan information input file:  /panfs/pan1/dnaorg/ssudetection/code/ribotyper-v1/models/ssu.7.lsu.3.170222.clans
# output directory name:        test-df                                                                          
# forcing directory overwrite:  yes [-f]                                                                         
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parsing and validating input files and determining target sequence lengths ... done. [0.0 seconds]
# Performing cmsearch-hmmonly search                                         ... done. [8.4 seconds]
# Sorting tabular search results                                             ... done. [0.0 seconds]
# Parsing tabular search results                                             ... done. [0.0 seconds]
#
# Short (3 column) output saved to file test-df/test-df.ribotyper.short.out.
# Long (14 column) output saved to file test-df/test-df.ribotyper.long.out.
#
#[RIBO-SUCCESS]

-----------------
Output files:

Currently, there are two output files. Both are tabular output files with one line per sequence:

A 'short' file of 3 columns, with target name, classification and
pass/fail, and a 'long' file with 18 columns with more information
including strand, score, and position information.

Short file:

#target                                        classification        pass/fail
#-----------------------------                 --------------------  ---------
00004::Nanoarchaeum_equitans::AJ318041         SSU.Archaea           PASS
00013::Methanobacterium_formicicum::M36508     SSU.Archaea           PASS
00035::Bacteroides_fragilis::M61006|g143965    SSU.Bacteria          PASS
00052::Halobacterium_sp.::AE005128             SSU.Archaea           PASS
00072::Chlamydia_trachomatis.::AE001345        SSU.Bacteria          PASS
00115::Pyrococcus_furiosus::U20163|g643670     SSU.Archaea           PASS
00121::Thermococcus_celer::M21529              SSU.Archaea           PASS
00220::Euplotes_aediculatus.::M14590           SSU.Eukarya           PASS
00224::Rickettsia_prowazekii.::AJ235272        SSU.Bacteria          PASS
00229::Oxytricha_granulifera.::AF164122        SSU.Eukarya           PASS
01106::Bacillus_subtilis::K00637               SSU.Bacteria          PASS
01223::Audouinella_hermannii.::AF026040        SSU.Eukarya           PASS
01240::Batrachospermum_gelatinosum.::AF026045  SSU.Eukarya           PASS
01351::Mycoplasma_gallisepticum::M22441        SSU.Bacteria          PASS
01710::Oryza_sativa.::X00755                   SSU.Eukarya           PASS


Long file:

First 14 columns:

#                                                                                                                   best-scoring model                                
#                                                                                           ------------------------------------------------------------------------
#target                                         p/f   targetlen  #ht  fam  domain           model               evalue       score  s    cov       start        stop
#-----------------------------                 ----  ----------  ---  ---  ---------------  ------------------  ------  ----------  -  -----  ----------  ----------
00004::Nanoarchaeum_equitans::AJ318041         PASS         867    1  SSU  Archaea          SSU_rRNA_archaea         -       658.5  +  1.000           1         867
00013::Methanobacterium_formicicum::M36508     PASS        1476    1  SSU  Archaea          SSU_rRNA_archaea         -      1237.8  +  1.000           1        1476
00035::Bacteroides_fragilis::M61006|g143965    PASS        1537    1  SSU  Bacteria         SSU_rRNA_bacteria        -      1123.0  +  1.000           1        1537
00052::Halobacterium_sp.::AE005128             PASS        1473    1  SSU  Archaea          SSU_rRNA_archaea         -      1216.7  +  1.000           1        1473
00072::Chlamydia_trachomatis.::AE001345        PASS         887    1  SSU  Bacteria         SSU_rRNA_bacteria        -       638.1  +  1.000           1         887
00115::Pyrococcus_furiosus::U20163|g643670     PASS         922    1  SSU  Archaea          SSU_rRNA_archaea         -       782.5  -  1.000         922           1
00121::Thermococcus_celer::M21529              PASS        1780    1  SSU  Archaea          SSU_rRNA_archaea         -      1251.7  +  1.000           1        1780
00220::Euplotes_aediculatus.::M14590           PASS        1082    1  SSU  Eukarya          SSU_rRNA_eukarya         -       623.4  +  1.000           1        1082
00224::Rickettsia_prowazekii.::AJ235272        PASS        1620    1  SSU  Bacteria         SSU_rRNA_bacteria        -      1195.7  +  1.000           1        1620
00229::Oxytricha_granulifera.::AF164122        PASS         600    1  SSU  Eukarya          SSU_rRNA_eukarya         -       405.5  -  1.000         600           1
01106::Bacillus_subtilis::K00637               PASS        1552    1  SSU  Bacteria         SSU_rRNA_bacteria        -      1266.4  +  1.000           1        1552
01223::Audouinella_hermannii.::AF026040        PASS        1771    1  SSU  Eukarya          SSU_rRNA_eukarya         -      1254.3  +  1.000           1        1771
01240::Batrachospermum_gelatinosum.::AF026045  PASS        1765    1  SSU  Eukarya          SSU_rRNA_eukarya         -      1250.3  +  1.000           1        1765
01351::Mycoplasma_gallisepticum::M22441        PASS         881    1  SSU  Bacteria         SSU_rRNA_bacteria        -       584.2  -  1.000         881           1
01710::Oryza_sativa.::X00755                   PASS        2046    1  SSU  Eukarya          SSU_rRNA_eukarya         -      1320.8  +  1.000           1        2046

Final 4 columns (with first column included):

#                                             ...                        second-best-scoring model              
#                                             ...               ----------------------------------------------  
#target                                       ...       scdiff  model                       evalue       score  extra
#-----------------------------                ...   ----------  ----------------------  ----------  ----------  -----
00004::Nanoarchaeum_equitans::AJ318041        ...        201.0  SSU_rRNA_bacteria                -       457.5  -
00013::Methanobacterium_formicicum::M36508    ...        441.7  SSU_rRNA_bacteria                -       796.1  -
00035::Bacteroides_fragilis::M61006|g143965   ...        179.1  SSU_rRNA_chloroplast             -       943.9  -
00052::Halobacterium_sp.::AE005128            ...        486.6  SSU_rRNA_bacteria                -       730.1  -
00072::Chlamydia_trachomatis.::AE001345       ...         66.4  SSU_rRNA_chloroplast             -       571.7  -
00115::Pyrococcus_furiosus::U20163|g643670    ...        270.8  SSU_rRNA_bacteria                -       511.7  -
00121::Thermococcus_celer::M21529             ...        442.5  SSU_rRNA_bacteria                -       809.2  -
00220::Euplotes_aediculatus.::M14590          ...        287.1  SSU_rRNA_microsporidia           -       336.3  -
00224::Rickettsia_prowazekii.::AJ235272       ...        124.7  SSU_rRNA_chloroplast             -      1071.0  -
00229::Oxytricha_granulifera.::AF164122       ...        198.7  SSU_rRNA_microsporidia           -       206.8  -
01106::Bacillus_subtilis::K00637              ...        117.2  SSU_rRNA_cyanobacteria           -      1149.2  -
01223::Audouinella_hermannii.::AF026040       ...        599.5  SSU_rRNA_microsporidia           -       654.8  -
01240::Batrachospermum_gelatinosum.::AF026045 ...        595.9  SSU_rRNA_microsporidia           -       654.4  -
01351::Mycoplasma_gallisepticum::M22441       ...         69.3  SSU_rRNA_chloroplast             -       514.9  -
01710::Oryza_sativa.::X00755                  ...        649.5  SSU_rRNA_microsporidia           -       671.3  -





















Further development:
--------------------
- Test different modes (default, slow, fast) on several diverse SSU
  datasets and compare results to determine if default setting is 
  the best choice. 

- Decide on final set of models to use by default

- Modify decision for 'FAILURE' based on score differences between
  top two scoring models based on:
  o which two models are involved (more complicated than current)
  o observed per-position score differences between models versus
    expected (much more complicated than current, but probably best)



Possible improvements:
----------------------



perl $DOD/ssudetection/code/ribotyper-v1/ribotyper.pl --fast -f $DOD/ssudetection/code/ribotyper-v1/testfiles/seed-15.fa $DOD/ssudetection/code/ribotyper-v1/models/ssu.7.lsu.3.170222.cm $DOD/ssudetection/code/ribotyper-v1/models/ssu.7.lsu.3.170222.clans test
