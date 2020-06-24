#!/bin/bash
# The previous line forces this script to be run with bash, regardless of user's 
# shell.
#
# EPN, Thu Jan 17 12:59:26 2019
#
# A shell script for installing ribovore its dependencies
# for ribosomal RNA sequence analysis.
#
RIBOINSTALLDIR=$PWD
VERSION="0.40"
RVERSION="ribovore-$VERSION"
BLASTVERSION="2.8.1"

# The following line will make the script fail if any commands fail
set -e
#
echo "------------------------------------------------"
echo "INSTALLING RIBOVORE $VERSION"
echo "------------------------------------------------"
echo ""
echo "************************************************************"
echo "IMPORTANT: BEFORE YOU WILL BE ABLE TO RUN RIBOVORE"
echo "SCRIPTS, YOU NEED TO FOLLOW THE INSTRUCTIONS OUTPUT AT"
echo "THE END OF THIS SCRIPT TO UPDATE YOUR ENVIRONMENT VARIABLES."
echo "************************************************************"
echo ""
echo "Determining current directory ... "
echo "Set RIBOINSTALLDIR as current directory ($RIBOINSTALLDIR)."
echo "------------------------------------------------"
# Clone what we need from GitHub (these are all public)

# ribovore
echo "Installing ribovore ... "
curl -k -L -o ribovore-$RVERSION.zip https://github.com/nawrockie/ribovore/archive/$RVERSION.zip; unzip ribovore-$RVERSION.zip; mv ribovore-$RVERSION ribovore; rm ribovore-$RVERSION.zip
# for a test build of a release, comment out above curl and uncomment block below
# ----------------------------------------------------------------------------
#git clone https://github.com/nawrockie/ribovore.git ribovore
#cd ribovore
#git checkout release-$VERSION
#rm -rf .git
#cd ..
# ----------------------------------------------------------------------------

# rRNA_sensor
echo "Installing rRNA_sensor ... "
curl -k -L -o rRNA_sensor-$RVERSION.zip https://github.com/aaschaffer/rRNA_sensor/archive/$RVERSION.zip; unzip rRNA_sensor-$RVERSION.zip; mv rRNA_sensor-$RVERSION rRNA_sensor; rm rRNA_sensor-$RVERSION.zip

# epn-options, epn-ofile epn-test
echo "Installing required perl modules ... "
for m in epn-options epn-ofile epn-test; do 
    curl -k -L -o $m-$RVERSION.zip https://github.com/nawrockie/$m/archive/$RVERSION.zip; unzip $m-$RVERSION.zip; mv $m-$RVERSION $m; rm $m-$RVERSION.zip
done

##########BEGINNING OF LINES TO COMMENT OUT TO SKIP INFERNAL INSTALLATION##########################
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
echo "Finished installing Infernal 1.1.2"
echo "------------------------------------------------"
##########END OF LINES TO COMMENT OUT TO SKIP INFERNAL INSTALLATION##########################
# 
################
# Output the final message:
echo ""
echo ""
echo "********************************************************"
echo "IMPORTANT INFORMATION ABOUT FURTHER INSTALLATION STEPS"
echo "REQUIRED FOR FULL FUNCTIONALITY OF RIBOVORE:"
echo ""
echo "If you want to use the ribosensor.pl script you will need to"
echo "have blastn installed. If you want to use the ribodbmaker.pl"
echo "script you will need to have blastn and vecscreen_plus_taxonomy"
echo "installed. See below for instructions."
echo ""
echo "To install blastn, run the script 'install-optional-blastn-macosx.sh'"
echo "or 'install-optional-blastn-linux.sh' depending on your OS, and follow"
echo "the instructions output from that command to change the RIBOBLASTDIR"
echo " environment variable. That will install blast version $BLASTVERSION"
echo "which is compatible with this version of ribovore. Alternatively,"
echo "if you already have blastn installed and want to use that version,"
echo "add a line to the end of your .bashrc or .cshrc file that updates the"
echo "environment variable RIBOBLASTDIR to the directory the blastn"
echo "executable is."
echo ""
echo "To install vecscreen_plus_taxonomy, run the script"
echo " 'install-optional-vecscreen_plus_taxonomy-linux.sh' and follow"
echo "the instructions output from that command to change the RIBOBLASTDIR"
echo "environment variable. Note that vecscreen_plus_taxonomy can"
echo "only be installed on Linux systems, which means that ribodbmaker.pl"
echo "cannot currently be run on non-Linux systems (including Mac OS/X)."
echo ""
echo "********************************************************"
echo "The final step is to update your environment variables."
echo "(See ribovore/README.txt for more information.)"
echo ""
echo "If you are using the bash shell, add the following"
echo "lines to the end of the '.bashrc' file in your home directory:"
echo ""
echo "export RIBODIR=$RIBOINSTALLDIR/ribovore"
echo "export RIBOINFERNALDIR=$RIBOINSTALLDIR/bin"
echo "export RIBOEASELDIR=$RIBOINSTALLDIR/bin"
echo "export RIBOTIMEDIR=/usr/bin"
echo "export SENSORDIR=$RIBOINSTALLDIR/rRNA_sensor"
echo "export EPNOPTDIR=$RIBOINSTALLDIR/epn-options"
echo "export EPNOFILEDIR=$RIBOINSTALLDIR/epn-ofile"
echo "export EPNTESTDIR=$RIBOINSTALLDIR/epn-test"
echo "export PERL5LIB=\"\$RIBODIR\":\"\$EPNOPTDIR\":\"\$EPNOFILEDIR\":\"\$EPNTESTDIR\":\"\$PERL5LIB\""
echo "export PATH=\"\$RIBODIR\":\"\$SENSORDIR\":\"\$PATH\""
echo "export BLASTDB=\"\$SENSORDIR\":\"\$BLASTDB\""
echo ""
echo "After adding the export lines to the end of your .bashrc file,"
echo "source that file to update your current environment with the command:"
echo ""
echo "source ~/.bashrc"
echo ""
echo "---"
echo "If you are using the C shell, add the following"
echo "lines to the end of the '.cshrc' file in your home directory:"
echo ""
echo "setenv RIBODIR $RIBOINSTALLDIR/ribovore-$VERSION"
echo "setenv RIBOINFERNALDIR $RIBOINSTALLDIR/bin"
echo "setenv RIBOEASELDIR $RIBOINSTALLDIR/bin"
echo "setenv RIBOTIMEDIR /usr/bin"
echo "setenv SENSORDIR $RIBOINSTALLDIR/rRNA_sensor"
echo "setenv EPNOPTDIR $RIBOINSTALLDIR/epn-options"
echo "setenv EPNOFILEDIR $RIBOINSTALLDIR/epn-ofile"
echo "setenv EPNTESTDIR $RIBOINSTALLDIR/epn-test"
echo "setenv PERL5LIB \"\$RIBODIR\":\"\$EPNOPTDIR\":\"\$EPNOFILEDIR\":\"\$EPNTESTDIR\":\"\$PERL5LIB\""
echo "setenv PATH \"\$RIBODIR\":\"\$SENSORDIR\":\"\$PATH\""
echo "setenv BLASTDB \"\$SENSORDIR\":\"\$BLASTDB\""
echo ""
echo "After adding the setenv lines to the end of your .bashrc file,"
echo "source that file to update your current environment with the command:"
echo ""
echo "source ~/.cshrc"
echo ""
echo "(To determine which shell you use, type: 'echo \$SHELL')"
echo ""
echo ""
