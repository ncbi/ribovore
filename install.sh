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
TMPVERSION1="0.13"
TMPVERSION2="0.16"
VERSION="0.34"
DVERSION="ribotyper-$VERSION"

# ribovore
curl -k -L -o ribovore-$VERSION.zip https://github.com/nawrockie/ribovore/archive/$VERSION.zip; unzip ribovore-$VERSION.zip; rm ribovore-$VERSION.zip

# rRNA_sensor
curl -k -L -o rRNA_sensor-$TMPVERSION1.zip https://github.com/aaschaffer/rRNA_sensor/archive/$TMPVERSION1.zip; unzip rRNA_sensor-$TMPVERSION1.zip; rm rRNA_sensor-$TMPVERSION1.zip

# epn-options, epn-ofile epn-test
for m in epn-options epn-ofile epn-test; do 
    curl -k -L -o $m-$DVERSION.zip https://github.com/nawrockie/$m/archive/$DVERSION.zip; unzip $m-$DVERSION.zip; rm $m-$DVERSION.zip
done
echo "Finished cloning github repos with required code."

# Install Infernal 1.1.2
# You can comment out this part if you already have Infernal installed 
# on your system.
echo "Installing Infernal 1.1.2 ... "
curl -k -L -o infernal-1.1.2.tar.gz http://eddylab.org/infernal/infernal-1.1.2.tar.gz
tar xfz infernal-1.1.2.tar.gz
cd infernal-1.1.2
sh ./configure --prefix $RIBOINSTALLDIR
make
make install
cd easel
make install
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
curl -k -L -o vecscreen_plus_taxonomy-$TMPVERSION2.zip https://github.com/aaschaffer/vecscreen_plus_taxonomy/archive/$TMPVERSION2.zip; unzip vecscreen_plus_taxonomy-$TMPVERSION2.zip; rm vecscreen_plus_taxonomy-$TMPVERSION2.zip
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
curl -k -L -o blastn.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.8.1+-x64-macosx.tar.gz
tar xfz blastn.tar.gz
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
echo "export RIBODIR=\"$RIBOINSTALLDIR/ribovore-$VERSION\""
echo "export RIBOINFERNALDIR=\"$RIBOINSTALLDIR/bin\""
echo "export RIBOEASELDIR=\"$RIBOINSTALLDIR/bin\""
echo "export RIBOBLASTDIR=\"/usr/bin\""
echo "export RIBOTIMEDIR=\"/usr/bin\""
echo "export VECPLUSDIR=\"$RIBOINSTALLDIR/vecscreen_plus_taxonomy-$TMPVERSION2\""
echo "export SENSORDIR=\"$RIBOINSTALLDIR/rRNA_sensor-$TMPVERSION1\""
echo "export EPNOPTDIR=\"$RIBOINSTALLDIR/epn-options-$DVERSION\""
echo "export EPNOFILEDIR=\"$RIBOINSTALLDIR/epn-ofile-$DVERSION\""
echo "export EPNTESTDIR=\"$RIBOINSTALLDIR/epn-test-$DVERSION\""
echo "export PERL5LIB=\"\$RIBODIR:\$EPNOPTDIR:\$EPNOFILEDIR:\$EPNTESTDIR:\$PERL5LIB\""
echo "export PATH=\"\$RIBODIR:\$PATH\""
echo "export BLASTDB=\"\$SENSORDIR:\$BLASTDB\""
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
echo "setenv RIBODIR \"$RIBOINSTALLDIR/ribovore-$VERSION\""
echo "setenv RIBOINFERNALDIR \"$RIBOINSTALLDIR/bin\""
echo "setenv RIBOEASELDIR \"$RIBOINSTALLDIR/bin\""
echo "setenv RIBOBLASTDIR \"/usr/bin\""
echo "setenv RIBOTIMEDIR \"/usr/bin\""
echo "setenv VECPLUSDIR \"$RIBOINSTALLDIR/vecscreen_plus_taxonomy-$TMPVERSION2\""
echo "setenv SENSORDIR \"$RIBOINSTALLDIR/rRNA_sensor-$TMPVERSION1\""
echo "setenv EPNOPTDIR \"$RIBOINSTALLDIR/epn-options-$DVERSION\""
echo "setenv EPNOFILEDIR \"$RIBOINSTALLDIR/epn-ofile-$DVERSION\""
echo "setenv EPNTESTDIR \"$RIBOINSTALLDIR/epn-test-$DVERSION\""
echo "setenv PERL5LIB \"\$RIBODIR\":\"\$EPNOPTDIR\":\"\$EPNOFILEDIR\":\"\$EPNTESTDIR\":\"\$PERL5LIB\""
echo "setenv PATH \"\$RIBODIR\":\"\$PATH\""
echo "setenv BLASTDB \"\$SENSORDIR\":\"\$BLASTDB\""
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
