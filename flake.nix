{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    prisma-utils.url = "github:VanCoding/nix-prisma-utils";
    devenv.url = "github:cachix/devenv";
    devenv-helix = {
      url = "git+https://codeberg.org/quasigod/devenv-helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, prisma-utils, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, lib, ... }:
        let
          prisma =
            (prisma-utils.lib.prisma-factory {
              inherit pkgs;
              prisma-fmt-hash = "sha256-3YArAgnfj95UdT/7+P+v4Is7t746SAoHUm77XtJVC8s=";
              query-engine-hash = "sha256-XGDTAimNXLJqdLb4q8YKBg0+GCCeQz09bUJUQesFOfo=";
              libquery-engine-hash = "sha256-Lj0bOALAANtru6SLGrdtFQ1NUaupXe/l692g3Zk7l2Q=";
              schema-engine-hash = "sha256-99TWwC3lqVl3US8W5lhNt9iBiQgt5dsGRckbnSXMMp0=";
            }).fromPnpmLock
              ./pnpm-lock.yaml;
        in
        {
          devenv.shells.default =
            { config, ... }:
            {
              name = "my-project";
              imports = [ inputs.devenv-helix.module ];
              packages = with pkgs; [
                atk
                cairo
                dbus
                egl-wayland
                gdk-pixbuf
                glib
                glib-networking
                gtk3
                librsvg
                libsoup_2_4
                mesa
                openssl_3_3
                pango
                patchelf
                pkg-config
                sass
                turbo
                webkitgtk_4_1
              ];
              env = prisma.env // {
                DATABASE_URL = "postgresql://quasi@127.0.0.1:5432";
                GIO_MODULE_DIR = "${pkgs.glib-networking}/lib/gio/modules/";
              };
              services.postgres = {
                enable = true;
                listen_addresses = "127.0.0.1";
                initialDatabases = lib.singleton { name = "turborepo"; };
              };
              enterShell =
                let
                  dotenv = pkgs.writeText "dotenv" ''
                    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n}=${toString v}") config.env)}
                  '';
                in
                ''
                  cp ${dotenv} .env
                '';
              languages = {
                javascript = {
                  enable = true;
                  pnpm.enable = true;
                  pnpm.install.enable = true;
                  npm.enable = true;
                };
              };
            };
        };
      flake = {
      };
    };
}
