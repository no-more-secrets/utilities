#!/bin/bash
set -eo pipefail

port=5901

ssh -L $port:127.0.0.1:$port linode