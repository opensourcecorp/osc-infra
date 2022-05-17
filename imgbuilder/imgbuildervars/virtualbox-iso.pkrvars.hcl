app_name = "imgbuilder"

# This looks kind of gross/brittle, but a) it's assumed that all OSC repos would
# sit in the same root subdir (and so configmgmt is imgbuilder's directory neighbor), and
# b) it lets imgbuilder-local symlinking work. Ymir needs the Salt SLS files from
# Aether for itself, too
source_files = [
  "../configmgmt/salt"
]

shell_provisioner = [
  # "sleep 3600",
  "mount /home/packer/VBoxGuestAdditions.iso /mnt",
  "sh /mnt/VBoxLinuxAdditions.run || true", # Guest Additions never seem to exit 0
  "modinfo vboxsf || exit 1",               # This will actually check the install status
  "umount /mnt"
]
