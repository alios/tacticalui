{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nci.url = "github:yusdacra/nix-cargo-integration";
  inputs.nci.inputs.nixpkgs.follows = "nixpkgs";
  inputs.parts.url = "github:hercules-ci/flake-parts";
  inputs.parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";

  outputs =
    inputs@{
      parts,
      nci,
      rust-overlay,
      ...
    }:
    parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        nci.flakeModule
        ./crates.nix
      ];
      perSystem =
        {
          pkgs,
          lib,
          system,
          config,
          ...
        }:
        let
          rust-extensions = [
            "rust-src"
            "rust-docs"
            "rust-analyzer"
            "clippy"
          ];
          # shorthand for accessing outputs
          # you can access crate outputs under `config.nci.outputs.<crate name>` (see documentation)
          outputs = config.nci.outputs;

          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = rust-extensions;
            targets = [ "wasm32-unknown-unknown" ];
          };

#          rustToolchain = pkgs.rust-bin.selectLatestNightlyWith (
#            toolchain:
#            toolchain.default.override {
#              extensions = rust-extensions;
#            }
#          );

        in
        {
          formatter = inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.rust-overlay.overlays.default ];
            config.allowUnfree = true;
          };

          # export the project devshell as the default devshell
          devShells.default = outputs."tacticalui".devShell.overrideAttrs (old: {
            packages =
              (old.packages or [ ])
              ++ (with pkgs; [
                nil
                git
                rustToolchain
                cargo-udeps
                cargo-deny
                libicns
                trunk
              ]);

            shellHook = ''
              # For rust-analyzer 'hover' tooltips to work.
              export RUST_SRC_PATH="${rustToolchain}/lib/rustlib/src/rust/library";
              export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [
                pkgs.alsa-lib
                pkgs.udev
                pkgs.vulkan-loader
                pkgs.wayland

                pkgs.vulkan-headers
                pkgs.libxkbcommon
                pkgs.xorg.libX11
                pkgs.xorg.libXcursor
                pkgs.xorg.libXfixes
                pkgs.libGL
              ]}"
            '';
            buildInputs =
              (old.buildInputs or [ ])
              ++ (with pkgs; [
                libiconv
                libressl
                alsa-lib
                vulkan-tools
                vulkan-headers
                vulkan-loader
                vulkan-validation-layers
                udev
                clang
                lld
                libxkbcommon
                wayland
                xorg.libX11
                xorg.libXi
                xorg.libXcursor
                xorg.libXfixes
                libGL
              ]);
            nativeBuildInput =
              (old.nativeBuildInputs or [ ])
              ++ (with pkgs; [
                pkg-config
              ]);
          });

          # export the release package of one crate as default package
          packages.default = outputs."tacticalui".packages.release;
        };
    };
}
