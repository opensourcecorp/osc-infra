clean:
	rm -rf ./baseimg/output-*
	find . -type l -delete
	for box in $$(vagrant box list | awk '{ print $$1 }'); do vagrant box remove "$${box}" || true ; done
	find . -type d -name '.vagrant' -exec rm -rf {} +
	find . -type d -name '.packer.d' -exec rm -rf {} +
	find ./infracode -name 'docs' -exec rm -rf {} +
