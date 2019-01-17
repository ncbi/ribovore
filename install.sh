#!/bin/bash
# The previous line forces this script to be run with bash, regardless of user's 
# shell.
#
# EPN, Thu Jan 17 12:59:26 2019
#
# A shell script for installing ribovore its dependencies
# for ribosomal RNA sequence analysis.
#
# The following line will make the script fail if any commands fail
set -e
#
echo "------------------------------------------------"
echo "Determining current directory ... "
RIBOINSTALLDIR=$PWD
echo "Set RIBOINSTALLDIR as current directory ($RIBOINSTALLDIR)."

echo "------------------------------------------------"
echo "Cloning github repos with required code ... "
# Clone what we need from GitHub (these are all public)
# ribovore
git clone https://github.com/nawrockie/ribovore.git
#
# rRNA_sensor
git clone https://github.com/aaschaffer/rRNA_sensor/archive/ribovore-0.35.zip
#
# epn-options
git clone https://github.com/nawrockie/epn-options/archive/ribovore-0.35.zip
#
# epn-ofile
git clone https://github.com/nawrockie/epn-ofile/archive/ribovore-0.35.zip
#
# epn-test
git clone https://github.com/nawrockie/epn-test/archive/ribovore-0.35.zip
#
echo "Finished cloning github repos with required code."

# Install Infernal 1.1.2
# You can comment out this part if you already have Infernal installed 
# on your system.
echo "Installing Infernal 1.1.2 ... "
curl -o infernal.tar.gz http://eddylab.org/infernal/infernal-1.1.2.tar.gz
tar xf infernal-1.1.2.tar.gz
cd infernal-1.1.2
sh ./configure $RIBOINSTALLDIR
make
#make install
cd easel
sh ./configure $RIBOINSTALLDIR
#make install
cd $RIBOINSTALLDIR
#echo "Finished installing Infernal 1.1.2"
#echo "------------------------------------------------"
#
# Other software that is optional to install: 
# 
################
# vecscreen_plus_taxonomy
# This is only necessary if you want to run the ribodbmaker.pl program.
# To install it, uncomment the line below.
#
# git clone https://github.com/aaschaffer/vecscreen_plus_taxonomy/archive/ribovore-0.35.zip
# 
#
################
# blastn:
#
# This may already be on your system. If not, you can uncomment the
# lines below to install blastn. Only uncomment the 2 lines that
# are appropriate for your system/os.
#
# For 64-bit mac os/x:
#~~~~~~~~~~~~~
# curl -o blastn.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.8.1+-x64-macosx.tar.gz
# tar xfz blastn.tar.gz
#~~~~~~~~~~~~~
# 
# For Linux: 
#~~~~~~~~~~~~~
# curl -o blastn.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.8.1+-x64-linux.tar.gz
# tar xfz blastn.tar.gz
#~~~~~~~~~~~~~
# 
# The above commands will download the
# latest version of blast+. You may want to install version 2.8.1+
# which is known to be compatible with this version of ribovore.
# Those files are at ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.8.1/
#
################
# Output the final message:
echo "The final step is to update your environment variables."
echo "(See ribovore/00README.txt for more information.)"
echo ""
echo "If you are using the bash shell, add the following"
echo "lines to the '.bashrc' file in your home directory:"
echo ""
echo "export RIBODIR=\"$RIBOINSTALLDIR\""
echo "export RIBOINFERNALDIR=\"$RIBOINSTALLDIR/infernal-1.1.2/src\""
echo "export RIBOEASELDIR=\"$RIBOINSTALLDIR/infernal-1.1.2/easel/miniapps\""
echo "export RIBOBLASTDIR=\"/usr/bin\""
echo "export RIBOTIMEDIR=\"/usr/bin\""
echo "export VECPLUSDIR=\"$RIBOINSTALLDIR/vecscreen_plus_taxonomy\""
echo "export SENSORDIR=\"$RIBOINSTALLDIR/rRNA_sensor\""
echo "export EPNOPTDIR=\"$RIBOINSTALLDIR/epn-options\""
echo "export EPNOFILEDIR=\"$RIBOINSTALLDIR/epn-ofile\""
echo "export EPNTESTDIR=\"$RIBOINSTALLDIR/epn-test\""
echo "export PERL5LIB=\"$RIBODIR:$EPNOPTDIR:$EPNOFILEDIR:$EPNTESTDIR:$PERL5LIB\""
echo "export PATH=\"$RIBODIR:$PATH\""
echo "export BLASTDB=\"$SENSORDIR:$BLASTDB\""
echo ""
echo "Note that the above assumes your blastn executable is in /usr/bin/."
echo "If it is somewhere else, update the above line accordingly. If"
echo "blastn is not installed and you do not want to (and are okay with"
echo "not using ribosensor or ribodbmaker), then you can leave the above"
echo "RIBOBLASTDIR line alone, it won't cause any problems."
echo ""
echo "The above also assumes you haven't modified the above commands that"
echo "download from github, and download and install infernal. If you have,"
echo "(for example, if infernal is already installed and you skipped that"
echo "step by commenting it out) then adjust the above as necessary."
echo ""
echo "After adding the export lines to your .bashrc file, source that file"
echo "to update your current environment with the command:"
echo ""
echo "source ~/.bashrc"
echo ""
echo "---"
echo "If you are using the C shell, add the following"
echo "lines to the '.cshrc' file in your home directory:"
echo ""
echo "setenv RIBODIR \"$RIBOINSTALLDIR\""
echo "setenv RIBOINFERNALDIR \"$RIBOINSTALLDIR/infernal-1.1.2/src\""
echo "setenv RIBOEASELDIR \"$RIBOINSTALLDIR/infernal-1.1.2/easel/miniapps\""
echo "setenv RIBOBLASTDIR \"/usr/bin\""
echo "setenv RIBOTIMEDIR \"/usr/bin\""
echo "setenv VECPLUSDIR \"$RIBOINSTALLDIR/vecscreen_plus_taxonomy\""
echo "setenv SENSORDIR \"$RIBOINSTALLDIR/rRNA_sensor\""
echo "setenv EPNOPTDIR \"$RIBOINSTALLDIR/epn-options\""
echo "setenv EPNOFILEDIR \"$RIBOINSTALLDIR/epn-ofile\""
echo "setenv EPNTESTDIR \"$RIBOINSTALLDIR/epn-test\""
echo "setenv PERL5LIB \"$RIBODIR\":\"$EPNOPTDIR\":\"$EPNOFILEDIR\":\"$EPNTESTDIR\":\"$PERL5LIB\""
echo "setenv PATH \"$RIBODIR\":\"$PATH\""
echo "setenv BLASTDB \"$SENSORDIR\":\"$BLASTDB\""
echo ""
echo "And see the notes above after the export commands about blastn and"
echo "infernal and make changes as necessary."
echo ""
echo "After adding the setenv lines to your .bashrc file, source that file"
echo "to update your current environment with the command:"
echo ""
echo "source ~/.cshrc"
echo ""
echo "(To determine which shell you use, type: 'echo \$$SHELL')"
echo ""
echo ""
echo "********************************************************"
echo "Unless you changed the install.sh file prior to running"
echo "it, blastn nor vecscreen_plus_taxonomy was installed. If"
echo "you want to install those (blastn is required to run ribosensor.pl"
echo "and ribodbmaker.pl, and vecscreen_plus_taxonomy is required"
echo "to run ribodbmaker.pl) read all the comments in the install.sh"
echo "file."
echo "********************************************************"
echo ""
