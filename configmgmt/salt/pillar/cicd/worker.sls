# TODO: when pulled from here for Consul member registration, this will ONLY
# WORK for the first server that comes up in this group, since member names need
# to be unique. Find a way to make this unique, *so that it persists with
# idempotency across salt-calls*
app_name: cicd-worker

concourse_node_type: worker
concourse_runas_user: root
concourse_work_dir: /opt/concourse/worker
concourse_vars_file: /opt/concourse/worker.vars

concourse_runtime: containerd
concourse_containerd_bin: /opt/concourse/concourse/bin/containerd
concourse_containerd_init_bin: /opt/concourse/concourse/bin/init
concourse_containerd_cni_plugins_dir: /opt/concourse/concourse/bin
concourse_baggageclaim_overlays_dir: /opt/concourse/worker/overlays
concourse_baggageclaim_volumes: /opt/concourse/worker/volumes
concourse_session_signing_key: /opt/concourse/keys/session_signing_key

concourse_tsa_host_key: /opt/concourse/keys/tsa_host_key
concourse_tsa_public_key: /opt/concourse/keys/tsa_host_key.pub
concourse_tsa_worker_private_key: /opt/concourse/keys/worker_key
concourse_tsa_authorized_keys: /opt/concourse/keys/authorized_worker_keys
