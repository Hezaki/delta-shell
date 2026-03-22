{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    astal-niri = {
      url = "github:sameoldlab/astal?ref=feat/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal-niri";
    };
  };

  outputs = inputs @ {
    flake-parts,
    astal,
    astal-niri,
    ags,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = {
        system,
        pkgs,
        ...
      }: let
        pname = "delta-shell";

        buildInputs =
          (with pkgs; [
            gjs
            gtk4
            libsoup_3
            libadwaita
            gobject-introspection
            glib-networking
            wrapGAppsHook3

            bluez
            geoclue2
            libgtop
          ])
          ++ (with astal.packages.${system}; [
            io
            astal4
            apps
            hyprland
            battery
            bluetooth
            mpris
            network
            notifd
            powerprofiles
            tray
            wireplumber
          ])
          ++ [
            astal-niri.packages.${system}.niri
            ags.packages.${system}.ags
          ];

        nativeBuildInputs = with pkgs; [
          meson
          ninja
          wrapGAppsHook3
        ];

        runtimeDependencies = with pkgs; [
          ags.packages.${system}.ags
          dart-sass
          brightnessctl
          ddcutil
          gpu-screen-recorder
          wl-clipboard
          cliphist
        ];

        devshellBuildInputs =
          nativeBuildInputs ++ buildInputs ++ runtimeDependencies;
      in {
        packages = rec {
          default = delta-shell;

          delta-shell = pkgs.stdenv.mkDerivation {
            name = pname;
            src = ./.;

            inherit buildInputs;
            inherit nativeBuildInputs;

            postInstall = ''
              wrapProgram $out/bin/${pname} \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDependencies}
            '';

            meta.mainProgram = pname;
          };
        };

        devShells = {
          default = pkgs.mkShell {
            buildInputs = devshellBuildInputs;
            shellHook = ''
              echo 'Welcome to the delta-shell nix devShell!'
              echo 'To get build instructions, please read README.'
            '';
          };
        };
      };

      flake = {
        nixosModules.default = {
          system,
          lib,
          config,
          ...
        }: {
          options.programs.delta-shell = {
            enable = lib.mkEnableOption "Install delta-shell";

            package = lib.mkOption {
              type = lib.types.package;
              description = "The delta-shell package to use";
              default = self.packages.${system}.delta-shell;
            };
          };

          config = lib.mkMerge [
            (lib.mkIf config.programs.delta-shell.enable {
              programs.gpu-screen-recorder.enable = true;

              environment.systemPackages = [
                config.programs.delta-shell.package
              ];
            })
          ];
        };
      };
    };
}
