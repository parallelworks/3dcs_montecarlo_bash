out_hst=$(basename ${dcs_model_file%.*})_${case_index}

echo "TRANSFERRING MODEL FILE FROM PW"
origin="usercontainer:${PW_JOB_DIR}/models/${dcs_model_file}"
rsync -avzq -e "ssh -J ${resource_privateIp}" ${origin} ${dcs_model_file}

cat >> macroScript.txt <<END
DCSVERS	200
DCSMSSG	1  0
DCSWORK .

DCS_DEL_FILE *.hst

DCSLOAD ${dcs_model_file}

DCS_CFG_SETTING ${dcs_thread} 0

DCSSIMU_RUN_WITH_SEED 1 ${dcs_num_seeds} ${case_index} ${dcs_concurrency}
DCS_DATA ${out_hst}
END

# run in bat file to get correct exit code from the software
#echo set DCS2FLMD_LICENSE_FILE="$DCS2FLMD_LICENSE_FILE" > run.bat

# Load 3dcs environment
if ! [ -z "${dcs_load}" ]; then
    "${dcs_load}"
fi

# Run 3dcs
eval "${dcs_run}"  macroScript.txt

echo "TRANSFERRING RESULTS TO PW"
origin="Results/"
destination="usercontainer:${PW_JOB_DIR}/Results/"
rsync -avzq -e "ssh -J ${resource_privateIp}" ${origin} ${destination}
