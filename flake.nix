{
  outputs = { self, ... }@inputs: {
    nixosModules = import ./hardware;
  };
}
