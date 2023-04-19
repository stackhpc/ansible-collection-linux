#!/usr/bin/env bash

# Run Ansible collection sanity tests.

set -e

ANSIBLE_COLLECTIONS_PATH=$(mktemp -d)
mkdir -p "${ANSIBLE_COLLECTIONS_PATH}/ansible_collections/stackhpc/linux"
trap 'rm -rf ${ANSIBLE_COLLECTIONS_PATH}' err exit
ansible-galaxy collection build --force
ansible-galaxy collection install stackhpc-linux-*.tar.gz --collections-path "${ANSIBLE_COLLECTIONS_PATH}" --force
PY_VER=$(python3 -c "from platform import python_version;print(python_version())" | cut -f 1,2 -d".")
cd "${ANSIBLE_COLLECTIONS_PATH}/ansible_collections/stackhpc/linux"
ansible-test sanity -v --venv --python "${PY_VER}"
