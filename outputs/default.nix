{
  self,
  nixpkgs,
  pre-commit-hooks,
  ...
}: let
  # List of supported systems
  systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

  # Function to generate system-specific attributes
  forAllSystems = nixpkgs.lib.genAttrs systems;
in {
  # Packages for all systems
  packages = forAllSystems (system: {
    inherit (nixpkgs.legacyPackages.${system}) hello;
    default = nixpkgs.legacyPackages.${system}.hello;
  });

  # Default package for 'nix build'
  defaultPackage = forAllSystems (system: self.packages.${system}.default);

  # Formatter configuration
  formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

  # Pre-commit hooks configuration
  checks = forAllSystems (system: {
    pre-commit-check = pre-commit-hooks.lib.${system}.run {
      src = ./.; # Ruta al directorio raíz del proyecto
      hooks = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix = {
          enable = true;
          settings = {
            noLambdaArg = true;
            noLambdaPatternNames = true;
          };
        };
      };
    };
  });

  # Development environment with pre-commit tools
  devShells = forAllSystems (system: {
    default = nixpkgs.legacyPackages.${system}.mkShell {
      buildInputs = with nixpkgs.legacyPackages.${system}; [
        pre-commit
        statix
        deadnix
        alejandra
      ];
      shellHook = ''
        echo "Development environment ready. Pre-commit hooks are set up."
      '';
    };
  });
}
