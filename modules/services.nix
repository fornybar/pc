{
  # Enable CUPS to print documents.
  services = {
    printing.enable = true;

    # Enable sound with pipewire.
    #sound.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security.rtkit.enable = true;
}
