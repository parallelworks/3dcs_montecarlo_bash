#!/bin/bash
cd $(dirname $0)

source inputs.sh
source workflow-libs.sh

create_case(){
    case_dir=simulation_${case_index}
    mkdir -p ${case_dir}

    echo "    Writing job script"
    cp batch_header.sh  ${case_dir}/run_case.sh

    if [[ ${jobschedulertype} == "SLURM" ]]; then 
        echo "#SBATCH -o ${resource_jobdir}/logs_${case_index}.out" >> ${case_dir}/run_case.sh
        echo "#SBATCH -e ${resource_jobdir}/logs_${case_index}.out" >> ${case_dir}/run_case.sh
    elif [[ ${jobschedulertype} == "PBS" ]]; then
        echo "#PBS -o ${resource_jobdir}/logs_${case_index}.out" >> ${case_dir}/run_case.sh
        echo "#PBS -e ${resource_jobdir}/logs_${case_index}.out" >> ${case_dir}/run_case.sh
    fi
    
    # Main script
    echo "mkdir -p ${PWD}/${case_dir}" >> ${case_dir}/run_case.sh
    echo "cd ${PWD}/${case_dir}" >> ${case_dir}/run_case.sh
    
    # FIXME: This is needed because run directory is not shared between controller and compute nodes
    echo "rsync -avzq ${resource_privateIp}:${PWD}/${case_dir}/ ."  >> ${case_dir}/run_case.sh

    # Main script
    echo >> ${case_dir}/run_case.sh
    cat inputs.sh >> ${case_dir}/run_case.sh
    echo "export case_index=${case_index}" >> ${case_dir}/run_case.sh
    echo >> ${case_dir}/run_case.sh
    cat run_case.sh >> ${case_dir}/run_case.sh

    echo; cat ${case_dir}/run_case.sh

}

echo; echo; echo "CREATING JOB SCRIPTS"
for case_index in $(seq 1 ${dcs_concurrency}); do
    echo; echo "  Case ${case_index}"
    create_case
done

echo; echo; echo "SUBMITTING JOB SCRIPTS"
for case_index in $(seq 1 ${dcs_concurrency}); do
    case_dir=simulation_${case_index}
    echo; echo "  Case ${case_index}"

    submit_job_sh=${case_dir}/run_case.sh
    echo "  Job script ${submit_job_sh}"

    if [[ ${jobschedulertype} == "SLURM" ]]; then 
        job_id=$(${submit_cmd} ${submit_job_sh} | tail -1 | awk -F ' ' '{print $4}')
    elif [[ ${jobschedulertype} == "PBS" ]]; then
        job_id=$(${submit_cmd} ${submit_job_sh} | tail -1)
    fi
    
    if [ -z "${job_id}" ]; then
        echo "  ERROR: ${submit_cmd} ${submit_job_sh} failed"
    else
        echo "  Submitted job ${job_id}"
        echo ${job_id} > ${PWD}/${case_dir}/job_id.submitted
    fi
done



echo; echo "CHECKING JOBS STATUS"
while true; do
    date
    submitted_jobs=$(find . -name job_id.submitted)

    if [ -z "${submitted_jobs}" ]; then
        if [[ "${FAILED}" == "true" ]]; then
            echo "ERROR: Jobs [${FAILED_JOBS}] failed"
            exit 1
        fi
        echo "  All jobs are completed. Please check job logs in directories [${case_dirs}] and results"
        break
    fi

    for sj in ${submitted_jobs}; do
        jobid=$(cat ${sj})
        get_job_status
        job_status_ec=$?
        echo "  Status of job ${jobid} is ${job_status} with exit code ${job_status_ec}"
        if [ ${job_status_ec} -eq 1 ]; then
            # Job completed
            mv ${sj} ${sj}.completed
            case_dir=$(dirname ${sj} | sed "s|${PWD}/||g")
            #scp ${resource_publicIp}:${resource_jobdir}/${case_dir}/pw-${job_id}.out ${case_dir}
        elif [ ${job_status_ec} -eq 2 ]; then
            # Job failed
            FAILED=true
            FAILED_JOBS="${job_id}, ${FAILED_JOBS}"
        fi
    done
    sleep 30
done

#echo; echo "TRANSFERRING RESULTS TO PW"
#rsync -avzq ${PWD}/ usercontainer:${PW_RESOURCE_DIR}/
