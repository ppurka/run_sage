run_sage
========

Pick and execute one version of Sage from many different installed versions.

While developing for [Sage](http://sagemath.org), we often have multiple
versions of Sage installed. It would be really useful if the version of
Sage that is desired to be run can be chosen at run time. Additionally, the
process is run with ulimit to ensure that it does not exceed certain memory
limits.

The following files are present in the repository.

1. `sage` - This is an executable file that must be configured at the
   very top of the file. The first variable in the file `MY_SAGE_DIR`
   must be configured before the script will successfully run. This
   directory must point to the directory where the sage installations
   are present.

2. `Sage.desktop` - This is a Linux desktop file. The `Icon` field
   within the file must be provided with the full path to a Sage icon.
   This file must be copied to `$HOME/.local/share/applications`.
   Thereafter, it will appear in your desktop environment's application
   menu under Office or Education. When the menu is used, the Sage
   notebook will be launched by executing Sage in a terminal.

User configurable variables
---------------------------

The following variables at the top of the script are user configurable.

1. `MY_SAGE_DIR` - This variable stores the directory where all the sage
   versions are installed. For instance, sage-5.8 may be installed as
   `$MY_SAGE_DIR/sage-5.8`. This variable must be set.

2. `MAX_MEMORY` - This variable stores the maximum amount of virtual memory
   that is allowed for the Sage process. This is used to set the maximum
   memory by running:

    ulimit -v $MAX_MEMORY

   This prevents some very computational process from bringing down the
   whole system. The default amount is set to half the RAM present in the
   system.

3. `TERMINAL` - This variable sets the terminal that is used if the script
   is called from a desktop file. It need not be set. The script will
   default to at least `xterm` in case it doesn't find some other terminal.

