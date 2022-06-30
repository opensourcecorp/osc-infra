app_name = "baseimg"

# This looks kind of gross/brittle, but a) it's assumed that all OSC repos would
# sit in the same root subdir (and so configmgmt is baseimg's directory neighbor), and
# b) it lets baseimg-local symlinking work. baseimg needs the Salt SLS files from
# configmgmt for itself, too
source_files = [
  "../configmgmt/salt"
]
