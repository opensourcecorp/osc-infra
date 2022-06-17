test:
	@printf 'No tests specified for osc-infra right now\n'

clean:
	rm -rf ./imgbuilder/output-*
	for box in $$(vagrant box list | awk '{ print $$1 }'); do vagrant box remove "$${box}" ; done
	find . -type d -name '.vagrant' -exec rm -rf {} +
	find . -type d -name '.packer.d' -exec rm -rf {} +
	find ./infracode -name 'docs' -exec rm -rf {} +
