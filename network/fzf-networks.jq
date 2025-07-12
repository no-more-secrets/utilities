# This takes the json output from the scan-local-network tool
# (run in json mode) and extras one ip/host per line with the in-
# tention that it will be fed into fzf.
.nmaprun.host
 | .[]
 | .address."@addr" + " " + .hostnames.hostname."@name"