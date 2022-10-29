{
  description = "LaTeX document European Commission";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    theme-ec.url = "git+https://code.europa.eu/pol/european-commission-latex-beamer-theme/";
  };

  outputs = { self, nixpkgs, flake-utils, theme-ec, ... }@inputs:
    with flake-utils.lib; eachSystem allSystems (system:
      let
        version = self.shortRev or self.lastModifiedDate;

        overlays = [
          theme-ec.overlays.default
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-full latex-bin latexmk;

          latex-theme-ec = {
              pkgs = [ pkgs.latex-theme-ec ];
          };
        };

        documentProperties = {
          name = "ec-presentation";
          inputs = [
            tex
            pkgs.coreutils
            pkgs.gnumake
            pkgs.imagemagick
            pkgs.plantuml
            # pkgs.pandoc
            # pkgs.plantuml
            # pkgs.nixpkgs-fmt
            # pkgs.nixfmt
            # pkgs.pympress
          ];
        };

        documentDrv = pkgs.stdenvNoCC.mkDerivation {
          name = documentProperties.name + "-" + version;
          src = self;
          buildInputs = documentProperties.inputs;
          configurePhase = ''
            runHook preConfigure
            substituteInPlace "src/session--composition-and-inheritance/version.tex" \
              --replace "dev-local" "${version}"
            runHook postConfigure
          '';
          installPhase = ''
            runHook preInstall
            cp build/session--composition-and-inheritance.pdf $out
            runHook postInstall
          '';
        };
      in
      rec {
        # Nix shell / nix build
        packages.default = documentDrv;

        # Nix develop
        devShells.default = pkgs.mkShellNoCC {
          name = documentProperties.name;
          buildInputs = documentProperties.inputs;
        };
      });
}
