#!/bin/bash
# Windows MinGW bash script for running a 3DCS task

in_name=$(basename ${dcs_model_file%.*})

echo "TRANSFERRING RESULTS FROM PW"
destination="./Results/"
origin="usercontainer:${PW_JOB_DIR}/Results/"
rsync -avzq -e "ssh -J ${resource_privateIp}" ${origin} ${destination}

echo "TRANSFERRING MODEL FILE FROM PW"
origin="usercontainer:${PW_JOB_DIR}/models/${dcs_model_file}"
rsync -avzq -e "ssh -J ${resource_privateIp}" ${origin} ${dcs_model_file}

sleep 60

#export DCS2FLMD_LICENSE_FILE="27000@172.31.44.156"

# generate the 3DCS macro script for the run
echo "Writing Macro File..."
echo

num_runs=$(ls -1q Results/*.hst | wc -l)

cat > macroScript.txt <<END
//Generic Needed
DCSVERS	200
DCSMSSG	1  0 // 1st 0 MEANS print-msg is OFF; 2nd 0 MEANS using RELATIVE path
DCSWORK .
DCSCOMPLIANT  0 //load compliant or not: 0 -- not load; otherwise -- load
DCSMECHANICAL  0 //load Mechanical AddIn or not: 0 -- not load; otherwise -- load
DCSLOAD_CFG dcs4d.cfg

//load a model (wtx) 
DCSLOAD $in_name.wtx

//merge results files (in Results folder)
#DCS_MERGE_HST $num_runs merged.hst
DCSSIMU_MERGE $num_runs merged.hst
END

# write the merge indices
for f in Results/*.hst;do
    echo "DCS_DATA $(basename $f)" >> macroScript.txt
done

echo >> macroScript.txt
echo "DCSSIMU_LOAD merged" >> macroScript.txt
echo "DCSREPORT_GEN 1 ./reports" >> macroScript.txt

cat macroScript.txt 

# Load 3dcs environment
if ! [ -z "${dcs_load}" ]; then
    "${dcs_load}"
fi

# Run 3dcs
"${dcs_run}"  macroScript.txt

echo "TRANSFERRING RESULTS TO PW"
origin="Results/"
destination="usercontainer:${PW_JOB_DIR}/Results/"
rsync -avzq -e "ssh -J ${resource_privateIp}" ${origin} ${destination}