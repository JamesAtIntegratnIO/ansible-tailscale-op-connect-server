{
  description = "Ansible flake with artis3n.tailscale";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    score-compose-src = {
      url = "github:score-spec/score-compose?ref=0.28.0";
      flake = false;
    };
    score-k8s-src = {
      url = "github:score-spec/score-k8s?ref=0.4.3";
      flake = false;
    };
  };

  outputs = { 
    self, 
    nixpkgs, 
    flake-utils, 
    score-compose-src, 
    score-k8s-src  
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        score-compose-version = "0.28.0";
        score-k8s-version = "0.4.3";
      in
      {
        packages.score-compose = pkgs.buildGoModule {
          pname = "score-compose";
          version = score-compose-version;
          src = score-compose-src;

          modVendor = false;         # Don't require vendor dir
          vendorHash = "sha256-fWV5Gr86CjuKX4HC1N9pu+b7HaOJJzGdN5eElg8SOvM=";

          subPackages = [ "cmd/score-compose" ];

          doCheck = false;
        };
          packages.score-k8s = pkgs.buildGoModule {
            pname = "score-k8s";
            version = score-k8s-version;
            src = score-k8s-src;

            modVendor = false;
            vendorHash = "sha256-iGJnFEsp5BMG8L1HEe+hjvAbpxa+YI+hSJvTocFV3f4="; # placeholder

            subPackages = [ "cmd/score-k8s" ];

            doCheck = false;
          };

        devShells.default = pkgs.mkShell {
          name = "ansible-shell";

          buildInputs = with pkgs; [
            # The score-compose executable built by this flake.
            self.packages.${system}.score-compose
            self.packages.${system}.score-k8s

            # Go development tools.
            go
            gopls # Go language server
            gotools # Additional Go tools (goimports, etc.)
            delve # Go debugger

            ansible
            git
            rsync
          ];

          shellHook = ''
            export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
            export ANSIBLE_COLLECTIONS_PATH="$PWD/ansible/collections"

             source ./secrets.env

            # install galaxy roles/collections into project-local dir
            if [ -f requirements.yml ]; then
              echo "Installing Ansible Galaxy collections..."
              ansible-galaxy collection install -r requirements.yml --collections-path ./ansible/collections
            fi
          '';
        };
      }
    );
}
