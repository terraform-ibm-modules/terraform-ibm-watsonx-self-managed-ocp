#!/bin/bash

schematics_tmp_dir_exists=false
schematics_tmp_dir_path="/tmp/.schematics"
if [[ -d ${schematics_tmp_dir_path} ]]; then
	schematics_tmp_dir_exists=true
fi

jq -n \
	--arg schematics_tmp_dir_exists "$schematics_tmp_dir_exists" \
	'{"schematics_tmp_dir_exists":$schematics_tmp_dir_exists}'
