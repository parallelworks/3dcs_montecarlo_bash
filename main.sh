#!/bin/bash
source inputs.sh

# Use the resource wrapper
source /etc/profile.d/parallelworks.sh
source /etc/profile.d/parallelworks-env.sh
source /pw/.miniconda3/etc/profile.d/conda.sh
conda activate
python3 /swift-pw-bin/utils/input_form_resource_wrapper.py 

# Load useful functions
source workflow-libs.sh

# Run job on remote resource
cluster_rsync_exec