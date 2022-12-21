{
  description = "LaTeX document European Commission";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ec-theme.url = "git+https://code.europa.eu/pol/european-commission-latex-beamer-theme/";
    ec-fonts.url = "git+https://code.europa.eu/pol/ec-fonts/";
    ci-detector.url = "github:loophp/ci-detector";
  };

  outputs = { self, nixpkgs, flake-utils, ec-theme, ec-fonts, ci-detector, ... }@inputs:
    with flake-utils.lib; eachSystem allSystems (system:
      let
        version = self.shortRev or self.lastModifiedDate;

        pkgs = import nixpkgs {
          overlays = [
            ec-theme.overlays.default
            ec-fonts.overlays.default
          ];
          inherit system;
        };

        tex = pkgs.texlive.combine {
            inherit (pkgs.texlive) scheme-full latex-bin latexmk;

            latex-theme-ec = {
                pkgs = [ pkgs.latex-theme-ec pkgs.ec-square-sans-lualatex ];
            };
        };

        tex-for-ci = pkgs.texlive.combine {
            inherit (pkgs.texlive) scheme-full latex-bin latexmk;

            latex-theme-ec = {
                pkgs = [ pkgs.latex-theme-ec ];
            };
        };

        latex-presentation = pkgs.stdenvNoCC.mkDerivation {
          name = "ec-presentation-" + version;
          src = pkgs.lib.cleanSource ./.;
          buildInputs = [
            pkgs.coreutils
            pkgs.gnumake
            pkgs.imagemagick
            pkgs.plantuml
          ];
          buildPhase = ''
            runHook preBuild
            make build-latex-presentation
            runHook postBuild
          '';
          configurePhase = ''
            runHook preConfigure
            substituteInPlace "src/session--composition-and-inheritance/version.tex" \
              --replace "dev-local" "${version}"
            runHook postConfigure
          '';
          installPhase = ''
            runHook preInstall
            install -m644 -D build/*.pdf --target $out/
            runHook postInstall
          '';
        };

        myaspell = pkgs.aspellWithDicts (d: [d.en d.en-science d.en-computers d.fr d.be]);
      in
      {
        # Nix shell / nix build
        packages.default = if ci-detector.lib.inCI then
            (latex-presentation.overrideAttrs (oldAttrs: {
                buildInputs = [ oldAttrs.buildInputs ] ++ [ tex-for-ci ];
            }))
        else
            (latex-presentation.overrideAttrs (oldAttrs: {
                buildInputs = [ oldAttrs.buildInputs ] ++ [ tex ];
            }));

        # Nix develop
        devShells.default = pkgs.mkShellNoCC {
          name = "ec-presentation-devshell";
          buildInputs = [
            tex
            pkgs.gnumake
            pkgs.nodePackages.cspell
            pkgs.nodePackages.prettier
            myaspell
            pkgs.inotify-tools
            pkgs.nixpkgs-fmt
            pkgs.nixfmt
          ];
        };
      });
}
