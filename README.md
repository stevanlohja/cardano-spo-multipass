# Get Cardano SPO on Preview testnet up and running.

This tutorial is to get a Cardano SPO up and running on Preview testnet. This is a quick and dirty tutorial and not meant for production or mainnet enviorments.

I'm going to use my local workstation to run the stake pool therefore my workstation needs enough CPU cores, RAM, and STORAGE to allocate to the virtual machines.

Therefore, make sure you have at least 8 free CPU cores, 80 GB disk storage, and 8 GB free RAM.

# Step 01 - Install Multipass on Workstation

1. Download and install Multipass from the official website: https://multipass.run/install
2. Verify installation by invoking Multipass from shell:

```shell
multipass --version
multipass --help
```

# Step 02 - Create Ubuntu instances

1. Open shell and invoke Multipass to launch 2 VMs given the following parameters:

```shell
multipass launch -n cn1 -m 4GB -d 40GB
multipass launch -n cn2 -m 4GB -d 40GB
```

This will create 2 virtual machines named `cn1` and `cn2`. In other words, "cardano node 1" and "cardano node 2".

# Step 03 - Install SPO dependencies 

We will use the SPO Guild Operator's toolkit to create and manage the Cardano node services for our SPO.
1. Copy and paste the script script below directly into shell:

```
#!/bin/bash

# Define your instance names
instances=("cn1" "cn2")

# Loop through each instance and execute the commands
for instance in "${instances[@]}"; do
  echo "Running commands on $instance..."
  
  multipass exec "$instance" -- bash -c '
    sudo apt update -y
    sudo apt upgrade -y
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
  
  echo "Finished running commands on $instance."
done
```

If you are on a Mac workstation, then you may see an error such as `ERROR:   The build archives are not available for ARM, you might need to build them!`. 

