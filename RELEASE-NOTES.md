# Ribovore release notes 

### Ribovore 1.0.4 release (Feb 2023): Documentation fix release
  * Updates version and date in README.md which were incorrect
    in v1.0.3 (unchanged from v1.0.2).

### Ribovore 1.0.3 release (Feb 2023): Bug/documentation fix release
  * Updates NCBI taxonomy tree
    (taxonomy/ncbi-taxonomy-tree.ribodbmaker.txt) 
  * Fixes several typos and makes several clarifications related to
    environment variables in install script (install.sh)
  * Fixes bug in ribosensor script that required esl-sfetch to be in
    user's path

### Ribovore 1.0.2 release (March 2021): Bug fix release
  * Fixes install.sh again to download correct version tarballs
  * Adds public domain notice as LICENSE
  * No code changes between 1.0, 1.0.1, and 1.0.2 only changes
    are to install script and addition of LICENSE in 1.0.2

### Ribovore 1.0.1 release (March 2021): Bug fix release
  * Fixes install.sh to properly name ribovore zip file after downloading.

### Ribovore 1.0 release (Feb 2021): First major release
  * The version used in the Ribovore manuscript: *Ribovore: ribosomal
    RNA sequence analysis for GenBank submissions and database curation*;
    in preparation (to be uploaded to bioRxiv in Feb 2021);

---

### Ribovore 0.40 release (June 2020): Minor update
  * adds ribotyper.pl --skipval option for skipping validation stage
  * adds ribotyper.pl --onlyval option for only doing validation stage
    and then exiting
  * adds 11 new riboaligner.0p40 SSU rRNA models, that already had
    analogous ribotyper models.
  * fixes bug related to ribodbmaker.pl --riboopts1 option processing
  * updates test suite

---

For more information, see the [git log for the develop
branch](https://github.com/nawrockie/vadr/commits/develop).

