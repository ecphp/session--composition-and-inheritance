INPUT ?= src/session--composition-and-inheritance/index.tex
OUTPUT ?= $(shell basename "$(shell dirname "$(INPUT)")")
DOCKER_COMPOSE = docker-compose
UP = ${DOCKER_COMPOSE} up
OUTPUT_DIRECTORY = build
LATEXMK_ARGS ?= -halt-on-error -MP -logfilewarninglist -pdf -shell-escape -interaction=nonstopmode -file-line-error -output-directory=$(OUTPUT_DIRECTORY)

DOCKER_TEXINPUTS = "/home/src//:"
TEXINPUTS = "$(shell pwd)/src//:"

DOCKER_TEXLIVE_RUN = ${DOCKER_COMPOSE} run -e TEXINPUTS=$(DOCKER_TEXINPUTS) texlive
DOCKER_PANDOC_RUN = ${DOCKER_COMPOSE} run pandoc
DOCKER_PLANTUML_RUN = ${DOCKER_COMPOSE} run plantuml
DOCKER_CONVERT_RUN = ${DOCKER_COMPOSE} run imagemagick
DOCKER_LATEXMK_COMMAND = $(DOCKER_TEXLIVE_RUN) latexmk $(LATEXMK_ARGS)

TEXLIVE_RUN = TEXINPUTS=$(TEXINPUTS)
PANDOC_RUN = pandoc
PLANTUML_RUN = plantuml
CONVERT_RUN = mogrify
LATEXMK_COMMAND = $(TEXLIVE_RUN) latexmk $(LATEXMK_ARGS)

# Make does not offer a recursive wildcard function, so here's one:
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

.PHONY: docker-build build docker-build-document build-document

%:
	$(MAKE) build INPUT=src/$@/index.tex

build :
	$(MAKE) build-document

build-document:
	$(LATEXMK_COMMAND) -jobname=$(OUTPUT) $(INPUT)

asset :
	rm -rf src/session--composition-and-inheritance/resources/*.png
	$(PLANTUML_RUN) -tsvg src/session--composition-and-inheritance/resources/*.plantuml
	$(CONVERT_RUN) -background transparent -density 600 -format png src/session--composition-and-inheritance/resources/*.svg
	rm -rf src/session--composition-and-inheritance/resources/*.svg

pandoc :
	$(PANDOC_RUN) -s $(INPUT) -o $(OUTPUT)

latexindent :
	$(TEXLIVE_RUN) latexindent

clean :
	rm -rf build

lint :
	$(foreach file, $(call rwildcard,$(shell dirname "$(INPUT)"),*.tex), $(TEXLIVE_RUN) lacheck $(file);)
	$(foreach file, $(call rwildcard,$(shell dirname "$(INPUT)"),*.tex), $(TEXLIVE_RUN) chktex $(file);)
	$(foreach file, $(call rwildcard,$(shell dirname "$(INPUT)"),*.tex), $(TEXLIVE_RUN) latexindent $(file);)

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
