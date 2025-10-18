#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"

get-image-tag() {
  clean_branch_name="$(git branch --show-current | sed -E 's;origin/;;g' | sed -E 's;(/|_);-;g' | tr '[:upper:]' '[:lower:]')"
  if [[ -z "${clean_branch_name}" ]] ; then
    clean_branch_name='commit'
  fi
  branch_name="${clean_branch_name}"
  short_sha="$(git rev-parse --short HEAD)"
  dirty_suffix=''
  if [[ "$(git status --porcelain | wc -l)" -gt 0 ]]; then
    dirty_suffix='-dirty'
  fi

  tag="$(printf '%s-%s%s' "${branch_name}" "${short_sha}" "${dirty_suffix}")"

  printf '%s' "${tag}"
}

get-rendered-output-root-dir() {
  d="${root}/deploy/rendered"
  mkdir -p "${d}"
  printf '%s' "${d}"
}
