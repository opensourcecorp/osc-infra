test:
	@printf 'No tests specified for osc-infra right now\n'

clean:
	find . -type d -name '.vagrant' -exec rm -rf {} +
	find . -type d -name '.packer.d' -exec rm -rf {} +
	find ./infracode -name 'docs' -exec rm -rf {} +
