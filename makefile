.DEFAULT_GOAL := help

org_code := mahagri

tasks := writeTxt_
tasks := $(foreach t,$(tasks),flow/$t)

sub_tasks := translate_
sub_tasks := $(foreach s, $(foreach t,$(sub_tasks),subFlows/$t), flow/$s)


.PHONY: help install import flow export check readme lint format pre-commit $(tasks) check_env
.PHONY: trans-install translate $(sub_tasks)

help:
	$(info Please use 'make <target>', where <target> is one of)
	$(info )
	$(info   install     install packages and prepare software environment)
	$(info )
	$(info   import      import data required for processing document flow)
	$(info   flow        execute the tasks in the document flow)
	$(info   export      export the data generated by the document flow)
	$(info )
	$(info   readme      generate the readme for the flow/task directories)
	$(info )
	$(info   lint        run the code linters)
	$(info   format      reformat code)
	$(info   pre-commit  run pre-commit checks, runs yaml lint, you need pre-commit)
	$(info )
	$(info Check the makefile to know exactly what each target is doing.)
	@echo # dummy command

install: pyproject.toml
	poetry install --only=dev

check_env:
ifndef GR_DIR
	$(error GR_DIR is undefined)
endif
ifndef SECRETS_DIR
	$(error SECRETS_DIR is undefined)
endif
ifndef MODELS_DIR
	$(error MODELS_DIR is undefined)
endif



import/websites/gr.maharashtra.gov.in/Agriculture:
	cd import/websites/gr.maharashtra.gov.in/ && ln -s $(GR_DIR)/Agriculture .

.secrets/google.token:
	cd .secrets && ln -s $(SECRETS_DIR)/google.token .

import/models/ai4bharat/IndicTrans2-en/ct2_int8_model:
	mkdir -p import/models/ai4bharat/IndicTrans2-en
	cd import/models/ai4bharat/IndicTrans2-en/ && ln -sf $(MODELS_DIR)/ct2_int8_model .

import: check_env import/websites/gr.maharashtra.gov.in/Agriculture .secrets/google.token 
	poetry run python import/src/build_documents.py import/websites/gr.maharashtra.gov.in/Agriculture import/documents
	poetry run python flow/src/link_new.py import/documents flow/writeTxt_/input
	cd flow/writeTxt_/conf && ln -sf ../../subFlows/translate_/output/doc_translations.json .
	cd flow/subFlows/translate_/input && ln -sf ../../../writeTxt_/output/doc_translations_todo.json .

flow: $(tasks)
$(tasks):
	poetry run make -C $@

trans-install: import/models/ai4bharat/IndicTrans2-en/ct2_int8_model
	poetry lock
	poetry install --only=translate

translate: $(sub_tasks)
$(sub_tasks):
	poetry run make -C $@

check:
	poetry run op check

readme:
	poetry run op readme-mah

lint:
	poetry run black -q .
	poetry run ruff .

format:
	poetry run black -q .
	poetry run ruff --fix .

export: readme
	poetry run op export-mah


# Use pre-commit if there are lots of edits,
# https://pre-commit.com/ for instructions
# Also set git hook `pre-commit install`
pre-commit:
	pre-commit run --all-files
