{
  description = "Advent of Code 2025 - Zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zig
            zls
            # helix from home-manager, not needed here
            gdb
            lldb       # use latest for better Zig support
          ];

          shellHook = ''
            echo "Advent of Code 2025 - Zig dev environment"
            echo "Zig: $(zig version)"
            echo "ZLS: $(zls --version)"
            echo "Helix: $(hx --version)"
          '';
        };
      }
    );
}
