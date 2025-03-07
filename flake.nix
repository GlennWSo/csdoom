{
  description = "flake for rust dev";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
    crane,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {inherit system overlays;};
        # rust =
        #   pkgs.rust-bin.selectLatestNightlyWith
        #   (toolchain:
        #     toolchain.default.override {
        #       extensions = ["rust-src"];
        #       targets = [];
        #     });
        rust = pkgs.rust-bin.stable.latest.default.override {
          extensions = ["rust-src"];
          targets = [
            # "wasm32-unknown-unknown"
          ];
        };
        craneLib = (crane.mkLib pkgs).overrideToolchain (_p: rust);

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
          glib
          gtk3
          libxkbcommon
          libz
          pkg-config
          vulkan-loader
          wayland
          wayland-protocols
          zlib
          alsa-lib.dev
          udev.dev
          udev
          alsa-lib
        ]);

        commonRust = {
          src = craneLib.cleanCargoSource ./.;
          buildInputs = with pkgs; [
            # Add extra build inputs here, etc.
            openssl
            alsa-lib.dev
            udev.dev
            xorg.libX11.dev
            xorg.libXcursor.dev
            xorg.libXi.dev
            udev

            clang
            lld
          ];
          nativeBuildInputs = with pkgs; [
            # Add extra native build inputs here, etc.
            pkg-config
          ];
        };
        cargoArtifacts = craneLib.buildDepsOnly (commonRust
          // {
            # Be warned that using `//` will not do a deep copy of nested sets
            pname = "mycrate-deps";
          });
      in rec {
        packages.default = packages.hello;
        devShells.default = craneLib.devShell {
          inherit LD_LIBRARY_PATH;
          inputsFrom = [packages.hello];
          packages = [
            pkgs.rust-analyzer
          ];
        };
        packages.hello = craneLib.buildPackage (commonRust
          // {
            inherit cargoArtifacts;
          });
      }
    );
}
