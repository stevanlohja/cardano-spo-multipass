# Setting Up a Cardano SPO on Preview Testnet

This guide provides a detailed walkthrough for setting up a Cardano Stake Pool Operator (SPO) on the Preview testnet. It's designed for educational purposes and should not be used for production or mainnet environments.

## System Requirements

Before starting, ensure your local workstation or server meets these specifications:
- **CPU:** At least 8 free cores
- **RAM:** 8 GB free
- **Storage:** 80 GB free disk space

**Note:** This tutorial assumes you are using a Linux or Windows system with an AMD or Intel CPU. ARM-based systems like newer Macs are not supported due to lack of pre-built binaries.

## Step 1: Create Ubuntu instances using Multipass

Multipass is used to manage Ubuntu virtual machines (VMs) easily.

1. **Download and Install Multipass:**
   - Visit the official [Multipass](https://multipass.run/install) website and download the appropriate version for your operating system.
   - Follow the installation instructions provided.

2. **Verify Multipass Installation:**
    - Open shell and invoke multipass to check version and display usage and commands:
     
   ```shell
   multipass --version
   multipass --help
   ``

3. **Launch 2 Ubuntu instances named `cn1` and `cn2`**

   ```shell
   multipass launch -n cn1 -m 4GB -d 40GB
   multipass launch -n cn2 -m 4GB -d 40GB
   ```

   This creates two Ubuntu instances named `cn1` and `cn2`. In other words, "cardano-node-1" and "cardano-node-2". 

   A Cardano SPO requires a minimum of 2 Cardano nodes:

    1. **Cardano Relay Node:** A Cardano Relay Node propagates transactions and blocks across the network, enhancing connectivity and reliability for stake pools.

    2. **Cardano Block Producer Node:** A Cardano Block Producer Node, often part of a stake pool, creates new blocks and mints new transactions, crucial for maintaining the blockchain's integrity and operation.

    :::important

    **Use multiple relay nodes for mainnet:** More relay nodes are recommended for stake pool operation to increase network resilience, ensure better block propagation, and minimize the risk of downtime or connectivity issues that could affect block production.

    :::

4. **List Ubuntu instances and obtain IP addresses:**

  - List the Ubuntu instances that were created:

   ```shell
   multipass list
   ```

   This command helps verify VM creation, status, and IP addresses, crucial for node configuration.

   Example output: 

   ```shell
  $ multipass list
  Name                    State             IPv4             Image
  cn1                     Running           10.190.51.250    Ubuntu 24.04 LTS
  cn2                     Running           10.190.51.166    Ubuntu 24.04 LTS
   ```

  - Make a note of the IP addresses of each instance. This will be needed.

## Step 2: Install SPO Toolkit

Using the [SPO Guild Operator](https://cardano-community.github.io/guild-operators/) toolkit simplifies Cardano node setup and common SPO tasks.

1. **Run the Setup Script:**
   ```shell
   #!/bin/bash

   instances=("cn1" "cn2")

   for instance in "${instances[@]}"; do
     echo "Running commands on $instance..."
     
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
     
     echo "Finished running commands on $instance."
   done
   ```

   This script:
   - Updates the system.
   - Installs necessary tools like `curl`.
   - Downloads and runs the guild deployment script for the Preview testnet.
   - Clones and updates the Cardano node repository.
   - Builds the Cardano node.

:::note

If you encounter errors related to ARM architecture on a Mac, you'll need to find a compatible Cardano node release or use a different machine. 

:::

## Step 3: Configure `cn1` to operate in `relay` mode

1. **Enter `cn1` Instance:**
    - Using Multipass enter the CN1 instance:
    ```shell
    multipass shell cn1
    ```

2. **Test start the relay node interactively in shell:**

    Keep the default ports and paths setup by the toolkit. This is described in `$CNODE_HOME/scripts/env`.

    - Test start the relay node interactively in the shell:

    ```shell
    cd "${CNODE_HOME}"/scripts
    ./cnode.sh
    ```

    You should see some output that ends with `Listening on http://127.0.0.1:12798`. This is the correct output. `CRTL` + `C` will close the node, but let's not close it just yet.

3. **Monitor the node with the `gLiveView` utility:** 

    - Continue to run the node interactively in shell.
    - Open a new shell and enter `cn1` again:
    ```shell
    multipass shell cn1
    ```
    - Monitor the node using `gLiveView`:
    ```shell
    cd $CNODE_HOME/scripts
    ./gLiveView.sh
    ```

    This should result in realtime information about the node. For example:

    ![gliveview screenshot](cn1_gliveview.png)

    - Exit gLiveView with `CTL` + `C`.
    - Stop the node with `CTL` + `C`.

4. **Modify relay node config file:**

    - Open `$CNODE_HOME/files/config.json` in an editor.
    - Edit `"PeerSharing"` to be `true` instead of `false`.

5. **Modify topology file:**

    The relay node needs to have a persistant connection to the block producer node (`cn2`). This is described in the `$CNODE_HOME/files/topology.json` file.

    The defaults contents of `$CNODE_HOME/files/topology.json` look like so:

    <details><summary>topology.json (before)</summary>

    ```json
    {
      "bootstrapPeers": [
        {
          "address": "preview-node.play.dev.cardano.org",
          "port": 3001
        }
      ],
      "localRoots": [
        {
          "accessPoints": [
            {
              "address": "127.0.0.1",
              "port": 6000,
              "description": "replace-this-with-BP"
            },
            {
              "address": "127.0.0.1",
              "port": 6001,
              "description": "replace-this-with-relay"
            }
          ],
          "advertise": false,
          "trustable": true,
          "hotValency": 2
        },
        {
          "accessPoints": [
            {
              "address": "preview-test.ahlnet.nu",
              "port": 2102,
              "pool": "AHL"
            },
            {
              "address": "95.216.173.194",
              "port": 16000,
              "pool": "HOM1"
            },
            {
              "address": "tn-preview.psilobyte.io",
              "port": 4201,
              "pool": "PSBT"
            },
            {
              "address": "tn-preview2.psilobyte.io",
              "port": 4202,
              "pool": "PSBT"
            }
          ],
          "advertise": false,
          "trustable": false,
          "hotValency": 2,
          "warmValency": 3
        }
      ],
      "publicRoots": [
        {
          "accessPoints": [],
          "advertise": false
        }
      ],
      "useLedgerAfterSlot": 53827185
    }
    ```

    </details>

    - Edit `$CNODE_HOME/files/topology.json` in your prefered editor.
    - Populate the IP `address` for your block producer node (`cn2`) in `"localRoots"`.
    - Unless you have multiple relay nodes, simply remove the relay node placeholder from `"localRoots"`.
    - Set "`hotValency"` to `1`.

    <details><summary>topology.json (after)</summary>

    ```json
    {
      "bootstrapPeers": [
        {
          "address": "preview-node.play.dev.cardano.org",
          "port": 3001
        }
      ],
      "localRoots": [
        {
          "accessPoints": [
            {
              "address": "10.190.51.166",
              "port": 6000,
              "description": "cn2"
            }
          ],
          "advertise": false,
          "trustable": true,
          "hotValency": 1
        },
        {
          "accessPoints": [
            {
              "address": "preview-test.ahlnet.nu",
              "port": 2102,
              "pool": "AHL"
            },
            {
              "address": "95.216.173.194",
              "port": 16000,
              "pool": "HOM1"
            },
            {
              "address": "tn-preview.psilobyte.io",
              "port": 4201,
              "pool": "PSBT"
            },
            {
              "address": "tn-preview2.psilobyte.io",
              "port": 4202,
              "pool": "PSBT"
            }
          ],
          "advertise": false,
          "trustable": false,
          "hotValency": 2,
          "warmValency": 3
        }
      ],
      "publicRoots": [
        {
          "accessPoints": [],
          "advertise": false
        }
      ],
      "useLedgerAfterSlot": 53827185
    }
    ```
    </details>

6. **Setup node to run as service:**

    Instead of manually starting the node, configure it as a systemd service for automatic startup. The toolkit includes a script to make this easier:

    - Invoke the systemd setup scripts:

    ```shell
    cd $CNODE_HOME/scripts
    ./cnode.sh -d
    # Deploying cnode.service as systemd service
    # cnode.service deployed successfully

    ./submitapi.sh -d
    # Deploying cnode-submit-api.service as systemd service
    # cnode-submit-api deployed successfully
    ```

7. **Start node as a service:**

    - Start the systemd service files created:

    ```shell
    sudo systemctl start cnode.service
    sudo systemctl start cnode-submit-api.service
    ```
    
    Check `status` and replace status with `stop`/`start`/`restart` depending on what action to take.

    ```shell
    sudo systemctl status cnode.service
    sudo systemctl status cnode-submit-api.service
    ```

    - In a new shell, monitor node to verify node status using `gLiveView`:

    ```shell
    cd $CNODE_HOME/scripts
    ./gLiveView.sh
    ```

Allow the relay node to sync to 100% before continuing.

## Step 4: Configure `cn2` to operate in `block producer` mode.

1. **Enter `cn2` Instance:**
    - Using Multipass enter the `cn2` instance:
    ```shell
    multipass shell cn2
    ```

2. **Modify block producer node config file:**

    - Open `$CNODE_HOME/files/config.json` in an editor.
    - Edit `"PeerSharing"` and `"EnableP2P"` to be `false`.

3. **Modify block producer node topology file:**

```json
{
  "bootstrapPeers": [],
  "localRoots": [
    {
      "accessPoints": [
        {
          "address": "10.190.51.250",
          "port": 6000,
          "description": "cn2"
        }
      ],
      "advertise": false,
      "trustable": true,
      "hotValency": 1
    }
  ],
  "publicRoots": [
    {
      "accessPoints": [],
      "advertise": false
    }
  ],
  "useLedgerAfterSlot": -1
}