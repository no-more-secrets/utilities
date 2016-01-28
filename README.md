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

                # Set some variables.  What you type will
                # be sent verbatim to make, except for
                # a few select iMake commands.

                make> g = 5
                make> h = $(g)
                make> $(info $(h))
                5

                # Here are some iMake special commands:
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

                # We can still type it the long way
                make> $(info $(origin h))
                file

                # Try a more complex command
                make> info $(patsubst %,%.x,$(h))
                5.x

                # Try an invalid command
                make> invalid_command
                ./.makepipe.6448:33: *** missing separator.  Stop.

                # Make has reloaded due to the error,
                # but our variable values from this
                # session are still intact:
                make> print h
                5

                # Now source a Makefile into the session.
                # (no targets are run).
                make> . src/Makefile

                # At this point all variables loaded
                # from the Makefile are available for
                # inspection/changing in the REPL.

                make> quit

    * recycle - Recycle Bin for Linux.  This is intended as a
                replacement for the `rm` command.  Instead of
                deleting a file it will simply move it to the
                /tmp/recycle folder (after having flattened
                the file path by replacing / with _.  It will
                place that file in a folder marked with the
                current time stamp for easy recovery.
