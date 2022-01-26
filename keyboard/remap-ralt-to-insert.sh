#!/bin/bash
# Rebind the right alt key to insert. This is useful for small
# keyboards that don't have an insert key.
set -eo pipefail

# You can find keycodes by running the `xev` command.
RIGHT_ALT_KEYCODE=108

# 1. Key
# 2. Shift+Key
# 3. Mode_switch+Key
# 4. Mode_switch+Shift+Key
# 5. ISO_Level3_Shift+Key
# 6. ISO_Level3_Shift+Shift+Key
xmodmap -e "keycode $RIGHT_ALT_KEYCODE = Insert Insert Insert Insert Insert Insert"