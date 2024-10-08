# SPO Workshop

## Setting Up a Cardano SPO on Preview Testnet

This guide provides a detailed walkthrough for setting up a Cardano Stake Pool Operator (SPO) on Cardano. In a mainnet enviornment you will use dedicated bare metals servers or a cloud provider. However, this tutorial we simulate Ubuntu instances locally using Multipass.

Cardano mainnets and testnets different system requirements since mainnet is much larger of a blockchain. For latest system requirements see the official https://developers.cardano.org/docs/operate-a-stake-pool/hardware-requirements/.

This tutorial will be applied to the Cardano `Preview` testnet. Please target this Cardano environment.

## Tutorial requirements

|  | |  |
|-----------------------------------|-------------|--------------|
| **CPU**                          | Minimum 4 cores, Quad-core or better recommended | 
| **RAM**                          | 8 GB or more recommended | 
| **Storage**                      | SSD recommended, 40 GB of free storage | 

The tutorial requirements accounts for 2 Cardano nodes instances for `Preview` testnet.

### General Cardano node requirements

| **Requirement**                  | **Mainnet** | **Testnets** |
|-----------------------------------|-------------|--------------|
| **Operating System**             | Linux (Ubuntu recommended) | Linux (Ubuntu recommended) |
| **CPU**                          | Minimum 2 cores, Quad-core or better recommended | Minimum 2 cores, Quad-core or better recommended |
| **RAM**                          | 8 GB or more recommended | 4 GB or more recommended |
| **Storage**                      | SSD recommended, 150 GB of free storage (250 GB recommended for future growth) | SSD recommended, at least 20 GB free space |

This tutorial assumes you are using a Linux or Windows system with an AMD or Intel CPU. ARM-based systems like newer Macs are not supported due to lack of pre-built binaries.

## Minimum viable SPO architecture

A Cardano SPO requires a minimum of 2 Cardano nodes:

1. **Cardano Relay Node:** A Cardano Relay Node propagates transactions and blocks across the network, enhancing connectivity and reliability for stake pools.

2. **Cardano Block Producer Node (BP node):** A Cardano Block Producer Node, often part of a stake pool, creates new blocks and mints new transactions, crucial for maintaining the blockchain's integrity and operation.

```mermaid
graph TD
    A[Stake Pool] --> B[BP Node]
    C[Relay Node] --> D[Cardano Network]
    B --> C
    style A fill:none,stroke-dasharray: 5,5
    style D fill:none,stroke-dasharray: 5,5
```

More relay nodes are recommended for stake pool operation to increase network resilience, ensure better block propagation, and minimize the risk of downtime or connectivity issues that could affect block production. This tutorial is for testing on `Preview` testnet and will use the minimum required instances of Cardano node (1 BP node and 1 Relay node).

## Step 1: Create Ubuntu instances using Multipass

Multipass is used to manage Ubuntu virtual machines easily.

1. **Download and Install Multipass:**
   - Visit the official [Multipass](https://multipass.run/install) website and download the appropriate version for your operating system.
   - Follow the installation instructions provided.

2. **Verify Multipass Installation:**

    - Open shell and invoke multipass to check version and display usage and commands:
     
   ```shell
   multipass --version
   multipass --help
   ```

3. **Launch 2 Ubuntu instances using Multipass**

    -  Launch 2 Ubuntu instances following recommended system requirements.

   ```shell
    multipass launch -n cn1 -c 2 -m 4GB -d 20GB
    multipass launch -n cn2 -c 2 -m 4GB -d 20GB
   ```

   This creates two Ubuntu instances named `cn1` and `cn2`. In other words, "cardano-node-1" and "cardano-node-2". Feel free to allocate more hardware resources if available.

   Understanding the `multipass launch` parameters 

   ```shell
   # Launching the instance
    multipass launch \
        -n cn2 \                  # Name of the instance: cn2
        -c 2 \                    # Number of CPU cores: 2
        -m 4GB \                  # Memory allocation: 4GB
        -d 20GB                   # Disk space allocation: 20GB
    ```
4. **List Ubuntu instances and obtain IP addresses:**

  - List the Ubuntu instances that were created:

    ```shell
    multipass list
    ```
    Example output: 

    ```shell
    $ multipass list
    Name                    State             IPv4             Image
    cn1                     Running           10.249.38.7      Ubuntu 24.04 LTS
    cn2                     Running           10.249.38.198    Ubuntu 24.04 LTS
    ```

    This command helps verify VM creation, status, and IP addresses, crucial for node configuration.

  - Make a note of each IP address. This will be needed.

    Feel free to utilize the Multipass GUI that comes with Multipass. Simply go in applications and select Multipass to launch the GUI.

    ![multipass-gui](/multipass_dashboard.png)

## Step 2: Install SPO Toolkit on Ubuntu instances

The [SPO Guild Operator](https://cardano-community.github.io/guild-operators/) toolkit simplifies Cardano node setup and common SPO tasks.

1. **Run setup and deployment script on multiple instances:**

  - Open a new shell and run this initial setup script:
    ```shell
    curl -o- https://raw.githubusercontent.com/stevanlohja/cardano-spo-multipass/main/scripts/initial_provision.sh | bash
    ```
    This script may take a few minutes ⌛ to complete as it provisions both instances.

### Optional: Mac/ ARM architecture workaround

If you're on device with Mac/ ARM architecture, then you may encounter an error when installation Cardano node that reads:

```
ERROR:   The build archives are not available for ARM, you might need to build them!
```

The setup script intended to place the binary release of Cardano node in `$HOME/.local/bin/`.

Official pre-built binaries for ARM-Linux architecture is not well supported. Therefore you will have to build Cardano node from source, or find a community maintained ARM-Linux release such as https://github.com/armada-alliance/cardano-node-binaries/.

- **Download and Install Cardano Node (for ARM architecture):**
  - Run this script to install the desired Cardano node in each instance:

    ```shell
    #!/bin/bash

    instances=("cn1" "cn2")

    for instance in "${instances[@]}"; do
        echo "🚀 Running commands on $instance..."

        multipass exec "$instance" -- bash -c '
            ARCHIVE_URL="https://github.com/armada-alliance/cardano-node-binaries/blob/main/static-binaries/9_1_0.tar.zst?raw=true"
            DEST_DIR="$HOME/.local/bin"
            mkdir -p "$DEST_DIR"
            echo "Downloading archive..."
            curl -L "$ARCHIVE_URL" -o 9_1_0.tar.zst
            if [ $? -ne 0 ]; then
                echo "Failed to download the archive."
                exit 1
            fi
            if ! command -v zstd &> /dev/null; then
                sudo apt-get update -y
                sudo apt-get install -y zstd
            fi
            echo "Extracting archive..."
            zstd -d -c 9_1_0.tar.zst | tar -x -C "$DEST_DIR" --strip-components=1
            if [ $? -ne 0 ]; then
                echo "Failed to extract the archive."
                exit 1
            fi
            rm 9_1_0.tar.zst
            echo "Archive downloaded and extracted successfully to $DEST_DIR"
        '

        echo "🎉 Finished running commands on $instance."
    done 
    ```

- **Verify Cardano Node Installation:**
  - Enter the instance and invoke `cardano-node` to check it's installed:
    ```shell
    multipass shell cn1 # enter instance
    cardano-node --version # invoke cardano-node and check version
    which cardano-node # verify binary location
    ```

    Example output:

    ```shell
    $ cardano-node --version
    cardano-node 9.1.0 - linux-aarch64 - ghc-9.6
    $ which cardano-node
    /home/ubuntu/.local/bin/cardano-node
    ```

  - Repeat to verify installation in each instance.

## Strategic Node Configuration: From Relay to Block Producer

`cn1` will be designated as the Relay node. `cn2` will initially be set up as a Relay node but will later be converted into a BP node. This setup involves configuring both `cn1` and `cn2` initially as Relay nodes, followed by a transition where `cn2` assumes the role of a BP node. Starting `cn2` as a Relay node simplifies network integration and peer connection, streamlining the transition to a BP node.

## Step 3: Configure `cn1` instance:

1. **Enter `cn1` Instance:**
    - Using Multipass enter the `cn1` instance:
    ```shell
    multipass shell cn1
    ```

2. **Test start the relay node interactively in shell:**

    Keep the default port (`6000`) and paths setup by the toolkit. This is described in `$CNODE_HOME/scripts/env` and many env variables may be customized.

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

4. **Modify `cn1` config file:**

    - Open `$CNODE_HOME/files/config.json` in an editor.
    - Edit `"PeerSharing"` to be `true` instead of `false`.

5. **Modify topology file:**

    The relay node needs to have a persistant connection to the intended BP node (`cn2`). This is described in the `$CNODE_HOME/files/topology.json` file.

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
    - Add the IP `address` for the BP node (`cn2`) in `"localRoots"`.
    - Unless you have multiple relay nodes, simply remove the relay node placeholder from `"localRoots"`.
    - Set "`hotValency"` to `1` since `cn2` is the only other `"accessPoints"`.

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
              "address": "10.249.38.198",
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

5. **Test start the relay node interactively in shell:**
    
    Topology and config files mistakes can interrupt the node from starting properly. So, it's a good idea to test start nodes after modifying node files.

    - Repeat Step **3.1** and **3.2** to test start the node and monitor it to ensure it's syncing.

6. **Setup node to run as service:**

    Instead of manually starting the node, configure it as a systemd service for automatic startup. The toolkit includes a script to make this easier:

    - Stop any running node processes.
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
    
    - Check `status` and replace status with `stop`/`start`/`restart` depending on what action to take.

    ```shell
    sudo systemctl status cnode.service
    sudo systemctl status cnode-submit-api.service
    ```

    - In a new shell, monitor node to verify node status using `gLiveView`:

    ```shell
    cd $CNODE_HOME/scripts
    ./gLiveView.sh
    ```

## Step 4: Start `cn2` as a Relay node.

As mentioned earlier, `cn2` will initially run as a Relay node, then be converted into a BP node.

1. **Enter `cn2` Instance:**
    - Using Multipass enter the `cn2` instance:
    ```shell
    multipass shell cn2
    ```

2. **Setup node to run as service:**

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

3. **Start node as a service:**

    - Start the systemd service files created:

    ```shell
    sudo systemctl start cnode.service
    sudo systemctl start cnode-submit-api.service
    ```
    
    - Check `status` and replace status with `stop`/`start`/`restart` depending on what action to take.

    ```shell
    sudo systemctl status cnode.service
    sudo systemctl status cnode-submit-api.service
    ```

    - In a new shell, monitor node to verify node status using `gLiveView`:

    ```shell
    cd $CNODE_HOME/scripts
    ./gLiveView.sh
    ```

## Allow both `cn1` and `cn2` to sync to 100%.

Allow both `cn1` and `cn2` to sync to 100%. This can be tracked with the `gLiveView` utility and can take up to a couple hours.

## Step 5: Convert `cn2` into a BP node

1. **Stop `cn2` Relay node:**
    - Using Multipass enter the `cn2` instance and stop the node:
    ```shell
    multipass shell cn2 
    sudo systemctl stop cnode.service # stop the service
    sudo systemctl status cnode.service # verify service stopped
    ```

2. **Modify node config file:**

    - Open `$CNODE_HOME/files/config.json` in an editor.
    - Edit `"PeerSharing"` and `"EnableP2P"` to be `false`.

3. **Modify node topology file:**

    The BP node will only peer with the Relay node and not the public network. Therefore, the default topology file has to reflect the Relay node (`cn1`) as the only `"accessPoints"` under `"localRoots"`

    - Open `$CNODE_HOME/files/topology.json` in an editor.
    - Delete the contents of the file and simply copy and paste the example `topology.json` contents below. However, ensure you replace the IP address with your Relay node IP address (Instance `cn1`).

    ```json
    {
      "bootstrapPeers": [],
      "localRoots": [
        {
          "accessPoints": [
            {
              "address": "10.190.51.250",
              "port": 6000,
              "description": "cn1"
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
    ```

4. **Test start the BP node interactively in the shell:**

    Test start the node interactively in shell.

    ```shell
    cd "${CNODE_HOME}"/scripts
    ./cnode.sh
    ```