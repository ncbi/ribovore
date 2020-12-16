#  <a name="top"></a> Ribovore installation instructions

* [Installation using `install.sh`](#install.sh)
* [Setting environment variables](#environment)
* [Verifying successful installation](#tests)
* [Further information](#further)

---
## Ribovore installation using the `install.sh` script <a name="install"></a>

The file `install.sh` is an executable file for installing Ribovore
and its dependencies. That file is located online at github.
To install the latest version of Ribovore download this file:

https://raw.githubusercontent.com/nawrockie/ribovore/master/install.sh

To download any specific release/version, for example version 1.0 download
the corresponding `install.sh` file for that release/version.

https://raw.githubusercontent.com/nawrockie/ribovore/1.0/vadr-install.sh

Copy the `install.sh` file into the directory in which you want
to install Ribovore. A good name for that directory is
`ribovore-install`. Then move into that directory and run one of the
following two commands depending on whether you are installing on a
Linux or Mac/OSX system. *Note that you if you are installing on Mac/OSX the
ribodbmaker.pl script will have limited functionality because vecscreen_plus_taxonomy
can only be installed and run on linux systems.*

```
sh ./install.sh linux
```

OR

```
sh ./install.sh macosx
```
The `linux` or `macosx` argument controls (only) the type of infernal
and blast executable files that will be installed.

The `install.sh` command will create several directories in the
current directory.  It will download and install Ribovore and the
required module libraries
[sequip](https://github.com/nawrockie/sequip), as well as the binary
executables of [Infernal](http://eddylab.org/infernal/), the NCBI
BLAST package (for either Linux or Mac/OSX), and (if Linux) the
vecscreen_plus_taxonomy package.

When `install.sh` is finished running it will print important
instructions to the screen that explain how to modify your environment
variables so that you can run the Ribovore scripts, as discussed next.

---

## Setting Ribovore environment variables <a name="environment"></a>

As mentioned above, when you run `install.sh`, instructions will be
output about how to change your environment variables so that you can
run the Ribovore scripts. Those instructions are also included below for
reference, but without the actual path to where you ran `install.sh`
(below it is replaced with `<full path to directory in which you ran
install.sh>`)

---

### Instructions for setting environment variables output by `install.sh`

```
********************************************************
The final step is to update your environment variables.
(See https://github.com/nawrockie/ribovore/blob/1.0/documentation/install.md for more information.)

If you are using the bash or zsh shell (zsh is default in MacOS/X as
of v10.15 (Catalina)), add the following lines to the end of your
'.bashrc' or '.zshrc' file in your home directory:

export VADRINSTALLDIR=<full path to directory in which you ran vadr-install.sh>
export VADRSCRIPTSDIR="$VADRINSTALLDIR/vadr"
export VADRMODELDIR="$VADRINSTALLDIR/vadr-models"
export VADRINFERNALDIR="$VADRINSTALLDIR/infernal/binaries"
export VADREASELDIR="$VADRINSTALLDIR/infernal/binaries"
export VADRHMMERDIR="$VADRINSTALLDIR/hmmer/binaries"
export VADRBIOEASELDIR="$VADRINSTALLDIR/Bio-Easel"
export VADRSEQUIPDIR="$VADRINSTALLDIR/sequip"
export VADRBLASTDIR="$VADRINSTALLDIR/ncbi-blast/bin"
export PERL5LIB="$VADRSCRIPTSDIR":"$VADRSEQUIPDIR":"$VADRBIOEASELDIR/blib/lib":"$VADRBIOEASELDIR/blib/arch":"$PERL5LIB"
export PATH="$VADRSCRIPTSDIR":"$PATH"

After adding the export lines to your .bashrc or .zshrc file, source that file
to update your current environment with the command:

source ~/.bashrc

OR

source ~/.zshrc

---
If you are using the C shell, add the following
lines to the end of your '.cshrc' file in your home
directory:

setenv VADRINSTALLDIR "<full path to directory in which you ran vadr-install.sh>"
setenv VADRSCRIPTSDIR "$VADRINSTALLDIR/vadr"
setenv VADRMODELDIR "$VADRINSTALLDIR/vadr-models"
setenv VADRINFERNALDIR "$VADRINSTALLDIR/infernal/binaries"
setenv VADRHMMERDIR "$VADRHMMERDIR/hmmer/binaries"
setenv VADREASELDIR "$VADRINSTALLDIR/infernal/binaries"
setenv VADRBIOEASELDIR "$VADRINSTALLDIR/Bio-Easel"
setenv VADRSEQUIPDIR "$VADRINSTALLDIR/sequip"
setenv VADRBLASTDIR "$VADRINSTALLDIR/ncbi-blast/bin"
setenv PERL5LIB "$VADRSCRIPTSDIR":"$VADRSEQUIPDIR":"$VADRBIOEASELDIR/blib/lib":"$VADRBIOEASELDIR/blib/arch":"$PERL5LIB"
setenv PATH "$VADRSCRIPTSDIR":"$PATH"

After adding the setenv lines to your .cshrc file, source that file
to update your current environment with the command:

source ~/.cshrc

(To determine which shell you use, type: 'echo $SHELL')


********************************************************
```
---

### If you get an error about `PERL5LIB` being undefined...

If you use bash or zsh, change the PERL5LIB line in your `~/.bashrc` or
`~/.zshrc` file to:

```
export PERL5LIB="$VADRSCRIPTSDIR":"$VADRSEQUIPDIR":"$VADRBIOEASELDIR/blib/lib":"$VADRBIOEASELDIR/blib/arch"
````

or if you use C shell, change the PERL5LIB line in your `~/.cshrc`
file to:

```
setenv PERL5LIB "$VADRSCRIPTSDIR":"$VADRSEQUIPDIR":"$VADRBIOEASELDIR/blib/lib":"$VADRBIOEASELDIR/blib/arch"
```

And then execute `source ~/.bashrc`, `source ~/.zshrc`, or `source ~/.cshrc` again.

---
## Verifying successful installation with test runs<a name="tests"></a>

The VADR package includes some tests you can run to make sure that
your installation was successful and that your environment variables
are set-up correctly. 

These are several shell scripts for running tests; with respect to the
installation directory they are in the directory `vadr/testfiles/` and
start with `do-` and end with `.sh`.

At a minimum, you should run the 
`vadr/testfiles/do-install-tests-local.sh` script to make sure VADR installed
correctly. They should pass, as shown below.

The script `vadr/testfiles/do-all-tests.sh` will run all tests, but be
warned that script may take up to an hour or so to run. All the tests
should pass.

There is also special test script `do-install-tests-parallel.sh` that you
should run if you want to test if you can use the `-p` option to
`v-annotate.pl` for parallelization on a cluster.  But this test will
likely only work internally at NCBI or if you happen to have a compute
farm set-up in a similar way at NCBI. See this
[example](annotate.md#exampleparallel) for more information.
`do-install-tests-parallel.sh` is **not** run as part of `do-all-tests.sh`.

To run all tests, execute:

```
$VADRSCRIPTSDIR/testfiles/do-all-tests.sh
```

To run only the `do-install-tests-local.sh` script, execute:

```
$VADRSCRIPTSDIR/testfiles/do-install-tests-local.sh
```

This scripts can take up to several minutes to run. 
If something goes wrong, the script will likely exit quickly.

If the script fails immediately with a warning like:

`Can't locate LWP/Simple.pm in @INC (you may need to install the
LWP::Simple module)`

Or something similar but with `Inline` instead of `LWP`, then you will
need to install the perl `LWP` and/or `Inline` modules as described
[here.](#inline)

Below is an example of the expected output for
`do-install-tests-local.sh`:

```
# v-test.pl :: test VADR scripts [TEST SCRIPT]
# VADR 1.1 (May 2020)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Wed May  6 11:58:08 2020
#
# test file:                                                         /usr/local/vadr-install-dir/vadr/testfiles/noro.r10.local.testin
# output directory:                                                  vt-n10-local
# forcing directory overwrite:                                       yes [-f]
# if output files listed in testin file already exist, remove them:  yes [--rmout]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parsing test file                                  ... done. [    0.0 seconds]
##teamcity[testStarted name='annotate-noro-10-local' captureStandardOutput='true']
# Running command  1 [annotate-noro-10-local]        ... done. [   20.0 seconds]
#       checking va-noro.r10/va-noro.r10.vadr.pass.tbl                                                                ... pass
#       checking va-noro.r10/va-noro.r10.vadr.fail.tbl                                                                ... pass
#       checking va-noro.r10/va-noro.r10.vadr.sqa                                                                     ... pass
#       checking va-noro.r10/va-noro.r10.vadr.sqc                                                                     ... pass
#       checking va-noro.r10/va-noro.r10.vadr.ftr                                                                     ... pass
#       checking va-noro.r10/va-noro.r10.vadr.sgm                                                                     ... pass
#       checking va-noro.r10/va-noro.r10.vadr.mdl                                                                     ... pass
#       checking va-noro.r10/va-noro.r10.vadr.alt                                                                     ... pass
#       checking va-noro.r10/va-noro.r10.vadr.alc                                                                     ... pass
#       removing directory va-noro.r10                               ... done
##teamcity[testFinished name='annotate-noro-10-local']
#
#
# PASS: all 9 files were created correctly.
#
# Output printed to screen saved in:                   vt-n10-local.vadr.log
# List of executed commands saved in:                  vt-n10-local.vadr.cmd
# List and description of all output files saved in:   vt-n10-local.vadr.list
#
# All output files created in directory ./vt-n10-local/
#
# Elapsed time:  00:00:20.13
#                hh:mm:ss
#
[ok]
# v-test.pl :: test VADR scripts [TEST SCRIPT]
# VADR 1.1 (May 2020)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# date:    Wed May  6 11:58:28 2020
#
# test file:                                                         /usr/local/vadr-install-dir/vadr/testfiles/noro.r10.local.testin
# output directory:                                                  vt-d5-local
# forcing directory overwrite:                                       yes [-f]
# if output files listed in testin file already exist, remove them:  yes [--rmout]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Parsing test file                                  ... done. [    0.0 seconds]
##teamcity[testStarted name='annotate-dengue-5-local' captureStandardOutput='true']
# Running command  1 [annotate-dengue-5-local]       ... done. [   28.4 seconds]
#       checking va-dengue.r5/va-dengue.r5.vadr.pass.tbl                                                              ... pass
#       checking va-dengue.r5/va-dengue.r5.vadr.fail.tbl                                                              ... pass
#       checking va-dengue.r5/va-dengue.r5.vadr.sqa                                                                   ... pass
#       checking va-dengue.r5/va-dengue.r5.vadr.sqc                                                                   ... pass
#       checking va-dengue.r5/va-dengue.r5.vadr.ftr                                                                   ... pass
#       checking va-dengue.r5/va-dengue.r5.vadr.sgm                                                                   ... pass
#       checking va-dengue.r5/va-dengue.r5.vadr.mdl                                                                   ... pass
#       checking va-dengue.r5/va-dengue.r5.vadr.alt                                                                   ... pass
#       checking va-dengue.r5/va-dengue.r5.vadr.alc                                                                   ... pass
#       removing directory va-dengue.r5                              ... done
##teamcity[testFinished name='annotate-dengue-5-local']
#
#
# PASS: all 9 files were created correctly.
#
# Output printed to screen saved in:                   vt-d5-local.vadr.log
# List of executed commands saved in:                  vt-d5-local.vadr.cmd
# List and description of all output files saved in:   vt-d5-local.vadr.list
#
# All output files created in directory ./vt-d5-local/
#
# Elapsed time:  00:00:28.52
#                hh:mm:ss
#
[ok]
Success: all tests passed
```
The most important line is the final line:

```
Success: all tests passed
```

This means that the test has passed. You should see similar 
lines if you run the other tests. If you do not and need help
figuring out why, email me at eric.nawrocki@nih.gov.

---
## Further information

* [`v-annotate.pl` example usage and command-line options](annotate.md#top)
* [`v-build.pl` example usage and command-line options](build.md#top)
* [VADR output formats](formats.md#top)

---
#### Questions, comments or feature requests? Send a mail to eric.nawrocki@nih.gov.


