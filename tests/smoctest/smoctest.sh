#!/bin/bash

test_dir="$(dirname "$0")"
mptoolcp_dir="$(dirname "$0")/../.."
parent_path=$( cd "$(dirname "${BASH_SOURCE}")" ; pwd -P )

source ${mptoolcp_dir}/mptoolcp.sh
source ${test_dir}/config.sh


