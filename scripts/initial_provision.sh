#!/bin/bash

instances=("cn1" "cn2")

for instance in "${instances[@]}"; do
    echo "🚀 Running commands on $instance..."

    multipass exec "$instance" -- bash -c '
        sudo apt update -y && sudo apt upgrade -y
        mkdir -p "$HOME/tmp" && cd "$HOME/tmp"
        sudo apt -y install curl
        curl -sS -o guild-deploy.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/guild-deploy.sh
        chmod 755 guild-deploy.sh
        ./guild-deploy.sh -b master -n preview -t cnode -s pdlcowx
        . "${HOME}/.bashrc"
        cd ~/git || mkdir -p ~/git && cd ~/git
        git clone https://github.com/intersectmbo/cardano-node || (cd cardano-node && git fetch --tags --recurse-submodules --all && git pull)
        cd cardano-node
        git checkout $(curl -sLf https://api.github.com/repos/intersectmbo/cardano-node/releases/latest | jq -r .tag_name)
        $CNODE_HOME/scripts/cabal-build-all.sh
    '

    echo "🎉 Finished running commands on $instance."
done