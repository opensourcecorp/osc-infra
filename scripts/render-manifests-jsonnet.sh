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
    "${svc_path}/main.jsonnet" \
  | yq --output-format=yaml --prettyPrint '.[] | split_doc' \
  >> "${rendered_output_root_dir}/${svc_name}.yaml"
done

printf 'Rendered manifests to "%s"\n' "${rendered_output_root_dir}"
