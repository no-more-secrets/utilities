# Make a symlink called `Makefile` in the top-level of the
# project which is linked to this file.
.DEFAULT_GOAL := all
builds        := .builds
build-current := .builds/current
stamp-file    := $(build-current)/last-build-stamp
cmake-utils   := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

-include $(build-current)/env-vars.mk

pre-build := $(if $(wildcard scripts/pre-build.sh),scripts/pre-build.sh,:)

cmake_targets := all clean test rn cmake-run

ifeq ($(origin, NINJA_STATUS_PRINT_MODE),)
	NINJA_STATUS_PRINT_MODE=scrolling
endif

export DSICILIA_NINJA_STATUS_PRINT_MODE=$(NINJA_STATUS_PRINT_MODE)
export DSICILIA_NINJA_REFORMAT_MODE=pretty

build-config := $(notdir $(realpath $(build-current)))
ifneq (,$(wildcard $(build-current)/Makefile))
    # Here we are invoking $(MAKE) directly instead of using
    # cmake because otherwise there seem to be issues with
    # propagating the jobserver.  For this same reason we
    # also do not just put the whole command into a variable
    # and just define the targets once.
    $(cmake_targets): $(build-current)
	    @$(pre-build)
	    @cd $(build-current) && $(MAKE) -s $@
	    @touch $(stamp-file)
else
    # Use cmake to build here because it is the preferred
    # way to go when it works for us (which it does in this
    # case).
    $(cmake_targets): $(build-current)
	    @$(pre-build)
	    @cd $(build-current) && ninja $@
	    @touch $(stamp-file)
endif

clean-target := $(if $(wildcard $(builds)),clean,)

run:
	@$(MAKE) -s all # somehow `exe` doesn't clear the screen.
	@$(MAKE) -s cmake-run

# Need to have `clean` as a dependency before removing the
# .builds folder because some outputs of the build are in the
# source tree and we need to clear them first.
distclean: $(clean-target)
	@rm -rf .builds

update:
	@git pull origin `git rev-parse --abbrev-ref HEAD` --quiet
	@git submodule sync --quiet
	@git submodule update --init
	@: bash $(cmake-utils)/outdated.sh -v
	@cmc rc
	@$(MAKE) -s all
	@$(MAKE) -s test

what:
	@$(cmake-utils)/outdated.sh -v

$(build-current):
	@cmc

.PHONY: $(cmake_targets) update what run
