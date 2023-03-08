{
  description = "Session - Composition and Inheritance";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    theme-ec.url = "git+https://code.europa.eu/pol/european-commission-latex-beamer-theme/";
    ec-fonts.url = "git+https://code.europa.eu/pol/ec-fonts/";
    ci-detector.url = "github:loophp/ci-detector";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          overlays =
            [
              inputs.theme-ec.overlays.default
            ]
            ++ inputs.nixpkgs.lib.optional (inputs.ci-detector.lib.notInCI) inputs.ec-fonts.overlays.default;

          inherit system;
        };

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-full latex-bin latexmk;

          latex-theme-ec = {
            pkgs = [pkgs.latex-theme-ec] ++ inputs.nixpkgs.lib.optional (inputs.ci-detector.lib.notInCI) pkgs.ec-square-sans-lualatex;
          };
        };

        myaspell = pkgs.aspellWithDicts (d: [d.en d.en-science d.en-computers d.fr d.be]);

        session--composition-and-inheritance = pkgs.stdenvNoCC.mkDerivation {
          name = "session--composition-and-inheritance";

          src = inputs.self;

          buildInputs = [tex pkgs.plantuml pkgs.imagemagick];

          # TMPDIR is provided by latexmk, and lualatex needs HOME to be set
          # for temporary files while building
          HOME = "$TMPDIR";
          TEXINPUTS = "$src/src//:";
          LC_ALL = "C";

          buildPhase = ''
            runHook preBuild

            rm -rf src/session--composition-and-inheritance/resources/*.png
            rm -rf src/session--composition-and-inheritance/resources/*.svg
            ${pkgs.plantuml}/bin/plantuml -tsvg src/session--composition-and-inheritance/resources/*.plantuml
            ${pkgs.imagemagick}/bin/mogrify -background transparent -density 600 -format png src/session--composition-and-inheritance/resources/*.svg

            ${tex}/bin/latexmk \
                -pdflua \
                -halt-on-error \
                -MP \
                -logfilewarninglist \
                -shell-escape \
                -interaction=nonstopmode \
                -file-line-error \
                -jobname=session--composition-and-inheritance \
                src/session--composition-and-inheritance/index.tex

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            install -m644 -D *.pdf --target $out/

            runHook postInstall
          '';
        };
      in {
        # nix fmt
        formatter = pkgs.alejandra;

        # nix build
        packages.default = session--composition-and-inheritance;

        # nix develop
        devShells.default = pkgs.mkShellNoCC {
          name = "session--composition-and-inheritance--devshell";
          buildInputs = [
            tex
            pkgs.plantuml
            pkgs.imagemagick
            pkgs.nodePackages.cspell
            pkgs.nodePackages.prettier
            myaspell
          ];
        };
      };
    };
}
