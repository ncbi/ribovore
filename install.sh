#!/bin/bash
# EPN, Mon Dec 14 16:55:10 2020
# install.sh
# A shell script for downloading and installing Ribovore and its dependencies.
# 
# usage: 
# install.sh <"linux" or "macosx">
#
# for example:
# install.sh linux
#
# The following line will make the script fail if any commands fail
set -e 

RIBOINSTALLDIR=$PWD

# versions
VERSION="1.0"
# blast+
BVERSION="2.11.0"
# infernal
IVERSION="1.1.4"
IESLCLUSTERVERSION="1.1.2"
# dependency git tag
RVERSION="ribovore-$VERSION"

# set defaults
INPUTSYSTEM="?"

########################
# Validate correct usage
########################
# make sure correct number of cmdline arguments were used, exit if not
if [ "$#" -ne 1 ]; then
   echo "Usage: $0 <\"linux\" or \"macosx\">"
   exit 1
fi

# make sure 1st argument is either "linux" or "macosx"
if [ "$1" = "linux" ]; then
    INPUTSYSTEM="linux";
fi
if [ "$1" = "macosx" ]; then
    INPUTSYSTEM="macosx";
fi
if [ "$INPUTSYSTEM" = "?" ]; then 
   echo "Usage: $0 <\"linux\" or \"macosx\">"
   exit 1
fi
########################################################
echo "------------------------------------------------"
echo "DOWNLOADING AND BUILDING RIBOVORE $VERSION"
echo "------------------------------------------------"
echo ""
echo "************************************************************"
echo "IMPORTANT: BEFORE YOU WILL BE ABLE TO RUN RIBOVORE SCRIPTS,"
echo "YOU NEED TO FOLLOW THE INSTRUCTIONS OUTPUT AT THE END"
echo "OF THIS SCRIPT TO UPDATE YOUR ENVIRONMENT VARIABLES."
echo "************************************************************"

echo ""
echo "Determining current directory ... "
echo "Set RIBOINSTALLDIR as current directory ($RIBOINSTALLDIR)."

###########################################
# Download section
###########################################
echo "------------------------------------------------"
# ribovore
echo "Downloading ribovore ... "
#curl -k -L -o $RVERSION.zip https://github.com/nawrockie/ribovore/archive/$RVERSION.zip; unzip $RVERSION.zip; mv $RVERSION ribovore; rm $RVERSION.zip
# for a test build of a release, comment out above curl and uncomment block below
# ----------------------------------------------------------------------------
git clone https://github.com/nawrockie/ribovore.git ribovore
cd ribovore
git checkout release-$VERSION
rm -rf .git
cd ..
# ----------------------------------------------------------------------------

# rRNA_sensor
echo "Downloading rRNA_sensor ... "
#curl -k -L -o rRNA_sensor-$RVERSION.zip https://github.com/aaschaffer/rRNA_sensor/archive/$RVERSION.zip; unzip rRNA_sensor-$RVERSION.zip; mv rRNA_sensor-$RVERSION rRNA_sensor; rm rRNA_sensor-$RVERSION.zip
# ----------------------------------------------------------------------------
git clone https://github.com/aaschaffer/rRNA_sensor.git rRNA_sensor
cd rRNA_sensor
git checkout release-0.14
rm -rf .git
cd ..
# ----------------------------------------------------------------------------

# sequip
echo "Downloading sequip ... "
#curl -k -L -o sequip-$RVERSION.zip https://github.com/nawrockie/sequip/archive/$RVERSION.zip; unzip sequip-$RVERSION.zip; mv sequip-$RVERSION sequip; rm sequip-$RVERSION.zip
# to checkout a specific branch, comment out above curl and uncomment block below
# ----------------------------------------------------------------------------
git clone https://github.com/nawrockie/sequip.git sequip
cd sequip
git checkout develop
rm -rf .git
cd ..
# ----------------------------------------------------------------------------

# download two infernal binary distributions
# the first is a recent release, we'll use most programs from this release,
# the second is *only* for esl-cluster which is no longer available in current releases
# 
# - to download source distributions and build them instead of binary distributions, see 
#   'infernal block 2' below.

# ----- infernal block 1 start  -----
if [ "$INPUTSYSTEM" = "linux" ]; then
    echo "Downloading Infernal version $IVERSION for Linux"
    curl -k -L -o infernal.tar.gz http://eddylab.org/infernal/infernal-$IVERSION-linux-intel-gcc.tar.gz
    echo "Downloading Infernal version $IESLCLUSTERVERSION for Linux"
    curl -k -L -o infernal2.tar.gz http://eddylab.org/infernal/infernal-$IESLCLUSTERVERSION-linux-intel-gcc.tar.gz
else
    echo "Downloading Infernal version $IVERSION for Mac/OSX"
    curl -k -L -o infernal.tar.gz http://eddylab.org/infernal/infernal-$IVERSION-macosx-intel.tar.gz
    echo "Downloading Infernal version $IESLCLUSTERVERSION for Mac/OSX"
    curl -k -L -o infernal2.tar.gz http://eddylab.org/infernal/infernal-$IESLCLUSTERVERSION-macosx-intel.tar.gz
fi
tar xfz infernal.tar.gz
tar xfz infernal2.tar.gz
rm infernal.tar.gz
rm infernal2.tar.gz
if [ "$INPUTSYSTEM" = "linux" ]; then
    mv infernal-$IVERSION-linux-intel-gcc infernal
    mv infernal-$IESLCLUSTERVERSION-linux-intel-gcc/binaries/esl-cluster infernal/binaries/
    rm -rf infernal-$IESLCLUSTERVERSION-linux-intel-gcc
else
    mv infernal-$IVERSION-macosx-intel infernal
    mv infernal-$IESLCLUSTERVERSION-macosx-intel/binaries/esl-cluster infernal/binaries/
    rm -rf infernal-$IESLCLUSTERVERSION-macosx-intel
fi
# ----- infernal block 1 end -----

# if you'd rather download the source distros and build them yourself
# (maybe because the binaries aren't working for you for some reason)
# comment out 'infernal block 1' above and 
# uncomment 'infernal block 2' below
# ----- infernal block 2 start  -----
#echo "Downloading Infernal version $IVERSION src distribution"
#curl -k -L -o infernal.tar.gz http://eddylab.org/infernal/infernal-$IVERSION.tar.gz
#echo "Downloading Infernal version $IESLCLUSTERVERSION src distribution"
#curl -k -L -o infernal2.tar.gz http://eddylab.org/infernal/infernal-$IESLCLUSTERVERSION.tar.gz
#tar xfz infernal.tar.gz
#tar xfz infernal2.tar.gz
#rm infernal.tar.gz
#rm infernal2.tar.gz
#echo "Building Infernal ... "
#mv infernal-$IVERSION infernal
#mv infernal-$IESLCLUSTERVERSION infernal2
#cd infernal
#mkdir binaries
#sh ./configure --bindir=$PWD/binaries --prefix=$PWD
#make
#make install
#(cd easel/miniapps; make install)
#cd ..
#cd infernal2
#sh ./configure
#make
#mv easel/miniapps/esl-cluster ../infernal/binaries/
#cd ..
#rm -rf infernal2
#echo "Finished building Infernal "
# ----- infernal block 2 end -----
echo "------------------------------------------------"

# download blast binaries
if [ "$INPUTSYSTEM" = "linux" ]; then
echo "Downloading BLAST version $BVERSION for Linux"
curl -k -L -o blast.tar.gz https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/$BVERSION/ncbi-blast-$BVERSION+-x64-linux.tar.gz
else 
echo "Downloading BLAST version $BVERSION for Mac/OSX"
echo "curl -k -L -o blast.tar.gz https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/$BVERSION/ncbi-blast-$BVERSION+-x64-macosx.tar.gz"
curl -k -L -o blast.tar.gz https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/$BVERSION/ncbi-blast-$BVERSION+-x64-macosx.tar.gz
fi
tar xfz blast.tar.gz
rm blast.tar.gz
mv ncbi-blast-$BVERSION+ ncbi-blast
echo "------------------------------------------------"

# if linux, download vecscreen_plus_taxonomy
if [ "$INPUTSYSTEM" = "linux" ]; then
curl -k -L -o vecscreen_plus_taxonomy-$RVERSION.zip https://github.com/aaschaffer/vecscreen_plus_taxonomy/archive/$RVERSION.zip; 
unzip vecscreen_plus_taxonomy-$RVERSION.zip; 
mv vecscreen_plus_taxonomy-$RVERSION vecscreen_plus_taxonomy
rm vecscreen_plus_taxonomy-$RVERSION.zip
(cd vecscreen_plus_taxonomy/scripts; gunzip srcchk.gz; gunzip vecscreen.gz;)
else 
echo "Not installing vecscreen_plus_taxonomy (only avaiable for Linux)"
fi
echo "------------------------------------------------"

###############################################
# Message about setting environment variables
###############################################
echo ""
echo ""
echo "If you want to use the ribodbmaker.pl script you will need to"
echo "have vecscreen_plus_taxonomy installed. See below for instructions."
echo ""
echo "To install vecscreen_plus_taxonomy, run the script"
echo " 'install-optional-vecscreen_plus_taxonomy-linux.sh' and follow"
echo "the instructions output from that command to change the RIBOBLASTDIR"
echo "environment variable. Note that vecscreen_plus_taxonomy can"
echo "only be installed on Linux systems, which means that ribodbmaker.pl"
echo "cannot currently be run on non-Linux systems (including Mac OS/X)."
echo ""
echo "********************************************************"
echo ""
echo "The final step is to update your environment variables."
echo "(See ribovore/README.txt for more information.)"
echo ""
echo "If you are using the bash or zsh shell (zsh is default in MacOS/X as"
echo "of v10.15 (Catalina)), add the following lines to the end of your"
echo "'.bashrc' or '.zshrc' file in your home directory:"
echo ""
echo "export RIBOINSTALLDIR=\"$RIBOINSTALLDIR\""
echo "export RIBOSCRIPTSDIR=\"\$RIBOINSTALLDIR/ribovore\""
echo "export RIBOINFERNALDIR=\"\$RIBOINSTALLDIR/infernal/binaries\""
echo "export RIBOEASELDIR=\"\$RIBOINSTALLDIR/infernal/binaries\""
echo "export RIBOSEQUIPDIR=\"\$RIBOINSTALLDIR/sequip\""
echo "export RIBOBLASTDIR=\"\$RIBOINSTALLDIR/ncbi-blast/bin\""
echo "export RIBOTIMEDIR=/usr/bin"
echo "export RRNASENSORDIR=\"\$RIBOINSTALLDIR/rRNA_sensor\""
echo "export PERL5LIB=\"\$RIBOSCRIPTSDIR\":\"\$RIBOSEQUIPDIR\":\"\$PERL5LIB\""
echo "export PATH=\"\$RIBOSCRIPTSDIR\":\"\$RIBOBLASTDIR\":\"\$RRNASENSORDIR\":\"\$PATH\""
if [ "$INPUTSYSTEM" = "linux" ]; then
echo "export VECPLUSDIR=\"\$RIBOINSTALLDIR/vecscreen_plus_taxonomy\""
echo "export BLASTDB=\"\$VECPLUSDIR/univec-files\":\"\$RRNASENSORDIR\":\"\$BLASTDB\""
else
echo "export BLASTDB=\"\$RRNASENSORDIR\":\"\$BLASTDB\""
fi
echo ""
echo "After adding the export lines to your .bashrc or .zshrc file, source that file"
echo "to update your current environment with the command:"
echo ""
echo "source ~/.bashrc"
echo ""
echo "OR"
echo ""
echo "source ~/.zshrc"
echo ""
echo "---"
echo "If you are using the C shell, add the following"
echo "lines to the end of your '.cshrc' file in your home"
echo "directory:"
echo ""
echo "setenv RIBOINSTALLDIR \"$RIBOINSTALLDIR\""
echo "setenv RIBOSCRIPTSDIR \"\$RIBOINSTALLDIR/ribovore\""
echo "setenv RIBOINFERNALDIR \"\$RIBOINSTALLDIR/bin\""
echo "setenv RIBOEASELDIR \"\$RIBOINSTALLDIR/bin\""
echo "setenv RIBOSEQUIPDIR \"\$RIBOINSTALLDIR/sequip\""
echo "setenv RIBOBLASTDIR \"\$RIBOINSTALLDIR/ncbi-blast/bin\""
echo "setenv RIBOTIMEDIR /usr/bin"
echo "setenv RRNASENSORDIR \"$RIBOINSTALLDIR/rRNA_sensor\""
echo "setenv PERL5LIB \"\$RIBOSCRIPTSDIR\":\"\$RIBOSEQUIPDIR\":\"\$PERL5LIB\""
echo "setenv PATH \"\$RIBOSCRIPTSDIR\":\"\$RIBOBLASTDIR\":\"\$RRNASENSORDIR\":\"\$PATH\""
if [ "$INPUTSYSTEM" = "linux" ]; then
echo "setenv VECPLUSDIR \"\$RIBOINSTALLDIR/vecscreen_plus_taxonomy\""
echo "setenv BLASTDB \"\$VECPLUSDIR/univec-files\":\"\$RRNASENSORDIR\":\"\$BLASTDB\""
else
echo "setenv BLASTDB \"\$RRNASENSORDIR\":\"\$BLASTDB\""
fi
echo "After adding the setenv lines to your .cshrc file, source that file"
echo "to update your current environment with the command:"
echo ""
echo "source ~/.cshrc"
echo ""
echo "(To determine which shell you use, type: 'echo \$SHELL')"
echo ""
echo "********************************************************"
echo ""
