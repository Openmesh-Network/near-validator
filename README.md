# NEAR Validator

Run a NEAR validator with minimal setup and maximum reproducibility using Nix.

## One click deployment

[<img src="https://www.openmesh.network/xnode/deploy-on-xnode.svg" width=200 />](https://www.openmesh.network/xnode/deploy?useCaseId=3)

# Run as Nix flake

> [!NOTE]
> Requires Nix to be installed. Installation on linux can be done through `sh <(curl -L https://nixos.org/nix/install) --daemon`. For other platforms please refer to [the official installation guide](https://nixos.org/download/).

## Generate config

```sh
nix run github:Openmesh-Network/near-validator init  --experimental-features 'nix-command flakes' -- --chain-id=mainnet --account-id="<pool id>.<pool or poolv1>.near" --download-genesis --download-config validator
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/update_boot_nodes.sh | bash -s -- mainnet $HOME/.near/config.json
```

## Fast sync (optional)

> [!NOTE]
> Requires rclone to be installed. Installation can be done permanently through `sudo -v ; curl https://rclone.org/install.sh | sudo bash` or temporarily with `nix-shell -p rclone`.

```sh
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/down_rclone.sh | DATA_PATH=$HOME/.near/data CHAIN_ID=mainnet RPC_TYPE=fast-rpc bash
```

## Run NEAR node

```sh
nix run github:Openmesh-Network/near-validator --experimental-features 'nix-command flakes' run
```

## Update flake

Nix will run a previously downloaded version if available. Run this command to update your NEAR validator to the latest version.

```sh
nix flake update --flake github:Openmesh-Network/near-validator
```

# NixOS Configuration

An example Xnode (NixOS container) configuration can be found [here](./example/flake.nix).

```nix
boot.kernel.sysctl = {
    "net.core.rmem_max" = 8388608;
    "net.core.wmem_max" = 8388608;
    "net.ipv4.tcp_rmem" = "4096 87380 8388608";
    "net.ipv4.tcp_wmem" = "4096 16384 8388608";
    "net.ipv4.tcp_slow_start_after_idle" = 0;
};

services.near-validator = {
    enable = true;
    pool = {
        id = "<pool id>";
        version = "<pool or poolv1>";
    };
};

networking = {
    firewall.allowedTCPPorts = [
        3030
        24567
    ];
};
```
