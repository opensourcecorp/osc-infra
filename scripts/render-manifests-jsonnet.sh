#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar

env="${1:-}"
if [[ -z "${env}" ]] ; then
  printf 'ERROR: env name not specified as first script arg\n'
  exit 1
fi

root="$(git rev-parse --show-toplevel)"

# shellcheck disable=SC1091
source "${root}/scripts/utils.sh"

tag="$(get-image-tag)"
printf 'Image tag used in manifests: "%s"\n' "${tag}"

# TODO: determine this dynamically, not heuristically, always.
lb_ip_addrs=''
current_k8s_context="$(kubectl config current-context)"
if grep -q -E '^kind' <<< "${current_k8s_context}" ; then
  # Locally, kind uses the Docker bridge network, which is almost always 172.18.0.0/16, so we can
  # pool from that
  lb_ip_addrs="['172.18.255.1-172.18.255.255']"
else
  lb_ip_addrs='UNSET'
fi

jsonnet \
  --ext-str env="${env}" \
  --ext-str image_tag="${tag}" \
  ./deploy/jsonnet/skaffold.jsonnet \
| yq --output-format=yaml --prettyPrint \
> "${root}/skaffold.yaml"

printf 'Rendered %s/skaffold.yaml\n' "${root}"

rendered_output_root_dir="$(get-rendered-output-root-dir)/${env}"
rm -rf "${rendered_output_root_dir}"
mkdir -p "${rendered_output_root_dir}"

for svc_path in ./deploy/jsonnet/"${env}"/*/ ; do
  printf 'Processing inputs from "%s"\n' "${svc_path}"
  svc_name="$(basename "${svc_path}")"
  printf -- '---\n' > "${rendered_output_root_dir}/${svc_name}.yaml"
  jsonnet \
    --ext-str image_name="docker.io/library/nginx" \
    --ext-str image_tag="alpine" \
    --ext-code lb_ip_addrs="${lb_ip_addrs}" \
    "${svc_path}/main.jsonnet" \
  | yq --output-format=yaml --prettyPrint '.[] | split_doc' \
  >> "${rendered_output_root_dir}/${svc_name}.yaml"
done

printf 'Rendered manifests to "%s"\n' "${rendered_output_root_dir}"
