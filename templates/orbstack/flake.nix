{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/fornybar/registry/main/registry.json";

  inputs = {
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      pc,
      ...
    }@inputs:
    {
      nixosConfigurations.gauss = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = inputs;
        modules = [
          pc.nixosModules.terminal
          pc.nixosModules.hdw-orbstack
          {
            midgard.pc = {
              hostName = "gauss";
              nixbuild.enable = true;
              users = {
                kristoffer = {
                  fullName = "Kristoffer K. Føllesdal";
                  email = "kristoffer.follesdal@eviny.no";
                  git.userName = "kfollesdal";
                };
              };
            };
          }
        ];
      };
    };
}
