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
BLASTVERSION="2.8.1"

# ribovore
curl -k -L -o ribovore-$VERSION.zip https://github.com/nawrockie/ribovore/archive/$VERSION.zip; unzip ribovore-$VERSION.zip; rm ribovore-$VERSION.zip

# rRNA_sensor
curl -k -L -o rRNA_sensor-$TMPVERSION1.zip https://github.com/aaschaffer/rRNA_sensor/archive/$TMPVERSION1.zip; unzip rRNA_sensor-$TMPVERSION1.zip; rm rRNA_sensor-$TMPVERSION1.zip

# epn-options, epn-ofile epn-test
for m in epn-options epn-ofile epn-test; do 
    curl -k -L -o $m-$DVERSION.zip https://github.com/nawrockie/$m/archive/$DVERSION.zip; unzip $m-$DVERSION.zip; rm $m-$DVERSION.zip
done
echo "Finished cloning github repos with required code."

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
#echo "Finished installing Infernal 1.1.2"
#echo "------------------------------------------------"
##########END OF LINES TO COMMENT OUT TO SKIP INFERNAL INSTALLATION##########################
#
# Other software that is optional to install: 
# 
# vecscreen_plus_taxonomy
# This is only necessary if you want to run the ribodbmaker.pl program.
# To install it, uncomment the line below.
#
##########BEGINNING OF LINES TO UNCOMMENT TO INSTALL vecscreen_plus_taxonomy##########################
curl -k -L -o vecscreen_plus_taxonomy-$TMPVERSION2.zip https://github.com/aaschaffer/vecscreen_plus_taxonomy/archive/$TMPVERSION2.zip; unzip vecscreen_plus_taxonomy-$TMPVERSION2.zip; rm vecscreen_plus_taxonomy-$TMPVERSION2.zip
##########END OF LINES TO UNCOMMENT TO INSTALL vecscreen_plus_taxonomy##########################
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
##########BEGINNING OF LINES TO UNCOMMENT TO INSTALL blastn FOR MAC OS/X##########################
curl -k -L -o blastn.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/$BLASTVERSION/ncbi-blast-$BLASTVERSION+-x64-macosx.tar.gz
tar xfz blastn.tar.gz
##########END OF LINES TO UNCOMMENT TO INSTALL blastn FOR MAC OS/X##########################
#~~~~~~~~~~~~~
# 
# For Linux: 
#~~~~~~~~~~~~~
##########BEGINNING OF LINES TO UNCOMMENT TO INSTALL blastn FOR LINUX##########################
# curl -o blastn.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.8.1+-x64-linux.tar.gz
# tar xfz blastn.tar.gz
##########END OF LINES TO UNCOMMENT TO INSTALL blastn FOR LINUX##########################
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
echo "IMPORTANT INFORMATION ABOUT Infernal, blastn AND vecscreen_plus_taxonomy"
echo "that may mean you should change some of the above lines for setting"
echo "the environment variables in your .bashrc or .cshrc files:"
echo ""
echo "Unless you changed the install.sh file prior to running"
echo "it, infernal-1.1.2 was installed, but neither blastn nor"
echo "vecscreen_plus_taxonomy was installed. If you already"
echo "have blastn installed, you can update the RIBOBLASTDIR"
echo "environment variable to where the blastn executable is."
echo ""
echo "If you want to use the ribosensor.pl script, you will need to"
echo "have blastn installed. If you want to use the ribodbmaker.pl"
echo "script you will need to have blastn and vecscreen_plus_taxonomy"
echo "installed. See below for instructions."
echo ""
echo "If you want to have this install.sh script install blastn, open the"
echo "file install.sh and look for the text: \"BEGINNING OF LINES TO UNCOMMENT\""
echo "TO INSTALL blastn\" and uncomment (by removing the first '#' character)"
echo "either the Mac OS/X lines or the Linux lines depending on your OS."
echo "If you do that you'll want to update RIBOBLASTDIR to"
echo "$RIBOINSTALLDIR/ncbi-blast-$BLASTVERSION\"".
echo ""
echo "If blastn is not installed and you do *not* want to (and are okay with"
echo "not using ribosensor or ribodbmaker), then you can leave the above"
echo "RIBOBLASTDIR line alone, it won't cause any problems." 
echo "" 
echo "If you want to have this install.sh script install vecscreen_plus_taxonomy"
echo "open the file install.sh and look for the text: \"BEGINNING OF LINES TO\""
echo "UNCOMMENT TO INSTALL vecscreen_plus_taxonomy\" and uncomment (by removing"
echo " the first '#' character) those lines. If you do that you'll want to update"
echo "RIBOBLASTDIR to $RIBOINSTALLDIR/vecscreen_plus_taxonomy-$TMPVERSION2\"."
echo ""
echo "If you already had infernal installed, and want to delete the version you"
echo "just installed, you can delete the copy in $RIBOINSTALLDIR. If you do that"
echo "(or you skipped the infernal installation by commenting out the relevant"
echo "lines), you will need to update the RIBOINFERNALDIR and RIBOEASELDIR"
echo "environment variables to the paths where you have infernal-1.1.2 executables"
echo "(e.g. cmsearch) and easel executables (e.g. esl-sfetch) installed."
echo ""
echo "********************************************************"
echo ""
