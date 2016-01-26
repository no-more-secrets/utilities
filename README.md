Collection of Miscellaneous Scripts
================================================================================

    * iMake   - GNU Make REPL.  This is a bash script written
                as a wrapper around make.  Runs `make` in the
                background and sends user input to the process.
                If the process exits with an error due to
                invalid input then it will be reloaded with
                all variable values still intact.

    * recycle - Recycle Bin for Linux.  This is intended as a
                replacement for the `rm` command.  Instead of
                deleting a file it will simply move it to the
                /tmp/recycle folder (after having flattened
                the file path by replacing / with _.  It will
                place that file in a folder marked with the
                current time stamp for easy recovery.
