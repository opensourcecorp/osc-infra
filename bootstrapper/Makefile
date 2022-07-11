export OSC_INFRA_ROOT ?= $(shell realpath ..)

export PACKER_CACHE_DIR := "$(OSC_INFRA_ROOT)/.packer.d/packer_cache"
export TF_CLI_CONFIG_FILE := "$(OSC_INFRA_ROOT)/osc.tfrc"
export TF_PLUGIN_CACHE_DIR := "$(OSC_INFRA_ROOT)/.terraform.d/plugin-cache"

export AWS_ACCOUNT_ID = $(shell aws sts get-caller-identity --query 'Account' --output text)

clean-everything-local:
	rm -rf $(OSC_INFRA_ROOT)/baseimg/output-*
	find $(OSC_INFRA_ROOT) -type l -delete
	for box in $$(vagrant box list | awk '{ print $$1 }'); do vagrant box remove "$${box}" || true ; done
	find $(OSC_INFRA_ROOT) -type d -name '.vagrant' -exec rm -rf {} +
	find $(OSC_INFRA_ROOT) -type d -name '.packer.d' -exec rm -rf {} +
	find $(OSC_INFRA_ROOT) -type d -name '.terraform.d' -exec rm -rf {} +
	find $(OSC_INFRA_ROOT) -type d -path '*/infracode/*/.terraform' -exec rm -rf {} +
	find $(OSC_INFRA_ROOT)/infracode -name 'docs' -exec rm -rf {} + # TODO: we def want TF etc. docs, but they fail the markdown linters right now

# TODO: this doesn't currently clear out the S3 or DynamoDB contents, so you'll need to do those manually
clean-everything-aws:
	aws ec2 describe-images \
		--owners $(AWS_ACCOUNT_ID) \
		--filters Name=name,Values='osc-baseimg*' \
		--query 'Images[*].ImageId' \
		--output text \
	| xargs -I{} aws ec2 deregister-image --image-id {}
	aws ec2 describe-snapshots \
		--owner-ids $(AWS_ACCOUNT_ID) \
		--filters Name=tag:Name,Values='osc-baseimg*' \
		--query 'Snapshots[*].SnapshotId' \
		--output text \
	| xargs -I{} aws ec2 delete-snapshot --snapshot-id {}
	# describe-volumes text output has a bug, so we spit out json here instead
	aws ec2 describe-volumes \
		--filters Name=status,Values='available' \
		--query 'Volumes[*].VolumeId' \
		--output json \
	| jq -r '.[]' \
	| xargs -I{} aws ec2 delete-volume --volume-id {}

validate-infracode:
	find $(OSC_INFRA_ROOT) -name 'main.pkr.hcl' | xargs -I{} bash -c 'cd $$(dirname {}) && packer fmt .'
	find $(OSC_INFRA_ROOT) -name 'main.tf' | xargs -I{} bash -c 'cd $$(dirname {}) && terraform init -backend=false && terraform fmt && terraform validate'
