{
  description = "Ansible flake with artis3n.tailscale";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { 
    self, 
    nixpkgs, 
    flake-utils 
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {

        devShells.default = pkgs.mkShell {
          name = "ansible-shell";

          buildInputs = with pkgs; [
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
