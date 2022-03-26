SHELL = /usr/bin/env bash -euo pipefail

MY_IP := $(shell curl -fsSL -q https://ipv4.icanhazip.com/)

ifndef OSC_ROOT
$(error You MUST set the 'OSC_ROOT' environment variable)
endif

# If you pass 'only=<builder>', it will get sent to the '-only=' flag for
# 'packer build'. Can be used e.g. 'only=virtualbox-iso.main'
ifdef only
onlyflag = -only=$(only)
$(info Will only process Packer builder '$(only)' for this image build)
else
$(warning !!! WARNING -- Makefile variable 'only=' not provided; will use as many Packer builders as are defined in main.pkr.hcl. This is probably NOT what you want)
endif

prep-and-validate:
	@printf 'Will process Packer build template for target app "%s"\n' "$${app_name}"
	@if [[ -d "$${OSC_ROOT}/$${app_name}/scripts" ]]; then \
		printf 'Running Shellcheck on scripts/ dir...\n' \
		&& { find "$${OSC_ROOT}/$${app_name}"/scripts/ -name '*.sh' | xargs -I{} shellcheck {} ; } \
		&& printf "done.\n" ; \
	fi
	@printf "Grabbing any .auto.pkrvars.hcl files from ymirvars/ ...\n" \
	&& cp "$${OSC_ROOT}/$${app_name}"/ymirvars/*.auto.pkrvars.hcl . || { printf "WARNING: couldn't copy any .auto.pkrvars.hcl files from ymirvars/ in your repo's root\n" ; }
	@printf 'Running Packer init & validation...\n' \
	&& { [[ -d "${HOME}/.packer.d/plugins" ]] || packer init -upgrade . ; } \
	&& packer validate \
		-var-file "$${var_file}" \
		-- \
		. \
	&& printf "done.\n"

build: prep-and-validate
	@PKR_VAR_my_ip=$(MY_IP) \
	packer build \
		-var-file "$${var_file}" \
		-force \
		$(onlyflag) \
		-- \
		.

vagrant-box: build
	@vagrant box add --force "$${app_name}" output-vagrant-"$${app_name}"/"$${app_name}".box
