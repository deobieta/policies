# SPDX-FileCopyrightText: Copyright 2026 Carabiner Systems, Inc
# SPDX-License-Identifier: Apache-2.0

# policyctl runs at the version pinned by the tool directive in go.mod.
# Override it to use another build: make docs POLICYCTL=/path/to/policyctl
POLICYCTL ?= go tool policyctl

# Policy files that must not be documented, as paths relative to this file.
DOC_EXCLUDE :=

# Policy sources: every .hjson file, plus every .json file without an .hjson
# sibling (the .hjson version is the source of truth when both exist).
# Fixtures under testdata and dot directories are never sources.
HJSON_SOURCES := $(sort $(shell find . \( -path ./testdata -o -path './.*' \) -prune -o -name '*.hjson' -print | sed 's|^\./||'))
JSON_SOURCES  := $(sort $(shell find . \( -path ./testdata -o -path './.*' \) -prune -o -name '*.json' -print | sed 's|^\./||'))
POLICY_SOURCES := $(filter-out $(DOC_EXCLUDE),$(HJSON_SOURCES) $(filter-out $(HJSON_SOURCES:.hjson=.json),$(JSON_SOURCES)))

# One document per source, next to it with the .md extension, and one index
# per directory holding sources, as its README.md.
POLICY_DOCS    := $(addsuffix .md,$(basename $(POLICY_SOURCES)))
POLICY_DIRS    := $(sort $(dir $(POLICY_SOURCES)))
POLICY_INDEXES := $(addsuffix README.md,$(POLICY_DIRS))

.PHONY: docs
docs: $(POLICY_DOCS) $(POLICY_INDEXES) ## Generate the documentation of every policy material and the per directory indexes

# The .hjson rule comes first so it wins over a .json sibling.
%.md: %.hjson
	$(POLICYCTL) doc -o $@ $<

%.md: %.json
	$(POLICYCTL) doc -o $@ $<

# Each index lists the sources of its directory and is refreshed whenever
# one of them changes. Text outside the index markers of an existing
# README.md is preserved, so titles and introductions can be hand written.
define INDEX_RULE
$(1)README.md: $(foreach s,$(POLICY_SOURCES),$(if $(filter $(1),$(dir $(s))),$(s)))
	$$(POLICYCTL) doc index --title "$(patsubst %/,%,$(1))" -o $$@ $$^
endef
$(foreach d,$(POLICY_DIRS),$(eval $(call INDEX_RULE,$(d))))
