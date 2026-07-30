{
  description = "QEMU/KVM TUI Manager - virsh curses interface";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux;
      pkgsFor = system: import nixpkgs { inherit system; };

      mkRunVm = pkgs:
        pkgs.python3.pkgs.buildPythonApplication {
          pname = "run-vm";
          version = "0.1.0";
          pyproject = false;
          dontUnpack = true;
          src = ./.;
          installPhase = ''
            mkdir -p $out/bin
            cp ${./src/main.py} $out/bin/run-vm
            chmod +x $out/bin/run-vm
          '';
          propagatedBuildInputs = with pkgs; [ libvirt ];
          makeWrapperArgs = [
            "--prefix" "PATH" ":" (with pkgs; lib.makeBinPath [ libvirt virt-manager ])
          ];
          meta = with pkgs.lib; {
            description = "TUI manager for QEMU/KVM virtual machines";
            platforms = platforms.linux;
          };
        };
    in
    {
      packages = forAllSystems (system: {
        default = mkRunVm (pkgsFor system);
        run-vm = self.packages.${system}.default;
      });

      nixosModules.default = self.nixosModules.run-vm;
      nixosModules.run-vm = { pkgs, ... }: {
        environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.run-vm ];
      };

      overlays.default = final: prev: {
        run-vm = mkRunVm final;
      };
    };
}