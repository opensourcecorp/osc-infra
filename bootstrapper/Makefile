clean-everything-locally:
	rm -rf ../baseimg/output-*
	find .. -type l -delete
	for box in $$(vagrant box list | awk '{ print $$1 }'); do vagrant box remove "$${box}" || true ; done
	find .. -type d -name '.vagrant' -exec rm -rf {} +
	find .. -type d -name '.packer.d' -exec rm -rf {} +
	find .. -type d -name '.terraform.d' -exec rm -rf {} +
	find .. -type d -path '*/infracode/*/.terraform' -exec rm -rf {} +
	find ../infracode -name 'docs' -exec rm -rf {} + # TODO: we def want docs, but they fail the markdown linters right now
