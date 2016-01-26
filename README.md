Collection of Miscellaneous Scripts
================================================================================

    * iMake   - GNU Make REPL.  This is a bash script written
                as a wrapper around make.  Runs `make` in the
                background and sends user input to the process.
                If the process exits with an error due to
                invalid input then it will be reloaded with
                all variable values still intact.  Also, iMake
                supports a few special commands for convenience:
                print, info, origin, value

                Sample session:

                make> # Set some variables.  What you type will
                make> # be sent verbatim to make, except for
                make> # a few select iMake commands.

                make> g = 5
                make> h = $(g)
                make> $(info $(h))
                5

                make> # Here are some iMake special commands:
                make> info h       # like $(info h)
                h
                make> info $(h)    # like $(info $(h))
                5
                make> value h      # like $(value h)
                $(g)
                make> print h      # like $(info $(h))
                5
                make> origin h     # $(info $(origin h))
                file

                make> # We can still type it the long way
                make> $(info $(origin h))
                file

                make> # Try a more complex command
                make> info $(patsubst %,%.x,$(h))
                5.x

                make> # Try an invalid command
                make> invalid_command
                ./.makepipe.6448:33: *** missing separator.  Stop.

                make> # Make has reloaded due to the error,
                make> # but our variable values from this
                make> # session are still intact:
                make> print h
                5

                make> # Now source a Makefile into the session.
                make> # (no targets are run).
                make> . src/Makefile

                make> # At this point all variables loaded
                make> # from the Makefile are available for
                make> # inspection/changing in the REPL.

                make> quit

    * recycle - Recycle Bin for Linux.  This is intended as a
                replacement for the `rm` command.  Instead of
                deleting a file it will simply move it to the
                /tmp/recycle folder (after having flattened
                the file path by replacing / with _.  It will
                place that file in a folder marked with the
                current time stamp for easy recovery.
