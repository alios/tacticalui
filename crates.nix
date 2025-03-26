{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # declare projects
      # TODO: change this to your workspace's path
      nci.projects."tacticalui" = {
        path = ./.;
        # export all crates (packages and devshell) in flake outputs
        # alternatively you can access the outputs and export them yourself
        export = true;

        depsDrvConfig = {
          mkDerivation = {
          shellHook = ''
              export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [
                pkgs.alsa-lib
                pkgs.udev
                pkgs.vulkan-loader
                pkgs.wayland
              ]}"
            '';
            buildInputs = (with pkgs; [
                pkg-config
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
              ]);
            nativeBuildInputs = [ pkgs.pkg-config ];
          };


         # env.PKG_CONFIG_PATH = "${pkgs.libressl.dev}/lib/pkgconfig";
         env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
                  pkgs.alsa-lib
                  pkgs.udev
                  pkgs.vulkan-loader
                  pkgs.wayland
         ];
        };

      };
    };
}
