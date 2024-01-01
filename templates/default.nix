{
  default = {
    path = ./hardware;
    description = "Example setup for nixos pc";
    welcomeText = ''
    # Nixos config setup
    Setup a simple nixos pc
    ''; # Can use markdown here
  };

  orbstack = {
    path = ./orbstack;
    description = "Example setup for nixos in orbstack";
    welcomeText = ''
    # Nixos config setup
    Setup a simple nixos pc
    ''; # Can use markdown here
  };
}