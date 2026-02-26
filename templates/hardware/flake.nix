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
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          pc.nixosModules.hdw-hp-elitebook-830-g5
          pc.nixosModules.default
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
