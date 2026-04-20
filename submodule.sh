#!/bin/bash


submodule() {
cat << EOF
### Add submodule to another branch

# I take you are on a branch without submodule

# Add submodule to the current branch
rm -rf tdx-kernel-tools
git submodule add https://github.com/MarekBykowski/tdx-kernel-tools.git tdx-kernel-tools
git commit -m "Add submodule"

# Edit .gitsubmodule and add "branch = master"

# Now update to the lastest
git submodule update --remote tdx-kernel-tools
git add tdx-kernel-tools
git commit -m "Update submodule to latest"

EOF
}

submodule
