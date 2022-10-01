{ modulesPath, config, ... }:
# Have to start VM with sudo if /etc/age is own by root
{
  virtualisation.vmVariant = {
    imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

    virtualisation = {
      cores = 4;
      memorySize = 8000;
      sharedDirectories.age = {
        source = "/root/.config/sops/age";
        target = "/root/.config/sops/age";
      };

      qemu.options = [ "-vga virtio" ];
    };
  };
}