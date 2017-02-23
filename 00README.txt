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

The Long file is not shown because it is so wide. 
An example is in testfiles/example.long.txt.

Currently, PASS/FAIL is determined as follows:

A sequence passes if it has 1 hit to any SSU or LSU model (but not to
both) and the score difference between the top scoring and second top
scoring model is < 50 bits, otherwise the sequence FAILs. The higher
the score difference between the top top scoring models, the more
confident the classification is.

We expect the definition of PASS and FAIL will change as testing
continues and we get feedback from indexers.


Possible future development:
----------------------------
- Test different modes (default, slow, fast) on several diverse SSU
  datasets and compare results to determine if default setting is 
  the best choice. 

- Decide on final set of models to use by default

- Modify decision for 'FAILURE' based on score differences between
  top two scoring models based on:
  o which two models are involved (more complicated than current)
  o observed per-position score differences between models versus
    expected (much more complicated than current, but probably best)

