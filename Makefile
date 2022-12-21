INPUT ?= src/session--composition-and-inheritance/index.tex
OUTPUT ?= $(shell basename "$(shell dirname "$(INPUT)")")
PWD = "$(shell pwd)"
OUTPUT_DIRECTORY ?= build
LATEXMK_ARGS ?= -pdflua -halt-on-error -MP -logfilewarninglist -shell-escape -interaction=nonstopmode -file-line-error -output-directory=$(OUTPUT_DIRECTORY)
TEXINPUTS = "$(PWD)/src//:"

TEXLIVE_RUN = TEXINPUTS=$(TEXINPUTS)
LATEXMK_COMMAND = HOME=$(OUTPUT_DIRECTORY) $(TEXLIVE_RUN) latexmk $(LATEXMK_ARGS)

TEXMFHOME = $(shell kpsewhich -var-value=TEXMFHOME)
INSTALL_DIR = $(TEXMFHOME)/tex/latex

# Make does not offer a recursive wildcard function, so here's one:
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

.PHONY: build view

%:
	$(MAKE) build INPUT=src/$@/index.tex

build-latex-presentation :
	$(LATEXMK_COMMAND) -jobname=latex-presentation src/session--composition-and-inheritance/index.tex

build-pandoc-presentation :
	HOME=$(OUTPUT_DIRECTORY) pandoc src/pandoc/presentation/*.md --pdf-engine=lualatex --from markdown --slide-level 2 --shift-heading-level=0 -s --to=beamer --template=beamer-theme-ec.latex -o pandoc-presentation.pdf

latexindent :
	$(TEXLIVE_RUN) latexindent

clean :
	rm -rf build

lint :
	# $(foreach file, $(call rwildcard,$(shell dirname "$(INPUT)"),*.tex), lacheck $(file);)
	# $(foreach file, $(call rwildcard,$(shell dirname "$(INPUT)"),*.tex), chktex $(file);)
	$(foreach file, $(call rwildcard,$(shell dirname "$(INPUT)"),*.tex), latexindent -l -w $(file);)

chmodbuild:
	$(TEXLIVE_RUN) chmod 777 build

watch:
	$(LATEXMK_COMMAND) -pvc -jobname=$(OUTPUT) $(INPUT)
	$(MAKE) chmodbuild

fresh:
	$(MAKE) chmodbuild clean build

buildall:
	$(MAKE) clean
	$(foreach file, $(wildcard src/**/index.tex), $(MAKE) build INPUT=$(file);)

install:
	rm -rf $(INSTALL_DIR)
	mkdir -p $(INSTALL_DIR)
	ln -s $(PWD) $(INSTALL_DIR)
