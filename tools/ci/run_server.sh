#!/bin/bash
set -euo pipefail

tools/deploy.sh ci_test
mkdir ci_test/config
mkdir ci_test/data

#test config
cp tools/ci/ci_config.txt ci_test/config/config.txt
cp tools/ci/config.toml ci_test/config/config.toml

cd ci_test
DreamDaemon citadel.dmb -close -trusted -verbose -params "log-directory=ci"
cd ..
cat ci_test/data/logs/ci/clean_run.lk
