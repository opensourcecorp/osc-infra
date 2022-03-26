#!/usr/bin/env bash
set -euo pipefail

pipelines_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

[[ -d "${pipelines_dir}" ]] || {
  printf 'ERROR: Could not resolve path to gnar pipeline definition files (%s) on host!\n' "${pipelines_dir}" > /dev/stderr
  exit 1
}

action="${1:-set}"

# Core repo pipelines
while read -r line; do
  # Skip commented lines in config
  if grep -qE '^#.*' <<< "${line}"; then
    continue
  else
    repo_name=$(awk '{ print $1 }' <<< "${line}")
    repo_uri=$(awk '{ print $2 }' <<< "${line}")
    repo_branch=$(awk '{ print $3 }' <<< "${line}")
    # Can't get this to parse right right now
    # varflags="--var \"repo.name=${repo_name}\" --var \"repo.uri=${repo_uri}\" --var \"repo.branch=${repo_branch}\""
  fi

  if [[ "${action}" == 'set' ]]; then
    printf 'Setting up pipeline %s, address %s, branch %s\n' "${repo_name}" "${repo_uri}" "${repo_branch}"
    
    fly validate-pipeline \
      --config "${pipelines_dir}"/_core.yaml \
      --var "repo.name=${repo_name}" \
      --var "repo.uri=${repo_uri}" \
      --var "repo.branch=${repo_branch}"
    fly -t main set-pipeline \
      --pipeline "${repo_name}" \
      --config "${pipelines_dir}"/_core.yaml \
      --var "repo.name=${repo_name}" \
      --var "repo.uri=${repo_uri}" \
      --var "repo.branch=${repo_branch}" \
      --non-interactive
    fly -t main unpause-pipeline \
      --pipeline "${repo_name}"
  elif [[ "${action}" == 'destroy' ]]; then
    fly -t main destroy-pipeline \
      --pipeline "${repo_name}" \
      --non-interactive
  fi
done < "${pipelines_dir}"/pipelines.txt

# for pipeline in "${pipelines_dir}"/*; do
#   fly validate-pipeline \
#     -c "${pipeline}" \
#     --var "repo.name=${pipeline}" \
#   # fly -t main set-pipeline
#   echo "${pipeline}"
# done
