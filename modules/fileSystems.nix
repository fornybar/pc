{
  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" ={
    label = "boot";
    fsType = "vfat";
  };

  #swapDevices = [ ];
}