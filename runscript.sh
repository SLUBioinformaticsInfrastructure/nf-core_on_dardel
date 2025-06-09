#! /usr/bin/env bash

# Adapted from https://github.com/NBISweden/assembly-project-template/pull/21/files
# Thanks to Mahesh Binzer-Panchal for developing this script and letting us adapt it!

set -euo pipefail

function get_cluster_name {
    if command -v sacctmgr >/dev/null 2>&1; then
        # Only return cluster names we're catering for
        sacctmgr show cluster -P -n \
        | cut -f1 -d'|' \
        | grep "rackham\|dardel"
    fi
}

function clean_nextflow_cache {
    local WORKDIR=$1  # Path to Nextflow work directory
    # Clean up Nextflow cache to remove unused files
    nextflow clean -f -before "$( nextflow log -q | tail -n 1 )"
    # Clean up empty work directories
    find "$WORKDIR" -type d -empty -delete
}

function run_nextflow {
    PROFILE="${PROFILE:-$1}"                                                               # Profile to use (values: uppmax, dardel)
    STORAGEALLOC="$2"                                                                      # NAISS storage allocation (path)
    WORKDIR="${PWD/\/cfs\/klemming\/projects\/supr/$PDC_TMP}/analyses/nxf-work"            # Nextflow work directory, now in the executing persons scratch
    RESULTS="${PWD}/outputs"                                                               # Path to store results from Nextflow

    # Set common path to store all Singularity containers
    export NXF_SINGULARITY_CACHEDIR="${PWD}/analyses/singularity-cache"

    # Column 4 = STATUS is also space padded, hence the tr -d " "
    # possible STATUS values: "" - first run, "-" - manually cancelled/killed, "OK", "ERR"
    if test "$( nextflow log | tail -n 1 | cut -f 4 | tr -d " " )" == "ERR"; then
        echo "WARN: Cleaning results folder due to previous error" >&2
        rm -rf "$RESULTS"
        # Clean cache to prevent build up of failed run work directories
        clean_nextflow_cache "$WORKDIR"
    fi

    # Run Nextflow
    nextflow run nf-core/mag \
        -r 3.4.0 \
        -latest \
        -profile "$PROFILE" \
        -work-dir "$WORKDIR" \
        -resume \
        -ansi-log false \
        -params-file params.yml \
        --outdir "$RESULTS"
        # -with-dag

    clean_nextflow_cache "$WORKDIR"
    
    # change permissions so all members of the project can access the files
    # thanks to Karl Johan from PDC support for this useful tidbit!
    # change the file ownership to group:
    chgrp --no-dereference --silent --recursive ${GRP} ${PWD}
    # change permission: group gets user's permissions
    chmod --silent --recursive g=u ${PWD}

}

# Detect cluster name ( rackham, dardel )
cluster=$( get_cluster_name )
echo "Running on HPC=$cluster."

# Run Nextflow with appropriate settings
if [ "$cluster" == "dardel" ]; then
    module load PDC apptainer
    export APPTAINER_CACHEDIR=$PDC_TMP/apptainer/cache
    export SINGULARITY_CACHEDIR=$PDC_TMP/singularity/cache
    run_nextflow pdc_kth path_to_project_directory
else 
    echo "Error: unrecognised cluster '$cluster'." >&2
    exit 1
fi
