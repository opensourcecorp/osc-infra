app_name = "aether"

# This looks kind of gross/brittle, but a) it's assumed that all OSC repos would
# sit in the same root subdir (and so aether is ymir's directory neighbor), and
# b) it lets ymir-local symlinking work
source_files = [
  # "../aether/scripts",
  "../aether/salt"
]
