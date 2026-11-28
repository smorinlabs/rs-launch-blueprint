#!/bin/sh
# Devcontainer setup. The repository's own chain, nothing parallel to it:
#   Level 0: rustup toolchain install  (materialize rust-toolchain.toml)
#   Level 1: make bootstrap            (F179-F182 Level 1)
#   Level 2: just setup                (F179-F182 Level 2)
# Unlike py's slim uv base, this image already carries make, curl, git and
# ca-certificates, so there is no apt-get step here.
set -eu

rustup toolchain install

make bootstrap
just setup
