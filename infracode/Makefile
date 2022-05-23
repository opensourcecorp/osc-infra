docs:
	@find providers -mindepth 3 -maxdepth 3 -type d \
	| xargs -I{} sh -c 'mkdir -p {}/docs && terraform-docs markdown table {} > {}/docs/README.md'
