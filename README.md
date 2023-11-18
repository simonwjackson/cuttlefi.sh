# cuttlefi.sh

## Usage as a flake

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/simonwjackson/cuttlefi.sh/badge)](https://flakehub.com/flake/simonwjackson/cuttlefi.sh)

Add cuttlefi.sh to your `flake.nix`:

```nix
{
  inputs.cuttlefish.url = "https://flakehub.com/f/simonwjackson/cuttlefi.sh/*.tar.gz";

  outputs = { self, cuttlefish }: {
    # Use in your outputs
  };
}
```
