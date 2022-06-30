AWS_ACCOUNT_ID = $(shell aws sts get-caller-identity --query 'Account' --output text)

clean-everything-local:
	rm -rf ../baseimg/output-*
	find .. -type l -delete
	for box in $$(vagrant box list | awk '{ print $$1 }'); do vagrant box remove "$${box}" || true ; done
	find .. -type d -name '.vagrant' -exec rm -rf {} +
	find .. -type d -name '.packer.d' -exec rm -rf {} +
	find .. -type d -name '.terraform.d' -exec rm -rf {} +
	find .. -type d -path '*/infracode/*/.terraform' -exec rm -rf {} +
	find ../infracode -name 'docs' -exec rm -rf {} + # TODO: we def want docs, but they fail the markdown linters right now

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

format-infracode:
	find .. -name 'main.pkr.hcl' | xargs -I{} bash -c 'cd $$(dirname {}) && packer fmt .'
	find .. -name 'main.tf' | xargs -I{} bash -c 'cd $$(dirname {}) && terraform fmt'
