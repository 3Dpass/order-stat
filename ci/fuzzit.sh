#!/bin/bash
set -xe

# Validate arguments
if [ "$#" -ne 1 ]; then
    cat << EOF
Usage: $0 <type>

Types are:
local-regression - Run corpus and past crashes locally to catch regressions.
fuzzing - Submit for long run fuzzing on Fuzzit.
EOF
    exit 1
fi

# Configure
set -xe
NAME=huonw
REPO=order-stat
TYPE=$1
FUZZIT_VERSION=2.4.72

# Setup
if [[ ! -f fuzzit || ! `./fuzzit --version` =~ $FUZZIT_VERSION$ ]]; then
    wget -q -O fuzzit https://github.com/fuzzitdev/fuzzit/releases/download/v$FUZZIT_VERSION/fuzzit_Linux_x86_64
    chmod a+x fuzzit
fi
./fuzzit --version

cargo install -v cargo-fuzz || echo "cargo-fuzz already installed"

# Fuzz
function fuzz {
    FUZZER=$1
    TARGET=$2
    cargo fuzz run $FUZZER -- -runs=0
    ./fuzzit --version
    ./fuzzit create job --type $TYPE "$NAME/$REPO-$TARGET" ./fuzz/target/x86_64-unknown-linux-gnu/debug/$FUZZER
}
fuzz fuzz_kth kth
fuzz fuzz_mom mom

