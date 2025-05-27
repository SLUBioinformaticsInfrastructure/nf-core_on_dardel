#! /usr/bin/env bash

# Adapted from https://github.com/NBISweden/assembly-project-template/pull/21/files
# Thanks to Mahesh Binzer-Panchal for developing this script!

set -euo pipefail

function get_cluster_name {
    if command -v sacctmgr >/dev/null 2>&1; then
        # Only return cluster names we're catering for
        sacctmgr show cluster -P -n \
        | cut -f1 -d'|' \
        | grep "rackham\|dardel"
    fi
}

function run_nextflow {
    PROFILE="${PROFILE:-$1}"                                                               # Profile to use (values: uppmax, dardel)
    STORAGEALLOC="$2"                                                                      # NAISS storage allocation (path)
    WORKDIR="${PWD/\/cfs\/klemming\/projects\/supr/$PDC_TMP}/analyses/nxf-work"            # Nextflow work directory, now in the executing persons scratch
    RESULTS="${PWD}/outputs"                                                               # Path to store results from Nextflow

    # Set common path to store all Singularity containers
    export NXF_SINGULARITY_CACHEDIR="${PWD}/analyses/singularity-cache"

    # Clean results folder if last run resulted in error
    if [ "$( nextflow log | awk -F $'\t' '{ last=$4 } END { print last }' )" == "ERR" ]; then
        echo "WARN: Cleaning results folder due to previous error" >&2
        rm -rf "$RESULTS"
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

    # Clean up Nextflow cache to remove unused files
    nextflow clean -f -before "$( nextflow log -q | tail -n 1 )"
    # Use `nextflow log` to see the time and state of the last nextflow executions.
    # remove the empty working directories after the cleanup
    find "$WORKDIR" -type d -empty -delete
    
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
    run_nextflow pdc_kth path_to_project_directory
else 
    echo "Error: unrecognised cluster '$cluster'." >&2
    exit 1
fi
