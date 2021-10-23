#!/bin/bash
set -eo pipefail

port=12345

ssh -L $port:127.0.0.1:$port linode