#!/bin/bash
# The previous line forces this script to be run with bash, regardless of user's 
# shell.
#
# EPN, Tue Jan 22 12:54:43 2019
#
# A shell script for installing blastn (mac os/x)
# for use with ribovore for ribosomal RNA sequence analysis.
#
#
VERSION="0.37"
BLASTVERSION="2.8.1"
BLASTDIR="ncbi-blast-$BLASTVERSION+"

# The following line will make the script fail if any commands fail
set -e

echo "--------------------------------------------------------"
echo "INSTALLING blastn $BLASTVERSION FOR RIBOVORE $VERSION"
echo "--------------------------------------------------------"
echo ""
echo "************************************************************"
echo "IMPORTANT: BEFORE YOU WILL BE ABLE TO RUN RIBOVORE"
echo "SCRIPTS, YOU NEED TO FOLLOW THE INSTRUCTIONS OUTPUT AT"
echo "THE END OF THIS SCRIPT TO UPDATE YOUR ENVIRONMENT VARIABLES."
echo "************************************************************"
echo ""
echo "------------------------------------------------"
echo "Determining current directory ... "
RIBOINSTALLDIR=$PWD
echo "Set RIBOINSTALLDIR as current directory ($RIBOINSTALLDIR)."
################
# blastn:
#
# For 64-bit mac os/x:
#~~~~~~~~~~~~~
echo "Installing blastn version $BLASTVERSION for mac os/x ... "
curl -k -L -o blastn.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/$BLASTVERSION/ncbi-blast-$BLASTVERSION+-x64-macosx.tar.gz
tar xfz blastn.tar.gz
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
echo "(See ribovore/README.txt for more information.)"
echo ""
echo "If you are using the bash shell, add the following"
echo "lines to the end of the '.bashrc' file in your home"
echo "directory:"
echo ""
echo "export RIBOBLASTDIR=\"$RIBOINSTALLDIR/$BLASTDIR/bin\""
echo "export BLASTDB=\"\$SENSORDIR:\$BLASTDB\""
echo ""
echo "After adding the export lines to your .bashrc file, source that file"
echo "to update your current environment with the command:"
echo ""
echo "source ~/.bashrc"
echo ""
echo "---"
echo "If you are using the C shell, add the following"
echo "lines to the end of the '.cshrc' file in your home"
echo "directory:"
echo ""
echo "setenv RIBOBLASTDIR \"$RIBOINSTALLDIR/$BLASTDIR/bin\""
echo "setenv BLASTDB \"\$SENSORDIR\":\"\$BLASTDB\""
echo ""
echo "After adding the setenv lines to your .bashrc file, source that file"
echo "to update your current environment with the command:"
echo ""
echo "source ~/.cshrc"
echo ""
echo "(To determine which shell you use, type: 'echo \$SHELL')"
echo ""
echo ""
