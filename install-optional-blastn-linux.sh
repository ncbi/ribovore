#!/bin/bash
# The previous line forces this script to be run with bash, regardless of user's 
# shell.
#
# EPN, Tue Jan 22 12:54:29 2019
#
# A shell script for installing blastn (linux)
# for use with ribovore for ribosomal RNA sequence analysis.
#
BLASTVERSION="2.8.1"
VERSION="0.34"

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
# For Linux: 
#~~~~~~~~~~~~~
echo "Installing blastn version $BLASTVERSION for linux ... "
 curl -o blastn.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.8.1+-x64-linux.tar.gz
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
echo "(See ribovore/00README.txt for more information.)"
echo ""
echo "If you are using the bash shell, add the following"
echo "lines to the '.bashrc' file in your home directory:"
echo ""
echo "export RIBOBLASTDIR=\"/usr/bin\""
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
echo "setenv RIBOBLASTDIR \"/usr/bin\""
echo "setenv BLASTDB \"\$SENSORDIR\":\"\$BLASTDB\""
echo ""
echo "After adding the setenv lines to your .bashrc file, source that file"
echo "to update your current environment with the command:"
echo ""
echo "source ~/.cshrc"
echo ""
echo "(To determine which shell you use, type: 'echo \$$SHELL')"
echo ""
echo ""
