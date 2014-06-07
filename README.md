run_sage
========

Pick and execute one version of Sage from many different installed versions.

While developing for [Sage](http://sagemath.org), we often have multiple
versions of Sage installed. It would be really useful if the version of
Sage that is desired to be run can be chosen at run time. Additionally, the
process is run with ulimit to ensure that it does not exceed certain memory
limits.

Installation
------------
To install it system-wide perform the following commands. First, remove
any `sage` links you have already installed in `/usr/local/bin`.  This is
because this script is called `sage` and simply copying it might overwrite
any installed script or link called `sage`.

Now, run the following commands, assuming you are in the `run_sage`
directory and you are logged in as _root_. Alternatively, you may prefix
each install command with `sudo `.

    install -D -m 755 ./sage /usr/local/bin/sage
    install -D -m 644 ./sage48x48.png /usr/share/pixmaps/sage48x48.png
    install -D -m 644 ./Sage.desktop /usr/share/applications/Sage.desktop

To install it in your home directory, issue the same commands, taking care
to remove any previously installed script called `sage` in your home
directory. Make sure to add that path to your `$PATH` environment variable.

    install -D -m 755 ./sage ~/path/to/sage
    install -D -m 644 ./sage48x48.png ~/.local/share/icons/sage48x48.png
    install -D -m 644 ./Sage.desktop ~/.local/share/applications/Sage.desktop

Behavior
--------

The behavior of the script is as follows. All the arguments it receives are
passed on to a Sage process. It tries to do "The Right Thing" depending on
the argument that is passed to the script.

1. _First run_: At the very first time, run it once so that it creates the configuration
   files and then set the variable `my_sage_dir` in the configuration file.

2. If it is run from a graphical interface, or from the desktop file, then
   it opens a terminal process and runs itself in the terminal.

3. If there are no arguments, or the first argument is `-n` or `--notebook`
   then the script provides the user with a selection of the versions of
   Sage that are installed. Once the user selects the Sage version, the
   corresponding Sage is launched with the rest of the arguments. It also
   writes this version of Sage into a config file in
   `$HOME/.config/sage.config`.

4. If any other argument is present, then the script first tries to run the
   Sage version that is present in the config file. If the config file is
   empty, or if the corresponding Sage installation is not found, then the
   script tries the first Sage version that it finds installed. So, from
   the perspective of the user, it behaves as if there was no intermediary
   script between the Sage binary and the user command and as if the user
   had run that Sage version directly.

5. Irrespective of whether 3. or 4. ensues, the Sage process is run under
   `ulimit`.

The following files are present in the repository.

1. `sage` - This is an executable file that must be configured at the
   very top of the file. The first variable `my_sage_dir` in the
   configuration file `$HOME/.config/run_sage.conf` must be configured
   before the script will successfully run. This directory must point to
   the directory where the sage installations are present.

2. `Sage.desktop` - This is a Linux desktop file.  This file must be copied
   to either the `$HOME/.local/share/applications` directory or to the
   `/usr/share/applications` directory.  Thereafter, it will appear in
   your desktop environment's application menu under Office or Education.
   When the menu is used, the Sage notebook will be launched by executing
   Sage in a terminal.

3. `sage48x48.png` - This is the Sage icon which must be copied to either
   `$HOME/.local/share/icons` directory or to the `/usr/share/pixmaps`
   directory.

User configurable variables
---------------------------

The following variables in the configuration file
`$HOME/.config/run_sage.conf` are configurable. This configuration file
will be automatically created the first time the script is run.

1. `my_sage_dir` - This variable stores the directory where all the sage
   versions are installed. For instance, sage-5.8 may be installed as
   `$my_sage_dir/sage-5.8`. This variable must be set.

2. `max_memory` - This variable stores the maximum amount of virtual memory
   that is allowed for the Sage process. This is used to set the maximum
   memory by running:

    ulimit -v $max_memory

   This prevents some very computational process from bringing down the
   whole system. The default amount is set to half the RAM present in the
   system. This should be specified in the form `<number>[kKmMgG]`,
   examples being `2G`, `3000m`, etc. For a limit of `1.5GB`, you can set
   this to `1500000`, or `1500000k` or `1500M` or `1.5G`.

3. `terminal` - This variable sets the terminal that is used if the script
   is called from a desktop file. It need not be set. The script will
   default to at least `xterm` in case it doesn't find some other terminal.

Demo
----

This [YouTube video](http://www.youtube.com/watch?v=iRsWHC0t-Ik) shows the behavior.

Dependencies
------------

The script depends on bash-4.0 or higher, xterm (or some other terminal),
awk, sed, grep, and dialog. On a Debian Linux derivative, or Fedora Linux
derivative, you will have to install dialog since it is not installed by
default.

