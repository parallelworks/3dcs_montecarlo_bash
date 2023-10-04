#!/bin/bash
cd $(dirname $0)

source inputs.sh
source workflow-libs.sh

echo; echo; echo "MERGING RESULTS"
pwd
echo "    Writing job script"
cp batch_header.sh merge.sh

if [[ ${jobschedulertype} == "SLURM" ]]; then 
    echo "#SBATCH -o ${resource_jobdir}/logs_merge.out" >> merge.sh
    echo "#SBATCH -e ${resource_jobdir}/logs_merge.out" >> merge.sh
elif [[ ${jobschedulertype} == "PBS" ]]; then
    echo "#PBS -o ${resource_jobdir}/logs_merge.out" >> merge.sh
    echo "#PBS -e ${resource_jobdir}/logs_merge.out" >> merge.sh
fi
    
# FIXME: This is needed because run directory is not shared between controller and compute nodes
echo "rsync -avzq ${resource_privateIp}:${PWD}/ ."  >> merge.sh


# Main script
cat inputs.sh >> merge.sh
cat merge_dcs.sh >> merge.sh

# FIXME: This is needed because run directory is not shared between controller and compute nodes
#echo "rsync -avzq . ${resource_privateIp}:${PWD}/"  >> merge.sh

echo; cat merge.sh


echo; echo; echo "SUBMITTING MERGE JOB"
submit_job_sh=./merge.sh
echo "  Job script ${submit_job_sh}"

if [[ ${jobschedulertype} == "SLURM" ]]; then 
    jobid=$(${submit_cmd} ${submit_job_sh} | tail -1 | awk -F ' ' '{print $4}')
elif [[ ${jobschedulertype} == "PBS" ]]; then
    jobid=$(${submit_cmd} ${submit_job_sh} | tail -1)
fi
    
if [ -z "${jobid}" ]; then
    echo "  ERROR: ${submit_cmd} ${submit_job_sh} failed"
    exit 1
fi

wait_job