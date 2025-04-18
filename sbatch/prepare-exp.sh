#!/bin/bash
set -e
set -u

module load apptainer

export PROJECT_DIR=/home/mdugre/scratch/mri-registration-rp
export SIF_DIR=/home/mdugre/projects/rrg-glatard/mdugre/containers
export TEMPLATEFLOW_DIR=/home/mdugre/projects/rrg-glatard/mdugre/templateflow
export DATA_DIR=${PROJECT_DIR}/datasets/ds004513
SLURM_OPTS="--account=rrg-glatard"

# Datatset preparation
cat << EOF
########################
# Datatset preparation #
########################
EOF
DATALAD_URL="https://github.com/OpenNeuroDatasets/ds004513.git"
echo "datalad install -gr -J\$(nproc) --source ${DATALAD_URL} ${DATA_DIR}"
## Convert symlink to hardlink to prevent issue with preprocessing
echo "find ${DATA_DIR} -type l -exec bash -c 'ln -f \$(readlink -m \$0) \$0' {} \;"

# Write subjects to file
find ${DATA_DIR} -maxdepth 1 -name "sub-*" -exec basename {} \;| sed -e "s/^sub-//" > subject_ids.txt
NUM_SUBJECTS=$(wc -l < subject_ids.txt)

#########################
# ANTs Brain Extraction #
#########################
export SIF_IMG=${SIF_DIR}/ants-paper-base.simg
job1=$(sbatch --parsable --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsBrainExtraction.sbatch)

#####################
# ANTs Registration #
#####################
export FIXED_IMG=/templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w.nii.gz
export SIF_IMG=${SIF_DIR}/ants-vprec-no_metrics.simg

# Binary64
export EXPERIMENT_NAME="antsRegistration-binary64"
export APPTAINERENV_VFC_BACKENDS="libinterflop_ieee.so"
sbatch --job-name=${EXPERIMENT_NAME} --dependency=afterok:$job1 --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsRegistration-0000.sbatch
# sbatch --job-name=${EXPERIMENT_NAME} --array=1-${NUM_SUBJECTS} ${SLURM_OPTS} ./sbatch/antsRegistration-0000.sbatch
