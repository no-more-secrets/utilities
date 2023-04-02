# This describes how to forward audio over a tcp connection using
# pulseaudio. This script is not intended to be run directly.
exit

# 1. Connect to Linode with port forwarding on 4000 for pulse
# audio (arbitrary port), and also on port 5901 for VNC as usual.
# Note that the forwarding is in different directions for the
# two, since in the case of VNC, the local machine is the client
# where is for PulseAudio the local machine is the server.
ssh -L 5901:127.0.0.1:5901 \
    -R 4000:127.0.0.1:4000 \
    linode

# 2. Now there are two possibilities for connecting the tcp port
# 4000 to pulseaudio on the machine with the speakers. Do only
# one of the below two.
#
#   a. [Preferred] This will load a module that will cause
#   pulseaudio to read (using its native protocol) from the tcp
#   port 4000.
#
pactl load-module module-native-protocol-tcp \
    port=4000                                \
    listen=127.0.0.1
#
#   b. This will forward the tcp port 4000 to the domain socket
#   that pulseaudio listens on by default. Note that the file
#   path of the domain socket can be different on different sys-
#   tems.
#
socat TCP-LISTEN:4000,fork \
      UNIX-CONNECT:/run/user/1000/pulse/native

# 3. Now, on the remote machine (producing the sound data), you
# can do one of two things.
#
#   a. Set the environment variable as follows and run any pro-
#   gram that produces sound under this variable.
#
export PULSE_SERVER=localhost:4000
#
#   b. Alternatively, you can create the file ~/.pulse/client.-
#   conf and add the following line:
#
default-server = localhost:4000
#
#   and then restart pulseaudio with:
pulseaudio -k