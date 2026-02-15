#!/bin/bash
set -e

cd "$(dirname "$0")"

ip="$(./choose-host.sh)"

[[ -n "$ip" ]]

ssh -XY "$ip"