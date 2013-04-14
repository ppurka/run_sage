run_sage
========

Pick and execute one version of Sage from many different installed versions.

While developing for [Sage](http://sagemath.org), we often have multiple
versions of Sage installed. It would be really useful if the version of
Sage that is desired to be run can be chosen at run time.

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

