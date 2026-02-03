{
  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixos }: {
    nixosConfigurations.default = nixos.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ lib, ... }: {
          system.stateVersion = "25.11";
          boot.supportedFilesystems = [ "bcachefs" ];
          virtualisation.vmVariant.virtualisation = {
            emptyDiskImages = [ 4096 4096 4096 ];
            fileSystems = {
              "/" = lib.mkForce {
                device = "/dev/disk/by-uuid/7a0c1516-e651-41fd-9fd8-2adebe0238e6";
                fsType = "bcachefs";
              };
            };
          };
          boot.initrd.postDeviceCommands = ''
            bcachefs format \
              --foreground_target=ssd \
              --promote_target=ssd \
              --background_target=hdd \
              --replicas=2 \
              --uuid=7a0c1516-e651-41fd-9fd8-2adebe0238e6 \
              --label=ssd.ssd1 /dev/vdb \
              --label=hdd.hdd1 /dev/vdc \
              --label=hdd.hdd2 /dev/vdd
          '';
          services.getty.autologinUser = "root";
          systemd.services.fill-fs = {
            wantedBy = [ "multi-user.target" ];
            enable = true;
            script = ''
              for i in {1..1000}
              do
                dd bs=1K count=$(($RANDOM / 2000 + 100)) if=/dev/urandom of=/file$i
              done
            '';
          };
        })
      ];
    };
    apps.x86_64-linux.default = {
      type = "app";
      program = "${self.nixosConfigurations.default.config.system.build.vm}/bin/run-nixos-vm";
    };
  };
}
