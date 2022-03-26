# TODO: when pulled from here for Consul member registration, this will ONLY
# WORK for the first server that comes up in this group, since member names need
# to be unique. Find a way to make this unique, *so that it persists with
# idempotency across salt-calls*
app_name: gnar-web
system_user: concourse

concourse_node_type: web
concourse_runas_user: concourse
concourse_work_dir: /opt/concourse
concourse_vars_file: /opt/concourse/web.vars
concourse_session_signing_key: /opt/concourse/keys/session_signing_key
concourse_tsa_host_key: /opt/concourse/keys/tsa_host_key
concourse_tsa_public_key: /opt/concourse/keys/tsa_host_key.pub
concourse_tsa_worker_private_key: /opt/concourse/keys/worker_key
concourse_tsa_authorized_keys: /opt/concourse/keys/authorized_worker_keys
