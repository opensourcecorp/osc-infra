app_name = "configmgmt"

# This looks kind of gross/brittle, but a) it's assumed that all OSC repos would
# sit in the same root subdir (and so configmgmt is imgbuilder's directory neighbor), and
# b) it lets imgbuilder-local symlinking work
source_files = [
  # "../configmgmt/scripts",
  "../configmgmt/salt"
]
