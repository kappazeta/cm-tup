#!/bin/bash

# beginning of the main flow
if [ "$#" -ne 1 ]; then
    echo "Usage: ./cvat-tup.sh SRC_DIR"
    exit 1
fi

SRC_DIR=$1
CONFIG_PATH=${SRC_DIR}/cvat-tup.cfg
CLASSES_JSON_PATH=${SRC_DIR}/classes.json

# Name of the directory that hosts this script.
DIR=$(dirname "${BASH_SOURCE[0]}")
# Full path to the directory that hosts this script.
DIRPATH=$(realpath "${DIR}")
# Path to the root directory.
PATH_ROOT=$(realpath "$DIRPATH/../")

HAVE_CONDA_ENV=false

# Configuration parameters
cvat_host_addr="localhost"
cvat_host_port=8080

# ANSI colors
INF="\e[32m"
IGN="\e[30m"
ERR="\e[31;1m"
RED="\e[31;1m"
END="\e[0m"

find_tci_file() {
	local basedir=$1

	for f in ${basedir}/*_TCI_10m_*.png; do
		echo "$f"
		# We were only looking for a single file anyway.
		break
	done
}

find_cvat_file() {
	local basedir=$1

	for f in ${basedir}/*_SCL_20m_*.xml; do
		echo "$f"
		# We were only looking for a single file anyway.
		break
	done
}

check_conda() {
	if ! which conda; then
		>&2 echo -e "${RED}Please install miniconda3 ${END}"
		exit 1
	fi
}

check_conda_env() {
	local conda_env_name=$1

	echo -en "${IGN}"
	if source activate ${conda_env_name}; then
		HAVE_CONDA_ENV=true
	else
		HAVE_CONDA_ENV=false
		>&2 echo -e "${RED}Failed to activate conda environment ${conda_env_name} ${END}"
	fi
	echo -en "${END}"
}

activate_conda() {
	echo -e "${INF}Checking if conda is installed.. ${END}"
	check_conda

	check_conda_env "cvat-cli"
	if [ ! $HAVE_CONDA_ENV = true ]; then
		echo -e "${INF}Creating a new conda environment, cvat-cli ${END}"
		conda env create -f ${PATH_ROOT}/environment.yml
	else
		echo -e "${INF}We already have the conda environment cvat-cli ${END}"
	fi
}

check_classes_json() {
	local path=${CLASSES_JSON_PATH}

	echo -e "${INF}Using classes from ${path}.${END}"

	if [ ! -f ${path} ]; then
		echo -e "${ERR}Missing classes file, creating a template at ${path} ${END}"
		cp ${DIRPATH}/../share/classes_template.json ${path}
		exit 1
	fi
}

list_tasks() {
	python ${cvat_cli_path} --server-host ${cvat_host_addr} --server-port ${cvat_host_port} --auth ${cvat_credentials} ls
}

create_task() {
	local task_name=$1
	local data_path=$2

	local tci_path=$(find_tci_file "${data_path}")
	
	python ${cvat_cli_path} --server-host ${cvat_host_addr} --server-port ${cvat_host_port} --auth ${cvat_credentials} create --labels ${CLASSES_JSON_PATH} --img-quality 100 --url ${git_repository} "${task_name}" local ${tci_path} | sed -e "s/Created task ID: \([[:digit:]]\+\) .*$/\1/g"
}

delete_task() {
	local task_id=$1

	python ${cvat_cli_path} --server-host ${cvat_host_addr} --server-port ${cvat_host_port} --auth ${cvat_credentials} delete ${task_id}
}

function upload_annotations {
	local task_id=$1
	local data_path=$2

	local cvat_path=$(find_cvat_file "${data_path}")

	python ${cvat_cli_path} --server-host ${cvat_host_addr} --server-port ${cvat_host_port} --auth ${cvat_credentials} upload ${task_id} ${cvat_path} | grep -o finished
}

create_tasks_for_tiles() {
	local tasks=$1
	local max_count=3

	local count=0
	local tilename=''
	for dir in ${SRC_DIR}/tile_*/; do
		tilename=$(basename ${dir})
		if [[ "${tasks[@]}" =~ "${tilename}" ]]; then
			echo "Task ${tilename} exists"
		else
			echo "Creating task ${tilename}"
			create_task "cvat-tup ${tilename}" "${SRC_DIR}/${tilename}"
			
			# Limit the number of tasks created.
			((count+=1))
			if [ ${count} -ge ${max_count} ]; then
				break
			fi
		fi
	done
}

activate_conda
check_classes_json

echo -e "${INF}Loading configuration from ${CONFIG_PATH}.${END}"

if [ -f ${CONFIG_PATH} ]; then
	while read LINE; do declare "$LINE"; done < ${CONFIG_PATH}

	if [[ -z "${cvat_credentials}" ]]; then
		echo -e "${RED}Please provide 'credentials' for CVAT login, in ${CONFIG_PATH}${END}"
		exit 1
	fi
	if [[ -z "${cvat_cli_path}" ]]; then
		echo -e "${RED}Please provide the path to CVAT CLI utility, 'cvat_cli_path' in ${CONFIG_PATH}${END}"
		exit 1
	fi
else
	echo -e "${ERR}Missing configuration file, creating a template at ${CONFIG_PATH} ${END}"
	cp ${DIRPATH}/../share/config_template.cfg ${CONFIG_PATH}
	exit 1
fi

existing_tasks=$(list_tasks | cut -d',' -f2)
create_tasks_for_tiles "$existing_tasks"

