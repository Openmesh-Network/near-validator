# NEAR Validator

Run a NEAR validator with minimal setup and maximum reproducibility using Nix.

## One click deployment

[<img src="https://www.openmesh.network/xnode/deploy-on-xnode.svg" width=200 />](https://www.openmesh.network/xnode/deploy?useCaseId=3)

# Run as Nix flake

> [!NOTE]
> Requires Nix to be installed. Installation on linux can be done through `sh <(curl -L https://nixos.org/nix/install) --daemon`. For other platforms please refer to [the official installation guide](https://nixos.org/download/).

## Generate config

```sh
nix run github:Openmesh-Network/near-validator init  --experimental-features 'nix-command flakes' --accept-flake-config -- --chain-id=mainnet --account-id="<pool id>.<pool or poolv1>.near" --download-genesis --download-config validator
```

## Fast sync (optional)

> [!NOTE]
> Requires rclone to be installed. Installation can be done permanently through `sudo -v ; curl https://rclone.org/install.sh | sudo bash` or temporarily with `nix-shell -p rclone`.

```sh
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/fastnear/static/refs/heads/main/down_rclone.sh | DATA_PATH=$HOME/.near/data CHAIN_ID=mainnet RPC_TYPE=fast-rpc bash
```

## Run NEAR node

```sh
nix run github:Openmesh-Network/near-validator run --experimental-features 'nix-command flakes' --accept-flake-config -- --boot-nodes "$(curl -s -X POST https://rpc.mainnet.fastnear.com -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "network_info", "params": [], "id": "0"}' | jq '.result.active_peers as $list1 | .result.known_producers as $list2 | $list1[] as $active_peer | $list2[] | select(.peer_id == $active_peer.id) | "\(.peer_id)@\($active_peer.addr)"' | awk 'NR>2 {print ","} length($0) {print p} {p=$0}' ORS="" | sed 's/"//g')"
```

## Update flake

Nix will run a previously downloaded version if available. Run this command to update your NEAR validator to the latest version.

```sh
nix flake update --flake github:Openmesh-Network/near-validator
```

# NixOS Configuration

An example Xnode (NixOS container) configuration can be found [here](./example/flake.nix).

## Add flake input

```nix
  inputs = {
    nixpkgs.url = "<your nixpkgs version>";
    near-validator.url = "github:Openmesh-Network/near-validator";
  };
```

## Edit config

This assumes nixosSystem has `specialArgs = { inherit inputs; };` to access the import. If this is not the case, add it or import the near-validator in another way.

```nix
imports = [
    inputs.near-validator.nixosModules.default
];

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
    # pinger.enable = true;
};

networking = {
    firewall.allowedTCPPorts = [
        3030
        24567
    ];
};
```
