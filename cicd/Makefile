SHELL = /usr/bin/env bash -euo pipefail

local-test:
# If YMIR_LOCAL is exported, this script will use that; useful for if you're
# developing on the imgbuilder repo itself
	@bash scripts/local-test.sh

get-imgbuilder-local:
	@cp -r ../imgbuilder/* ./imgbuilder/
