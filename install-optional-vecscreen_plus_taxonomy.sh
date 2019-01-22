#!/bin/bash
# The previous line forces this script to be run with bash, regardless of user's 
# shell.
#
# EPN, Tue Jan 22 09:27:15 2019
#
# A shell script for installing vecscreen_plus_taxonomy
# for use with ribovore for ribosomal RNA sequence analysis.
#
# The following line will make the script fail if any commands fail
set -e
#
echo "------------------------------------------------"
echo "Determining current directory ... "
RIBOINSTALLDIR=$PWD
TMPVERSION2="0.16"
echo "Set RIBOINSTALLDIR as current directory ($RIBOINSTALLDIR)."

echo "------------------------------------------------"
echo "Installing vecscreen_plus_taxonomy ... "
curl -k -L -o vecscreen_plus_taxonomy-$TMPVERSION2.zip https://github.com/aaschaffer/vecscreen_plus_taxonomy/archive/$TMPVERSION2.zip; unzip vecscreen_plus_taxonomy-$TMPVERSION2.zip; rm vecscreen_plus_taxonomy-$TMPVERSION2.zip

################
# Output the final message:
echo "The final step is to update your environment variables."
echo "(See ribovore/00README.txt for more information.)"
echo ""
echo "If you are using the bash shell, add the following"
echo "lines to the '.bashrc' file in your home directory:"
echo ""
echo "export VECPLUSDIR=\"$RIBOINSTALLDIR/vecscreen_plus_taxonomy-$TMPVERSION2\""
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
echo "setenv VECPLUSDIR \"$RIBOINSTALLDIR/vecscreen_plus_taxonomy-$TMPVERSION2\""
echo ""
echo "After adding the setenv lines to your .bashrc file, source that file"
echo "to update your current environment with the command:"
echo ""
echo "source ~/.cshrc"
echo ""
echo "(To determine which shell you use, type: 'echo \$$SHELL')"
echo ""
echo ""
echo ""
